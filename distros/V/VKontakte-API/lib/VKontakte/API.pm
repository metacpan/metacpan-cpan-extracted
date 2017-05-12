package VKontakte::API;

use warnings;
use strict;
use utf8;

use Digest::MD5 qw(md5 md5_hex);
use WWW::Mechanize;
use JSON;

=pod

=head1 NAME

VKontakte::API - Module for login into vkontakte.ru and sending requests

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

	First of all register you application at http://vkontakte.ru/apps.php?act=add
	get api_id and secret_key to use it like this:

	#1. 
	use VKontakte::API;
 
	my $vk = VKontakte::API->new('api_id', 'secret_key');
	my $data=$vk->sendRequest('getProfiles', {'domains'=>'deevaas'});

	#2. or
	use VKontakte::API;
	$vk = VKontakte::API->new(
	        $api_id,
	        $cgi_query->param('session[secret]'),
	        $cgi_query->param('session[mid]'),
	        $cgi_query->param('session[sid]')
	);
	my $data=$vk->sendRequest('getProfiles', {'domains'=>'deevaas'});


	#3. or new one, use OAuth 2.0
	use VKontakte::API::OAuth;
	$vk = VKontakte::API::OAuth->new(
	        $api_id,
	        $secret
	);
	my $data=$vk->sendRequest('getProfiles', {'domains'=>'deevaas'});
       

=head1 SUBROUTINES/METHODS

=head2 new

Create new object. Two parameters of registered application:

=over 4

=item api_id

=item secret_key

=back

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );

	$self->{api_id}     = $_[0];
	$self->{secret} = $_[1];
	$self->{mid}	= $_[2];
	$self->{sid}	= $_[3];

	$self->{api_url} = "http://api.vk.com/api.php";

	return $self;
}

=head2 sendRequest

Send requests described at http://vkontakte.ru/developers.php?o=-1&p=%D0%9E%D0%BF%D0%B8%D1%81%D0%B0%D0%BD%D0%B8%D0%B5+%D0%BC%D0%B5%D1%82%D0%BE%D0%B4%D0%BE%D0%B2+API

$resp = $auth->sendRequest('getProfiles', {'uids'=>'123123'});

=over 4

=item method

Name of methods listed at http://vkontakte.ru/developers.php?o=-1&p=%D0%9E%D0%BF%D0%B8%D1%81%D0%B0%D0%BD%D0%B8%D0%B5+%D0%BC%D0%B5%D1%82%D0%BE%D0%B4%D0%BE%D0%B2+API  

=item params

Parameters for method

=back

=cut

sub sendRequest {
	my $self   = shift;
	my $method = $_[0];
	my $params = $_[1];

	$params->{'api_id'}    = $self->{'api_id'};
	$params->{'v'}         = '3.0';
	$params->{'method'}    = $method;
	$params->{'timestamp'} = time();
	$params->{'format'}    = 'json';
	$params->{'rnd'}    = int(rand()*10000);

	my $sig = defined $self->{'mid'} ? $self->{'mid'} : '';
	foreach my $k (sort keys %$params){
		$sig .= $k . '=' . $params->{$k};
	}
        $sig .= $self->{secret};

	$params->{'sig'} = md5_hex($sig);
	$params->{'sid'} = $self->{sid} if $self->{sid};
	my $query = $self->{api_url} . '?' . $self->_params($params);

	my $mech = WWW::Mechanize->new( agent => 'VKontakte::API', );
	my $r = $mech->get($query);

	#	my $res      = file_get_contents($query);
	my $response = $mech->content();
	utf8::encode($response);
	return decode_json($response);
}

=head2 _params

prepares parameters for request

=cut

sub _params {
	my $self   = shift;
	my $params = shift;

	return unless ( ref $params eq "HASH" );

	my @pice;
	while ( my ( $k, $v ) = each %$params ) {
		push @pice, $k . '=' . $v;# _encurl($v);
	}
	return join( '&', @pice );
}


=head2 _encurl

encodes data for url

=cut

sub _encurl {
	my ($url) = @_;
	( defined $url ) || ( $url = "" );

	$url=~s/([^a-z0-9])/sprintf("%%%02x",ord($1))/egsi;
	#$url =~ s/([^a-z0-9])/sprintf("%%%x",ord($1))/egsi;
	$url =~ s/ /\+/go;
	return $url;
}


=head1 AUTHOR

Anastasiya Deeva, C<< <nastya at creograf.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-vkontakte-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=VKontakte-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VKontakte::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=VKontakte-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/VKontakte-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/VKontakte-API>

=item * Search CPAN

L<http://search.cpan.org/dist/VKontakte-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Anastasiya Deeva.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;   
