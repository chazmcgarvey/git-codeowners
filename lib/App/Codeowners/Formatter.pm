package App::Codeowners::Formatter;
# ABSTRACT: Base class for formatting codeowners output

=head1 SYNOPSIS

    my $formatter = App::Codeowners::Formatter->new(handle => *STDOUT);
    $formatter->add_result($_) for @results;

=head1 DESCRIPTION

This is a base class for formatters. A formatter is a class that takes data records, stringifies
them, and prints them to an IO handle.

This class is mostly abstract, though it is also usable as a null formatter where results are simply
discarded if it is instantiated directly. These other formatters do more interesting things:

=for :list
* L<App::Codeowners::Formatter::CSV>
* L<App::Codeowners::Formatter::String>
* L<App::Codeowners::Formatter::JSON>
* L<App::Codeowners::Formatter::TSV>
* L<App::Codeowners::Formatter::Table>
* L<App::Codeowners::Formatter::YAML>

=cut

use warnings;
use strict;

our $VERSION = '9999.999'; # VERSION

use Module::Load;

=method new

    $formatter = App::Codeowners::Formatter->new;
    $formatter = App::Codeowners::Formatter->new(%attributes);

Construct a new formatter.

=cut

sub new {
    my $class = shift;
    my $args  = {@_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_};

    $args->{results} = [];

    # see if we can find a better class to bless into
    ($class, my $format) = $class->_best_formatter($args->{format}) if $args->{format};
    $args->{format} = $format;

    my $self = bless $args, $class;

    $self->start;

    return $self;
}

### _best_formatter
#   Find a formatter that can handle the format requested.
sub _best_formatter {
    my $class = shift;
    my $type  = shift || '';

    return ($class, $type) if $class ne __PACKAGE__;

    my ($name, $format) = $type =~ /^([A-Za-z]+)(?::(.*))?$/;
    if (!$name) {
        $name   = '';
        $format = '';
    }

    $name = lc($name);
    $name =~ s/:.*//;

    my @formatters = $class->formatters;

    # default to the string formatter since it has no dependencies
    my $package = __PACKAGE__.'::String';

    # look for a formatter whose name matches the format
    for my $formatter (@formatters) {
        my $module = lc($formatter);
        $module =~ s/.*:://;

        if ($module eq $name) {
            $package = $formatter;
            $type    = $format;
            last;
        }
    }

    load $package;
    return ($package, $type);
}

=method DESTROY

Destructor calls L</finish>.

=cut

sub DESTROY {
    my $self = shift;
    my $global_destruction = shift;

    return if $global_destruction;

    my $results = $self->{results};
    $self->finish($results) if $results;
    delete $self->{results};
}

=attr handle

Get the IO handle associated with a formatter.

=attr format

Get the format string, which may be used to customize the formatting.

=attr columns

Get an arrayref of column headings.

=attr results

Get an arrayref of all the results that have been provided to the formatter using L</add_result> but
have not yet been formatted.

=cut

sub handle  { shift->{handle}  }
sub format  { shift->{format}  || '' }
sub columns { shift->{columns} || [] }
sub results { shift->{results} }

=method add_result

    $formatter->add_result($result);

Provide an additional result to be formatted.

=cut

sub add_result {
    my $self = shift;
    $self->stream($_) for @_;
}

=method start

    $formatter->start;

Begin formatting results. Called before any results are passed to the L</stream> method.

This method may print a header to the L</handle>. This method is used by subclasses and should
typically not be called explicitly.

=method stream

    $formatter->stream(\@result, ...);

Format one result.

This method is expected to print a string representation of the result to the L</handle>. This
method is used by subclasses and should typically not called be called explicitly.

The default implementation simply stores the L</results> so they will be available to L</finish>.

=method finish

    $formatter->finish;

End formatting results. Called after all results are passed to the L</stream> method.

This method may print a footer to the L</handle>. This method is used by subclasses and should
typically not be called explicitly.

=cut

sub start  {}
sub stream { push @{$_[0]->results}, $_[1] }
sub finish {}

=method formatters

    @formatters = App::Codeowners::Formatter->formatters;

Get a list of package names of potential formatters within the C<App::Codeowners::Formatter>
namespace.

=cut

sub formatters {
    return qw(
        App::Codeowners::Formatter::CSV
        App::Codeowners::Formatter::JSON
        App::Codeowners::Formatter::String
        App::Codeowners::Formatter::TSV
        App::Codeowners::Formatter::Table
        App::Codeowners::Formatter::YAML
    );
}

1;
