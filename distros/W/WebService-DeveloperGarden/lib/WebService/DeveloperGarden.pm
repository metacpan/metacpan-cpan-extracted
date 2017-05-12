package WebService::DeveloperGarden;

# ABSTRACT: Use DeveloperGarden APIs from Perl

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str);
use JSON;
use HTTP::Tiny;
use MIME::Base64;

our $VERSION = 0.01;

has client_id     => (is => 'ro',  isa => Str);
has client_secret => (is => 'ro',  isa => Str);
has client_base64 => (is => 'rwp', isa => Str);
has access_token  => (is => 'rwp', isa => Str);
has token_type    => (is => 'rwp', isa => Str);
has scope         => (is => 'rw', isa => Str, default => sub { 'DG-Webservice-Perl' } );
has auth_url      => (is => 'ro',  isa => Str, default => sub { 'https://global.telekom.com/gcp-web-api/oauth' } );

sub auth {
    my $self = shift;

    my $base64 = encode_base64 join ':', $self->client_id, $self->client_secret;
    $base64    =~ s/\s//g;
    $self->_set_client_base64( $base64 );

    my $http = HTTP::Tiny->new(
        agent           => 'WebService_DeveloperGarden_Perl_API',
        default_headers => {
            Authorization => 'Basic ' . $self->client_base64,
            Accept        => 'application/json',
        },
    );

    my $result = $http->post_form(
        $self->auth_url,
        {
            grant_type => 'client_credentials',
            scope      => $self->scope,
        },
    );

    if ( $result->{success} ) {
        my $perl = JSON->new->allow_nonref->decode( $result->{content} );

        $self->_set_access_token( $perl->{access_token} );
        $self->_set_token_type( $perl->{token_type} );
    }
}

my %map = (
    sms => 'SMS',
);

no strict 'refs';
for my $api (qw(sms)) {
    *{__PACKAGE__ . "::" . $api} = sub {
        my $self = shift;

        my @namespace = qw(WebService DeveloperGarden);

        my $file   = join '/', @namespace, $map{$api};
           $file  .= '.pm';

        my $module = join '::', @namespace, $map{$api};
        require $file;

        return $module->new( dg => $self, @_ );
    };
}

1;

__END__

=pod

=head1 NAME

WebService::DeveloperGarden - Use DeveloperGarden APIs from Perl

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use WebService::DeveloperGarden;
    
    my $dg = WebService::DeveloperGarden->new(
        client_id     => $client_id,
        client_secret => $client_secret,
    );

    # send a sms
    my $sms_sender = $dg->sms;

    # use features of "premium" environment
    # my $sms_sender = $dg->sms( environment => 'premium' );

    $sms_sender->send(
        to   => $recipient_phone_number,
        from => $your_phone_number,
        text => $text_of_sms,
        uid  => $unique_id_for_sms, # optional
    );

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
