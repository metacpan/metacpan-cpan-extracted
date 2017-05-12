use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 6;

my $script = catfile('bin', 'grok');
my $pod = catfile('t_source', 'basic.pod');
my $result_short = qx/$^X $script -F $pod/;
my $result_long = qx/$^X $script --file $pod/;

for my $para (qw(Foo Bar Baz)) {
    like($result_short, qr/$para/, "Paragraph $para (-F)");
    like($result_long, qr/$para/, "Paragraph $para (--file)");
}
