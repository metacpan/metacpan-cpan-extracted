# -*- perl -*-

# t/001_load.t - check module loading

use Test::More tests => 4;

BEGIN {
	use_ok('WWW::Newzbin');
	use_ok('WWW::Newzbin::Constants');
}

# basic object creation (required parameters only)
my $nzb_basic = WWW::Newzbin->new(
	username => "joebloggs",
	password => "secretpass123"
);
isa_ok($nzb_basic, 'WWW::Newzbin');

# extended object creation (all possible parameters)
my $nzb_ext = WWW::Newzbin->new(
        username => "joebloggs",
        password => "secretpass123",
	nowarnings => 1,
	proxy => "http://localhost:8080"
);
isa_ok($nzb_ext, 'WWW::Newzbin');


