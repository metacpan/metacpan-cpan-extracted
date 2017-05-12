#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('LWP::UserAgent');
    use_ok('Class::Data::Accessor');
	use_ok( 'WWW::Pastebin::Base::Retrieve' );
}

diag( "Testing WWW::Pastebin::Base::Retrieve $WWW::Pastebin::Base::Retrieve::VERSION, Perl $], $^X" );

my $o = WWW::Pastebin::Base::Retrieve->new;

isa_ok($o,'WWW::Pastebin::Base::Retrieve');
can_ok($o, qw(new retrieve     ua
    uri
    id
    content
    error
    results
    _parse
    _make_uri_and_id
    _get_was_successful
    _set_error));