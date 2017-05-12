#!perl -T

use strict;
use warnings;
use Test::More tests => 17;

BEGIN { use_ok( 'XML::Rules' ); }

my $xml = <<'*END*';
<doc>
 <person>
  <fname>Jane</fname>
  <lname>Luser</lname>
  <email>JLuser@bogus.com</email>
  <address>
   <street>Washington st.</street>
   <city>Old Creek</city>
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
  <fname>John</fname>
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
</doc>
*END*

{ #1
	my $parser = new XML::Rules (
		rules => [
			_default => 'content',
			'^bogus' => undef, # means "ignore"
			address => sub {address => "$_[1]->{street}, $_[1]->{city} ($_[1]->{country})"},
			person => sub {
				#print Dumper($_[2], $_[3]);
				return '@person' => "$_[1]->{lname}, $_[1]->{fname}\n<$_[1]->{email}>\n$_[1]->{address}"
			},
			doc => sub { join "\n\n", @{$_[1]->{person}} },
		]
	);
	ok(($parser and ref($parser)), 'Create 1st parser');

	my $result = $parser->parsestring($xml) . "\n";

	my $correct = <<'*END*';
Luser, Jane
<JLuser@bogus.com>
Washington st., Old Creek (The US)

Other, John
<JOther@silly.com>
Grant's st., New Creek (Canada)
*END*

	is  ($result, $correct, "Convert XML to text");
}

{ #2
	my $foo_count = 0;
	my $parser = new XML::Rules (
		rules => [
			_default => 'content',
		#	bogus => '', # means "returns no value. The subtags ARE processed.
			'^bogus' => '', # means "ignore". The subtags ARE NOT processed.
			phones => undef,
			address => 'no content',
			person => 'no content array',
			doc => sub {$_[1]->{person}}, #'pass no content',
			foo => sub {$foo_count++;return},
		]
	);
	ok(($parser and ref($parser)), 'Create 2nd parser');

	my $result = $parser->parsestring($xml);

	my $correct = [
	  {
		'email' => 'JLuser@bogus.com',
		'lname' => 'Luser',
		'fname' => 'Jane',
		'address' => {
					 'country' => 'The US',
					 'city' => 'Old Creek',
					 'street' => 'Washington st.'
				   }
	  },
	  {
		'email' => 'JOther@silly.com',
		'lname' => 'Other',
		'fname' => 'John',
		'address' => {
					 'country' => 'Canada',
					 'city' => 'New Creek',
					 'street' => 'Grant\'s st.'
				   }
	  }
	];

	is_deeply($result, $correct, "Convert XML to structure");

	is( $foo_count, 0, "The <foo> tag should be ignored as it's only inside <bogus>");
}

{ #3
	my $buff;
	open my $OUT, '>', \$buff;

	my $parser = new XML::Rules (
		rules => {
			_default => 'content',
			'^bogus' => undef, # means "ignore"
			address => 'no content',
			person => sub {
				print $OUT <<"*END*";
Person: $_[1]->{fname} $_[1]->{lname}
Email:  $_[1]->{email}
Address: $_[1]->{address}{street}
         $_[1]->{address}{city}
         $_[1]->{address}{country}

*END*
				return '+count' => 1;
			},
			doc => sub {print $OUT "Printed $_[1]->{count} addresses.\n";return},
		}
	);
	ok(($parser and ref($parser)), 'Create 3rd parser');

	my $result = $parser->parsestring($xml);

	my $correct = <<'*END*';
Person: Jane Luser
Email:  JLuser@bogus.com
Address: Washington st.
         Old Creek
         The US

Person: John Other
Email:  JOther@silly.com
Address: Grant's st.
         New Creek
         Canada

Printed 2 addresses.
*END*

	is  ($buff, $correct, "Convert XML to text, print each completed <person>");
	is	($result, undef, "Nothing to return");
}

{ #4
	my $buff;
	open my $OUT, '>', \$buff;

	my $parser = new XML::Rules (
		rules => {
			_default => sub {$_[0] => $_[1]->{_content}},
			'fname,lname' => sub {$_[0] => $_[1]->{_content}},
			'^bogus' => undef,
			address => sub {address => "$_[1]->{street}, $_[1]->{city} ($_[1]->{country})"},
			phone => sub {$_[1]->{type} => $_[1]->{_content}},
				# let's use the "type" attribute as the key and the content as the value
			phones => sub {delete $_[1]->{_content}; %{$_[1]}},
				# remove the text content and pass along the type => content from the child nodes
			person => sub { # lets print the values, all the data is readily available in the attributes
				print $OUT "$_[1]->{lname}, $_[1]->{fname} <$_[1]->{email}>\n";
				print $OUT "Home phone: $_[1]->{home}\n" if $_[1]->{home};
				print $OUT "Office phone: $_[1]->{office}\n" if $_[1]->{office};
				print $OUT "Fax: $_[1]->{fax}\n" if $_[1]->{fax};
				print $OUT "$_[1]->{address}\n\n";
				return; # the <person> tag is processed, no need to remember what it contained
			},
		}
	);
	ok(($parser and ref($parser)), 'Create 4th parser');

	my $result = $parser->parsestring($xml);

	my $correct = <<'*END*';
Luser, Jane <JLuser@bogus.com>
Home phone: 123-456-7890
Office phone: 663-486-7890
Fax: 663-486-7000
Washington st., Old Creek (The US)

Other, John <JOther@silly.com>
Office phone: 663-486-7891
Grant's st., New Creek (Canada)

*END*

	is  ($buff, $correct, "Convert XML to text, print each completed <person>, simplify address");

}

{ #5
	my $foo_count = 0;
	my $parser = new XML::Rules (
		rules => [
			_default => 'content',
			'^bogus' => undef, # means "ignore"
			phones => undef,
			address => sub {delete $_[1]->{_content}; $_[1]},
			person => 'as array',
			doc => 'pass no content',
			foo => sub {$foo_count++;return;},
			'/^.name$/' => sub {$_[0] => $_[1]->{_content}},
		]
	);
	ok(($parser and ref($parser)), 'Create 5th parser');

	my $result = $parser->parsestring($xml);

	my $correct = {
          'person' => [
                      {
                        'email' => 'JLuser@bogus.com',
                        '_content' => [
                                        "\n  \n  \n  \n  ",
                                        {
                                          'country' => 'The US',
                                          'city' => 'Old Creek',
                                          'street' => 'Washington st.'
                                        },
                                        "\n  \n "
                                      ],
                        'lname' => 'Luser',
                        'fname' => 'Jane'
                      },
                      {
                        'email' => 'JOther@silly.com',
                        '_content' => [
                                        "\n  \n  \n  \n  ",
                                        {
                                          'country' => 'Canada',
                                          'city' => 'New Creek',
                                          'street' => 'Grant\'s st.'
                                        },
                                        "\n  \n "
                                      ],
                        'lname' => 'Other',
                        'fname' => 'John'
                      }
                    ]
        };
	is_deeply($result, $correct, "Convert XML to structure");
}

{ # 6
	my $xml = <<'*END*';
<doc>
 <book>
  <name>Valka s mloky</name>
  <author>Karel Capek</author>
  <description>It's really <b>something</b> and I have to <u>underline it</u>.</description>
 </book>
 <book>
  <name>Predtucha</name>
  <author>Pujmanova</author>
  <description>It's really a <u>stupid</u> pointless book.
Confront <link id="12345">this one</link>. And don't read this one please!
  </description>
 </book>
</doc>
*END*

	my $buff;
	open my $OUT, '>', \$buff;

	my $parser = new XML::Rules (
		rules => [
			_default => 'content',
			u => sub {my $str = $_[1]->{_content}; $str =~ tr/ /_/; return '_'.$str.'_'},
			b => sub {my $str = $_[1]->{_content}; return '*'.$str.'*'},
			link => sub { qq{<a href="http://www.books.com/find_book.pl?id=$_[1]->{id}">$_[1]->{_content}</a>} },
			description => sub {my $desc = $_[1]->{_content}; $desc =~ s/^\s+//;$desc =~ s/\s+$//; return 'description' => $desc},
			book => sub {
				my $desc = $_[1]->{description};
				$desc =~ s/\n/\n\t/g;
				print $OUT "Book: $_[1]->{name}\nAuthor: $_[1]->{author}\nDescription: $desc\n\n";
			},
		],
	);

	$parser->parsestring($xml);

	my $correct = <<'*END*';
Book: Valka s mloky
Author: Karel Capek
Description: It's really *something* and I have to _underline_it_.

Book: Predtucha
Author: Pujmanova
Description: It's really a _stupid_ pointless book.
	Confront <a href="http://www.books.com/find_book.pl?id=12345">this one</a>. And don't read this one please!

*END*

	is  ($buff, $correct, "Convert XML to text, print each completed <person>");
}


{ #7
	my $xml = <<'*END*';
<foo>
	<bar id="hello">
		<x>Chiao</x>
		<x>Ahoj</x>
		<x>Hola</x>
		<x>Chao</x>
		<x>Hi</x>
		<x>Hello</x>
	</bar>
	<bar id="GoodBye">
		<x>Hasta luego</x>
		<x>Nashle</x>
		<x>Dosvidania</x>
		<x>Farewell</x>
	</bar>
</foo>
*END*
	my $parser = new XML::Rules (
		rules => [
			'x' => sub {'.x' => $_[1]->{_content} . ', '},
			bar => sub {$_[1]->{x} =~ s/, $//; return $_[1]->{id} => $_[1]->{x}},
			foo => 'pass no content',
		]
	);

	my $result = $parser->parsestring($xml);

	my $correct = {
		'GoodBye' => 'Hasta luego, Nashle, Dosvidania, Farewell',
		'hello' => 'Chiao, Ahoj, Hola, Chao, Hi, Hello'
	};

	is_deeply($result, $correct, "Test '.attrname'");
}


{ #8
	my $xml = <<'*END*';
<doc>
	7
	<times>3</times>
	<plus>-6</plus>
	<plus>
		5
		<times>4</times>
	</plus>
</doc>
*END*
	my $parser = new XML::Rules (
		rules => [
			'times' => sub {'*_content' => $_[1]->{_content}},
			'plus' => sub {'+_content' => $_[1]->{_content}},
			'doc' => 'pass trim',
		]
	);
	my $result = $parser->parsestring($xml);

	my $correct = 7*3 -6 + (5 * 4);

	is($result, $correct, "Test '+attrname' and '*attrname'");
}

{ #9
	my $xml = <<'*END*';
<doc>
	<foo status="on"><bar>1</bar></foo>
	<foo status="off"><bar>2</bar></foo>
	<foo status="off"><bar>3</bar></foo>
	<foo status="on"><bar>4</bar></foo>
</doc>
*END*
	my $buff;
	open my $OUT, '>', \$buff;

	my $parser = new XML::Rules (
		rules => [
			'bar' => sub {print $OUT "Found <bar>$_[1]->{_content}</bar>, preset is $_[3]->[-1]{preset}\n"; return},
			'^foo' => sub {$_[1]->{preset} = 12345; return ($_[1]->{status} eq 'on')},
			'foo' => '',
			'doc' => '',
		]
	);

	$parser->parsestring($xml);
	close $OUT;

	my $correct = <<'*END*';
Found <bar>1</bar>, preset is 12345
Found <bar>4</bar>, preset is 12345
*END*

	is($buff, $correct, "Test '^tagname' rules");
}
