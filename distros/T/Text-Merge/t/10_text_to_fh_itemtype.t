
use Text::Merge;

$|=1;

require "t/test.pl";	# $data is here
$data = $data;
$actions = { 'Mothers' => \&apple_pie };

my $publisher = new Text::Merge;

($ct,$passed) = (0,0);

print "1..1\n";

my $input = slurp('t/input.txt');
my $ofile = 't/tmp/TPB'.$$.'.txt';
my $output = new FileHandle(">$ofile") or die "Can't open $ofile for output";

my $item = { 'ItemType'=>'testitem', 'Data'=>$data, 'Actions'=>$actions };
$publisher->publish_to($output, $input, $item);  $output->close; $ct++;

my $diff = `perl t/diffutil t/results.txt $ofile`;
if ($diff) { print "not ok\n"; } else { $passed++;  print "ok\n"; };

if (-e $ofile) { unlink $ofile; };

exit ($passed ne $ct || $diff && 1 || 0);


sub apple_pie {
	my $val = shift;
	my $ret = $$val{Data}{TestFruit}.' pie';
	return $ret;
};

sub slurp {
	my $filename = shift;
	my $fh = new FileHandle("<$filename") || return '';
	my $text = '';
	foreach (<$fh>) { $text.=$_; };
	$fh->close;
	return $text;
};
