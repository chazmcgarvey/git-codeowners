use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/git-codeowners',
    'lib/App/Codeowners.pm',
    'lib/App/Codeowners/Options.pm',
    'lib/App/Codeowners/Util.pm',
    'lib/File/Codeowners.pm',
    'lib/Test/File/Codeowners.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/app-codeowners-util.t',
    't/app-codeowners.t',
    't/file-codeowners.t',
    't/samples/basic.CODEOWNERS',
    't/samples/kitchensink.CODEOWNERS',
    'xt/author/critic.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/consistent-version.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
