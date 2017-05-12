
use Time::Local;

$::data = { 'Test1' => 'works',
	  'TestFloat' => 1.3312,
	  'TestName' => 'JOHN Q. SMITH',
	  'TestTabular' => "\tOne\tTwo\t\tBuckle My Shoe.\t",
	  'TestEscape' => '&;"#<>',
	  'TestCase' => 'bOoK',
	  'TestDate' => Time::Local::timelocal(0,0,21,9,6,98,4,189,1),
	  'TestFruit' => 'apple',
	  'TestParagraph' => 'The quick brown snuffle-uppagus jumped '.
			     'scr-ump-dilly-iciously over the lazy supercalifragilisticexpialidocious bug.'
};

$::recurseitem3 = { 'ItemType' => 'testtype',
		    'Data' => { 'id'=>3, 'ItemList' => [] } 
};

$::recurseitem2 = { 'ItemType' => 'testtype',
		    'Data' => { 'id'=>2, 'ItemList' => [] } 
};

$::recurseitem1 = { 'ItemType' => 'testtype',
		    'Data' => { 'id'=>1, 'ItemList' => [ $::recurseitem2, $::recurseitem3] } 
};

$$::recurseitem2{'Data'}{'ItemList'} = [ $::recurseitem1 ];


1;

sub create_file {
	my $file = $_[0];
	if (!-e $file) {
		open FILE, ">$file" or die "Can't create $file";
		print FILE $_[1];
		close FILE;
	}
}


