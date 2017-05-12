use strict;
use Test::More tests => 11;

BEGIN { use_ok("WSST::Schema"); }

can_ok("WSST::Schema", qw(clone_data data lang));

my $obj = WSST::Schema->new();
ok(ref $obj, '$obj->new()');
is_deeply($obj->data, {}, '$obj->data');
is_deeply($obj->clone_data, {}, '$obj->clone_data');

my $data = $obj->data;
$data->{test} = 1;
is_deeply($data, {test => 1}, '$data');
is_deeply($obj->{data}, {test => 1}, '$obj->{data}');
is_deeply($obj->clone_data, {test => 1}, '$obj->clone_data');

my $cdata = $obj->clone_data;
$cdata->{test2} = 2;
is_deeply($cdata, {test => 1, test2 => 2}, '$cdata');
is_deeply($obj->{data}, {test => 1}, '$obj->{data}');
is_deeply($obj->clone_data, {test => 1}, '$obj->clone_data');

1;
