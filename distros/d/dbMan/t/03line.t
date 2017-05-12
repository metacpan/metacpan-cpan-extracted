BEGIN { $| = 1; print "1..3\n"; }
END { print "not ok 1\n" unless $loaded; }

use DBIx::dbMan;

$loaded = 1;
print "ok 1\n";

my $dbman = new DBIx::dbMan -interface => 'cmdline';
print "not " unless defined $dbman and ref $dbman;
print "ok 2\n";

=comment
$main::TEST = 1;
$dbman->start();
print "not " unless $main::TEST_RESULT;
=cut

print "ok 3 # skip\n";
