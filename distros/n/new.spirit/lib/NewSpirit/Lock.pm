package NewSpirit::Lock;

use strict;
use Carp;
use NewSpirit::LKDB;

sub new {
	my $type = shift;
	
	my %par = @_;
	
	croak "ticket missing"   unless defined $par{ticket};
	croak "username missing" unless defined $par{username};
	croak "project_meta_dir missing"  unless defined $par{project_meta_dir};

	my $lock_file = "$par{project_meta_dir}/##object_locks";
	
	my $lkdb;
	eval {
		$lkdb = new NewSpirit::LKDB ($lock_file);
	};
	if ( $@ =~ /can't write/ ) {
		print "$CFG::FONT<b><font color=red>Warning:</font>",
		      "<br>$@</b></font><p>\n";
	} elsif ( $@ ) {
		croak $@;
	}

	my $self = {
		ticket    => $par{ticket},
		username  => $par{username},
		project   => $par{project},
		lock_file => $lock_file,
		lkdb      => $lkdb,
		hash      => $lkdb->{hash}
	};
	
	return bless $self, $type;
}

sub set {
	my $self = shift;
	
	my ($object, $force) = @_;
	
	$force ||= 0;

	# first delete actual lock of this session
	$self->delete;
	
	# check if object is already locked
	my $lock_info_href = $self->get_object_info ($object);

	if ( defined $lock_info_href and
	     $lock_info_href->{ticket} ne $self->{ticket} ) {
	     	if ( $force ) {
			# ok, another owner, but we are advised to force the lock,
			# so the existant lock will be removed hard
			delete $self->{hash}->{$object};
			delete $self->{hash}->{$lock_info_href->{ticket}};
		} else {
			# we are not the owner of the lock, we are not
			# allowed to force, so we left here returning
			# the lock_info.
			return $lock_info_href;
		}
	}

	# set new lock
	my $time = NewSpirit::get_timestamp();
	my $ticket = $self->{ticket};
	my $username = $self->{username};

	$self->{hash}->{$ticket} = "$object\t$username\t$time";
	$self->{hash}->{$object} = "$ticket\t$username\t$time";

	# return lock info
	return {
		object => $object,
		ticket => $ticket,
		username => $username,
		time => $time
	};
}

sub delete {
	my $self = shift;
	
	# we need to know which object is actually locked
	# by this session

	my $lock_info_href = $self->get_session_info;
	
	return 1 if not defined $lock_info_href;

	delete $self->{hash}->{$lock_info_href->{object}};
	delete $self->{hash}->{$self->{ticket}};

	1;
}

sub get_object_info {
	my $self = shift;
	
	my ($object) = @_;
	
	if ( defined $self->{hash}->{$object} ) {
		my ($ticket, $username, $time) = split (
			"\t",
			$self->{hash}->{$object},
			3
		);
	
		return {
			object => $object,
			ticket => $ticket,
			username => $username,
			time => $time
		};
	}
	
	return;
}
	
sub get_session_info {
	my $self = shift;
	
	my $ticket = $self->{ticket};
	
	if ( defined $self->{hash}->{$ticket} ) {
		my ($object, $username, $time) = split (
			"\t",
			$self->{hash}->{$ticket},
			3
		);
	
		return {
			object => $object,
			ticket => $ticket,
			username => $username,
			time => $time
		};
	}
	
	return;
}
	
1;
		
