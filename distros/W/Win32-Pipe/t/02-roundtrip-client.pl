use strict;
use warnings;
use Win32::Pipe;

my $client_path = shift @ARGV or die "usage: $0 <client_path>\n";

my $client = Win32::Pipe->new($client_path) or exit 1;

my $msg = $client->Read;
exit 2 unless defined $msg && $msg eq 'ping';

$client->Write('pong');
$client->Close;
exit 0;
