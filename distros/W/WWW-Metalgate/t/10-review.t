use strict;
use warnings;

use Test::More tests => 3;

use_ok("WWW::Metalgate::Review");

{
    my $review = WWW::Metalgate::Review->new( artist => "Angra" );
    my @albums = $review->albums;
    ok( @albums > 2, 'number of albums');
    my @keys = qw(artist album point album_kana body);
    my @full = grep { $_->{artist} and $_->{body} and $_->{point} } @albums;
    ok( @albums == @full, 'valid body field');
    #use XXX;
    #XXX @albums;
}
