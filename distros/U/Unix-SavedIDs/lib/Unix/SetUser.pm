# $Id$

package Unix::SetUser;

use warnings;
use strict;
use Carp;
use Unix::SavedIDs 0.004002;
use Data::Dumper;

#warn "\@INC = ".join(" ",@INC)."\n";
#warn "\%INC = ".Dumper(\%INC)."\n";

our $verbose = 0;

my $warncount = 0;

BEGIN {
	use Exporter ();
	our ($VERSION,@ISA,@EXPORT);
	@ISA    = qw(Exporter);
	@EXPORT = qw(set_user);
	$VERSION = 0.004003;
}

sub set_user {
	## Figure Out IDs to Set
	my($user,$group,@sup_groups) = @_;
	my($uid,$gid,%sup_gids);
	my $is_int = qr/^(\d+)$/o;
	if ( !defined($user) ) {
		croak "set_user() called with no arguments";
	}
	# get uids
	if ( $user =~ $is_int ) {
		$uid = $1;
	}
	else {
		# get numeric uid if given non-numeric user name
		$uid = getpwnam($user);
		if ( !defined($uid) ) {
			croak "User '$user' does not exist";
		}
		if ( $uid !~ $is_int ) {
			croak "User id for '$user' is not an int.  "
				."This shouldn't ever happen";
		}
		$uid = $1;
	}
	# get primary gid
	if ( defined($group) && $group =~ $is_int ) {
		$gid = $1;
		if ( !getgrgid($gid) ) {
			croak "Primary group id '$gid' does not exist\n";
		}
	} 
	else {
		# use user's primary group if no primary group specified
		if ( !defined($group) ) {
			$gid = (getpwuid($uid))[3];
			if ( !defined($gid)) {
				croak "Failed to get primary group ID for uid '$uid'";
			}
		} 
		else {
			# get gid from group name 
			$gid = getgrnam($group);
			if ( !defined($gid) ) {
				croak "Primary group '$group' does not exist";
			}

		}
		if ( $gid !~ $is_int ) {
			croak "Primary group ID for '$user' is not an int.  "
				."This shouldn't ever happen";
		}
	}
	# get supplemental groups
	my @dont_exist;
	foreach my $sup_group (@sup_groups) {
		my $sup_gid;
		if ( !defined($sup_group) ) {
			croak "Supplemental group list contains 'undef'";
		}
		# if ints, make sure they exist
		if ( $sup_group =~ $is_int ) {
			$sup_gid = $1;
			if ( $sup_gid == $gid || defined($sup_gids{$sup_gid})) {
				# remove duplicates
				next;
			}
			if ( !getgrgid($sup_gid) ) {
				push(@dont_exist,$sup_group);
				next;
			}
		}
		# if not ints, convert text usernames to ints which tests existance
		else { 
			$sup_gid = getgrnam($sup_group);
			if ( !defined($sup_gid) ) {
				push(@dont_exist,$sup_group);
				next;
			}
			if ( $sup_gid !~ $is_int ) {
				croak "Supplemental group id for group '$sup_group' is "
					."not an int.  This shouldn't ever happen";
			}
			if ( $sup_gid == $gid || defined($sup_gids{$sup_gid}) ) {
				# duplicate
				next;
			}
		}
		$sup_gids{$sup_gid} = 1;
	}
	if ( @dont_exist ) {
		croak "Specified supplemental group(s) '".join("', '",@dont_exist)
			."' do(es) not exist(s)";
	} 

	## Set Ids

	# set gid, egid and sgid
	setresgid($gid,$gid,$gid);
	# set egid & supplimental gids
	my $egid_string = $gid;
	if ( keys(%sup_gids) == 0 ) { #  $) lists primary group twice 
		$egid_string .= ' '.$gid; #  if it's your only group
	}
	else {
		$egid_string .= ' '.join(' ',sort(keys(%sup_gids)));
	}
	$) = $egid_string;
	# set uid,euid & suid
	#_warn_ids();
	#warn "-- Setting uid,euid & suid setresuid($uid,$uid,$uid)\n";
	setresuid($uid,$uid,$uid);
	#_warn_ids();

	## Make sure everything worked
	my @errs = ();
	# make sure uid change worked
	if ( $< != $uid ) {
		push(@errs,"Failed to set uid: uid = '$<', not '$uid'");
	}
	# make sure set euid worked
	if ( $> != $uid ) {
		push(@errs,"Failed to set euid: euid = '$>', not '$uid'");
	}
	# make sure saved uid got set correctly
	my $suid = (getresuid())[2];
	if ( $suid != $uid ) {
		push(@errs,'Failed to set saved uid: saved uid = '.$suid
			.' not '.$uid);
	}
	#warn "about to check rgid\n";
	#_warn_ids();
	# make sure rgid is correct
	if ( $( !~ /^(\d+)/o ) {
		croak "GID is not an int!??!";
	}
	my $now_gid = $1;
	if ( $now_gid != $gid ) {
		croak "Failed to set gid: gid is '$now_gid' not '$gid'\n";
	}
	# make sure set egid & supplimental gids worked
	if ( $) ne $egid_string ) {
		# Order doesn't matter, so split, sort and rejoin to test.  
		my $now = join(' ',sort(split(' ',$))));
		my $want = join(' ',sort(split(' ',$egid_string)));
		if ( $now ne $want ) {
			push(@errs,"Failed to set egid: egid = '$)', not '$egid_string'");
		}
	}
	# make sure sgid got set correctly
	my $sgid = (getresgid())[2];
	if ( $sgid != $gid ) {
		push(@errs,'Failed to set saved gid: saved gid = '.$sgid
			.' not '.$gid);
	}
	if ( @errs ) {
		croak join("\n",@errs);
	}
	#_warn_ids();
	return undef;
}

sub _warn_ids {
	$warncount++;
	warn "count = $warncount\n";
	warn "\$< = '$<'\n";
	warn "\$> = '$>'\n";
	warn "\$( = '$('\n";
	warn "\$) = '$)'\n";
	warn "geresuid = ".join(',',getresuid())."\n";
	warn "geresgid = ".join(',',getresuid())."\n";
}

1; # Magic true value required at end of module
__END__

=head1 NAME

B<Unix::SetUser> - carefully drop root privileges 

=head1 SYNOPSIS

	use Unix::SetUser;

	if ( $> != 0 ) {
		die "Run this as root!\n";
	}
	
	# do something with root privileges

	set_user('nobody');

	# do stuff without root privileges

  
=head1 DESCRIPTION

Dropping privileges is something that needs to be done right and can 
easily be done wrong.  Even if you know how to do it right, it takes a 
lot of boring code.  

=head1 About Saved IDs

Most modern unices have saved ids.  This is a 3rd id type, so you have real
user id, effective user id and now saved user id.  (The same applies to groups).
This means if you don't set your saved id, you really haven't dropped root
privileges.  Please see L<Unix::SavedIDs>, the module used in Unix::SetUser to
handle saved ids, for more information.

=head1 USAGE

=head2 set_user(I<new_user>, [I<primary_group>] , [I<supplemental_group> ... ]);

This is the only function provided by B<Unix::SetUser>.  It is exported by 
default.  

B<set_user()> switches the uid, euid, suid, gid, egid, sgid and reduces the supplemental groups to those specified if any.

I<new_user> is the user name or numeric user id of the user whom 
you wish the process to run as.

I<primary_group> is the group name or numeric group id of the primary group.
If undefined, the primary group of the user I<new_user> is used.

I<supplemental_group> is any group which you'd like the process to be a member of.  If undefined, all supplemental group memberships are dropped.

All names and groups are assumed to be numeric uids and numeric gids if 
they are integers.  Otherwise they are assumed to be user names or group names.

=head1 EXAMPLES

=over 4

=item *

set_user('jdoe');

Switch the uid, euid & suid to 'jdoe'.
Switch the gid, egid & suid to jdoe's primary group (probably 'jdoe' 
or 'users' but maybe not.)
Drop membership in any other groups.

=item * 

set_user('jdoe','users,'tape');

Switch the uid, euid & suid to 'jdoe'.
Switch the gid, egid & sgid to 'users'. 
Add membership in the 'tape' group and drop membership in any other groups.

=item * 

set_user('jdoe',undef,'tape');

Switch the uid, euid & suid to 'jdoe'.
Switch the gid, egid & sgid to jdoe's primary group (probably 'jdoe' 
or 'users' but maybe not.)
Add membership in the 'tape' group and drop membership in any other groups.

=back

=head1 DIAGNOSTICS

B<set_user()> returns undef on success and croaks on failure.

=head1 DISCUSSION

Here's some of the gotchas involved in dropping privileges.  
These are all taken care of by Unix::SetUser

=over 4

=item Make sure you drop group membership as well as changing user id.

=item Handle supplemental groups as well as the users primary group.

=item Set saved ids as well as real and effective ids.

=item Check to make sure ids really did change.

=item Check group membership without getting hung up about the order 
the groups are listed in.

=back

=head1 PORTABILITY

This module will only work on unix-like systems which support saved ids.  That
is the vast majority of unices.  I would like to add support for unices without
saved ids and Windows, but I don't use those systems so I can't justify the
time spent.

=head1 ACKNOWLEDGMENTS

After I wrote version 0.1, I discovered L<Proc::UID> by Paul Fenwick.  It does
everything that this module does plus more.  Sadly, its unmaintained since 2004
and the author specifically states that it is not for production code.

=head1 BUGS AND LIMITATIONS

This has only been tested on Linux and OpenBSD.

I assume you want uid == euid == suid and gid == euid == suid.  If you don't 
L<Unix::SavedIds> will let you manipulate all 3.  

Please report any bugs or feature requests to
C<bug-process-dropprivs@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Dylan Martin  C<< <dmartin@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Dylan Martin & Seattle Central Community College 
C<< <dmartin@cpan.org> >>. 

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

=head1 DISCLAIMER

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


