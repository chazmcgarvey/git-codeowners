package App::Codeowners::Formatter::YAML;
# ABSTRACT: Format codeowners output as YAML

=head1 DESCRIPTION

This is a L<App::Codeowners::Formatter> that formats output using L<YAML>.

=cut

use warnings;
use strict;

our $VERSION = '9999.999'; # VERSION

use parent 'App::Codeowners::Formatter';

use App::Codeowners::Util qw(zip);

sub finish {
    my $self    = shift;
    my $results = shift;

    eval { require YAML } or die "Missing dependency: YAML\n";

    my $columns = $self->columns;
    $results = [map { +{zip @$columns, @$_} } @$results];
    print { $self->handle } YAML::Dump($results);
}

1;
