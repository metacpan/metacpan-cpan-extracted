#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  Test::STDmaker::tg1;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION);

$VERSION = '0.06';

1

__END__

=head1 Requirements

=head2 Capability-A 

The requriements are as follows:

=over 4

=item capability-A [1]

This subroutine shall[1] have feature 1. 

=item capability-A [2]

This subroutine shall[2] have feature 2.

=back

=head2 Capability-B
 
=over 4

=item Capability-B [1]

This subroutine shall[1] have feature 1.

=item Capability-B [2]

This subroutine shall[2] have feature 2.

=item Capability-B [3]

This subroutine shall[3] have feature 3.

=back

=head1 DEMONSTRATION

 #########
 # perl tgA1.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     #########
     # For "TEST" 1.24 or greater that have separate std err output,
     # redirect the TESTERR to STDOUT
     #
     tech_config( 'Test.TESTERR', \*STDOUT );

 ##################
 # Quiet Code
 # 

 'hello world'

 # 'hello world'
 #

 ##################
 # Pass test
 # 

 my $x = 2
 my $y = 3
 $x + $y

 # 5
 #

 ##################
 # Todo test that passes
 # 

 $y-$x

 # 1
 #

 ##################
 # Test that fails
 # 

 $x+4

 # 6
 #

 ##################
 # Skipped tests
 # 

 ##################
 # Todo Test that Fails
 # 

 $x*$y*2

 # 12
 #

 ##################
 # demo only
 # 

 $x

 # 2
 #

 ##################
 # Failed test that skips the rest
 # 

 $x + $y

 # 5
 #

 ##################
 # A test to skip
 # 

 $x + $y + $x

 # 7
 #

 ##################
 # A not skip to skip
 # 

 $x + $y + $x + $y

 # 10
 #

 ##################
 # A skip to skip
 # 


=head1 SEE ALSO

http://perl.SoftwareDiamonds.com

