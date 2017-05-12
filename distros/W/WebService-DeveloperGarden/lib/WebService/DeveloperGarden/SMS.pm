package WebService::DeveloperGarden::SMS;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str InstanceOf);
use JSON;
use URI::Escape;

has dg           => (is => 'ro',   isa => InstanceOf["WebService::DeveloperGarden"]);
has to           => (is => 'rwp',  isa => Str);
has from         => (is => 'rwp',  isa => Str);
has text         => (is => 'rwp',  isa => Str);
has uid          => (is => 'rwp',  isa => Str);
has scope        => (is => 'ro',   isa => Str, required => 1);
has environment  => (is => 'ro',   isa => Str, default => sub { 'budget' } );
has realm        => (is => 'ro',   isa => Str, default => sub { 'developergarden.com' } );
has sms_send_url => (is => 'lazy', isa => Str, default => sub {
    my $self = shift;
    sprintf 'https://gateway.developer.telekom.com/plone/sms/rest/%s/smsmessaging/v1/outbound/tel%%3A%s/requests',
        uri_escape( $self->environment ),
        uri_escape( $self->from );
} );

sub send {
    my ($self, %param) = @_;

    $self->dg->scope( $self->scope );
    $self->dg->auth;

    $self->_set_to( $param{to} )     if defined $param{to};
    $self->_set_from( $param{from} ) if defined $param{from};
    $self->_set_text( $param{text} ) if defined $param{text};
    $self->_set_uid( $param{uid} )   if defined $param{uid};

    my $http = HTTP::Tiny->new(
        agent           => 'WebService_DeveloperGarden_Perl_API',
        default_headers => {
            Authorization  => sprintf( 'OAuth realm="%s",oauth_token="%s"', $self->realm, $self->dg->access_token ),
            Accept         => 'application/json',
            'Content-Type' => 'application/json',
        },
    );

    my $result = $http->post(
        $self->sms_send_url,
        {
            content => JSON->new->allow_nonref->encode({
                outboundSMSMessageRequest => {
                    address                => [ "tel:" . $self->to ],
                    senderAddress          => "tel:" . $self->from,
                    outboundSMSTextMessage => {
                        message => $self->text,
                    },
                    outboundEncoding => '7bitGSM',
                    clientCorrelator => $self->uid,
                },
            }), 
        }
    );

    use Data::Dumper;
    print STDERR Dumper $result;
}

1;

__END__

=pod

=head1 NAME

WebService::DeveloperGarden::SMS

=head1 VERSION

version 0.01

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
