#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  Test::STDmaker;

use 5.001;
use strict;
use warnings;
use warnings::register;

use File::Spec;
use Cwd;
use File::AnySpec;
use File::Where;

use vars qw($VERSION $DATE);
$VERSION = '1.21';
$DATE = '2004/05/24';

use vars qw(@ISA @EXPORT_OK);
@ISA = qw();

use Exporter;
use File::Maker 0.03;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(File::Maker Exporter);  # inherit the new and make_targets methods
@EXPORT_OK = qw(find_t_roots get_date perl_command);

my %targets = (
    all => [ 'check_db' ],
    Check => [ 'check_db' ],
    __no_target__ => [ qw(target_error) ],
);


######
# This is the main interface with the Test Database drivers
#
sub build
{
     my ($self, $output_type) = @_;
     my $generator = "Test::STDmaker::$output_type";
     $self = bless $self,$generator; # change the class
     $self = $self->generate();
     return undef unless ref($self);
     return undef unless $self->print(); 
     $self;    
}


######
# Bring the data in from an input file
#
sub check_db
{
     my ($self) = @_;

     my $std_pm = $self->{FormDB_PM};
     unless( $std_pm ) {
        warn "No file specified\n";
        return undef;
     } 
     return 1 if $self->{std_pm} && $self->{std_pm} eq $std_pm;  # $file_in all cleaned

     $self->{std_db} = '';
     $self->{std_pm} = $std_pm;
     $self->{Date} = '';
     $self->{file} = '';
     $self->{vol} = '';
     $self->{dir} = '';
    
     #########
     # Record file load stats in the object database
     #
     $self->{std_db} = $self->{FormDB};
     $self->{Date} = get_date( );
     $self->{Record} = $self->{FormDB_Record};
     $self->{std_file} = $self->{FormDB_File};
     ($self->{vol}, $self->{dir}, $self->{file}) = File::Spec->splitpath( $self->{FormDB_File});

     #######
     # Clean up and standardize the file database.
     #
     $self->{Temp} = 'temp.pl' unless $self->{'Temp'};
     $self->{'Test::STDmaker::Check'}->{file_out} = $self->{'Temp'};
     $self = ($self->build('Check'));
     $self;
}

####
# Find test roots
#
sub find_t_roots
{
   ######
   # This subroutine uses no object data; therefore,
   # drop any class or object.
   #
   shift if UNIVERSAL::isa($_[0],__PACKAGE__);

   #######
   # Add t directories to the search path
   #
   my ($t_dir,@dirs,$vol);
   my %t_root=();
   my @t_root = ();
   my @t;
   foreach my $dir (@INC) {
       ($vol,$t_dir) = File::Spec->splitpath( $dir, 'nofile' );
       @dirs = File::Spec->splitdir($t_dir);
       @t = ();
       for (@dirs) {
           if($_ eq 't') {
               $t_dir = File::Spec->catdir( @t);
               @t_root = (File::Spec->catpath( $vol, $t_dir, ''));
               return @t_root;
           }
           push @t,$_;
       } 
       pop @dirs;
       $t_dir = File::Spec->catdir( @dirs);
       $t_dir = File::Spec->catpath( $vol, $t_dir, '');
       next unless $t_dir;
       next if $t_root{$t_dir}; # eliminate dups
       $t_root{$t_dir} = 1;
       push @t_root, $t_dir;
   }
   @t_root
}



sub generate
{
    my ($self) = @_;

    my $data_out;

    my $restore_dir = cwd();
    chdir $self->{vol} if $self->{vol};
    chdir $self->{dir} if $self->{dir};

    ########
    #  Start generating the output file
    #
    #  Start is a method supplied by the
    #  class that inherits this base file
    #  generation class
    #
    my $success = 1;
    if ($self->can( 'start' )) {
        $data_out = $self->start();
    }
    else {
        $success = 0;
        $data_out .= "***ERROR*** No start method available.";
    }    

    my ($command, $data, $result);
    my $type = ref($self);
    my $std_db = $self->{std_db};
    unless ($std_db) {
        $data_out .= "No std_db to process\n";
        return 0;       
    }
    for (my $i=0; $i < @$std_db; $i +=2) {
      
        ($command,$data) = ($std_db->[$i],$std_db->[$i+1]);
        $result = $self->$command( $command, $data );
        if( defined( $result ) ) {
            $data_out .= $result; 
        }
        else {
            $success = 0;
            $data_out .= "***ERROR*** No $type->$command method available.";
        }   
    }

    ########
    #  Finish generating the output file
    #
    #  Start is a method supplied by the
    #  class that inherits this base file
    #  generation class
    #
    #
    if ($self->can( 'finish' )) {
        $data_out .= $self->finish();
    }
    else {
        $success = 0;
        $data_out .= "***ERROR*** No finish method available.";
    }    

    chdir $restore_dir;

    ########
    # Determine the class of the object that
    # inherited these methods
    #
    $self->{$type}->{data_out} = \$data_out;
    $self;

}


######
# Date with year first
#
sub get_date
{
   my @d = localtime();
   @d = @d[5,4,3];
   $d[0] += 1900;
   $d[1] += 1;
   sprintf( "%04d/%02d/%02d", @d[0,1,2]);

}


#######
# When running under some new improved CPAN on some tester setups,
# the `perl $command` crashes and burns with the following
# 
# Perl lib version (v5.8.4) doesn't match executable version (v5.6.1)
# at /usr/local/perl-5.8.4/lib/5.8.4/sparc-linux/Config.pm line 32.
#
# To prevent this, use the return from the below instead of perl
#
sub perl_command {
    my $OS = $^O; 
    unless ($OS) {   # on some perls $^O is not defined
	require Config;
	$OS = $Config::Config{'osname'};
    }
    return "MCR $^X"                    if $OS eq 'VMS';
    return Win32::GetShortPathName($^X) if $OS =~ /^(MS)?Win32$/;
    $^X;
}

######
# Print the output data
#
sub print
{
    my ($self, $file_out) = @_;

    my $success = 1;

    ########
    # Determine the type of the object that
    # inherited these methods
    #
    my $type = ref($self);
 
    #######
    # Determine the output data
    #
    my $data_out_p = $self->{$type}->{data_out};
    return 1 unless ref($data_out_p) eq 'SCALAR'; # only print scalars
    
    #######
    # Determine the output file
    #
    unless ($file_out) {

        unless( $file_out = $self->{$type}->{file_out} ) {
            warn "No output file specified\n";
            return undef;
        }

        #####
        # Does not work without parens around $file_out
        #
        ($file_out) = File::AnySpec->fspec2os( $self->{File_Spec}, $file_out );
    }

    ######
    # Finally print the output files, store absolute file name of output
    # in $self 
    #
    my $restore_dir = cwd();
    chdir $self->{vol} if $self->{vol};
    chdir $self->{dir} if $self->{dir};
    File::SmartNL->fout( $file_out, $$data_out_p ) if $file_out && $data_out_p && $$data_out_p;
    $self->{$type}->{generated_files} = [] unless $self->{$type}->{generated_files};
    push  @{$self->{$type}->{generated_files}},File::Spec->rel2abs($file_out);
    $self->{$type}->{data_out} = undef;  # do not want to send 2nd time

    $success = $self->post_print( ) if $self->can( 'post_print');

    ###########
    # Sometimes have untentional unlinks
    # 
    unless( $success && !$self->{options}->{nounlink}) {
        File::SmartNL->fout( $file_out, $$data_out_p ) if $file_out && $data_out_p && $$data_out_p;
    }

    chdir $restore_dir;

    $success;

}

sub target_error
{
     my $self = shift @_;
     warn "Bad target $self->{target}\n";
}


######
# Write out files
#
sub tmake
{
     my ($self, @targets) = @_;

     $self->{options} = pop @targets if ref($targets[-1]) eq 'HASH';

     my $restore_class = ref($self);
     my $options = $self->{options};

     print( "SoftwareDiamonds.com - Harnessing the power of automation.\n\n" ) if $options->{verbose};

     ########
     # Load output generators
     #
     my @generators = File::Where->program_modules( __FILE__, 'file', 'STDmaker');
     my ($error);
     my @output_generators = ();
     foreach (@generators) {
          $error = File::Package->load_package( "Test::STDmaker::$_" );
          if( $error ) {
             warn "\t$error\n";
             next;
          }
          next if $_ eq 'Check';
          $targets{$_} = ['check_db', ['build', $_ ] ];
          push @{$targets{all}},['build', $_ ];
          push @output_generators,$_ ; 
     }
     $self->{generators} = \@output_generators;
     @targets = @output_generators if 0 == @targets || (join ' ',@targets) =~ /all/;

     ##########
     # Santize targets, Need only partial match of generator
     #     
     my $generator;
     for (@targets) {
         next if ref($_);
         $generator = File::Where->is_module($_, @output_generators);
         $_ = $generator if $generator;     
     }

     ########
     # Default FormDB program module is "STD"
     #
     my @t_inc = find_t_roots( );
     $self->{Load_INC} = \@t_inc ;

     ######
     # If have not picked up a pm and there are no test scripts
     #
     $options->{pm} = 't::STD' unless $options->{pm} || $options->{test_scripts};
     my $success = $self->make_targets( \%targets, @targets);

     ######
     # Add test script to the Verify generated files that
     # will be ran using the test harness. 
     #
     if( $self->{options}->{run} && $options->{test_scripts} ) {
         my @restore_inc = @INC;
         unshift @INC, @t_inc;
         my $test_fspec = $options->{test_fspec};
         $test_fspec = 'Unix' unless $test_fspec;
         my @test_scripts = split /(?: |,|;|\n)+/, $options->{test_scripts};
         my $test_script;
         foreach $test_script (@test_scripts) {
             $test_script = File::AnySpec->fspec2os( $test_fspec, $test_script);
             unshift   @{$self->{'Test::STDmaker::Verify'}->{generated_files}} ,File::Where->where( $test_script );
         } 
         @INC = @restore_inc; 
     }

     ########
     # Post process any generated files
     #
     if( $success ) {
         my $target;
         foreach $target (@targets) {
             $self = bless $self, "Test::STDmaker::$target";
             $self->post_generate( ) if $self->can( 'post_generate');
         }
     }

     print( "****\nFinish Processing\n****\n" ) if $options->{verbose};

     $self = bless($self, $restore_class);

     return $success;
}


1;

__END__


=head1 NAME

Test::STDmaker - generate test scripts, demo scripts from a test description short hand

=head1 SYNOPSIS

 #######
 # Procedural (subroutine) interface
 # 
 use Test::STDmake qw(find_t_roots get_data perl_command);

 @t_path = find_t_paths()
 $date = get_date();
 $myperl = perl_command();

 #####
 # Class interface
 #
 use Test::STDmaker

 $std = new Test::STDmaker( @options ); # From File::Maker

 $success = $std->check_db($std_pm);
 @t_path = $std->find_t_paths()
 $date = $std->get_date();
 $myperl = $std->perl_command();

 $std->tmake( @targets, \%options ); 
 $std->tmake( @targets ); 
 $std->tmake( \%options  );

 ######
 # Internal (Private) Methods
 #
 $success = $std->build($std_driver_class);
 $success = $std->generate();
 $success = $std->print($file_out);


=head1 DESCRIPTION

The C<Test::STDmaker> program module provides the following capabilities:

=over 4

=item 1

Automate Perl related programming needed to create a
test script resulting in reduction of time and cost.

=item 2

Translate a short hand Software Test Description (STD)
file into a Perl test script that eventually makes use of 
the L<Test|Test> module.

=item 3

Translate the sort hand STD data file into a Perl demo
script that demonstrates the features of the 
the module under test.

=item 4

Provide in the POD of a STD file information required by
a Military/Federal Government 
Software Test Description (L<STD>) document
that may easily be index and accessed by
automated Test software. 
ISO, British Military require most of the same
information, US agencies such as the FAA. 
The difference is that ISO,
British Military do not dictate 
detail format. 
US agencies such as FAA will generally
tailor down the DOD required formats.
Thus, there is an extremely wide variation
in the format of the same information among
ISO certified comericial activities and 
militaries other than US.
Once the information is in a POD, different
translators may format nearly
exactly as dictated by the end user, whether
it is the US DOD, ISO certified commericial activity,
British Military or whoever.
By being able to provide the most demanding,
which is usually US DOD, 
the capabilities are there for all the others.

=back

The C<Test::STDmaker> package relieves the designer
and developer from the burden of filling
out word processor boiler plate templates
(whether run-off, Word, or vi), 
counting oks, providing
documentation examples, tracing tests to
test requirments, making sure it is in the
proper corporate, ISO or military format,
and other such extremely time
consuming, boring, development support tasks.
Instead the designers and developers need
only to fill in a form using a test description short hand.
The C<Test::STDmaker> will take it from there
and automatically and quickly generate
the desired test scripts, demo scripts,
and test description documents.

Look at the economics.
It does not make economically sense to have expensive talent
do this work.
In does not even make economically sense to take a bright
16 year, at mimimum wage and have him manually count oks.
Perl can count those oks much much cheaper
and it is so easily to automated with Perl.
And something like this were you are doing it year in and
year out, the saving are enormous.
To a program manager or contract officer, 
this is what programming and computers are all about,
saving money and increasing productivity, not object oriented
oriented programing, gotos or other such things.

The C<Test::STDmaker> class package automates the
generation of Software Test Descriptions (STD)
Plain Old Documentation (POD), test scripts,
demonstrations scripts and the execution of the
generated test scripts and demonstration scripts.
It will automatically insert the output from the
demonstration script into the POD I<-headx Demonstration>
section of the file being tested.

The inputs for C<Test::STDmaker> class package is the C<__DATA__>
section of Software Test Description (STD)
program module and a list of targets.
The __DATA__ section must contain a STD
forms text database in the
L<Tie::Form|Tie::Form> format.
Most of the targets are the ouputs. 
Each output has its own program module in the
C<Test::STDmaker::> repository.
The targets are the name of a program
module that process the form database
as follows:

 target output program module   description
 -------------------------------------------------------
 Check  Test::STDmaker::Check   cleans database, counts oks
 Demo   Test::STDmaker::Demo    generates demo script
 STD    Test::STDmaker::STD     generates STD POD
 Verify Test::STDmaker::Verify  generates test script

The interface between the C<Test::STDmaker> package
each of the driver packages in the C<Test::STDmaker::>
repository is the
same. New driver packages may be added by putting them
in the C<Test::STDmaker::> repository without
modifying the C<Test::STDmaker> package.
The C<Test::STDmaker> package will find it and add
it to is target list.

The STD program modules that contain the forms database
should reside in a C<'t'> subtree whose root
is the same as the C<'lib'> subtree.
For the host site development and debug, 
the C<lib> directory is most convenient for test program modules.
However, when building the distribution
file for installation on a target site, test library program
modules should be placed at the same level as the test script.

For example, while debugging and development the directory
structure may look as follows:

 development_dir   
   lib
     MyTopLevel
       MyUnitUnderTest.pm  # code program module
     Data::xxxx.pm  # test library program modules

     File::xxxx.pm  # test library program modules
   t
     MyTopLevel
       MyUnitUnderTest.pm  # STD program module

 # @INC contains the absolute path for development_dir

while a target site distribution directory for
the C<MyUnitUnderTest> would be as follows:

 devlopment_dir 
   release_dir
     MyUnitUnderTest_dir
       lib
         MyTopLevel
           MyUnitUnderTest.pm  # code program module
       t
         MyTopLevel
           MyUnitUnderTest.pm  # STD program module

           Data::xxxx.pm  # test library program modules

           File::xxxx.pm  # test library program modules

 # @INC contains the absolute path for MyUnitUnderTest_dir 
 # and does not contain the absolute path for devlopment_dir

When C<Test::STDmaker> methods searches for a STD PM,
it looks for it first under all the directories in @INC
This means the STD program module name must start with C<"t::">.
Thus the program module name for the Unit Under
Test (UUT), C<MyTopLevel::MyUnitUNderTest>,
and the UUT STD program module, C<t::MyTopLevel::MyUnitUNderTest>,
are always different.

Use the C<tmake.pl> (test make), found in the distribution file,
cover script for  L<Test::STDmaker|Test::STDmaker> to process a STD database
module to generate a test script for debug and development as follows:

 tmake -verbose -nounlink -pm=t::MyTopLevel::MyUnitUnderTest

The C<tmake> script creates a C<$std> object and runs the C<tmake> method

 my $std = new Test::STDmaker(\%options);
 $std->tmake(@ARGV);

which replaces the POD in C<t::MyTopLevel::MyUnitUNderTest> STD program
module and creates the following files

 development_dir
   t
     MyTopLevel
       MyUnitUNderTest.t  # test script
       MyUnitUNderTest.d  # demo script
       temp.pl            # calculates test steps and so forth

The names for these three files are determined by fields
in the C<__DATA__> section of the C<t::MyTopLevel::MyUnitUNderTest> 
STD program module. All geneated scripts will contain Perl
code to change the working directory to the same directory
as the test script and add this directory to C<@INC> so
the Perl can find any test library program modules placed
in the same directory as the test script.

The first step is to debug temp.pl in the C<development_dir>

 perl -d temp.pl

Make any correction to the STD program module 
C<t::MyTopLevel::MyUnitUNderTest> not to C<temp.pl>
and repeat the above steps.
After debugging C<temp.pl>, use the same procedure to
debug C<MyUnitUnderTest.t>, C<MyUnitUnderTest.d>

  perl -d MyUnitUnderTest.t
  perl -d MyUnitUnderTest.d

Again make any correction to the STD program module 
C<t::MyTopLevel::MyUnitUNderTest> not to C<MyUnitUnderTest.t>
C<MyUnitUnderTest.d>

Once this is accomplished, develop and debug the UUT using
the test script as follows:

 perl -d MyUnitUnderTest.t

Finally, when the C<MyTopLevel::MyUnitUNderTest> is working
replace the C<=head1 DEMONSTRATION> in the C<MyTopLevel::MyUnitUNderTest>
with the output from C<MyUnitUnderTest.d> and run the 
C<MyUnitUnderTest.t> under C<Test::Harness> with the following:

 tmake -verbose -test_verbose -demo -report -run -pm=t::MyTopLevel::MyUnitUnderTest

Since there is no C<-unlink> option, C<tmake>
removes the C<temp.pl> file.

Keep the C<t> subtree under the C<development library> for regression testing of
the development library.

Use L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> to automatically build a release
directory from the development directory,
run the test script using only the files in the release directory,
bump revisions for files that changed since the
last distribution,
and package the UUT program module, test script and
test library program modules and other
files for distrubtion.

=head1 STD Program Module

The input(s) for the C<Test::STDmaker> package
are Softare Test Description Program Modules (STM PM).

A STD PM consists of three sections as follows:

=over 4

=item Perl Code Section

The code section contains the following
Perl scalars: $VERSION, $DATE, and $FILE.
STDmaker automatically generates this section.

=item STD POD Section

The STD POD section is either a tailored Detail STD format
or a tailored STD2167 format described below.
STDmaker automatically generates this section.

=item STD Form Database Section

This section contains a STD Form Database that
STDmaker uses (only when directed by specifying
STD as the output option) to generate the
Perl code section and the STD POD section.

=back

=head2 POD Section

The POD sectin contains the detail STD for the
program module under test.
L<US DOD 490A 3.1.2|Docs::US_DOD::490A/3.1.2 Coverage of specifications.>
allows for general/detail separation of requirement for a group
of configuration items with a set of common requirements.
Perl program modules qualify as such.
This avoids repetition of common requirements
in detail specifications.
The detail specification and the referenced general specification
then constitute the total requirements.

=head2 Form Database Section 

The C<Test::STDmaker> module uses the
L<Tie::Form|Tie::Form>
lenient format to access the data in the Data Section.

The requirements of 
L<Tie::Form|Tie::Form>
lenient format govern in case of a conflict with the description
herein.

In accordance with 
L<Tie::Form|Tie::Form>,
STD PM data consists of series
of I<field name> and I<field data> pairs.

The L<Tie::Form|Tie::Form>
format separator strings are as follows:

 End of Field Name:  [^:]:[^:]
 ENd of Field Data:  [^\^]\^[^\^]
 End of Record    :  ~-~

In other words, the separator strings 
have a string format of the following:

 (not_the_char) . (char) . (not_the_char)

The following are valid I<FormDB> fields:

 name: data^

 name:
 data
  ..
 data
 ^

Separator strings are escaped by added
an extra chacater.
For example,

=over 4

=item  DIR:::Module: $data ^

  unescaped field name:  DIR::MOdule

=item  DIR::Module:: : $data ^

  unescaped field name: DIR:Module:

Since the field name ends in a colon
the format requires a space
between the field name and 
the I<end of field name colon>.
Since the I<FormDB> format ignores
leading and trailing white space
for field names, this space is
not part of the field name.
space.

=back

This is customary form that 
all of us have been forced to fill out
through out our lives with the addition
of ending field punctuation.
Since the separator sequences
are never part of the field name and data,
the code
to read it is trivial.
For being computer friendly it is
hard to beat. 
And, altough most of us are adverse to
forms, it makes good try of being
people friendly.

An example of a STD Form follows:

 File_Spec: Unix^
 UUT: Test::STDmaker::tg1^
 Revision: -^
 End_User: General Public^
 Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
 STD2167_Template: ^
 Detail_Template: ^
 Classification: None^
 Demo: TestGen1.d^
 Verify: TestGen1.t^

  T: 0^

  C: use Test::t::TestGen1^

  R: L<Test::t::TestGen1/Description> [1]^

  C: 
     my $x = 2
     my $y = 3
 ^

  A: $x + $y^
 SE: 5^

  N: Two Additions 
  A: ($x+$y,$y-$x)^
  E: (5,1)^

  N: Two Requirements^

  R: 
     L<Test::t::TestGen1/Description> [2]
     L<Test::t::TestGen1/Description> [3]
  ^

  A: ($x+4,$x*$y)^
  E: (6,5)^

  U:  Test under development ^ 
  S: 1^
  A: $x*$y*2^
  E: 6^

  S: 0^
  A: $x*$y*2^
  E: 6^

 See_Also: http://perl.SoftwareDiamonds.com^
 Copyright: copyright © 2003 Software Diamonds.^

This is a very compact database form. The actual
test code is Perl snippets that will
be passed to the appropriate build-in,
behind the scenes Perl subroutines.

=head1 STD PM Form Database Fields

The following database file fields are information
needed to generate the documentation files
and not information about the tests themselves:

=head2 Author field

The I<prepare for> STD title page
entry.

=head2 Classification field

Security classification.

=head2 Copyright field

Any copyright and license requirements.
This is integrated into the Demo Script, Test Script
and the STD module.

=head2 Detail_Template field

This field contains a template program module
that the C<Test::STDmaker> package method uses to generate
the STD POD section of the STD PM.
Normally this field is left blank and
the C<Test::STDmaker> package methods uses its
built-in detail template.

The C<Test::STDmaker> package methods merges the
following variables with the template
in generating the C<STD> file:

Date UUT_PM Revision End_User Author Classification 
Test_Script SVD Tests STD_PM Test_Descriptions See_Also
Trace_Requirement_Table Trace_Test_Table Copyright

=head2 Demo field

The file for the L<C<Demo output>|Test::STDmaker/Demo output>
relative to the STD PM directory.

=head2  End_User field

The I<prepare for> STD title page
entry.

=head2 File_Spec field

the operating system file specification
used for the following fields:

 Verify Demo

Valid values are Unix MacOS MSWin32 os2 VMS epoc.
The scope of this value is very limited.
It does not apply to any file specification
used in the test steps nor the files used
for input to the C<Test::STDmaker> package method.

=head2  Revision field

Enter the revision for the STD POD.
Revision numbers, in accordance
with standard engineering drawing
practices are letters A .. B AA .. ZZ
except for the orginal revision which
is -.

=head2 STD2167_Template field

Similar to the Detail_Template field except that
the template is a tailored STD2167 template.

=head2 See_Also field

This section provides links to other resources.

=head2 Test Description Fields

The Test Description Fields are described in the next section.

=head2 UUT field

The Unit Under Test (UUT).

=head2 Verify field

The file for the L<C<Verify output>|Test::STDmaker/Verify output>
relative to the STD PM directory.


=head1 STD PM Form Database Test Description Fields

The test description fields are 
order sensitive 
data as follows: 

=head2 A

 A: actual-expression 

This is the actual Perl expression under test and used for
the L<STD 4.x.y.3 Test inputs.|Docs::US_DOD::STD/4.x.y.3 Test inputs.> 

=head2 E

 E: expected-expression 

This is the expected results. This should be raw Perl
values and used for the 
<STD 4.x.y.4 Expected test results.|Docs::US_DOD::STD/4.x.y.4 Expected test results.>

This field triggers processing of the previous fields as a test.
It must always be the last field of a test.
On failure, testing continues.

=head2 C

  C: code

The C<code> field data is free form Perl code.
This field is generally used for 
L<STD 4.x.y.2 Prerequisite conditions.|Docs::US_DOD::STD/4.x.y.2 Prerequisite conditions.> 

=head2 DO

 DO: comment

This field tags all the fields up to the next
L<C<A: actual-expression>|Test::STDmaker/A: actual-expression>
for use only in generating a 
L<Demo output|Test::STDmaker/Demo output>

=head2 DM

 DM: msg

This field assigns a diagnostic message
to the test step. The test software prints
out this message  on test failure.

=head2 N

 N: name_data

This field provides a name for the test.
This is usually the same name as
the base name for the STD file. 

=head2 ok

 ok: test_number

The C<ok: test_number> is a the test number that 
results from the execution of C<&TEST::ok>
by the previous C<E: data> or C<SE: data> expression.
A STD file does not require any C<ok:> fields since
The C<Test::STDmaker> package methods will automatically 
generate the C<ok: test_number> fields.

=head2 QC

 QC: code

This field is the same as a C<C: code> field except that
for the demo script.
The demo script will exectue the code,
but will not print it out.

=head2 R

 R: requirement_data

The I<requirement_data> cites a binding requirement
that is verified by the test.
The test software uses the I<requirement_data> to automatically generate
tracebility information that conforms to
L<STD 4.x.y.1 Requirements addressed.|STD/Docs::US_DOD::4.x.y.1 Requirements addressed.> 

Many times the relationship between binding requirements and
the a test is vague and can even stretch the imagination.
Perhaps by tracing the binding requirement down to an actual
test number,
will help force requirements that have clean cut
tests in qualitative terms that can verify and/or validate
a requirement.

=head2 S

 S: expression

The mode C<S: expression> provides means to
conditionally preform a test. 
The condition is usually platform dependent.
In other words, a feature may be provided, say
for a VMS platform that is not available on a
Microsoft platform.

=head2 SF

 SF: value,msg

This field assigns a value to the skip flag and optional message
to the skip flag.
A zero turns it off;
otherwise, it is turned on.
The test software prints out the msg for each file skipped. 

=head2 SE

 SE: expected-expression

This field is the same as L<E: expected-expression|/E>
except that testing stops on failure. The test software implements
the stop by turning on the skip flag. When the skip flag is on,
every test will be skip.

=head2 T

 T: number_of_tests - todo tests

This field provides the number of tests
and the number of the todo tests.
The C<Test::STDmaker> package methods
will automatically fill in this field.

=head2 TS

 TS: \&subroutine

This field provides a subroutine used to
determine if an actual result is within
expected parameters with the following
synopsis:

 $success = &subroutine($acutal_result,$expected_paramters)

=head2 U

 U: comment

This tags a test as testing a feature or capability
under development. The test is added to the I<todo>
list.

=head2 VO

 VO: comment

This field tags all the fields up to the next
L<C<E: expected-expression>|Test::STDmaker/E: expected-expression>
for use only in generating a 
L<Verify output|Test::STDmaker/Verify output>

=head1 METHODS

The C<STDmaker> class inherits the all the methods from
the L<File::Maker|File::Maker> class.
The additional C<STDmaker> methods are follows.

=head2 check_std

 $success = $std->load_std($std_pm);

The C<load_std> loads a STD database in the L<Tie::Form|Tie::Form>
format from the C<__DATA__> section of C<$std_pm>.
The subroutine adds the following to the object hash, C<$std>:

 hash
 key     description 
 ----------------------------------------------------------
 std_db  ordered name,data pairs from the $std_pm database
 Record  complete $std_pm database record
 std_pm  $std_pm;
 Date    date using $std->get_date()
 file    base file of $std_pm
 vol     volume of $std_pm
 dir     directory of $std_pm

It changes the class of object C<$std> to C<Test::STDmaker::Check>,
keeping the same data hash as the incoming object.
Since the class is now C<Test::STD:Check> and this class inherits
methods from C<Test::STDmaker> and the methods of both classes are
now visible.

The C<$std> then executes the incoming object data using
first the C<generate> method and then the C<print> method
herein which in turn use the methods from the C<Test::STDmaker::Check>
class.

=head2 find_t_roots

 @t_path = find_t_paths()

The C<find_t_roots> subroutine operates on the assumption that the 
test files are a subtree to
a directory named I<t> and the I<t> directories are on the same level as
the last directory of each directory tree specified in I<@INC>.
If this assumption is not true, this method most likely will not behave
very well.

=head2 get_date

 $date = $std->get_date();

The C<get_date> subroutine returns the C<$date> in
the yyyy/mm/dd format.

=head2 tmake

 $std->tmake( @targets, \%options ); 
 $std->tmake( @targets ); 
 $std->tmake( \%options  );

The C<tmake> method reads the data 
from the form database (FormDB) section of a
Software Test Description program module (STD PM), 
clean it, and use the cleaned
data to generate the output file(s)
based on the targets as follows:

 target    description 
 ----------------------------------------
 all       generates all outputs
 Demo      generates demo script
 Verify    generates a test script
 STD       generates and replaces the STD PM POD
 Check     checks test description database

No target is the same as the C<all> target.

The C<@options> are as follows:

=over 4

=item demo option

 demo => 1

run the all demo scripts and use thier output to replace the
Unit Under Test (UUT)  =headx Demonstration POD section.
The STD PM UUT field specifies the UUT file.

=item nosemi

Do not automatically add ';' at
the end of the C<C>, code, test description short hand field.

=item nounlink

 nounlink => 1

do not delete the check test script (typically C<temp.pl>)

=item pm

 pm => $program_module

The STD PM is a Perl program module specified using
the Perl '::' notation. 
The module must be in one of the directories in the
@INC array.
For example, the STD PM for this program module is

 pm => t::Test::STDmaker::STDmaker

If there is no pm option, the C<tmake> subroutine uses C<t::STD>

=item report option

 report => 1

run the all test scripts and use thier output to replace the
Unit Under Test (UUT)  =headx Test Report POD section.
The STD PM  UUT field specifies the UUT file.

=item  run option

 run => 1

run all generated test scripts using the L<Test::Harness|Test::Harness>

=item test_verbose option

 test_verbose => 1           

use verbose mode when using the L<Test::Harness|Test::Harness>

=item verbose option

 verbose => 1           

print out informative messages about processing steps and such

=back

=head1 INTERNAL METHODS

The methods in this section are methods internal to
the C<Test::STDmaker>. 
The are more of design in nature and not
part of the functional interface for the package.
Typically they will never be used outside of
the C<Test::STDmaker>. 
They do provide some insight on the form data processing
and the exchange between the c<Test::STDmaker> package
and the driver packages in the C<Test::STDmaker::> repository.

=head2 build

 $success = $std->build($std_driver_class);

The C<$output_type> is the name of a driver in the
C<Test::STDmaker> repository. 
The C<build> subroutine takes C<$output_type> and
recast the C<$std> class to C<Test::STDmaker::$std_driver_class>
driver class
The C<bless> subroutine does do class recasting as follows:

 $std_driver = bless $std, Test::STDmaker::$output_type

Typically the recasted class is one of the following:

=over 4

=item L<Test::STDmaker::Check|Test::STDmaker::Check>

=item L<Test::STDmaker::Demo|Test::STDmaker::Demo>

=item L<Test::STDmaker::STD|Test::STDmaker::STD>

=item L<Test::STDmaker::Verify|Test::STDmaker::Verify>

=back

New drivers class may be added by including them in
the C<Test::STDmaker::> repository and thus expand
the above list. 
The C<Test::STDmaker> methods will automatically find the new 
driver classes.

The C<build> subroutine then uses the recast object to
call the C<generate> method followed by the C<print> methods
described below. 
Since the object is now of the C<Test::STDmaker::$std_driver_class>
class which inherits the C<Test::STDmaker> class,
it used the C<&Test::STDmaker::generate> and C<&Test::STDmaker::print>
methods to communicate with the methods in the 
C<Test::STDmaker::$output_type> class.

=head2 generate

 $sucess = $std_driver->generate();

The c<generate> subroutine is the work horse. 
It takes each ordered
C<$name,$data> pair from the C<@{$std->{std_pm}}> array
and executes the method C<$name> with C<$name,$data> as arguments.
The C<$name> variable is the test description short hands C<A> C<E> and so on, 
L<STD PM Form Database Test Description Fields|Test::STDmaker/STD PM Form Database Test Description Fields>.

=head2 perl_command

 $myperl = perl_command();

When running under some CPAN testers setup, the test harness perl executable
may not be the same as the one for the backtick `perl $command` and crash and
burn with errors such as 

Perl lib version (v5.8.4) doesn't match executable version (v5.6.1) 
at /usr/local/perl-5.8.4/lib/5.8.4/sparc-linux/Config.pm line 32.

The C<perl_command> uses C<$^X> to return the current executable Perl
that may be used in backticks without crashing and burning.

=head2 print

 $success = $std_driver->print($file_out);

The C<print> method prints any data accumulated in C<$std>
hash to C<$file_out>.
The method initiates the C<post_print> method, provided it exists
as a C<Test::STDmaker::$output_type> method.

=head1 REQUIREMENTS

This section establishes the functional requirements for the C<Test::STDmaker>
module and the C<Test::STDmaker> package package methods.
All other subroutines in the F<Test::STDmaker> module and modules used
by the C<Test::STDmaker> module support the C<Test::STDmaker> package methods.
Their requirements are of a design nature and not included.
All design requirements may change at any time without notice to
improve performance as long as the change does not
impact the functional requirements and the test results of
the functional requirements.

Binding functional requirements, 
in accordance with L<DOD STD 490A|Docs::US_DOD::STD490A/3.2.3.6>,
are uniquely identified  with the pharse 'shall[dd]' 
where dd is an unique number for each section.
The phrases such as I<will, should, and may> do not identified
binding requirements. 
They provide clarifications of the requirements and hints
for the module design.

The general C<Test::STDmaker> Perl module requirements are as follows:

=over 4

=item load [1]

shall[1] load without error and

=item pod check [2] 

shall[2] passed the L<Pod::Checker|Pod::Checker> check
without error.

=back

=head2 Clean C<Form Database Section> requirements

Before generating any output from a C<Form Database Section> read from a STD PM,
the C<Test::STDmaker> package methods fill clean the data.
The requirements for cleaning the data are as follows:

=over 4

=item clean C<Form Database Section> [1]

The C<Test::STDmaker> package methods shall[1] ensure there is a test 
step number field C<ok: $test_number^> 
after each C< E: $expected ^> and each C<E: $expected^> field.
The C<$test_number> will apply to all fields preceding the C<ok: $test_number^>
to the previous C<ok: $test_number^> or <T: $total_tests^> field

=item clean C<Form Database Section> [2]

The C<Test::STDmaker> package methods shall[2] ensure all test numbers in 
the C<ok: test_number^> fields are numbered the same as when
executed by the test script.

=item clean C<Form Database Section> [3]

The C<Test::STDmaker> package methods shall[3] ensure the first test field is C<T: $total_tests^> 
where C<$total_tests>
is the number of C<ok: $test_number^> fields.

=item clean C<Form Database Section> [4]

The C<Test::STDmaker> package methods shall[4] include a C<$todo_list> in the C<T: $total_tests - $todo_list^> field
where each number in the list is the $test_number for a C<U: ^> field.

=back

The C<Test::STDmaker> package methods will perform this processing as soon as it reads in the
STD PM.
All file generation will use the processed, cleaned
internal test data instead of the raw data directly from the
STD PM.

=head2 Verify output file

When the C<tmake> subroutine c<@targets> contains C<verify>, C<all>
(case insensitive) or is empty, 
the C<Test::STDmaker> package methods, for each input STD PM,
will produce an verify ouput file. 
The functional requirements specify the results of executing the
verify output file.
The contents of the verify output file are of a design nature
and function requirements are not applicable.

The requirements for the generated verify output file are as follow:

=over 4

=item verify file [1]

The C<Test::STDmaker> package methods shall[1] obtained the name for the verify output file
from the C<Verify> field in the STD PM and assume it is
a UNIX file specification relative to STD PM. 

=item verify file [2]

The C<Test::STDmaker> package methods shall[2] generate a test script that when executed
will, for each test, execute the C<C: $code> fields and 
compared the results obtained from the C<A: $actual^> actual expression with the
results from the C<E: $epected^> expected expression and 
produce an output compatible with the L<<C<Test::Harness>|Test::Harness> module.
A test is the fields between the C<ok: $test_number> fields of a cleaned STD PM.
The generated test script will provide skip test functionality by processing
the C<S: $skip-condition>, C<DO: comment> and C<U: comment> test fields and producing suitable
L<Test::Harness|Test::Harness> output.

=item verify file [3]

The C<Test::STDmaker> package methods shall[3] output the
C<N: $name^> field data as a L<<C<Test::Harness>|Test::Harness> compatible comment.

=back

The C<Test::STDmaker> package methods will properly compare complex data structures 
produce by the C<A: $actual^> and C<E: $epected^> expressions by
utilizing modules such as L<Data::Secs2|Data::Secs2> subroutines.

=head2 Demo output file

When the C<tmake> subroutine c<@targets> contains C<demo>, C<all>
(case insensitive) or is empty, 
the C<Test::STDmaker> package methods, for each input STD PM,
will produce a demo ouput file. 
The functional requirements specify the results of executing the
demo output file.
The contents of the demo output file are of a design nature
and function requirements are not applicable.

The requirements for the generated demo output file are as follow:

=over 4

=item demo file [1]

The C<Test::STDmaker> package methods shall[1] obtained the name for the demo output file
from the C<Demo> field in the STD PM and assume it is
a UNIX file specification relative to STD PM. 

=item demo file [2]

The C<Test::STDmaker> package methods shall[2] generate the a demo script that when executed
will produce an output that appears as if the actual C<C: ^> and C<A: ^> where
typed at a console followed by the results of the execution of the C<A: ^> field.
The purpose of the demo script is to provide automated, complete examples, of
the using the Unit Under Test.
The generated demo script will provide skip test functionality by processing
the C<S: $skip-condition>, C<VO: comment> and C<U: comment> test fields.

=back

=head2 STD PM POD

When the C<tmake> subroutine c<@targets> contains C<STD>, C<all>
(case insensitive) or is empty,  
the C<Test::STDmaker> package methods, for each input STD PM,
will generate the code and POD sections of the STD PM from the C<Form Database Section> section. 
The requirements for the generated STD output file are as follow:

=over 4

=item STD PM POD [1]

The C<Test::STDmaker> package methods shall[2] produce the STD output file by taking
the merging STD template file from either the C<Detail_Template> field
C<STD2167_Template> field in the STD PM or a built-in template with the 

C<Copyright Revision End_User Author SVD Classification>

fields from the C<Form Database Section > and the generated  

C<Date UUT_PM STD_PM Test_Descriptions
Test_Script Tests Trace_Requirement_Table Trace_Requirement_Table>

fields.

=back

The C<Test::STDmaker> package methods will generate fields for merging with
the template file as follows:

=over

=item Date

The current data

=item UUT_PM

The Perl :: module specfication for the UUT field in the C<Form Database Section > database

=item STD_PM 

The Perl :: module specification for the C<Form Database Section > Unix file specification

=item Test_Script

The the C<Verify> field in the C<Form Database Section > database

=item Tests

The number of tests in the C<Form Database Section > database

=item Test_Descriptions

A description of a test defined by the fields between
C<ok:> fields in the C<Form Database Section > database.
The test descriptions will be in a L<STD|Docs::US_DOD::STD> format
as tailored by L<STDtailor|STD::STDtailor>

=item Trace_Requirement_Table

A table that relates the C<R:> requirement fields to the test number
in the C<Form Database Section > database.

=item Trace_Test_Table

A table that relates the test number in the C<Form Database Section > database
to the C<R:> requirement fields.

=back

The usual template file is the C<STD/STD001.fmt> file. 
This template is in the L<STD|Docs::US_DOD::STD> format
as tailored by L<STDtailor|STD::STDtailor>.

=head2 Options requirements

The C<tmake> option processing requirements are as follows:

=over 

=item file_out option [1]

When the c<@targets> has only target,  specifying the option

 { file_out => $file_out }

shall[1] cause the C<tmake> method to print the ouput to the file C<$file_out>
instead of the file specified in the STD PM.
The $file_out specification will be in the UNIX specification relative
to the STD PM.

=item replace option [2]

Specifying the option

 { replace => 1 } or { demo => 1 }

with c<@targets> containing C<Demo>, 
shall[2] cause the c<tmake> method to execute the demo script that it generates
and replace the C</(\n=head\d\s+Demonstration).*?\n=/i> section in
the module named by the C<UUT> field in C<Form Database Section> with the output from the
demo script. 

=item run option [3]

Specifying the option

 { run => 1 }

with the c<@targets> list containing C<Verify>, 
shall[3] cause the c<tmake> method to run the
C<Test::Harness> with the test script in non-verbose mode.

=item verbose option [4]

Specifying the options

 { run => 1, test_verbose => 1 }

with the c<@targets> containg C<Verify>, 
shall[4] cause the C<tmake> method to run the
C<Test::Harness> with the test script in verbose mode.

=item fspec_out option [5]

Specifying the option

 { fspec_out => I<$file_spec> }

shall[5] cause the C<Test::STDmaker> methods to translate the
file names in the C<STD> file output to the file specification
I<$file_spec>.

=item fspec_in option [6]

Specifying the option

 { fspec_in => I<$file_spec> }

shall[6] cause the C<Test::STDmaker> methods to use file specification
I<$file_spec> for the files in the STD PM database.

=back

=head1 DEMONSTRATION

 #########
 # perl basic.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use vars qw($loaded);
     use File::Glob ':glob';
     use File::Copy;
     use File::Package;
     use File::SmartNL;
     use Text::Scrub;

     my $fp = 'File::Package';
     my $snl = 'File::SmartNL';
     my $s = 'Text::Scrub';

     my $test_results;
     my $loaded = 0;
     my @outputs;

     my ($success, $diag);

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package( 'Test::STDmaker' )
 $errors

 # ''
 #

 ##################
 # Test::STDmaker Version 1.2
 # 

 $Test::STDmaker::VERSION

 # '1.2'
 #
 $snl->fin('tgA0.pm')

 # '#!perl
 ##
 ## The copyright notice and plain old documentation (POD)
 ## are at the end of this file.
 ##
 #package  t::Test::STDmaker::tgA1;

 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION $DATE $FILE );
 #$VERSION = '0.08';
 #$DATE = '2004/05/23';
 #$FILE = __FILE__;

 #__DATA__

 #Name: t::Test::STDmaker::tgA1^
 #File_Spec: Unix^
 #UUT: Test::STDmaker::tg1^
 #Revision: -^
 #Version: 0.01^
 #End_User: General Public^
 #Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
 #STD2167_Template: ^
 #Detail_Template: ^
 #Classification: None^
 #Demo: tgA1.d^
 #Verify: tgA1.t^

 # T: 0^

 # C: 
 #    #########
 #    # For "TEST" 1.24 or greater that have separate std err output,
 #    # redirect the TESTERR to STDOUT
 #    #
 #    tech_config( 'Test.TESTERR', \*STDOUT );   
 #^  

 #QC: my $expected1 = 'hello world'; ^

 # N: Quiet Code^
 # A: 'hello world'^
 # E: $expected1^

 # N: Pass test^
 # R: L<Test::STDmaker::tg1/capability-A [1]>^
 # C: my $x = 2^
 # C: my $y = 3^
 # A: $x + $y^
 #SE: 5^

 # N: Todo test that passes^
 # U: xy feature^
 # A: $y-$x^
 # E: 1^

 # N: Test that fails^
 # R: 
 #    L<Test::STDmaker::tg1/capability-A [2]>
 #    L<Test::STDmaker::tg1/capability-B [1]>
 # ^
 # A: $x+4^
 # E: 7^

 # N: Skipped tests^
 # S: 1^
 # A: $x*$y*2^
 # E: 6^

 # N: Todo Test that Fails^
 # U: zyw feature^
 # S: 0^
 # A: $x*$y*2^
 # E: 6^

 #DO: ^
 # N: demo only^
 # A: $x^

 #VO: ^
 # N: verify only^
 # A: $x^
 # E: $x^

 # N: Failed test that skips the rest^
 # R: L<Test::STDmaker::tg1/capability-B [2]>^
 # A: $x + $y^
 #SE: 6^

 # N: A test to skip^
 # A: $x + $y + $x^
 # E: 9^

 # N: A not skip to skip^
 # S: 0^
 # R: L<Test::STDmaker::tg1/capability-B [3]>^
 # A: $x + $y + $x + $y^
 # E: 10^

 # N: A skip to skip^
 # S: 1^
 # R: L<Test::STDmaker::tg1/capability-B [3]>^
 # A: $x + $y + $x + $y + $x^
 # E: 10^

 #See_Also: L<Test::STDmaker::tg1> ^

 #Copyright: This STD is public domain.^

 #HTML: ^

 #~-~'
 #

 ##################
 # tmake('STD', {pm => 't::Test::STDmaker::tgA1'})
 # 

     copy 'tgA0.pm', 'tgA1.pm';
     my $tmaker = new Test::STDmaker(pm =>'t::Test::STDmaker::tgA1', nounlink => 1);
     my $perl_executable = $tmaker->perl_command();
     $success = $tmaker->tmake( 'STD' );
     $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
     $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
     $diag .= (-e 'temp.pl') ? "\n~~~~~~~\ntemp.pl\n\n" . $snl->fin('temp.pl') : 'No temp.pl';
     $diag .= (-e 'tgA1.pm') ? "\n~~~~~~~\ntgA1.pm\n\n" . $snl->fin('tgA1.pm') : 'No tgA1.pm';
 $success

 # 1
 #

 ##################
 # Clean STD pm with a todo list
 # 

 $s->scrub_date_version($snl->fin('tgA1.pm'))

 # '#!perl
 ##
 ## The copyright notice and plain old documentation (POD)
 ## are at the end of this file.
 ##
 #package  t::Test::STDmaker::tgA1;

 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION $DATE $FILE );
 #$VERSION = '0.00';
 #$DATE = 'Feb 6, 1969';
 #$FILE = __FILE__;

 #########
 ## The Test::STDmaker module uses the data after the __DATA__ 
 ## token to automatically generate the this file.
 ##
 ## Do not edit anything before __DATA_. Edit instead
 ## the data after the __DATA__ token.
 ##
 ## ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
 ##
 ## the next time Test::STDmaker generates this file.
 ##
 ##

 #=head1 NAME

 #t::Test::STDmaker::tgA1 - Software Test Description for Test::STDmaker::tg1

 #=head1 TITLE PAGE

 # Detailed Software Test Description (STD)

 # for

 # Perl Test::STDmaker::tg1 Program Module

 # Revision: -

 # Version: 0.01

 # $DATE: Feb 6, 1969

 # Prepared for: General Public 

 # Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 # Classification: None

 ########
 ##  
 ##  1. SCOPE
 ##
 ##
 #=head1 SCOPE

 #This detail STD and the 
 #L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
 #establishes the tests to verify the
 #requirements of Perl Program Module (PM) L<Test::STDmaker::tg1|Test::STDmaker::tg1>
 #The format of this STD is a tailored L<2167A STD DID|Docs::US_DOD::STD>.

 ########
 ##  
 ##  3. TEST PREPARATIONS
 ##
 ##
 #=head1 TEST PREPARATIONS

 #Test preparations are establishes by the L<General STD|Test::STD::PerlSTD>.

 ########
 ##  
 ##  4. TEST DESCRIPTIONS
 ##
 ##
 #=head1 TEST DESCRIPTIONS

 #The test descriptions uses a legend to
 #identify different aspects of a test description
 #in accordance with
 #L<STD PM Form Database Test Description Fields|Test::STDmaker/STD PM Form Database Test Description Fields>.

 #=head2 Test Plan

 # T: 11 - 3,6^

 #=head2 ok: 1

 #  C:
 #     #########
 #     # For "TEST" 1.24 or greater that have separate std err output,
 #     # redirect the TESTERR to STDOUT
 #     #
 #     tech_config( 'Test.TESTERR', \*STDOUT );
 # ^
 # QC: my $expected1 = 'hello world';^
 #  N: Quiet Code^
 #  A: 'hello world'^
 #  E: $expected1^
 # ok: 1^

 #=head2 ok: 2

 #  N: Pass test^
 #  R: L<Test::STDmaker::tg1/capability-A [1]>^
 #  C: my $x = 2^
 #  C: my $y = 3^
 #  A: $x + $y^
 # SE: 5^
 # ok: 2^

 #=head2 ok: 3

 #  N: Todo test that passes^
 #  U: xy feature^
 #  A: $y-$x^
 #  E: 1^
 # ok: 3^

 #=head2 ok: 4

 #  N: Test that fails^

 #  R:
 #     L<Test::STDmaker::tg1/capability-A [2]>
 #     L<Test::STDmaker::tg1/capability-B [1]>
 # ^
 #  A: $x+4^
 #  E: 7^
 # ok: 4^

 #=head2 ok: 5

 #  N: Skipped tests^
 #  S: 1^
 #  A: $x*$y*2^
 #  E: 6^
 # ok: 5^

 #=head2 ok: 6

 #  N: Todo Test that Fails^
 #  U: zyw feature^
 #  S: 0^
 #  A: $x*$y*2^
 #  E: 6^
 # ok: 6^

 #=head2 ok: 7

 # DO: ^
 #  N: demo only^
 #  A: $x^

 #VO: ^
 #  N: verify only^
 #  A: $x^
 #  E: $x^
 # ok: 7^

 #=head2 ok: 8

 #  N: Failed test that skips the rest^
 #  R: L<Test::STDmaker::tg1/capability-B [2]>^
 #  A: $x + $y^
 # SE: 6^
 # ok: 8^

 #=head2 ok: 9

 #  N: A test to skip^
 #  A: $x + $y + $x^
 #  E: 9^
 # ok: 9^

 #=head2 ok: 10

 #  N: A not skip to skip^
 #  S: 0^
 #  R: L<Test::STDmaker::tg1/capability-B [3]>^
 #  A: $x + $y + $x + $y^
 #  E: 10^
 # ok: 10^

 #=head2 ok: 11

 #  N: A skip to skip^
 #  S: 1^
 #  R: L<Test::STDmaker::tg1/capability-B [3]>^
 #  A: $x + $y + $x + $y + $x^
 #  E: 10^
 # ok: 11^

 ########
 ##  
 ##  5. REQUIREMENTS TRACEABILITY
 ##
 ##

 #=head1 REQUIREMENTS TRACEABILITY

 #  Requirement                                                      Test
 # ---------------------------------------------------------------- ----------------------------------------------------------------
 # L<Test::STDmaker::tg1/capability-A [1]>                          L<t::Test::STDmaker::tgA1/ok: 2>
 # L<Test::STDmaker::tg1/capability-A [2]>                          L<t::Test::STDmaker::tgA1/ok: 4>
 # L<Test::STDmaker::tg1/capability-B [1]>                          L<t::Test::STDmaker::tgA1/ok: 4>
 # L<Test::STDmaker::tg1/capability-B [2]>                          L<t::Test::STDmaker::tgA1/ok: 8>
 # L<Test::STDmaker::tg1/capability-B [3]>                          L<t::Test::STDmaker::tgA1/ok: 10>
 # L<Test::STDmaker::tg1/capability-B [3]>                          L<t::Test::STDmaker::tgA1/ok: 11>

 #  Test                                                             Requirement
 # ---------------------------------------------------------------- ----------------------------------------------------------------
 # L<t::Test::STDmaker::tgA1/ok: 10>                                L<Test::STDmaker::tg1/capability-B [3]>
 # L<t::Test::STDmaker::tgA1/ok: 11>                                L<Test::STDmaker::tg1/capability-B [3]>
 # L<t::Test::STDmaker::tgA1/ok: 2>                                 L<Test::STDmaker::tg1/capability-A [1]>
 # L<t::Test::STDmaker::tgA1/ok: 4>                                 L<Test::STDmaker::tg1/capability-A [2]>
 # L<t::Test::STDmaker::tgA1/ok: 4>                                 L<Test::STDmaker::tg1/capability-B [1]>
 # L<t::Test::STDmaker::tgA1/ok: 8>                                 L<Test::STDmaker::tg1/capability-B [2]>

 #=cut

 ########
 ##  
 ##  6. NOTES
 ##
 ##

 #=head1 NOTES

 #This STD is public domain.

 ########
 ##
 ##  2. REFERENCED DOCUMENTS
 ##
 ##
 ##

 #=head1 SEE ALSO

 #L<Test::STDmaker::tg1>

 #=back

 #=for html

 #=cut

 #__DATA__

 #Name: t::Test::STDmaker::tgA1^
 #File_Spec: Unix^
 #UUT: Test::STDmaker::tg1^
 #Revision: -^
 #Version: 0.01^
 #End_User: General Public^
 #Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
 #STD2167_Template: ^
 #Detail_Template: ^
 #Classification: None^
 #Temp: temp.pl^
 #Demo: tgA1.d^
 #Verify: tgA1.t^

 # T: 11 - 3,6^

 # C:
 #    #########
 #    # For "TEST" 1.24 or greater that have separate std err output,
 #    # redirect the TESTERR to STDOUT
 #    #
 #    tech_config( 'Test.TESTERR', \*STDOUT );
 #^

 #QC: my $expected1 = 'hello world';^
 # N: Quiet Code^
 # A: 'hello world'^
 # E: $expected1^
 #ok: 1^

 # N: Pass test^
 # R: L<Test::STDmaker::tg1/capability-A [1]>^
 # C: my $x = 2^
 # C: my $y = 3^
 # A: $x + $y^
 #SE: 5^
 #ok: 2^

 # N: Todo test that passes^
 # U: xy feature^
 # A: $y-$x^
 # E: 1^
 #ok: 3^

 # N: Test that fails^

 # R:
 #    L<Test::STDmaker::tg1/capability-A [2]>
 #    L<Test::STDmaker::tg1/capability-B [1]>
 #^

 # A: $x+4^
 # E: 7^
 #ok: 4^

 # N: Skipped tests^
 # S: 1^
 # A: $x*$y*2^
 # E: 6^
 #ok: 5^

 # N: Todo Test that Fails^
 # U: zyw feature^
 # S: 0^
 # A: $x*$y*2^
 # E: 6^
 #ok: 6^

 #DO: ^
 # N: demo only^
 # A: $x^

 #VO: ^
 # N: verify only^
 # A: $x^
 # E: $x^
 #ok: 7^

 # N: Failed test that skips the rest^
 # R: L<Test::STDmaker::tg1/capability-B [2]>^
 # A: $x + $y^
 #SE: 6^
 #ok: 8^

 # N: A test to skip^
 # A: $x + $y + $x^
 # E: 9^
 #ok: 9^

 # N: A not skip to skip^
 # S: 0^
 # R: L<Test::STDmaker::tg1/capability-B [3]>^
 # A: $x + $y + $x + $y^
 # E: 10^
 #ok: 10^

 # N: A skip to skip^
 # S: 1^
 # R: L<Test::STDmaker::tg1/capability-B [3]>^
 # A: $x + $y + $x + $y + $x^
 # E: 10^
 #ok: 11^

 #See_Also: L<Test::STDmaker::tg1>^
 #Copyright: This STD is public domain.^
 #HTML: ^

 #~-~
 #'
 #

 ##################
 # Cleaned tgA1.pm
 # 

 $s->scrub_date_version($snl->fin('tgA1.pm'))

 # '#!perl
 ##
 ## The copyright notice and plain old documentation (POD)
 ## are at the end of this file.
 ##
 #package  t::Test::STDmaker::tgA1;

 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION $DATE $FILE );
 #$VERSION = '0.00';
 #$DATE = 'Feb 6, 1969';
 #$FILE = __FILE__;

 #########
 ## The Test::STDmaker module uses the data after the __DATA__ 
 ## token to automatically generate the this file.
 ##
 ## Do not edit anything before __DATA_. Edit instead
 ## the data after the __DATA__ token.
 ##
 ## ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
 ##
 ## the next time Test::STDmaker generates this file.
 ##
 ##

 #=head1 NAME

 #t::Test::STDmaker::tgA1 - Software Test Description for Test::STDmaker::tg1

 #=head1 TITLE PAGE

 # Detailed Software Test Description (STD)

 # for

 # Perl Test::STDmaker::tg1 Program Module

 # Revision: -

 # Version: 0.01

 # $DATE: Feb 6, 1969

 # Prepared for: General Public 

 # Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 # Classification: None

 ########
 ##  
 ##  1. SCOPE
 ##
 ##
 #=head1 SCOPE

 #This detail STD and the 
 #L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
 #establishes the tests to verify the
 #requirements of Perl Program Module (PM) L<Test::STDmaker::tg1|Test::STDmaker::tg1>
 #The format of this STD is a tailored L<2167A STD DID|Docs::US_DOD::STD>.

 ########
 ##  
 ##  3. TEST PREPARATIONS
 ##
 ##
 #=head1 TEST PREPARATIONS

 #Test preparations are establishes by the L<General STD|Test::STD::PerlSTD>.

 ########
 ##  
 ##  4. TEST DESCRIPTIONS
 ##
 ##
 #=head1 TEST DESCRIPTIONS

 #The test descriptions uses a legend to
 #identify different aspects of a test description
 #in accordance with
 #L<STD PM Form Database Test Description Fields|Test::STDmaker/STD PM Form Database Test Description Fields>.

 #=head2 Test Plan

 # T: 11 - 3,6^

 #=head2 ok: 1

 #  C:
 #     #########
 #     # For "TEST" 1.24 or greater that have separate std err output,
 #     # redirect the TESTERR to STDOUT
 #     #
 #     tech_config( 'Test.TESTERR', \*STDOUT );
 # ^
 # QC: my $expected1 = 'hello world';^
 #  N: Quiet Code^
 #  A: 'hello world'^
 #  E: $expected1^
 # ok: 1^

 #=head2 ok: 2

 #  N: Pass test^
 #  R: L<Test::STDmaker::tg1/capability-A [1]>^
 #  C: my $x = 2^
 #  C: my $y = 3^
 #  A: $x + $y^
 # SE: 5^
 # ok: 2^

 #=head2 ok: 3

 #  N: Todo test that passes^
 #  U: xy feature^
 #  A: $y-$x^
 #  E: 1^
 # ok: 3^

 #=head2 ok: 4

 #  N: Test that fails^

 #  R:
 #     L<Test::STDmaker::tg1/capability-A [2]>
 #     L<Test::STDmaker::tg1/capability-B [1]>
 # ^
 #  A: $x+4^
 #  E: 7^
 # ok: 4^

 #=head2 ok: 5

 #  N: Skipped tests^
 #  S: 1^
 #  A: $x*$y*2^
 #  E: 6^
 # ok: 5^

 #=head2 ok: 6

 #  N: Todo Test that Fails^
 #  U: zyw feature^
 #  S: 0^
 #  A: $x*$y*2^
 #  E: 6^
 # ok: 6^

 #=head2 ok: 7

 # DO: ^
 #  N: demo only^
 #  A: $x^

 #VO: ^
 #  N: verify only^
 #  A: $x^
 #  E: $x^
 # ok: 7^

 #=head2 ok: 8

 #  N: Failed test that skips the rest^
 #  R: L<Test::STDmaker::tg1/capability-B [2]>^
 #  A: $x + $y^
 # SE: 6^
 # ok: 8^

 #=head2 ok: 9

 #  N: A test to skip^
 #  A: $x + $y + $x^
 #  E: 9^
 # ok: 9^

 #=head2 ok: 10

 #  N: A not skip to skip^
 #  S: 0^
 #  R: L<Test::STDmaker::tg1/capability-B [3]>^
 #  A: $x + $y + $x + $y^
 #  E: 10^
 # ok: 10^

 #=head2 ok: 11

 #  N: A skip to skip^
 #  S: 1^
 #  R: L<Test::STDmaker::tg1/capability-B [3]>^
 #  A: $x + $y + $x + $y + $x^
 #  E: 10^
 # ok: 11^

 ########
 ##  
 ##  5. REQUIREMENTS TRACEABILITY
 ##
 ##

 #=head1 REQUIREMENTS TRACEABILITY

 #  Requirement                                                      Test
 # ---------------------------------------------------------------- ----------------------------------------------------------------
 # L<Test::STDmaker::tg1/capability-A [1]>                          L<t::Test::STDmaker::tgA1/ok: 2>
 # L<Test::STDmaker::tg1/capability-A [2]>                          L<t::Test::STDmaker::tgA1/ok: 4>
 # L<Test::STDmaker::tg1/capability-B [1]>                          L<t::Test::STDmaker::tgA1/ok: 4>
 # L<Test::STDmaker::tg1/capability-B [2]>                          L<t::Test::STDmaker::tgA1/ok: 8>
 # L<Test::STDmaker::tg1/capability-B [3]>                          L<t::Test::STDmaker::tgA1/ok: 10>
 # L<Test::STDmaker::tg1/capability-B [3]>                          L<t::Test::STDmaker::tgA1/ok: 11>

 #  Test                                                             Requirement
 # ---------------------------------------------------------------- ----------------------------------------------------------------
 # L<t::Test::STDmaker::tgA1/ok: 10>                                L<Test::STDmaker::tg1/capability-B [3]>
 # L<t::Test::STDmaker::tgA1/ok: 11>                                L<Test::STDmaker::tg1/capability-B [3]>
 # L<t::Test::STDmaker::tgA1/ok: 2>                                 L<Test::STDmaker::tg1/capability-A [1]>
 # L<t::Test::STDmaker::tgA1/ok: 4>                                 L<Test::STDmaker::tg1/capability-A [2]>
 # L<t::Test::STDmaker::tgA1/ok: 4>                                 L<Test::STDmaker::tg1/capability-B [1]>
 # L<t::Test::STDmaker::tgA1/ok: 8>                                 L<Test::STDmaker::tg1/capability-B [2]>

 #=cut

 ########
 ##  
 ##  6. NOTES
 ##
 ##

 #=head1 NOTES

 #This STD is public domain.

 ########
 ##
 ##  2. REFERENCED DOCUMENTS
 ##
 ##
 ##

 #=head1 SEE ALSO

 #L<Test::STDmaker::tg1>

 #=back

 #=for html

 #=cut

 #__DATA__

 #Name: t::Test::STDmaker::tgA1^
 #File_Spec: Unix^
 #UUT: Test::STDmaker::tg1^
 #Revision: -^
 #Version: 0.01^
 #End_User: General Public^
 #Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
 #STD2167_Template: ^
 #Detail_Template: ^
 #Classification: None^
 #Temp: temp.pl^
 #Demo: tgA1.d^
 #Verify: tgA1.t^

 # T: 11 - 3,6^

 # C:
 #    #########
 #    # For "TEST" 1.24 or greater that have separate std err output,
 #    # redirect the TESTERR to STDOUT
 #    #
 #    tech_config( 'Test.TESTERR', \*STDOUT );
 #^

 #QC: my $expected1 = 'hello world';^
 # N: Quiet Code^
 # A: 'hello world'^
 # E: $expected1^
 #ok: 1^

 # N: Pass test^
 # R: L<Test::STDmaker::tg1/capability-A [1]>^
 # C: my $x = 2^
 # C: my $y = 3^
 # A: $x + $y^
 #SE: 5^
 #ok: 2^

 # N: Todo test that passes^
 # U: xy feature^
 # A: $y-$x^
 # E: 1^
 #ok: 3^

 # N: Test that fails^

 # R:
 #    L<Test::STDmaker::tg1/capability-A [2]>
 #    L<Test::STDmaker::tg1/capability-B [1]>
 #^

 # A: $x+4^
 # E: 7^
 #ok: 4^

 # N: Skipped tests^
 # S: 1^
 # A: $x*$y*2^
 # E: 6^
 #ok: 5^

 # N: Todo Test that Fails^
 # U: zyw feature^
 # S: 0^
 # A: $x*$y*2^
 # E: 6^
 #ok: 6^

 #DO: ^
 # N: demo only^
 # A: $x^

 #VO: ^
 # N: verify only^
 # A: $x^
 # E: $x^
 #ok: 7^

 # N: Failed test that skips the rest^
 # R: L<Test::STDmaker::tg1/capability-B [2]>^
 # A: $x + $y^
 #SE: 6^
 #ok: 8^

 # N: A test to skip^
 # A: $x + $y + $x^
 # E: 9^
 #ok: 9^

 # N: A not skip to skip^
 # S: 0^
 # R: L<Test::STDmaker::tg1/capability-B [3]>^
 # A: $x + $y + $x + $y^
 # E: 10^
 #ok: 10^

 # N: A skip to skip^
 # S: 1^
 # R: L<Test::STDmaker::tg1/capability-B [3]>^
 # A: $x + $y + $x + $y + $x^
 # E: 10^
 #ok: 11^

 #See_Also: L<Test::STDmaker::tg1>^
 #Copyright: This STD is public domain.^
 #HTML: ^

 #~-~
 #'
 #

 ##################
 # Internal Storage
 # 

     use Data::Dumper;
     my $probe = 3;
     my $actual_results = Dumper([0+$probe]);
     my $internal_storage = 'undetermine';
     if( $actual_results eq Dumper([3]) ) {
         $internal_storage = 'number';
     }
     elsif ( $actual_results eq Dumper(['3']) ) {
         $internal_storage = 'string';
     }

     my $expected_results;
 $internal_storage

 # 'string'
 #

 ##################
 # tmake('demo', {pm => 't::Test::STDmaker::tgA1', demo => 1})
 # 

 $snl->fin( 'tg0.pm'  )

 # '#!perl
 ##
 ## Documentation, copyright and license is at the end of this file.
 ##
 #package  Test::STDmaker::tg1;

 #use 5.001;
 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION);

 #$VERSION = '0.03';

 #1

 #__END__

 #=head1 Requirements

 #=head2 Capability-A 

 #The requriements are as follows:

 #=over 4

 #=item capability-A [1]

 #This subroutine shall[1] have feature 1. 

 #=item capability-A [2]

 #This subroutine shall[2] have feature 2.

 #=back

 #=head2 Capability-B
 # 
 #=over 4

 #=item Capability-B [1]

 #This subroutine shall[1] have feature 1.

 #=item Capability-B [2]

 #This subroutine shall[2] have feature 2.

 #=item Capability-B [3]

 #This subroutine shall[3] have feature 3.

 #=back

 #=head1 DEMONSTRATION
 #  
 #=head1 SEE ALSO

 #http://perl.SoftwareDiamonds.com

 #'
 #

 ##################
 # tmake('demo', {pm => 't::Test::STDmaker::tgA1', demo => 1})
 # 

     #########
     #
     # Individual generate outputs using options
     #
     ########

     skip_tests(0);

     #####
     # Make sure there is no residue outputs hanging
     # around from the last test series.
     #
     @outputs = bsd_glob( 'tg*1.*' );
     unlink @outputs;
     copy 'tg0.pm', 'tg1.pm';
     copy 'tgA0.pm', 'tgA1.pm';
     my @cwd = File::Spec->splitdir( cwd() );
     pop @cwd;
     pop @cwd;
     unshift @INC, File::Spec->catdir( @cwd );  # put UUT in lib path
     $success = $tmaker->tmake('demo', { pm => 't::Test::STDmaker::tgA1', demo => 1});
     shift @INC;

     #######
     # expected results depend upon the internal storage from numbers 
     #
     if( $internal_storage eq 'string') {
         $expected_results = 'tg2B.pm';
     }
     else {
         $expected_results = 'tg2A.pm';
     }
     $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
     $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
     $diag .= (-e 'tgA1.pm') ? "\n~~~~~~~\ntgA1.pm\n\n" . $snl->fin('tgA1.pm') : 'No tgA1.pm';
     $diag .= (-e 'tgA1.d') ? "\n~~~~~~~\ntgA1.d\n\n" . $snl->fin('tgA1.d') : 'No tgA1.d';
 $success

 # 1
 #

 ##################
 # Generate and replace a demonstration
 # 

 $s->scrub_date_version($snl->fin('tg1.pm'))

 # '#!perl
 ##
 ## Documentation, copyright and license is at the end of this file.
 ##
 #package  Test::STDmaker::tg1;

 #use 5.001;
 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION);

 #$VERSION = '0.00';

 #1

 #__END__

 #=head1 Requirements

 #=head2 Capability-A 

 #The requriements are as follows:

 #=over 4

 #=item capability-A [1]

 #This subroutine shall[1] have feature 1. 

 #=item capability-A [2]

 #This subroutine shall[2] have feature 2.

 #=back

 #=head2 Capability-B
 # 
 #=over 4

 #=item Capability-B [1]

 #This subroutine shall[1] have feature 1.

 #=item Capability-B [2]

 #This subroutine shall[2] have feature 2.

 #=item Capability-B [3]

 #This subroutine shall[3] have feature 3.

 #=back

 #=head1 DEMONSTRATION

 # #########
 # # perl tgA1.d
 # ###

 #~~~~~~ Demonstration overview ~~~~~

 #The results from executing the Perl Code 
 #follow on the next lines as comments. For example,

 # 2 + 2
 # # 4

 #~~~~~~ The demonstration follows ~~~~~

 #     #########
 #     # For "TEST" 1.24 or greater that have separate std err output,
 #     # redirect the TESTERR to STDOUT
 #     #
 #     tech_config( 'Test.TESTERR', \*STDOUT );

 # ##################
 # # Quiet Code
 # # 

 # 'hello world'

 # # 'hello world'
 # #

 # ##################
 # # Pass test
 # # 

 # my $x = 2
 # my $y = 3
 # $x + $y

 # # '5'
 # #

 # ##################
 # # Todo test that passes
 # # 

 # $y-$x

 # # '1'
 # #

 # ##################
 # # Test that fails
 # # 

 # $x+4

 # # '6'
 # #

 # ##################
 # # Skipped tests
 # # 

 # ##################
 # # Todo Test that Fails
 # # 

 # $x*$y*2

 # # '12'
 # #

 # ##################
 # # demo only
 # # 

 # $x

 # # 2
 # #

 # ##################
 # # Failed test that skips the rest
 # # 

 # $x + $y

 # # '5'
 # #

 # ##################
 # # A test to skip
 # # 

 # $x + $y + $x

 # # '7'
 # #

 # ##################
 # # A not skip to skip
 # # 

 # $x + $y + $x + $y

 # # '10'
 # #

 # ##################
 # # A skip to skip
 # # 

 #=head1 SEE ALSO

 #http://perl.SoftwareDiamonds.com

 #'
 #

 ##################
 # tmake('verify', {pm => 't::Test::STDmaker::tgA1', run => 1, test_verbose => 1})
 # 

     skip_tests(0);

     no warnings;
     open SAVEOUT, ">&STDOUT";
     use warnings;
     open STDOUT, ">tgA1.txt";
     $success = $tmaker->tmake('verify', { pm => 't::Test::STDmaker::tgA1', run => 1, test_verbose => 1});
     close STDOUT;
     open STDOUT, ">&SAVEOUT";

     ######
     # For some reason, test harness puts in a extra line when running u
     # under the Active debugger on Win32. So just take it out.
     # Also the script name is absolute which is site dependent.
     # Take it out of the comparision.
     #
     $test_results = $snl->fin('tgA1.txt');
     $test_results =~ s/.*?1..9/1..9/; 
     $test_results =~ s/------.*?\n(\s*\()/\n $1/s;
     $snl->fout('tgA1.txt',$test_results);
 $success

 # 1
 #

 ##################
 # Generate and verbose test harness run test script
 # 

 $s->scrub_probe($s->scrub_test_file($s->scrub_file_line($test_results)))

 # '~~~~
 #ok 1 - Quiet Code 
 #ok 2 - Pass test 
 #ok 3 - Todo test that passes  # (xxxx.t at line 000 TODO?!)
 #not ok 4 - Test that fails 
 ## Test 4 got: '6' (xxxx.t at line 000)
 ##   Expected: '7'
 #ok 5 - Skipped tests  # skip
 #not ok 6 - Todo Test that Fails 
 ## Test 6 got: '12' (xxxx.t at line 000 *TODO*)
 ##   Expected: '6'
 #ok 7 - verify only 
 #not ok 8 - Failed test that skips the rest 
 ## Test 8 got: '5' (xxxx.t at line 000)
 ##   Expected: '6'
 #ok 9 - A test to skip  # skip - Test not performed because of previous failure.
 #ok 10 - A not skip to skip  # skip - Test not performed because of previous failure.
 #ok 11 - A skip to skip  # skip - Test not performed because of previous failure.
 ## Skipped: 5 9 10 11
 ## Failed : 4 6 8
 ## Passed : 4/7 57%
 #FAILED tests 4, 8
 #	Failed 2/11 tests, 81.82% okay (less 4 skipped tests: 5 okay, 45.45%)
 #Failed Test                       Stat Wstat Total Fail  Failed  List of Failed

 #  (1 subtest UNEXPECTEDLY SUCCEEDED), 4 subtests skipped.
 #Failed 1/1 test scripts, 0.00% okay. 2/11 subtests failed, 81.82% okay.
 #~~~~
 #Finished running Tests

 #'
 #

 ##################
 # Generate and test harness run test script
 # 

 $test_results

 # '~~~~
 #Running Tests

 #E:\User\SoftwareDiamonds\installation\t\Test\STDmaker\tgA1....1..11 todo 3 6;
 ## Running under perl version 5.006001 for MSWin32
 ## Win32::BuildNumber 635
 ## Current time local: Mon May 24 00:44:23 2004
 ## Current time GMT:   Mon May 24 04:44:23 2004
 ## Using Test.pm version 1.24
 ## Test::Tech     : 1.26
 ## Data::Secs2    : 1.26
 ## Data::Startup  : 0.07
 ## Data::Str2Num  : 0.08
 ## Number of tests: 11
 ## =cut 
 #ok 1 - Quiet Code 
 #ok 2 - Pass test 
 #ok 3 - Todo test that passes  # (E:\User\SoftwareDiamonds\installation\t\Test\STDmaker\tgA1.t at line 149 TODO?!)
 #not ok 4 - Test that fails 
 ## Test 4 got: '6' (E:\User\SoftwareDiamonds\installation\t\Test\STDmaker\tgA1.t at line 164)
 ##   Expected: '7'
 #ok 5 - Skipped tests  # skip
 #not ok 6 - Todo Test that Fails 
 ## Test 6 got: '12' (E:\User\SoftwareDiamonds\installation\t\Test\STDmaker\tgA1.t at line 182 *TODO*)
 ##   Expected: '6'
 #ok 7 - verify only 
 #not ok 8 - Failed test that skips the rest 
 ## Test 8 got: '5' (E:\User\SoftwareDiamonds\installation\t\Test\STDmaker\tgA1.t at line 203)
 ##   Expected: '6'
 #ok 9 - A test to skip  # skip - Test not performed because of previous failure.
 #ok 10 - A not skip to skip  # skip - Test not performed because of previous failure.
 #ok 11 - A skip to skip  # skip - Test not performed because of previous failure.
 ## Skipped: 5 9 10 11
 ## Failed : 4 6 8
 ## Passed : 4/7 57%
 #FAILED tests 4, 8
 #	Failed 2/11 tests, 81.82% okay (less 4 skipped tests: 5 okay, 45.45%)
 #Failed Test                       Stat Wstat Total Fail  Failed  List of Failed

 #  (1 subtest UNEXPECTEDLY SUCCEEDED), 4 subtests skipped.
 #Failed 1/1 test scripts, 0.00% okay. 2/11 subtests failed, 81.82% okay.
 #~~~~
 #Finished running Tests

 #'
 #
 $snl->fin('tgB0.pm')

 # '#!perl
 ##
 ## The copyright notice and plain old documentation (POD)
 ## are at the end of this file.
 ##
 #package  t::Test::STDmaker::tgB1;

 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION $DATE $FILE );
 #$VERSION = '0.02';
 #$DATE = '2004/05/18';
 #$FILE = __FILE__;

 #########
 ## The Test::STDmaker module uses the data after the __DATA__ 
 ## token to automatically generate the this file.
 ##
 ## Don't edit anything before __DATA_. Edit instead
 ## the data after the __DATA__ token.
 ##
 ## ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
 ##
 ## the next time Test::STDmaker generates this file.
 ##
 ##

 #__DATA__

 #Name: t::Test::STDmaker::tgB1^
 #File_Spec: Unix^
 #UUT: Test::STDmaker::tg1^
 #Revision: -^
 #End_User: General Public^
 #Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
 #Detail_Template: ^
 #STD2167_Template: ^
 #Version: 0.01^
 #Classification: None^
 #Temp: temp.pl^
 #Demo: tgB1.d^
 #Verify: tgB1.t^

 # T: 2^

 # C: 
 #    #########
 #    # For "TEST" 1.24 or greater that have separate std err output,
 #    # redirect the TESTERR to STDOUT
 #    #
 #    tech_config( 'Test.TESTERR', \*STDOUT );   
 #^  

 # R: L<Test::STDmaker::tg1/capability-A [1]>^
 # C: my $x = 2^
 # C: my $y = 3^
 # A: $x + $y^
 #SE: 5^
 #ok: 1^

 # A: [($x+$y,$y-$x)]^
 # E: [5,2]^
 #ok: 2^

 #See_Also: L<Test::STDmaker::tg1>^
 #Copyright: This STD is public domain^

 #HTML:
 #<hr>
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="NOTICE" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="OPT-IN" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="LOG_CGI" -->
 #<!-- /BLK -->
 #<p><br>
 #^

 #~-~
 #'
 #
     skip_tests(0);
     copy 'tgB0.pm', 'tgB1.pm';
     $success = $tmaker->tmake('STD', 'verify', {pm => 't::Test::STDmaker::tgB1', nounlink => 1} );
     $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
     $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
     $diag .= (-e 'temp.pl') ? "\n~~~~~~~\ntemp.pl\n\n" . $snl->fin('temp.pl') : 'No temp.pl';
     $diag .= (-e 'tgB1.pm') ? "\n~~~~~~~\ntgB1.pm\n\n" . $snl->fin('tgB1.pm') : 'No tgB1.pm';
     $diag .= (-e 'tgB1.t') ? "\n~~~~~~~\ntgB1.t\n\n" . $snl->fin('tgB1.t') : 'No tgB1.t';

 ##################
 # tmake('STD', 'verify', {pm => 't::Test::STDmaker::tgB1'})
 # 

 $success

 # 1
 #

 ##################
 # Clean STD pm without a todo list
 # 

 $s->scrub_date_version($snl->fin('tgB1.pm'))

 # '#!perl
 ##
 ## The copyright notice and plain old documentation (POD)
 ## are at the end of this file.
 ##
 #package  t::Test::STDmaker::tgB1;

 #use strict;
 #use warnings;
 #use warnings::register;

 #use vars qw($VERSION $DATE $FILE );
 #$VERSION = '0.00';
 #$DATE = 'Feb 6, 1969';
 #$FILE = __FILE__;

 #########
 ## The Test::STDmaker module uses the data after the __DATA__ 
 ## token to automatically generate the this file.
 ##
 ## Do not edit anything before __DATA_. Edit instead
 ## the data after the __DATA__ token.
 ##
 ## ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
 ##
 ## the next time Test::STDmaker generates this file.
 ##
 ##

 #=head1 NAME

 #t::Test::STDmaker::tgB1 - Software Test Description for Test::STDmaker::tg1

 #=head1 TITLE PAGE

 # Detailed Software Test Description (STD)

 # for

 # Perl Test::STDmaker::tg1 Program Module

 # Revision: -

 # Version: 0.01

 # $DATE: Feb 6, 1969

 # Prepared for: General Public 

 # Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 # Classification: None

 ########
 ##  
 ##  1. SCOPE
 ##
 ##
 #=head1 SCOPE

 #This detail STD and the 
 #L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
 #establishes the tests to verify the
 #requirements of Perl Program Module (PM) L<Test::STDmaker::tg1|Test::STDmaker::tg1>
 #The format of this STD is a tailored L<2167A STD DID|Docs::US_DOD::STD>.

 ########
 ##  
 ##  3. TEST PREPARATIONS
 ##
 ##
 #=head1 TEST PREPARATIONS

 #Test preparations are establishes by the L<General STD|Test::STD::PerlSTD>.

 ########
 ##  
 ##  4. TEST DESCRIPTIONS
 ##
 ##
 #=head1 TEST DESCRIPTIONS

 #The test descriptions uses a legend to
 #identify different aspects of a test description
 #in accordance with
 #L<STD PM Form Database Test Description Fields|Test::STDmaker/STD PM Form Database Test Description Fields>.

 #=head2 Test Plan

 # T: 2^

 #=head2 ok: 1

 #  C:
 #     #########
 #     # For "TEST" 1.24 or greater that have separate std err output,
 #     # redirect the TESTERR to STDOUT
 #     #
 #     tech_config( 'Test.TESTERR', \*STDOUT );
 # ^
 #  R: L<Test::STDmaker::tg1/capability-A [1]>^
 #  C: my $x = 2^
 #  C: my $y = 3^
 #  A: $x + $y^
 # SE: 5^
 # ok: 1^

 #=head2 ok: 2

 #  A: [($x+$y,$y-$x)]^
 #  E: [5,2]^
 # ok: 2^

 ########
 ##  
 ##  5. REQUIREMENTS TRACEABILITY
 ##
 ##

 #=head1 REQUIREMENTS TRACEABILITY

 #  Requirement                                                      Test
 # ---------------------------------------------------------------- ----------------------------------------------------------------
 # L<Test::STDmaker::tg1/capability-A [1]>                          L<t::Test::STDmaker::tgB1/ok: 1>

 #  Test                                                             Requirement
 # ---------------------------------------------------------------- ----------------------------------------------------------------
 # L<t::Test::STDmaker::tgB1/ok: 1>                                 L<Test::STDmaker::tg1/capability-A [1]>

 #=cut

 ########
 ##  
 ##  6. NOTES
 ##
 ##

 #=head1 NOTES

 #This STD is public domain

 ########
 ##
 ##  2. REFERENCED DOCUMENTS
 ##
 ##
 ##

 #=head1 SEE ALSO

 #L<Test::STDmaker::tg1>

 #=back

 #=for html
 #<hr>
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="NOTICE" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="OPT-IN" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="LOG_CGI" -->
 #<!-- /BLK -->
 #<p><br>

 #=cut

 #__DATA__

 #Name: t::Test::STDmaker::tgB1^
 #File_Spec: Unix^
 #UUT: Test::STDmaker::tg1^
 #Revision: -^
 #Version: 0.01^
 #End_User: General Public^
 #Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
 #STD2167_Template: ^
 #Detail_Template: ^
 #Classification: None^
 #Temp: temp.pl^
 #Demo: tgB1.d^
 #Verify: tgB1.t^

 # T: 2^

 # C:
 #    #########
 #    # For "TEST" 1.24 or greater that have separate std err output,
 #    # redirect the TESTERR to STDOUT
 #    #
 #    tech_config( 'Test.TESTERR', \*STDOUT );
 #^

 # R: L<Test::STDmaker::tg1/capability-A [1]>^
 # C: my $x = 2^
 # C: my $y = 3^
 # A: $x + $y^
 #SE: 5^
 #ok: 1^

 # A: [($x+$y,$y-$x)]^
 # E: [5,2]^
 #ok: 2^

 #See_Also: L<Test::STDmaker::tg1>^
 #Copyright: This STD is public domain^

 #HTML:
 #<hr>
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="NOTICE" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="OPT-IN" -->
 #<!-- /BLK -->
 #<p><br>
 #<!-- BLK ID="LOG_CGI" -->
 #<!-- /BLK -->
 #<p><br>
 #^

 #~-~
 #'
 #

 ##################
 # Generated and execute the test script
 # 

     $test_results = `$perl_executable tgB1.t`;
     $snl->fout('tgB1.txt', $test_results);
 $s->scrub_probe($s->scrub_file_line($test_results))

 # '1..2
 #ok 1
 #not ok 2
 ## Test 2 got: 'U1[1] 80
 #N[2] 5 1
 #' (xxxx.t at line 000)
 ##   Expected: 'U1[1] 80
 #N[2] 5 2
 #'
 ## Failed : 2
 ## Passed : 1/2 50%
 #'
 #
     #####
     # Make sure there is no residue outputs hanging
     # around from the last test series.
     #
     @outputs = bsd_glob( 'tg*1.*' );
     unlink @outputs;
     unlink 'tgA1.pm';
     unlink 'tgB1.pm';
     unlink 'tgC1.pm';

     #####
     # Suppress some annoying warnings
     #
     sub __warn__ 
     { 
        my ($text) = @_;
        return $text =~ /STDOUT/;
        CORE::warn( $text );
     };

=head1 QUALITY ASSURANCE

The module "t::Test::STDmaker::STDmaker" is the Software
Test Description file (STD) for the "Test::STDmaker".
module. This module contains all the information
necessary for this module to verify that
this module meets its requirements.
In other words, this module will verify
itself. This is valid because if something
is wrong with this module, it will not be
able to verify itself. And if it cannot
verify itself, it cannot verify that another
module meets its requirements.

To generate all the test output files, 
run the generated test script,
run the demonstration script,
execute the following in any directory:

 tmake -verbose -demo -report -run -pm=t::Test::STDmaker::STDmaker

Note that F<tmake.pl> must be in the execution path C<$ENV{PATH}>
and the "t" directory on the same level as the "lib" that
contains the "Test::STDmaker" module. The distribution file
contains a copy of the F<tmake.pl> test make script.

And yes, the <Test::STDmaker> program module generates the test script to test
the <Test::STDmaker> program module which is perfectly legal. 
If <Test::STDmaker> is not working, <Test::STDmaker> will fail to
generate a valid test script.

=head1 NOTES

=head2 Binding Requirements

In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 Author

The author, holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright

copyright © 2003 SoftwareDiamonds.com

=head2 License

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
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

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
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

=item L<Test::Tech|Test::Tech> 

=item L<Test|Test>

=item L<Data::Secs2|Data::Secs2> 

=item L<Data::Str2Num|Data::Str2Num> 

=item L<Test::Harness|Test::Harness> 

=item L<Test::STD::PerlSTD|Test::STD::PerlSTD>

=item L<Test::STDmaker::STD|Test::STDmaker::STD>

=item L<Test::STDmaker::Verify|Test::STDmaker::Verify>

=item L<Test::STDmaker::Demo|Test::STDmaker::Demo>

=item L<Test::STDmaker::Check|Test::STDmaker::Check>

=item L<Software Test Description|Docs::US_DOD::STD>

=item L<Specification Practices|Docs::US_DOD::STD490A>

=item L<Software Development|Docs::US_DOD::STD2167A>

=back

=cut

### end of file ###

