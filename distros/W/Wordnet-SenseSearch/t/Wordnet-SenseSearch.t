use Test::More tests => 18;
BEGIN { use_ok('Wordnet::SenseSearch') };

my $wn = new Wordnet::SenseSearch (dir => "/usr/local/gbn/lexicon/other-dbs/wordnet-2.1/dict/");
ok($wn, "object");
my %animal = $wn->lookup("animal%1:03:00::");
is((scalar @{$animal{words}}), 6, "animal word count");
is((join "|", @{$animal{words}}), "animal|animate_being|beast|brute|creature|fauna", "animal word text");
is($animal{gloss}, "a living organism characterized by voluntary movement", "animal gloss");
is($animal{pos}, "n", "animal pos");

my %darkling = $wn->lookup("darkling%5:00:01:dark:01");
is((scalar @{$darkling{words}}), 1, "darkling word count");
is($darkling{pos}, "s", "darkling pos");
is($darkling{sensenum}, 2, "darkling sense num");
is($darkling{lexfile}, "00", "darkling lex file");

my %walk = $wn->lookup("walk%2:38:00::");
is((scalar @{$walk{words}}), 1, "walk word count");
is($walk{pos}, "v", "walk pos");
is($walk{sensenum}, 1, "walk sense num");
is($walk{lexfile}, 38, "walk lex file");

# bug submitted by Fintan Costello
my %earthworm = $wn->lookup("earthworm%1:05:00::");
is($earthworm{pos}, "n", "earthworm pos");
is($earthworm{lexfile},"05", "earthwork lex file");
ok(@{$earthworm{words}} > 9, "earthworm words");

my %empty = $wn->lookup("");
ok(!%empty);

