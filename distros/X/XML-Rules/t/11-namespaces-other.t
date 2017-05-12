#!perl -T

use strict;
use warnings;
use Test::More tests => 11;

use XML::Rules;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys = 1;

my $xml = <<'*END*';
<doc xmlns:a="http://www.some.sdf/sdf_a" xmlns:b="http://www.some.sdf/sdf_b" xmlns:x="http://www.some.sdf/sdf_x" xmlns:y="http://www.some.sdf/sdf_y">
 <a:tag_a>value A</a:tag_a>
 <b:tag_b>value B</b:tag_b>
 <x:tag_x>value X</x:tag_x>
 <y:tag_y>value Y</y:tag_y>
 <a:parent_a>value A<child_in_a>chld</child_in_a> <a:child_a>chld A</a:child_a> <x:child_x>chld X</x:child_x> </a:parent_a>
 <b:parent_b>value B<child_in_b>chld</child_in_b> <a:child_a>chld A</a:child_a> <x:child_x>chld X</x:child_x> </b:parent_b>
 <x:parent_x>value X<child_in_x>chld</child_in_x> <a:child_a>chld A</a:child_a> <x:child_x>chld X</x:child_x> </x:parent_x>
 <y:parent_y>value Y<child_in_y>chld</child_in_y> <a:child_a>chld A</a:child_a> <x:child_x>chld X</x:child_x> </y:parent_y>
 <parent_c xmlns="http://www.some.sdf/sdf_c">value A<child_in_c>chld</child_in_c> <a:child_a>chld A</a:child_a> <x:child_x>chld X</x:child_x> </parent_c>
 <parent_z xmlns="http://www.some.sdf/sdf_z">value X<child_in_z>chld</child_in_z> <a:child_a>chld A</a:child_a> <x:child_x>chld X</x:child_x> </parent_z>
</doc>
*END*

my $result_keep =
{
  doc => {
	'A:parent_a' => {
	  'A:child_a' => 'chld A',
	  _content => 'value A   ',
	  child_in_a => 'chld',
	  'x:child_x' => 'chld X'
	},
	'A:tag_a' => 'value A',
	'b:parent_b' => {
	  'A:child_a' => 'chld A',
	  _content => 'value B   ',
	  child_in_b => 'chld',
	  'x:child_x' => 'chld X'
	},
	'b:tag_b' => 'value B',
	'c:parent_c' => {
	  'A:child_a' => 'chld A',
	  _content => 'value A   ',
	  'c:child_in_c' => 'chld',
	  'x:child_x' => 'chld X'
	},
	'ns1:parent_z' => {
	  'A:child_a' => 'chld A',
	  _content => 'value X   ',
	  'ns1:child_in_z' => 'chld',
	  'x:child_x' => 'chld X',
	  'xmlns:ns1' => 'http://www.some.sdf/sdf_z'
	},
	'x:parent_x' => {
	  'A:child_a' => 'chld A',
	  _content => 'value X   ',
	  child_in_x => 'chld',
	  'x:child_x' => 'chld X'
	},
	'x:tag_x' => 'value X',
	'xmlns:x' => 'http://www.some.sdf/sdf_x',
	'xmlns:y' => 'http://www.some.sdf/sdf_y',
	'y:parent_y' => {
	  'A:child_a' => 'chld A',
	  _content => 'value Y   ',
	  child_in_y => 'chld',
	  'x:child_x' => 'chld X'
	},
	'y:tag_y' => 'value Y'
  }
};

my $result_strip =
{
  doc => {
    'A:child_a' => 'chld A',
    'A:parent_a' => {
      'A:child_a' => 'chld A',
      _content => 'value A   ',
      child_in_a => 'chld'
    },
    'A:tag_a' => 'value A',
    'b:parent_b' => {
      'A:child_a' => 'chld A',
      _content => 'value B   ',
      child_in_b => 'chld'
    },
    'b:tag_b' => 'value B',
    'c:parent_c' => {
      'A:child_a' => 'chld A',
      _content => 'value A   ',
      'c:child_in_c' => 'chld'
    },
    child_in_x => 'chld',
    child_in_y => 'chld'
  }
};

my $result_flatten =
{
  doc => {
    'A:parent_a' => {
      'A:child_a' => 'chld A',
      _content => 'value A   ',
      child_in_a => 'chld',
      child_x => 'chld X'
    },
    'A:tag_a' => 'value A',
    'b:parent_b' => {
      'A:child_a' => 'chld A',
      _content => 'value B   ',
      child_in_b => 'chld',
      child_x => 'chld X'
    },
    'b:tag_b' => 'value B',
    'c:parent_c' => {
      'A:child_a' => 'chld A',
      _content => 'value A   ',
      'c:child_in_c' => 'chld',
      child_x => 'chld X'
    },
    parent_x => {
      'A:child_a' => 'chld A',
      _content => 'value X   ',
      child_in_x => 'chld',
      child_x => 'chld X'
    },
    parent_y => {
      'A:child_a' => 'chld A',
      _content => 'value Y   ',
      child_in_y => 'chld',
      child_x => 'chld X'
    },
    parent_z => {
      'A:child_a' => 'chld A',
      _content => 'value X   ',
      child_in_z => 'chld',
      child_x => 'chld X'
    },
    tag_x => 'value X',
    tag_y => 'value Y'
  }
};

my $parser = new XML::Rules (
	rules => [
		_default => 'as is',
		qr/tag_|child/ => 'content',
		doc => 'no content',
	],
	namespaces => {
		"http://www.some.sdf/sdf_a" => 'A',
		"http://www.some.sdf/sdf_b" => 'b',
		"http://www.some.sdf/sdf_c" => 'c',
	},
);

my $warnings = '';
$SIG{__WARN__} = sub {$warnings .= $_[0]};

{
	$warnings = '';
	my $result = $parser->parsestring($xml);
	is_deeply( $result, $result_keep,	"Known and unknown namespaces, warn and keep");

	ok( $warnings =~ m{^(Unexpected namespace "http://www\.some\.sdf/sdf_[xy]" found in the XML!\n){2}Unexpected namespace "http://www\.some\.sdf/sdf_z" found in the XML!$}, "The warnings were printed");
}

{
	$warnings = '';
	$parser->{namespaces}{'*'} = 'keep';
	my $result = $parser->parsestring($xml);
	is_deeply( $result, $result_keep, "Known and unknown namespaces, keep and stay silent");

	is( $warnings, '', "No warnings were printed");
}

{
	$warnings = '';
	$parser->{namespaces}{'*'} = 'strip';
	my $result = $parser->parsestring($xml);
#print Dumper($result);
	is_deeply( $result, $result_strip, "Known and unknown namespaces, strip tags/attributes in unknown namespaces");

	is( $warnings, '', "No warnings were printed");
}

{
	$warnings = '';
	$parser->{namespaces}{'*'} = '';
	my $result = $parser->parsestring($xml);
#print Dumper($result);
	is_deeply( $result, $result_flatten, "Known and unknown namespaces, namespaces->{'*'}='' (remove xmlns:xx and xx:)");

	is( $warnings, '', "No warnings were printed");
}

{
	$warnings = '';
	$parser->{namespaces}{'*'} = 'die';
	eval {
		my $result = $parser->parsestring($xml);
#print Dumper($result);
	};
	ok( $@ =~ m{Unexpected namespace "http://www\.some\.sdf/sdf_[xy]" found in the XML! at}, "Known and unknown namespaces, die if an unknown is found");

	is( $warnings, '', "No warnings were printed");
}


{

	my $xml = <<'*END*';
<doc xmlns:a="http://www.some.sdf/sdf_a" xmlns:x="http://www.some.sdf/sdf_x">
 <a:tag_a attr_a="blah A">value A</a:tag_a>
 <x:tag_x attr_x="blah X">value X</x:tag_x>
 <x:parent_x attr_x="blaaah X">value X<child_in_x>chld</child_in_x> <a:child_a1>chld A</a:child_a1> <x:child_x>chld X</x:child_x> </x:parent_x>
 <parent_z attr_z="blaaah Z" xmlns="http://www.some.sdf/sdf_z">value X<child_in_z>chld</child_in_z> <a:child_a>chld A</a:child_a> <x:child_x>chld X</x:child_x> </parent_z>
 <keep>This will be <x:bogus>skipped <u>bold</u> skipped again</x:bogus>. You know.</keep>
</doc>
*END*

	my $result_keep_inner =
{
  doc => {
    'A:child_a' => {
      _content => 'chld A'
    },
    'A:child_a1' => {
      _content => 'chld A'
    },
    'A:tag_a' => {
      _content => 'value A',
      attr_a => 'blah A'
    },
    child_in_x => {
      _content => 'chld'
    },
    keep => 'This will be _bold_. You know.'
  }
};

	my $parser = new XML::Rules (
		rules => [
			_default => 'as is',
			doc => 'no content',
			keep => 'content',
			u => sub {'_' . $_[1]->{_content} . '_'},
		],
		namespaces => {
			"http://www.some.sdf/sdf_a" => 'A',
			"http://www.some.sdf/sdf_b" => 'b',
			"http://www.some.sdf/sdf_c" => 'c',
			"*" => 'strip',
		},
	);
	my $result = $parser->parsestring($xml);
#print Dumper($result);
	is_deeply( $result, $result_keep_inner, "Known and unknown namespaces, strip tags/attributes in unknown namespaces, keep inner tags");
}

__END__
print Dumper($result);

#
