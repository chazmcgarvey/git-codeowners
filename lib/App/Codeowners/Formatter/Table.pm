package App::Codeowners::Formatter::Table;
# ABSTRACT: Format codeowners output as a table

=head1 DESCRIPTION

This is a L<App::Codeowners::Formatter> that formats output using L<Text::Table::Any>.

=cut

use warnings;
use strict;

our $VERSION = '9999.999'; # VERSION

use parent 'App::Codeowners::Formatter';

use App::Codeowners::Util qw(stringify);

sub finish {
    my $self    = shift;
    my $results = shift;

    eval { require Text::Table::Any } or die "Missing dependency: Text::Table::Any\n";

    my $table = Text::Table::Any::table(
        header_row  => 1,
        rows        => [$self->columns, map { [map { stringify($_) } @$_] } @$results],
        backend     => $ENV{PERL_TEXT_TABLE},
    );
    print { $self->handle } $table;
}

1;
