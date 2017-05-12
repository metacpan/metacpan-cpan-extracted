package Tivoli::AccessManager::PDAdmin::TabComplete::group;
$Tivoli::AccessManager::PDAdmin::TabComplete::group::VERSION = '1.11';

use strict;
use warnings;

use Tivoli::AccessManager::PDAdmin::TabComplete::utils;

sub _modGroup {
    my ($tam, $tokref, $word, $buffer, $start, $tok_cnt) = @_;
    my ($resp,$subcmd, @ret);

    if ( $tok_cnt == 4 ) {
	return grep { /$word/ } qw/add description remove/;
    }

    $subcmd = $tokref->[3];

    return if $subcmd eq 'description';
    if ( $subcmd eq 'add' ) {
	$word .= "*" unless $word =~ /\*/;
	$resp = Tivoli::AccessManager::Admin::User->list( $tam, pattern => $word );
	@ret = $resp->value if $resp->isok;
    }
    else {
	my $grp = Tivoli::AccessManager::Admin::Group->new( $tam, name => $tokref->[2] );
	$resp = $grp->members();
	if ( $resp->isok ) {
	    @ret = grep /^$word/, $resp->value;
	}
    }
    return @ret;
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
	  $command eq 'show' or
	 ($command eq 'show_members' and $tok_cnt == 3) or
	 ($command eq 'modify' and $tok_cnt == 3) or
         ($command eq 'delete' and $tok_cnt == 3)) {
	return _list_group_or_user($tam,"group",$word);
    }

    # There is no completion possible for the list or create 
    # I think import could be a weird little function.
    if ( $command eq 'list'    or 
	 $command eq 'list_dn' or
	 ($command eq 'create' and $tok_cnt < 4) or
         ($command eq 'import' and $tok_cnt == 3) ) {
	return ();
    }

    if ( $command eq 'import' ) {
	# But I can do some wickedly funky stuff to complete the the DN
	return _guessDN($tam, 'group', $word, $tokref->[2]);
    }

    if ( $command eq 'create' ) {
	# If you are on the DN part, do that magic
	if ( $tok_cnt == 4 ) {
	    return _guessDN($tam,'group',$word,$tokref->[2])
	}
	elsif ( $tok_cnt == 5 ) {
	    return $tokref->[2];
	}
	else {
	    return;
	}
    }

    if ( $command eq 'modify' ) {
	return _modGroup(@_,$tok_cnt);
    }

    return ();
}

1;
