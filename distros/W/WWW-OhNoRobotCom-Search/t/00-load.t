#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('LWP::UserAgent');
    use_ok('HTML::TokeParser::Simple');
    use_ok('HTML::Entities');
    use_ok('Class::Accessor::Grouped');
	use_ok( 'WWW::OhNoRobotCom::Search' );
}

diag( "Testing WWW::OhNoRobotCom::Search $WWW::OhNoRobotCom::Search::VERSION, Perl $], $^X" );

my $o = WWW::OhNoRobotCom::Search->new;
isa_ok($o, 'WWW::OhNoRobotCom::Search');
can_ok($o, qw(    ua
    error
    results
    new
    search
    _fetch_results
    _parse_results
    _make_valid_include
    _set_error));

isa_ok($o->ua, 'LWP::UserAgent');