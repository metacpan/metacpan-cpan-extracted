use strict;
use warnings;
use Test::More;
use Unix::SavedIDs;
use Unix::SetUser;
use Data::Dumper;


if ( $< != 0 ) {
	plan skip_all => "Only root can change user, so please run these tests as root.";
}
#else {
#	plan tests => 26;
#}

my(%exist,%nonexist);

foreach my $type ('uid','gid','user','group') {
	$exist{$type} = [];
	$nonexist{$type} = [];
}

TRYUID: foreach my $uid (1 .. 60000) {
	if ( $uid == $< ) {
		# hey, that's me!
		next;
	}
	my $gid = (getpwuid($uid))[3];
	if ( defined($gid) ) {
			if ($gid == 0) {
				next;
			}
			push(@{$exist{uid}},$uid);
			push(@{$exist{user}},(getpwuid($uid))[0]);
			push(@{$exist{gid}},$gid);
			push(@{$exist{group}},(getgrgid($gid))[0]);
	} else {
		push(@{$nonexist{uid}},$uid);
	}
	if ( !getgrgid($uid) ) {
		push(@{$nonexist{gid}}, $uid);
	}
	if ( $uid >= 60000 ) {
		die "Failed to find 5 existant and nonexistant uids and gids "
			."after trying 60000 numbers.  Yikes!";
	}
	foreach my $state (\%exist,\%nonexist) {
		my $statelabel = 'exists';
		if ( $state eq \%nonexist ) {
			$statelabel = 'nonexistant';
		}
		foreach my $type ('uid','gid') {
		   	if ( !defined($state->{$type}) ) {
				next TRYUID;
			}
			if ( @{$state->{$type}} < 5 ) {
				next TRYUID;
			}
		}
	}
	last;
}

my @alphabet = ('A' .. 'Z');
for my $try ( 0 .. 1000 ) {
	my $randstr = '';
	for my $letter ( 0 .. 8 ) {
		$randstr .= $alphabet[int(rand(26))];
	}
	if ( !getpwnam($randstr) ) {
		push(@{$nonexist{user}},$randstr);
	}
	if ( !getgrnam($randstr) ) {
		push(@{$nonexist{group}},$randstr);
	}
	if ( @{$nonexist{group}} >= 5  && 
		 @{$nonexist{user}}  >= 5 )
	{
		last;
	}
	if ( $try >= 1000 ) {
		die "Failed to find five unused usernames and groupnames in 1000 "		
			."random strings!  Wow!";
	}
}

print "\n  --  Users and Groups Used During Tests  --\n\n";
print "Exising Users/Groups:\n";
map { print '  '.$_.' => '.join(", ",@{$exist{$_}})."\n" } sort(keys(%exist));
print "\nNon-Exising Users/Groups:\n";
map { print '  '.$_.' => '.join(", ",@{$nonexist{$_}})."\n" } sort(keys(%nonexist));
print "\n";

my @tests = (
	[ 0, "1 Arg", $exist{user}->[0] ],
	[ 0, "2 Arg", $exist{user}->[0],$exist{group}->[0] ],
	[ 0, "3 Arg", $exist{user}->[0],$exist{group}->[0],$exist{group}->[1] ],
	[ 0, "3 Arg no primary group", $exist{user}->[0],undef,$exist{group}->[0] ],
	[ 0, "4 Arg", $exist{user}->[0],$exist{group}->[0],$exist{group}->[1],$exist{group}->[2] ],
	[ 0, "1 Arg Numeric", $exist{uid}->[0] ],
	[ 0, "2 Arg Numeric", $exist{uid}->[0],$exist{gid}->[0] ],
	[ 0, "3 Arg Numeric", $exist{uid}->[0],$exist{gid}->[0],$exist{gid}->[1] ],
	[ 0, "3 Arg Numeric no primary gid", $exist{uid}->[0],undef,$exist{gid}->[0] ],
	[ 0, "4 Arg Numeric", $exist{uid}->[0],$exist{gid}->[0],$exist{gid}->[1],$exist{gid}->[2] ],
	[ 0, "Duplicates in Sup Groups", $exist{uid}->[0],$exist{gid}->[0],$exist{group}->[1],$exist{group}->[1] ],
	[ 0, "Duplicates in Sup Gids", $exist{uid}->[0],$exist{gid}->[0],$exist{gid}->[1],$exist{gid}->[1] ],
	[ 0, "Primary Gid also in Sup Gids", $exist{uid}->[0],$exist{gid}->[0],$exist{gid}->[0] ],
	[ 0, "Primary Group also in Sup Groups", $exist{uid}->[0],$exist{group}->[0],$exist{group}->[0] ],
	[ 0, "Lots of Groups", $exist{uid}->[0],$exist{group}->[0],
		$exist{group}->[1], $exist{group}->[2], $exist{group}->[3] ],
	[ 0, "Lots of Groups with duplicates", $exist{uid}->[0],$exist{group}->[0],
		$exist{group}->[1], $exist{group}->[2], $exist{group}->[1] ],
	[ 0, "Lots of Gids", $exist{uid}->[0],$exist{gid}->[0],
		$exist{gid}->[1], $exist{gid}->[2], $exist{gid}->[3] ],
	[ 0, "Lots of Gids with duplicates", $exist{uid}->[0],$exist{gid}->[0],
		$exist{gid}->[1], $exist{gid}->[2], $exist{gid}->[1] ],
	
	[ 1, "Croak when user is undef" ],
	[ 1, "Croak when user doesn't exist", $nonexist{user}->[0]],
	[ 1, "Croak when uid doesn't exist", $nonexist{uid}->[0]],
	[ 1, "Croak when group doesn't exist", $exist{user}->[0],$nonexist{group}->[0] ],
	[ 1, "Croak when gid doesn't exist", $exist{user}->[0],$nonexist{gid}->[0] ],
	[ 1, "Croak when supplimental group doesn't exist", $exist{user}->[0],undef,
		$nonexist{group}->[0] ],
	[ 1, "Croak when supplimental gid doesn't exist", $exist{user}->[0],undef,
		$nonexist{gid}->[0] ],
	[ 1, "Croak when supplimental group specified as undef", $exist{user}->[0],
		undef,undef ],
	
); 

for my $test (@tests) {
	my $croak_good = shift(@$test);
	my $description = shift(@$test);

	pipe(my $from, my $to);
	my $orig_handle = select();
	select($to);
	$| = 1;
	select($from);
	$| = 1;
	select($orig_handle);

	my $pid = fork();
	if ( !defined($pid) ) {
		die "Failed to fork!";
	}
	if ( $pid == 0 ) {
		close($from);
		if ( @$test ) {
			no warnings;
			print "set_user(".join(", ",@$test).")\n";
		}
		eval{ set_user(@$test) };
		if ( $@ ) {
			chomp($@);
			print $to $@;
			exit;
		}
		my @errs;
		my $uid = to_int(shift(@$test));
		if ( $< != $uid ) {
			push(@errs,"Failed to change uid to $uid");
		}
		if ( $> != $uid ) {
			push(@errs,"Failed to change euid to $uid");
		}
		my $prim_gid = shift(@$test);
		if ( !defined($prim_gid) ) {
			$prim_gid = (getpwuid($uid))[3];
		}
		else {
			$prim_gid = to_int($prim_gid,'group');
		}
		my @sup_gids;
		my $gid_string = $prim_gid;
		foreach my $group (@$test) {  
			$gid_string .= ' '.to_int($group,'group');
		}
		if ( !@$test ) {
			$gid_string .= ' '.$prim_gid;
		}
		if ( $( !~ /^(\d+)/ ) {
		 	die "Your system returned a gid that wasn't an int: '$('";
		}
		my $now_prim_gid = $1;
		if ( $now_prim_gid != $prim_gid ) {
			push(@errs,"Primary Group is '$now_prim_gid' not '$prim_gid'");
		}
		if ( $) ne $gid_string ) {
			my $now = join(' ',sort(split(' ',$))));
			my $want = join(' ',sort(uniqe(split(' ',$gid_string))));
			if ( $now ne $want ) {
				push(@errs,"Effective and supplimental are '$)' not "
							."'$gid_string'");
			}
		}
		my $suid = (getresuid())[2];
		if ( $suid != $uid ) {
			push(@errs,"Saved Uid is $suid, not $uid");
		}
		my $sgid = (getresgid())[2];
		if ( $sgid != $prim_gid ) {
			push(@errs,"Saved gid is $sgid, not $prim_gid");
		}
		#print "UID = $<, EUID = $>, GIDS = $(, EGIDS = $(\n";
		if ( @errs ) {
			print $to join(', ',@errs)."\n";
			exit;
		}
		print $to '';
		exit;
	}
	close($to);
	my $err = <$from>;
	if ( !defined($err) ) {
		$err = '';
	}
	waitpid($pid,0);
	if ( $croak_good ) {
		ok( $err ne '' , $description) || diag("Should have croaked!");
	} 
	else {
		ok( $err eq '' , $description) || diag($err."\n");
	}
}


sub to_int {
	my ($thing,$type) = @_;
	if ( $thing =~ /^\d+$/ ) {
		return $thing;
	}
	if ( defined($type) ) {
		return scalar(getgrnam($thing));
	}
	return scalar(getpwnam($thing));
}

sub uniqe {
	my %hash;
	my @out;
	for my $thing (@_) {
		if ( $hash{$thing} ) {
			next;
		}
		push(@out,$thing);
		$hash{$thing} = 1;
	}
	return @out;
}
		
done_testing();
