# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..28\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::Vpp;
use Config;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# will load a text file, set some variables and compare the output

$fin = new Text::Vpp("text_in.txt") ;
$fin->setVar('var1' => 'was set in calling script') ;

my $ret = $fin -> substitute() ;

my $expect = 
"Sample text for Text::Vpp
Some included text

We shoud see this line from included file
We should see this line

We should see this line if var1 was set by perl
var 1 is: was set in calling script.

Should see this one.

" ;

if ($ret)
  {
	print "ok 2\n";
  }
else
  {
	print "not ok 2\n";
	print @{$fin->getErrors()} ;
  }

my $res = join("\n",@{$fin->getText()})."\n" ;

if ($res eq $expect)
  {
	print "ok 3\n";
  }
else
  {
	print "not ok 3\n",
	"expect\n---\n",$expect,"---\n",
	"got   \n---\n",$res,   "---\n";
  }



# Test the ELSIF construct.

$fin = new Text::Vpp("text_elsif.txt") ;
$fin->setVar('var1' => 3) ;

$ret = $fin -> substitute() ;

$expect =  "Sample text for Text::Vpp using ELSEIF
We should see this line, because var1 should be 3
" ;

if ($ret)
  {
	print "ok 4\n";
  }
else
  {
	print "not ok 4\n";
	print @{$fin->getErrors()} ;
  }

$res = join("\n",@{$fin->getText()})."\n" ;

if ($res eq $expect)
  {
	print "ok 5\n";
  }
else
  {
	print "not ok 5\n",
	"expect\n---\n",$expect,"---\n",
	"got   \n---\n",$res,   "---\n";
  }


# test backslash stuff
$fin = new Text::Vpp("text_backslash.txt") ;

$expect =  "first line next line\n\nsecond line\n" ;

$ret = $fin -> substitute() ;

if ($ret)
  {
	print "ok 6\n";
  }
else
  {
	print "not ok 6\n";
	print @{$fin->getErrors()} ;
  }

$res = join("\n",@{$fin->getText()})."\n" ;

if ($res eq $expect)
  {
	print "ok 7\n";
  }
else
  {
	print "not ok 7\n",
	"expect\n---\n",$expect,"---\n",
	"got   \n---\n",$res,   "---\n";
  }

# test ignore backslash stuff
$fin = new Text::Vpp("text_backslash.txt") ;
$fin->ignoreBackslash;

$expect =  "first line \\\nnext line\n\nsecond line\n" ;

$ret = $fin -> substitute() ;

if ($ret)
  {
	print "ok 8\n";
  }
else
  {
	print "not ok 8\n";
	print @{$fin->getErrors()} ;
  }

$res = join("\n",@{$fin->getText()})."\n" ;

if ($res eq $expect)
  {
	print "ok 9\n";
  }
else
  {
	print "not ok 9\n",
	"expect\n---\n",$expect,"---\n",
	"got   \n---\n",$res,   "---\n";
  }


# test action Char 
$fin = new Text::Vpp("text_action.txt") ;
$fin->ignoreBackslash;

$expect =  "included text\n\nSome more text\n\n";
$fin->setActionChar('^');
$fin->setVar('foo' => 1);

$ret = $fin -> substitute() ;

if ($ret)
  {
	print "ok 10\n";
  }
else
  {
	print "not ok 10\n";
	print @{$fin->getErrors()} ;
  }

$res = join("\n",@{$fin->getText()})."\n" ;

if ($res eq $expect)
  {
	print "ok 11\n";
  }
else
  {
	print "not ok 11\n",
	"expect\n---\n",$expect,"---\n",
	"got   \n---\n",$res,   "---\n";
  }


#redo the subsitute for fun
$fin->rewind;
$ret = $fin -> substitute() ;

if ($ret)
  {
	print "ok 12\n";
  }
else
  {
	print "not ok 12\n";
	print @{$fin->getErrors()} ;
  }

$res = join("\n",@{$fin->getText()})."\n" ;

if ($res eq $expect)
  {
	print "ok 13\n";
  }
else
  {
	print "not ok 13\n",
	"expect\n---\n",$expect,"---\n",
	"got   \n---\n",$res,   "---\n";
  }

# test FOREACH loop and substitution patter
 
$fin = new Text::Vpp("for_subs.txt") ;
$fin->setPrefixChar('\\');

$expect = <<'EOExp';
Sample text for demonstrating loops and subsitution patterns
numbers 0: 0  and  3: 3 on this line
 print this line

---------------------
generated line: 1 column: 7 position 7 <<<
generated line: 1 column: 11 position 11 <<<
---------------------
generated line: 2 column: 7 position 87 <<<
generated line: 2 column: 11 position 91 <<<
---------------------
generated line: 3 column: 7 position 167 <<<
generated line: 3 column: 11 position 171 <<<

last line
EOExp

$fin->setVar(Real => 1, Complex => 0);

$ret = $fin -> substitute() ;

if ($ret)
  {
	print "ok 14\n";
  }
else
  {
	print "not ok 14\n";
	print @{$fin->getErrors()} ;
  }

$res = join("\n",@{$fin->getText()})."\n" ;

if ($res eq $expect)
  {
	print "ok 15\n";
  }
else
  {
	print "not ok 15\n",
	"expect\n---\n",$expect,"---\n",
	"got   \n---\n",$res,   "---\n";
  }

$fin = new Text::Vpp("advanced.txt") ;
$fin->setPrefixChar('\\');

$expect = <<'EOExp';

>hello world: here is Pi: 3.14159265358979     EOL
>> expanded Forlist 1st time
  ----- inner loop at 1 / 1
    +++ level 3 : 1 / 1 / 1
    +++ level 3 : 1 / 1 / 2
  ----- inner loop at 1 / 2
    +++ level 3 : 1 / 2 / 1
    +++ level 3 : 1 / 2 / 2
  ----- inner loop at 1 / 3
    +++ level 3 : 1 / 3 / 1
    +++ level 3 : 1 / 3 / 2
<<<<<<<<<<
>> expanded Forlist 2nd time
  ----- inner loop at 2 / 1
    +++ level 3 : 2 / 1 / 1
    +++ level 3 : 2 / 1 / 2
  ----- inner loop at 2 / 2
    +++ level 3 : 2 / 2 / 1
    +++ level 3 : 2 / 2 / 2
  ----- inner loop at 2 / 3
    +++ level 3 : 2 / 3 / 1
    +++ level 3 : 2 / 3 / 2
<<<<<<<<<<
EOExp

$fin->setVar(Real => 1, Complex => 0);

$ret = $fin -> substitute() ;

if ($ret)
  {
	print "ok 16\n";
  }
else
  {
	print "not ok 16\n";
	print @{$fin->getErrors()} ;
  }

$res = join("\n",@{$fin->getText()})."\n" ;

if ($res eq $expect)
  {
	print "ok 17\n";
  }
else
  {
	print "not ok 17\n",
	"expect\n---\n",$expect,"---\n",
	"got   \n---\n",$res,   "---\n";
  }

use IO::File;
my $Input = new IO::File("text_in2.txt");
my $Output= new IO::File(">text_in2.out");
$fin = new Text::Vpp($Input,{ Var1 => 'first', Var2 => 'Include' });
$expect = <<'EOExp';
This is the first line.
# this isn't a comment and should show up
expanded loop (Include file) line 1 EOL
expanded loop (Include file) line 2 EOL
2 times 3 gives 6
EOExp
if ( $fin->substitute($Output) )
     { print "ok 18\n"; }
else { print "not ok 18\n"; print @{$fin->getErrors()}; }
close $Input; close $Output;

if ( $Input->open("text_in2.out") )
     { print "ok 19\n"; }
else { print "not ok 19\n"; }

{ local $/; $res= <$Input>; }
close $Input; unlink "text_in2.out";
if ($res eq $expect)
  {
	print "ok 20\n";
  }
else
  {
	print "not ok 20\n",
	"expect\n---\n",$expect,"---\n",
	"got   \n---\n",$res,   "---\n";
  }
$fin = new Text::Vpp("test1_1.txt");
$fin->setVarFromFile("test1_1.var");
$fin->setPrefixChar('^(');  $fin->setSuffixChar(')');
$fin->setSubstitute(['&{','}']);
$expect = <<'EOExp';
Here is pi : 3.14159265358979 !
  Keep the dollar $ here
  Guru's address is
  Sarathy Gurusamy
  Madison  in  Michigan or in Perl City or in elsewhere
  008
EOExp

#' ; # for xemacs

$ret = $fin -> substitute() ;

if ($ret)
  {
	print "ok 21\n";
  }
else
  {
	print "not ok 21\n";
	print @{$fin->getErrors()} ;
  }

$res = join("\n",@{$fin->getText()})."\n" ;

if ($res eq $expect)
  {
	print "ok 22\n";
  }
else
  {
	print "not ok 22\n",
	"expect\n---\n",$expect,"---\n",
	"got   \n---\n",$res,   "---\n";
  }

#-----------------------------------------

$fin = new Text::Vpp("perlprog.txt");
$fin->setVar(Guru => 'Gurusamy Sarathy');
$expect = <<'EOExp';
This is the first normal line
This is the second normal line
Hello world - Here I am
and here on the next line
This is the third normal line
double chance_7_of_49 = 0.000000013582;
This is the fourth normal line
double chance_6_of_16 = 0.000199800200;
Who is the Guru : our Guru is Gurusamy Sarathy :
This is the last line
EOExp

$ret = $fin -> substitute() ;

if ($ret)
  {
	print "ok 23\n";
  }
else
  {
	print "not ok 23\n";
	print @{$fin->getErrors()} ;
  }

$res = join("\n",@{$fin->getText()})."\n" ;

if ($res eq $expect)
  {
	print "ok 24\n";
  }
else
  {
	print "not ok 24\n",
	"expect\n---\n",$expect,"---\n",
	"got   \n---\n",$res,   "---\n";
  }

# test shell stuff
$expect='test shell stuff on unix only
1rst test
test.pl
text_shell.txt

2nd test
Vpp.pm

3rd test
Vpp.pm
text_shell.txt
';

if ($Config{osname} ne 'win32')
  {
    $fin = new Text::Vpp("text_shell.txt");
    $ret = $fin -> substitute() ;
    if ($ret)
      {
        print "ok 25\n";
      }
    else
      {
	print "not ok 25\n";
	print @{$fin->getErrors()} ;
      }

    $res = join("\n",@{$fin->getText()})."\n" ;

    if ($res eq $expect)
      {
	print "ok 26\n";
      }
    else
      {
	print "not ok 26\n",
          "expect\n---\n",$expect,"---\n",
            "got   \n---\n",$res,   "---\n";
      }
  }
else
  {
    print "skip 25\nskip 26\n";
  }

# test include mixed with eval
$expect='
de:\usepackage[german]{babel}:en:\usepackage[english]{babel}

Some included text

We shoud see this line from included file

  {\Large \bf
de:Produkte \& Services:en:Products \& Services
\\\\\medskip
';

$fin = new Text::Vpp("text_eval_include.txt");
$fin->setVar('var1' => 1);
$ret = $fin -> substitute() ;
if ($ret)
  {
    print "ok 27\n";
  }
else
  {
    print "not ok 27\n";
    print @{$fin->getErrors()} ;
  }
$res = join("\n",@{$fin->getText()})."\n" ;

if ($res eq $expect)
  {
    print "ok 28\n";
  }
else
  {
    print "not ok 28\n",
      "expect\n---\n",$expect,"---\n",
	"got   \n---\n",$res,   "---\n";
  }
