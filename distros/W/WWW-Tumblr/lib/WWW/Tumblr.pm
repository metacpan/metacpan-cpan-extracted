package WWW::Tumblr;

use strict;
use warnings;

our $VERSION = '5.2';

=pod

=head1 NAME

WWW::Tumblr - Perl bindings for the Tumblr API

=head1 VERSION

5.00

=head1 SYNOPSIS

  my $t = WWW::Tumblr->new(
     consumer_key    => $consumer_key,
     secret_key      => $secret_key,
     token           => $token,
     token_secret    => $token_secret,
  );
 
  my $blog = $t->blog('perlapi.tumblr.com');

  print Dumper $blog->info;

=head1 DESCRIPTION

This module makes use of some sort of the same models as the upstream API,
meaning that you will have User, Blog and Tagged methods:

  my $t = WWW::Tumblr->new(
    consumer_key    => $consumer_key,
    secret_key      => $secret_key,
    token           => $token,
    token_secret    => $token_secret,
  );

  # Once you have a WWW::Tumblr object, you can get a WWW::Tumblr::Blog object
  # by calling the blog() method from the former object:
  
  my $blog = $t->blog('perlapi.tumblr.com');
 
  # And then just use WWW::Tumblr::Blog methods from it:
  if ( my $post = $blog->post( type => 'text', body => 'Hell yeah, son!' ) ) {
     say "I have published post id: " . $post->{id};    
  } else {
     print STDERR Dumper $blog->error;
     die "I couldn't post it :(";
  }

You can also work directly with a L<WWW::Tumblr::Blog> class for example:

  # You will need to set base_hostname:
  my $blog = WWW::Tumblr::Blog->new(
     %four_tokens,
     base_hostname => 'myblogontumblr.com'
  );

All operation methods on the entire API will return false in case of an
upstream error and you can check the status with C<error()>:

  die Dumper $blog->error unless $blog->info();

On success, methods will return a hash reference with the JSON representation
of the upstream response. This behavior has not changed from previous versions
of this module.

=head1 METHOD PARAMETERS

All methods require the same parameters as the upstream API, passed as hash
where the keys are the request parameters and the values the corresponding
data.

=head1 DOCUMENTATION

Please refer to each module for further tips, tricks and slightly more detailed
documentation:

=over

=item *

L<WWW::Tumblr::Blog>

=item *

L<WWW::Tumblr::User>

=item *

L<WWW::Tumblr::Tagged>

=item *

L<WWW::Tumblr::ResponseError>

=back

Take also a look at the C<t/> directory inside the distribution. There you can see
how you can do a bunch of things: get posts, submissions, post quotes, text,
etc, etc.

=head1 AUTHORIZATION

It is possible to generate authorization URLs and do the whole OAuth dance. Please
refer to the C<examples/> directory within the distribution to learn more.

=head1 CAVEATS

This is considered an experimental version of the module. The request engine
needs a complete rewrite, as well as proper documentation. The main author of the
module wanted to release it like this to have people interested on Tumblr and Perl
give it a spin.

=head1 BUGS

Please report as many as you want/can. File them up at GitHub:
L<https://github.com/damog/www-tumblr/issues/new>. Please don't use the CPAN RT.

=head1 MODULE AND TUMBLR API VERSION NOTE

This module supports Tumblr API v2, starting from module version 5. Since the
previous API was deprecated upstream anyway, there's no backwards compatibility
with < 5 versions.

=head1 AUTHOR(S)

L<David Moreno|http://damog.net/> is the main author and maintainer of this module.
The following amazing people have also contributed from version 5 onwards: Artem
Krivopolenov, Squeeks, Fernando Vezzosi.

=head1 SEE ALSO

=over

=item *

L<Net::OAuth> because, you know, we're based off it.

=item *

L<Moose>, likewise.

=back

=head1 COPYRIGHT and LICENSE

This software is copyright (c) 2013 by David Moreno.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER

The author is in no way affiliated to Tumblr or Yahoo! Inc. If either of them
want to show their appreciation for this work, they can contact the author directly
or donate a few of those billion dollars Yahoo! paid for Tumblr, to the Perl
Foundation at L<http://donate.perlfoundation.org/>.

=cut

use Moose;
use Carp;
use Data::Dumper;
use HTTP::Request::Common;
use Net::OAuth::Client;
use WWW::Tumblr::API;
use WWW::Tumblr::Blog;
use WWW::Tumblr::User;
use WWW::Tumblr::Authentication;
use LWP::UserAgent;

has 'consumer_key',     is => 'rw', isa => 'Str';
has 'secret_key',       is => 'rw', isa => 'Str';
has 'token',            is => 'rw', isa => 'Str';
has 'token_secret',     is => 'rw', isa => 'Str';

has 'callback',         is => 'rw', isa => 'Str';
has 'error',            is => 'rw', isa => 'WWW::Tumblr::ResponseError';
has 'ua',               is => 'rw', isa => 'LWP::UserAgent', default => sub { LWP::UserAgent->new };

has 'session_store',	is => 'rw', isa => 'HashRef', default => sub { {} };

has 'oauth',            is => 'rw', isa => 'Net::OAuth::Client', default => sub {
	my $self = shift;
	Net::OAuth::Client->new(
		$self->consumer_key,
		$self->secret_key,
		request_token_path => 'http://www.tumblr.com/oauth/request_token',
		authorize_path => 'http://www.tumblr.com/oauth/authorize',
		access_token_path => 'http://www.tumblr.com/oauth/access_token',
		callback => $self->callback, 
		session => sub { if (@_ > 1) { $self->_session($_[0] => $_[1]) }; return $self->_session($_[0]) },
	);
};

sub user {
    my ( $self ) = shift;
    return WWW::Tumblr::User->new({
        consumer_key    => $self->consumer_key,
        secret_key      => $self->secret_key,
        token           => $self->token,
        token_secret    => $self->token_secret,
    });
}

sub blog {
    my ( $self ) = shift;
    my $name = shift or croak "A blog host name is needed.";

    return WWW::Tumblr::Blog->new({
        consumer_key    => $self->consumer_key,
        secret_key      => $self->secret_key,
        token           => $self->token,
        token_secret    => $self->token_secret,
        base_hostname   => $name,
    });
}

sub tagged {
    my $self = shift;
    my $args = { @_ };

    return $self->_tumblr_api_request({
        auth => 'apikey',
        http_method => 'GET',
        url_path => 'tagged',
        extra_args => $args,
    });
}

sub oauth_tools {
	my ( $self ) = shift;
	return WWW::Tumblr::Authentication::OAuth->new(
		consumer_key    => $self->consumer_key,
        secret_key      => $self->secret_key,
        callback		=> $self->callback,
	);
}

sub _tumblr_api_request {
    my $self    = shift;
    my $r       = shift; #args

    my $method_to_call = '_' . $r->{auth} . '_request';
    return $self->$method_to_call(
        $r->{http_method}, $r->{url_path}, $r->{extra_args}
    );
}

sub _none_request {
    my $self        = shift;
    my $method      = shift;
    my $url_path    = shift;
    my $params      = shift;

    my $req;
    if ( $method eq 'GET' ) {
        print "Requesting... " .'http://api.tumblr.com/v2/' . $url_path, "\n";
        $req = HTTP::Request->new(
            $method => 'http://api.tumblr.com/v2/' . $url_path,
        );
    } elsif ( $method eq 'POST' ) {
        Carp::croak "Unimplemented";
    } else {
        die "dude, wtf.";
    }

    my $res = $self->ua->request( $req );

    if ( my $prev = $res->previous ) {
        return $prev;
    } else { return $res };
}

sub _apikey_request {
    my $self        = shift;
    my $method      = shift;
    my $url_path    = shift;
    my $params      = shift;

    my $req; # request object
    if ( $method eq 'GET' ) {
        $req = HTTP::Request->new(
            $method => 'http://api.tumblr.com/v2/' . $url_path . '?api_key='.$self->consumer_key . '&' .
            ( join '&', map { $_ .'='. $params->{ $_} } keys %$params )
        );
    } elsif ( $method eq 'POST' ) {
        Carp::croak "Unimplemented";
    } else {
        die "$method misunderstood";
    }

    my $res = $self->ua->request( $req );

}

sub _oauth_request {
	my $self = shift;
	my $method = shift;
	my $url_path= shift;
	my $params = shift;

    my $data = delete $params->{data};

	my $request = $self->oauth->_make_request(
		'protected resource', 
		request_method => uc $method,
		request_url => 'http://api.tumblr.com/v2/' . $url_path,
		consumer_key => $self->consumer_key,
	    consumer_secret => $self->secret_key,
		token => $self->token,
		token_secret => $self->token_secret,
		extra_params => $params,
	);
	$request->sign;

    my $authorization_signature = $request->to_authorization_header;

    my $message;
    if ( $method eq 'GET' ) {
        $message = GET 'http://api.tumblr.com/v2/' . $url_path . '?' . $request->normalized_message_parameters, 'Authorization' => $authorization_signature;
    } elsif ( $method eq 'POST' ) {
        $message = POST('http://api.tumblr.com/v2/' . $url_path,
            Content_Type => 'form-data',
            Authorization => $authorization_signature,
            Content => [
                %$params, ( $data ? do {
                   if (ref($data) eq 'ARRAY') {
                      my $i = -1;
                      map { $i++; 'data[' . $i .']' => [ $_ ] } @$data
                   } else {
                     'data' => [ $data ]
                   }
                } : () )
            ]);
    }

	return $self->ua->request( $message );
}

sub _session {
	my $self = shift;

	if ( ref $_[0] eq 'HASH' ) {
		$self->session_store($_[0]);
	} elsif ( @_ > 1 ) {
		$self->session_store->{$_[0]} = $_[1]
	}
	return $_[0] ? $self->session_store->{$_[0]} : $self->session_store;
}

1;

