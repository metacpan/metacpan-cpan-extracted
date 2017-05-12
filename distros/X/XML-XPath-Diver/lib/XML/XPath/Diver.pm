package XML::XPath::Diver;
use 5.008005;
use strict;
use warnings;
use parent 'XML::XPath';
use XML::XPath::XMLParser;
use Class::Builtin ();

our $VERSION = "0.02";

sub dive {
    my ($self, $xpath) = @_;
    my $nodeset = $self->find($xpath);
    my @nodes = map {__PACKAGE__->new(xml => XML::XPath::XMLParser::as_string($_))} $nodeset->get_nodelist;
    wantarray ? @nodes : Class::Builtin->can('OO')->([@nodes]);
}

sub attr { 
    my ($self, $attr_name) = @_;
    my $nodeset = $self->find(sprintf('//@%s', $attr_name));
    my $node = $nodeset->shift;
    $node->getNodeValue;
}

sub text { shift->getNodeText(shift || '/')->value }

sub to_string { 
    my $self = shift;
    my $nodeset = $self->find('/');
    XML::XPath::XMLParser::as_string($nodeset->shift);
}

1;
__END__

=encoding utf-8

=head1 NAME

XML::XPath::Diver - Dive XML with XML::XPath and first-class collection + alpha

=head1 SYNOPSIS

    use XML::XPath::Diver;
    my $diver  = XML::XPath::Diver->new(...);  # same as XML::XPath;
    my $images = $diver->dive('//img');        # OMG! $images is Class::Builtin::Array class!
    my $urls   = $images->each(sub {
        my $node = shift;        # this is img element node, but XML::XPath::Diver object!
        $node->attr('src');      # return image url 
    });
    $urls->each(sub { say shift });  # say image url
    
    # as oneline
    $diver->dive('//img')->each(sub{ say shift->attr('src') });
    
    # or simple perl way
    my @images = $diver->dive('//img');
    my @urls = map { $_->attr('src') } @images;
    say $_ for @urls;
    

=head1 DESCRIPTION

XML::XPath::Diver is XML data parse tool class that inherits L<XML::XPath>.

=head1 METHODS

=head2 dive

    my $nodes = $diver->dive($xpath); # first-class collection (Class::Builtin::Array object)
    my @nodes = $diver->dive($xpath); # primitive array

Returns Class::Builtin::Array object or primitive array. These contains XML::XPath::Diver objects.

For this reason, It can as following.

    # case of first-class collection
    my $child_nodes = $nodes->each(sub{
        my $node = shift; # !!! This is a XML::XPath::Diver object !!!
        $node->dive($some_xpath);
    });
    
    # case of primitive array
    my @child_nodes = map {( $_->dive($some_xpath) )} @nodes;

=head1 attr

Returns string value of attribute that specified.

=head1 text

    my $str = $diver->text($xpath);

Returns string that contained in specified xpath element.

$xpath is default '/'.

=head1 to_string

Returns XML data as string.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

