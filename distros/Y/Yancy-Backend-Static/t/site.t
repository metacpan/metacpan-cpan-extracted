
=head1 DESCRIPTION

This tests a website built with the L<Yancy::Backend::Static> module.

=head1 SEE ALSO

L<Yancy>

=cut

use Test::More;
use Test::Mojo;
use Mojo::File qw( path );
use FindBin qw( $Bin );
my $SHARE_DIR = path( $Bin, 'share' );

$ENV{ MOJO_HOME } = $SHARE_DIR->child( 'site' );
my $t = Test::Mojo->new( 'Mojolicious' );
$t->app->plugin( Yancy => {
    backend => 'static:' . $SHARE_DIR->child( 'site' ),
    read_schema => 1,
} );
$t->app->routes->get( '/*id' )->to(
    'yancy#get',
    schema => 'pages',
    id => 'index',
    template => 'page',
    layout => 'default',
);

$t->get_ok( '/index.html' )
    ->status_is( 200 )
    ->content_type_like( qr{^text/html} )
    ->text_is( h1 => 'Static Test Site' )
    ->or( sub { diag shift->tx->res->body } )
    ->text_is( p => 'This is a static test site' )
    ->or( sub { diag shift->tx->res->body } )
    ->text_is( title => 'Static Test Site' )
    ->or( sub { diag shift->tx->res->body } )
    ;

$t->get_ok( '/', 'index is default' )
    ->status_is( 200 )
    ->content_type_like( qr{^text/html} )
    ->text_is( h1 => 'Static Test Site' )
    ->text_is( p => 'This is a static test site' )
    ->text_is( title => 'Static Test Site' )
    ;

$t->get_ok( '/about', 'request for directory' )
    ->status_is( 200 )
    ->content_type_like( qr{^text/html} )
    ->text_is( h1 => 'About' )
    ->text_is( title => 'About' )
    ;

$t->get_ok( '/style.css', 'static file not handled' )
    ->status_is( 200 )
    ->content_type_like( qr{^text/css} )
    ->content_like( qr{\Qh1 { font-size: 1.2em }} )
    ;

my @items = $t->app->yancy->list( 'pages' );
is_deeply
    [ sort map { $_->{path} } @items ],
    [
        'about/index', 'index',
    ],
    'list is complete and correct';

done_testing;
