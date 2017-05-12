# $Id: Session.pm,v 1.18 2001/02/06 15:10:10 joern Exp $

package NewSpirit::Session;

$VERSION = "0.02";

use strict;
use Carp;
use NewSpirit;
use NewSpirit::LKDB;
use NewSpirit::LKFile;

BEGIN { srand $$; srand $$ ^ int(rand(1000)) }

#---------------------------------------------------------------------
# Constructor
# Set up session object, with tied session hash
#---------------------------------------------------------------------
sub new {
	my $type = shift;
	my ($filename) = @_;

	$filename ||= $CFG::ticket_file;
	
	my $lkdb = new NewSpirit::LKDB ($filename);

	my $self = {
		lkdb => $lkdb,		# locked tied hash handle
		hash => $lkdb->{hash},	# tied session hash
		proved => 0,		# is session proved?
		ticket => undef,	# ticket of this session
		username => undef,	# owner of this session
		ip_adress => undef,	# client adress of this session
		persist_file => undef,	# filename of user perstant data
		session_file => undef,	# filename of session pers. data
	};

	return bless $self, $type;
}

sub create_ticket {
	my $self = shift;

	my $ticket;
	do {
		$ticket = '';
		for (my $i=0; $i < 16; ++$i) {
			$ticket .= chr(int (rand (10)) + 48);
		}
	} while defined $self->{hash}->{$ticket};
	
	return $ticket;
}	

#---------------------------------------------------------------------
# Create a session from scratch. A ticket is created, stored in
# combination with username and IP adress.
#---------------------------------------------------------------------
sub create {
	my $self = shift;
	my ($ip_adress, $username, $from_ticket, $window) = @_;

	my $ticket = $self->create_ticket;
	$window ||= 0;

	# put an entry for this session into the hash
	my $timestamp = time;
	$self->{hash}->{$ticket} = 
		"$ip_adress\t$username\t$timestamp\t$timestamp\t$window";

	# set up internal session attributes
	$self->{ticket}       = $ticket;
	$self->{username}     = $username;
	$self->{ip_adress}    = $ip_adress;
	$self->{persist_file} = "$CFG::user_conf_dir/$username.tree";
	$self->{session_file} = "$CFG::session_dir/$ticket";

	# a new session is naturally proved
	$self->{proved} = 1;

	# inialize additional session data
	# (e.g. state of project tree)
	$self->initialize_session_data ($from_ticket);
	
	# remove outdated sessions
	$self->remove_outdated;

	return $ticket;
}

#---------------------------------------------------------------------
# Check a session. $ticket and $ip_adress must match. $username
# and $window will be returned.
#---------------------------------------------------------------------
sub check {
	my $self = shift;
	my ($ticket, $ip_adress) = @_;

	my $value = $self->{hash}->{$ticket};
	croak "user session is unknown" unless defined $value;
	
	my @field = split ("\t", $value);
	croak "user session is invalid" unless $ip_adress eq $field[0];

	$field[3] = time;
	$self->{hash}->{$ticket} = join ("\t", @field);

	my $username = $field[1];
	$self->{ticket} = $ticket;
	$self->{ip_adress} = $ip_adress;
	$self->{username} = $username;
	$self->{persist_file} = "$CFG::user_conf_dir/$username.tree";
	$self->{session_file} = "$CFG::session_dir/$ticket";

	$self->{proved} = 1;

	return ($field[1], $field[4]);
}

#---------------------------------------------------------------------
# Initialize additional session data. Some information are made
# permanent over sessions, so this session will be initialized with
# the last preserved state. (e.g. state of the tree view)
# If $from_ticket is given, the session data will be cloned from
# this session.
#---------------------------------------------------------------------
sub initialize_session_data {
	my $self = shift;
	my ($from_ticket) = @_;

	croak "Session not checked" unless $self->{proved};

	my $username = $self->{username};
	my $ticket = $self->{ticket};

	my $persist_file = $self->{persist_file};
	my $session_file = $self->{session_file};

	if ( $from_ticket ) {
		$persist_file = "$CFG::session_dir/$from_ticket";
	}

	return if not -f $persist_file;

	my $from_lk = new NewSpirit::LKFile ($persist_file);
	my $to_lk = new NewSpirit::LKFile ($session_file);
	
	$to_lk->write ($from_lk->read);
}

#---------------------------------------------------------------------
# Make actual session data persistent, for initialization of future
# sessions.
#---------------------------------------------------------------------
sub preserve_session_data {
	my $self = shift;

	croak "Session not checked" unless $self->{proved};

#	print STDERR  "preserve_session_data\n";

	my $username = $self->{username};
	my $ticket = $self->{ticket};

	my $persist_file = $self->{persist_file};
	my $session_file = $self->{session_file};

	my $from_lk = new NewSpirit::LKFile ($session_file);
	my $to_lk = new NewSpirit::LKFile ($persist_file);
	
	$to_lk->write ($from_lk->read);
}

#---------------------------------------------------------------------
# Delete a session from the session hash and appropriate files in
# filesystem.
#---------------------------------------------------------------------
sub delete {
	my $self = shift;
	my ($ticket) = @_;

	$ticket ||= $self->{ticket};

	my $value = $self->{hash}->{$ticket};
	croak "user session '$ticket' unknown" unless defined $value;
	
	delete $self->{hash}->{$ticket};    

	my $session_file = "$CFG::session_dir/$ticket";
	unlink "$session_file";
	unlink "$session_file.lck";

	1;
}

#---------------------------------------------------------------------
# Return a session attribute
#---------------------------------------------------------------------
sub get_attrib {
	my $self = shift;
	my ($name, $sf) = @_;

	croak "Session not checked" unless $self->{proved};

	my $ticket = $self->{ticket};
	$sf ||= NewSpirit::open_session_file ($ticket);
	
	return $sf->{hash}->{"__attr_$name"};
}

#---------------------------------------------------------------------
# Set a session attribute
#---------------------------------------------------------------------
sub set_attrib {
	my $self = shift;
	my ($name, $value, $sf) = @_;

#	print STDERR "set_attrib: name='$name' value='$value' sf='$sf'\n";

	croak "Session not checked" unless $self->{proved};

	my $ticket = $self->{ticket};
	$sf ||= NewSpirit::open_session_file ($ticket);
	
	$sf->{hash}->{"__attr_$name"} = $value;

	1;
}

#---------------------------------------------------------------------
# Remove outdated sessions.
#---------------------------------------------------------------------
sub remove_outdated {
	my $self = shift;

	my ($interval) = @_ || $CFG::session_length;

	my $time = time - $interval;

	my @remove_sessions;
	my ($ticket, $data);
	while ( ($ticket,$data) = each %{$self->{hash}} ) {
		my @field = split ("\t", $data);
		if ( $field[3] < $time ) {
			push @remove_sessions, $ticket;
		}
	}

	foreach $ticket (@remove_sessions) {
		$self->delete ($ticket);
	}

	1;
}

#---------------------------------------------------------------------
# Check if a ticket exists
#---------------------------------------------------------------------
sub ticket_exists {
	my $self = shift;

	my ($ticket) = @_;
	return exists $self->{hash}->{$ticket};
}

1;
