package WWW::LogicBoxes::Role::Command::Domain::Registration;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::LogicBoxes::Types qw( DomainRegistration Int );

use WWW::LogicBoxes::DomainRequest::Registration;

use Try::Tiny;
use Carp;

requires 'submit', 'get_domain_by_id';

our $VERSION = '1.10.0'; # VERSION
# ABSTRACT: Domain Registration API Calls

sub register_domain {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        request => { isa => DomainRegistration, coerce => 1 }
    );

    my $response = $self->submit({
        method => 'domains__register',
        params => $args{request}->construct_request(),
    });

    return $self->get_domain_by_id( $response->{entityid} );
}

sub delete_domain_registration_by_id {
    my $self = shift;
    my ( $domain_id ) = pos_validated_list( \@_, { isa => Int } );

    return try {
        $self->submit({
            method => 'domains__delete',
            params => {
                'order-id' => $domain_id,
            },
        });

        return;
    }
    catch {
        if( $_ =~ m/No Entity found for Entityid/ ) {
            croak 'No such domain to delete';
        }

        croak $_;
    };
}

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Role::Command::Domain::Registration - Domain Registration Related Operations

=head1 SYNOPSIS

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;
    use WWW::LogicBoxes::DomainRequest::Registration;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    # Creation
    my $registration_request = WWW::LogicBoxes::DomainRequest::Registration->new( ... );
    my $domain = $logic_boxes->register_domain( request => $registration_request );

    # Deletion
    $logic_boxes->delete_domain_registration_by_id( $domain->id );

=head1 REQUIRES

=over 4

=item submit

=item get_domain_by_id

=back

=head1 DESCRIPTION

Implements domain registration related operations with the L<LogicBoxes's|http://www.logicboxes.com> API.

=head1 METHODS

=head2 register_domain

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;
    use WWW::LogicBoxes::DomainRequest::Registration;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $registration_request = WWW::LogicBoxes::DomainRequest::Registration->new( ... );
    my $domain = $logic_boxes->register_domain( request => $registration_request );

Given a L<WWW::LogicBoxes::DomainRequest::Registration> or a HashRef that can be coreced into a L<WWW::LogicBoxes::DomainRequest::Registration>, attempts to register a domain with L<LogicBoxes|http://www.logicboxes.com>.

Returned is a fully formed L<WWW::LogicBoxes::Domain>.

=head2 delete_domain_registration_by_id

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    $logic_boxes->delete_domain_registration_by_id( $domain->id );

Given an Integer L<domain|WWW::LogicBoxes::Domain> id, deletes the specified domain registration.  There is a limited amount of time in which you can do this for a new order (typically between 24 and 72 hours) and if you do this too often then L<LogicBoxes|http://www.logicboxes.com> will get grumpy with you.

=cut
