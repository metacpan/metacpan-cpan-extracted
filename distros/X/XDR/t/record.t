# -*-Perl-*-

use XDR::Encode 'record';
use XDR::Decode;

print "1..1\n";
my $in = "Hello, world!\n";
my $pkt = record ($in);
my $dec = XDR::Decode->new ();
$dec->record ($pkt);
my $out = $dec->inline (length $in);

print ($out eq $in ? '' : 'not ', "ok 1\n");

exit 0;
