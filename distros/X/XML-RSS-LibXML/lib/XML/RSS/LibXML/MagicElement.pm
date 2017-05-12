# $Id$
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package XML::RSS::LibXML::MagicElement;
use strict;
use overload 
    bool => sub { 1 },
    '""' => \&toString,
    fallback => 1
;
use vars qw($VERSION);
$VERSION = '0.3105';

# Make UNIVERSAL::isa happy
sub isa { __PACKAGE__ eq ($_[1] || '') } 

sub new
{
    my $class = shift;
    my %args  = @_;

    my %attrs;
    my @attrs;
    my $attrs = $args{attributes};
    if (ref($attrs) eq 'ARRAY') {
        %attrs = map { (
            $_->prefix && $_->prefix ne 'xmlns' ?
                sprintf('%s:%s', $_->prefix, $_->localname || '') :
                $_->localname || ''
            , $_->getData
        ) } @$attrs;
        @attrs = map { $_->getName } @$attrs;
    } elsif (ref($attrs) eq 'HASH') {
        %attrs = %$attrs;
        @attrs = keys %$attrs;
    } else {
        die "'attributes' must be an arrayref of XML::LibXML::Attr objects, or a hashref of scalars";
    }

    return bless {
        %attrs,
        _attributes => \@attrs,
        _content => $args{content},
    }, $class;
}

sub attributes
{
    my $self = shift;
    return wantarray ? @{$self->{_attributes}} : $self->{_attributes};
}

sub toString
{
    my $self = shift;
    return (defined $self->{_content} && length $self->{_content}) ?
        $self->{_content} :
        join('', map { $self->{$_} || '' } $self->attributes);
}

1;

__END__

=head1 NAME

XML::RSS::LibXML::MagicElement - Represent A Non-Trivial RSS Element

=head1 SYNOPSIS

  us XML::RS::LibXML::MagicElement;
  my $xml = XML::RSS::LibXML::MagicElement->new(
    content => $textContent,
    attributes => \@attributes
  );

=head1 DESCRIPTION

This module is a handy object that allows users to access non-trivial
RSS elements in XML::RSS style. For example, suppose you have an RSS
feed with an element like the following:

  <channel>
    <title>Example</title>
    <tag attr1="foo" attr2="bar">baz</tag>
    ...
  </channel>

While it is simple to access the title element like this:

  $rss->{channel}->{title};

It was slightly non-trivial for the second tag. With this module, E<lt>tagE<gt>
is parsed as a XML::RSS::LibXML::MagicElement object and then you can access
all the elements like so:

  $rss->{channel}->{tag};  # "baz"
  $rss->{channel}->{tag}->{attr1}; # "foo"
  $rss->{channel}->{tag}->{attr2}; # "bar"

=head1 METHODS

=head2 new

Create a new MagicElement object.

=head2 attributes

Returns the list of attributes associated with this element

=head2 toString

Returns the string representation of this object. 
By default we use the "text content" of the found tag, but for XML::RSS 
compatibility, we use the concatenation of the attributes if no content is
found.

=head1 AUTHOR

Copyright 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>. All rights reserved.

Development partially funded by Brazil, Ltd. E<lt>http://b.razil.jpE<gt>

=cut
