package Tivoli::AccessManager::PDAdmin::TabComplete::rsrccred;
$Tivoli::AccessManager::PDAdmin::TabComplete::rsrccred::VERSION = '1.11';

use strict;
use warnings;

use Data::Dumper;
use Tivoli::AccessManager::PDAdmin::TabComplete::utils;

sub _showall {
    my ($tam,$word) = @_;
    my @ret;

    push @ret, _list_gso($tam,'web',$word);
    push @ret, _list_gso($tam,'group',$word);

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

    if ( $tok_cnt == 2 ) {
	return grep { /^$word/ } qw/list show create delete modify/;
    }

    $tok_cnt++ if $command eq 'list';
    if ( $tok_cnt == 3 ) {
	return _showall($tam,$word);
    }
    elsif ( $tok_cnt == 4 ) {
	return 'user';
    }
    elsif ( $tok_cnt == 5 ) {
	return _list_group_or_user($tam,'user',$word);
    }

    return '-group' if $tok_cnt == 10 and ($command eq 'create' or $command eq 'modify');
    if ( $command eq 'create' ) {
	return 'id'   if $tok_cnt == 6;
	return 'pswd' if $tok_cnt == 8;
    }
    if ( $command eq 'delete' ) {
	return '-group' if $tok_cnt == 6;
    }
    if ( $command eq 'modify' ) {
	if ( $tok_cnt == 6 ) {
	    return grep(/^$word/,qw/id pswd/);
	}
	elsif ( $tok_cnt == 8 ) {
	    return $tokref->[5] eq 'id' ? 'pswd' : 'id';
	}
    }

    return ();
}
    
1;
