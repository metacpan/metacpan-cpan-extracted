package VKontakte::API::OAuth;

use warnings;
use strict;
use utf8;

use Digest::MD5 qw(md5 md5_hex);
use WWW::Mechanize;
use JSON;

=pod

=head1 NAME

VKontakte::API::OAuth - Module for login into vkontakte.ru using OAuth 2.0 and send requests

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    Register you application at http://vkontakte.ru/apps.php?act=add and get api_id and api_secret
    Details:
    http://vkontakte.ru/developers.php?o=-1&p=%C0%E2%F2%EE%F0%E8%E7%E0%F6%E8%FF%20%F1%E5%F0%E2%E5%F0%E0%20%EF%F0%E8%EB%EE%E6%E5%ED%E8%FF    
    
    use VKontakte::API::OAuth;
    
    my $vk = VKontakte::API::OAuth->new( $opt->{api_id}, $opt->{api_secret} );
    my $h = $vk->sendRequest( "getProfiles", { uid => 66748 } );
    print Dumper($h);
    
=head1 SUBROUTINES/METHODS

=head2 new

Two parameters of registered application:

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
 
	my $query='https://api.vkontakte.ru/oauth/access_token?client_id=' . $self->{api_id} . '&client_secret=' . $self->{secret}. '&grant_type=client_credentials';

	my $mech = WWW::Mechanize->new( agent => 'VKontakte::API::OAuth' );
	$mech->get($query);
	
	my $response = $mech->content();
	utf8::encode($response);
	my $h=decode_json($response);
	return undef unless(defined $h->{'access_token'});    

	$self->{'access_token'}=$h->{'access_token'};
	return $self;
}

=head2 sendRequest

$resp = $vk->sendRequest('getProfiles', {'uids'=>'123123'});

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

	my $query="https://api.vkontakte.ru/method/$method?".$self->_params($params)."&access_token=".$self->{'access_token'};

	my $mech = WWW::Mechanize->new( agent => 'VKontakte::API::OAuth' );
	my $r = $mech->get($query);

	my $response = $mech->content();
	utf8::encode($response);
	return decode_json($response);
}

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

=head1 AUTHOR

Anastasiya Deeva, C<< <nastya at creograf.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-vkontakte-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=VKontakte-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VKontakte::API::OAuth


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
