#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 12;

BEGIN {
    use_ok('Carp');
    use_ok('WWW::Pastebin::NoMorePastingCom::Retrieve');
    use_ok('WWW::Pastebin::PastebinCa::Retrieve');
    use_ok('WWW::Pastebin::PastebinCom::Retrieve');
    use_ok('WWW::Pastebin::PastieCabooSe::Retrieve');
    use_ok('WWW::Pastebin::PhpfiCom::Retrieve');
    use_ok('WWW::Pastebin::RafbNet::Retrieve');
    use_ok('WWW::Pastebin::UbuntuNlOrg::Retrieve');
    use_ok('Class::Data::Accessor');
	use_ok( 'WWW::Pastebin::Many::Retrieve' );
}

diag( "Testing WWW::Pastebin::Many::Retrieve $WWW::Pastebin::Many::Retrieve::VERSION, Perl $], $^X" );
my $o = WWW::Pastebin::Many::Retrieve->new;
isa_ok($o,'WWW::Pastebin::Many::Retrieve');
can_ok($o, qw(new retrieve error content response _objs _res _set_error));

