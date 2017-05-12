package Test::Magpie::Util;
{
  $Test::Magpie::Util::VERSION = '0.11';
}
# ABSTRACT: Internal utility functions for Test::Magpie

use strict;
use warnings;

# smartmatch dependencies
use 5.010001;
use experimental qw( smartmatch );

use Exporter qw( import );
use Scalar::Util qw( blessed looks_like_number refaddr );
use Moose::Util qw( find_meta );

our @EXPORT_OK = qw(
    extract_method_name
    get_attribute_value
    has_caller_package
    match
);


sub extract_method_name {
    my ($method_name) = @_;
    $method_name =~ s/.*:://;
    return $method_name;
}


sub get_attribute_value {
    my ($object, $attribute) = @_;

    return find_meta($object)
        ->find_attribute_by_name($attribute)
        ->get_value($object);
}


sub has_caller_package {
    my $package= shift;

    my $level = 1;
    while (my ($caller) = caller $level++) {
        return 1 if $caller eq $package;
    }
    return;
}


sub match {
    my ($a, $b) = @_;

    # This function uses smart matching, but we need to limit the scenarios
    # in which it is used because of its quirks.

    # ref types must match
    return if ref($a) ne ref($b);

    # objects match only if they are the same object
    if (blessed($a) || ref($a) eq 'CODE') {
        return refaddr($a) == refaddr($b);
    }

    # don't smartmatch on arrays because it recurses
    # which leads to the same quirks that we want to avoid
    if (ref($a) eq 'ARRAY') {
        return if $#{$a} != $#{$b};

        # recurse to handle nested structures
        foreach (0 .. $#{$a}) {
            return if !match( $a->[$_], $b->[$_] );
        }
        return 1;
    }

    # smartmatch only matches hash keys
    # but we want to match the values too
    if (ref($a) eq 'HASH') {
        return unless $a ~~ $b;

        foreach (keys %$a) {
            return if !match( $a->{$_}, $b->{$_} );
        }
        return 1;
    }

    # avoid smartmatch doing number matches on strings
    # e.g. '5x' ~~ 5 is true
    return if looks_like_number($a) xor looks_like_number($b);

    return $a ~~ $b;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Magpie::Util - Internal utility functions for Test::Magpie

=head1 FUNCTIONS

=head2 extract_method_name

    $method_name = extract_method_name($full_method_name)

From a fully qualified method name such as Foo::Bar::baz, will return
just the method name (in this example, baz).

=head2 get_attribute_value

    $value = get_attribute_value($object, $attr_name)

Gets value of Moose attributes that have no accessors by accessing the class'
underlying meta-object.

=head2 has_caller_package

    $bool = has_caller_package($package_name)

Returns whether the given C<$package> is in the current call stack.

=head2 match

    $bool = match($a, $b)

Match 2 values for equality.

=head1 AUTHORS

=over 4

=item *

Oliver Charles <oliver.g.charles@googlemail.com>

=item *

Steven Lee <stevenwh.lee@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Oliver Charles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
