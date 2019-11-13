package Test::File::Codeowners;
# ABSTRACT: Write tests for CODEOWNERS files

=head1 SYNOPSIS

    use Test::More;

    eval 'use Test::File::Codeowners';
    plan skip_all => 'Test::File::Codeowners required for testing CODEOWNERS' if $@;

    codeowners_syntax_ok();
    done_testing;

=head1 DESCRIPTION

This package has assertion subroutines for testing F<CODEOWNERS> files.

=cut

use warnings;
use strict;

use App::Codeowners::Util qw(find_nearest_codeowners git_ls_files git_toplevel);
use Encode qw(encode);
use File::Codeowners;
use Test::Builder;

our $VERSION = '9999.999'; # VERSION

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';   ## no critic (TestingAndDebugging::ProhibitNoStrict)
    *{$caller.'::codeowners_syntax_ok'} = \&codeowners_syntax_ok;
    *{$caller.'::codeowners_git_files_ok'} = \&codeowners_git_files_ok;

    $Test->exported_to($caller);
    $Test->plan(@_);
}

=func codeowners_syntax_ok

    codeowners_syntax_ok();     # search up the tree for a CODEOWNERS file
    codeowners_syntax_ok($filepath);

Check the syntax of a F<CODEOWNERS> file.

=cut

sub codeowners_syntax_ok {
    my $filepath = shift || find_nearest_codeowners();

    eval { File::Codeowners->parse($filepath) };
    my $err = $@;

    $Test->ok(!$err, "Check syntax: $filepath");
    $Test->diag($err) if $err;
}

=func codeowners_git_files_ok

    codeowners_git_files_ok();  # search up the tree for a CODEOWNERS file
    codeowners_git_files_ok($filepath);

=cut

sub codeowners_git_files_ok {
    my $filepath = shift || find_nearest_codeowners();

    $Test->subtest('codeowners_git_files_ok' => sub {
        my $codeowners = eval { File::Codeowners->parse($filepath) };
        if (my $err = $@) {
            $Test->plan(tests => 1);
            $Test->ok(0, "Parse $filepath");
            $Test->diag($err);
            return;
        }

        my ($proc, @files) = git_ls_files(git_toplevel());

        $Test->plan($proc->wait == 0 ? (tests => scalar @files) : (skip_all => 'git ls-files failed'));

        for my $filepath (@files) {
            my $msg = encode('UTF-8', "Check file: $filepath");

            my $match = $codeowners->match($filepath);
            my $is_unowned = $codeowners->is_unowned($filepath);

            if (!$match && !$is_unowned) {
                $Test->ok(0, $msg);
                $Test->diag("File is unowned\n");
            }
            elsif ($match && $is_unowned) {
                $Test->ok(0, $msg);
                $Test->diag("File is owned but listed as unowned\n");
            }
            else {
                $Test->ok(1, $msg);
            }
        }
    });
}

1;
