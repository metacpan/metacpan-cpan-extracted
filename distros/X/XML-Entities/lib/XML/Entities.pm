package XML::Entities;

use strict;
use 5.008;    # Unicode all over
use Carp;
use XML::Entities::Data;

our $VERSION = '1.0002';

eval { require HTML::Parser };  # for fast XS implemented _decode_entities

if (  eval { HTML::Entities::UNICODE_SUPPORT() }  ) {
    *_decode_entities = \&HTML::Entities::_decode_entities;
}
else {
    sub ord2chr {
        if (substr($_[0], 0, 1) eq 'x') {
            return chr(hex '0'.$_[0])
        }
        else {
            return chr($_[0])
        }
    }
    *_decode_entities = sub {
        my $hash = pop;
        $_[0] =~ s/ & (\#?) (\w+) \b (;?) /
            $1
            ? ord2chr($2)
            : exists $hash->{$2}
            ? $hash->{$2}
            : exists $hash->{$2.';'}
            ? $hash->{$2.';'}
            : '&'.$1.$2.$3
        /xeg;
    };
}

sub decode {
    my $set = shift;
    my @set_names = XML::Entities::Data::names;
    my $entity2char;
    if (ref $set eq 'HASH') {
        $entity2char = $set;
    }
    else {
        croak "'$set' is not a valid entity set name. Choose one of: all @set_names"
            if not grep {$_ eq $set} 'all', @set_names;
        no strict 'refs';
        $entity2char = "XML::Entities::Data::$set"->();
        use strict;
    }
    if (defined wantarray) { @_ = @_ };
    for (@_) {
        _decode_entities($_, $entity2char);
    }
    return @_[0 .. $#_]
}

sub numify {
    my $set = shift;
    my @set_names = XML::Entities::Data::names;
    my $entity2char;
    if (ref $set eq 'HASH') {
        $entity2char = $set;
    }
    else {
        croak "'$set' is not a valid entity set name. Choose one of: all @set_names"
            if not grep {$_ eq $set} 'all', @set_names;
        no strict 'refs';
        $entity2char = "XML::Entities::Data::$set"->();
        use strict;
    }
    if (defined wantarray) {
        @_ = @_;
    }
    my %set = %$entity2char;
    s/(?<= & )  ( [^\#] \w*? )  (?= ; )/
          exists $set{$1}
        ? '#'.ord($set{$1})
        : exists $set{$1.';'}
        ? '#'.ord($set{$1.';'})
        : $1
    /xeg for @_;
    return @_ if wantarray;
    return pop @_ if defined wantarray;
}

1

__END__

=encoding utf8

=head1 NAME

XML::Entities - Decode strings with XML entities

=head1 SYNOPSIS

 use XML::Entities;

 $a = "Tom &amp; Jerry &copy; Warner Bros&period;";
 $b = XML::Entities::decode('all', $a);
 $c = XML::Entities::numify('all', $a);
 # now $b is "Tom & Jerry © Warner Bros.
 # and $c is "Tom &#38; Jerry &#169; Warner Bros&#46;"

 # void context modifies the arguments
 XML::Entities::numify('all', $a);
 XML::Entities::decode('all', $a, $c);
 # Now $a, $b and $c all contain the decoded string

=head1 DESCRIPTION

Based upon the HTML::Entities module by Gisle Aas

This module deals with decoding of strings with XML
character entities.  The module provides two functions:

=over 4

=item decode( $entity_set, $string, ... )

This routine replaces XML entities from $entity_set found in the
$string with the corresponding Unicode character. Unrecognized
entities are left alone.

The $entity_set can either be a name of an entity set - the selection
of which can be obtained by XML::Entities::Data::names(), or "all" for
a union, or alternatively a hashref which maps entity names (without
leading &'s) to the corresponding Unicode characters (or strings).

If multiple strings are provided as argument they are each decoded
separately and the same number of strings are returned.

If called in void context the arguments are decoded in-place.

Note: If your version of C<HTML::Parser> was built without Unicode support, then
C<XML::Entities> uses a regular expression to do the decoding, which is slower.

=item numify( $entity_set, $string, ... )

This functions converts named XML entities to numeric XML entities. It is less
robust than the C<decode> function in the sense that it doesn't capture
improperly terminated entities. It behaves like C<decode> in treating parameters
and returning values.

=back

=head2 XML::Entities::Data

The list of entities is defined in the XML::Entities::Data module.
The list can be generated from the w3.org definition (or any other).
Check C<perldoc XML::Entities::Data> for more details.

=head2 Encoding entities

The HTML::Entities module provides a function for encoding entities. You just
have to assign the right mapping to the C<%HTML::Entities::char2entity> hash.
So, to encode everything that XML::Entities knows about, you'd say:

 use XML::Entities;
 use HTML::Entities;
 %HTML::Entities::char2entity = %{
    XML::Entities::Data::char2entity('all');
 };
 my $encoded = encode_entities('tom&jerry');
 # now $encoded is 'tom&amp;jerry'

=head1 SEE ALSO

HTML::Entities, XML::Entities::Data

=head1 COPYRIGHT

Copyright 2012 Jan Oldrich Kruza E<lt>sixtease@cpan.orgE<gt>. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
