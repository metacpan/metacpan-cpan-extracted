#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN {
	plan tests => 5;
	use_ok('Time::Epoch');
}

my $macos_offset = 2082844800;
my $mac_time     = 3136327459;
my $mac_edt_time = 3136313059;
my $unix_time    = 1053482659;


SKIP: {
	is(perl2epoch($unix_time, 'macos', -400),    $mac_edt_time, "Perl to Mac EDT");
	is(epoch2perl($mac_edt_time, 'macos', -400), $unix_time,    "Mac EDT to Perl");

	is(perl2epoch($unix_time, 'macos', 0), $mac_time,  "Perl to Mac GMT");
	is(epoch2perl($mac_time, 'macos', 0),  $unix_time, "Mac GMT to Perl");
}

__END__
