# -*- cperl -*-
use Test;

use IO::File;

BEGIN {
  autoflush STDOUT 1;
  autoflush STDERR 1;

  {   no warnings 'once';
      $XML::XSH2::Map::t = 'true()';
  }
  @xsh_test=split /\n\n/, <<'EOF';
quiet;
def assert2 $exp1 $exp2 {
    perl {
        xsh("\$r = $exp1;
             unless \$r=$exp2
             throw concat('Assertion failed: ', \$r, ' != $exp2')
            ")}
}
def assert1 $cond { assert2 $cond 'true()' }
try {
  assert1 '/xyz';
  throw "assert1 failed";
} catch local $err {
  unless { $err =~ m{Assertion failed:  != true()} } throw $err;
};

assert1 '/scratch';

assert2 '/xyz' 'false()';

$doc2 := create 'foo';
insert text 'scratch' into ($doc2/foo);

#function xsh:var
$var=//node();

assert2 'count(xsh:var("var"))' 2;

assert2 'name(xsh:var("var")[1])' '"foo"';

assert1 'xsh:var("var")[2]/self::text()';

assert2 'xsh:var("var")[2]' '"scratch"';

#function xsh:matches
assert1 'xsh:matches("foo","^fo{2}$")';

assert1 'not(xsh:matches("foo","O{2}"))';

assert1 'not(xsh:matches("foo","O{2}",0))';

assert1 'xsh:matches("foo","O{2}",1)';

assert1 'xsh:matches(/foo,"^sCR.tch$",1)';

assert1 'not(xsh:matches(/foo,"foo",1))';

#function xsh:substr
assert2 'xsh:substr("foobar",3)' '"bar"';

assert2 'xsh:substr("foobar",3)="baz"' 'false()';

assert2 'xsh:substr("foobar",0,3)' '"foo"';

assert2 'xsh:substr("foobar",-2)' '"ar"';

assert2 'xsh:substr("foobar",-4,3)' '"oba"';

assert2 'xsh:substr(/,1)' '"cratch"';

assert2 'xsh:substr(/foo,1)' '"cratch"';

#function xsh:reverse
assert2 'xsh:reverse("foobar")' '"raboof"';

assert2 'xsh:reverse(/foo)' '"hctarcs"';

assert2 'xsh:reverse(/foo/text())' '"hctarcs"';

#function xsh:grep
assert2 'count(xsh:grep(//node(),"."))' '2';

assert2 'count(xsh:grep(//node(),"^scr"))' '2';

assert2 'xsh:grep(//node(),".")' 'xsh:grep(//node(),"^scr")';

assert2 'xsh:grep(//node(),".")=xsh:grep(//node(),"^Scr")' 'false()';

assert2 'xsh:grep(//node(),".")' 'xsh:grep(//node(),"(?i)Scr")';

assert1 'xsh:grep(//node(),".")/self::foo';

assert1 'xsh:grep(//node(),".")/self::text()';

assert1 'not(xsh:grep(//node(),"foo"))';

assert1 'xsh:grep(//node(),".")[.="scratch"]';


assert1 'xsh:grep(//node(),"scratch")[.="scratch"]';

#function xsh:same
assert1 'xsh:same(//node(),/foo)';

assert1 'xsh:same(/foo,/foo)';

assert1 'not(xsh:same(/foo,/foo/text()))';

assert1 'not(xsh:same(/bar,/baz))';

assert1 'not(xsh:same(/foo,/bar))';

assert1 'xsh:same(/*,$doc2/*)';

#function xsh:max
$doc3 := create '<a><b>4</b><b>-3</b><b>2</b></a>';

assert2 'xsh:max(//b)' '4';

assert2 'xsh:max(//b/text())' '4';

assert2 'xsh:max(//a/text())' '0';

assert2 'xsh:max(//b[1],//b[3])' '4';

assert2 'xsh:max(-4,2,7)' '7';

assert2 'xsh:max(3,9,7)' '9';

assert2 'xsh:max(-4,-9,0)' '0';

#function xsh:min
$doc3 := create '<a><b>4</b><b>-3</b><b>2</b></a>';

assert2 'xsh:min(//b)' '-3';

assert2 'xsh:min(//b/text())' '-3';

assert2 'xsh:min(//a/text())' '0';

assert2 'xsh:min(//b[1],//b[2])' '-3';

count string(//b[1]);

count string(//b[3]);

count (xsh:min(//b[1],//b[3]));

assert2 'xsh:min(//b[1],//b[3])' '2';

assert2 'xsh:min(-4,2,7)' '-4';

assert2 'xsh:min(3,9,7)' '3';

assert2 'xsh:min(3,9,0)' '0';

#function xsh:sum
assert2 'xsh:sum(//node())' '4+4-3+2+4-3+2';

assert2 'xsh:sum(//b)' '3';

assert2 'xsh:sum(//b/text())' '3';

assert2 'xsh:sum(//b[1],//b[3])' '6';

rm //b[2];

assert2 'xsh:sum(//b)' '6';

assert2 'xsh:sum(//node())' '42+4+2+4+2';

assert2 'xsh:sum(0)' '0';

assert2 'xsh:sum(3,4,5)' '12';

assert2 'xsh:sum(-3,4,-5)' '-4';

#function xsh:strmax
$doc3 := create '<a><b>abc</b><b>bde</b><b>bbc</b></a>';

assert2 'xsh:strmax(//a)' '"abcbdebbc"';

assert2 'xsh:strmax(//b)' '"bde"';

assert2 'xsh:strmax(//b/text())' '"bde"';

assert2 'xsh:strmax(//b[1],//b[3])' '"bbc"';

#function xsh:strmin
$doc3 := create '<a><b>abc</b><b>bde</b><b>bbc</b></a>';

assert2 'xsh:strmin(//a)' '"abcbdebbc"';

assert2 'xsh:strmin(//b)' '"abc"';

assert2 'xsh:strmin(//b/text())' '"abc"';

assert2 'xsh:strmin(//b[2],//b[3])' '"bbc"';

#function xsh:join
assert2 'xsh:join("",//b)' '"abcbdebbc"';

assert2 'xsh:join(":",//b)' '"abc:bde:bbc"';

assert2 'xsh:join(//b,//b)' '"abcabcbdebbcbdeabcbdebbcbbc"';

assert2 'xsh:join(";;",//b[1],//b,//b[3])' '"abc;;abc;;bde;;bbc;;bbc"';

#function xsh:serialize
$xml = '<a>abc<!--foo--><?bar bug?> <dig/></a>';

$doc3 := create $xml;

assert2 'xsh:serialize(//dig)' '"<dig/>"';

assert2 'xsh:serialize(//a/text()[1])' '"abc"';

assert2 'xsh:serialize(//a/comment())' '"<!--foo-->"';

assert2 'xsh:serialize(//a/processing-instruction())' '"<?bar bug?>"';

assert2 'xsh:serialize(/a)' "$xml";

assert2 'xsh:serialize(//*)' '"${xml}<dig/>"';

assert2 'xsh:serialize(//node())' '"${xml}abc<!--foo--><?bar bug?> <dig/>"';

assert2 'xsh:serialize(/a,//dig,//text())' '"${xml}<dig/>abc "';

#function xsh:subst
$doc4 := create '<a>abcb</a>';

assert2 'xsh:subst("foo","fo",12)' '"12o"';

assert2 'xsh:subst("foo","o","XY")' '"fXYo"';

count (xsh:subst("foo","O","XY"));

assert2 'xsh:subst("foo","O","XY")' '"foo"';

assert2 'xsh:subst("foo","O","XY","i")' '"fXYo"';

assert2 'xsh:subst("foo","O","XY","ig")' '"fXYXY"';

assert2 'xsh:subst("foobar","f(.*b)a(.+)","$1-$2")' '"oob-r"';

assert2 'xsh:subst("foobar","(.{2}b)","uc($1)","e")' '"fOOBar"';

assert2 'xsh:subst("foobar","o","/","g")' '"f//bar"';

assert2 'xsh:subst("foobar","o","[\\]","g")' '"f[\][\]bar"';

assert2 'xsh:subst(/a,"b","X","g")' '"aXcX"';

#function xsh:sprintf
assert2 'xsh:sprintf("%%")' '"%"';

assert2 'xsh:sprintf("%d",123.3)' '"123"';

assert2 'xsh:sprintf("%04d",13.3)' '"0013"';

count (xsh:sprintf("%03.4d",13.123)) |cat 2>&1;

assert2 'xsh:sprintf("%09.4f",13.123)' '"0013.1230"';

$sp={sprintf("%e",13.123)};
assert2 'xsh:sprintf("%e",13.123)' $sp;

assert2 'xsh:sprintf("%s-%e-%s-%s","foo",13.123,"bar",/a)' '"foo-${sp}-bar-abcb"';

$doc4 := create '<a><b>abc</b><c>efg</c></a>';

assert1 '(xsh:map(/a/*,"string(text())")/self::xsh:string[1] = "abc")';

assert2 '(xsh:map(/a/*,"string(text())")/self::xsh:string)[2]' '"efg"';

assert1 '(xsh:map(/a,"count(*)")/self::xsh:number[1] = 2)';

assert1 '(xsh:map(/a,"*")/self::b)';

assert1 '(xsh:map(/a,"*")/self::c)';

assert1 '(xsh:same(xsh:map(/a,"*")/self::b,/a/b))';

assert1 '(xsh:same(xsh:map(/a,"*")/self::c,/a/c))';

foreach //node() {
  assert1 '(xsh:same(xsh:current(),.))';
}

foreach //b {
  assert1 '//c[xsh:current()="abc"]';
}

local $pwd;
foreach //node() {
  pwd |> $pwd;
  count $pwd;
  perl { chomp $pwd; chomp $pwd };
  count $pwd;
  assert2 'xsh:path(.)' '"${pwd}"';
}

$c = 0 ;
stream :N :s '<r><a/><b/><a/><c/></r>' select a { $c = $c + 1 } ;
assert2 $c 2 ;

$c = 0 ;
stream :N :p 'perl -e"print q(<r><n/><n/></r>)"' select n { $c = $c + 1 } ;
assert2 $c 2 ;
EOF

  plan tests => 4+@xsh_test;
}
END { ok(0) unless $loaded; }
use XML::XSH2 qw/&xsh &xsh_init &set_quiet &xsh_set_output/;
$loaded=1;
ok(1);

my $verbose=$ENV{HARNESS_VERBOSE};

($::RD_ERRORS,$::RD_WARN,$::RD_HINT)=(1,1,1);

$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules &c.
$::RD_HINT   = 1; # Give out hints to help fix problems.

#xsh_set_output(\*STDERR);
set_quiet(0);
xsh_init();

print STDERR "\n" if $verbose;
ok(1);

print STDERR "\n" if $verbose;
ok ( XML::XSH2::Functions::create_doc("scratch","scratch") );

print STDERR "\n" if $verbose;
ok ( XML::XSH2::Functions::set_local_xpath('/') );

foreach (@xsh_test) {
  print STDERR "\n\n[[ $_ ]]\n" if $verbose;
  eval { xsh($_) };
  print STDERR $@ if $@;
  ok( !$@ );
}

