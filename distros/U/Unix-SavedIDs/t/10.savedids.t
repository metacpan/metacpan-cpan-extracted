use strict;
use Test::More;
use Unix::SavedIDs;
use Carp;
use warnings;
use Data::Dumper;
use POSIX qw(getuid getgid geteuid getegid);

$Unix::SavedIDs::DEBUG = 1;

if ( $< != 0 ) {
	plan skip_all => "Only root can change user, so please run these tests as root.";
}
else {
	plan tests => 88;
}


# check getresuid
print "getresuid() before running setresuid\n";
check_values('uid',0,0,0);
# check getresgid
print "getresgid() before running setresgid\n";
check_values('gid',0,0,0);

print "setresgid() should do nothing\n";
eval { setresgid() };
ok ( !$@ , "setresgid() - should do nothing" ) || diag($@); 
check_values('gid',0,0,0);

#show_all();

print "setresgid(50,60,70) - setting some arbitrary gids\n";
eval { setresgid(50,60,70) };
ok ( !$@ , "setresgid(50,60,70)" ) || diag($@); 
check_values('gid',50,60,70);

#show_all();

eval { setresgid(51,61) };
ok ( !$@ , "setresgid(51,61) ie not with 3 args " ) || diag($@); 
check_values('gid',51,61,70);

eval { setresgid(undef,undef,25) };
ok ( !$@, "setresgid(undef,undef,25) - set sgid only") || diag($@);
check_values('gid',51,61,25);

eval { setresgid(-1,-1,30) };
ok ( !$@ , "setresgid(-1,-1,30) - also set sgid only" ) || diag($@); 
check_values('gid',51,61,30);

eval { setresuid() };
ok ( !$@, "setresuid() - do nothing ") || diag($@);
check_values('uid',0,0,0);

setresuid(0,0,0);
eval { setresuid(undef,undef,25) };
ok ( !$@, "setresuid(undef,undef,25) - set suid only") || diag($@);
check_values('uid',0,0,25);
setresuid(0,0,0);

eval { setresuid(-1,-1,30) };
ok ( !$@ , "setresuid(-1,-1,30) - also set suid only" ) || diag($@); 
check_values('uid',0,0,30);

eval { setresuid(50,60,70) };
ok ( !$@ , "setresuid(50,60,70) didn't crash" ) || diag($@); 
check_values('uid',50,60,70);

eval { setresuid(55,66,77) };
ok ( $@ , "setresuid while not root should crash" ) 
	|| diag("Didn't crash while running setresuid(55,66,77) as non root user!"); 
eval { setresgid(55,66,77) };
ok ( $@ , "setresgid while not root should crash" ) 
	|| diag("Didn't crash while running setresgid(55,66,77) as non root user!");


sub check_values {
	#warn "Posix sez uid = ".getuid().', euid = '.geteuid().', gid = '.getgid()
		#.', egid = '.getegid()."\n";
	my $type = shift;
	if ( $type ne 'uid' && $type ne 'gid' ) {
		croak "Specify type as 'uid' or 'gid'";
	}
	my($rid,$eid,$sid) = @_;

	# uncomment to make arg vars go bad to test this sub
	#$rid++; $eid++; $sid++;
	my @ids;
	if ( $type eq 'uid' ) {
		@ids = eval{ getresuid() };
	} 
	else {
		@ids = eval{ getresgid() };
	}
	# uncomment to make getre(u|g)suid output go bad
	# don't  uncomment both go-bad sections, they will cancel out
	#map { $ids[$_]++ } (0 ... 2);
	
	#my $args_as_string = defined($rid) ? $rid : 'undef';
	#$args_as_string .= ", ".( defined($eid) ? $eid : 'undef' );
	#$args_as_string .= ", ".( defined($sid) ? $sid : 'undef' );
	#print Dumper(\@ids)."\n";

	ok( !$@ ,'getres'.$type.'() didn\'t crash' ) || diag($@);
	ok ( @ids == 3 , "returned 3 elem array" ) || diag(Dumper(\@ids)); 
	ok ( $ids[0] == $rid, 'r'.$type.' is '.$rid ) || diag("r$type is ".$ids[0]);
	ok ( $ids[1] == $eid, 'e'.$type.' is '.$eid ) || diag("e$type is ".$ids[1]);
	ok ( $ids[2] == $sid, 's'.$type.' is '.$sid ) || diag("s$type is ".$ids[2]);
	if ( $type eq 'gid' ) {
		if ( $( !~ /^(\d+)/ ) { 
			croak "Can't parse \$( '$(' This shouldn't happen"; 
		}
		my $rgid_from_perl = $1;
		ok ( $rgid_from_perl == $ids[0], '$( agrees with getresid()') 
			|| diag("\$( = '$(', rgid part of that is '$rgid_from_perl'"
				." getresgid() says '".$ids[0]."'"
			);
		if ( $) !~ /^(\d+)/ ) { 
			croak "Can't parse \$) '$)' This shouldn't happen"; 
		}
		my $egid_from_perl = $1;
		ok ( $egid_from_perl == $ids[1], '$) agrees with getresgid()') 
			|| diag("\$) = '$)', egid part of that is '$egid_from_perl'"
			." getresgid() says '".$ids[1]."'");
	}
	else {
		ok ( $< == $ids[0], '$< agrees with getresuid()') 
			|| diag("\$< = '$<', getresuid() says '".$ids[0]."'".show_all());
		ok ( $> == $ids[1], '$> agrees with getresuid()') 
			|| diag("\$> = '$>', getresuid() says '".$ids[1]."'".show_all());
	}
}

sub show_all {
	print <<"END";
	\$< = '$<', \$> = '$>'
	\$( = '$('
	\$) = '$)'
END
	print "\tgetresuid() = ".join(', ',getresuid())."\n";
	print "\tgetresgid() = ".join(', ',getresgid())."\n";
}

#done_testing();
		
