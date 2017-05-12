package Tivoli::AccessManager::PDAdmin::TabComplete::pop;
$Tivoli::AccessManager::PDAdmin::TabComplete::pop::VERSION = '1.11';

use strict;
use warnings;

use Tivoli::AccessManager::PDAdmin::TabComplete::utils;

sub _listPOP {
    my ($tam,$word) = @_;
    my $resp;

    $resp = Tivoli::AccessManager::Admin::POP->list($tam);
    if ( $resp->isok ) {
	return grep { /^$word/ } $resp->value;
    }
    else {
	return ($resp->messages);
    }
}

sub _modPOP {
    my ($tam,$tokref,$word,$buffer,$start,$tok_cnt) = @_;
    my ($subcom,$resp);
    my @validcom = qw/audit-level description ipauth qop tod-access warning attribute/;

    my $pop = Tivoli::AccessManager::Admin::POP->new( $tam, name => $tokref->[2]);

    $subcom = $tokref->[4] || '';

    if ( $tok_cnt == 4 ) {
	return grep { /^$word/ } qw/set delete/;
    }

    if ( $tok_cnt == 5 ) {
	return "attribute" if $tokref->[3] eq 'delete';
	return grep { /^$word/ } @validcom;
    }

    if ($tokref->[3] eq 'delete') {
	if ( $word =~ /\w/ ) {
	    $resp = $pop->attributes;
	    my $href = $resp->value;
	    if ( $tok_cnt == 6 ) {
		return grep { /^$word/ } sort keys %{$href};
	    }
	    elsif ( $tok_cnt == 7 and defined $href->{$tokref->[5]} ) {
		return grep { /^$word/ } sort @{$href->{$tokref->[5]}};
	    }
	}
    }
    elsif ( $subcom eq 'audit-level' ) {
	return grep { /^$word/ } qw/all none permit deny error admin/;
    }
    elsif ( $subcom eq 'ipauth' ) {
	if ($tok_cnt == 6 ) {
	    return grep { /^$word/ } qw/add anyothernw remove forbidden/;
	}
	elsif ( $tokref->[5] eq 'remove' ) {
	    if ( $tok_cnt == 7 ) {
		$resp = $pop->ipauth;
		return grep { /^$word/ } sort keys %{$resp->value};
	    }
	    elsif ( $tok_cnt == 8 ) {
		$resp = $pop->ipauth;
		return $resp->value->{$tokref->[6]}{NETMASK};
	    }
	}
    }
    elsif ( $subcom eq 'warning' ) {
	$resp = $pop->warnmode;
	return $resp->value ? "no" : "yes";
    }
    elsif ( $subcom eq 'qop' ) {
	return grep { /^$word/ } qw/none integrity privacy/;
    }
    elsif ( $subcom eq 'attribute' and $tok_cnt == 6 and $word =~ /\w/ ) {
	$resp = $pop->attributes;
	return grep { /^$word/ } sort keys %{$resp->value};
    }
    return ();
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

	return _listPOP($tam,$word);
    }

    # There is no completion possible for the list, create command
    # I cannot complete a description modify
    return () if $command eq 'create' or $command eq 'list';

    return _modPOP(@_, $tok_cnt) if $command eq 'modify';

    # I handled all of the other situations for attach earlier.
    # Therefore, I do not need to worry about the token count -- the only way
    # I can get here is if I am browsing the object space
    if ( $command eq 'attach' or $command eq 'detach' ) {
	return _listObj($tam,$word);
    }
    return ();
}
1;
