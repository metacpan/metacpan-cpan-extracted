package WWW::API::Bitfinex;

use 5.006;
use strict;
use warnings;

=head1 NAME

WWW::API::Bitfinex - API Btifinex

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS
 
 + HTTP / WebSocket ( Mojo::UserAgent )
 - v2

  export BITFINEX_APIKEY='IDONTKNOW'
  export BITFINEX_APIPASS='HUHAAAAA'
 
  my $B = Bitfinex->new(apikey => 'YOUKNOW' , apipass => 'WEKNOW');
 
=cut

use Mojo::Base -base;

use Mojo::UserAgent;

use WWW::API::Bitfinex::Orders;
use WWW::API::Bitfinex::Positions;
use WWW::API::Bitfinex::Margin;
use WWW::API::Bitfinex::Wallet;

use JSON::XS;
use Digest::SHA 'hmac_sha384_hex';
use MIME::Base64 'encode_base64';

use Data::Dumper;

has debug => $ENV{'BITFINEX_DEBUG'} // 0;

has apiver  => 'v1';
has apikey  => shift // $ENV{'BITFINEX_APIKEY'};
has apipass => shift // $ENV{'BITFINEX_APIPASS'};
has baseurl => 'https://api.bitfinex.com';

has UA => sub { Mojo::UserAgent->new; };

has Orders    => sub { WWW::API::Bitfinex::Orders->new;    };
has Positions => sub { WWW::API::Bitfinex::Positions->new; };
has Margin    => sub { WWW::API::Bitfinex::Margin->new;    };
has Wallet    => sub { WWW::API::Bitfinex::Wallet->new;    };

=head1 SUBROUTINES/METHODS

=head2 Auth call

=cut
sub Auth {
    my $self = shift;
    my $url  = '/'.$self->apiver.'/'.shift;
    my $args = shift;
    
    my $req_url = $self->baseurl.$url;

    my $nonce = time()*1000;
    
    my $params = {
	nonce   => $nonce.'.00',
	request => $url
    };

    map { $params->{$_} = $args->{$_} } keys %{$args};
    
    print Dumper encode_json($params) if $self->debug;
    
    my $payload = encode_base64(encode_json($params), '');
    my $sha384  = hmac_sha384_hex($payload,$self->apipass);
    
    $self->UA->on(start => sub {
	my ($ua, $tx) = @_;
	$tx->req->headers->header('X-BFX-APIKEY'    => $self->apikey );
	$tx->req->headers->header('X-BFX-PAYLOAD'   => $payload);
	$tx->req->headers->header('X-BFX-SIGNATURE' => $sha384);
		  });

    $self->UA->post($req_url)->res->json;
}

=head2 Public call

=cut
sub Public {
    my $self = shift;
    my $url  = shift;

    $url = $self->baseurl.'/'.$self->apiver.'/'.$url;
    
    $self->UA->get($url)->res->json;
}

sub Required {
    my $self = shift;
    my $args = shift;
    my @chck = @_;
    
    for ( @chck ) {
        return { error => "Required: $_" } unless $args->{$_};
    }   
}

=doc Public API
=cut
sub Funding { shift->Public('lends/'.shift); }
sub Stats   { shift->Public('stats/'.shift); }
sub Symbols { shift->Public('symbols'); }
sub SymbolsDetail  { shift->Public('symbols_details'); }
sub Ticker  { shift->Public('ticker/'.shift); }
sub Trades  { shift->Public('trades/'.shift); }
sub Orderbook { shift->Public('book/'.shift); }

=doc Auth API
=cut
sub Account { shift->Auth('account_infos'); }
sub Summary { shift->Auth('summary'); }
sub KeyInfo { shift->Auth('key_info'); }

=head1 AUTHOR

Harun Delgado, C<< <hdp at nurmol.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-api-bitfinex at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-API-Bitfinex>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::API::Bitfinex


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-API-Bitfinex>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-API-Bitfinex>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-API-Bitfinex>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-API-Bitfinex/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Harun Delgado.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WWW::API::Bitfinex
