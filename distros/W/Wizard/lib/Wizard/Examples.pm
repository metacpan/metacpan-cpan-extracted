# -*- perl -*-

use strict;

use Wizard::State ();
use Wizard::SaveAble ();

package Wizard::Examples;

@Wizard::Examples::ISA     = qw(Wizard::State);
$Wizard::Examples::VERSION = '0.01';



sub Action_Reset {
    my($self, $wiz) = @_;

    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => 'Wizard Examples Menu'],
     ['Wizard::Elem::Submit', 'value' => 'Apache Wizard Menu',
      'name' => 'Wizard::Examples::Apache::Action_Reset',
      'id' => 1],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'ISDN Wizard Menu',
      'name' => 'Wizard::Examples::ISDN::Action_Reset',
      'id' => 2],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Exit Wizard',
      'id' => 99]);
}



1;
