#Template for writing a analyse PlugIn for Combine
#See documentation at http://combine.it.lth.se/documentation/

package Combine::myAnalyse; #Change to your own module name

use Combine::XWI; #Mandatory

#API:
#  a subroutine named 'analyse' taking a XWI-object as in parameter
#    use $xwi->robot_add($name, $value);
#    to a tag with name "$name" and value "$value"

sub analyse { 
  my ($self,$xwi) = @_;
  $xwi->robot_add('MyTag', 'MyTagValue');
  return;
}

1;
