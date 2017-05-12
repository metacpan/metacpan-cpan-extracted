
use Text::Merge::Lists;

$|=1;

require "t/test.pl";	# $data is here
$data = $data;
$actions = { 'Mothers' => \&apple_pie };

$apple = {
	'ItemType' => 'tree',
	'Data' => { 
		'Name'=>'apple', 
		'Color'=>'red', 
		'Size'=>'medium', 
		'Shape'=>'round' 
	}
};

$pear = {
	'ItemType' => 'tree',
	'Data' => { 
		'Name'=>'pear', 
		'Color'=>'green', 
		'Size'=>'medium', 	
		'Shape'=>'oblong' 
	}
};

$grape = {
	'ItemType' => 'vine',
	'Data' => { 
		'Name'=>'grape', 
		'Color'=>'purple', 
		'Size'=>'small', 
		'Shape'=>'round' 
	}
};

$pumpkin = {
	'ItemType' => 'vine',
	'Data' => { 
		'Name'=>'pumpkin', 
		'Color'=>'orange', 
		'Size'=>'large', 
		'Shape'=>'round' 
	}
};

$fruit_list = [ $apple, $pear, $grape, $pumpkin ];
$empty_list = [];

my $publisher = new Text::Merge::Lists('t/liststyles/');

my $dummy_list = $publisher->sort_method('REF:BogusField', $fruit_list);
$$data{FruitList} = $publisher->sort_method('REF:Name reverse', $fruit_list);
$$data{EmptyList} = $empty_list;

($ct,$passed) = (0,0);

print "1..1\n";
$publisher->line_by_line(1);

my $input = 't/listin.txt';
my $ofile = 't/tmp/TPB'.$$.'.txt';
my $output = new FileHandle(">$ofile") or die "Can't open $ofile for output";

$publisher->publish_to($output, $input, $data, $actions);  $output->close; $ct++;

my $diff = `perl t/diffutil t/listres2.txt $ofile`;
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
