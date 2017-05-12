#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  Test::Tech;

# use 5.001;
use strict;
use warnings;
use warnings::register;

use Test ();   # do not import the "Test" subroutines
use Data::Secs2 1.22 qw(stringify);
use Data::Str2Num 0.05;
use Data::Startup 0.03;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.27';
$DATE = '2004/05/28';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA=('Exporter');
@EXPORT_OK = qw(demo finish is_skip ok ok_sub plan skip skip_sub
                skip_tests stringify tech_config);

#######
# For subroutine interface keep all data hidden in a local hash of private object
# 
my $tech_p = new Test::Tech;

sub new
{

   ####################
   # $class is either a package name (scalar) or
   # an object with a data pointer and a reference
   # to a package name. A package name is also the
   # name of a class
   #
   my ($class, @args) = @_;
   $class = ref($class) if( ref($class) );
   my $self = bless {}, $class;

   ######
   # Make Test variables visible to tech_config
   #  
   $self->{Test}->{ntest} = \$Test::ntest;
   $self->{Test}->{TESTOUT} = \$Test::TESTOUT;
   $self->{Test}->{TestLevel} = \$Test::TestLevel;
   $self->{Test}->{ONFAIL} = \$Test::ONFAIL;
   $self->{Test}->{TESTERR} = \$Test::TESTERR if defined $Test::TESTERR; 

   $self->{TestDefault}->{TESTOUT} = $Test::TESTOUT;
   $self->{TestDefault}->{TestLevel} = $Test::TestLevel;
   $self->{TestDefault}->{ONFAIL} = $Test::ONFAIL;
   $self->{TestDefault}->{TESTERR} = $Test::TESTERR if defined $Test::TESTERR; 

   ######
   # Test::Tech object data
   #
   $self->{Skip_Tests} = 0;
   $self->{test_name} = '';
   $self->{passed} = [];
   $self->{failed} = [];
   $self->{skipped} = [];
   $self->{missed} = [];
   $self->{unplanned} = [];
   $self->{last_test} = 0;
   $self->{num_tests} = 0;
   $self->{highest_test} = 0;

   ######
   # Redirect Test:: output thru Test::Tech::Output handle
   #   unless been redirected and never restored!!
   #
   unless( \*TESTOUT eq $Test::TESTOUT ) {
       $self->{test_out} = $Test::TESTOUT;
       tie *TESTOUT, 'Test::Tech::Output', $Test::TESTOUT, $self;
       $Test::TESTOUT = \*TESTOUT;
   }

   $self;

}
 
######
# Demo
#
sub demo
{
   use Data::Dumper;

   ######
   # This subroutine uses no object data; therefore,
   # drop any class or object.
   #
   shift if UNIVERSAL::isa($_[0],__PACKAGE__);

   my ($quoted_expression, @expression) = @_;

   #######
   # A demo trys to simulate someone typing expresssions
   # at a console.
   #

   #########
   # Print quoted expression so that see the non-executed
   # expression. The extra space is so when pasted into
   # a POD, the POD will process the line as code.
   #
   $quoted_expression =~ s/(\n+)/$1 /g;
   print $Test::TESTOUT ' ' . $quoted_expression . "\n";   

   ########
   # @data is the result of the script executing the 
   # quoted expression.
   #
   # The demo output most likely will end up in a pod. 
   # The the process of running the generated script
   # will execute the setup. Thus the input is the
   # actual results. Putting a space in front of it
   # tells the POD that it is code.
   #
   return unless @expression;
  
   $Data::Dumper::Terse = 1;
   my $data = Dumper(@expression);
   $data =~ s/(\n)/$1 # /g;
   $data =~ s/\\\\/\\/g;
   $data =~ s/\\'/'/g;

   print $Test::TESTOUT "\n # " . $data . "\n" ;

}

#####
# Restore the Test:: moduel variable back to where they were when found
#
sub finish
{
    $tech_p = Test::Tech->new() unless $tech_p;
    my $self = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift @_ : $tech_p;
    $self = ref($self) ? $self : $tech_p;

    return undef unless $Test::TESTOUT;  # if IO::Handle object may be destroyed and undef
    return undef unless $Test::planned;  

    my $missing = $self->{last_test} + 1;
    $self->{test_name} = '';
    while($missing <= $self->{num_tests}) {
        $self->{Skip_Diag} = '' unless $self->{Skip_Diag};
        print $Test::TESTOUT "not ok $missing Not Performed # missing $self->{Skip_Diag}\n";
        if( 1.20 < $Test::VERSION ) {
            print $Test::TESTERR "# Test $missing got: (Missing)\n";
            print $Test::TESTERR "# Expected: (Missing)\n";
        }
        else {
            print $Test::TESTOUT "# Test $missing got: (Missing)\n";
            print $Test::TESTOUT "# Expected: (Missing)\n";
        }
        push @{$self->{missed}}, $missing++;
    }

    $Test::TESTOUT = $self->{TestDefault}->{TESTOUT};
    $Test::TestLevel = $self->{TestDefault}->{TestLevel};
    $Test::ONFAIL = $self->{TestDefault}->{ONFAIL};
    $Test::TESTERR = $self->{TestDefault}->{TESTERR} if defined $Test::TESTERR;

    if(@{$self->{unplanned}}) {
        print $Test::TESTOUT '# Extra  : ' . (join ' ', @{$self->{unplanned}}) . "\n";
    }
    if(@{$self->{missed}}) {
        print $Test::TESTOUT '# Missing: ' . (join ' ', @{$self->{missed}}) . "\n";
    }
    if(@{$self->{skipped}}) {
        print $Test::TESTOUT '# Skipped: ' . (join ' ', @{$self->{skipped}}) . "\n";
    }
    if(@{$self->{failed}}) {
        print $Test::TESTOUT '# Failed : ' . (join ' ', @{$self->{failed}}) . "\n";
    }
    use integer;

    my $total = $self->{num_tests} if $self->{num_tests};
    $total = $self->{last_test} if $self->{last_test} && $self->{num_tests} < $self->{last_test};
    $total -= @{$self->{skipped}};

    my $passed =  @{$self->{passed}};
    print $Test::TESTOUT '# Passed : ' . "$passed/$total " . ((100*$passed)/$total) . "%\n" if $total;

    ######
    # Only once per test run.
    #
    $Test::planned = 0;

    return ($total,$self->{unplanned},$self->{missed},$self->{skipped},$self->{passed},$self->{failed})
          if wantarray;

    $passed ? 1 : 0;
}

# *finish = &*Test::Tech::DESTORY; # DESTORY is alias for finish
sub DESTORY 
{
    finish( @_ );

}


######
#
#
sub is_skip
{
    $tech_p = Test::Tech->new() unless $tech_p;
    my $self = (UNIVERSAL::isa($_[0],__PACKAGE__) && ref($_[0])) ? shift @_ : $tech_p;
    $self = ref($self) ? $self : $tech_p;
    return ($self->{Skip_Tests}, $self->{Skip_Diag}) if wantarray;
    $self->{Skip_Tests};
   
}

######
# Cover function for &Test::ok that adds capability to test 
# complex data structures.
#
sub ok
{ 
  $Test::TestLevel++;
  my $results = ok_sub('',@_);
  $Test::TestLevel--;
  $results;
}

######
# Cover function for &Test::ok that adds capability to test 
# complex data structures.
#
sub ok_sub
{

    ######
    # If no object, use the default $tech_p object.
    #
    $tech_p = Test::Tech->new() unless $tech_p;
    my $self = (UNIVERSAL::isa($_[0],__PACKAGE__) && ref($_[0])) ? shift @_ : $tech_p;
    $self = ref($self) ? $self : $tech_p;

    my ($diagnostic,$name) = ('',''); 
    my $options = Data::Startup->new(pop @_) if (3 < @_) && ref($_[-1]);

    $diagnostic = $options->{diagnostic} if defined $options->{diagnostic};
    $name = $options->{name} if defined $options->{name};

    my ($subroutine, $actual_result, $expected_result, $diagnostic_in, $name_in) = @_;

    ######### 
    # Fill in undefined inputs
    #
    $diagnostic = $diagnostic_in if defined $diagnostic_in;
    $name = $name_in if defined $name_in;
    $diagnostic = $name unless defined $diagnostic;
    $self->{test_name} = $name;  # used by tied handle Test::Tech::Output

    if($self->{Skip_Tests}) { # skip rest of tests switch
        &Test::skip( 1, '', '', $self->{Skip_Diag});
        return 1; 
    }

    my $str_actual_result = stringify($actual_result);
    my $str_expected_result = stringify($expected_result);
    foreach ($str_actual_result,$str_expected_result) {
        if(ref($_)) {
            $$_ =~ s/\n\n/\n# /g; 
            $$_ =~ s/\n([^#])/\n# $1/g;
            $diagnostic = 'Test::Tech::stringify() broken.';
            $self->{test_name} .= ' # ' . $diagnostic;
            &Test::ok($$_,'',$diagnostic,$diagnostic);
            return 0;
        }
    }
    if($subroutine) {
        $diagnostic .= "\n" unless substr($diagnostic,-1,1) eq "\n";
        $str_actual_result =~ s/\n/\n /g;
        $str_expected_result =~ s/\n/\n /g;
        $diagnostic .= 
           " got: $str_actual_result\n" .
           " expected: $str_expected_result\n";   
        $str_actual_result = &$subroutine($actual_result,$expected_result);
        $str_expected_result = 1;
    }

    &Test::ok($str_actual_result, $str_expected_result, $diagnostic);

}


######
# Cover function for &Test::plan that sets the proper 'Test::TestLevel'
# and outputs some info on the current site
#
sub plan
{
    ######
    # This subroutine uses no object data; therefore,
    # drop any class or object.
    #
    $tech_p = Test::Tech->new() unless $tech_p;
    my $self = (UNIVERSAL::isa($_[0],__PACKAGE__) && ref($_[0])) ? shift @_ : $tech_p;
    $self = ref($self) ? $self : $tech_p;

    &Test::plan( @_ );

    ###############
    #  
    # Establish default for Test
    #
    # Test 1.24 resets global variables in plan which
    # never happens in 1.15
    #
    $Test::TestLevel = 1;

    my $loctime = localtime();
    my $gmtime = gmtime();

    my $perl = "$]";
    if(defined(&Win32::BuildNumber) and defined &Win32::BuildNumber()) {
       $perl .= " Win32 Build " . &Win32::BuildNumber();
    }
    elsif(defined $MacPerl::Version) {
       $perl .= " MacPerl version " . $MacPerl::Version;
    }

    print $Test::TESTOUT <<"EOF" unless 1.20 < $Test::VERSION ;
# OS             : $^O
# Perl           : $perl
# Local Time     : $loctime
# GMT Time       : $gmtime
# Test           : $Test::VERSION
EOF

    print $Test::TESTOUT <<"EOF";
# Test::Tech     : $VERSION
# Data::Secs2    : $Data::Secs2::VERSION
# Data::Startup  : $Data::Startup::VERSION
# Data::Str2Num  : $Data::Str2Num::VERSION
# Number of tests: $self->{num_tests}
# =cut 
EOF

   1
}


######
#
#
sub skip { 
  $Test::TestLevel++;
  my $results = skip_sub( '', @_ );
  $Test::TestLevel--;
  $results;

};


######
#
#
sub skip_sub
{

    ######
    # If no object, use the default $tech_p object.
    #
    $tech_p = Test::Tech->new() unless $tech_p;
    my $self = (UNIVERSAL::isa($_[0],__PACKAGE__) && ref($_[0])) ? shift @_ : $tech_p;
    $self = ref($self) ? $self : $tech_p;

    my ($diagnostic,$name) = ('',''); 
    my $options = Data::Startup->new(pop @_) if (4 < @_) && ref($_[-1]);

    $diagnostic = $options->{diagnostic} if $options->{diagnostic};
    $name = $options->{name} if $options->{name};

    my ($subroutine, $mod, $actual_result, $expected_result, $diagnostic_in, $name_in) = @_;

    $diagnostic = $diagnostic_in if defined $diagnostic_in;
    $name = $name_in if defined $name_in;
    $diagnostic = $name unless defined $diagnostic;
    $self->{test_name} = $name;  # used by tied handle Test::Tech::Output

    if($self->{Skip_Tests}) {  # skip rest of tests switch
        &Test::skip( 1, '', '', $self->{Skip_Diag});
        return 1; 
    }

    my $str_actual_result = stringify($actual_result);
    my $str_expected_result = stringify($expected_result);
    foreach ($str_actual_result,$str_expected_result) {
        if(ref($_)) {
            $$_ =~ s/\n\n/\n# /g; 
            $$_ =~ s/\n([^#])/\n# $1/g;
            $diagnostic = 'Test::Tech::stringify() broken.';
            $self->{test_name} .= ' # ' . $diagnostic;
            &Test::ok($$_,'',$diagnostic,$diagnostic);
            return 0;
        }
    }
  
    if($subroutine) {
        $diagnostic .= "\n" unless substr($diagnostic,-1,1) eq "\n";
        $str_actual_result =~ s/\n/\n /g;
        $str_expected_result =~ s/\n/\n /g;
        $diagnostic .= 
           " got: $str_actual_result\n" .
           " expected: $str_expected_result\n";
        $str_actual_result = &$subroutine($actual_result,$expected_result);
        $str_expected_result = 1;
    }

    &Test::skip($mod, $str_actual_result, $str_expected_result, $diagnostic);
}


######
#
#
sub skip_tests
{

    ######
    # If no object, use the default $tech_p object.
    #
    $tech_p = Test::Tech->new() unless $tech_p;
    my $self = (UNIVERSAL::isa($_[0],__PACKAGE__) && ref($_[0])) ? shift @_ : $tech_p;
    $self = ref($self) ? $self : $tech_p;

    my ($value,$diagnostic) =  @_;
    my $result = $self->{Skip_Tests};
    $value = 1 unless (defined $value);
    $self->{Skip_Tests} = $value;
    $diagnostic = 'Test not performed because of previous failure.' unless defined $diagnostic;
    $self->{Skip_Diag} = $value ? $diagnostic : '';
    $result;
   
}


#######
# This accesses the values in the %tech hash
#
# Use a dot notation for following down layers
# of hashes of hashes
#
sub tech_config
{

    ######
    # If no object, use the default $tech_p object.
    #
    $tech_p = Test::Tech->new() unless $tech_p;
    my $self = (UNIVERSAL::isa($_[0],__PACKAGE__) && ref($_[0])) ? shift @_ : $tech_p;
    $self = ref($self) ? $self : $tech_p;

    my ($key, $value) = @_;
    my @keys = split /\./, $key;

    #########
    # Follow the hash with the current
    # dot index until there are no more
    # hashes. For success, the dot hash 
    # notation must match the structure.
    #
    my $key_p = $self;
    while (@keys) {

        $key = shift @keys;

        ######
        # Do not allow creation of new configs
        #
        if( defined( $key_p->{$key}) ) {

            ########
            # Follow the hash
            # 
            if( ref($key_p->{$key}) eq 'HASH' ) { 
                $key_p  = $key_p->{$key};
            }
            else {
               if(@keys) {
                   warn( "More key levels than hashes.\n");
                   return undef; 
               } 
               last;
            }
        }
    }


    #########
    # References to arrays and scalars in the config may
    # be transparent.
    #
    my $current_value = $key_p->{$key};
    if( ref($current_value) eq 'SCALAR') {
        $current_value = $$current_value;
    }
    if (defined $value && $key ne 'ntest') {
        if( ref($value) eq 'SCALAR' ) {
            ${$key_p->{$key}} = $$value;
        }
        else {
            ${$key_p->{$key}} = $value;
        }
    }

    $current_value;
}


########
# Handle Tie to catch the Test module output
# so that it may be modified.
#
package Test::Tech::Output;
use Tie::Handle;
use vars qw(@ISA);
@ISA=('Tie::Handle');

#####
# Tie 
#
sub TIEHANDLE
{
     my($class, $test_handle, $tech) = @_;
     $class = ref($class) if ref($class); 
     bless {test_out => $test_handle, tech => $tech}, $class;
}


#####
#  Print out the test output
#
sub PRINT
{
    my $self = shift;   
    my $buf = join(defined $, ? $, : '',@_);
    $buf .= $\ if defined $\;
    my $test_name = $self->{tech}->{test_name};
    my $skip_diag = $self->{tech}->{Skip_Diag};
    
    #####
    # Insert test name after ok or not ok
    #
    $buf =~ s/(ok \d+)/$1 - $test_name /g if($test_name);

    ######
    # Insert skip diag after a skip comment
    #
    $buf =~ s/(# skip.*?)(\s*|\n)/$1 - $skip_diag$2/ig if $skip_diag;

    #####
    # Keep stats on what tests that pass, failed, skip, todo
    # 
    $self->stats($buf);

    #####
    # Output the modified buffer
    #
    my $handle = $self->{test_out};
    print $handle $buf;
}

#####
# 
#
sub PRINTF
{
    my $self = shift;   
    $self->PRINT (sprintf(shift,@_));
}

sub stats
{
    my ($self,$buf) = @_;
    #####
    # Stats
    my $tech = $self->{tech};
    my $test_num;
    if($buf =~ /^\s*(not ok|ok)\s*(\d+)/) {
        $test_num = $2;
    }
    if($test_num) {
        if( $tech->{num_tests} < $test_num) {
            push @{$tech->{unplanned}},$test_num;
        }
        if($tech->{last_test} + 1 != $test_num) {
            push @{$tech->{missing}},$test_num;
        }
        $tech->{last_test} = $test_num;
    }
    if($buf =~ /^\d+\.\.(\d+)/) {
        $tech->{num_tests} = $1;
    }
    elsif ($buf =~ /^\s*ok\s*(\d+).*?\#\s*skip/i) {
        push @{$tech->{skipped}},$1;
    }
    elsif ($buf =~ /^\s*not ok\s*(\d+)/i) { 
       push @{$tech->{failed}},$1;
    }
    elsif ($buf =~ /^\s*ok\s*(\d+)/i) {
       push @{$tech->{passed}},$1;
    }
}

1

__END__

=head1 NAME
  
Test::Tech - adds skip_tests and test data structures capabilities to the "Test" module

=head1 SYNOPSIS

 #######
 # Procedural (subroutine) Interface
 #
 # (use for &Test::plan, &Test::ok, &Test::skip drop in)
 #  
 use Test::Tech qw(demo finish is_skip ok ok_sub plan skip skip_sub
      skip_tests stringify tech_config);

 demo($quoted_expression, @expression);

 (@stats) = finish( );
 $num_passed = finish( );

 $skip_on = is_skip( );
 ($skip_on, $skip_diag) = is_skip( );

 $test_ok = ok($actual_results, $expected_results, [@options]);
 $test_ok = ok($actual_results, $expected_results, $diagnostic, [@options]);
 $test_ok = ok($actual_results, $expected_results, $diagnostic, $test_name, [@options]);

 $test_ok = ok_sub(\&subroutine, $actual_results, $expected_results, [@options]);
 $test_ok = ok_sub(\&subroutine, $actual_results, $expected_results, $diagnostic, [@options]);
 $test_ok = ok_sub(\&subroutine, $actual_results, $expected_results, $diagnostic, $test_name, [@options]);

 $success = plan(@args);

 $test_ok = skip($skip_test, $actual_results,  $expected_results, [@options]);
 $test_ok = skip($skip_test, $actual_results,  $expected_results, $diagnostic, [@options]);
 $test_ok = skip($skip_test, $actual_results,  $expected_results, $diagnostic, $test_name, [@options]);

 $test_ok = skip_sub(\&subroutine, $skip_test, $actual_results, $expected_results, [@options]);
 $test_ok = skip_sub(\&subroutine, $skip_test, $actual_results, $expected_results, $diagnostic, [@options]);
 $test_ok = skip_sub(\&subroutine, $skip_test, $actual_results, $expected_results, $diagnostic, $test_name, [@options]);

 $skip_on = skip_tests( $on_off, $skip_diagnostic);
 $skip_on = skip_tests( $on_off );
 $skip_on = skip_tests( );

 $string = stringify($var, @options); # imported from Data::Secs2

 $new_value  = tech_config( $key, $old_value);

 #####
 # Object Interface
 # 
 $tech = new Test::Tech;

 $tech->demo($quoted_expression, @expression)

 (@stats) = $tech->finish( );
 $num_passed = $tech->finish( );

 $skip_on = $tech->is_skip( );
 ($skip_on, $skip_diag) = $tech->is_skip( );

 $test_ok = $tech->ok($actual_results, $expected_results, [@options]);
 $test_ok = $tech->ok($actual_results, $expected_results, $diagnostic, [@options]);
 $test_ok = $tech->ok($actual_results, $expected_results, $diagnostic, $test_name, [@options]);

 $test_ok = $tech->ok_sub(\&subroutine, $actual_results, $expected_results, [@options]);
 $test_ok = $tech->ok_sub(\&subroutine, $actual_results, $expected_results, $diagnostic, [@options]);
 $test_ok = $tech->ok_sub(\&subroutine, $actual_results, $expected_results, $diagnostic, $test_name, [@options]);

 $success = $tech->plan(@args);

 $test_ok = $tech->skip($skip_test, $actual_results,  $expected_results, [@options]);
 $test_ok = $tech->skip($skip_test, $actual_results,  $expected_results, $diagnostic, [@options]);
 $test_ok = $tech->skip($skip_test, $actual_results,  $expected_results, $diagnostic, $test_name, [@options]);

 $test_ok = $tech->skip_sub(\&subroutine, $skip_test, $actual_results, $expected_results, [@options]);
 $test_ok = $tech->skip_sub(\&subroutine, $skip_test, $actual_results, $expected_results, $diagnostic, [@options]);
 $test_ok = $tech->skip_sub(\&subroutine, $skip_test, $actual_results, $expected_results, $diagnostic, $test_name, [@options]);

 $state  = $tech->skip_tests( );
 $state  = $tech->skip_tests( $on_off );

 $state = skip_tests( $on_off, $skip_diagnostic );

 $string = $tech->stringify($var, @options); # imported from Data::Secs2

 $new_value = $tech->tech_config($key, $old_value);

Generally, if a subroutine will process a list of options, C<@options>,
that subroutine will also process an array reference, C<\@options>, C<[@options]>,
or hash reference, C<\%options>, C<{@options}>.
If a subroutine will process an array reference, C<\@options>, C<[@options]>,
that subroutine will also process a hash reference, C<\%options>, C<{@options}>.
See the description for a subroutine for details and exceptions.


=head1 DESCRIPTION

The "Test::Tech" module extends the capabilities of the "Test" module.

The design is simple. 
The "Test::Tech" module loads the "Test" module without exporting
any "Test" subroutines into the "Test::Tech" namespace.
There is a "Test::Tech" cover subroutine with the same name
for each "Test" module subroutine.
Each "Test::Tech" cover subroutine will call the &Test::$subroutine
before or after it adds any additional capabilities.
The "Test::Tech" module procedural (subroutine) interface 
is a drop-in for the "Test" module.

The "Test::Tech" has a hybrid interface. The subroutine/methods that use
object data are the 'new', 'ok', 'skip', 'skip_tests', 'tech_config' and 'finish'
subroutines/methods.

When the module is loaded it creates a default object. If any of the
above subroutines/methods are used procedurally, without a class or
object, the subroutine/method will use the default method. 

The "Test::Tech" module extends the capabilities of
the "Test" module as follows:

=over 4

=item *

Compare almost any data structure by passing variables
through the L<Data::Secs2::stringify() subroutine|Data::Secs2/stringify subroutine>
before making the comparision

=item *

Method to skip the rest of the tests, with a $dianostic input,
upon a critical failure. 

=item *

Adds addition $name, [@option], {@option} inputs to the ok and skip subroutines.
The $name input is print as  "ok $test_num - $name" or "not ok $test_num - $name".

=item *

Method to generate demos that appear as an interactive
session using the methods under test

=back

=head2 demo

 demo($quoted_expression, @expression)

The demo subroutine/method provides a session like out.
The '$quoted_express' is printed out as typed in from
the keyboard.
The '@expression' is executed and printed out as the
results of '$quoted_expression'.

=head2 finish

 (@stats) = $tech->finish( );
 $num_passed = $tech->finish( );

The C<finish()> subroutine/method restores changes made
to the C<Test> module module made by the 
C<tech_config> subroutine/method or directly.

When the C<new> subroutine/method creates a C<Test::Tech>
object.
Perl will automatically run the
C<finish()> method when that object is destoried.

Running the 'finish' method without a class or object,
restores the 'Test' module to the values when
the 'Test::Tech' module was loaded.

When used in an array context
the C<finish()> subroutine/method 
returns the C<@stats> array.
The C<@stats> array consists of the following:

The C<finish()> subroutine resets the C<last_test> and
to zero and will returns undef without
performing any of the above. 
The C<finish()> subroutine will not be active again
until a new test run is start with  C<&Test::Tech::plan>
and the first test performed by C<&Test::Tech::ok> or
C<&Test::Tech::skip>.

In a scalar contents, the C<finish()> subroutine/method outputs
a 1 for sucess and 0 for failure.
In an array context,
the C<finish()> subroutine/method outputs C<@stats>
array that consists of the following:

=over 4

=item 0

number of tests

This is calculated as the maximum of the tests planned
and the highest test number. From the maximum, substract
the skipped tests. In other words, the sum of the missed,
passed and failed test steps.

=item 1

reference to the unplanned test steps

=item 2

reference to the missed test steps

=item 3

reference to the skipped test steps

=item 4

reference to the passed test steps

=item 5

reference to the failed test steps

=back

=head2 is_skip

 $skip_on = is_skip( );
 ($skip_on, $skip_diag) = is_skip( );

Returns the object data set by the C<set_tests> subroutine.

=head2 ok

 $test_ok = ok($actual_results, $expected_results, [@options]);
 $test_ok = ok($actual_results, $expected_results, {@options});
 $test_ok = ok($actual_results, $expected_results, $diagnostic, [@options]);
 $test_ok = ok($actual_results, $expected_results, $diagnostic, {@options});
 $test_ok = ok($actual_results, $expected_results, $diagnostic, $test_name, [@options]);
 $test_ok = ok($actual_results, $expected_results, $diagnostic, $test_name, {@options});

The $diagnostic, $test_name, [@options], and {@options} inputs are optional.
The $actual_results and $expected_results inputs may be references to
any type of data structures.  The @options is a hash input that will
process the 'diagnostic' key the same as the $diagnostic input and the
'name' key the same as the $test_name input.

The C<ok> method is a cover function for the &Test::ok subroutine
that extends the &Test::ok routine as follows:

=over 4

=item *

Prints out the C<$test_name> to provide an English identification
of the test. The $test_name appears as either "ok $test_num - $name" or
"not ok $test_num - $name".

=item *

The C<ok> subroutine passes referenced inputs
C<$actual_results> and C<$expectet_results> through 
L<Data::Secs2::stringify() subroutine|Data::Secs2/stringify subroutine>.
The C<ok> method then uses &Test::ok to compare the text results
from L<Data::Secs2::stringify() subroutine|Data::Secs2/stringify subroutine>.

=item *

The C<ok> subroutine method passes variables that are not a reference
directly to &Test::ok unchanged.

=item *

Responses to a flag set by the L<skip_tests subroutine|Test::Tech/skip_tests> subroutine
and skips the test completely.

=back

=head2 ok_sub

 $test_ok = ok_sub(\&subroutine, $actual_results, $expected_results, [@options]);
 $test_ok = ok_sub(\&subroutine, $actual_results, $expected_results, {@options});
 $test_ok = ok_sub(\&subroutine, $actual_results, $expected_results, $diagnostic, [@options]);
 $test_ok = ok_sub(\&subroutine, $actual_results, $expected_results, $diagnostic, {@options});
 $test_ok = ok_sub(\&subroutine, $actual_results, $expected_results, $diagnostic, $test_name, [@options]);
 $test_ok = ok_sub(\&subroutine, $actual_results, $expected_results, $diagnostic, $test_name, {@options});

The C<ok_sub> subroutine will execute the below:

 $sub_ok = &subroutine( $actual_results, $expected_results)

The C<ok_sub> subroutine will add additional information to
C<$diagnostic> and pass the C<$sub_ok> and other inputs 
along to C<ok> subroutine as follows:

 $test_ok = ok($sub_ok, 1, $diagnostic, $test_name, [@options]); 

=head2 plan

 $success = plan(@args);

The C<plan> subroutine is a cover method for &Test::plan.
The C<@args> are passed unchanged to &Test::plan.
All arguments are options. Valid options are as follows:

=over 4

=item tests

The number of tests. For example

 tests => 14,

=item todo

An array of test that will fail. For example

 todo => [3,4]

=item onfail

A subroutine that the C<Test> module will
execute on a failure. For example,

 onfail => sub { warn "CALL 911!" } 

=back

=head2 skip

 $test_ok = skip($skip_test, $actual_results,  $expected_results, [@options]);
 $test_ok = skip($skip_test, $actual_results,  $expected_results, {@options});
 $test_ok = skip($skip_test, $actual_results,  $expected_results, $diagnostic, [@options]);
 $test_ok = skip($skip_test, $actual_results,  $expected_results, $diagnostic, {@options});
 $test_ok = skip($skip_test, $actual_results,  $expected_results, $diagnostic, $test_name, [@options]);
 $test_ok = skip($skip_test, $actual_results,  $expected_results, $diagnostic, $test_name, {@options});

The $diagnostic, $test_name, [@options], and {@options} inputs are optional.
The $actual_results and $expected_results inputs may be references to
any type of data structures.  The @options is a hash input that will
process the 'diagnostic' key the same as the $diagnostic input and the
'name' key the same as the $test_name input.

The C<skip> subroutine is a cover function for the &Test::skip subroutine
that extends the &Test::skip the same as the 
L<ok subroutine|Test::Tech/ok> subroutine extends
the C<&Test::ok> subroutine.

=head2 ok_skip

 $test_ok = skip_sub(\&subroutine, $skip_test, $actual_results, $expected_results, [@options]);
 $test_ok = skip_sub(\&subroutine, $skip_test, $actual_results, $expected_results, {@options});
 $test_ok = skip_sub(\&subroutine, $skip_test, $actual_results, $expected_results, $diagnostic, [@options]);
 $test_ok = skip_sub(\&subroutine, $skip_test, $actual_results, $expected_results, $diagnostic, {@options});
 $test_ok = skip_sub(\&subroutine, $skip_test, $actual_results, $expected_results, $diagnostic, $test_name, [@options]);
 $test_ok = skip_sub(\&subroutine, $skip_test, $actual_results, $expected_results, $diagnostic, $test_name, {@options});

The C<skip_sub> subroutine will execute the below:

 $sub_ok = &subroutine( $actual_results, $expected_results)

The C<skip_sub> subroutine will add additional information to
C<$diagnostic> and pass the C<$sub_ok> and other inputs 
along to C<skip> subroutine as follows:

 $test_ok = skip($skip_test, $sub_ok, 1, $diagnostic, $test_name, [@options]); 

=head2 skip_tests

 $skip_on = skip_tests( $on_off );
 $skip_on = skip_tests( );

The C<skip_tests> subroutine sets a flag that causes the
C<ok> and the C<skip> methods to skip testing.

=head2 stringify subroutine

 $string = stringify( $var );
 $string = stringify($var, @options); 
 $string = stringify($var, [@options]);
 $string = stringify($var, {@options});


The C<stringify> subroutine will stringify C<$var> using
the "L<Data::Secs2::stringify subroutine|Data::Secs2/stringify subroutine>" 
module only if C<$var> is a reference;
otherwise, it leaves it unchanged.

=head2 tech_config

 $old_value = tech_config( $dot_index, $new_value );

The C<tech_config> subroutine reads and writes the
below configuration variables

 dot index              contents           mode
 --------------------   --------------     --------
 Test.ntest             $Test::ntest       read only 
 Test.TESTOUT           $Test::TESTOUT     read write
 Test.TestLevel         $Test::TestLevel   read write
 Test.ONFAIL            $Test::ONFAIL      read write
 Test.TESTERR           $Test::TESTERR     read write
 Skip_Tests             # boolean          read write
 
The C<tech_config> subroutine always returns the
C<$old_value> of C<$dot_index> and only writes
the contents if C<$new_value> is defined.

The 'SCALAR' and 'ARRAY' references are transparent.
The C<tech_config> subroutine, when it senses that
the C<$dot_index> is for a 'SCALAR' and 'ARRAY' reference,
will read or write the contents instead of the reference.

The The C<tech_config> subroutine will read 'HASH" references
but will never change them. 

The variables for the top level 'Dumper' C<$dot_index> are
established by "L<Data::Dumper|Data::Dumper>" module;
for the top level 'Test', the "L<Test|Test>" module.


=head1 REQUIREMENTS

Coming soon.

=head1 DEMONSTRATION

 #########
 # perl Tech.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::Spec;

     use File::Package;
     my $fp = 'File::Package';

     use Text::Scrub;
     my $s = 'Text::Scrub';

     use File::SmartNL;
     my $snl = 'File::SmartNL';

     my $uut = 'Test::Tech';
 $snl->fin('techA0.t')

 # '#!perl
 ##
 ##
 #use 5.001;
 #use strict;
 #use warnings;
 #use warnings::register;
 #use vars qw($VERSION $DATE);
 #$VERSION = '0.13';
 #$DATE = '2004/04/15';

 #BEGIN {
 #   use FindBin;
 #   use File::Spec;
 #   use Cwd;
 #   use vars qw( $__restore_dir__ );
 #   $__restore_dir__ = cwd();
 #   my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
 #   chdir $vol if $vol;
 #   chdir $dirs if $dirs;
 #   use lib $FindBin::Bin;

 #   # Add the directory with "Test.pm" version 1.15 to the front of @INC
 #   # Thus, 'use Test;' in  Test::Tech, will find Test.pm 1.15 first
 #   unshift @INC, File::Spec->catdir ( cwd(), 'V001015'); 

 #   # Create the test plan by supplying the number of tests
 #   # and the todo tests
 #   require Test::Tech;
 #   Test::Tech->import( qw(plan ok skip skip_tests tech_config finish) );
 #   plan(tests => 8, todo => [4, 8]);
 #}

 #END {
 #   # Restore working directory and @INC back to when enter script
 #   @INC = @lib::ORIG_INC;
 #   chdir $__restore_dir__;
 #}

 #my $x = 2;
 #my $y = 3;

 ##  ok:  1 - Using Test 1.15
 #ok( $Test::VERSION, '1.15', '', 'Test version');

 #skip_tests( 1 ) unless ok( #  ok:  2 - Do not skip rest
 #    $x + $y, # actual results
 #    5, # expected results
 #    '', 'Pass test'); 

 ##  ok:  3
 ##
 #skip( 1, # condition to skip test   
 #      ($x*$y*2), # actual results
 #      6, # expected results
 #      '','Skipped tests');

 ##  zyw feature Under development, i.e todo
 #ok( #  ok:  4
 #    $x*$y*2, # actual results
 #    6, # expected results
 #    '','Todo Test that Fails');

 #skip_tests(1) unless ok( #  ok:  5
 #    $x + $y, # actual results
 #    6, # expected results
 #    '','Failed test that skips the rest'); 

 #ok( #  ok:  6
 #    $x + $y + $x, # actual results
 #    9, # expected results
 #    '', 'A test to skip');

 #ok( #  ok:  7
 #    $x + $y + $x + $y, # actual results
 #    10, # expected results
 #    '', 'A not skip to skip');

 #skip_tests(0);
 #ok( #  ok:  8
 #    $x*$y*2, # actual results
 #         12, # expected results
 #         '', 'Stop skipping tests. Todo Test that Passes');

 #ok( #  ok:  9
 #    $x * $y, # actual results
 #    6, # expected results
 #    {name => 'Unplanned pass test'}); 

 #finish(); # pick up stats

 #__END__

 #=head1 COPYRIGHT

 #This test script is public domain.

 #=cut

 ### end of test script file ##

 #'
 #

 ##################
 # Run test script techA0.t using Test 1.15
 # 

     my $actual_results = `perl techA0.t`;
     $snl->fout('tech1.txt', $actual_results);

 ##################
 # Run test script techA0.t using Test 1.15
 # 

 $s->scrub_probe($s->scrub_file_line($actual_results))

 # '1..8 todo 4 8;
 #ok 1 - Test version 
 #ok 2 - Pass test 
 #ok 3 - Skipped tests  # skip
 #not ok 4 - Todo Test that Fails 
 ## Test 4 got: '12' (xxxx.t at line 000 *TODO*)
 ##   Expected: '6'
 #not ok 5 - Failed test that skips the rest 
 ## Test 5 got: '5' (xxxx.t at line 000)
 ##   Expected: '6'
 #ok 6 - A test to skip  # skip - Test not performed because of previous failure.
 #ok 7 - A not skip to skip  # skip - Test not performed because of previous failure.
 #ok 8 - Stop skipping tests. Todo Test that Passes  # (xxxx.t at line 000 TODO?!)
 #ok 9 - Unplanned pass test 
 ## Extra  : 9
 ## Skipped: 3 6 7
 ## Failed : 4 5
 ## Passed : 4/6 66%
 #'
 #
 $snl->fin('techC0.t')

 # '#!perl
 ##
 ##
 #use 5.001;
 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION $DATE);
 #$VERSION = '0.13';
 #$DATE = '2004/04/13';

 #BEGIN {
 #   use FindBin;
 #   use File::Spec;
 #   use Cwd;
 #   use vars qw( $__restore_dir__ );
 #   $__restore_dir__ = cwd();
 #   my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
 #   chdir $vol if $vol;
 #   chdir $dirs if $dirs;
 #   use lib $FindBin::Bin;

 #   # Add the directory with "Test.pm" version 1.24 to the front of @INC
 #   # Thus, load Test::Tech, will find Test.pm 1.24 first
 #   unshift @INC, File::Spec->catdir ( cwd(), 'V001024'); 

 #   # Create the test plan by supplying the number of tests
 #   # and the todo tests
 #   require Test::Tech;
 #   Test::Tech->import( qw(plan ok skip skip_tests tech_config finish) );
 #   plan(tests => 2, todo => [1]);

 #}

 #END {
 #   # Restore working directory and @INC back to when enter script
 #   @INC = @lib::ORIG_INC;
 #   chdir $__restore_dir__;
 #}

 ## 1.24 error goes to the STDERR
 ## while 1.15 goes to STDOUT
 ## redirect STDERR to the STDOUT
 #tech_config('Test.TESTERR', \*STDOUT);

 #my $x = 2;
 #my $y = 3;

 ##  xy feature Under development, i.e todo
 #ok( #  ok:  1
 #    [$x+$y,$y-$x], # actual results
 #    [5,1], # expected results
 #    '', 'Todo test that passes');

 #ok( #  ok:  2
 #    [$x+$y,$x*$y], # actual results
 #    [6,5], # expected results
 #    '', 'Test that fails');

 #finish() # pick up stats

 #__END__

 #=head1 COPYRIGHT

 #This test script is public domain.

 #=cut

 ### end of test script file ##

 #'
 #

 ##################
 # Run test script techC0.t using Test 1.24
 # 

     $actual_results = `perl techC0.t`;
     $snl->fout('tech1.txt', $actual_results);
 $s->scrub_probe($s->scrub_file_line($actual_results))

 # '1..2 todo 1;
 #ok 1 - Todo test that passes  # (xxxx.t at line 000 TODO?!)
 #not ok 2 - Test that fails 
 ## Test 2 got: 'U1[1] 80
 #N[2] 5 6
 #' (xxxx.t at line 000)
 ##   Expected: 'U1[1] 80
 #N[2] 6 5
 #'
 ## Failed : 2
 ## Passed : 1/2 50%
 #'
 #
 $snl->fin('techE0.t')

 # '#!perl
 ##
 ##
 #use 5.001;
 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION $DATE);
 #$VERSION = '0.08';
 #$DATE = '2004/04/13';

 #BEGIN {
 #   use FindBin;
 #   use File::Spec;
 #   use Cwd;
 #   use vars qw( $__restore_dir__ );
 #   $__restore_dir__ = cwd();
 #   my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
 #   chdir $vol if $vol;
 #   chdir $dirs if $dirs;
 #   use lib $FindBin::Bin;

 #   # Add the directory with "Test.pm" version 1.24 to the front of @INC
 #   # Thus, load Test::Tech, will find Test.pm 1.24 first
 #   unshift @INC, File::Spec->catdir ( cwd(), 'V001024'); 

 #   require Test::Tech;
 #   Test::Tech->import( qw(finish is_skip plan ok skip skip_tests tech_config ) );
 #   plan(tests => 10, todo => [4, 8]);
 #}

 #END {
 #   # Restore working directory and @INC back to when enter script
 #   @INC = @lib::ORIG_INC;
 #   chdir $__restore_dir__;
 #}

 ## 1.24 error goes to the STDERR
 ## while 1.15 goes to STDOUT
 ## redirect STDERR to the STDOUT
 #tech_config('Test.TESTERR', \*STDOUT);

 #my $x = 2;
 #my $y = 3;

 ##  ok:  1 - Using Test 1.24
 #ok( $Test::VERSION, '1.24', '', 'Test version');

 #skip_tests( 1 ) unless ok(   #  ok:  2 - Do not skip rest
 #    $x + $y, # actual results
 #    5, # expected results
 #    {name => 'Pass test'} ); 

 #skip( #  ok:  3
 #      1, # condition to skip test   
 #      ($x*$y*2), # actual results
 #      6, # expected results
 #      {name => 'Skipped tests'});

 ##  zyw feature Under development, i.e todo
 #ok( #  ok:  4
 #    $x*$y*2, # actual results
 #    6, # expected results
 #    [name => 'Todo Test that Fails',
 #    diagnostic => 'Should Fail']);

 #skip_tests(1,'Skip test on') unless ok(  #  ok:  5
 #    $x + $y, # actual results
 #    6, # expected results
 #    [diagnostic => 'Should Turn on Skip Test', 
 #     name => 'Failed test that skips the rest']); 

 #my ($skip_on, $skip_diag) = is_skip();

 #ok( #  ok:  6 
 #    $x + $y + $x, # actual results
 #    9, # expected results
 #    '', 'A test to skip');

 #ok( #  ok:  7 
 #    skip_tests(0), # actual results
 #    1, # expected results
 #    '', 'Turn off skip');

 #ok( #  ok:  8 
 #    [$skip_on, $skip_diag], # actual results
 #    [1,'Skip test on'], # expected results
 #    '', 'Skip flag');

 #finish() # pick up stats

 #__END__

 #=head1 COPYRIGHT

 #This test script is public domain.

 #=cut

 ### end of test script file ##

 #'
 #

 ##################
 # Run test script techE0.t using Test 1.24
 # 

     $actual_results = `perl techE0.t`;
     $snl->fout('tech1.txt', $actual_results);
 $s->scrub_probe($s->scrub_file_line($actual_results))

 # '1..10 todo 4 8;
 #ok 1 - Test version 
 #ok 2 - Pass test 
 #ok 3 - Skipped tests  # skip
 #not ok 4 - Todo Test that Fails 
 ## Test 4 got: '12' (xxxx.t at line 000 *TODO*)
 ##   Expected: '6' (Should Fail)
 #not ok 5 - Failed test that skips the rest 
 ## Test 5 got: '5' (xxxx.t at line 000)
 ##   Expected: '6' (Should Turn on Skip Test)
 #ok 6 - A test to skip  # skip - Skip test on
 #ok 7 - Turn off skip 
 #ok 8 - Skip flag  # (xxxx.t at line 000 TODO?!)
 #not ok 9 Not Performed # missing 
 ## Test 9 got: (Missing)
 ## Expected: (Missing)
 #not ok 10 Not Performed # missing 
 ## Test 10 got: (Missing)
 ## Expected: (Missing)
 ## Missing: 9 10
 ## Skipped: 3 6
 ## Failed : 4 5 9 10
 ## Passed : 4/8 50%
 #'
 #
 $snl->fin('techF0.t')

 # '#!perl
 ##
 ##
 #use 5.001;
 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION $DATE);
 #$VERSION = '0.08';
 #$DATE = '2004/04/13';

 #BEGIN {
 #   use FindBin;
 #   use File::Spec;
 #   use Cwd;
 #   use vars qw( $__restore_dir__ );
 #   $__restore_dir__ = cwd();
 #   my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
 #   chdir $vol if $vol;
 #   chdir $dirs if $dirs;
 #   use lib $FindBin::Bin;

 #   # Add the directory with "Test.pm" version 1.24 to the front of @INC
 #   # Thus, load Test::Tech, will find Test.pm 1.24 first
 #   unshift @INC, File::Spec->catdir ( cwd(), 'V001024'); 

 #   require Test::Tech;
 #   Test::Tech->import( qw(finish is_skip plan ok ok_sub
 #                          skip skip_sub skip_tests tech_config) );
 #   plan(tests => 7);
 #}

 #END {
 #   # Restore working directory and @INC back to when enter script
 #   @INC = @lib::ORIG_INC;
 #   chdir $__restore_dir__;
 #}

 ## 1.24 error goes to the STDERR
 ## while 1.15 goes to STDOUT
 ## redirect STDERR to the STDOUT
 #tech_config('Test.TESTERR', \*STDOUT);
 ##  ok:  1 - Using Test 1.24
 #ok( $Test::VERSION, '1.24', '', 'Test version');

 #ok_sub( #  ok:  2 
 #    \&tolerance, # critera subroutine
 #    99, # actual results
 #    [100,10], # expected results
 #    'tolerance(x)', 
 #    'ok tolerance subroutine');

 #ok_sub( #  ok:  3
 #    \&tolerance, # critera subroutine
 #    80, # actual results
 #    [100,10], # expected results
 #    'tolerance(x)', 
 #    'not ok tolerance subroutine');

 #skip_sub( #  ok:  3 
 #    \&tolerance, # critera subroutine
 #    0, # do no skip
 #    99, # actual results
 #    [100,10], # expected results
 #    'tolerance(x)', 
 #    'no skip - ok tolerance subroutine');

 #skip_sub( #  ok:  4
 #    \&tolerance, # critera subroutine
 #    0,  # do no skip
 #    80, # actual results
 #    [100,10], # expected results
 #    'tolerance(x)', 
 #    'no skip - not ok tolerance subroutine');

 #skip_sub( #  ok:  5
 #    \&tolerance, # critera subroutine
 #    1,  # skip
 #    80, # actual results
 #    [100,10], # expected results
 #    'tolerance(x)', 
 #    'skip tolerance subroutine');

 #finish(); # pick up stats

 #sub tolerance
 #{   my ($actual,$expected) = @_;
 #    my ($average, $tolerance) = @$expected;
 #    use integer;
 #    $actual = (($average - $actual) * 100) / $average;
 #    no integer;
 #    (-$tolerance < $actual) && ($actual < $tolerance) ? 1 : 0;
 #}

 #__END__

 #=head1 COPYRIGHT

 #This test script is public domain.

 #=cut

 ### end of test script file ##

 #'
 #

 ##################
 # Run test script techF0.t using Test 1.24
 # 

     $actual_results = `perl techF0.t`;
     $snl->fout('tech1.txt', $actual_results);
 $s->scrub_probe($s->scrub_file_line($actual_results))

 # '1..7
 #ok 1 - Test version 
 #ok 2 - ok tolerance subroutine 
 #not ok 3 - not ok tolerance subroutine 
 ## Test 3 got: '0' (xxxx.t at line 000)
 ##   Expected: '1' (tolerance(x)
 ## got: 80
 ## expected: U1[1] 80
 ## N[2] 100 10
 ## 
 ##)
 #ok 4 - no skip - ok tolerance subroutine 
 #not ok 5 - no skip - not ok tolerance subroutine 
 ## Test 5 got: '0' (xxxx.t at line 000)
 ##   Expected: '1' (tolerance(x)
 ## got: 80
 ## expected: U1[1] 80
 ## N[2] 100 10
 ## 
 ##)
 #ok 6 - skip tolerance subroutine  # skip
 #not ok 7 Not Performed # missing 
 ## Test 7 got: (Missing)
 ## Expected: (Missing)
 ## Missing: 7
 ## Skipped: 6
 ## Failed : 3 5 7
 ## Passed : 3/6 50%
 #'
 #

 ##################
 # config Test.ONFAIL, read undef
 # 

 my $tech = new Test::Tech
 $tech->tech_config('Test.ONFAIL')

 # undef
 #

 ##################
 # config Test.ONFAIL, read undef, write 0
 # 

 $tech->tech_config('Test.ONFAIL',0)

 # undef
 #

 ##################
 # config Test.ONFAIL, read 0
 # 

 $tech->tech_config('Test.ONFAIL')

 # 0
 #

 ##################
 # 0, read 0
 # 

 $Test::ONFAIL

 # 0
 #

 ##################
 # restore Test.ONFAIL on finish
 # 

      $tech->finish( );
      $Test::planned = 1;  # keep going

 ##################
 # Test.ONFAIL restored by finish()
 # 

 $tech->tech_config('Test.ONFAIL')

 # 0
 #
 unlink 'tech1.txt'
 unlink 'tech1.txt'

=head1 QUALITY ASSURANCE

Running the test script C<Tech.t> verifies
the requirements for this module.
The C<tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<Tech.t> test script, C<Tech.d> demo script,
and C<t::File::Drawing> STD program module POD,
from the C<t::File::Tech::Tech> program module contents.
The C<tmake.pl> cover script automatically ran the
C<Tech.d> demo script and inserted the results
into the 'DEMONSTRATION' section above.
The  C<t::Test::Tech::Tech> program module
is in the distribution file
F<File-Drawing-$VERSION.tar.gz>.

=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright Notice 

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 Binding Requirement Notice

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<US DOD 490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 License

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=item 3

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.

=back

SOFTWARE DIAMONDS, http://www.softwarediamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE. 

=head1 SEE ALSO 

=over 4

=item L<Test|Test> 

=item L<Test::Harness|Test::Harness> 

=item L<Data::Secs2|Data::Secs2>

=item L<Data::SecsPack|Data::SecsPack>

=back

=cut


### end of file ###