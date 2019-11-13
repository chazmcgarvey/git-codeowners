package App::Codeowners::Formatter::TSV;
# ABSTRACT: Format codeowners output as tab-separated values

=head1 DESCRIPTION

This is a L<App::Codeowners::Formatter::CSV> that formats output using L<Text::CSV>.

=cut

use warnings;
use strict;

our $VERSION = '9999.999'; # VERSION

use parent 'App::Codeowners::Formatter::CSV';

sub sep { "\t" }

1;
