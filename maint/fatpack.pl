#!/usr/bin/env perl

=head1 NAME

    maint/fatpack.pl - Generate a fatpack version of git-codeowners

=head1 SYNOPSIS

    maint/fatpack.pl --dist-dir DIRPATH [--clean]

=cut

use 5.010001;
use strict;
use warnings;

use CPAN::Meta;
use Capture::Tiny qw(capture_stdout);
use Config;
use File::pushd;
use Getopt::Long;
use MetaCPAN::API;
use Module::CoreList;
use Path::Tiny 0.089;

my $core_version        = '5.010001';
my $plenv_version       = '5.10.1';
my %blacklist_modules   = map { $_ => 1 } (
    'perl',
    'Text::Table::ASV',     # brought in by Text::Table::Any but not actually required
    'Unicode::GCString',    # optional XS module
);
my @extra_modules = (
    'Proc::Find::Parents',  # used by Term::Detect::Software on some platforms
);

my $clean = 0;
my $distdir;
GetOptions(
    'clean!'    => \$clean,
    'dist=s'    => \$distdir,
) or die "Invalid options.\n";
$distdir && -d $distdir or die "Use --dist to specify path to a distribution directory.\n";

my $mcpan = MetaCPAN::API->new;

run($distdir, $clean);
exit;

sub install_modules {
    my $path    = path(shift);
    my @modules = @_;
    run_command('cpanm', '-n', "-L$path", @modules);
}

sub run {
    my $distdir = path(shift);
    my $clean   = shift;

    my $builddir = path('.build');
    my $fatlibdir = path('fatlib');

    if ($clean) {
        print STDERR "Cleaning...\n";
        $builddir->remove_tree({safe => 0});
        $fatlibdir->remove_tree({safe => 0});
    }

    $builddir->mkpath;

    my @modules = required_modules($distdir, $builddir->child('deps.txt'));
    install_modules($builddir->child('local'), @modules);
    pack_modules($builddir->child('local'), @modules);

    clean_fatlib($fatlibdir);

    # consolidate all modules into a new directory for packing
    my $moduledir = $builddir->child('modules');
    $moduledir->remove_tree({safe => 0});
    $moduledir->mkpath;
    system(qw{cp -r}, $fatlibdir, $distdir->child('lib'), "$moduledir/");

    $moduledir->child('lib/Test/File/Codeowners.pm')->remove;    # don't need this

    my $fatpack = do {
        my $cd_builddir = pushd($moduledir);

        system('perlstrip', '--cache', '-v', find_modules('.'));
        `fatpack file`;
    };

    generate_script($distdir->child('bin/git-codeowners'), $fatpack, 'git-codeowners');
}

sub required_modules {
    my $path            = path(shift);
    my $cache_filepath  = shift;

    print STDERR "Determining required modules...\n";

    my $cachefile = $cache_filepath && path($cache_filepath);
    if (my $contents = eval { $cachefile->slurp_utf8 }) {
        chomp $contents;
        return split(/\n/, $contents);
    }

    my $meta = CPAN::Meta->load_file($path->child('META.json'));

    my $requires = CPAN::Meta::Requirements->new;

    for my $type (qw{requires recommends suggests}) {
        my $reqs = $meta->effective_prereqs->requirements_for('runtime', $type);
        for my $module ($reqs->required_modules) {
            next if $blacklist_modules{$module};

            my $core = $Module::CoreList::version{$core_version}{$module};
            print STDERR "skipping core: $module $core\n" if $core;
            next if $core && $reqs->accepts_module($module, $core);

            $requires->add_string_requirement($module => $reqs->requirements_for_module($module));
            dependencies_for_module($requires, $module);
        }
    }
    $requires->clear_requirement($_) for qw(Module::CoreList ExtUtils::MakeMaker Carp);
    my @deps = $requires->required_modules;

    push @deps, @extra_modules;

    $cachefile->spew_utf8([map { "$_\n" } @deps]) if $cachefile;

    return @deps;
}

sub dependencies_for_dist {
    my $requires    = shift;
    my $name        = shift;

    state %dists;
    return if $dists{$name}++;
    print STDERR "Finding dependencies for dist $name\n";

    my $dist = $mcpan->release(distribution => $name);

    my $reqs = CPAN::Meta::Requirements->new;

    foreach my $dep (@{$dist->{dependency}}) {
        next if $dep->{phase} ne 'runtime';
        next if $dep->{relationship} ne 'requires'; # && $dep->{relationship} ne 'recommends';

        my $module = $dep->{module};
        next if $blacklist_modules{$module};

        $reqs->add_minimum($dep->{module} => $dep->{version});
        my $core = $Module::CoreList::version{$core_version}{$module};
        print STDERR "skipping core: $module $core\n" if $core;
        next if $core && $reqs->accepts_module($module, $core);

        $requires->add_string_requirement($module => $reqs->requirements_for_module($module));
        dependencies_for_module($requires, $dep->{module});
    }
}

sub dependencies_for_module {
    my $requires    = shift;
    my $name        = shift;

    state %modules;
    return if $modules{$name}++;
    print STDERR "Finding dependencies for module $name\n";

    my $module = $mcpan->module($name);
    dependencies_for_dist($requires, $module->{distribution});
}

sub clean_fatlib {
    my $path = path(shift);
    $path->child($Config{archname})->remove_tree({safe => 0});
    $path->child('POD2')->remove_tree({safe => 0});
    $path->visit(sub {
        local $_ = shift;
        if (/\.p(od|l)$/ || /\.sample$/) {
            print "rm $_\n";
            $_->remove;
        }
    }, {recurse => 1});
}

sub find_modules {
    my $path = path(shift);
    my @pm_filepaths;
    $path->visit(sub {
        local $_ = shift;
        push @pm_filepaths, $_ if /\.pm$/;
    }, {recurse => 1});
    return @pm_filepaths;
}

sub pack_modules {
    my ($path, @modules) = @_;

    my @filepaths = map { my $s = $_; $s =~ s!::!/!g; "$s.pm" } @modules;

    my $stdout = capture_stdout {
        local $ENV{PERL5LIB} = $path->child('lib/perl5')->absolute;
        system('fatpack', 'packlists-for', @filepaths);
    };

    my @packlists = split(/\n/, $stdout);
    for my $packlist (@packlists) {
        warn "Packing $packlist\n";
    }

    system('fatpack', 'tree', map { path($_)->absolute } @packlists);
}

sub generate_script {
    my ($input_filepath, $fatpack, $output_filepath) = @_;

    open(my $in,  '<', $input_filepath)        or die "open failed: $!";
    open(my $out, '>', "$output_filepath.tmp") or die "open failed: $!";

    while (<$in>) {
        s|^#!\h*perl|#!/usr/bin/env perl|;
        s|^# FATPACK.*|$fatpack|;
        print $out $_;
    }

    unlink($output_filepath);
    rename("$output_filepath.tmp", $output_filepath);

    path($output_filepath)->chmod(0755);

    print STDERR "Wrote fatpacked script: $output_filepath\n";
}

sub run_command {
    local $ENV{PLENV_VERSION} = $plenv_version;
    system('plenv', 'exec', @_);
}

