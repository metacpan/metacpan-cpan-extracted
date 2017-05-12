# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..25\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::FillIn;
$loaded = 1;
&report(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub report {
	$TEST_NUM++;
	print ( $_[0] ? "ok $TEST_NUM\n" : "not ok $TEST_NUM\n" );
}

# The variables for interpolation
$TVars{'var'} = 'text';
$TVars{'nestedtext'} = 'coconuts';
$TVars{'more_var'} = 'donuts';
$TVars{'var2'} = 'nested';
$TVars{'text\\]]'} = 'garbage';

# 2,3
&test_both('some [[$var]] and so on' => 'some text and so on');

# 4,5
&test_both('some [[ $nested[[$var]] ]] flambe' => 'some coconuts flambe');

# 6,7
&test_both('[[$var]]' => 'text');

# 8,9
&test_both('[[ $var ]]' => 'text');

# 10,11
&test_both('an example of [[$var]] and [[$more_var]] together' =>
             'an example of text and donuts together');

# 12,13
&test_both('some [[$[[$var2]][[$var]]]] and some \\[[ text \\]]' =>
             'some coconuts and some [[ text ]]');

# 14,15
&test_both('some [[$[[$var2]][[$var]]]] and some [[ $text\\]] ]]' =>
             'some coconuts and some garbage');

# 16,17
&test_both('some [[&func1()]]?' => 'some snails?');

# 18,19
&test_both('some [[&func2(star,studded)]] SNAILS?' => 'some STAR*STUDDED SNAILS?');

# 20,21
&test_both('Pi is about [[&add_numbers(3,.1,.04,.001,.0006)]]' => 'Pi is about 3.1416');

# 22,23,24
{
	my $t = new Text::FillIn('some [[$var} unbalanced');
	$t->Rdelim('}');
	&should_equal($t->interpret(), 'some text unbalanced');

	$t = new Text::FillIn('some {$var]] unbalanced');
	$t->Ldelim('{');
	&should_equal($t->interpret(), 'some text unbalanced');
	
	Text::FillIn->Ldelim('(');
	$t = new Text::FillIn('some ($var]] unbalanced');
	&should_equal($t->interpret(), 'some text unbalanced');
	Text::FillIn->Ldelim('[[');
	Text::FillIn->Rdelim(']]');
}

# 25
{
	my $obj = bless {thing=>5}, 'MyPack';
	sub MyPack::find_value { my $s = shift; $s->{shift()} }

	my $t = new Text::FillIn('some [[$thing]] is 5');
	$t->object($obj);
	&should_equal($t->interpret(), 'some 5 is 5');
}

###################################################################

sub test_both {
   &test_interpret(@_);
   &test_print(@_);
}

sub test_interpret {
   my ($raw_text, $cooked_text) = @_;
   my $result = Text::FillIn->new($raw_text)->interpret();

   &should_equal($result, $cooked_text);
}

sub test_print {
   my $debug = 0;
   my ($raw_text, $cooked_text) = @_;
   my $template = new Text::FillIn($raw_text);
   my $file = 'output_test';
   
   open (TEMP, ">$file") or die "Couldn't create $file: $!";
   my $prev_select = select TEMP;
   $template->interpret_and_print();
   close TEMP;
   select $prev_select;

   my $result = `cat $file`;
   unlink $file or die $!;
   
   &should_equal($result, $cooked_text);
}

sub should_equal {
	my ($one, $two) = @_;
	&report($one eq $two);
	if ($one ne $two  and  $ENV{TEST_VERBOSE}) {
		print STDERR "$one =/= $two\n";
	}
}

sub TExport::func1 {
   return "snails";
}

sub TExport::func2 {
   return join '*', map {uc} @_;
}

sub TExport::add_numbers {
  my $result;
  foreach (@_) {
     $result += $_;
  }
  return $result;
}
		    
