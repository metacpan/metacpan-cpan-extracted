require 5;

package XML::Element;
use warnings;
use strict;
use HTML::Tagset ();
use HTML::Element 4.1 ();
use Carp;

use vars qw(@ISA $VERSION);
$VERSION = '5.4';
@ISA     = ('HTML::Element');

# Init:
my %emptyElement = ();
foreach my $e (%HTML::Tagset::emptyElement) {
    $emptyElement{$e} = 1
        if substr( $e, 0, 1 ) eq '~' and $HTML::Tagset::emptyElement{$e};
}

my $in_cdata = 0;
my $nillio   = [];

#--------------------------------------------------------------------------
#Some basic overrides:

sub _empty_element_map { \%emptyElement }

*_fold_case      = \&HTML::Element::_fold_case_NOT;
*starttag        = \&starttag_XML;
*endtag          = \&endtag_XML;
*encoded_content = \$HTML::Element::encoded_content;
*_xml_escape     = \&HTML::Element::_xml_escape;

# TODO: override id with something that looks for xml:id too/instead?

#--------------------------------------------------------------------------

#TODO: test and document this:
# with no tagname set, assumes ALL all-whitespace nodes are ignorable!

sub delete_ignorable_whitespace {
    my $under_hash = $_[1];
    my (@to_do) = ( $_[0] );

    if ( $under_hash and ref($under_hash) eq 'ARRAY' ) {
        $under_hash = { map { ; $_ => 1 } @$under_hash };
    }

    my $all = !$under_hash;
    my ( $i, $this, $children );
    while (@to_do) {
        $this = shift @to_do;
        $children = $this->content || next;
        if ( ( $all or $under_hash->{ $this->tag } )
            and @$children )
        {
            for ( $i = $#$children; $i >= 0; --$i ) {

                # work backwards thru the list
                next if ref $children->[$i];
                if ( $children->[$i] =~ m<^\s*$>s ) {    # all WS
                    splice @$children, $i, 1;            # delete it.
                }
            }
        }
        unshift @to_do, grep ref($_), @$children;        # recurse
    }

    return;
}

## copied from HTML::Element to support CDATDA
sub starttag_XML {
    my ($self) = @_;

    # and a third parameter to signal emptiness?

    my $name = $self->{'_tag'};

    return $self->{'text'}               if $name eq '~literal';
    return '<!' . $self->{'text'} . '>'  if $name eq '~declaration';
    return "<?" . $self->{'text'} . "?>" if $name eq '~pi';

    if ( $name eq '~comment' ) {
        if ( ref( $self->{'text'} || '' ) eq 'ARRAY' ) {

            # Does this ever get used?  And is this right?
            $name = join( ' ', @{ $self->{'text'} } );
        }
        else {
            $name = $self->{'text'};
        }
        $name =~ s/--/-&#45;/g;    # can't have double --'s in XML comments
        return "<!-- $name -->";
    }

    if ( $name eq '~cdata' ) {
        $in_cdata = 1;
        return "<![CDATA[";
    }

    my $tag = "<$name";
    my $val;
    for ( sort keys %$self ) {     # predictable ordering
        next if !length $_ or m/^_/s or $_ eq '/';

        # Hm -- what to do if val is undef?
        # I suppose that shouldn't ever happen.
        next if !defined( $val = $self->{$_} );    # or ref $val;
        _xml_escape($val);
        $tag .= qq{ $_="$val"};
    }
    @_ == 3 ? "$tag />" : "$tag>";
}

## copied from HTML::Element to support CDATDA
sub endtag_XML {
    my ($self) = @_;

    # and a third parameter to signal emptiness?

    my $name = $self->{'_tag'};
    if ( $name eq '~cdata' ) {
        $in_cdata = 0;
        return "]]>";
    }

    "</$_[0]->{'_tag'}>";
}

## copied from HTML::Element to support CDATDA
sub as_XML {

    my ($self) = @_;

    #my $indent_on = defined($indent) && length($indent);
    my @xml               = ();
    my $empty_element_map = $self->_empty_element_map;

    my ( $tag, $node, $start );    # per-iteration scratch
    $self->traverse(
        sub {
            ( $node, $start ) = @_;
            if ( ref $node ) {     # it's an element
                $tag = $node->{'_tag'};
                if ($start) {      # on the way in

                    foreach my $attr ( $node->all_attr_names() ) {
                        croak("$tag has an invalid attribute name '$attr'")
                            unless ( $attr eq '/'
                            || $self->_valid_name($attr) );
                    }

                    if ( $empty_element_map->{$tag}
                        and !@{ $node->{'_content'} || $nillio } )
                    {
                        push( @xml, $node->starttag_XML( undef, 1 ) );
                    }
                    else {
                        push( @xml, $node->starttag_XML(undef) );
                    }
                }
                else {    # on the way out
                    unless ( $empty_element_map->{$tag}
                        and !@{ $node->{'_content'} || $nillio } )
                    {
                        push( @xml, $node->endtag_XML() );
                    }     # otherwise it will have been an <... /> tag.
                }
            }
            else {        # it's just text
                _xml_escape($node) unless ($in_cdata);
                push( @xml, $node );
            }
            1;            # keep traversing
        }
    );

    join( '', @xml, "\n" );
}

#--------------------------------------------------------------------------

1;

__END__

=head1 NAME

XML::Element - XML elements with the same interface as HTML::Element

=head1 SYNOPSIS

  [See HTML::Element]

=head1 METHODS AND ATTRIBUTES

=head2 delete_ignorable_whitespace

TODO: test and document this:
with no tagname set, assumes ALL all-whitespace nodes are ignorable!

=head2 endtag

Redirects to endtag_XML

=head2 starttag

Redirects to starttag_XML

=head2 as_XML

  $s = $doc->as_XML()

Returns a string representing in XML the element and its descendants.

=head2 starttag_XML

  $start = $doc->starttag_XML();

Returns a string representing the complete start tag for the element.
Except for CDATA.

=head2 endtag_XML

  $end = $doc->endtag_XML();

Returns a string representing the complete end tag for this element.
I.e., "</", tag name, and ">". Except for CDATA.


=head1 DESCRIPTION

This is just a subclass of HTML::Element.  It works basically the same
as HTML::Element, except that tagnames and attribute names aren't
forced to lowercase, as they are in HTML::Element.

L<HTML::Element> describes everything you can do with this class.

=head1 CAVEATS

Has currently no handling of namespaces.

=head1 SEE ALSO

L<XML::TreeBuilder> for a class that actually builds XML::Element
structures.

L<HTML::Element> for all documentation.

L<XML::DOM> and L<XML::Twig> for other XML document tree interfaces.

L<XML::Generator> for more fun.


=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2000,2004 Sean M. Burke.  All rights reserved.
Copyright (c) 2010,2011,2013 Jeff Fearn. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.


=head1 AUTHOR

Current Author:
	Jeff Fearn E<lt>jfearn@cpan.orgE<gt>.

Former Authors:
	Sean M. Burke, E<lt>sburke@cpan.orgE<gt>

=cut

