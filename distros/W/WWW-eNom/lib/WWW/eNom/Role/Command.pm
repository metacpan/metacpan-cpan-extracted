package WWW::eNom::Role::Command;

use strict;
use warnings;
use utf8;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( HashRef Str );

use Try::Tiny;
use Carp;

requires 'response_type';
with 'WWW::eNom::Role::Command::Raw',
     'WWW::eNom::Role::Command::Contact',
     'WWW::eNom::Role::Command::Domain',
     'WWW::eNom::Role::Command::Domain::Availability',
     'WWW::eNom::Role::Command::Domain::Registration',
     'WWW::eNom::Role::Command::Domain::Transfer',
     'WWW::eNom::Role::Command::Domain::PrivateNameServer',
     'WWW::eNom::Role::Command::Service';

our $VERSION = 'v2.7.0'; # VERSION
# ABSTRACT: Submission of eNom Commands

# Used to force xml_simple response type and restore the existing type afterwards
around submit => sub {
    my ( $orig, $self, $args ) = @_;

    my $current_response_type = $self->response_type;

    my $response;
    try {
        if( $current_response_type ne 'xml_simple' ) {
            $self->response_type( 'xml_simple' );
        }

        $response = $self->$orig( $args );
    }
    catch {
        croak $_;
    }
    finally {
        if( $self->response_type ne $current_response_type ) {
            $self->response_type( $current_response_type );
        }
    };
};

sub submit {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        method => { isa => Str },
        params => { isa => HashRef },
    );

    my $response;
    try {
        my $method = $args{method};
        $response  = $self->$method( $args{params} );
    }
    catch {
        croak "Error making eNom request: $_";
    };

    return $response;
}

1;

__END__

=pod

=head1 NAME

WWW::eNom::Role::Command - Basic Logic for Submission of Requests to eNom

=head1 SYNOPSIS

    use WWW::eNom;

    my $eNom     = WWW::eNom->new( ... );
    my $response = $eNom->submit({
        method => 'Check',
        params => {
            DomainList => 'drzigman.com, drzigman.net, enom.biz',
        }
    });

=head1 WITH

=over 4

=item L<WWW::eNom::Role::Command::Raw>

=item L<WWW::eNom::Role::Command::Contact>

=item L<WWW::eNom::Role::Command::Domain>

=item L<WWW::eNom::Role::Command::Domain::Availability>

=item L<WWW::eNom::Role::Command::Domain::Registration>

=item L<WWW::eNom::Role::Command::Domain::Transfer>

=item L<WWW::eNom::Role::Command::Domain::PrivateNameServer>

=item L<WWW::eNom::Role::Command::Service>

=back

=head1 REQUIRES

response_type

=head1 DESCRIPTION

Primary interface to L<eNom|http://www.enom.com/APICommandCatalog/> API that is used by the rest of the WWW::eNom::Role::Command::* roles.  The only reason a consumer would use the submit method directly would be if there was no corresponding Command for the needed operation.

=head1 METHODS

=head2 submit

    use WWW::eNom;

    my $eNom     = WWW::eNom->new( ... );
    my $response = $eNom->submit({
        method => 'Check',
        params => {
            DomainList => 'drzigman.com, drzigman.net, enom.biz',
        }
    });

The submit method is what sends requests over to L<eNom|http://www.enom.com/APICommandCatalog/>.  It accepts a L<raw method|WWW::eNom::Role::Command::Raw> and an HashRef of params.  For details on the structure of the params please see L<WWW::eNom::Role::Command::Raw>.

The submit method returns a HashRef that represents the data returned by eNom.  There is logic built into submit such that requests are always made with an xml_simple response_type which is what drives the creation of the HashRef to form the response.

=cut
