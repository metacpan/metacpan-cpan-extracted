package Tivoli::AccessManager::PDAdmin::TabComplete::user;
$Tivoli::AccessManager::PDAdmin::TabComplete::user::VERSION = '1.11';

use strict;
use warnings;

use Tivoli::AccessManager::PDAdmin::TabComplete::utils;

sub _modUser {
    my ($tam, $tokref, $word, $buffer, $start, $tok_cnt) = @_;
    my ($resp,$subcmd);
    my @valid = qw/account-valid description groups gsouser password password-valid/;

    if ( $tok_cnt == 4 ) {
	return grep { /$word/ } @valid;
    }

    $subcmd = $tokref->[3];

    return if $subcmd eq 'description' or $subcmd eq 'password';

    # A simple toggle.  If is yes, only allow no and vice versa
    if ( $tok_cnt == 5 and 
	($subcmd eq 'account-valid' or
         $subcmd eq 'gsouser'       or
         $subcmd eq 'password-valid')) {

	my $user = Tivoli::AccessManager::Admin::User->new($tam, name => $tokref->[2]);
	next unless $user->exist;

	if ($subcmd eq 'account-valid') {
	    $resp = $user->accountvalid;
	}
	elsif ($subcmd eq 'gsouser') {
	    $resp = $user->gsouser;
	}
	elsif ($subcmd eq 'password-valid') {
	    $resp = $user->passwordvalid;
	}
	return $resp->value ? "no" : "yes";
    }

    if ( $subcmd eq 'groups' ) {
	if ($tok_cnt == 5) {
	    return grep { /^$word/ } qw/add remove/;
	}
	if ( $tok_cnt >= 6 ) {
	    my $user = Tivoli::AccessManager::Admin::User->new($tam, name => $tokref->[2]);
	    my %interm;
	    if ( $tokref->[4] eq 'add' ) {
		%interm = map {$_ => 1} _list_group_or_user($tam,"group",$word);
	    }
	    elsif ( $tokref->[4] eq 'remove' ) {
		$resp = $user->groups;
		%interm = map {$_ => 1} $resp->value;
	    }

	    for ( @$tokref[5,-1] ) {
		last unless defined($_) and $_;
		delete $interm{$_} if defined($interm{$_});
	    }
	    return grep {/^$word/} sort(keys %interm);
	}
    }
    return ();
}

sub _addUser {
    my ($tam, $tokref, $word, $buffer, $start, $tok_cnt) = @_;
    my ($resp);

    # If you are on the DN part, do that magic
    if ( $tok_cnt == 4 ) {
	return _guessDN($tam,'user',$word,$tokref->[2])
    }
    # User first name -- this may not be an optimal guess...
    elsif ( $tok_cnt == 5 ) {
	return $tokref->[2];
    }
    # No reasonable way to guess the SN
    elsif ( $tok_cnt == 6 ) {
	return;
    }
    # Password
    elsif ( $tok_cnt == 7 ) {
	return '?';
    }
    # Groups
    elsif ( $tok_cnt >= 8 ) {
	my %interm;

	%interm = map { $_ => 1} _list_group_or_user($tam,"group",$word);
	for ( @$tokref[8,-1] ) {
	    delete $interm{$_} if defined($interm{$_});
	}
	return sort(keys %interm);
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
  
    if (  $command eq 'show' or
	 ($command eq 'show_groups' and $tok_cnt == 3) or
	 ($command eq 'modify' and $tok_cnt == 3) or
         ($command eq 'delete' and $tok_cnt == 3)) {
	return _list_group_or_user($tam,"user",$word);
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
	return _guessDN($tam, 'user', $word, $tokref->[2]);
    }

    if ( $command eq 'create' ) {
	return _addUser(@_, $tok_cnt);
    }

    if ( $command eq 'modify' ) {
	return _modUser(@_,$tok_cnt);
    }

    return ();
}

1;
