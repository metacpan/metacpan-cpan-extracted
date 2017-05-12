package WWW::LogicBoxes::Role::Command;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::LogicBoxes::Types qw( HashRef Str );

use JSON qw( decode_json );

use Try::Tiny;
use Carp;

requires 'response_type';
with 'WWW::LogicBoxes::Role::Command::Raw',
     'WWW::LogicBoxes::Role::Command::Contact',
     'WWW::LogicBoxes::Role::Command::Customer',
     'WWW::LogicBoxes::Role::Command::Domain',
     'WWW::LogicBoxes::Role::Command::Domain::Availability',
     'WWW::LogicBoxes::Role::Command::Domain::PrivateNameServer',
     'WWW::LogicBoxes::Role::Command::Domain::Registration',
     'WWW::LogicBoxes::Role::Command::Domain::Transfer';

our $VERSION = '1.9.0'; # VERSION
# ABSTRACT: Submission of LogicBoxes Commands

# Used to force json as the response_type and restore the existing type afterwards
around submit => sub {
    my $orig = shift;
    my $self = shift;
    my $args = shift;

    my $current_response_type = $self->response_type;

    my $response;
    try {
        if( $current_response_type ne 'json' ) {
            $self->response_type('json');
        }

        $response = $self->$orig( $args );
    }
    catch {
        croak $_;
    }
    finally {
        if($self->response_type ne $current_response_type) {
            $self->response_type($current_response_type);
        }
    };

    return $response;
};

sub submit {
    my $self   = shift;
    my (%args) = validated_hash(
        \@_,
        method => { isa => Str },
        params => { isa => HashRef, optional => 1 },
    );

    my $response;
    try {
        my $method   = $args{method};
        my $raw_json = $self->$method( $args{params} );

        if($raw_json =~ /^\d+$/) {
            # When just an id is returned, JSON is not used
            $response = { id => $raw_json };
        }
        elsif( $raw_json =~ m/^(?:true|false)$/i ) {
            # When just a true/false is returned, JSON is not used
            $response = { result => $raw_json };
        }
        elsif( $raw_json =~ m/^Success/i ) {
            $response = { result => $raw_json };
        }
        else {
            $response = decode_json( $raw_json );
        }
    }
    catch {
        croak "Error Making LogicBoxes Request: $_";
    };

    if(exists $response->{status} && lc $response->{status} eq "error") {
        if( exists $response->{message} ) {
            croak $response->{message};
        }
        elsif( exists $response->{error} ) {
            croak $response->{error};
        }

        croak 'Unknown error';
    }

    return $response;
}

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Role::Command - Basic Logic for Submission of Requests to LogicBoxes

=head1 SYNOPSIS

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Contact;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    my $contact     = WWW::LogicBoxes::Contact->new( ... );

    my $response = $logic_boxes->submit({
        method => 'contacts__add',
        params => $contact->construct_creation_request(),
    });

=head1 WITH

=over 4

=item L<WWW::LogicBoxes::Role::Command::Raw>

=item L<WWW::LogicBoxes::Role::Command::Contact>

=item L<WWW::LogicBoxes::Role::Command::Customer>

=item L<WWW::LogicBoxes::Role::Command::Domain>

=item L<WWW::LogicBoxes::Role::Command::Domain::Availability>

=item L<WWW::LogicBoxes::Role::Command::Domain::PrivateNameServer>

=item L<WWW::LogicBoxes::Role::Command::Domain::Registration>

=back

=head1 REQUIRES

response_type

=head1 DESCRIPTION

Primary interface to L<LogicBoxes|http://www.logicboxes.com> API that is used by the rest of the WWW::LogicBoxes::Role::Command::* roles.  The only reason a consumer would use the submit method directly would be if there was no corresponding Command for the needed operation.

=head1 METHODS

=head2 submit

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Contact;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    my $contact     = WWW::LogicBoxes::Contact->new( ... );

    my $response = $logic_boxes->submit({
        method => 'contacts__add',
        params => $contact->construct_creation_request(),  # Optional for some methods
    });

The submit method is what sends requests over to L<LogicBoxes|http://www.logicboxes.com>.  It accepts a L<raw method|WWW::LogicBoxes::Role::Command::Raw> and an optional HashRef of params (almost all methods require params to be provided, but not all do).  For details on the structure of the params please see L<WWW::LogicBoxes::Role::Command::Raw>.

The submit method returns a HashRef that represents the data returned by LogicBoxes.  There is logic built into submit such that requests are always made with a JSON response which is what drives the creation of the HashRef form the response.

=cut
