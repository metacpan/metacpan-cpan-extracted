use warnings;
use strict;

use Test::More tests => 4;

BEGIN { use_ok "Time::UTC::Segment"; }

{
	no warnings "redefine";
	sub Time::UTC::Segment::_download_latest_data() { 0 }
}

my $start_seg = Time::UTC::Segment->start;
ok $start_seg;

eval { Time::UTC::Segment::_use_builtin_knowledge(); };
is $@, "";

ok $start_seg->next;

1;
