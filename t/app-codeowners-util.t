#!/usr/bin/env perl

use warnings;
use strict;

use App::Codeowners::Util qw(run_git);
use Path::Tiny qw(path tempdir);
use Test::More;

can_ok('App::Codeowners::Util', qw{
    colorstrip
    find_codeowners_in_directory
    find_nearest_codeowners
    git_ls_files
    git_toplevel
    run_command
    run_git
    stringf
    stringify
    unbackslash
    zip
});

my $can_git = _can_git();

subtest 'git_ls_files' => sub {
    plan skip_all => 'Cannot run git' if !$can_git;
    my $repodir =_setup_git_repo();

    my (undef, @r) = App::Codeowners::Util::git_ls_files($repodir);
    is_deeply(\@r, [], 'git ls-files returns [] when no repo files') or diag explain \@r;

    run_git('-C', $repodir, qw{add .})->wait;
    run_git('-C', $repodir, qw{commit -m}, 'initial commit')->wait;

    (undef, @r) = App::Codeowners::Util::git_ls_files($repodir);
    is_deeply(\@r, [
        qw(a/b/c/bar.txt foo.txt)
    ], 'git ls-files returns correct repo files') or diag explain \@r;
};

subtest 'git_toplevel' => sub {
    plan skip_all => 'Cannot run git' if !$can_git;
    my $repodir =_setup_git_repo();

    my $r = App::Codeowners::Util::git_toplevel($repodir);
    is($r->canonpath, $repodir->canonpath, 'found toplevel directory from toplevel');

    $r = App::Codeowners::Util::git_toplevel($repodir->child('a/b'));
    is($r->canonpath, $repodir->canonpath, 'found toplevel directory');
};

subtest 'find_nearest_codeowners' => sub {
    plan skip_all => 'Cannot run git' if !$can_git;
    my $repodir =_setup_git_repo();

    $repodir->child('docs')->mkpath;
    my $filepath = _spew_codeowners($repodir->child('docs/CODEOWNERS'));

    my $r = App::Codeowners::Util::find_nearest_codeowners($repodir->child('a/b/c'));
    is($r, $filepath, 'found CODEOWNERS file');
};

subtest 'find_codeowners_in_directory' => sub {
    plan skip_all => 'Cannot run git' if !$can_git;
    my $repodir =_setup_git_repo();

    $repodir->child('docs')->mkpath;
    my $filepath = _spew_codeowners($repodir->child('docs/CODEOWNERS'));

    my $r = App::Codeowners::Util::find_codeowners_in_directory($repodir);
    is($r, $filepath, 'found CODEOWNERS file in docs');

    $filepath = _spew_codeowners($repodir->child('CODEOWNERS'));
    $r = App::Codeowners::Util::find_codeowners_in_directory($repodir);
    is($r, $filepath, 'found CODEOWNERS file in toplevel');
};

done_testing;
exit;

sub _can_git {
    my (undef, $version) = eval { run_git('--version') };
    note $@ if $@;
    note "Found: $version" if $version;
    return $version && $version ge 'git version 1.8.5';     # for -C flag
}

sub _setup_git_repo {
    my $repodir = tempdir;

    run_git('-C', $repodir, 'init')->wait;

    $repodir->child('foo.txt')->touchpath;
    $repodir->child('a/b/c/bar.txt')->touchpath;

    return $repodir;
}

sub _spew_codeowners {
    my $path = path(shift);
    $path->spew_utf8(\"foo.txt \@twix\n");
    return $path;
}
