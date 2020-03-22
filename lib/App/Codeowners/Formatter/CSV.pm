package App::Codeowners::Formatter::CSV;
# ABSTRACT: Format codeowners output as comma-separated values

=head1 DESCRIPTION

This is a L<App::Codeowners::Formatter> that formats output using L<Text::CSV>.

=cut

use warnings;
use strict;

our $VERSION = '9999.999'; # VERSION

use parent 'App::Codeowners::Formatter';

use App::Codeowners::Util qw(stringify);

sub start {
    my $self = shift;

    $self->text_csv->print($self->handle, $self->columns);
}

sub stream {
    my $self    = shift;
    my $result  = shift;

    $self->text_csv->print($self->handle, [map { stringify($_) } @$result]);
}

=attr text_csv

Get the L<Text::CSV> instance.

=cut

sub text_csv {
    my $self = shift;

    $self->{text_csv} ||= do {
        eval { require Text::CSV } or die "Missing dependency: Text::CSV\n";

        my %options;
        $options{escape_char} = $self->escape_char if $self->escape_char;
        $options{quote}       = $self->quote       if $self->quote;
        $options{sep}         = $self->sep         if $self->sep;
        if ($options{sep} && $options{sep} eq ($options{quote} || '"')) {
            die "Invalid separator value for CSV format.\n";
        }

        Text::CSV->new({binary => 1, eol => $/, %options});
    } or die "Failed to construct Text::CSV object";
}

=attr sep

Get the value used for L<Text::CSV/sep>.

=attr quote

Get the value used for L<Text::CSV/quote>.

=attr escape_char

Get the value used for L<Text::CSV/escape_char>.

=cut

sub sep         { $_[0]->{sep} || $_[0]->format }
sub quote       { $_[0]->{quote} }
sub escape_char { $_[0]->{escape_char} }

1;
