package Test::XML::Element;

use strict;
use warnings;

use 5.008;

our $VERSION = '0.01';

use base 'Test::Builder::Module';
our @EXPORT = qw( element_is has_attribute attribute_is );

use XML::Simple;

sub element_is {
    my $tb = Test::XML::Element->builder;
    my ($element, $name, $msg) = @_;

    my $xml = XMLin($element, KeepRoot => 1);
    return $tb->ok(exists $xml->{$name}, $msg);
}

sub has_attribute {
    my $tb = Test::XML::Element->builder;
    my ($element, $attribute, $msg) = @_;

    my $xml = XMLin($element);
    return $tb->ok(exists $xml->{$attribute}, $msg);
}

sub attribute_is {
    my $tb = Test::XML::Element->builder;
    my ($element, $attribute, $value, $msg) = @_;

    my $xml = XMLin($element);
    return $tb->ok(defined $xml->{$attribute} &&
                       $xml->{$attribute} eq $value, $msg);
}

1;

=head1 NAME

Test::XML::Element - Test the properties a single XML element in isolation.

=head1 VERSION

0.01

=head1 SYNOPSIS

    use Test::XML::Element tests => 4;
    element_is('<foobar />', "foobar")
    has_attribute('<foobar color="red" />', 'color');
    attribute_has_value('<foobar color="red">', color => 'red');

=head1 DESCRIPTION

This module allows you to test the properties of a single XML element on it's
own, which may be useful if your module does XML generation.

=head1 TESTS

=head2 element_is $element, $name, [$message]

Test that an element is of the correct type.

=head2 has_attribute $element, $attribute, [$message]

Check that an element has a certain attribute

=head2 attribute_is $element, $attribute, $value, [$message]

Check that an attribute has a certain attribute, and it is set to a certain
value.

=head1 AUTHOR

Oliver Charles C<< oliver.g.charles@googlemail.com >>

=head1 COPYRIGHT

Copyright 2009 Oliver Charles

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
