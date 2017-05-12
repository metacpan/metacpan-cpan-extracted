use lib qw(lib ../lib);
use Data::Dumper;
use Test::More;
use FindBin qw($Bin);
use WWW::Spinn3r; 
use Test::Memory::Cycle;

BEGIN { plan tests => 17 }
my $FROM_FILE = "$Bin/02.xml";
my $spinn3r = new WWW::Spinn3r( from_file => $FROM_FILE );
ok(ref $spinn3r, "parsing document... can take a few seconds");
my $first_item = $spinn3r->next();
ok($first_item, "parse success");

my @fields = qw(link title guid pubDate dc:source weblog:title weblog:description dc:lang weblog:tier weblog:iranking weblog:indegree atom:published post:date_found description);

for my $field (@fields) { 
    ok(defined $$first_item{$field}, "has $field");
}

memory_cycle_ok( $spinn3r, "no circular references, yay!" );

