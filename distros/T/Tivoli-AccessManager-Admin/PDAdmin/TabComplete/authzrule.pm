package Tivoli::AccessManager::PDAdmin::TabComplete::authzrule;
$Tivoli::AccessManager::PDAdmin::TabComplete::authzrule::VERSION = '1.11';

use strict;
use warnings;

use Tivoli::AccessManager::PDAdmin::TabComplete::utils;

sub _listAuthz {
    my ($tam, $word) = @_;
    my $resp = @_;

    $resp = Tivoli::AccessManager::Admin::AuthzRule->list($tam, pattern => $word);
    if ( $resp->isok ) {
	return $resp->value;
    }
    else {
	return ($resp->messages);
    }
}

# I should likely create a filesystem browser, but that is gonna be a PITA.
# It will annoy me enough to do it later, but not right now.
sub _ruletext {
    my ($tam,$tokref,$word,$tok_cnt) = @_;

    return $tok_cnt > 5 ? () : '-rulefile';
}

sub _modAuthz {
    my ($tam, $tokref, $word, $buffer, $start,$tok_cnt) = @_;
    my ($subcom, $resp);

    # Handle the sub command completion first.
    if ($tok_cnt == 4) {
	return grep { /^$word/ } qw/description failreason ruletext/;
    }
    # Now we need to parse out the subcommand
    $subcom = $tokref->[3];

    if ( $subcom eq 'ruletext' ) {
	return _ruletext($tam, $tokref, $word, $tok_cnt);
    }
    else {
	return ();
    }
}

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
  
    if (  $command eq 'delete' or 
	  $command eq 'find' or 
	  $command eq 'show' or
	 ($command eq 'modify' and $tok_cnt == 3) or
         ($command eq 'attach' and $tok_cnt == 4)) {
	return _listAuthz($tam,$word);
    }

    # I think I need to handle delete seperately -- there is just a bit too
    # much weirdness
    if ( $command eq 'detach' ) {
	if ( $tok_cnt == 3 ) {
	    if ( $word =~ /^-/ ) {
		return "-all";
	    }

	    my @returns = ();
	    unless ( rindex($word,"/") ) {
		push @returns, "-all";
	    }
	    push @returns, _listObj($tam,$word);
	    return @returns;
	}
	elsif ( $tok_cnt == 4 and $tokref->[2] eq '-all' ) {
	    return _listAuthz($tam,$word);
	}
    }

    # There is no completion possible for the list of create command
    # I cannot complete a description modify
    if ( $command eq 'list' ) {
	return ();
    }

    # The modify logic is sooo nasty, I split it out into a sub
    if ( $command eq 'modify' ) {
	return _modAuthz(@_,$tok_cnt);
    }

    # I handled all of the other situations for attach earlier.
    # Therefore, I do not need to worry about the token count -- the only way
    # I can get here is if I am browsing the object space
    if ($command eq 'attach') {
	my $prefix  = substr( $word, 0, rindex($word,"/") );

	$prefix = "/" if length($prefix) == 0;
	return _browserObjSp($tam,$word,$prefix);
    }
    return ();
}

1;
