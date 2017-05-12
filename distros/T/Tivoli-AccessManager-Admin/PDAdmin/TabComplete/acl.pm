package Tivoli::AccessManager::PDAdmin::TabComplete::acl;
$Tivoli::AccessManager::PDAdmin::TabComplete::acl::VERSION = '1.11';

use strict;
use warnings;

use Tivoli::AccessManager::PDAdmin::TabComplete::utils;

sub _get_acl_info {
    my ($acl, $request) = @_;
    my ($resp, @stuff);

    if ( $request eq 'group' ) {
	$resp = $acl->listgroups;
    }
    elsif ( $request eq 'user' ) {
	$resp = $acl->listusers;
    }

    unless ( $resp->isok ) {
	print "Error getting the $request for \"" . $acl->name . "\"\n";
	return 1;
    }
    return sort $resp->value;
}

sub _listACL {
    my ($tam,$word) = @_;
    my $resp;

    $resp = Tivoli::AccessManager::Admin::ACL->list($tam);
    if ( $resp->isok ) {
	return grep { /^$word/ } $resp->value;
    }
    else {
	return ($resp->messages);
    }
}

sub _aclmodSET {
    my ($tam, $tokref, $word, $tok_cnt) = @_;

    my @foo = qw/any-other description group user unauthenticated attribute/;

    if ($tok_cnt == 5) {
	return grep { /^$word/ } @foo;
    }
    return if $tok_cnt > 6;

    my $subsub = $tokref->[4];

    if ( $subsub eq 'group' or $subsub eq 'user' ) {
	return _list_group_or_user($tam,$subsub,$word);
    }
    return ();
}

sub _aclmodREM {
    my ($tam, $tokref, $word, $tok_cnt) = @_;
    if ($tok_cnt == 5) {
	return grep { /^$word/ } qw/any-other group unauthenticated user/;
    }

    my $subsub = $tokref->[4];
    if ( $subsub eq 'group' or $subsub eq 'user' ) {
	my $acl = Tivoli::AccessManager::Admin::ACL->new( $tam, name => $tokref->[2] );
	return grep { /^$word/ }  _get_acl_info($acl,$subsub);
    }
}

sub _aclmodDEL {
    my ($tam, $tokref, $word, $tok_cnt) = @_;
    my $resp;

    if ( $tok_cnt == 5 ) {
	return qw/attribute/;
    }
    if ( $tok_cnt == 6 ) {
	my $acl = Tivoli::AccessManager::Admin::ACL->new( $tam, name => $tokref->[2] );

	$resp = $acl->attributes;
	unless ( $resp->isok ) {
	    print "Error retrieving attributes for \"$tokref->[2]\"\n";
	    return 1;
	}
	return grep { /^$word/ } keys %{$resp->value};
    }

    if ( $tok_cnt == 7 ) {
	my $attname = $tokref->[5];
	my $acl = Tivoli::AccessManager::Admin::ACL->new( $tam, name => $tokref->[2] );

	$resp = $acl->attributes;
	my $href = $resp->value;
	if ( defined( $href->{$attname} ) ) {
	    return grep { /^$word/ } @{$href->{$attname}};
	}
    }
}

sub _modACL {
    my ($tam, $tokref, $word, $buffer, $start,$tok_cnt) = @_;
    my ($subcom, $resp);

    # Handle the sub command completion first.
    if ($tok_cnt == 4) {
	return grep { /^$word/ } qw/description remove set delete/;
    }
    # Now we need to parse out the subcommand
    $subcom = $tokref->[3];

    if ( $subcom eq 'set' ) {
	return _aclmodSET($tam, $tokref, $word, $tok_cnt);

    }

    if ( $subcom eq 'remove' ) {
	return _aclmodREM($tam, $tokref, $word, $tok_cnt);
    }

    if ( $subcom eq 'delete' ) {
	return _aclmodDEL($tam, $tokref, $word, $tok_cnt);
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
         ($command eq 'attach' and $tok_cnt ==4)) {

	return _listACL($tam,$word);
    }

    # There is no completion possible for the list, create command
    # I cannot complete a description modify
    if ( $command eq 'create' or $command eq 'list' or $command eq 'description' ) {
	return ();
    }

    # The modify logic is sooo nasty, I split it out into a sub
    if ( $command eq 'modify' ) {
	return _modACL(@_,$tok_cnt);
    }

    # I handled all of the other situations for attach earlier.
    # Therefore, I do not need to worry about the token count -- the only way
    # I can get here is if I am browsing the object space
    if ( $command eq 'attach' or $command eq 'detach' ) {
	return _listObj($tam,$word);
    }
    return ();
}
1;
