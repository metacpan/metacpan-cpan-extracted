#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 12;
BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('WWW::Mechanize');
    use_ok('HTML::TokeParser::Simple');
    use_ok('File::Basename');
    use_ok('Devel::TakeHashArgs');
    use_ok('Sort::Versions');
    use_ok('Class::Accessor::Grouped');
    use_ok('WWW::PAUSE::CleanUpHomeDir');
}

diag( "Testing WWW::PAUSE::CleanUpHomeDir $WWW::PAUSE::CleanUpHomeDir::VERSION, Perl $], $^X" );

my $o = WWW::PAUSE::CleanUpHomeDir->new( login => 'pass' );
isa_ok($o, 'WWW::PAUSE::CleanUpHomeDir');

can_ok($o, qw(
    error
    last_list
    deleted_list
    fetch_list
    list_scheduled
    list_old
    clean_up
    undelete
    new
    _set_error
    _parse_list
    _mech
));

isa_ok($o->_mech, 'WWW::Mechanize');
