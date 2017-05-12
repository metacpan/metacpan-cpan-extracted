use strict;
use warnings;
use IO::File;

$|++;

BEGIN { print "1..188\n"; }

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
                   " key(s) (", join(', ', keys(%$x)),
		   "), got: ",  scalar(keys(%$y)), " (", join(', ', keys(%$y)),
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
# Read file and return contents as a scalar.
#

sub ReadFile {
  local($/) = undef;

  open(_READ_FILE_, $_[0]) || die "open($_[0]): $!";
  my $data = <_READ_FILE_>;
  close(_READ_FILE_);
  return($data);
}

use XML::SAX::Simple;

# Try encoding a scalar value

my $xml = XMLout("scalar");
ok(1, 1);                             # XMLout did not crash
ok(2, defined($xml));                 # and it returned an XML string
ok(3, XMLin($xml), 'scalar');         # which parses back OK

# Next try encoding a hash

my $hashref1 = { one => 1, two => 'II', three => '...' };
my $hashref2 = { one => 1, two => 'II', three => '...' };

# Expect:
# <opt one="1" two="II" three="..." />

$_ = XMLout($hashref1);               # Encode to $_ for convenience
                                      # Confirm it parses back OK
ok(4, DataCompare($hashref1, XMLin($_)));
ok(5, s/one="1"//);                   # first key encoded OK
ok(6, s/two="II"//);                  # second key encoded OK
ok(7, s/three="..."//);               # third key encoded OK
ok(8, /^<\w+\s+\/>/);                 # no other attributes encoded


# Now try encoding a hash with a nested array

my $ref = {array => [qw(one two three)]};
# Expect:
# <opt>
#   <array>one</array>
#   <array>two</array>
#   <array>three</array>
# </opt>

$_ = XMLout($ref);                    # Encode to $_ for convenience
ok(9, DataCompare($ref, XMLin($_)));
ok(10, s{<array>one</array>\s*
         <array>two</array>\s*
         <array>three</array>}{}sx);  # array elements encoded in correct order
ok(11, /^<(\w+)\s*>\s*<\/\1>\s*$/s);  # no other spurious encodings


# Now try encoding a nested hash

$ref = { value => '555 1234',
         hash1 => { one => 1 },
         hash2 => { two => 2 } };
# Expect:
# <opt value="555 1234">
#   <hash1 one="1" />
#   <hash2 two="2" />
# </opt>

$_ = XMLout($ref);
ok(12, DataCompare($ref, XMLin($_))); # Parses back OK

ok(13, s{<hash1 one="1" />\s*}{}s);
ok(14, s{<hash2 two="2" />\s*}{}s);
ok(15, m{^<(\w+)\s+value="555 1234"\s*>\s*</\1>\s*$}s);


# Now try encoding an anonymous array

$ref = [ qw(1 two III) ];
# Expect:
# <opt>
#   <anon>1</anon>
#   <anon>two</anon>
#   <anon>III</anon>
# </opt>

$_ = XMLout($ref);
ok(16, DataCompare($ref, XMLin($_))); # Parses back OK

ok(17, s{<anon>1</anon>\s*}{}s);
ok(18, s{<anon>two</anon>\s*}{}s);
ok(19, s{<anon>III</anon>\s*}{}s);
ok(20, m{^<(\w+)\s*>\s*</\1>\s*$}s);


# Now try encoding a nested anonymous array

$ref = [ [ qw(1.1 1.2) ], [ qw(2.1 2.2) ] ];
# Expect:
# <opt>
#   <anon>
#     <anon>1.1</anon>
#     <anon>1.2</anon>
#   </anon>
#   <anon>
#     <anon>2.1</anon>
#     <anon>2.2</anon>
#   </anon>
# </opt>

$_ = XMLout($ref);
ok(21, DataCompare($ref, XMLin($_))); # Parses back OK

ok(22, s{<anon>1\.1</anon>\s*}{row}s);
ok(23, s{<anon>1\.2</anon>\s*}{ one}s);
ok(24, s{<anon>2\.1</anon>\s*}{row}s);
ok(25, s{<anon>2\.2</anon>\s*}{ two}s);
ok(26, s{<anon>\s*row one\s*</anon>\s*}{}s);
ok(27, s{<anon>\s*row two\s*</anon>\s*}{}s);
ok(28, m{^<(\w+)\s*>\s*</\1>\s*$}s);


# Now try encoding a hash of hashes with key folding disabled

$ref = { country => {
		      England => { capital => 'London' },
		      France  => { capital => 'Paris' },
		      Turkey  => { capital => 'Istanbul' },
                    }
       };
# Expect:
# <opt>
#   <country>
#     <England capital="London" />
#     <France capital="Paris" />
#     <Turkey capital="Istanbul" />
#   </country>
# </opt>

$_ = XMLout($ref, keyattr => []);
ok(29, DataCompare($ref, XMLin($_))); # Parses back OK
ok(30, s{<England\s+capital="London"\s*/>\s*}{}s);
ok(31, s{<France\s+capital="Paris"\s*/>\s*}{}s);
ok(32, s{<Turkey\s+capital="Istanbul"\s*/>\s*}{}s);
ok(33, s{<country\s*>\s*</country>}{}s);
ok(34, s{^<(\w+)\s*>\s*</\1>$}{}s);


# Try encoding same again with key folding set to non-standard value

# Expect:
# <opt>
#   <country fullname="England" capital="London" />
#   <country fullname="France" capital="Paris" />
#   <country fullname="Turkey" capital="Istanbul" />
# </opt>

$_ = XMLout($ref, keyattr => ['fullname']);
$xml = $_;
ok(35, DataCompare($ref,
                   XMLin($_, keyattr => ['fullname']))); # Parses back OK
ok(36, s{\s*fullname="England"}{uk}s);
ok(37, s{\s*capital="London"}{uk}s);
ok(38, s{\s*fullname="France"}{fr}s);
ok(39, s{\s*capital="Paris"}{fr}s);
ok(40, s{\s*fullname="Turkey"}{tk}s);
ok(41, s{\s*capital="Istanbul"}{tk}s);
ok(42, s{<countryukuk\s*/>\s*}{}s);
ok(43, s{<countryfrfr\s*/>\s*}{}s);
ok(44, s{<countrytktk\s*/>\s*}{}s);
ok(45, s{^<(\w+)\s*>\s*</\1>$}{}s);

# Same again but specify name as scalar rather than array

$_ = XMLout($ref, keyattr => 'fullname');
ok(46, $_ eq $xml);                            # Same result as last time


# Same again but specify keyattr as hash rather than array

$_ = XMLout($ref, keyattr => { country => 'fullname' });
ok(47, $_ eq $xml);                            # Same result as last time


# Same again but add leading '+'

$_ = XMLout($ref, keyattr => { country => '+fullname' });
ok(48, $_ eq $xml);                            # Same result as last time


# and leading '-'

$_ = XMLout($ref, keyattr => { country => '-fullname' });
ok(49, $_ eq $xml);                            # Same result as last time


# One more time but with default key folding values

# Expect:
# <opt>
#   <country name="England" capital="London" />
#   <country name="France" capital="Paris" />
#   <country name="Turkey" capital="Istanbul" />
# </opt>

$_ = XMLout($ref);
ok(50, DataCompare($ref, XMLin($_))); # Parses back OK
ok(51, s{\s*name="England"}{uk}s);
ok(52, s{\s*capital="London"}{uk}s);
ok(53, s{\s*name="France"}{fr}s);
ok(54, s{\s*capital="Paris"}{fr}s);
ok(55, s{\s*name="Turkey"}{tk}s);
ok(56, s{\s*capital="Istanbul"}{tk}s);
ok(57, s{<countryukuk\s*/>\s*}{}s);
ok(58, s{<countryfrfr\s*/>\s*}{}s);
ok(59, s{<countrytktk\s*/>\s*}{}s);
ok(60, s{^<(\w+)\s*>\s*</\1>$}{}s);


# Finally, confirm folding still works with only one nested hash

# Expect:
# <opt>
#   <country name="England" capital="London" />
# </opt>

$ref = { country => { England => { capital => 'London' } } };
$_ = XMLout($ref);
ok(61, DataCompare($ref, XMLin($_, forcearray => 1))); # Parses back OK
ok(62, s{\s*name="England"}{uk}s);
ok(63, s{\s*capital="London"}{uk}s);
ok(64, s{<countryukuk\s*/>\s*}{}s);
#print STDERR "\n$_\n";
ok(65, s{^<(\w+)\s*>\s*</\1>$}{}s);


# Check that default XML declaration works
#
# Expect:
# <?xml version='1' standalone='yes'?>
# <opt one="1" />

$ref = { one => 1 };

$_ = XMLout($ref, xmldecl => 1);
ok(66, DataCompare($ref, XMLin($_))); # Parses back OK
ok(67, s{^\Q<?xml version='1.0' standalone='yes'?>\E}{}s);
ok(68, s{<opt one="1" />}{}s);
ok(69, m{^\s*$}s);


# Check that custom XML declaration works
#
# Expect:
# <?xml version='1' encoding='ISO-8859-1'?>
# <opt one="1" />

$_ = XMLout($ref, xmldecl => "<?xml version='1.0' encoding='US-ASCII'?>");
ok(70, DataCompare($ref, XMLin($_))); # Parses back OK
ok(71, s{^\Q<?xml version='1.0' encoding='US-ASCII'?>\E}{}s);
ok(72, s{<opt one="1" />}{}s);
ok(73, m{^\s*$}s);


# Check that special characters do get escaped

$ref = { a => '<A>', b => '"B"', c => '&C&' };
$_ = XMLout($ref);
ok(74, DataCompare($ref, XMLin($_))); # Parses back OK
ok(75, s{a="&lt;A&gt;"}{}s);
ok(76, s{b="&quot;B&quot;"}{}s);
ok(77, s{c="&amp;C&amp;"}{}s);
ok(78, s{^<(\w+)\s*/>$}{}s);


# unless we turn escaping off

$_ = XMLout($ref, noescape => 1);
ok(79, s{a="<A>"}{}s);
ok(80, s{b=""B""}{}s);
ok(81, s{c="&C&"}{}s);
ok(82, s{^<(\w+)\s*/>$}{}s);


# Try encoding a recursive data structure and confirm that it fails

$_ = eval {
  my $ref = { a => '1' };
  $ref->{b} = $ref;
  XMLout($ref);
};
ok(83, !defined($_));
ok(84, $@ =~ /circular data structures not supported/);


# Try encoding a blessed reference and confirm that it fails

$_ = eval { my $ref = new IO::File; XMLout($ref) };
ok(85, !defined($_));
ok(86, $@ =~ /Can't encode a value of type: /);


# Repeat some of the above tests with named root element

# Try encoding a scalar value

$xml = XMLout("scalar", rootname => 'TOM');
ok(87, defined($xml));                 # and it returned an XML string
ok(88, XMLin($xml), 'scalar');         # which parses back OK
                                       # and contains the expected data
ok(89, $xml =~ /^\s*<TOM>scalar<\/TOM>\s*$/si);


# Next try encoding a hash

# Expect:
# <DICK one="1" two="II" three="..." />

$_ = XMLout($hashref1, rootname => 'DICK');
                                      # Confirm it parses back OK
ok(90, DataCompare($hashref1, XMLin($_)));
ok(91, s/one="1"//);                  # first key encoded OK
ok(92, s/two="II"//);                 # second key encoded OK
ok(93, s/three="..."//);              # third key encoded OK
ok(94, /^<DICK\s+\/>/);               # only expected root element left


# Now try encoding a hash with a nested array

$ref = {array => [qw(one two three)]};
# Expect:
# <LARRY>
#   <array>one</array>
#   <array>two</array>
#   <array>three</array>
# </LARRY>

$_ = XMLout($ref, rootname => 'LARRY'); # Encode to $_ for convenience
ok(95, DataCompare($ref, XMLin($_)));
ok(96, s{<array>one</array>\s*
         <array>two</array>\s*
         <array>three</array>}{}sx);    # array encoded in correct order
ok(97, /^<(LARRY)\s*>\s*<\/\1>\s*$/s);  # only expected root element left


# Now try encoding a nested hash

$ref = { value => '555 1234',
         hash1 => { one => 1 },
         hash2 => { two => 2 } };
# Expect:
# <CURLY value="555 1234">
#   <hash1 one="1" />
#   <hash2 two="2" />
# </CURLY>

$_ = XMLout($ref, rootname => 'CURLY');
ok(98, DataCompare($ref, XMLin($_))); # Parses back OK

ok(99, s{<hash1 one="1" />\s*}{}s);
ok(100, s{<hash2 two="2" />\s*}{}s);
ok(101, m{^<(CURLY)\s+value="555 1234"\s*>\s*</\1>\s*$}s);


# Now try encoding an anonymous array

$ref = [ qw(1 two III) ];
# Expect:
# <MOE>
#   <anon>1</anon>
#   <anon>two</anon>
#   <anon>III</anon>
# </MOE>

$_ = XMLout($ref, rootname => 'MOE');
ok(102, DataCompare($ref, XMLin($_))); # Parses back OK

ok(103, s{<anon>1</anon>\s*}{}s);
ok(104, s{<anon>two</anon>\s*}{}s);
ok(105, s{<anon>III</anon>\s*}{}s);
ok(106, m{^<(MOE)\s*>\s*</\1>\s*$}s);


# Test again, this time with no root element

# Try encoding a scalar value

ok(107, XMLout("scalar", rootname => '')    =~ /scalar\s+/s);
ok(108, XMLout("scalar", rootname => undef) =~ /scalar\s+/s);


# Next try encoding a hash

# Expect:
#   <one>1</one>
#   <two>II</two>
#   <three>...</three>

$_ = XMLout($hashref1, rootname => '');
                                      # Confirm it parses back OK
ok(109, DataCompare($hashref1, XMLin("<opt>$_</opt>")));
ok(110, s/<one>1<\/one>//);            # first key encoded OK
ok(111, s/<two>II<\/two>//);           # second key encoded OK
ok(112, s/<three>...<\/three>//);      # third key encoded OK
ok(113, /^\s*$/);                      # nothing else left


# Now try encoding a nested hash

$ref = { value => '555 1234',
         hash1 => { one => 1 },
         hash2 => { two => 2 } };
# Expect:
#   <value>555 1234</value>
#   <hash1 one="1" />
#   <hash2 two="2" />

$_ = XMLout($ref, rootname => '');
ok(114, DataCompare($ref, XMLin("<opt>$_</opt>"))); # Parses back OK
ok(115, s{<value>555 1234<\/value>\s*}{}s);
ok(116, s{<hash1 one="1" />\s*}{}s);
ok(117, s{<hash2 two="2" />\s*}{}s);
ok(118, m{^\s*$}s);


# Now try encoding an anonymous array

$ref = [ qw(1 two III) ];
# Expect:
#   <anon>1</anon>
#   <anon>two</anon>
#   <anon>III</anon>

$_ = XMLout($ref, rootname => '');
ok(119, DataCompare($ref, XMLin("<opt>$_</opt>"))); # Parses back OK

ok(120, s{<anon>1</anon>\s*}{}s);
ok(121, s{<anon>two</anon>\s*}{}s);
ok(122, s{<anon>III</anon>\s*}{}s);
ok(123, m{^\s*$}s);


# Test option error handling

$_ = eval { XMLout($hashref1, searchpath => []) }; # only valid for XMLin()
ok(124, !defined($_));
ok(125, $@ =~ /Unrecognised option:/);

$_ = eval { XMLout($hashref1, 'bogus') };
ok(126, !defined($_));
ok(127, $@ =~ /Options must be name=>value pairs .odd number supplied./);


# Test output to file

my $TestFile = 'testoutput.xml';
unlink($TestFile);
ok(128, !-e $TestFile);

$xml = XMLout($hashref1);
XMLout($hashref1, outputfile => $TestFile);
ok(129, -e $TestFile);
ok(130, ReadFile($TestFile) eq $xml);
unlink($TestFile);


# Test output to an IO handle

ok(131, !-e $TestFile);
my $fh = new IO::File;
$fh->open(">$TestFile") || die "$!";
XMLout($hashref1, outputfile => $TestFile);
$fh->close();

ok(132, -e $TestFile);
ok(133, ReadFile($TestFile) eq $xml);
unlink($TestFile);

# After all that, confirm that the original hashref we supplied has not
# been corrupted.

ok(134, DataCompare($hashref1, $hashref2));


# Confirm that hash keys with leading '-' are skipped

$ref = {
  'a'  => 'one',
  '-b' => 'two',
  '-c' => {
	    'one' => 1,
	    'two' => 2
          }
};

$_ = XMLout($ref, rootname => 'opt');
ok(135, m{^\s*<opt\s+a="one"\s*/>\s*$}s);


# Try a more complex unfolding with key attributes named in a hash

$ref = {
  'car' => {
    'LW1804' => {
      'option' => {
        '9926543-1167' => { 'key' => 1, 'desc' => 'Steering Wheel' }
      },
      'id' => 2,
      'make' => 'GM'
    },
    'SH6673' => {
      'option' => {
        '6389733317-12' => { 'key' => 2, 'desc' => 'Electric Windows' },
        '3735498158-01' => { 'key' => 3, 'desc' => 'Leather Seats' },
        '5776155953-25' => { 'key' => 4, 'desc' => 'Sun Roof' },
      },
      'id' => 1,
      'make' => 'Ford'
    }
  }
};

# Expect:
# <opt>
#   <car license="LW1804" id="2" make="GM">
#     <option key="1" pn="9926543-1167" desc="Steering Wheel" />
#   </car>
#   <car license="SH6673" id="1" make="Ford">
#     <option key="2" pn="6389733317-12" desc="Electric Windows" />
#     <option key="3" pn="3735498158-01" desc="Leather Seats" />
#     <option key="4" pn="5776155953-25" desc="Sun Roof" />
#   </car>
# </opt>

$_ = XMLout($ref, keyattr => { 'car' => 'license', 'option' => 'pn' });
ok(136, DataCompare($ref,                                      # Parses back OK
      XMLin($_, forcearray => 1,
	    keyattr => { 'car' => 'license', 'option' => 'pn' })));
ok(137, s{\s*make="GM"}{gm}s);
ok(138, s{\s*id="2"}{gm}s);
ok(139, s{\s*license="LW1804"}{gm}s);
ok(140, s{\s*desc="Steering Wheel"}{opt}s);
ok(141, s{\s*pn="9926543-1167"}{opt}s);
ok(142, s{\s*key="1"}{opt}s);
ok(143, s{\s*<cargmgmgm>\s*<optionoptoptopt\s*/>\s*</car>}{CAR}s);
ok(144, s{\s*make="Ford"}{ford}s);
ok(145, s{\s*id="1"}{ford}s);
ok(146, s{\s*license="SH6673"}{ford}s);
ok(147, s{\s*desc="Electric Windows"}{1}s);
ok(148, s{\s*pn="6389733317-12"}{1}s);
ok(149, s{\s*key="2"}{1}s);
ok(150, s{\s*<option111}{<option}s);
ok(151, s{\s*desc="Leather Seats"}{2}s);
ok(152, s{\s*pn="3735498158-01"}{2}s);
ok(153, s{\s*key="3"}{2}s);
ok(154, s{\s*<option222}{<option}s);
ok(155, s{\s*desc="Sun Roof"}{3}s);
ok(156, s{\s*pn="5776155953-25"}{3}s);
ok(157, s{\s*key="4"}{3}s);
ok(158, s{\s*<option333}{<option}s);
ok(159, s{\s*<carfordfordford>\s*(<option\s*/>\s*){3}</car>}{CAR}s);
ok(160, s{^<(\w+)\s*>\s*CAR\s*CAR\s*</\1>$}{}s);


# Check that empty hashes translate to empty tags

$ref = {
  'one' => {
    'attr1' => 'avalue1',
    'nest1' => [ 'nvalue1' ],
    'nest2' => {}
  },
  two => {}
};

$_ = XMLout($ref);

ok(161, s{<nest2\s*></nest2\s*>\s*}{<NNN>});
ok(162, s{<nest1\s*>nvalue1</nest1\s*>\s*}{<NNN>});
ok(163, s{<one\s*attr1\s*=\s*"avalue1">\s*}{<one>});
ok(164, s{<one\s*>\s*<NNN>\s*<NNN>\s*</one>}{<nnn>});
ok(165, s{<two\s*></two\s*>\s*}{<nnn>});
ok(166, m{^\s*<(\w+)\s*>\s*<nnn>\s*<nnn>\s*</\1\s*>\s*$});



# Unless undef is mapped to empty tags

$ref = { 'tag' => undef };
$_ = XMLout($ref, suppressempty => undef);
ok(167, m{^\s*<(\w*)\s*>\s*<tag\s*></tag\s*>\s*</\1\s*>\s*$}s);


# Test the keeproot option

$ref = {
  'seq' => {
    'name' => 'alpha',
    'alpha' => [ 1, 2, 3 ]
  }
};

my $xml1 = XMLout($ref, rootname => 'sequence');
my $xml2 = XMLout({ 'sequence' => $ref }, keeproot => 1);

ok(168, DataCompare($xml1, $xml2));


# Test that items with text content are output correctly
# Expect: <opt one="1">text</opt>

$ref = { 'one' => 1, 'content' => 'text' };

$_ = XMLout($ref);

ok(169, m{^\s*<opt\s+one="1">text</opt>\s*$}s);


# Even if we change the default value for the 'contentkey' option

$ref = { 'one' => 1, 'text_content' => 'text' };

$_ = XMLout($ref, contentkey => 'text_content');

ok(170, m{^\s*<opt\s+one="1">text</opt>\s*$}s);


# Check 'noattr' option

$ref = {
  attr1  => 'value1',
  attr2  => 'value2',
  nest   => [ qw(one two three) ]
};

# Expect:
#
# <opt>
#   <attr1>value1</attr1>
#   <attr2>value2</attr2>
#   <nest>one</nest>
#   <nest>two</nest>
#   <nest>three</nest>
# </opt>
#

$_ = XMLout($ref, noattr => 1);

ok(171, !m{=}s);                               # No '=' signs anywhere
ok(172, DataCompare($ref, XMLin($_)));         # Parses back ok
ok(173, s{\s*<(attr1)>value1</\1>\s*}{NEST}s); # Output meets expectations
ok(174, s{\s*<(attr2)>value2</\1>\s*}{NEST}s);
ok(175, s{\s*<(nest)>one</\1>\s*<\1>two</\1>\s*<\1>three</\1>}{NEST}s);
ok(176, s{^<(\w+)\s*>(NEST\s*){3}</\1>$}{}s);


# Check noattr doesn't screw up keyattr

$ref = { number => {
  'twenty one' => { dec => 21, hex => '0x15' },
  'thirty two' => { dec => 32, hex => '0x20' }
  }
};

# Expect:
#
# <opt>
#   <number>
#     <dec>21</dec>
#     <word>twenty one</word>
#     <hex>0x15</hex>
#   </number>
#   <number>
#     <dec>32</dec>
#     <word>thirty two</word>
#     <hex>0x20</hex>
#   </number>
# </opt>
#

$_ = XMLout($ref, noattr => 1, keyattr => [ 'word' ]);

ok(177, !m{=}s);                               # No '=' signs anywhere
                                               # Parses back ok
ok(178, DataCompare($ref, XMLin($_, keyattr => [ 'word' ])));
ok(179, s{\s*<(dec)>21</\1>\s*}{21}s);
ok(180, s{\s*<(hex)>0x15</\1>\s*}{21}s);
ok(181, s{\s*<(word)>twenty one</\1>\s*}{21}s);
ok(182, s{\s*<(number)>212121</\1>\s*}{NUM}s);
ok(183, s{\s*<(dec)>32</\1>\s*}{32}s);
ok(184, s{\s*<(hex)>0x20</\1>\s*}{32}s);
ok(185, s{\s*<(word)>thirty two</\1>\s*}{32}s);
ok(186, s{\s*<(number)>323232</\1>\s*}{NUM}s);
ok(187, s{^<(\w+)\s*>NUMNUM</\1>$}{}s);


# 'Stress test' with a data structure that maps to several thousand elements.
# Unfold elements with XMLout() and fold them up again with XMLin()

my $opt1 =  {};
foreach my $i (1..40) {
  foreach my $j (1..$i) {
    $opt1->{TypeA}->{$i}->{Record}->{$j} = { Hex => sprintf("0x%04X", $j) };
    $opt1->{TypeB}->{$i}->{Record}->{$j} = { Oct => sprintf("%04o", $j) };
  }
}

$xml = XMLout($opt1, keyattr => { TypeA => 'alpha', TypeB => 'beta', Record => 'id' });

my $opt2 = XMLin($xml, keyattr => { TypeA => 'alpha', TypeB => 'beta', Record => 'id' }, forcearray => 1);

ok(188, DataCompare($opt1, $opt2));

# Check undefined values generate warnings

{
my $warn = '';
local $SIG{__WARN__} = sub { $warn = $_[0] };
$_ = eval {
  $ref = { 'tag' => undef };
  XMLout($ref);
};
#ok(189, $warn =~ //); #Use of uninitialized value/);
}


exit(0);






