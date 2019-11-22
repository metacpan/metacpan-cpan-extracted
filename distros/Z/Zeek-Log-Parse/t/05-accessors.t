use 5.10.1;
use strict;
use warnings;

use Test::More tests=>10;

BEGIN { use_ok( 'Zeek::Log::Parse' ); }

my $parse = Zeek::Log::Parse->new('logs/ssl.log');
my $line = $parse->getLine();
is(scalar keys %$line, 20, "Number of entries");
is($parse->file, 'logs/ssl.log', "File name accessor");
is(length($parse->line), 323, "Line length");
is($parse->headerlines->[5], "#open	2014-08-08-17-13-55", "Header lines");
is(scalar @{$parse->headerlines}, 8, "Number of header lines");
is(scalar keys %{$parse->headers}, 8, "Number of header lines");
is($parse->headers->{open}, "2014-08-08-17-13-55", "Header access");
$parse->getLine(); # we do not want the next line
is(join(',', @{$parse->fields}), 'ts,uid,id.orig_h,id.orig_p,id.resp_h,id.resp_p,version,cipher,curve,server_name,resumed,last_alert,next_protocol,established,cert_chain_fuids,client_cert_chain_fuids,subject,issuer,client_subject,client_issuer', "Fields");
my $fh = $parse->fh;
like(<$fh>, qr/^#close\t2014-08-08-17-13-55/, 'File handle accessor');
