#
# Copyright (C) 1998, 1999 Ken MacLeod
# XML::Grove::AsCanonXML is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: AsCanonXML.pm,v 1.6 1999/08/17 18:36:20 kmacleod Exp $
#

use strict;

package XML::Grove::AsCanonXML;
use vars qw{%char_entities};
use Data::Grove::Visitor;

%char_entities = (
    "\x09" => '&#9;',
    "\x0a" => '&#10;',
    "\x0d" => '&#13;',
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
);

sub new {
    my $class = shift;
    my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };

    return bless $self, $class;
}

sub as_canon_xml {
    my $self = shift; my $object = shift; my $fh = shift;

    if (defined $fh) {
	return ();
    } else {
	return join('', $object->accept($self, $fh));
    }
}

sub visit_document {
    my $self = shift; my $document = shift;

    return $document->children_accept($self, @_);
}

sub visit_element {
    my $self = shift; my $element = shift; my $fh = shift;

    my @return;
    push @return, $self->_print($fh, '<' . $element->{Name});
    my $key;
    my $attrs = $element->{Attributes};
    foreach $key (sort keys %$attrs) {
	push @return, $self->_print($fh,
		      " $key=\"" . $self->_escape($attrs->{$key}) . '"');
    }
    push @return, $self->_print($fh, '>');

    push @return, $element->children_accept($self, $fh, @_);

    push @return, $self->_print($fh, '</' . $element->{Name} . '>');

    return @return;
}

sub visit_entity {
    # entities don't occur in text
    return ();
}

sub visit_pi {
    my $self = shift; my $pi = shift; my $fh = shift;

    return $self->_print($fh, '<?' . $pi->{Target} . ' ' . $pi->{Data} . '?>');
}

sub visit_comment {
    my $self = shift; my $comment = shift; my $fh = shift;

    if ($self->{Comments}) {
	return $self->_print($fh, '<!--' . $comment->{Data} . '-->');
    } else {
	return ();
    }
}

sub visit_characters {
    my $self = shift; my $characters = shift; my $fh = shift;

    return ($self->_print($fh, $self->_escape($characters->{Data})));
}

sub _print {
    my $self = shift; my $fh = shift; my $string = shift;

    if (defined $fh) {
	$fh->print($string);
	return ();
    } else {
	return ($string);
    }
}

sub _escape {
    my $self = shift; my $string = shift;

    $string =~ s/([\x09\x0a\x0d&<>"])/$char_entities{$1}/ge;
    return $string;
}

package XML::Grove;

sub as_canon_xml {
    my $xml_object = shift;

    return XML::Grove::AsCanonXML->new(@_)->as_canon_xml($xml_object);
}

1;

__END__

=head1 NAME

XML::Grove::AsCanonXML - output XML objects in canonical XML

=head1 SYNOPSIS

 use XML::Grove::AsCanonXML;

 # Using as_canon_xml method on XML::Grove objects:
 $string = $xml_object->as_canon_xml( OPTIONS );

 # Using an XML::Grove::AsCanonXML instance:
 $writer = XML::Grove::AsCanonXML->new( OPTIONS );

 $string = $writer->as_canon_xml($xml_object);
 $writer->as_canon_xml($xml_object, $file_handle);

=head1 DESCRIPTION

C<XML::Grove::AsCanonXML> will return a string or write a stream of
canonical XML for an XML object and it's content (if any).

C<XML::Grove::AsCanonXML> objects hold the options used for writing
the XML objects.  Options can be supplied when the the object is
created,

    $writer = XML::Grove::AsCanonXML->new( Comments => 1 );

or modified at any time before writing an XML object by setting the
option directly in the `C<$writer>' hash.

=head1 OPTIONS

=over 4

=item Comments

By default comments are not written to the output.  Setting comment to
TRUE will include comments in the output.

=back

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), XML::Parser(3), XML::Grove(3).

James Clark's Canonical XML definition
<http://www.jclark.com/xml/canonxml.html>

=cut
