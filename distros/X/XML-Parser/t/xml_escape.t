BEGIN { print "1..5\n"; }
END { print "not ok 1\n" unless $loaded; }
use XML::Parser;
$loaded = 1;
print "ok 1\n";

my $xp_saved;

sub start {
    my ($xp) = @_;
    $xp_saved = $xp;
}

my $parser = new XML::Parser( Handlers => { Start => \&start } );
$parser->parse('<doc/>');

# Test basic escaping of & and <
my $result = $xp_saved->xml_escape('a & b < c');
print "not " unless $result eq 'a &amp; b &lt; c';
print "ok 2\n";

# Test multiple double quotes are all escaped
$result = $xp_saved->xml_escape('say "hello" and "world"', '"');
print "not " unless $result eq 'say &quot;hello&quot; and &quot;world&quot;';
print "ok 3\n";

# Test multiple single quotes are all escaped
$result = $xp_saved->xml_escape("it's Bob's", "'");
print "not " unless $result eq "it&apos;s Bob&apos;s";
print "ok 4\n";

# Test both quote types together
$result = $xp_saved->xml_escape(q{He said "it's"}, '"', "'");
print "not " unless $result eq 'He said &quot;it&apos;s&quot;';
print "ok 5\n";
