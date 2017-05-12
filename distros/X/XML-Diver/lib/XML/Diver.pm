package XML::Diver;
use 5.008005;
use strict;
use warnings;
use parent 'XML::LibXML::XPathContext';
use XML::LibXML;
use Class::Builtin ();

our $VERSION = "0.01";

sub load_xml {
    my ($class, %opts) = @_;
    my $node = XML::LibXML->load_xml(%opts);
    $class->new($node);
}

sub dive {
    my ($self, $xpath) = @_;
    my $nodeset = $self->find($xpath);
    my @nodes = map {__PACKAGE__->load_xml(string => $_->toStringC14N)} $nodeset->get_nodelist;
    wantarray ? @nodes : Class::Builtin->can('OO')->([@nodes]);
}

sub attr { 
    my ($self, $attr_name) = @_;
    my $nodeset = $self->find(sprintf('//@%s', $attr_name));
    my $node = $nodeset->shift;
    $node->value;
}

sub text { shift->findvalue('/') }

sub to_string { 
    my $self = shift;
    my $nodeset = $self->find('/');
    $nodeset->shift->toStringC14N;
}

1;
__END__

=encoding utf-8

=head1 NAME

XML::Diver - Dive XML with XML and first-class collection + alpha

=head1 SYNOPSIS

    use XML::Diver;
    my $xml_str = ...;
    my $diver  = XML::Diver->load_xml(string => $xml_str); # same as XML::LibXML;
    my $images = $diver->dive('//img'); # $images is Class::Builtin::Array class!
    my $urls   = $images->each(sub {
        my $node = shift;        # this is img element node, but XML::Diver object!
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

XML::Diver is XML data parse tool class that inherits L<XML::LibXML::XPathContext>.

=head1 METHODS

=head2 dive

    my $nodes = $diver->dive($xpath); # first-class collection (Class::Builtin::Array object)
    my @nodes = $diver->dive($xpath); # primitive array

Returns Class::Builtin::Array object or primitive array. These contains XML::Diver objects.

For this reason, It can as following.

    # case of first-class collection
    my $child_nodes = $nodes->each(sub{
        my $node = shift; # !!! This is a XML::Diver object !!!
        $node->dive($some_xpath);
    });
    
    # case of primitive array
    my @child_nodes = map {( $_->dive($some_xpath) )} @nodes;

=head2 attr

Returns string value of attribute that specified.

=head2 text

    my $str = $diver->text($xpath);

Returns string that contained in specified xpath element.

$xpath is default '/'.

=head2 to_string

Returns XML data as string.

=head1 MOTIVE

I thought, I want a simple and easy XML parsing module. And its directivity are followings.

1. Parsable with XPath

2. Less Rules

3. Depth Preference Parsing

4. Iterative Processing to horizontally

5. Lightweight

Some months ago, I wrote XML::XPath::Diver as a concept release of above. But, that inherits L<XML::XPath>. L<XML::XPath> has been abandoned for a long time (Last update is 26 Jan. 2003). For this reason, I decided to remove its dependency.

Then, I wrote this module (without "XPath" string in dist-name!).

=head1 PERFORMANCE

300% or over faster than XML::XPath::Diver. See L<https://gist.github.com/ytnobody/10354590/>

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

