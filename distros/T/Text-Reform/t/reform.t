#! /usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We begin with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 66;
BEGIN {
  use_ok( 'Text::Reform', qw{ form tag break_at break_wrap break_with });
}
#my $testnum = 1;
#use Data::Dumper 'Dumper';
sub teststr(&$;$) # (&sub, $retval)
{
	do { #$testnum++;
	     my $res = &{$_[0]};
  	     my $exp = $_[1];
  	     my $message=$_[2];
             s/ /./g for $res, $exp;
             if ($res eq $exp) {
               ok(1,$message);
               #print "ok $testnum\n";
             } else {
	       diag "expected [", $exp, "]";
	       diag "but got  [", $res, "]";
	       ok(0,$message);
	     }
 	   };
}

######################### End of black magic.

START:


# BREAK EXCEPTIONS

teststr { form({break=>break_at('-')},
               "<<<<<<<<","http://foo.bar.baz.com") }
"http://-
";

teststr { form({break=>break_at('-',{except=>qr{http://\S*}})},
               "<<<<<<<<","http://foo.bar.baz.com and the rest") }
"http://foo.bar.baz.com
";

teststr { form({break=>break_at('-',{except=>qr{http://\S*}})},
               "<<<<<<<<","prefixhttp://foo.bar.baz.com and the rest") }
"prefix  
";



# ZERO-WIDTH FIELD SEPARATOR

teststr { form({break=>break_with('')},"<<<<\0<<<<","aaaaa","bbbbb") }
"aaaabbbb
";

teststr { form({break=>break_with('')},"<<<<\0\0<<<<","aaaaa","bbbbb") }
"aaaa\0bbbb
";


# NARROW FIELDS

teststr { form("~+","split") }
"s+
p+
l+
i+
t+
";

teststr { form("~  [[[","*","split") }
"*  sp-
   lit
";

teststr { form("~~+","split") }
"~~+
split
";

teststr { form("|+","split") }
"|+
split
";

teststr { form("||+","split") }
"sp+
li+
t +
";

teststr { form("|||+","split") }
"sp-+
lit+
";

# ARRAY ARGUMENTS

teststr { form('{]]]]}',[qw(1 10 100 1000 10000)]) }
'{   1}
{  10}
{ 100}
{1000}
{100-}
{  00}
',q/form('{]]]]}',[qw(1 10 100 1000 10000)])/;

teststr { form('{]]].[[}',[qw(1 10 100 1000 10000)]) }
'{  1.0 }
{ 10.0 }
{100.0 }
{###.##}
{###.##}
',q/form('{]]].[[}',[qw(1 10 100 1000 10000)])/;

my @data = qw( 1 10 100 1000 );
teststr { form('{]]]]}',\@data) }
'{   1}
{  10}
{ 100}
{1000}
';

teststr { @data } "0";

@data = qw( 1 10 100 1000 );
teststr { form('{]]]]}',[@data]) }
'{   1}
{  10}
{ 100}
{1000}
';

teststr { @data } "4";

# SIMPLE LEFT FORMATTING
teststr { form("<<<<<<<<<<","1234") }
"1234      \n";

my $data = "abcd abcd";
teststr { form("[[[[[","abcd abcd") }
"abcd \nabcd \n";


# BLOCK RIGHT FORMATTING
teststr { form("]]]]]]]]]]","1234") }
"      1234\n";

# BLOCK CENTRE FORMATTING
teststr { form("||||||||||","1234") }
"   1234   \n";

# SIMPLE AND BLOCK FORMATTING
teststr { form("<<<<< [[[[[[[[[[","1234 1234 1234 1234","1234 1234 1234 1234") }
"1234  1234 1234 \n      1234 1234 \n";

$data = "abcd abcd";
teststr { form("[[[[[",$data) }
"abcd \nabcd \n";

teststr sub { $data eq "abcd abcd" }, "1";

$data = "abcd abcd";
teststr { form("[[[[[",\$data) }
"abcd \nabcd \n";

teststr sub { $data eq "" }, "1";

# FULL JUSTIFICATION

teststr { form("(<<<>>>)","a b c d e") }
"(a b  c)
";

teststr { form("([[[[]])","a b c def ghijklm") }
"(a b  c)
(def   )
(ghijk-)
(lm    )
";


# ALIGNED NUMERICAL FORMATTING

teststr { form("***]]]].[[[[***","1 1.1 1.00001 1.00009 1.2345 1.23456 1111 12345.54321 a0 b 0") }
"***   1.0   ***
***   1.1   ***
***   1.0000***
***   1.0001***
***   1.2345***
***   1.2346***
***1111.0   ***
***####.####***
***????.????***
***????.????***
***   0.0   ***
";

teststr { form( { numeric => 'SkipNaN,AllPlaces' }, "***]]]].[[[[***","1 1.1 1.00001 1.00009 1.2345 1.23456 1111 12345.54321 a0 b 0") }
"***   1.0000***
***   1.1000***
***   1.0000***
***   1.0001***
***   1.2345***
***   1.2346***
***1111.0000***
***####.####***
***   0.0000***
";

# ESCAPED AND SINGLE SPECIAL CHARACTERS
teststr { form('\<\[\^\|\>\]\\') }
'<[^|>]\\
';

teststr { form('<[^|>]') }
'<[^|>]
';

teststr { form('<identifier>') }
'<identifier>
';

teststr { form('<[[[[[[[[[[>','identifier') }
'<identifier>
';

teststr { form("<\0<<<<<<<<<<>",'identifier') }
'<identifier>
';

teststr { form("<<<<<\Q<[^|>]\\\E",123) }
'123  <[^|>]\\
';

# SQUEEZING

$str = "a b  c";

teststr { form "<"x10, $str } "$str    \n";
teststr { form {squeeze=>0}, "<"x10, $str } "$str    \n";
teststr { form {squeeze=>1}, "<"x10, $str } "a b c     \n";

SCOPED:{
	my $scope = form { squeeze=>1 };
	teststr { form "<"x10, $str } "a b c     \n";
	teststr { form {squeeze=>0}, "<"x10, $str } "$str    \n";
	teststr { form "<"x10, $str } "a b c     \n";
}

# HYPHENATION

teststr { form('[[[[[[','supercalifragelisticexpealidocious') }
'super-
calif-
ragel-
istic-
expea-
lidoc-
ious  
';


teststr { form(
{ break => break_with('~~') },
'[[[[[[','supercalifragelisticexpealidocious') }
'supe~~
rcal~~
ifra~~
geli~~
stic~~
expe~~
alid~~
ocious
';

teststr { form(
{ break => '~~' },
'[[[[[[','supercalifragelisticexpealidocious') }
'supe~~
rcal~~
ifra~~
geli~~
stic~~
expe~~
alid~~
ocious
';

teststr { form(
{ break => break_with('') },
'[[[[[[','supercalifragelisticexpealidocious') }
'superc
alifra
gelist
icexpe
alidoc
ious  
';

teststr { form(
{ break => break_wrap },
'[[[[[[','supercalifragelisticexpealidocious') }
'supercalifragelisticexpealidocious
';

teststr { form(
{ break => break_wrap },
']]]]]]]',
'one ten one hundred thousand') }
'one ten
    one
hundred
thousand
';

# NO FILL MODE
teststr { form({nofill=>1},"[[[[[",["aa","bb"]) }
"aa   
bb   
";
# ERROR MESSAGES

my $err = "";
eval {form("<<<<<",{break=>break_with('-')},"abc") } or $err =  $@;
$err =~ s/\s*\bat\b.*?\n.*//s;
teststr { $err } "Configuration hash not allowed between format and data";

$err = "";
eval {form("abcbd",{break=>break_with('-')},"abc") } or $err =  $@;
$err =~ s/ at \S+ line \d+\s*//;
teststr { $err } "";


# ALTERNATIONS

$a = 'a'x25;
$b = 'b'x25;

teststr { form({break=>break_with("")},
"+ [[[[[ [[[[[
- [[[[[ [[[[[",
$a, $b, $b, $a) }
'+ aaaaa bbbbb
- bbbbb aaaaa
+ aaaaa bbbbb
- bbbbb aaaaa
+ aaaaa bbbbb
-            
';

teststr { form({break=>break_with("")},
"+ [[[[[ [[[[[",
$a, $b,
"- [[[[[ [[[[[",
$b, $a) }
'+ aaaaa bbbbb
+ aaaaa bbbbb
+ aaaaa bbbbb
+ aaaaa bbbbb
+ aaaaa bbbbb
-            
';


# PAGING

teststr { form {pagelen=>3}, "[[[", "abc def " }
"abc
def

";

teststr { form {pagelen=>3}, "[[[", "abc def ghi" }
"abc
def
ghi
";

teststr { form {pagelen=>3}, "[[[", "abc def ghi j" }
"abc
def
ghi
j  


";

teststr { form { header => sub { "---" }, footer => '|||', pagefeed => "===\n", pagelen=>3}, "[[[", "abc def" }
"---
abc
|||
===
---
def
|||
";

teststr { form { header => sub { "---" }, footer => '|||', pagefeed => "===\n", pagelen=>4}, "[[[", "abc def ghi" }
"---
abc
def
|||
===
---
ghi

|||
";


# SIMPLE TAGGING
teststr { tag('A',"some text\nto be\ntagged") }
'<A>some text
to be
tagged</A>';

# FORMATTED TAGGING
teststr { tag("\n   <A HREF='#B'>\n\n   ","some text\nto be\ntagged") }
q{
   <A HREF='#B'>

      some text
      to be
      tagged

   </A>
};

# EXTRAPOLATED DELIMITERS
teststr { tag("<:[TAG","some text to be tagged") }
"<:[TAG]:>some text to be tagged<:[/TAG]:>";

# MISSING DELIMITERS
teststr { tag("TAG TAGARGS=args","some text to be tagged") }
"<TAG TAGARGS=args>some text to be tagged</TAG>";

# PARTIALLY MISSING EXTRAPOLATED  DELIMITERS
teststr { tag("{{TAG TAGARGS=args","some text to be tagged") }
"{{TAG TAGARGS=args}}some text to be tagged{{/TAG}}";

# NESTED TAGS
teststr { tag "\n   <B>\n", tag("   <A HREF='#B'>\n   ","some text\nto be\ntagged\n") }
q{
   <B>
      <A HREF='#B'>
         some text
         to be
         tagged
      </A>
   </B>
};



# OBJECTS WHICH STRINGIFY
teststr { form("<<<", Stringify->new) }
"foo\n";

package Stringify;
use overload '""' => sub { return "foo" };
sub new {
  return bless {}, shift;
}

