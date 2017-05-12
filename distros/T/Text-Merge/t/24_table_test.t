
use Text::Merge::Lists;

$|=1;

require "t/test.pl";	# $data is here
$data = $data;
$actions = { 'Mothers' => \&apple_pie };

$apple = { 'Name'=>'apple', 'Color'=>'red', 'Size'=>'medium', 'Shape'=>'round' };
$pear = { 'Name'=>'pear', 'Color'=>'green', 'Size'=>'medium', 'Shape'=>'oblong' };
$grape = { 'Name'=>'grape', 'Color'=>'purple', 'Size'=>'small', 'Shape'=>'round' };
$pumpkin = { 'Name'=>'pumpkin', 'Color'=>'orange', 'Size'=>'large', 'Shape'=>'round' };
$fruit_list = [ $apple, $pear, $grape, $pumpkin ];
$empty_list = [];
$$data{FruitList} = $fruit_list;
$$data{EmptyList} = $empty_list;

my $publisher = new Text::Merge::Lists('t/liststyles/');

($ct,$passed) = (0,0);

print "1..1\n";
$publisher->line_by_line(1);

my $input = 't/tablein2.txt';
my $ofile = 't/tmp/TPB'.$$.'.txt';
my $output = new FileHandle(">$ofile") or die "Can't open $ofile for output";

$publisher->publish_to($output, $input, $data, $actions);  $output->close; $ct++;

my $diff = `perl t/diffutil t/tablres2.txt $ofile`;
if ($diff) { print "not ok\n";  print STDERR "DIFF: $diff\n"; } 
else { $passed++;  print "ok\n"; };

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
