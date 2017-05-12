# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

#use Test::More 'no_plan';
use Test::More tests => 26;

BEGIN { 
    use_ok( 'WWW::Finances::Bovespa' ); 
    use_ok( 'Moose' );
    use_ok( 'WWW::Mechanize' );
    use_ok( 'XML::XPath' );
}

my $bovespa2 = WWW::Finances::Bovespa->new();
$bovespa2->find( { codigo => 'PETR3' } );
isa_ok ( $bovespa2, 'WWW::Finances::Bovespa' );
is( 1, $bovespa2->is_valid , 'valid response' );
is( 1, $bovespa2->ibovespa =~ m/(.+)/ , '' );
is( 1, $bovespa2->valor_ultimo =~ m/(.+)/ , '' );
is( 1, $bovespa2->quant_neg =~ m/(.+)/ , '' );
is( 1, $bovespa2->delay =~ m/(.+)/ , '' );
is( 1, $bovespa2->codigo =~ m/(.+)/ , '' );
is( 1, $bovespa2->codigo =~ m/PETR3/ , 'Correct code' );
is( 1, $bovespa2->hora =~ m/(.+)/ , '' );
is( 1, $bovespa2->data =~ m/(.+)/ , '' );
is( 1, $bovespa2->descricao =~ m/(.+)/ , '' );
is( 1, $bovespa2->descricao =~ m/PETROBRAS/ , 'correct description' );
is( 1, $bovespa2->oscilacao =~ m/(.+)/ , '' );
is( 1, $bovespa2->mercado =~ m/(.+)/ , '' );





$bovespa2->find( { codigo => 'NONEXISTANT' } );
isa_ok ( $bovespa2, 'WWW::Finances::Bovespa' );
is( 0, $bovespa2->is_valid , 'Invalid Code' );




my $bov = WWW::Finances::Bovespa->new();
$bov->find( { codigo => 'USIM5F' } );
isa_ok( $bov, 'WWW::Finances::Bovespa' );
is( 1, $bov->is_valid , 'valid response' );
is( 1, $bov->ibovespa =~ m/(.+)/ , '' );
is( 1, $bov->valor_ultimo =~ m/(.+)/ , '' );
is( 1, $bov->quant_neg =~ m/(.+)/ , '' );





$bov->find( 'x' );
is( 0, $bov->is_valid , 'invalid find' );
