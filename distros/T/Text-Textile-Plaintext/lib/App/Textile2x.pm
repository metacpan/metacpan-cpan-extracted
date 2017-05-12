###############################################################################
#
# This file copyright (c) 2009 by Randy J. Ray, all rights reserved
#
# Copying and distribution are permitted under the terms of the Artistic
# License 2.0 (http://www.opensource.org/licenses/artistic-license-2.0.php) or
# the GNU LGPL (http://www.opensource.org/licenses/lgpl-2.1.php).
#
###############################################################################
#
#   Description:    Wrap the general functionality of the "textile2x"
#                   application.
#
#   Functions:      new
#                   version
#                   convert
#
#   Libraries:      Scalar::Util
#
#   Global Consts:  $VERSION
#
###############################################################################

package App::Textile2x;

use 5.006001;
use strict;
use warnings;
use vars qw($VERSION %FORMATS);
use subs qw(new version leftmargin rightmargin convert);

use Scalar::Util 'reftype';

$VERSION = '0.101';
$VERSION = eval $VERSION;    ## no critic

%FORMATS = (
    plaintext  => 'Text::Textile::Plaintext',
    postscript => 'Text::Textile::PostScript',
    rtf        => 'Text::Textile::RTF',
);

# Method-y access to our version
sub version { $VERSION }

###############################################################################
#
#   Sub Name:       new
#
#   Description:    Create an instance of this class
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Class we're creating
#                   %args     in      hash      Additional args, not examined
#                                                 until a call to convert()
#
#   Returns:        new object
#
###############################################################################
sub new
{
    my ($class, %args) = @_;

    my $self = \%args;

    bless $self, $class;
}

###############################################################################
#
#   Sub Name:       convert
#
#   Description:    Convert content from the given source, out to the given
#                   sink, using the specified format.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $source   in      scalar    Source of data, a string or
#                                                 IO-ish ref
#                   $sink     in      scalar    Place to store results, either
#                                                 a string or IO-ish ref
#                   $format   in      scalar    Format to use, the default is
#                                                 'plaintext'
#
#   Returns:        Success:    1
#                   Failure:    throws exception (dies)
#
###############################################################################
sub convert
{
    my ($self, $source, $sink) = @_;
	# Assign $format only if there is a 4th argument
	my $format = $_[3] ? lc $_[3] : '';
	$format = 'plaintext' unless $FORMATS{$format};

    my ($fmtclass, @formatargs, $textiler, $input, $output);

    $fmtclass = $FORMATS{$format};

    die "Second argument ('sink') to convert() must be scalar ref or IO ref"
        unless ((ref($sink) eq 'SCALAR') || (reftype($sink) eq 'GLOB'));

	unless ($textiler = $self->{$fmtclass})
	{
		# If the creation of this object provided arguments for this format,
		# set them up prior to the creation of the Text::Textile::* object:
		@formatargs = ref($self->{$format}) ?
			(formatter => $self->{$format}) : ();

		# Make sure we have the library in memory:
		eval "require $fmtclass";    ## no critic
		die "Error attempting to load $fmtclass: $@" if $@;

		# Create a processor object
		$self->{$fmtclass} = $textiler = $fmtclass->new(@formatargs);
	}

    # Determine our input content:
    if (ref($source) eq 'SCALAR')
    {
        $input = $$source;
    }
    elsif (reftype($source) eq 'GLOB')
    {
        $input = join('', <$source>);
    }
    else
    {
        $input = $source;
    }

    $output = $textiler->textile($input);

    # Send the output to where it belongs (we already validated $sink):
    if (ref($sink) eq 'SCALAR')
    {
        $$sink = $output;
    }
    else
    {
        print $sink $output;
    }

    1;
}

1;

=head1 NAME

App::Textile2x - Application-wrapper class for converting Textile mark-up

=head1 SYNOPSIS

    use App::Textile2x;

    # ...presume that %opts comes from the command-line or other source
    $input  = $opts{input}  || \*STDIN;
    $output = $opts{output} || \*STDOUT;

    $app = App::Textile2x->new();
    $app->convert($input, $output, $opts{format} || 'plaintext');

=head1 DESCRIPTION

The B<App::Textile2x> class is a wrapper around basic functionality based on
the B<Text::Textile::Plaintext>, etc., classes. It is meant to encapsulate the
functionality provided by the B<textile2x> family of scripts that come with
this distribution.

=head1 USAGE

This class makes two methods available:

=over 4

=item new([%args])

Create an instance of the class. Any arguments are assumed to be key-value
pairs that specify constructor arguments for the formatter classes. These are
used only when the class in question is actually instantiated.

The value associated with each key should be a hash-reference containing
key-value pairs that are used for the constructor of the given class. The three
keys currently recognized are:

=over 8

=item plaintext

Arguments for the B<Text::Textile::Plaintext> class.

=item postscript

Arguments for the B<Text::Textile::PostScript> class.

=item rtf

Arguments for the B<Text::Textile::RTF> class.

=back

Note that the keys are expected to be all-lowercase. See the associated
documentation pages for each formatter class for more information on their
arguments.

=item convert($source, $sink, $format)

Convert Textile mark-up in the given C<$source> and send the resulting output
to the given C<$sink>. Optionally, specify C<$format> to use, with the default
being "plaintext".

The C<$source> parameter may be in one of forms:

=over 8

=item Scalar

If the source is a plain scalar, it is taken as the Textile content itself and
used directly.

=item Scalar reference

If the source is a scalar reference, it is assumed to reference the content. It
is de-referenced and its content passed to B<Text::Textile>.

=item Filehandle reference (GLOB)

Lastly, if the source is a filehandle or filehandle-like value, it is read from
and the complete content from it is passed to B<Text::Textile>. Note that it is
not I<streamed> to the Textile converter (which does not support streaming
anyway). Caution should be taken when converting excessively large files this
way.

=back

The C<$sink> parameter may be in one of two forms:

=over 8

=item Scalar reference

If the sink is a scalar reference, the converted content is assigned to it
directly.

=item Filehandle reference (GLOB)

If the sink is a reference to a filehandle or filehandle-like value, then the
converted content is written to it using B<print>.

=back

The last parameter, C<$format>, is optional and defaults to C<plaintext>. It
specifies whether the converted Textile content is then converted to text
(C<plaintext>), PostScript (C<postscript>) or Rich Text Format (C<rtf>). The
value is converted to lower-case, so C<PostScript> is a synonym for
C<postscript>.

The return value from convert() is always a true value, as it uses B<die> to
throw an exception on any errors it encounters.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-textile-plaintext at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Textile-Plaintext>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Textile-Plaintext>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Textile-Plaintext>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Textile-Plaintext>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Textile-Plaintext>

=item * Source code on GitHub

L<http://github.com/rjray/text-textile-plaintext/tree/master>

=back

=head1 COPYRIGHT & LICENSE

This file and the code within are copyright (c) 2009 by Randy J. Ray.

Copying and distribution are permitted under the terms of the Artistic
License 2.0 (L<http://www.opensource.org/licenses/artistic-license-2.0.php>) or
the GNU LGPL 2.1 (L<http://www.opensource.org/licenses/lgpl-2.1.php>).

=head1 SEE ALSO

L<Text::Textile>, L<Text::Textile::Plaintext>, L<Text::Textile::PostScript>,
L<Text::Textile::RTF>

=head1 AUTHOR

Randy J. Ray C<< <rjray@blackperl.com> >>

=cut
