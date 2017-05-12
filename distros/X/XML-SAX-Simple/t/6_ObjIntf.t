use strict;
use warnings;

##############################################################################
# Derived version of XML::SAX::Simple that returns everything in lower case
##############################################################################

package XML::Simple::UC;

use vars qw(@ISA);
@ISA = qw(XML::SAX::Simple);

sub build_tree {
  my $self = shift;

  my $tree = $self->SUPER::build_tree(@_);

  ($tree) = uctree($tree);

  return($tree);
}

sub uctree {
  foreach my $i (0..$#_) {
    my $x = $_[$i];
    if(ref($x) eq 'ARRAY') {
      $_[$i] = [ uctree(@$x) ];
    }
    elsif(ref($x) eq 'HASH') {
      $_[$i] = { uctree(%$x) };
    }
    else {
      $_[$i] = uc($x);
    }
  }
  return(@_);
}


##############################################################################
# Derived version of XML::SAX::Simple that uses CDATA sections for escaping
##############################################################################

package XML::Simple::CDE;

use vars qw(@ISA);
@ISA = qw(XML::SAX::Simple);

sub escape_value {
  my $self = shift;

  my($data) = @_;

  if($data =~ /[&<>"]/) {
    $data = '<![CDATA[' . $data . ']]>';
  }

  return($data);
}


##############################################################################
# Start of the test script itself
##############################################################################

package main;

BEGIN { print "1..27\n"; }

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
# Start the tests
#

use XML::SAX::Simple;

my $xml = q(<cddatabase>
  <disc id="9362-45055-2" cddbid="960b750c">
    <artist>R.E.M.</artist>
    <album>Automatic For The People</album>
    <track number="1">Drive</track>
    <track number="2">Try Not To Breathe</track>
    <track number="3">The Sidewinder Sleeps Tonite</track>
    <track number="4">Everybody Hurts</track>
    <track number="5">New Orleans Instrumental No. 1</track>
    <track number="6">Sweetness Follows</track>
    <track number="7">Monty Got A Raw Deal</track>
    <track number="8">Ignoreland</track>
    <track number="9">Star Me Kitten</track>
    <track number="10">Man On The Moon</track>
    <track number="11">Nightswimming</track>
    <track number="12">Find The River</track>
  </disc>
</cddatabase>
);

my %opts1 = (
  keyattr => { disc => 'cddbid', track => 'number' },
  keeproot => 1,
  contentkey => 'title',
  forcearray => [ qw(disc album) ]
);

my %opts2 = (
  keyattr => { }
);

my $xs1 = new XML::SAX::Simple( %opts1 );
my $xs2 = new XML::SAX::Simple( %opts2 );
ok(1, $xs1);                            # Object created successfully
ok(2, $xs2);                            # and another
ok(3, DataCompare(\%opts1, {            # Options values not corrupted
  keyattr => { disc => 'cddbid', track => 'number' },
  keeproot => 1,
  contentkey => 'title',
  forcearray => [ qw(disc album) ]
}));

my $exp1 = {
  'cddatabase' => {
    'disc' => {
      '960b750c' => {
        'id' => '9362-45055-2',
        'album' => [ 'Automatic For The People' ],
        'artist' => 'R.E.M.',
        'track' => {
          1  => { 'title' => 'Drive' },
          2  => { 'title' => 'Try Not To Breathe' },
          3  => { 'title' => 'The Sidewinder Sleeps Tonite' },
          4  => { 'title' => 'Everybody Hurts' },
          5  => { 'title' => 'New Orleans Instrumental No. 1' },
          6  => { 'title' => 'Sweetness Follows' },
          7  => { 'title' => 'Monty Got A Raw Deal' },
          8  => { 'title' => 'Ignoreland' },
          9  => { 'title' => 'Star Me Kitten' },
          10 => { 'title' => 'Man On The Moon' },
          11 => { 'title' => 'Nightswimming' },
          12 => { 'title' => 'Find The River' }
        }
      }
    }
  }
};

my $ref1 = $xs1->XMLin($xml);
ok(4, DataCompare($ref1, $exp1));       # Parsed to what we expected


# Try using the other object

my $exp2 = {
  'disc' => {
    'album' => 'Automatic For The People',
    'artist' => 'R.E.M.',
    'cddbid' => '960b750c',
    'id' => '9362-45055-2',
    'track' => [
      { 'number' => 1,  'content' => 'Drive' },
      { 'number' => 2,  'content' => 'Try Not To Breathe' },
      { 'number' => 3,  'content' => 'The Sidewinder Sleeps Tonite' },
      { 'number' => 4,  'content' => 'Everybody Hurts' },
      { 'number' => 5,  'content' => 'New Orleans Instrumental No. 1' },
      { 'number' => 6,  'content' => 'Sweetness Follows' },
      { 'number' => 7,  'content' => 'Monty Got A Raw Deal' },
      { 'number' => 8,  'content' => 'Ignoreland' },
      { 'number' => 9,  'content' => 'Star Me Kitten' },
      { 'number' => 10, 'content' => 'Man On The Moon' },
      { 'number' => 11, 'content' => 'Nightswimming' },
      { 'number' => 12, 'content' => 'Find The River' }
    ]
  }
};

my $ref2 = $xs2->XMLin($xml);
ok(5, DataCompare($ref2, $exp2));       # Parsed to what we expected



# Confirm default options in object merge correctly with options as args

$ref1 = $xs1->XMLin($xml, keyattr => [], forcearray => 0);

ok(6, DataCompare($ref1, {              # Parsed to what we expected
  'cddatabase' => {
    'disc' => {
      'album' => 'Automatic For The People',
      'id' => '9362-45055-2',
      'artist' => 'R.E.M.',
      'cddbid' => '960b750c',
      'track' => [
        { 'number' => 1,  'title' => 'Drive' },
        { 'number' => 2,  'title' => 'Try Not To Breathe' },
        { 'number' => 3,  'title' => 'The Sidewinder Sleeps Tonite' },
        { 'number' => 4,  'title' => 'Everybody Hurts' },
        { 'number' => 5,  'title' => 'New Orleans Instrumental No. 1' },
        { 'number' => 6,  'title' => 'Sweetness Follows' },
        { 'number' => 7,  'title' => 'Monty Got A Raw Deal' },
        { 'number' => 8,  'title' => 'Ignoreland' },
        { 'number' => 9,  'title' => 'Star Me Kitten' },
        { 'number' => 10, 'title' => 'Man On The Moon' },
        { 'number' => 11, 'title' => 'Nightswimming' },
        { 'number' => 12, 'title' => 'Find The River' }
      ]
    }
  }
}));


# Confirm that default options in object still work as expected

$ref1 = $xs1->XMLin($xml);
ok(7, DataCompare($ref1, $exp1));       # Still parsed to what we expected


# Confirm they work for output too

$_ = $xs1->XMLout($ref1);

ok(8,  s{<track number="1">Drive</track>}                         {<NEST/>});
ok(9,  s{<track number="2">Try Not To Breathe</track>}            {<NEST/>});
ok(10, s{<track number="3">The Sidewinder Sleeps Tonite</track>}  {<NEST/>});
ok(11, s{<track number="4">Everybody Hurts</track>}               {<NEST/>});
ok(12, s{<track number="5">New Orleans Instrumental No. 1</track>}{<NEST/>});
ok(13, s{<track number="6">Sweetness Follows</track>}             {<NEST/>});
ok(14, s{<track number="7">Monty Got A Raw Deal</track>}          {<NEST/>});
ok(15, s{<track number="8">Ignoreland</track>}                    {<NEST/>});
ok(16, s{<track number="9">Star Me Kitten</track>}                {<NEST/>});
ok(17, s{<track number="10">Man On The Moon</track>}              {<NEST/>});
ok(18, s{<track number="11">Nightswimming</track>}                {<NEST/>});
ok(19, s{<track number="12">Find The River</track>}               {<NEST/>});
ok(20, s{<album>Automatic For The People</album>}                 {<NEST/>});
ok(21, s{cddbid="960b750c"}{ATTR});
ok(22, s{id="9362-45055-2"}{ATTR});
ok(23, s{artist="R.E.M."}  {ATTR});
ok(24, s{<disc(\s+ATTR){3}\s*>(\s*<NEST/>){13}\s*</disc>}{<DISC/>}s);
ok(25, m{^\s*<(cddatabase)>\s*<DISC/>\s*</\1>\s*$});


# Check that overriding build_tree() method works

$xml = q(<opt>
  <server>
    <name>Apollo</name>
    <address>10 Downing Street</address>
  </server>
</opt>
);

my $xsp = new XML::Simple::UC();
$ref1 = $xsp->XMLin($xml);
ok(26, DataCompare($ref1, {
  'SERVER' => {
    'NAME' => 'APOLLO',
    'ADDRESS' => '10 DOWNING STREET'
  }
}));


# Check that overriding escape_value() method works

my $ref = {
  'server' => {
    'address' => '12->14 "Puf&Stuf" Drive'
  }
};

$xsp = new XML::Simple::CDE();

$_ = $xsp->XMLout($ref);

ok(27, m{<opt>\s*
 <server\s+address="<!\[CDATA\[12->14\s+"Puf&Stuf"\s+Drive\]\]>"\s*/>\s*
</opt>}xs);
