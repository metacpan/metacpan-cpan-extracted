package Text::Sprintf::Named;

use warnings;
use strict;

use 5.008;

use Carp;
use warnings::register;

use parent 'Exporter';

use vars qw(@EXPORT_OK);

@EXPORT_OK = (qw( named_sprintf ));

=encoding utf8

=head1 NAME

Text::Sprintf::Named - sprintf-like function with named conversions

=head1 VERSION

Version 0.0402

=cut

our $VERSION = '0.0402';

=head1 SYNOPSIS

    use Text::Sprintf::Named;

    my $formatter =
        Text::Sprintf::Named->new(
            {fmt => "Hello %(name)s! Today is %(day)s!"}
        );

    # Returns "Hello Ayeleth! Today is Sunday!"
    $formatter->format({args => {'name' => "Ayeleth", 'day' => "Sunday"}});

    # Returns "Hello John! Today is Thursday!"
    $formatter->format({args => {'name' => "John", 'day' => "Thursday"}});

    # Or alternatively using the non-OOP interface:

    use Text::Sprintf::Named qw(named_sprintf);

    # Prints "Hello Sophie!" (and a newline).
    print named_sprintf("Hello %(name)s!\n", { name => 'Sophie' });

    # Same, but with a flattened parameter list (not inside a hash reference)
    print named_sprintf("Hello %(name)s!\n", name => 'Sophie');

=head1 DESCRIPTION

Text::Sprintf::Named provides a sprintf equivalent with named conversions.
Named conversions are sprintf field specifiers (like C<"%s"> or C<"%4d>")
only they are associated with the key of an associative array of
parameters. So for example C<"%(name)s"> will emit the C<'name'> parameter
as a string, and C<"%(num)4d"> will emit the C<'num'> parameter
as a variable with a width of 4.

=head1 FUNCTIONS

=head2 my $formatter = Text::Sprintf::Named->new({fmt => $format})

Creates a new object which formats according to the C<$format> format.

=cut

sub new
{
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my ($self, $args) = @_;

    my $fmt = $args->{fmt} or
        confess "The 'fmt format was not specified for Text::Sprintf::Named.";
    $self->_fmt($fmt);

    return 0;
}

sub _fmt
{
    my $self = shift;

    if (@_)
    {
        $self->{_fmt} = shift;
    }

    return $self->{_fmt};
}

=head2 $formatter->format({args => \%bindings})

Returns the formatting string as formatted using the named parameters
pointed to by the C<args> parameter.

=cut

sub format
{
    my $self = shift;

    my $args = shift || {};

    if ( (scalar keys %{$args}) > 0  && not exists $args->{args} ){
        warnings::warnif( $self, 'Format parameters were specified, but none of them were \'args\', this is probably a mistake.' );
    }

    my $named_params = $args->{args} || {};

    my $format = $self->_fmt;

    $format =~ s/%(%|\(([a-zA-Z_]\w*)\)([\+\-\.\d]*)([DEFGOUXbcdefgiopsux]))/
        $self->_conversion({
            format_args => $args,
            named_params => $named_params,
            conv => $1,
            name => $2,
            conv_prefix => $3,
            conv_letter => $4,
        })
        /ge;

    return $format;
}

=head2 $self->calc_param({%args})

This method is used to calculate the parameter for the conversion. It
can be over-rided by subclasses so it will behave differently. An example
can be found in C<t/02-override-param-retrieval.t> where it is used to
call the accessors of an object for values.

%args contains:

=over 4

=item * named_params

The named paramters.

=item * name

The name of the conversion.

=back

=cut

sub calc_param
{
    my ($self, $args) = @_;
    if ( not exists $args->{named_params}->{$args->{name}} ){
        warnings::warnif($self, "Token '$args->{name}' specified in the format '$self->{_fmt}' was not found." );
        return '';
    }
    return $args->{named_params}->{$args->{name}};
}

sub _conversion
{
    my ($self, $args) = @_;

    if ($args->{conv} eq "%")
    {
        return "%";
    }
    else
    {
        return $self->_sprintf(
            ("%" . $args->{conv_prefix} . $args->{conv_letter}),
            $self->calc_param($args),
        );
    }
}

sub _sprintf
{
    my ($self, $format, @args) = @_;

    return sprintf($format, @args);
}

=head2 named_sprintf($format, {%parameters})

=head2 named_sprintf($format, %parameters)

This is a convenience function to directly format a string with the named
parameters, which can be specified inside a (non-blessed) hash reference or
as a flattened hash. See the synopsis for an example.

=cut

sub named_sprintf
{
    my ($format, @args) = @_;

    my $params;
    if (! @args)
    {
        $params = {};
    }
    elsif (ref($args[0]) eq "HASH")
    {
        $params = shift(@args);
    }
    else
    {
        $params = {@args};
    }

    return
        Text::Sprintf::Named->new({ fmt => $format})
                            ->format({args => $params});
}

=head1 AUTHOR

Shlomi Fish, C<< shlomif@cpan.org >> , L<http://www.shlomifish.org/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-sprintf-named at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text::Sprintf::Named>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Sprintf::Named

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text::Sprintf::Named>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text::Sprintf::Named>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text::Sprintf::Named>

=item * Search CPAN

L<http://search.cpan.org/dist/Text::Sprintf::Named>

=item * Subversion Repository

L<http://svn.berlios.de/svnroot/repos/web-cpan/Text-Sprintf/trunk/>

=back

=head1 ACKNOWLEDGEMENTS

The (possibly ad-hoc) regex for matching the optional digits+symbols
parameters' prefix of the sprintf conversion was originally written by Bart
Lateur (BARTL on CPAN) for his L<String::Sprintf> module.

The syntax was borrowed directly from Python’s "%" operator when used
with its dictionaries as the right-hand argument. A quick web search did
not yield good documentation about it (and I came with the idea of a named
sprintf without knowing that Python had it, only ran into the fact that
Python had it by web-searching).

=head1 SIMILAR MODULES

L<Text::sprintfn> is a newer module which only provides a procedural interface
that allows one to mix positional and named arguments, with some other
interesting features.

L<String::Formatter> is a comprehensive module that allows one to define
custom sprintf-like functions (I’m not sure whether it has named conversions).
Its license is the GNU General Public Licence version 2 (GPLv2), which is both
restrictive and incompatible with version 3 of the GPL and with many other
open-source licenses.

L<String::Sprintf> appears to allow one to provide custom sprintf/printf
formats (without providing named conversions).

For the lighter side, there is L<Acme::StringFormat>, which provides a
"%" operator to format a string.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT/X11:

L<http://www.opensource.org/licenses/mit-license.php>

=cut

1; # End of Text::Sprintf::Named
