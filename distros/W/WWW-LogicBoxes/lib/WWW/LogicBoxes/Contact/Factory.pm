package WWW::LogicBoxes::Contact::Factory;

use strict;
use warnings;

use MooseX::Params::Validate;

use WWW::LogicBoxes::Types qw( HashRef );

use WWW::LogicBoxes::Contact;
use WWW::LogicBoxes::Contact::CA;
use WWW::LogicBoxes::Contact::US;

use Carp;

our $VERSION = '1.10.1'; # VERSION
# ABSTRACT: Abstract Factory For Construction of Contacts

sub construct_from_response {
    my $self         = shift;
    my ( $response ) = pos_validated_list( \@_, { isa => HashRef } );

    if( $response->{type} eq 'CaContact' ) {
        return WWW::LogicBoxes::Contact::CA->construct_from_response( $response );
    }
    elsif( ( grep { $_ eq 'domus' } @{ $response->{contacttype} } )
        && exists $response->{ApplicationPurpose} && exists $response->{NexusCategory} ) {
        return WWW::LogicBoxes::Contact::US->construct_from_response($response);
    }
    else {
        return WWW::LogicBoxes::Contact->construct_from_response($response);
    }
}

1;

__END__

=pod

=head1 NAME

WWW::LogicBoxes::Contact::Factory - Factory for Construction of Contact Objects

=head1 SYNOPSIS

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Contact::Factory;

    my $api = WWW::LogicBoxes->new( ... );

    my $response = $api->submit({
        method => 'contacts__details',
        params => {
            'contact-id' => 42,
        },
    });

    my $contact = WWW::LogicBoxes::Contact::Factory->construct_from_response( $response );

=head1 DESCRIPTION

Abstract Factory that accepts the raw response from L<LogicBoxes|http://www.logicboxes.com> and returns a fully formed L<WWW::LogicBoxes::Contact> or one of it's subclasses.

=head1 METHODS

=head2 construct_from_response

    my $response = $api->submit({
        method => 'contacts__details',
        params => {
            'contact-id' => 42,
        },
    });

    my $contact = WWW::LogicBoxes::Contact::Factory->construct_from_response( $response );

Given a HashRef that is the JSON response from LogicBoxes when retrieving contact details, returns an instance of L<WWW::LogicBoxes::Contact> or one of it's subclasses.
