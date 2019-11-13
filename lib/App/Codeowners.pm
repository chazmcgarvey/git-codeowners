package App::Codeowners;
# ABSTRACT: A tool for managing CODEOWNERS files

use v5.10.1;    # defined-or
use utf8;
use warnings;
use strict;

use App::Codeowners::Formatter;
use App::Codeowners::Options;
use App::Codeowners::Util qw(find_codeowners_in_directory run_git git_ls_files git_toplevel);
use Color::ANSI::Util 0.03 qw(ansifg);
use Encode qw(encode);
use File::Codeowners;
use Path::Tiny;

our $VERSION = '9999.999'; # VERSION

=method main

    App::Codeowners->main(@ARGV);

Run the script and exit; does not return.

=cut

sub main {
    my $class = shift;
    my $self  = bless {}, $class;

    my $opts = App::Codeowners::Options->new(@_);

    my $color = $opts->{color};
    local $ENV{NO_COLOR} = 1 if defined $color && !$color;

    my $command = $opts->command;
    my $handler = $self->can("_command_$command")
        or die "Unknown command: $command\n";
    $self->$handler($opts);

    exit 0;
}

sub _command_show {
    my $self = shift;
    my $opts = shift;

    my $toplevel = git_toplevel('.') or die "Not a git repo\n";

    my $codeowners_path = find_codeowners_in_directory($toplevel)
        or die "No CODEOWNERS file in $toplevel\n";
    my $codeowners = File::Codeowners->parse_from_filepath($codeowners_path);

    my ($proc, $cdup) = run_git(qw{rev-parse --show-cdup});
    $proc->wait and exit 1;

    my $formatter = App::Codeowners::Formatter->new(
        format  => $opts->{format} || ' * %-50F %O',
        handle  => *STDOUT,
        columns => [qw(File Owner), $opts->{project} ? 'Project' : ()],
    );

    $proc = git_ls_files('.', $opts->args);
    while (my $filepath = $proc->next) {
        my $match = $codeowners->match(path($filepath)->relative($cdup));
        $formatter->add_result([
            $filepath,
            $match->{owners},
            $opts->{project} ? $match->{project} : (),
        ]);
    }
    $proc->wait and exit 1;
}

sub _command_owners {
    my $self = shift;
    my $opts = shift;

    my $toplevel = git_toplevel('.') or die "Not a git repo\n";

    my $codeowners_path = find_codeowners_in_directory($toplevel)
        or die "No CODEOWNERS file in $toplevel\n";
    my $codeowners = File::Codeowners->parse_from_filepath($codeowners_path);

    my $results = $codeowners->owners($opts->{pattern});

    my $formatter = App::Codeowners::Formatter->new(
        format  => $opts->{format} || '%O',
        handle  => *STDOUT,
        columns => [qw(Owner)],
    );
    $formatter->add_result(map { [$_] } @$results);
}

sub _command_patterns {
    my $self = shift;
    my $opts = shift;

    my $toplevel = git_toplevel('.') or die "Not a git repo\n";

    my $codeowners_path = find_codeowners_in_directory($toplevel)
        or die "No CODEOWNERS file in $toplevel\n";
    my $codeowners = File::Codeowners->parse_from_filepath($codeowners_path);

    my $results = $codeowners->patterns($opts->{owner});

    my $formatter = App::Codeowners::Formatter->new(
        format  => $opts->{format} || '%T',
        handle  => *STDOUT,
        columns => [qw(Pattern)],
    );
    $formatter->add_result(map { [$_] } @$results);
}

sub _command_create { goto &_command_update }
sub _command_update {
    my $self = shift;
    my $opts = shift;

    my ($filepath) = $opts->args;

    my $path = path($filepath || '.');
    my $repopath;

    die "Does not exist: $path\n" if !$path->parent->exists;

    if ($path->is_dir) {
        $repopath = $path;
        $path = find_codeowners_in_directory($path) || $repopath->child('CODEOWNERS');
    }

    my $is_new = !$path->is_file;

    my $codeowners;
    if ($is_new) {
        $codeowners = File::Codeowners->new;
        my $template = <<'END';
 This file shows mappings between subdirs/files and the individuals and
 teams who own them. You can read this file yourself or use tools to query it,
 so you can quickly determine who to speak with or send pull requests to. ❤️

 Simply write a gitignore pattern followed by one or more names/emails/groups.
 Examples:
   /project_a/**  @team1
   *.js  @harry @javascript-cabal
END
        for my $line (split(/\n/, $template)) {
            $codeowners->append(comment => $line);
        }
    }
    else {
        $codeowners = File::Codeowners->parse_from_filepath($path);
    }

    if ($repopath) {
        # if there is a repo we can try to update the list of unowned files
        my $git_files = git_ls_files($repopath);
        if (@$git_files) {
            $codeowners->clear_unowned;
            $codeowners->add_unowned(grep { !$codeowners->match($_) } @$git_files);
        }
    }

    $codeowners->write_to_filepath($path);
    print STDERR "Wrote $path\n";
}

1;
