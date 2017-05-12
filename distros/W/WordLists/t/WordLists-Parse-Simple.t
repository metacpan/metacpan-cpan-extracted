#!perl -w
use strict;
use WordLists::Parse::Simple;
use WordLists::Serialise::Simple;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 0;
sub compare_struct # TODO: Replace with is_deeply
{
	if (Dumper ($_[0]) eq Dumper ($_[1]))
	{
		return 1;
	}
	else 
	{
		print Dumper ($_[0]) ."\n". Dumper ($_[1]). "\n";
	}
	return 0
}

my $parser = WordLists::Parse::Simple->new();

use Test::More qw(no_plan);
ok(
	compare_struct(
		[{hw=>'a', pos=>'det'}] ,
		[ { pos => 'det' , hw =>'a', } ] 
	),
	'The testing framework works!'
);
ok(
	compare_struct(
		$parser->parse_string("#*hw\tpos\na\tdet") , 
		[{hw=>'a', pos=>'det'}] 
	),
	'parse_string on default settings works ok with a header'
);
ok(
	compare_struct(
		$parser->parse_string("#*hw\tpos\na\tdet\naardvark\tn") , 
		[{hw=>'a', pos=>'det'}, {hw=>'aardvark', pos=>'n'}] 
	),
	'parse_string on default settings works ok with mutliple lines'
);
ok(
	compare_struct(
		$parser->parse_string("#*hw\tpos\n\na\tdet\naardvark\tn\n") , 
		[{hw=>'a', pos=>'det'}, {hw=>'aardvark', pos=>'n'}] 
	),
	'parse_string correctly ignores empty lines'
);
ok(
	compare_struct(
		$parser->parse_string("a\tdet\tone\ta bag\naardvark\tn\tan animal with a long nose\tan aardvark ate my semicolons") , 
		[{hw=>'a', pos=>'det'}, {hw=>'aardvark', pos=>'n'}] 
	),
	'parse_string on default settings works ok with no header' # NB: hw/pos/def/eg because of previous reads
);
ok(
	compare_struct(
		$parser->parse_string("#*hw:pos\na:det\naardvark:n", {field_sep=>":"}) , 
		[{hw=>'a', pos=>'det'}, {hw=>'aardvark', pos=>'n'}] 
	),
	'parse_string field_sep works'
);
ok(
	compare_struct(
		$parser->parse_string("#*hw\tpos;a\tdet;aardvark\tn", {line_sep=>";"}) , 
		[{hw=>'a', pos=>'det'}, {hw=>'aardvark', pos=>'n'}] 
	),
	'parse_string line_sep works'
);
ok(
	compare_struct(
		$parser->parse_file('t/parse-crlf-comma.csv', undef, {field_sep=>",",header_marker=>0,line_sep=>"\x0d\x0a"}),
		[{'hw' => 'head','pos' => 'n','def' => 'thing on top of your shoulders','gw' => 'NOGGIN'}]
	),
	'parse_file field_sep works (setting line_sep to CRLF)'
);
ok(
	compare_struct(
		$parser->parse_file('t/parse-lf-comma.csv', undef, {field_sep=>",",header_marker=>0,line_sep=>"\x0a"}),
		[{'hw' => 'head','pos' => 'n','def' => 'thing on top of your shoulders','gw' => 'NOGGIN'}]
	),
	'parse_file field_sep works (setting line_sep to LF)'
);

# check File::BOM works, if we have it.


