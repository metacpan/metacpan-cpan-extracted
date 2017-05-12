#!/usr/bin/env perl

use Test::More tests => 9;

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('LWP::UserAgent');
    use_ok('Devel::TakeHashArgs');
    use_ok('Class::Data::Accessor');
	use_ok( 'WWW::Pastebin::Bot::Pastebot::Create' );
}

diag( "Testing WWW::Pastebin::Bot::Pastebot::Create $WWW::Pastebin::Bot::Pastebot::Create::VERSION, Perl $], $^X" );

my $o = WWW::Pastebin::Bot::Pastebot::Create->new;
isa_ok($o,'WWW::Pastebin::Bot::Pastebot::Create');
can_ok($o, qw(new paste site uri ua error _set_error));
isa_ok($o->ua, 'LWP::UserAgent');