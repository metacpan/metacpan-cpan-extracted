
use Text::Merge;

$|=1;

require "t/test.pl";	# $data is here
$data = $data;
$actions = { 'Mothers' => \&apple_pie };

my $publisher = new Text::Merge;

($ct,$passed) = (0,0);

print "1..2\n";

my $input = 't/delimin.txt';
my $ofile = 't/tmp/TPB'.$$.'.txt';
my ($output,$diff);

# First test just redefining the standard delimiters (compat w/version <= 0.32)
$output = new FileHandle(">$ofile") or die "Can't open $ofile for output";
$publisher->set_delimiters('<[', ']>');
$publisher->publish_to($output, $input, $data, $actions);  $output->close; $ct++;
$diff = `perl t/diffutil t/results.txt $ofile`;
if ($diff) { print "not ok\n";  print STDERR "DIFF: $diff\n"; } 
else { $passed++; print "ok\n"; };
if (-e $ofile) { unlink $ofile; };


# Next test with "zeroing" both standard delimiters
$output = new FileHandle(">$ofile") or die "Can't open $ofile for output";
$publisher->set_delimiters('','');
$publisher->publish_to($output, $input, $data, $actions);  $output->close; $ct++;
$diff = `perl t/diffutil t/results-d2.txt $ofile`;
if ($diff) { print "not ok\n";  print STDERR "DIFF: $diff\n"; } 
else { $passed++; print "ok\n"; };
if (-e $ofile) { unlink $ofile; };


exit ($passed ne $ct || $diff && 1 || 0);


sub apple_pie {
	my $val = shift;
	my $ret = $$val{TestFruit}.' pie';
	return $ret;
};

sub slurp {
	my $filename;
	my $fh = new FileHandle("<$filename") || return '';
	my $text = '';
	foreach (<$fh>) { $text.=$_; };
	$fh->close;
	return $text;
};
