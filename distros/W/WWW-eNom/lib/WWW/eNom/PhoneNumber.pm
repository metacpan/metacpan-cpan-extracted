package WWW::eNom::PhoneNumber;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use overload '""' => \&_to_string, fallback => 1;

use WWW::eNom::Types qw( Str NumberPhone );

use Number::Phone;
use Carp;

our $VERSION = 'v2.7.0'; # VERSION
# ABSTRACT: Extendes Number::Phone to add 'number' functionatly (without country code)

has '_number_phone_obj' => (
    is       => 'ro',
    isa      => NumberPhone,
    required => 1,
);

has 'country_code' => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_country_code',
    lazy    => 1,
);

has 'number' => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_number',
    lazy    => 1,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args;
    if( scalar @_ > 1 ) {
        return $class->$orig( @_ );
    }
    else {
        $args = shift;
    }

    if( ref $args eq '' ) {
        return $class->$orig( _number_phone_obj => Number::Phone->new( $args ) );
    }
    elsif( ( ref $args ) =~ m/Number::Phone/ ) {
        return $class->$orig( _number_phone_obj => $args );
    }
    else {
        croak "Invalid params passed to $class";
    }
};

sub _build_country_code {
    my $self = shift;

    return $self->_number_phone_obj->country_code;
}

sub _build_number {
    my $self = shift;

    my $full_number = $self->_number_phone_obj->format;
    $full_number =~ s/[^\d]*//g;

    return substr( $full_number, length( $self->country_code ) );
}

sub _to_string {
    my $self = shift;

    return $self->country_code . $self->number;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

WWW::eNom::PhoneNumber - PhoneNumber object with eNom Compatable Formatting

=head1 SYNOPSIS

    use WWW::eNom::PhoneNumber;

    my $phone_number = WWW::eNom::PhoneNumber->new( '+18005551212' );


    use Number::Phone;
    use WWW::eNom::PhoneNumber;

    my $number_phone = Number::Phone->new( '+18005551212' );
    my $phone_number = WWW::eNom::PhoneNumber->new( $number_phone );

    print "My Phone Number is $phone_number \n";

=head1 DESCRIPTION

While L<Number::Phone> is an excellent library, there is a bit of inconsistency when it comes to international phone numbers and how to get the full number back out from the L<Number::Phone> object.  The purpose of this object is to abstract away those difficulties and provide a uniform way to work with phone numbers.

L<eNom|http://www.enom.com/APICommandCatalog/> is rather picky when it comes to phone numbers and this library exists to address that.  While you certainly can use this object as a consumer it should be noted that coercions and overloads exist so that it's not needed.  Anywhere that excepts a PhoneNumber will take a string or Number::Phone object and automagically convert it into a WWW::eNom::PhoneNumber.  When used as a string the full phone number is returned.

=head1 ATTRIBUTES

=head2 B<_number_phone_obj>

This private attribute contains an instance of L<Number::Phone>.  While you certainly can set it in the call to new, it's not necessary as an around BUILDARGS will take the values passed to new and ensure this attribute is set.

There really is no reason to do anything with this attribute.

=head2 country_code

Lazy built country code assoicated with the phone number.

=head2 number

Lazy built party number (the phone number without the country code) assoicated with the phone number.

=cut
