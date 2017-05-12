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
#   Description:    A sub-class of Text::Textile::Plaintext that plugs in a
#                   PostScript formatter in place of the plain-text one.
#
#   Functions:      new
#                   textile
#
#   Libraries:      HTML::FormatPS
#
#   Global Consts:  $VERSION
#
###############################################################################

package Text::Textile::PostScript;

use 5.008;
use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK);
use subs qw(new textile);
use base qw(Exporter Text::Textile::Plaintext);

use Scalar::Util qw(blessed reftype);
require HTML::FormatPS;

$VERSION   = '0.101';
$VERSION   = eval $VERSION;    ## no critic
@EXPORT    = ();
@EXPORT_OK = qw(textile);

###############################################################################
#
#   Sub Name:       new
#
#   Description:    Look for "formatter" arguments, and/or create a PS-based
#                   formatter before relegating to the parent-class
#                   constructor.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Class we are blessing into
#                   %args     in      hash      Additional arguments
#
#   Returns:        object reference, dies if given bad "formatter" data
#
###############################################################################
sub new
{
    my ($class, %args) = @_;

    if ($args{formatter})
    {
        if (!blessed $args{formatter})
        {
            die __PACKAGE__ . "::new: Argument to 'formatter' must be an " .
              'object or a hash reference, stopped'
              unless (reftype($args{formatter}) eq 'HASH');

			$args{formatter} = HTML::FormatPS->new(%{$args{formatter}});
        }
    }
    else
    {
        $args{formatter} = HTML::FormatPS->new(PaperSize => 'Letter');
    }

    $class->SUPER::new(%args);
}

###############################################################################
#
#   Sub Name:       textile
#
#   Description:    A wrapper around the parent-class version, so that this
#                   can be properly exported.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       If present, an object of this
#                                                 class. If not present, a
#                                                 throw-away one is created.
#                   $content  in      scalar    Content to be converted to
#                                                 plain text.
#
#   Returns:        return value from SUPER::textile
#
###############################################################################
sub textile
{
	my ($self, $content) = @_;

	unless (blessed $self && $self->isa('Text::Textile::PostScript'))
	{
		$content = $self;
		$self = __PACKAGE__->new();
	}

	$self->SUPER::textile($content);
}

1;

=head1 NAME

Text::Textile::PostScript - Generate PostScript output from Textile mark-up

=head1 SYNOPSIS

    use Text::Textile::PostScript qw(textile);

    my $textile = <<EOT;
    h1. Heading

    A _simple_ demonstration of Textile markup.

    * One
    * Two
    * Three

    "More information":http://www.textism.com/tools/textile is available.
    EOT

    # Procedural interface:
    my $postscript = textile($textile);
    print $postscript;

    # Object-oriented interface
    my $ttps = Text::Textile::RTF->new();
    $postscript = $ttps->process($textile);

=head1 DESCRIPTION

B<Text::Textile::PostScript> is a sub-class of B<Text::Textile::Plaintext> that
produces PostScript output instead of plain text. See
L<Text::Textile::Plaintext> for more detail.

=head1 METHODS

This class only defines the following two methods. It inherits everything else
from B<Text::Textile::Plaintext>.

=over 4

=item new([%args])

Create a new instance of this class. This constructor calls the super-class
constructor after handling the C<formatter> parameter and setting up an
instance of B<HTML::FormatRTF> to pass to the parent. This method only handles
the following parameter:

=over 8

=item formatter($obj|$hashref)

Specify either a pre-created instance of B<HTML::FormatPS> (or a suitable
sub-class) or a hash-reference of parameters to pass to the constructor when
creating one. If this parameter is not present, an object is created with the
default parameters (as according to B<HTML::FormatPS>). The exception to this
is that the default paper-size in B<HTML::FormatPS> is "A4", whereas this
module defaults paper size to "Letter". See L<HTML::FormatPS> for details on
the options available to the constructor.

=back

See documentation of the new() method in L<Text::Textile::Plaintext> for
additional recognized parameters.

=item textile($textile)

This method is defined in this class so that it can be imported and used
procedurally, as textile() is used in either B<Text::Textile::Plaintext> or
B<Text::Textile> itself. It renders the Textile mark-up in C<$textile> to HTML,
then renders the resulting HTML tree into PostScript. It returns the PostScript
content as a single string.

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

L<Text::Textile>, L<Text::Textile::Plaintext>, L<Text::Textile::RTF>,
L<HTML::FormatPS>.

=head1 AUTHOR

Randy J. Ray C<< <rjray@blackperl.com> >>

=cut
