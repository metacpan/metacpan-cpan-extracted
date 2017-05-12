package WebService::Riya;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use HTTP::Request::Common;
use LWP::UserAgent;
use URI;
use XML::LibXML;

our $VERSION = '0.01';

my $API_ROOT = 'http://www.riya.com/rest';

__PACKAGE__->mk_accessors(qw/user_name password api_key errstr status debug/);

sub new {
    my($class, %opt) = @_;
    my $self = bless {
        user_name => $opt{user_name},
        password  => $opt{password},
        api_key   => $opt{api_key},
    }, $class;
    $self->{ua} = LWP::UserAgent->new;
    return $self;
}

sub get_auth_token {
    my $self = shift;

    return $self->{token} if $self->{token};

    my $uri = URI->new($API_ROOT);
    $uri->query_form(
        user_name => $self->user_name,
        password  => $self->password,
        api_key   => $self->api_key,
        method    => 'riya.auth.GetToken',
    );
    my $response = $self->{ua}->get($uri->as_string);

    my $xml = XML::LibXML->new();
    my $doc = $xml->parse_string($response->content);

    $self->{token} = $doc->findvalue("//*[local-name()='token']");

    $self->errstr($doc->findvalue("//*[local-name()='error']/\@code"))
        unless $self->{token};

    return $self->{token};
}

sub call_method {
    my($self, $method, $opt) = @_;
   
    my $uri = URI->new($API_ROOT);
    my $req_param;
    $opt->{user_name}  = $self->user_name;
    $opt->{password}   = $self->password;
    $opt->{api_key}    = $self->api_key;
    $opt->{auth_token} = $self->get_auth_token();
    $opt->{method}     = $method;
    if (lc $method eq 'riya.photos.upload.uploadphoto') {
        $req_param = POST($API_ROOT, Content_Type => 'form-data', Content => [%$opt]);
    } else { 
        $uri->query_form($opt);
        $req_param = GET($uri->as_string);
    }
    my $response = $self->{ua}->request($req_param);

    warn $uri->as_string if $self->debug;

    return '' unless $response->content; 

    my $xml = XML::LibXML->new();
    my $doc = $xml->parse_string($response->content);
    
    $self->errstr($doc->findvalue("//*[local-name()='error']/\@code"));
    $self->status($self->errstr() ? 0 : 1);

    return $response->content;
}

1;
__END__

=head1 NAME

WebService::Riya - Perl interface to the Riya API

=head1 SYNOPSIS

  use WebService::Riya;
  
  my $api = WebService::Riya->new(
      api_key   => 'yourapikey',
      user_name => 'yourusername',
      password  => 'yourpassword',
  );

  my $response = $api->callMethod('riya.photos.search.SearchPublic', {
              'person' => 'david',
      });


=head1 DESCRIPTION

This module provides you Perl interface for Riya API.

Riya.com is photo sharing service.

=head1 METHODS

=head2 new([%options])

this method returns an instance of this module.
and this method allows following arguments;
- user_name (almost your email address for log in to Riya.com)
- password
- api_key

=head2 get_auth_token 

Get a token for using API.
this method uses riya.auth.GetToken of Riya.com API.

=head2 call_method

call Riya.com API.
seealso Riya.com API document. 

=head1 AUTHOR

Takatsugu Shigeta, E<lt>takatsugu.shigeta@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

==head1 SEE ALSO

L<http://www.riya.com/apiDoc>

=cut
