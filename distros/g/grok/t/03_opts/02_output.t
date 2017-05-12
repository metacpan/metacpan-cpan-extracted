use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 14;

my $script = catfile('bin', 'grok');

my $pod6 = catfile('t_source', 'basic.pod');
my $pod6_text_short = qx/$^X $script -F $pod6 -o text/;
my $pod6_text_long = qx/$^X $script -F $pod6 --output text/;
my $pod6_ansi_short = qx/$^X $script -F $pod6 -o ansi/;
my $pod6_ansi_long = qx/$^X $script -F $pod6 --output ansi/;
my $pod6_xhtml_short = qx/$^X $script -F $pod6 -o xhtml/;
my $pod6_xhtml_long  = qx/$^X $script -F $pod6 --output xhtml/;

isnt($pod6_text_short, $pod6_ansi_short, "Pod 6 text and ANSI are different (-o)");
like($pod6_ansi_short, qr/\e\[/, "Pod 6 ANSI has color codes (-o)");
isnt($pod6_text_long, $pod6_ansi_long, "Pod 6 text and ANSI are different (--output)");
like($pod6_ansi_long, qr/\e\[/, "Pod 6 ANSI has color codes (--output)");
isnt($pod6_text_long, $pod6_xhtml_long, "Pod 6 text and xhtml are different (--output)");
like($pod6_xhtml_long, qr/<p>/, "Pod 6 xhtml has <p> (--output)");

my $pod5 = catfile('t_source', 'basic5.pod');
my $pod5_text_short  = qx/$^X $script -F $pod5 -o text/;
my $pod5_text_long   = qx/$^X $script -F $pod5 --output text/;
my $pod5_ansi_short  = qx/$^X $script -F $pod5 -o ansi/;
my $pod5_ansi_long   = qx/$^X $script -F $pod5 --output ansi/;
my $pod5_xhtml_short = qx/$^X $script -F $pod5 -o xhtml/;
my $pod5_xhtml_long  = qx/$^X $script -F $pod5 --output xhtml/;
my $pod5_pod_short   = qx/$^X $script -F $pod5 -o pod/;
my $pod5_pod_long    = qx/$^X $script -F $pod5 --output pod/;

isnt($pod5_text_short, $pod5_ansi_short, "Pod 5 text and ANSI are different (-o)");
like($pod5_ansi_short, qr/\e\[/, "Pod 5 ANSI has color codes (-o)");
isnt($pod5_text_long, $pod5_ansi_long, "Pod 5 text and ANSI are different (--output)");
like($pod5_ansi_long, qr/\e\[/, "Pod 5 ANSI has color codes (--output)");
isnt($pod5_text_long, $pod5_xhtml_long, "Pod 5 text and xhtml are different (--output)");
like($pod5_xhtml_long, qr/<p>/, "Pod 5 xhtml has <p> (--output)");
isnt($pod5_text_long, $pod5_pod_long, "Pod 5 text and pod are different (--output)");
like($pod5_pod_long, qr/^=head1/m, "Pod 5 pod has =head1 (--output)");
