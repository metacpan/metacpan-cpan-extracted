#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 6;

BEGIN {
    use_ok('Moo');
    use_ok('WWW::Mechanize');
    use_ok('overload');
    use_ok( 'WWW::Pastebin::PastebinCom::Create' ) || print "Bail out!\n";
}

diag( "Testing WWW::Pastebin::PastebinCom::Create $WWW::Pastebin::PastebinCom::Create::VERSION, Perl $], $^X" );

my $bin = WWW::Pastebin::PastebinCom::Create->new;

isa_ok($bin, 'WWW::Pastebin::PastebinCom::Create');
can_ok($bin, qw/paste  paste_uri  new  error/);