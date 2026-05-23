use strict;
use warnings;

use Test::More;
use File::Temp qw( tempdir );

use WWW::RobotRules::AnyDBM_File ();

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/robotdb";

my $r = WWW::RobotRules::AnyDBM_File->new("myrobot/2.0", $file);

# Cache backing file(s) must have no group/world permission bits.
if ($^O ne 'MSWin32') {
    my @backing = glob "$file*";
    ok scalar @backing, "DBM backing file(s) exist after construction";
    for my $f (@backing) {
        my $mode = (stat $f)[2] & 07777;
        is($mode & 0077,
            0,
            "$f mode " . sprintf("%04o", $mode) . " has no group/world bits");
    }
}

$r->parse("http://www.aas.no/robots.txt", "");

$r->visit("www.aas.no:80");

is $r->no_visits("www.aas.no:80"), 1;

$r->push_rules("www.sn.no:80", "/aas", "/per");
$r->push_rules("www.sn.no:80", "/god", "/old");

my @r = $r->rules("www.sn.no:80");

is "@r", "/aas /per /god /old";

$r->clear_rules("per");
$r->clear_rules("www.sn.no:80");

@r = $r->rules("www.sn.no:80");

is "@r", "";

$r->visit("www.aas.no:80", time + 10);
$r->visit("www.sn.no:80");

note "No visits: " . $r->no_visits("www.aas.no:80");
note "Last visit: " . $r->last_visit("www.aas.no:80");
note "Fresh until: " . $r->fresh_until("www.aas.no:80");

is $r->no_visits("www.aas.no:80"), 2;

cmp_ok abs($r->last_visit("www.sn.no:80") - time), '<=', 2;

$r = undef;

# Try to reopen the database without a name specified
$r = WWW::RobotRules::AnyDBM_File->new(undef, $file);
$r->visit("www.aas.no:80");

is $r->no_visits("www.aas.no:80"), 3;

note "Agent-Name: ", $r->agent;
is $r->agent, 'myrobot';

$r = undef;

note "*** Dump of database ***";
tie(my %cat, 'AnyDBM_File', $file, 0, 0644) or die "Can't tie: $!";
while (my ($key, $val) = each(%cat)) {
    note "$key\t$val";
}
note "******";

untie %cat;

# Try to open database with a different agent name
$r = WWW::RobotRules::AnyDBM_File->new("MOMSpider/2.0", $file);

is $r->no_visits("www.sn.no:80"), 0;

# Try parsing
$r->parse("http://www.sn.no:8080/robots.txt", <<EOT, (time + 1));

User-Agent: *
Disallow: /

User-Agent: Momspider
Disallow: /foo
Disallow: /bar

EOT

@r = $r->rules("www.sn.no:8080");
is "@r", "/foo /bar";

cmp_ok $r->allowed("http://www.sn.no"), '<', 0;

ok !$r->allowed("http://www.sn.no:8080/foo/gisle");

sleep(2);    # wait until file has expired
cmp_ok $r->allowed("http://www.sn.no:8080/foo/gisle"), '<', 0;

$r = undef;

note "*** Dump of database ***";
tie(%cat, 'AnyDBM_File', $file, 0, 0644) or die "Can't tie: $!";
while (my ($key, $val) = each(%cat)) {
    note "$key\t$val";
}
note "******";

untie %cat;    # Otherwise the next line fails on DOSish

while (unlink("$file", "$file.pag", "$file.dir", "$file.db")) { }

# Try open a an emty database without specifying a name
eval { $r = WWW::RobotRules::AnyDBM_File->new(undef, $file); };
isnt $@, "";

unlink "$file", "$file.pag", "$file.dir", "$file.db";

done_testing;
