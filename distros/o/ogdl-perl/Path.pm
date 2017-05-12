# Path.pm
# author 'Rolf Veen'
# license zlib
# date 20030609

package OGDL::Path;

use strict;
use warnings;

our $VERSION = '0.01';

# takes a string and returns a list
# with the path elements
sub path2list
{
    my @l;
    my $s = $_[0];
    my $len = length($s);
    my $state = 0;
    my $ix = 0;
    my $i=0; 
    my $j=0;
    my $n=0;
    
    foreach my $c (split //, $s) {
  
        if ($state == 0) {
            if ( $c eq "." ) {      
                if ($n != 0) { $l[$ix++] = substr($s,$j,$i-$j); }           
                $l[$ix++] = ".";
                $j = $i+1;
                $n = 0;
            }
            elsif ( $c eq "\"") {
                $state = 1;
            }
            elsif ( $c eq "'") {
                $state = 2;
            }
            elsif ( ($c eq "[") && ($n > 0)) {          
                $l[$ix++] = substr($s,$j,$i-$j);
                $j = $i;
                $state = 3;
                $n = 0;
            } 
            else { $n++; }         
        }
        elsif ( ($state == 1) && ($c eq '"')) {
            $state = 0;  
            $n++;     
        }
        elsif ( ($state == 2) && ($c eq '\'')) {
            $state = 0;
            $n++;       
        }
        elsif ( ($state == 3) && ($c eq ']') ) {
            $l[$ix++] = substr($s,$j,$i-$j+1);
            $j = $i+1;
            $state = 0;
            $n = 0;
        }
        $i++;
    }
    $l[$ix++] = substr($s,$j,$i-$j);

    return @l;
}
1;
__END__
