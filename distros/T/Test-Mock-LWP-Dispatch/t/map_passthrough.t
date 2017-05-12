#!perl
use strict;
use warnings;
use Test::More tests => 4;
use Test::Mock::LWP::Dispatch ();
use File::Spec::Functions qw(catfile);
use FindBin qw($Bin $Script);

# dummy_marker_of_this_file_123

my $ua = LWP::UserAgent->new;
my $url = "file://" . catfile($Bin, $Script);

is($ua->get($url)->code, 404, 'before map');

my $index1 = $ua->map_passthrough(qr{^file://});
my $resp = $ua->get($url);
is($resp->code, 200, 'after map');
like($resp->content, qr/dummy_marker_of_this_file_123/,
     'actual content in resp');

$ua->unmap($index1);
is($ua->get("file://$Bin")->code, 404, 'after unmap');
