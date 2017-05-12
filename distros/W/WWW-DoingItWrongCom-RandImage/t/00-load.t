#!perl -T

use Test::More tests => 7;

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('LWP::UserAgent');
    use_ok('HTML::TokeParser::Simple');
	use_ok( 'WWW::DoingItWrongCom::RandImage' );
}

diag( "Testing WWW::DoingItWrongCom::RandImage $WWW::DoingItWrongCom::RandImage::VERSION, Perl $], $^X" );


use WWW::DoingItWrongCom::RandImage;

my $o = WWW::DoingItWrongCom::RandImage->new;

isa_ok($o, 'WWW::DoingItWrongCom::RandImage');
can_ok($o, qw(new fetch err_msg) );