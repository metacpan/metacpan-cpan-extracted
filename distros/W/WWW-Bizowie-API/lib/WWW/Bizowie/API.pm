package WWW::Bizowie::API;

use strict;
use warnings;

use WWW::Bizowie::API::Response;
use LWP::UserAgent;
use HTTP::Request::Common;
use Try::Tiny;
use JSON;

our $VERSION = '0.02';

=head1 NAME

WWW::Bizowie::API - Perl interface to the Bizowie.com API

=head1 SYNOPSIS

  my $bz = WWW::Bizowie::API->new(
      api_key    => '02cc7058-cd22-4c8e-ad7c-a8f3f2a64bd0',
      secret_key => '58c57abc-1e16-3571-bb35-73876bcef746',
      site       => 'mysite.bizowie.com',
  );

  $bz->call(
      '/tickets/add_comment/0824', {
          comment => "I added this comment via the API!",
      },
  );

=head1 METHODS

=head2 new

Returns a new instance of WWW::Bizowie::API

Requires three parameters: api_key (your Bizowie API key), secret_key, and site (the hostname of your Bizowie instance).

=cut

sub new 
{
    my ($class, %params) = @_;

    my $bzua = LWP::UserAgent->new;
    $bzua->ssl_opts( verify_hostname => 0 ); 
    $bzua->agent('Bizowie::API');

    die 'site not specified'    unless $params{site};
    die 'api_key not specified' unless $params{api_key};
    die 'secret_key not specified' unless $params{secret_key};

    my $self = {
        ua         => $bzua,
        api_key    => $params{api_key},
        secret_key => $params{secret_key},
        site       => $params{site},
    };

    bless($self);

    return $self;
}

=head2 call

Makes a Bizowie API call.

Takes two a parameters: a string indicating the path to the API method you wish to call, and a has reference of the parameters to be passed.

=cut

sub call
{
    my ($self, $method, $params) = @_;

    my $site = $self->{site};

    die "[Bizowie::API] fatal error: no method given" unless $method;

    my $request = encode_json($params || { });

    my $q = $self->{ua}->request(POST("https://${site}/bz/api/$method",
         Content_Type => 'form-data',
         Content      => [
             api_key    => $self->{api_key},
             secret_key => $self->{secret_key},
             site       => $site,
             request    => $request,
         ])
    );

    my $o;
    {
        local $SIG{__DIE__} = sub { };
        try {
            $o = decode_json($q->decoded_content);
        } catch {       
            $o = { unprocessed => 1 };
        };
    }

    return WWW::Bizowie::API::Response->new(
        data    => $o,
        success => delete $o->{success} || 0,
    );
}

=head1 DEPENDENCIES

HTTP::Request::Common, LWP::UserAgent, Try::Tiny, JSON, Mo

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

