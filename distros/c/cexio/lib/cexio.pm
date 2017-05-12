#######################################
# CEX.IO Beta Trade API Perl Module   #
#  version 0.2.3                      #
#                                     #
# Author: Michael W. Renz             #
# Created: 03-Jun-2014                #
#######################################

=pod

=head1 NAME

cexio - perl module interface to cex.io/ghash.io's API

=head1 SYNOPSIS

	use cexio;
	use Data::Dumper;

	# public functions do not require any options
	my $cexio_object = new cexio();

	print Dumper( $cexio_object->ticker("GHS", "BTC" ) ) ."\n";
	print Dumper( $cexio_object->order_book("GHS", "BTC", "100") ) ."\n";
	print Dumper( $cexio_object->trade_history("GHS", "BTC", "1184696000") ) ."\n";

	# private functions require username, key, and secret to be set
	my $cexio_object = new cexio( { username => "sample-user", key => "this-is-not-a-real-key", secret => "this-is-not-a-real-secret" } );

	print Dumper( $cexio_object->open_orders("GHS","BTC") ) ."\n";
	print Dumper( $cexio_object->cancel_order("1") ) ."\n";
	print Dumper( $cexio_object->place_order("GHS", "BTC", "buy", "1", "0.007") ) ."\n";
	print Dumper( $cexio_object->hashrate() ) ."\n";
	print Dumper( $cexio_object->workers() ) ."\n";


=head1 DESCRIPTION

Implements the cex.io API described at https://cex.io/api as a perl module

=cut

package cexio;

# standard includes
use strict;
use warnings;
use Exporter;
use Carp;

my $modname="cexio-perl-module";
my $modver="0.2.3";

use vars qw($VERSION);
$cexio::VERSION = '0.2.3';

use JSON;
use Digest::SHA qw(hmac_sha256_hex);
use Hash::Flatten qw(:all);
use LWP::UserAgent;

my $ua = LWP::UserAgent->new();
$ua->agent("${modname}/${modver}");
$ua->timeout(1);

my $opcount = 0;

my %cexio = ( urls     => { api_url => "https://cex.io/api" } );

# cexio URLs
#  public/nonauthenticated functions
#    These are all GET requests
$cexio{urls}{api}{ticker}          = $cexio{urls}{api_url}. "/ticker/";
$cexio{urls}{api}{order_book}      = $cexio{urls}{api_url}. "/order_book/";
$cexio{urls}{api}{trade_history}   = $cexio{urls}{api_url}. "/trade_history/";

#  private functions
#    These are all POST requests
$cexio{urls}{api}{balance}         = $cexio{urls}{api_url}. "/balance/";
$cexio{urls}{api}{open_orders}     = $cexio{urls}{api_url}. "/open_orders/";
$cexio{urls}{api}{cancel_order}    = $cexio{urls}{api_url}. "/cancel_order/";
$cexio{urls}{api}{place_order}     = $cexio{urls}{api_url}. "/place_order/";

# ghash.io private functions
$cexio{urls}{api}{ghash_url}       = $cexio{urls}{api_url}. "/ghash.io";
$cexio{urls}{api}{ghash}{hashrate} = $cexio{urls}{api}{ghash_url}. "/hashrate";
$cexio{urls}{api}{ghash}{workers}  = $cexio{urls}{api}{ghash_url}. "/workers";

my $o = new Hash::Flatten();

=pod

=over 4

=item my $cexio_object = new cexio( \%options );

The only time you need to pass options to new() is when you are using a private function.

The only options you need to pass are 'username', 'key', and 'secret'.

=back

=cut

sub new
{
	my ($class, $options) = @_;
	$options = {} unless ref $options eq 'HASH';
	my $self = {
		%$options
	};

	# We only expect the following options:
	#  - key - needed for private functions
	#  - secret - needed for private functions
	#  - username - needed for private functions

	return bless($self, $class);	
}

=pod

=head2 Public functions

=over 4

=item my $ticker = $cexio_object->ticker( $primary, $secondary );

Returns the current ticker for orders of $primary for $secondary.

=item my $order_book = $cexio_object->order_book( $primary, $secondary, $depth );

Returns the current list of bids and asks for price and amount of $primary for $secondary

Setting $depth is optional, and will limit the amount of orders returned.

=item my $trade_history = $cexio_object->trade_history( $primary, $secondary, $since );

Returns the current trade history of $primary for $secondary since $since trade id.

Setting $since is optional, and will limit the number of trades returned.

=back

=cut

# subroutines for public functions
sub ticker
{
	my ($self, $primary, $secondary) = @_;
	return $o->unflatten( $self->_json_get($cexio{urls}{api}{ticker}.$primary."/".$secondary) );
}

sub order_book
{
	my ($self, $primary, $secondary, $depth) = @_;
	if ( defined($depth) ) { $secondary .= "/?depth=${depth}"; }
	return $o->unflatten( $self->_json_get($cexio{urls}{api}{order_book}.$primary."/".$secondary) );
}

sub trade_history
{
	my ($self, $primary, $secondary, $since) = @_;
	if ( defined($since) ) { $secondary .= "/?since=${since}"; }
	return $self->_json_get($cexio{urls}{api}{trade_history}.$primary."/".$secondary);
}

=pod

=head2 Private functions

=over 4

=item my $open_orders = $cexio_object->open_orders( $primary, $secondary );

Returns an array of open orders of $primary for $secondary that includes:
	id - order id
	time - timestamp
	type - buy or sell
	price - price
	amount - amount
	pending - pending amount (if partially executed)

=item my $cancel_order = $cexio_object->cancel_order( $order_id );

Returns 'true' if $order_id has been found and cancelled.

=item my $place_order = $cexio_object->place_order( $primary, $secondary, "buy" | "sell", $quantity, $price );

Places an order of $primary for $secondary that is either "buy" or "sell" of $quantity at $price.

Returns an associative array representing the order placed:
	id - order id
	time - timestamp
	type - buy or sell
	price - price
	amount - amount
	pending - pending amount (if partially executed)

=back

=cut

# subroutines for private functions
sub balance
{
	my ($self) = @_;
	return $o->unflatten( $self->_json_post( $cexio{urls}{api}{balance} ) );
}

sub open_orders
{
	my ($self) = @_;
	return $self->_json_post( $cexio{urls}{api}{open_orders} );
}

sub cancel_order
{
	my ($self, $id) = @_;
	$self->{post_message}{id} = $id;
	return $o->unflatten( $self->_json_post( $cexio{urls}{api}{cancel_order} ) );
}

sub place_order
{
	my ($self, $primary, $secondary, $type, $amount, $price) = @_;

	croak("order type must be either 'buy' or 'sell'") unless ($type =~ m/^buy$|^sell$/);

	$self->{post_message}{type}   = $type;
	$self->{post_message}{amount} = $amount;
	$self->{post_message}{price}  = $price;

	return $o->unflatten( $self->_json_post( $cexio{urls}{api}{place_order}.$primary."/".$secondary."/" ) );
}

=pod

=head2 GHash.io-specific private functions

=over 4

=item my $hashrate = $cexio_object->hashrate();

Takes no options.  Returns an associative array of general mining hashrate statistics for the past day in MH/s.

=item my $workers = $cexio_object->workers();

Takes no options.  Returns an associative array of mining hashrate statistics broken down by workers in MH/s.

=back

=cut

# subroutines for private ghash.io functions
sub hashrate
{
	my ($self) = @_;
	return $o->unflatten( $self->_json_post( $cexio{urls}{api}{ghash}{hashrate} ) );
}

sub workers
{
	my ($self) = @_;
	return $o->unflatten( $self->_json_post( $cexio{urls}{api}{ghash}{workers} ) );
}


# private module functions

# This gets called only when a POST operation gets used
sub _generate_signature
{
	my ($self) = @_;

	my $nonce = _generate_nonce();

	croak("username not defined for private function") if ( !defined($self->{username}) );
	croak("key not defined for private function")      if ( !defined($self->{key}) );
	croak("secret not defined for private function")   if ( !defined($self->{secret}) );

	# We now have enough information to create a signature
	$self->{signature} = hmac_sha256_hex($nonce . $self->{username} . $self->{key}, $self->{secret});

	# fix length of signature to mod4 
	while (length($self->{signature}) % 4) {
	    $self->{signature} .= '=';
	}

	# Now let's build a post_message
	$self->{post_message}{key}         = $self->{key};
	$self->{post_message}{signature}   = $self->{signature};
	$self->{post_message}{nonce}       = $nonce;

	return $self;
}

sub _generate_nonce
{
        # $opcount is used in case we want to 
        # use the same instance of this module
        # for multiple POST operations, potentially
        # within the same second of each other.
        $opcount++;

        # we are using epoch time + $opcount to
        # act as nonce
        return time . $opcount;
}

sub _json_get
{
	my ($self, $url) = @_;
	return decode_json $ua->get( $url )->decoded_content();
}

sub _json_post
{
	my ($self, $url) = @_;
	return decode_json $ua->post( $url, $self->_generate_signature()->{post_message} )->decoded_content();
}

sub TRACE {}

1;

=pod

=head1 CHANGELOG

=over 4

=item * Changes to POD to fix formatting

=item * Fixed _generate_signature private function to merge $self->{post_message} instead of overwriting it

=back


=head1 TODO

=over 4

=item * Add comprehensive unit tests to module distribution
=item * Add server-side error handling
=item * Fix any bugs that anybody reports
=item * Write better documentation.  Always write better documentation

=back


=head1 SEE ALSO

See https://cex.io/api for the most updated API docs and more details on each of the functions listed here.


=head1 VERSION

$Id: cexio.pm,v 0.2.3 2014/06/08 09:08:00 CRYPTOGRA Exp $


=head1 AUTHOR

Michael W. Renz, C<< <cryptographrix+cpan at gmail.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-cexio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=cexio>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc cexio


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=cexio>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/cexio>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/cexio>

=item * Search CPAN

L<http://search.cpan.org/dist/cexio/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael W. Renz.

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
