package App::Codeowners::Formatter::JSON;
# ABSTRACT: Format codeowners output as JSON

=head1 DESCRIPTION

This is a L<App::Codeowners::Formatter> that formats output using L<JSON::MaybeXS>.

=cut

use warnings;
use strict;

our $VERSION = '9999.999'; # VERSION

use parent 'App::Codeowners::Formatter';

use App::Codeowners::Util qw(zip);

=attr format

If unset (default), the output will be compact. If "pretty", the output will look nicer to humans.

=cut

sub finish {
    my $self    = shift;
    my $results = shift;

    eval { require JSON::MaybeXS } or die "Missing dependency: JSON::MaybeXS\n";

    my %options;
    $options{pretty} = 1 if lc($self->format) eq 'pretty';

    my $json = JSON::MaybeXS->new(canonical => 1, %options);

    my $columns = $self->columns;
    $results = [map { +{zip @$columns, @$_} } @$results];
    print { $self->handle } $json->encode($results);
}

1;
