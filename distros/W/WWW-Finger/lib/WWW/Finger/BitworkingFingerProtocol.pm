package WWW::Finger::BitworkingFingerProtocol;

use 5.010;
use common::sense;
use utf8;

use Carp 0;
use JSON 2.00;
use LWP::UserAgent 0;
use URI 0;
use URI::Escape 0;

use parent qw(WWW::Finger);

BEGIN {
	$WWW::Finger::BitworkingFingerProtocol::AUTHORITY = 'cpan:TOBYINK';
	$WWW::Finger::BitworkingFingerProtocol::VERSION   = '0.105';
}

sub speed { 105 }

sub new
{
	my $class = shift;
	my $ident = shift or croak "Need to supply an account address\n";
	my $self  = bless {}, $class;

	$ident = "mailto:$ident"
		unless $ident =~ /^[a-z0-9\.\-\+]+:/i;
	$ident = URI->new($ident);
	return undef
		unless $ident->scheme =~ /^(mailto|acct|xmpp)$/;

	$self->{'ident'} = $ident;
	my ($user, $host) = split /\@/, $ident->authority;
	if ("$ident" =~ /^(acct|mailto|xmpp)\:([^\s\@]+)\@([a-z0-9\-\.]+)$/i)
	{
		$user = $2;
		$host = $3;
	}
	
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	$ua->env_proxy;
	$ua->default_header('Accept' => 'application/json');
	
	my $host_get  = $ua->get("http://$host/.well-known/finger");	
	return undef unless $host_get->is_success;
	### Joe's own server sends the wrong response type :-(
	### return undef unless $host_get->content_type =~ m#^application/(\S+\+)?json$#i;
	
	my $host_data = from_json( $host_get->decoded_content );
	my $template  = $host_data->{'finger'};
	
	return undef unless length $template;
	
	my $profile   = $template;
	$profile =~ s/\{local\}/$user/i;
	
	my $profile_get = $ua->get($profile, 'Accept'=>'application/json, application/rdf+xml, text/turtle');
	return undef unless $profile_get->is_success;

	if ($profile_get->content_type =~ /(rdf|turtle|n3)/i)
	{
		$self = WWW::Finger::_GenericRDF->_new_from_response($ident, $profile_get);
	}
	else ### Joe's own server sends the wrong response type :-(
	{
		$self->{'profile_uri'} = $profile;
		$self->{'data'}        = from_json( $profile_get->decoded_content );
	}
	
	return $self;
}

sub _simple_key
{
	my $self = shift;
	my $key  = shift;
	my @blogs;
	
	if (ref $self->{'data'}->{$key} eq 'ARRAY')
	{
		@blogs = @{ $self->{'data'}->{$key} };
	}
	else
	{
		push @blogs, $self->{'data'}->{$key};
	}
	
	if (wantarray)
	{
		return @blogs;
	}
	else
	{
		return $blogs[0];
	}
}

sub webid
{
	my $self = shift;
	return 'http://thing-described-by.org/?' . $self->{'profile_uri'};
}

sub weblog { return _simple_key(@_, 'blog'); } ;
sub openid { return _simple_key(@_, 'OpenID'); } ;

sub dictionary
{
	my $self = shift;
	return $self->{'data'};
}

1;

__END__

=head1 NAME

WWW::Finger::BitworkingFingerProtocol - WWW::Finger module for Joe Gregorio's finger protocol

=head1 SYNOPSIS

  use WWW::Finger;
  my $finger = WWW::Finger->new("joe@example.com");
  if (defined $finger)
  {
    print $finger->openid . "\n";
  }

=head1 DESCRIPTION

This module implements an alternative finger proposal by Joe Gregorio.

Additional methods (other than standard WWW::Finger):

=over

=item * C<openid> - returns the person's OpenID.

=item * C<dictionary> - returns a hashref of key-value pairs from their profile

=back

=head1 SEE ALSO

L<WWW::Finger>.

L<http://bitworking.org/news/2010/01/webfinger>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2010-2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
