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
#   Description:    Render plain-text output from Textile input by taking the
#                   HTML content and converting it to text the way LWP's
#                   lwp-request script does.
#
#   Functions:      new
#                   textile
#
#   Libraries:      Text::Textile
#                   HTML::TreeBuilder
#                   HTML::FormatText
#
#   Global Consts:  $VERSION
#
###############################################################################

package Text::Textile::Plaintext;

use 5.008;
use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK);
use subs qw(new textile treebuilder formatter);
use base qw(Exporter Text::Textile);

use Scalar::Util qw(blessed reftype);
require HTML::TreeBuilder;
require HTML::FormatText;

$VERSION   = '0.101';
$VERSION   = eval $VERSION;    ## no critic
@EXPORT    = ();
@EXPORT_OK = qw(textile);

###############################################################################
#
#   Sub Name:       new
#
#   Description:    Create a new object of this class by creating a super-class
#                   instance and then adding objects for the parser and text-
#                   formatter.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Name of the class to bless into
#                   %args     in      hash      If passed, arguments for the
#                                                 constructer, either for the
#                                                 super-class or the two that
#                                                 are specific here (the parser
#                                                 and text-formatter referents)
#
#   Returns:        Success:    new object
#                   Failure:    whatever Text::Textile::new() returned
#
###############################################################################
sub new
{
    my ($class, %args) = @_;

    my $htmltree = delete $args{treebuilder} || HTML::TreeBuilder->new();
    my $fmttext = delete $args{formatter};

    unless ($fmttext)
    {
        my $lmargin = (exists $args{leftmargin}) ? delete $args{leftmargin} : 0;
        my $rmargin =
          (exists $args{rightmargin}) ? delete $args{rightmargin} : 79;
        $fmttext = HTML::FormatText->new(
            leftmargin  => $lmargin,
            rightmargin => $rmargin
        );
    }

    my $self = $class->SUPER::new(%args);
    return $self unless ref($self);

    bless $self, $class;
    $self->treebuilder($htmltree);
    $self->formatter($fmttext);

    $self;
}

###############################################################################
#
#   Sub Name:       textile
#
#   Description:    Overload of the parent's textile() method. Calls the
#                   superclass form, then returns the content formatted to
#                   plain-text via an instance of HTML::TreeBuilder working
#                   with an instance of HTML::FormatText.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       If present, an object of this
#                                                 class. If not present, a
#                                                 throw-away one is created.
#                   $content  in      scalar    Content to be converted to
#                                                 plain text.
#
#   Returns:        Success:    lines of plain text
#                   Failure:    whatever the underlying error(s) are/were
#
###############################################################################
sub textile
{
    my ($self, $content) = @_;

    # Check whether this was called procedurally or as a method, by looking to
    # see if the first value is an object.
    unless (blessed($self) && $self->isa('Text::Textile::Plaintext'))
    {
		$content = $self;
        $self = __PACKAGE__->new();
    }

    # Use the super-class to turn the Textile into HTML:
    my $html_content = $self->SUPER::textile($content);

    # Use the accessors to get the HTML::TreeBuilder and HTML::FormatText
    # objects, and use those to turn the HTML into text. This is also the
    # return value:
    $self->formatter->format($self->treebuilder->parse($html_content));
}

###############################################################################
#
#   Sub Name:       treebuilder
#
#   Description:    Get or set the instance of an HTML::TreeBuilder-compatible
#                   object to be used to parse/tokenize the HTML that
#                   Text::Textile produces.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $obj      in      ref       If present, new object to save
#
#   Returns:        current (new) attribute value
#
###############################################################################
sub treebuilder
{
    my ($self, $obj) = @_;

    (blessed $obj) ? $self->{__treebuilder} = $obj : $self->{__treebuilder};
}

###############################################################################
#
#   Sub Name:       formatter
#
#   Description:    Get or set the instance of an HTML::FormatText-compatible
#                   object to be used to convert the tokenized HTML to plain
#                   text.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $obj      in      ref       If present, new object to save
#
#   Returns:        current (new) attribute value
#
###############################################################################
sub formatter
{
    my ($self, $obj) = @_;

    (blessed $obj) ? $self->{__formatter} = $obj : $self->{__formatter};
}

1;

=head1 NAME

Text::Textile::Plaintext - Convert Textile mark-up to plain text

=head1 SYNOPSIS

    use Text::Textile::Plaintext qw(textile);

    my $textile = <<EOT;
    h1. Heading

    A _simple_ demonstration of Textile markup.

    * One
    * Two
    * Three

    "More information":http://www.textism.com/tools/textile is available.
    EOT

    # Procedural interface:
    my $text = textile($textile);
    print $text;

    # Object-oriented interface
    my $ttp = Text::Textile::Plaintext->new();
    $text = $ttp->process($textile);

=head1 DESCRIPTION

The B<Text::Textile::Plaintext> class extends B<Text::Textile> by running the
HTML content that it produces through instances of a tree-builder and a
formatter. By default, B<HTML::TreeBuilder> and B<HTML::FormatText> are used,
but classes that match their interfaces can be substituted.

The functionality provided by this module is identical to that of
B<Text::Textile>. Note that even the synopsis, above, is lifted directly from
there. The only difference is in the format of the output produced.

=head1 USAGE

As with B<Text::Textile>, this module's functionality may be used either
procedurally or via an object interface. You can import the textile() function
and call it without having to first instantiate an object instance. See below
for documentation on this function and its calling convention.

=head1 METHODS

The following methods are available within this class:

=over 4

=item new([%ARGS])

Create a new object of this class. The arguments detailed below, if present,
are stripped and processed by B<Text::Textile::Plaintext> while any remaining
arguments are passed to the super-class (B<Text::Textile>) constructor.

The arguments handled locally are:

=over 8

=item treebuilder

Provide a pre-instantiated instance of B<HTML::TreeBuilder> (or suitable
sub-class) to use in place of new() constructing one itself.

=item formatter

Provide a pre-instantiated instance of B<HTML::FormatText> (or suitable
sub-class) to use in place of new() constructing one itself.

=item leftmargin

=item rightmargin

These are passed directly to the constructor of B<HTML::FormatText>, unless you
passed in a specific formatter instance via the C<formatter> parameter, above.
The defaults for the margins are those set by B<HTML::FormatText> (3 for the
left margin, 72 for the right).

=back

Both of the objects (tree-builder and formatter) are kept until after the
parent constructor is called and the object re-blessed into the calling
class. At that point, the values are assigned to the object using the accessor
methods defined below. This allows a sub-class to overload the accessors and
handle these parameters.

=item textile($textile_content)

Convert the Textile mark-up in C<$textile_content> to plain text, and return
the converted content. This method is identical in nature and calling form
to the same-named method in the parent class. The difference is the production
of plain text rather than HTML.

This method may be imported and called as a function. In such a case, a
temporary B<Text::Textile::Plaintext> object is created and used to invoke
the needed parent class functionality.

=item treebuilder([$new])

Get or set the C<treebuilder> attribute.

If a value is given, it is assigned as the new value of the attribute. This
must be a reference to an object that is either an instance of
B<HTML::TreeBuilder>, or an instance of an object that matches its
interface. You can use this to assign a tree-builder that has debugging
capacity built into it, for example.

The return value is the current attribute value (after update).

=item formatter([$new])

Get or set the C<formatter> attribute.

If a value is given, it is assigned as the new value of the attribute. This
must be a reference to an object that is either an instance of
B<HTML::FormatText>, or an instance of an object that matches its
interface. You can use this to assign a formatter that has debugging capacity
built into it, for example.

The return value is the current attribute value (after update).

=back

Note that the method process() is not defined here, as it is inherited from
B<Text::Textile>.

=head1 DIAGNOSTICS

This module makes no effort to trap error messages or exceptions. Any output to
STDERR or STDOUT, or calls to C<warn> or C<die> by B<Text::Textile>,
B<HTML::TreeBuilder> or B<HTML::FormatText> will go through unchallenged unless
the user sets up their own exception-handling.

=head1 CAVEATS

In truth, Textile could be converted to text without first being turned into
HTML. But B<Text::Textile> does a good job of handling all the various
stylistic syntax that can affect things like paragraph justification, etc.,
and the other modules do their jobs quite well, too.

The B<HTML::FormatText> package has some quirks in the way things are laid-out,
such as bulleted lists.

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

L<Text::Textile>

=head1 AUTHOR

Randy J. Ray C<< <rjray@blackperl.com> >>

=cut
