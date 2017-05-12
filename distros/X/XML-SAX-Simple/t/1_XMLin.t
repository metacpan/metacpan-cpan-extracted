use strict;
use warnings;
use IO::File;
use File::Spec;

$|++;

# Initialise filenames and check they're there

my $XMLFile = File::Spec->catfile('t', 'test1.xml');  # t/test1.xml

unless(-e $XMLFile) {
  print STDERR "test data missing...";
  print "1..0\n";
  exit 0;
}


print "1..65\n";

my $t = 1;

##############################################################################
#                   S U P P O R T   R O U T I N E S
##############################################################################

##############################################################################
# Print out 'n ok' or 'n not ok' as expected by test harness.
# First arg is test number (n).  If only one following arg, it is interpreted
# as true/false value.  If two args, equality = true.
#

sub ok {
  my($n, $x, $y) = @_;
  die "Sequence error got $n expected $t" if($n != $t);
  $x = 0 if(@_ > 2  and  $x ne $y);
  print(($x ? '' : 'not '), 'ok ', $t++, "\n");
}


##############################################################################
# Take two scalar values (may be references) and compare them (recursively
# if necessary) returning 1 if same, 0 if different.
#

sub DataCompare {
  my($x, $y) = @_;

  my($i);

  if(!defined($x)) {
    return(1) if(!defined($y));
    print STDERR "$t:DataCompare: undef != $y\n";
    return(0);
  }


  if(!ref($x)) {
    return(1) if($x eq $y);
    print STDERR "$t:DataCompare: $x != $y\n";
    return(0);
  }

  if(ref($x) eq 'ARRAY') {
    unless(ref($y) eq 'ARRAY') {
      print STDERR "$t:DataCompare: expected arrayref, got: $y\n";
      return(0);
    }
    if(scalar(@$x) != scalar(@$y)) {
      print STDERR "$t:DataCompare: expected ", scalar(@$x),
                   " element(s), got: ", scalar(@$y), "\n";
      return(0);
    }
    for($i = 0; $i < scalar(@$x); $i++) {
      DataCompare($x->[$i], $y->[$i]) || return(0);
    }
    return(1);
  }

  if(ref($x) eq 'HASH') {
    unless(ref($y) eq 'HASH') {
      print STDERR "$t:DataCompare: expected hashref, got: $y\n";
      return(0);
    }
    if(scalar(keys(%$x)) != scalar(keys(%$y))) {
      print STDERR "$t:DataCompare: expected ", scalar(keys(%$x)),
                   " key(s), (", join(', ', keys(%$x)),
		   ") got: ",  scalar(keys(%$y)), " (", join(', ', keys(%$y)),
		   ")\n";
      return(0);
    }
    foreach $i (keys(%$x)) {
      unless(exists($y->{$i})) {
	print STDERR "$t:DataCompare: missing hash key - {$i}\n";
	return(0);
      }
      DataCompare($x->{$i}, $y->{$i}) || return(0);
    }
    return(1);
  }

  print STDERR "Don't know how to compare: " . ref($x) . "\n";
  return(0);
}


##############################################################################
#                      T E S T   R O U T I N E S
##############################################################################

eval "use XML::SAX::Simple;";
ok(1, !$@);                       # Module compiled OK

# Start by parsing an extremely simple piece of XML

my $opt = XMLin(q(<opt name1="value1" name2="value2"></opt>));

my $expected = {
		 name1 => 'value1',
		 name2 => 'value2',
	       };

ok(2, 1);                         # XMLin() didn't crash
ok(3, defined($opt));             # and it returned a value
ok(4, ref($opt) eq 'HASH');       # and a hasref at that
ok(5, DataCompare($opt, $expected));


# Now try a slightly more complex one that returns the same value

$opt = XMLin(q(
  <opt>
    <name1>value1</name1>
    <name2>value2</name2>
  </opt>
));
ok(6, DataCompare($opt, $expected));


# And something else that returns the same (line break included to pick up
# missing /s bug)

$opt = XMLin(q(<opt name1="value1"
                    name2="value2" />));
ok(7, DataCompare($opt, $expected));


# Try something with two lists of nested values

$opt = XMLin(q(
  <opt>
    <name1>value1.1</name1>
    <name1>value1.2</name1>
    <name1>value1.3</name1>
    <name2>value2.1</name2>
    <name2>value2.2</name2>
    <name2>value2.3</name2>
  </opt>)
);

ok(8, DataCompare($opt, {
  name1 => [ 'value1.1', 'value1.2', 'value1.3' ],
  name2 => [ 'value2.1', 'value2.2', 'value2.3' ],
}));


# Now a simple nested hash

$opt = XMLin(q(
  <opt>
    <item name1="value1" name2="value2" />
  </opt>)
);

ok(9, DataCompare($opt, {
  item => { name1 => 'value1', name2 => 'value2' }
}));


# Now a list of nested hashes

$opt = XMLin(q(
  <opt>
    <item name1="value1" name2="value2" />
    <item name1="value3" name2="value4" />
  </opt>)
);
ok(10, DataCompare($opt, {
  item => [
            { name1 => 'value1', name2 => 'value2' },
            { name1 => 'value3', name2 => 'value4' }
	  ]
}));


# Now a list of nested hashes transformed into a hash using default key names

my $string = q(
  <opt>
    <item name="item1" attr1="value1" attr2="value2" />
    <item name="item2" attr1="value3" attr2="value4" />
  </opt>
);
my $target = {
  item => {
            item1 => { attr1 => 'value1', attr2 => 'value2' },
            item2 => { attr1 => 'value3', attr2 => 'value4' }
	  }
};
$opt = XMLin($string);
ok(11, DataCompare($opt, $target));


# Same thing left as an array by suppressing default key names

$target = {
  item => [
            {name => 'item1', attr1 => 'value1', attr2 => 'value2' },
            {name => 'item2', attr1 => 'value3', attr2 => 'value4' }
	  ]
};
$opt = XMLin($string, keyattr => [] );
ok(12, DataCompare($opt, $target));


# Same again with alternative key suppression

$opt = XMLin($string, keyattr => {} );
ok(13, DataCompare($opt, $target));


# Try the other two default key attribute names

$opt = XMLin(q(
  <opt>
    <item key="item1" attr1="value1" attr2="value2" />
    <item key="item2" attr1="value3" attr2="value4" />
  </opt>
));
ok(14, DataCompare($opt, {
  item => {
            item1 => { attr1 => 'value1', attr2 => 'value2' },
            item2 => { attr1 => 'value3', attr2 => 'value4' }
	  }
}));


$opt = XMLin(q(
  <opt>
    <item id="item1" attr1="value1" attr2="value2" />
    <item id="item2" attr1="value3" attr2="value4" />
  </opt>
));
ok(15, DataCompare($opt, {
  item => {
            item1 => { attr1 => 'value1', attr2 => 'value2' },
            item2 => { attr1 => 'value3', attr2 => 'value4' }
	  }
}));


# Similar thing using non-standard key names

my $xml = q(
  <opt>
    <item xname="item1" attr1="value1" attr2="value2" />
    <item xname="item2" attr1="value3" attr2="value4" />
  </opt>);

$target = {
  item => {
            item1 => { attr1 => 'value1', attr2 => 'value2' },
            item2 => { attr1 => 'value3', attr2 => 'value4' }
	  }
};

$opt = XMLin($xml, keyattr => [qw(xname)]);
ok(16, DataCompare($opt, $target));


# And with precise element/key specification

$opt = XMLin($xml, keyattr => { 'item' => 'xname' });
ok(17, DataCompare($opt, $target));


# Same again but with key field further down the list

$opt = XMLin($xml, keyattr => [qw(wibble xname)]);
ok(18, DataCompare($opt, $target));


# Same again but with key field supplied as scalar

$opt = XMLin($xml, keyattr => qw(xname));
ok(19, DataCompare($opt, $target));


# Weird variation, not exactly what we wanted but it is what we expected
# given the current implementation and we don't want to break it accidently

$xml = q(
<opt>
  <item id="one" value="1" name="a" />
  <item id="two" value="2" />
  <item id="three" value="3" />
</opt>
);

$target = { item => {
    'three' => { 'value' => 3 },
    'a'     => { 'value' => 1, 'id' => 'one' },
    'two'   => { 'value' => 2 }
  }
};

$opt = XMLin($xml);
ok(20, DataCompare($opt, $target));


# Or somewhat more as one might expect

$target = { item => {
    'one'   => { 'value' => '1', 'name' => 'a' },
    'two'   => { 'value' => '2' },
    'three' => { 'value' => '3' },
  }
};
$opt = XMLin($xml, keyattr => { 'item' => 'id' });
ok(21, DataCompare($opt, $target));


# Now a somewhat more complex test of targetting folding

$xml = q(
<opt>
  <car license="SH6673" make="Ford" id="1">
    <option key="1" pn="6389733317-12" desc="Electric Windows"/>
    <option key="2" pn="3735498158-01" desc="Leather Seats"/>
    <option key="3" pn="5776155953-25" desc="Sun Roof"/>
  </car>
  <car license="LW1804" make="GM"   id="2">
    <option key="1" pn="9926543-1167" desc="Steering Wheel"/>
  </car>
</opt>
);

$target = {
  'car' => {
    'LW1804' => {
      'id' => 2,
      'make' => 'GM',
      'option' => {
	  '9926543-1167' => { 'key' => 1, 'desc' => 'Steering Wheel' }
      }
    },
    'SH6673' => {
      'id' => 1,
      'make' => 'Ford',
      'option' => {
	  '6389733317-12' => { 'key' => 1, 'desc' => 'Electric Windows' },
	  '3735498158-01' => { 'key' => 2, 'desc' => 'Leather Seats' },
	  '5776155953-25' => { 'key' => 3, 'desc' => 'Sun Roof' }
      }
    }
  }
};

$opt = XMLin($xml, forcearray => 1, keyattr => { 'car' => 'license', 'option' => 'pn' });
ok(22, DataCompare($opt, $target));


# Now try leaving the keys in place

$target = {
  'car' => {
    'LW1804' => {
      'id' => 2,
      'make' => 'GM',
      'option' => {
	  '9926543-1167' => { 'key' => 1, 'desc' => 'Steering Wheel',
	                      '-pn' => '9926543-1167' }
      },
      license => 'LW1804'
    },
    'SH6673' => {
      'id' => 1,
      'make' => 'Ford',
      'option' => {
	  '6389733317-12' => { 'key' => 1, 'desc' => 'Electric Windows',
	                       '-pn' => '6389733317-12' },
	  '3735498158-01' => { 'key' => 2, 'desc' => 'Leather Seats',
	                       '-pn' => '3735498158-01' },
	  '5776155953-25' => { 'key' => 3, 'desc' => 'Sun Roof',
	                       '-pn' => '5776155953-25' }
      },
      license => 'SH6673'
    }
  }
};
$opt = XMLin($xml, forcearray => 1, keyattr => { 'car' => '+license', 'option' => '-pn' });
ok(23, DataCompare($opt, $target));


# Make sure that the root element name is preserved if we ask for it

$target = XMLin("<opt>$xml</opt>", forcearray => 1,
                keyattr => { 'car' => '+license', 'option' => '-pn' });

$opt    = XMLin(      $xml,        forcearray => 1, keeproot => 1,
                keyattr => { 'car' => '+license', 'option' => '-pn' });

ok(24, DataCompare($opt, $target));


# confirm that CDATA sections parse correctly

$xml = q{<opt><cdata><![CDATA[<greeting>Hello, world!</greeting>]]></cdata></opt>};
$opt = XMLin($xml);
ok(25, DataCompare($opt, {
  'cdata' => '<greeting>Hello, world!</greeting>'
}));

$xml = q{<opt><x><![CDATA[<y>one</y>]]><![CDATA[<y>two</y>]]></x></opt>};
$opt = XMLin($xml);
ok(26, DataCompare($opt, {
  'x' => '<y>one</y><y>two</y>'
}));


# Try parsing a named external file

$opt = eval{ XMLin($XMLFile); };
ok(27, !$@);                                  # XMLin didn't die
print STDERR $@ if($@);
ok(28, DataCompare($opt, {
  location => 't/test1.xml'
}));


# Try parsing default external file (scriptname.xml in script directory)

$opt = eval { XMLin(); };
print STDERR $@ if($@);
ok(29, !$@);                                  # XMLin didn't die
ok(30, DataCompare($opt, {
  location => 't/1_XMLin.xml'
}));


# Try parsing named file in a directory in the searchpath

$opt = eval {
  XMLin('test2.xml', searchpath => [
    'dir1', 'dir2', File::Spec->catdir('t', 'subdir')
  ] );

};
print STDERR $@ if($@);
ok(31, !$@);                                  # XMLin didn't die
ok(32, DataCompare($opt, { location => 't/subdir/test2.xml' }));


# Ensure we get expected result if file does not exist

$opt = eval {
  XMLin('bogusfile.xml', searchpath => [qw(. ./t)] ); # should 'die'
};
ok(33, !defined($opt));                          # XMLin failed
ok(34, $@ =~ /Could not find bogusfile.xml in/); # with the expected message


# Try parsing from an IO::Handle

my $fh = new IO::File;
$XMLFile = File::Spec->catfile('t', '1_XMLin.xml');  # t/1_XMLin.xml
$fh->open($XMLFile) || die "$!";
$opt = XMLin($fh);
ok(35, 1);                                      # XMLin didn't die
ok(36, $opt->{location}, 't/1_XMLin.xml');      # and it parsed the right file


# Try parsing from STDIN

close(STDIN);
open(STDIN, $XMLFile) || die "$!";
$opt = XMLin('-');
ok(37, $opt->{location}, 't/1_XMLin.xml');      # parsed the right file


# Confirm anonymous array folding works in general

$opt = XMLin(q(
  <opt>
    <row>
      <anon>0.0</anon><anon>0.1</anon><anon>0.2</anon>
    </row>
    <row>
      <anon>1.0</anon><anon>1.1</anon><anon>1.2</anon>
    </row>
    <row>
      <anon>2.0</anon><anon>2.1</anon><anon>2.2</anon>
    </row>
  </opt>
));
ok(38, DataCompare($opt, {
  row => [
	   [ '0.0', '0.1', '0.2' ],
	   [ '1.0', '1.1', '1.2' ],
	   [ '2.0', '2.1', '2.2' ]
         ]
}));


# Confirm anonymous array folding works in special top level case

$opt = XMLin(q{
  <opt>
    <anon>one</anon>
    <anon>two</anon>
    <anon>three</anon>
  </opt>
});
ok(39, DataCompare($opt, [
  qw(one two three)
]));


$opt = XMLin(q(
  <opt>
    <anon>1</anon>
    <anon>
      <anon>2.1</anon>
      <anon>
	<anon>2.2.1</anon>
	<anon>2.2.2</anon>
      </anon>
    </anon>
  </opt>
));
ok(40, DataCompare($opt, [
  1,
  [
   '2.1', [ '2.2.1', '2.2.2']
  ]
]));


# Check for the dreaded 'content' attribute

$xml = q(
  <opt>
    <item attr="value">text</item>
  </opt>
);

$opt = XMLin($xml);
ok(41, DataCompare($opt, {
  item => {
	    content => 'text',
	    attr    => 'value'
          }
}));


# And check that we can change its name if required

$opt = XMLin($xml, contentkey => 'text_content');
ok(42, DataCompare($opt, {
  item => {
	    text_content => 'text',
	    attr         => 'value'
          }
}));


# Check that it doesn't get screwed up by forcearray option

$xml = q(<opt attr="value">text content</opt>);

$opt = XMLin($xml, forcearray => 1);
ok(43, DataCompare($opt, {
  'attr'   => 'value',
  'content' => 'text content'
}));


# Test that we can force all text content to parse to hash values

$xml = q(<opt><x>text1</x><y a="2">text2</y></opt>);
$opt = XMLin($xml, forcecontent => 1);
ok(44, DataCompare($opt, {
    'x' => {           'content' => 'text1' },
    'y' => { 'a' => 2, 'content' => 'text2' }
}));


# And that this is compatible with changing the key name

$opt = XMLin($xml, forcecontent => 1, contentkey => '0');
ok(45, DataCompare($opt, {
    'x' => {           0 => 'text1' },
    'y' => { 'a' => 2, 0 => 'text2' }
}));


# Check that mixed content parses in the weird way we expect

$xml = q(<p class="mixed">Text with a <b>bold</b> word</p>);

ok(46, DataCompare(XMLin($xml), {
  'class'   => 'mixed',
  'content' => [ 'Text with a ', ' word' ],
  'b'       => 'bold'
}));


# Confirm single nested element rolls up into a scalar attribute value

$string = q(
  <opt>
    <name>value</name>
  </opt>
);
$opt = XMLin($string);
ok(47, DataCompare($opt, {
  name => 'value'
}));


# Unless 'forcearray' option is specified

$opt = XMLin($string, forcearray => 1);
ok(48, DataCompare($opt, {
  name => [ 'value' ]
}));


# Confirm array folding of single nested hash

$string = q(<opt>
  <inner name="one" value="1" />
</opt>);

$opt = XMLin($string, forcearray => 1);
ok(49, DataCompare($opt, {
  'inner' => { 'one' => { 'value' => 1 } }
}));


# But not without forcearray option specified

$opt = XMLin($string, forcearray => 0);
ok(50, DataCompare($opt, {
  'inner' => { 'name' => 'one', 'value' => 1 }
}));


# Test advanced features of forcearray

$xml = q(<opt zero="0">
  <one>i</one>
  <two>ii</two>
  <three>iii</three>
  <three>3</three>
  <three>c</three>
</opt>
);

$opt = XMLin($xml, forcearray => [ 'two' ]);
ok(51, DataCompare($opt, {
  'zero' => '0',
  'one' => 'i',
  'two' => [ 'ii' ],
  'three' => [ 'iii', 3, 'c' ]
}));


# Test 'noattr' option

$xml = q(<opt name="user" password="foobar">
  <nest attr="value">text</nest>
</opt>
);

$opt = XMLin($xml, noattr => 1);
ok(52, DataCompare($opt, { nest => 'text' }));


# And make sure it doesn't screw up array folding

$xml = q{<opt>
  <item><key>a</key><value>alpha</value></item>
  <item><key>b</key><value>beta</value></item>
  <item><key>g</key><value>gamma</value></item>
</opt>
};


$opt = XMLin($xml, noattr => 1);
ok(53, DataCompare($opt, {
 'item' => {
    'a' => { 'value' => 'alpha' },
    'b' => { 'value' => 'beta' },
    'g' => { 'value' => 'gamma' }
  }
}));


# Confirm empty elements parse to empty hashrefs

$xml = q(<body>
  <name>bob</name>
  <outer attr="value">
    <inner1 />
    <inner2></inner2>
  </outer>
</body>);

$opt = XMLin($xml, noattr => 1);
ok(54, DataCompare($opt, {
  'name' => 'bob',
  'outer' => {
    'inner1' => {},
    'inner2' => {}
  }
}));


# Unless 'suppressempty' is enabled

$opt = XMLin($xml, noattr => 1, suppressempty => 1);
ok(55, DataCompare($opt, { 'name' => 'bob', }));


# Check behaviour when 'suppressempty' is set to to undef;

$opt = XMLin($xml, noattr => 1, suppressempty => undef);
ok(56, DataCompare($opt, {
  'name' => 'bob',
  'outer' => {
    'inner1' => undef,
    'inner2' => undef
  }
}));

# Check behaviour when 'suppressempty' is set to to empty string;

$opt = XMLin($xml, noattr => 1, suppressempty => '');
ok(57, DataCompare($opt, {
  'name' => 'bob',
  'outer' => {
    'inner1' => '',
    'inner2' => ''
  }
}));

# Confirm completely empty XML parses to undef with 'suppressempty'

$xml = q(<body>
  <outer attr="value">
    <inner1 />
    <inner2></inner2>
  </outer>
</body>);

$opt = XMLin($xml, noattr => 1, suppressempty => 1);
ok(58, DataCompare($opt, undef));


# Test that nothing unusual happens with namespaces by default

$xml = q(<opt xmlns="urn:accounts" xmlns:eng="urn:engineering">
  <invoice_num>12345678</invoice_num>
  <eng:partnum>8001-22374-001</eng:partnum>
</opt>);

$opt = XMLin($xml);
ok(59, DataCompare($opt, {
  'xmlns' => 'urn:accounts',
  '{urn:accounts}invoice_num' => '12345678',
  '{urn:engineering}partnum' => '8001-22374-001',
  '{http://www.w3.org/2000/xmlns/}eng' => 'urn:engineering',
}));


# Test that we can pass an option in to turn on XML::Parser's namespace mode

# Skip for now since I haven't added this feature to XML::SAX::PurePerl yet!
ok(60, 1);
# $opt = XMLin($xml, parseropts => [ Namespaces => 1 ]);
# ok(60, DataCompare($opt, {
#  'invoice_num' => 12345678,
#  'partnum' => '8001-22374-001'
# }));


# Test option error handling

$_ = eval { XMLin('<x y="z" />', rootname => 'fred') }; # not valid for XMLin()
ok(61, !defined($_));
ok(62, $@ =~ /Unrecognised option:/);

$_ = eval { XMLin('<x y="z" />', 'searchpath') };
ok(63, !defined($_));
ok(64, $@ =~ /Options must be name=>value pairs .odd number supplied./);


# Now for a 'real world' test, try slurping in an SRT config file

$opt = XMLin(File::Spec->catfile('t', 'srt.xml'), forcearray => 1);
$target = {
  'global' => [
    {
      'proxypswd' => 'bar',
      'proxyuser' => 'foo',
      'exclude' => [
        '/_vt',
        '/save\\b',
        '\\.bak$',
        '\\.\\$\\$\\$$'
      ],
      'httpproxy' => 'http://10.1.1.5:8080/',
      'tempdir' => 'C:/Temp'
    }
  ],
  'pubpath' => {
    'test1' => {
      'source' => [
        {
          'label' => 'web_source',
          'root' => 'C:/webshare/web_source'
        }
      ],
      'title' => 'web_source -> web_target1',
      'package' => {
        'images' => { 'dir' => 'wwwroot/images' }
      },
      'target' => [
        {
          'label' => 'web_target1',
          'root' => 'C:/webshare/web_target1',
          'temp' => 'C:/webshare/web_target1/temp'
        }
      ],
      'dir' => [ 'wwwroot' ]
    },
    'test2' => {
      'source' => [
        {
          'label' => 'web_source',
          'root' => 'C:/webshare/web_source'
        }
      ],
      'title' => 'web_source -> web_target1 & web_target2',
      'package' => {
        'bios' => { 'dir' => 'wwwroot/staff/bios' },
        'images' => { 'dir' => 'wwwroot/images' },
        'templates' => { 'dir' => 'wwwroot/templates' }
      },
      'target' => [
        {
          'label' => 'web_target1',
          'root' => 'C:/webshare/web_target1',
          'temp' => 'C:/webshare/web_target1/temp'
        },
        {
          'label' => 'web_target2',
          'root' => 'C:/webshare/web_target2',
          'temp' => 'C:/webshare/web_target2/temp'
        }
      ],
      'dir' => [ 'wwwroot' ]
    },
    'test3' => {
      'source' => [
        {
          'label' => 'web_source',
          'root' => 'C:/webshare/web_source'
        }
      ],
      'title' => 'web_source -> web_target1 via HTTP',
      'addexclude' => [ '\\.pdf$' ],
      'target' => [
        {
          'label' => 'web_target1',
          'root' => 'http://127.0.0.1/cgi-bin/srt_slave.plx',
          'noproxy' => 1
        }
      ],
      'dir' => [ 'wwwroot' ]
    }
  }
};
ok(65, DataCompare($target, $opt));


exit(0);

