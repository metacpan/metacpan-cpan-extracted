
use Text::Merge;

$|=1;

require "t/test.pl";	# $data is here
$data=$data;
$actions = { 'Mothers' => \&apple_pie };

my $publisher = new Text::Merge;

($ct,$passed) = (0,0);

print "1..1\n";
$publisher->line_by_line(0);

my $input = 't/mline.txt';
my $ofile = 't/tmp/TPB'.$$.'.txt';
my $output = new FileHandle(">$ofile") or die "Can't open $ofile for output";

$publisher->publish_to($output, $input, $data, $actions);  $output->close; $ct++;

my $diff = `perl t/diffutil t/mlineout.txt $ofile`;
if ($diff) { print "not ok\n"; print STDERR "DIFF:$diff\n"; } 
else { $passed++; print "ok\n"; };

unlink $ofile if -e $ofile;

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
