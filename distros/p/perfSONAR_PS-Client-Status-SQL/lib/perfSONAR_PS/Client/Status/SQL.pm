package perfSONAR_PS::Client::Status::SQL;

use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use perfSONAR_PS::DB::SQL;
use perfSONAR_PS::Status::Link;
use perfSONAR_PS::Status::Common;

our $VERSION = 0.09;

use fields "READ_ONLY", "DBI_STRING", "DB_USERNAME", "DB_PASSWORD", "DB_TABLE", "DB_OPEN", "DATADB";

sub new {
	my ($package, $dbi_string, $db_username, $db_password, $table, $read_only) = @_;

	my $self = fields::new($package);

	if ($read_only) {
		$self->{"READ_ONLY"} = 1;
	} else {
		$self->{"READ_ONLY"} = 0;
	}

	if (defined $dbi_string and $dbi_string ne "") { 
		$self->{"DBI_STRING"} = $dbi_string;
	}

	if (defined $db_username and $db_username ne "") { 
		$self->{"DB_USERNAME"} = $db_username;
	}

	if (defined $db_password and $db_password ne "") { 
		$self->{"DB_PASSWORD"} = $db_password;
	}

	if (defined $table and $table ne "") { 
		$self->{"DB_TABLE"} = $table;
	} else {
		$self->{"DB_TABLE"} = "link_status";
	}

	$self->{"DB_OPEN"} = 0;
	$self->{"DATADB"} = "";

	return $self;
}

sub open {
	my ($self) = @_;
	my $logger = get_logger("perfSONAR_PS::Client::Status::SQL");

	return (0, "") if ($self->{DB_OPEN} != 0);

        my @dbSchema = ("link_id", "link_knowledge", "start_time", "end_time", "oper_status", "admin_status"); 

	$logger->debug("Table: ".$self->{DB_TABLE});

	$self->{DATADB} = new perfSONAR_PS::DB::SQL({ name => $self->{DBI_STRING}, user => $self->{DB_USERNAME}, pass => $self->{DB_PASSWORD}, schema => \@dbSchema });
	if (not defined $self->{DATADB}) {
		my $msg = "Couldn't open specified database";
		$logger->error($msg);
		return (-1, $msg);
	}

	my $status = $self->{DATADB}->openDB;
	if ($status == -1) {
		my $msg = "Couldn't open status database";
		$logger->error($msg);
		return (-1, $msg);
	}

	$self->{DB_OPEN} = 1;

	return (0, "");
}

sub close {
	my ($self) = @_;
	my $logger = get_logger("perfSONAR_PS::Client::Status::SQL");

	return 0 if ($self->{DB_OPEN} == 0);

	$self->{DB_OPEN} = 0;

	return $self->{DATADB}->closeDB;
}

sub setDBIString {
	my ($self, $dbi_string) = @_;

	$self->close();

	$self->{DB_OPEN} = 0;
	$self->{DBI_STRING} = $dbi_string;

    return;
}

sub dbIsOpen {
	my ($self) = @_;
	return $self->{DB_OPEN};
}

sub getDBIString {
	my ($self) = @_;

	return $self->{DBI_STRING};
}

sub getAll {
	my ($self) = @_;
	my $logger = get_logger("perfSONAR_PS::Client::Status::SQL");

	return (-1, "Database is not open") if ($self->{DB_OPEN} == 0);

	my $links = $self->{DATADB}->query({ query => "select distinct link_id from ".$self->{DB_TABLE} });
	if ($links == -1) {
		$logger->error("Couldn't grab list of links");
		return (-1, "Couldn't grab list of links");
	}

	my %links = ();

	foreach my $link_ref (@{ $links }) {
		my @link = @{ $link_ref };

		my $states = $self->{DATADB}->query({ query => "select link_knowledge, start_time, end_time, oper_status, admin_status from ".$self->{DB_TABLE}." where link_id=\'".$link[0]."\' order by end_time" });
		if ($states == -1) {
			$logger->error("Couldn't grab information for link ".$link[0]);
			return (-1, "Couldn't grab information for link ".$link[0]);
		}

		foreach my $state_ref (@{ $states }) {
			my @state = @{ $state_ref };

			my $new_link = new perfSONAR_PS::Status::Link($link[0], $state[0], $state[1], $state[2], $state[3], $state[4]);
			if (not defined $links{$link[0]}) {
				$links{$link[0]} = ();
			}
			push @{ $links{$link[0]} }, $new_link;
		}
	}

	return (0, \%links);
}

sub getUniqueIDs {
	my ($self) = @_;
	my $logger = get_logger("perfSONAR_PS::Client::Status::SQL");

	return (-1, "Database is not open") if ($self->{DB_OPEN} == 0);

	my $links = $self->{DATADB}->query({ query => "select distinct link_id from ".$self->{DB_TABLE} });
	if ($links == -1) {
		$logger->error("Couldn't grab list of links");
		return (-1, "Couldn't grab list of links");
	}

	my @link_ids = ();
	foreach my $link_ref (@{ $links }) {
		my @link = @{ $link_ref };

		push @link_ids, $link[0];
	}

	return (0, \@link_ids);
}

sub getLinkHistory {
	my ($self, $link_ids, $time) = @_;
	my $logger = get_logger("perfSONAR_PS::Client::Status::SQL");

	return (-1, "Database is not open") if ($self->{DB_OPEN} == 0);

	my $query = "select link_id, link_knowledge, start_time, end_time, oper_status, admin_status from ".$self->{DB_TABLE};
	my $i = 0;
	foreach my $link_id (@{ $link_ids }) {
		if ($i == 0) {
			$query .= " where (link_id=\'".$link_id."\'";
		} else {
			$query .= " or link_id=\'".$link_id."\'";
		}
		$i++;
	}
	$query .= ")";

	if (defined $time and $time ne "") {
		$query .= " and end_time => $time and start_time <= $time";
	}

	my $status = $self->{DATADB}->openDB;
	if ($status == -1) {
		my $msg = "Couldn't open status database";
		$logger->error($msg);
		return (-1, $msg);
	}

	my $states = $self->{DATADB}->query( { query => $query });
	if ($states == -1) {
		$logger->error("Couldn't grab link history information");
		return (-1, "Couldn't grab link history information");
	}

	my %links = ();

	foreach my $state_ref (@{ $states }) {
		my @state = @{ $state_ref };

		my $new_link = new perfSONAR_PS::Status::Link($state[0], $state[1], $state[2], $state[3], $state[4], $state[5]);
		if (not defined $links{$state[0]}) {
			$links{$state[0]} = ();
		}

		push @{ $links{$state[0]} }, $new_link;
	}

	return (0, \%links);
}

sub getLinkStatus {
	my ($self, $link_ids, $time) = @_;
	my $logger = get_logger("perfSONAR_PS::Client::Status::SQL");

	return (-1, "Database is not open") if ($self->{DB_OPEN} == 0);

	my $status = $self->{DATADB}->openDB;
	if ($status == -1) {
		my $msg = "Couldn't open status database";
		$logger->error($msg);
		return (-1, $msg);
	}

	my %links;

    if ($time) {
        $logger->debug("Time: ".$time->getStartTime()."-".$time->getEndTime());
    }

	foreach my $link_id (@{ $link_ids }) {
		my $query;

		if (not defined $time) {
		$query = "select link_knowledge, start_time, end_time, oper_status, admin_status from ".$self->{DB_TABLE}." where link_id=\'".$link_id."\' order by end_time desc limit 1";
		} else {
		$query = "select link_knowledge, start_time, end_time, oper_status, admin_status from ".$self->{DB_TABLE}." where link_id=\'".$link_id."\' and start_time <= \'".$time->getEndTime()."\' and end_time >= \'".$time->getStartTime()."\'";
		}

		my $states = $self->{DATADB}->query({ query => $query });
		if ($states == -1) {
			$logger->error("Couldn't grab information for node ".$link_id);
			return (-1, "Couldn't grab information for node ".$link_id);
		}

		foreach my $state_ref (@{ $states }) {
			my @state = @{ $state_ref };
			my $new_link;

			if (defined $time) {
				if ($state[1] < $time->getStartTime()) {
					$state[1] = $time->getStartTime();
				}

				if ($state[2] > $time->getEndTime()) {
					$state[2] = $time->getEndTime();
				}
			}

			$new_link = new perfSONAR_PS::Status::Link($link_id, $state[0], $state[1], $state[2], $state[3], $state[4]);

            if (not defined $links{$link_id}) {
                my @newa = ();
                $links{$link_id} = \@newa;
            }

			push @{ $links{$link_id} }, $new_link;
		}
	}

	return (0, \%links);
}

sub updateLinkStatus {
	my($self, $time, $link_id, $knowledge_level, $oper_value, $admin_value, $do_update) = @_;
	my $logger = get_logger("perfSONAR_PS::Client::Status::SQL");
	my $prev_end_time;

	$oper_value = lc($oper_value);
	$admin_value = lc($admin_value);

	if (!isValidOperState($oper_value)) {
		return (-1, "Invalid operational state: $oper_value");
	}

	if (!isValidAdminState($admin_value)) {
		return (-1, "Invalid administrative state: $admin_value");
	}

	return (-1, "Database is not open") if ($self->{DB_OPEN} == 0);

	return (-1, "Database is Read-Only") if ($self->{READ_ONLY} == 1);

	my $status = $self->{DATADB}->openDB;
	if ($status == -1) {
		my $msg = "Couldn't open status database";
		$logger->error($msg);
		return (-1, $msg);
	}

	if ($do_update) {
		my @tmp_array = ( $link_id );

		my ($status, $res) = $self->getLinkStatus(\@tmp_array, undef);

		if ($status != 0) {
			my $msg = "No previous value for $link_id to update";
			$logger->error($msg);
			return (-1, $msg);
		}

		my $link = pop(@{ $res->{$link_id} });

        if (defined $link and $link->getEndTime > $time) {
			my $msg = "Update in the past for $link_id: most recent data was obtained for ".$link->getEndTime;
			$logger->error($msg);
			return (-1, $msg);
        }

		if (not defined $link or $link->getOperStatus ne $oper_value or $link->getAdminStatus ne $admin_value) {
			$logger->debug("Something changed on link $link_id");
			$do_update = 0;
		} else {
			$prev_end_time = $link->getEndTime;
		}
	} else {
		$do_update = 0;

		my @tmp_array = ( $link_id );
        my $time_elm = perfSONAR_PS::Time->new("point", $time);

		my ($status, $res) = $self->getLinkStatus(\@tmp_array, $time_elm);

        if (defined $res->{$link_id} and defined $res->{$link_id}->[0]) {
            my $state = $res->{$link_id}->[0];
			my $msg = "Already have information on $link_id at $time";
			$logger->error($msg);
			return (-1, $msg);
        }
	}

	if ($do_update != 0) {
		$logger->debug("Updating $link_id");

		my %updateValues = (
				end_time => $time,
				);

		my %where = (
				link_id => "'$link_id'",
				end_time => $prev_end_time,
			    );

		if ($self->{DATADB}->update({ table => $self->{DB_TABLE}, wherevalues => \%where, updatevalues => \%updateValues }) == -1) {
			my $msg = "Couldn't update link status for link $link_id";
			$logger->error($msg);
			$self->{DATADB}->closeDB;
			return (-1, $msg);
		}
	} else {
		my %insertValues = (
				link_id => $link_id,
				start_time => $time,
				end_time => $time,
				oper_status => $oper_value,
				admin_status => $admin_value,
				link_knowledge => $knowledge_level,
				);

		if ($self->{DATADB}->insert({ table => $self->{DB_TABLE}, argvalues => \%insertValues }) == -1) {
			my $msg = "Couldn't update link status for link $link_id";

			$logger->error($msg);
			$self->{DATADB}->closeDB;
			return (-1, $msg);
		}
	}

	$self->{DATADB}->closeDB;

	return (0, "");
}

1;

__END__

=head1 NAME

perfSONAR_PS::Client::Status::SQL - A module that provides methods for
interacting with a Status MA database directly.

=head1 DESCRIPTION

This module allows one to interact with the Status MA SQL Backend directly
using a standard set of methods. The API provided is identical to the API for
interacting with the MAs via its Web Services interface. Thus, a client written
to read from or update a Status MA can be easily modified to interact directly
with its underlying database allowing more efficient interactions if required.

The module is to be treated as an object, where each instance of the object
represents a connection to a single database. Each method may then be invoked
on the object for the specific database.  

=head1 SYNOPSIS

	use perfSONAR_PS::Client::Status::SQL;

	my $status_client = new perfSONAR_PS::Client::Status::SQL("DBI:SQLite:dbname=status.db");
	if (not defined $status_client) {
		print "Problem creating client for status MA\n";
		exit(-1);
	}

	my ($status, $res) = $status_client->open;
	if ($status != 0) {
		print "Problem opening status MA: $res\n";
		exit(-1);
	}

	($status, $res) = $status_client->getAll();
	if ($status != 0) {
		print "Problem getting complete database: $res\n";
		exit(-1);
	}

	my @links = (); 

	foreach my $id (keys %{ $res }) {
		print "Link ID: $id\n";

		foreach my $link ( @{ $res->{$id} }) {
			print "\t" . $link->getStartTime . " - " . $link->getEndTime . "\n";
			print "\t-Knowledge Level: " . $link->getKnowledge . "\n";
			print "\t-operStatus: " . $link->getOperStatus . "\n";
			print "\t-adminStatus: " . $link->getAdminStatus . "\n";
		}
	
		push @links, $id;
	}

	($status, $res) = $status_client->getLinkStatus(\@links, "");
	if ($status != 0) {
		print "Problem obtaining most recent link status: $res\n";
		exit(-1);
	}

	foreach my $id (keys %{ $res }) {
		print "Link ID: $id\n";

		foreach my $link ( @{ $res->{$id} }) {
			print "-operStatus: " . $link->getOperStatus . "\n";
			print "-adminStatus: " . $link->getAdminStatus . "\n";
		}
	}

	($status, $res) = $status_client->getLinkHistory(\@links);
	if ($status != 0) {
		print "Problem obtaining link history: $res\n";
		exit(-1);
	}

	foreach my $id (keys %{ $res }) {
		print "Link ID: $id\n";
	
		foreach my $link ( @{ $res->{$id} }) {
			print "-operStatus: " . $link->getOperStatus . "\n";
			print "-adminStatus: " . $link->getAdminStatus . "\n";
		}
	}

=head1 DETAILS

=head1 API

The API os perfSONAR_PS::Client::Status::SQL is rather simple and greatly
resembles the messages types received by the server. It is also identical to
the perfSONAR_PS::Client::Status::MA API allowing easy construction of
programs that can interface via the MA server or directly with the database.

=head2 new($package, $dbi_string)

The new function takes a DBI connection string as its first argument. This
specifies which DB to read from/write to.

=head2 open($self)

The open function opens the database to read from/write to. The function
returns an array containing two items. The first is the return status of the
function, 0 on success and non-zero on failure. The second is the error message
generated if applicable.

=head2 close($self)

The close function closes the associated database. It returns 0 on success and
-1 on failure.

=head2 setDBIString($self, $dbi_string)

The setDBIString function changes the database that the instance uses. If open,
it closes the current database.

=head2 dbIsOpen($self)

The dbIsOpen function checks whether the database backend is currently open. If so, it returns 1, if not, 0.

=head2 getDBIString($self)

The getDBIString function returns the current DBI string

=head2 getAll($self)

The getAll function gets the full contents of the database. It returns the
results as a hash with the key being the link id. Each element of the hash is
an array of perfSONAR_PS::Status::Link structures containing a the status
of the specified link at a certain point in time.

=head2 getLinkHistory($self, $link_ids)

The getLinkHistory function returns the complete history of a set of links. The
$link_ids parameter is a reference to an array of link ids. It returns the
results as a hash with the key being the link id. Each element of the hash is
an array of perfSONAR_PS::Status::Link structures containing a the status
of the specified link at a certain point in time.

=head2 getLinkStatus($self, $link_ids, $time)

The getLinkStatus function returns the link status at the specified time. The
$link_ids parameter is a reference to an array of link ids. $time is the time
at which you'd like to know each link's status. $time is a perfSONAR_PS::Time
element. If $time is an undefined, it returns the most recent information it
has about each link. It returns the results as a hash with the key being the
link id. Each element of the hash is an array of perfSONAR_PS::Status::Link
structures containing a the status of the specified link at a certain point in
time.

=head2 updateLinkStatus($self, $time, $link_id, $knowledge_level, $oper_value, $admin_value, $do_update) 

The updateLinkStatus function adds a new data point for the specified link.
$time is a unix timestamp corresponding to when the measurement occured.
$link_id is the link to update. $knowledge_level says whether or not this
measurement can tell us everything about a given link ("full") or whether the
information only corresponds to one side of the link("partial"). $oper_value is
the current operational status and $admin_value is the current administrative
status.  $do_update tells whether or not we should try to update the a given
range of information(e.g. if you were polling the link and knew that nothing
had changed from the previous iteration, you could set $do_update to 1 and the
server would elongate the previous range instead of creating a new one).

=head2 getUniqueIDs($self)

This function is ONLY available in the SQL client as the functionality it is
not exposed by the MA. It does more or less what it sounds like, it returns a
list of unique link ids that appear in the database. This is used by the MA to
get the list of IDs to register with the LS.

=head1 SEE ALSO

L<perfSONAR_PS::DB::SQL>, L<perfSONAR_PS::Status::Link>,L<perfSONAR_PS::Client::Status::MA>, L<Log::Log4perl>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list. 

=head1 VERSION

$Id$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE
 
You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT
 
Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
