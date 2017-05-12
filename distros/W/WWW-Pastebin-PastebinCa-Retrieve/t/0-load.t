#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;
use Test::Deep;

BEGIN {
    use_ok('WWW::Pastebin::Base::Retrieve');
    use_ok('HTML::TokeParser::Simple');
    use_ok('HTML::Entities');
    use_ok('WWW::Pastebin::PastebinCa::Retrieve');
}

diag( "Testing WWW::Pastebin::PastebinCa::Retrieve $WWW::Pastebin::PastebinCa::Retrieve::VERSION, Perl $], $^X" );

use WWW::Pastebin::PastebinCa::Retrieve;
my $paster = WWW::Pastebin::PastebinCa::Retrieve->new( timeout => 10 );

isa_ok($paster, 'WWW::Pastebin::PastebinCa::Retrieve');
can_ok($paster, qw(
    new
    retrieve
    error
    results
    id
    uri
    ua
    _parse
    _set_error
    )
);
