package Tivoli::AccessManager::PDAdmin::TabComplete::rsrcgroup;
$Tivoli::AccessManager::PDAdmin::TabComplete::rsrcgroup::VERSION = '1.11';

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
 
    if ( $command eq 'delete' or
	 $command eq 'show'   or
	 ($command eq 'modify' and $tok_cnt == 3) ) {
	return _list_gso($tam,'group',$word);
    }
    elsif ( $command eq 'modify' ) {
	if ( $tok_cnt == 4 ) {
	    return grep { /^$word/ } qw/add remove/;
	}

	my %interm = map { $_ => 1 } _list_gso($tam,'web',$word);
	for ( @$tokref[3,-1] ) {
	    delete $interm{$_} if defined $interm{$_};
	}
	return sort keys %interm;
    }

    return ();
}
    
1;
