#!perl -T

use strict;
use warnings;
use Test::More tests => 7;

use XML::Rules;

my $xml = <<'*END*';
<?xml version="1.0"?>
<doc>
 <person>
  <fname>Jane</fname>
  <lname>Luser</lname>
  <email>JLuser@bogus.com</email>
  <address>
   <street>Washington st.</street>
   <city>Old Creek &amp; Pond</city>
   <country>The US</country>
   <bogus>bleargh</bogus>
  </address>
  <phones>
   <phone type="home">123-456-7890</phone>
   <phone type="office">663-486-7890</phone>
   <phone type="fax">663-486-7000</phone>
  </phones>
 </person>
 <person>
  <fname>John&amp;Mary</fname>
  <lname>Other</lname>
  <email>JOther@silly.com</email>
  <address>
   <street>Grant's st.</street>
   <city>New Creek</city>
   <country>Canada</country>
   <bogus>sdrysdfgtyh degtrhy <foo>degtrhy werthy</foo>werthy drthyu</bogus>
  </address>
  <phones>
   <phone type="office">663-486-7891</phone>
  </phones>
 </person>
 <start_only/>
 <empty></empty>
</doc>
*END*

{ #1
	my $parser = new XML::Rules (
		style => 'filter',
		rules => [
#			'^phone' => sub {return exists($_[1]->{type}) and $_[1]->{type} eq 'office'},
			'phone' => sub {
				return unless $_[1]->{type} eq 'office';
				return $_[0] => $_[1];
			}
		]
	);

	my $res = '';
	open my $FH, '>', \$res;
	$parser->filterstring($xml, $FH);
	close $FH;

	(my $correct = $xml) =~ s{<phone type="(home|fax)">[^<]+</phone>}{}g;
	is($res, $correct, "Remove tag according to attribute");
#open my $F, '>', 'test_mine.txt';print $F $res;close $F;
#open $F, '>', 'test_correct.txt';print $F $correct;close $F;
}

{ #2
	my $parser = new XML::Rules (
		style => 'filter',
		rules => [
			'^phone' => sub {return (exists($_[1]->{type}) and $_[1]->{type} eq 'office')},
		]
	);

	my $res = '';
	open my $FH, '>', \$res;
	$parser->filterstring($xml, $FH);
	close $FH;

#print $res;
#exit;

	(my $correct = $xml) =~ s{<phone type="(home|fax)">[^<]+</phone>}{}g;
	is($res, $correct, "Remove tag according to attribute using start rule");
#open my $F, '>', 'test_mine.txt';print $F $res;close $F;
#open $F, '>', 'test_correct.txt';print $F $correct;close $F;
}


{ #3
	my $parser = new XML::Rules (
		style => 'filter',
		rules => [
			'fname' => sub {
				$_[1]->{_content} = ":" . $_[1]->{_content} . ":";
				return $_[0] => $_[1];
			},
		]
	);

	my $res = '';
	open my $FH, '>', \$res;
	$parser->filterstring($xml, $FH);
	close $FH;

	(my $correct = $xml) =~ s{<fname>([^<]+)</fname>}{<fname>:$1:</fname>}g;
	is($res, $correct, "Tweak the content of <fname>");
#open my $F, '>', 'test_mine.txt';print $F $res;close $F;
#open $F, '>', 'test_correct.txt';print $F $correct;close $F;
}

{ #4
	my $parser = new XML::Rules (
		style => 'filter',
		rules => [
			'fname' => sub {return 'firstname' => $_[1]},
			'lname' => sub {return 'lastname' => $_[1]},
		]
	);

	my $res = '';
	open my $FH, '>', \$res;
	$parser->filterstring($xml, $FH);
	close $FH;

	(my $correct = $xml) =~ s{<fname>([^<]+)</fname>}{<firstname>$1</firstname>}g;
	$correct =~ s{<lname>([^<]+)</lname>}{<lastname>$1</lastname>}g;
	is($res, $correct, "Change <fname> to <firstname> and <lname> to <lastname>");
#open my $F, '>', 'test_mine.txt';print $F $res;close $F;
#open $F, '>', 'test_correct.txt';print $F $correct;close $F;
}

{ #5
	my $parser = new XML::Rules (
		style => 'filter',
		rules => [
			'phone' => sub {$_[1]->{type} => $_[1]->{_content}},
			'phones' => sub {
				if (exists $_[1]->{home}) {
					return 'phone' => $_[1]->{home}
				} else {
					return 'phone' => $_[1]->{office}
				}
			},
		]
	);

	my $res = '';
	open my $FH, '>', \$res;
	$parser->filterstring($xml, $FH);
	close $FH;

	(my $correct = $xml) =~ s{<phones>.*?</phones>}{<phone>123-456-7890</phone>}s;
	$correct =~ s{<phones>.*?</phones>}{<phone>663-486-7891</phone>}s;
	is($res, $correct, "Change <phones> to a single <phone> using the home or office phone");
#open my $F, '>', 'test_mine.txt';print $F $res;close $F;
#open $F, '>', 'test_correct.txt';print $F $correct;close $F;
}

{ #6
	my $parser = new XML::Rules (
		style => 'filter',
		ident => ' ',
		rules => [
			'phone' => sub {$_[1]->{_content} = "(1)" . $_[1]->{_content}; return $_[1]->{type} => [$_[1]->{_content}]},
			'phones' => sub {
				delete $_[1]->{_content};
				$_[1]->{home} = ['not_specified'] unless exists $_[1]->{home};
				$_[1]->{office} = ['not_specified'] unless exists $_[1]->{office};
				$_[1]->{fax} = ['not_specified'] unless exists $_[1]->{fax};

				return $_[0] => $_[1];
			},
		]
	);

	my $res = '';
	open my $FH, '>', \$res;
	$parser->filterstring($xml, $FH);
	close $FH;

	my $correct = <<'*END*';
<?xml version="1.0"?>
<doc>
 <person>
  <fname>Jane</fname>
  <lname>Luser</lname>
  <email>JLuser@bogus.com</email>
  <address>
   <street>Washington st.</street>
   <city>Old Creek &amp; Pond</city>
   <country>The US</country>
   <bogus>bleargh</bogus>
  </address>
  <phones>
   <fax>(1)663-486-7000</fax>
   <home>(1)123-456-7890</home>
   <office>(1)663-486-7890</office>
  </phones>
 </person>
 <person>
  <fname>John&amp;Mary</fname>
  <lname>Other</lname>
  <email>JOther@silly.com</email>
  <address>
   <street>Grant's st.</street>
   <city>New Creek</city>
   <country>Canada</country>
   <bogus>sdrysdfgtyh degtrhy <foo>degtrhy werthy</foo>werthy drthyu</bogus>
  </address>
  <phones>
   <fax>not_specified</fax>
   <home>not_specified</home>
   <office>(1)663-486-7891</office>
  </phones>
 </person>
 <start_only/>
 <empty></empty>
</doc>
*END*

	is($res, $correct, "Change <phones> to a <phone_type> tags and include all types");
#open my $F, '>', 'test_mine.txt';print $F $res;close $F;
#open $F, '>', 'test_correct.txt';print $F $correct;close $F;
}

{ #7
	my $parser = new XML::Rules (
		style => 'filter',
		ident => ' ',
		rules => [
			'phone' => sub {$_[1]->{_content} = "(1)" . $_[1]->{_content}; return $_[1]->{type} => [$_[1]->{_content}]},
		]
	);

	my $res = '';
	open my $FH, '>', \$res;
	$parser->filterstring($xml, $FH);
	close $FH;

	my $correct = <<'*END*';
<?xml version="1.0"?>
<doc>
 <person>
  <fname>Jane</fname>
  <lname>Luser</lname>
  <email>JLuser@bogus.com</email>
  <address>
   <street>Washington st.</street>
   <city>Old Creek &amp; Pond</city>
   <country>The US</country>
   <bogus>bleargh</bogus>
  </address>
  <phones>
   <home>(1)123-456-7890</home>
   <office>(1)663-486-7890</office>
   <fax>(1)663-486-7000</fax>
  </phones>
 </person>
 <person>
  <fname>John&amp;Mary</fname>
  <lname>Other</lname>
  <email>JOther@silly.com</email>
  <address>
   <street>Grant's st.</street>
   <city>New Creek</city>
   <country>Canada</country>
   <bogus>sdrysdfgtyh degtrhy <foo>degtrhy werthy</foo>werthy drthyu</bogus>
  </address>
  <phones>
   <office>(1)663-486-7891</office>
  </phones>
 </person>
 <start_only/>
 <empty></empty>
</doc>
*END*

	is($res, $correct, "Change <phones> to a <phone_type> tags and include all types");
#open my $F, '>', 'test_mine.txt';print $F $res;close $F;
#open $F, '>', 'test_correct.txt';print $F $correct;close $F;
}
