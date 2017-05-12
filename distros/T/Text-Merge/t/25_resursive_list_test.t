
use Text::Merge::Lists;

$|=1;

require "t/test.pl";	# $data is here
$data = $recurseitem1 = $recurseitem1;

my $publisher = new Text::Merge::Lists('t/liststyles/');

($ct,$passed) = (0,0);

print "1..1\n";
$publisher->line_by_line(1);

my $input = 't/recurse.txt';
my $ofile = 't/tmp/TPB'.$$.'.txt';
my $output = new FileHandle(">$ofile") or die "Can't open $ofile for output";

$publisher->set_max_nesting_depth(5);
$publisher->publish_to($output, $input, $data);  $output->close; $ct++;

my $diff = `perl t/diffutil t/recres2.txt $ofile`;
if ($diff) { print "not ok\n";  print STDERR "DIFF: $diff\n"; } 
else { $passed++;  print "ok\n"; };

if (-e $ofile) { unlink $ofile; };

exit ($passed ne $ct || $diff && 1 || 0);


sub slurp {
	my $filename;
	my $fh = new FileHandle("<$filename") || return '';
	my $text = '';
	foreach (<$fh>) { $text.=$_; };
	$fh->close;
	return $text;
};

