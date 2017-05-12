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
	return 0;
}
sub compare_string
{
	if ($_[0] eq $_[1])
	{
		return 1;
	}
	else 
	{
		print $_[0] ."\n". $_[1]. "\n";
	}
	return 0
}
my $parser = WordLists::Parse::Simple->new();
my $serialiser = WordLists::Serialise::Simple->new();

use Test::More qw(no_plan);

isa_ok($parser, 'WordLists::Parse::Simple', 'Created Parser OK');
isa_ok($serialiser, 'WordLists::Serialise::Simple' ,'Created Serialiser OK');
can_ok($serialiser, 'to_string');
ok(
	compare_string(
		'a',
		'a'
	),
	'The testing framework correctly identifies matching strings'
);
ok(
	!compare_string(
		'a',
		'b'
	),
	'The testing framework correctly identifies nonmatching strings'
);

ok(	
	compare_string
	(
		$serialiser->to_string({hw=>'a', pos=>'det'}),
		"a\tdet\t\t",
	),
	'The serialiser can output a simple hashref'
);
ok(	
	compare_string
	(
		$serialiser->to_string([{hw=>'a', pos=>'det'}, {hw=>'aardvark', pos=>'n'}] ),
		"#*hw\tpos\tdef\teg\na\tdet\t\t\naardvark\tn\t\t\n",
	),
	'The serialiser can output a simple arrayref'
);
ok(	
	compare_string
	(
		$serialiser->to_string([{hw=>'a', pos=>'det'}, {hw=>'aardvark', pos=>'n'}] ),
		"#*hw\tpos\tdef\teg\na\tdet\t\t\naardvark\tn\t\t\n",
	),
	'The serialiser can output a simple arrayref'
);