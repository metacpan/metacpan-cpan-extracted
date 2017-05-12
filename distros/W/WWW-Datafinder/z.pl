use strict;
use warnings;

use lib (
      $ENV{'DATAFINDER_HOME'}
    ? $ENV{'DATAFINDER_HOME'}
    : $FindBin::Bin
);

use WWW::Datafinder;

my %mws2datafiner = (
    'd_zip' => sub { my ($x) = @_; my ($z) = split('-', $x->{PostalCode}); return $z; },
    'd_fulladdr' => sub { my ($x) = @_;
                          return $x->{AddressLine1} .
                            ($x->{AddressLine2} ? ' '.$x->{AddressLine2} : ''); },
    'd_state' => sub { my ($x) = @_; return $x->{StateOrRegion}; },
    'd_city' =>  sub { my ($x) = @_; return $x->{City}; },
    'd_first' =>  sub { my ($x) = @_; my ($n) = split(/\s+/, $x->{BuyerName});
                     return $n; },
    'd_last' =>  sub { my ($x) = @_; my @n = split(/\s+/, $x->{BuyerName});
                     return $n[-1]; },
);
my $df  = WWW::Datafinder->new( {
    api_key   => 'gmnglsc3koi5yzmtte5sss6i'
   }) or die 'Cannot create Datafinder object';

use Storable qw(nstore retrieve);
use Data::Dumper;
use Readonly;
Readonly my $ORDERS_CACHE => '../mws/orders.cache2';

my $all_orders = [];
if (-s $ORDERS_CACHE) {
    $all_orders = eval { retrieve($ORDERS_CACHE); };
}
my $count = 0;
foreach my $x (@{$all_orders}) {
    $count++;
    next if $count < 77;
    print Dumper($x);
    my $data = {};
    $x->{ShippingAddress}->{BuyerName} = $x->{BuyerName}; # it seems to be cleaner
    while ( my ($field, $code) = each %mws2datafiner) {
        my $val = &{$code}($x->{ShippingAddress});
        $data->{$field} = $val if $val;
    }
    print Dumper($data);
    my $x = $df->append_email($data);
    print Dumper($x->{datafinder}) if $x;

    last if $count > 90;
}
