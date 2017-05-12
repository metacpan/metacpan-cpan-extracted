#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok('Carp');
    use_ok('HTTP::Request::Common');
    use_ok('LWP::UserAgent');
    use_ok('HTML::TokeParser::Simple');
	use_ok( 'WWW::ImagebinCa::Create' );
}

diag( "Testing WWW::ImagebinCa::Create $WWW::ImagebinCa::Create::VERSION, Perl $], $^X" );

use WWW::ImagebinCa::Create;
my $bin = WWW::ImagebinCa::Create->new;
isa_ok($bin,'WWW::ImagebinCa::Create');
can_ok($bin, qw(new upload error page_uri image_uri upload_id) );