#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.06';   # automatically generated file
$DATE = '2004/04/13';

use Cwd;
use File::Spec;

BEGIN {
   use FindBin;
   use File::Spec;
   use Cwd;
   use vars qw( $__restore_dir__ );
   $__restore_dir__ = cwd();
   my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
   chdir $vol if $vol;
   chdir $dirs if $dirs;
   use lib $FindBin::Bin;

   # Add the directory with "Test.pm" version 1.24 to the front of @INC
   # Thus, load Test::Tech, will find Test.pm 1.24 first
   unshift @INC, File::Spec->catdir ( cwd(), 'V001024'); 

   require Test::Tech;
   Test::Tech->import( qw(demo) );
}

END {
   # Restore working directory and @INC back to when enter script
   @INC = @lib::ORIG_INC;
   chdir $__restore_dir__;
}

print << 'MSG';

 ~~~~~~ Demonstration overview ~~~~~
 
Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

MSG

demo(   
"my\ \$x\ \=\ 2"); # typed in command           
my $x = 2; # execution

demo(   
"my\ \$y\ \=\ 3"); # typed in command           
my $y = 3; # execution

demo(   
"\$x\ \+\ \$y", # typed in command           
$x + $y); # execution


demo(   
"\(\$x\+\$y\,\$y\-\$x\)", # typed in command           
($x+$y,$y-$x)); # execution


demo(   
"\(\$x\+4\,\$x\*\$y\)", # typed in command           
($x+4,$x*$y)); # execution


demo(   
"\$x\*\$y\*2", # typed in command           
$x*$y*2 # execution
) unless     1; # condition for execution                            

demo(   
"\$x\*\$y\*2", # typed in command           
$x*$y*2 # execution
) unless     0; # condition for execution                            

demo(   
"\$x", # typed in command           
$x); # execution


demo(   
"\ \ \ \ my\ \@expected\ \=\ \(\'200\'\,\'201\'\,\'202\'\)\;\
\ \ \ \ my\ \$i\;\
\ \ \ \ for\(\ \$i\=0\;\ \$i\ \<\ 3\;\ \$i\+\+\)\ \{"); # typed in command           
    my @expected = ('200','201','202');
    my $i;
    for( $i=0; $i < 3; $i++) {; # execution

demo(   
"\$i\+200", # typed in command           
$i+200); # execution


demo(   
"\$i\ \+\ \(\$x\ \*\ 100\)", # typed in command           
$i + ($x * 100)); # execution


demo(   
"\ \ \ \ \}\;"); # typed in command           
    };; # execution

demo(   
"\$x\ \+\ \$y", # typed in command           
$x + $y); # execution


demo(   
"\$x\ \+\ \$y\ \+\ \$x", # typed in command           
$x + $y + $x); # execution


demo(   
"\$x\ \+\ \$y\ \+\ \$x\ \+\ \$y", # typed in command           
$x + $y + $x + $y # execution
) unless     0; # condition for execution                            

demo(   
"\$x\ \+\ \$y\ \+\ \$x\ \+\ \$y\ \+\ \$x", # typed in command           
$x + $y + $x + $y + $x # execution
) unless     1; # condition for execution                            


__END__

=head1 COPYRIGHT

This STD is public domain.

## end of test script file ##

=cut

