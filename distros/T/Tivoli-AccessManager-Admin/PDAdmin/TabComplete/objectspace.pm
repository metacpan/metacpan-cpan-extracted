package Tivoli::AccessManager::PDAdmin::TabComplete::objectspace;
$Tivoli::AccessManager::PDAdmin::TabComplete::objectspace::VERSION = '1.11';

use strict;
use warnings;

use Tivoli::AccessManager::PDAdmin::TabComplete::utils;

sub complete {
    my ($tam, $tokref, $word, $buffer, $start) = @_;
    my ($command, $subcom,$resp, $tok_cnt);

    # There is some magic here.  Basically, I need to know if there is a word
    # under the cursor or not.  If there is, use the number of tokens as my
    # switch.  If there isn't, it means we are trying to complete an entire
    # sub command (e.g., acl show <tab>).  I am cheating and just adding one
    # to the token count if this case.  It *should* simplify the logic later

    $tok_cnt = @{$tokref} + (not $word);

    # I need to know what they are doing -- this is going to be the second
    # part of the command and will assume values like create, delete, etc.
    $command = $tokref->[1];
  
    if (  $command eq 'delete' ) { 
	return _listObj($tam,$word);
    }
    return ();
}

1;
