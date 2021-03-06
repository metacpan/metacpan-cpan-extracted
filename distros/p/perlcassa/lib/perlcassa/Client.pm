package perlcassa::Client;

use strict;
use warnings;
use base 'Exporter';

our @EXPORT = qw(setup close_conn client_setup fail_host);

use Thrift;
use Thrift::Socket;
use Thrift::FramedTransport;
use Thrift::XS::BinaryProtocol;

use Time::HiRes qw ( gettimeofday );
use threads;

#####################################################################################################
# generate_host_hashes()
# generate two hashes to track both working and failed cassandra resources
#####################################################################################################
sub generate_host_hashes() {
	my $self = shift;

	foreach my $host (@{$self->{hosts}}) {
		$self->{availablehosts}{$host} = 1;
	}
}

#####################################################################################################
# generate_server_list()
# generate the round robbin load balancer pool with avaliable servers
#####################################################################################################
sub generate_server_list() {
	my $self = shift;

	my $tmpscalar = $self->{availablehosts};
	my %hosts = %$tmpscalar;

	# build up a nonrandomized server list from the current hash
	my @tmplist;
	for my $key (sort(keys(%hosts))) {
		push (@tmplist, $key);
	}

	# randomize the server list
	my $number_of_servers = scalar(keys(%hosts));

	if ($number_of_servers == 0) {
		die('[ERROR] There were no available Cassandra servers left');
	}

	my %addedhost; # keep track of what servers we have already added incase random number is the same more than once
	my @availablehosts;
	while (scalar(@availablehosts) < $number_of_servers) {
		my ($s, $usec) = gettimeofday();
		my $randomserver = $tmplist[$usec%$number_of_servers];

		if (!defined($addedhost{$randomserver})) {
			$addedhost{$randomserver} = 1;
			push (@availablehosts, $tmplist[$usec%$number_of_servers]);
		}
	} 

	# reset our request count that we use to grab the next host round robin
	$self->{request_count} = 0;

	$self->{hostpool} = \@availablehosts;

	if ($self->{debug} == 1) {
		print STDERR "regenerated_server_list @availablehosts";
	}
}

#####################################################################################################
# failure_thread()
# failure thread logic
# runs in the background and tries every 30 seconds to see if the host is back up
# if it is back up, adds the host back into the pool of avaliable hosts
#####################################################################################################
sub failure_thread() {
	my $self = shift;

	my $tmp = $self->{failedhosts};
	my %failedhosts = %$tmp;

	while (scalar(keys(%failedhosts)) != 0) {
		for my $key (sort(keys(%failedhosts))) {
			if (defined($self->perlcassa::Client::check_host($key))) {
				$self->perlcassa::Client::recover_host($key);
				%failedhosts = %$tmp;
			}
		}

		%failedhosts = %$tmp;
		sleep(30);
	}

	$self->{failure_thread_running} = 0;
	threads->exit();
}

#####################################################################################################
# check_host($)
# @args = host to check Thrift status on
# check to see if a cassandra node is up or not
# returns undef if host is down or 1 if host is up
#####################################################################################################
sub check_host($) {
	my ($self, $host) = @_;

	my $socket = new Thrift::Socket($host, $self->{port});
	my $transport = new Thrift::FramedTransport($socket,1024,1024);
	my $protocol = new Thrift::XS::BinaryProtocol($transport);
	my $client = new Cassandra::CassandraClient($protocol);

	eval {
		$transport->open();
	};

	if ($@) {
		return undef;
	} else {
		return 1;
	}
}

#####################################################################################################
# fail_host($)
# @arts = host to fail
# remove a failed host from the pool of avaliable cassandra hosts
#####################################################################################################
sub fail_host($) {
	my ($self, $failed_host) = @_;

	delete($self->{availablehosts}{$failed_host});
	$self->{failedhosts}{$failed_host} = time;

	# create a thread to check every n seconds to see if this hosts comes back
	unless ($self->{failure_thread_running} == 1) {
		my $thr = threads->create('failure_thread', $self);
		$self->{failure_thread_running} = 1;
		$thr->detach();
	}

	# regenerate the server list
	$self->perlcassa::Client::generate_server_list();

	warn("[WARNING] Failed $failed_host");
}

#####################################################################################################
# recover_host($)
# @args = host to add back into pool
# add a previously failed host back into the avaliable pool
#####################################################################################################
sub recover_host($) {
	my ($self, $host) = @_;

	delete($self->{failedhosts}{$host});
	$self->{availablehosts}{$host} = 1;

	# regenerate the server list
	$self->perlcassa::Client::generate_server_list();

	warn("[WARNING] Recovered $host back into the pool");
}

#####################################################################################################
# get_host()
# get the next avaliable cassandra host
#####################################################################################################
sub get_host() {
	my ($self) = @_;

	my $host = @{$self->{hostpool}}[$self->{request_count}%scalar(@{$self->{hostpool}})];

	if ($self->{debug} == 1) {
		print STDERR "[DEBUG] Using host $host\n";
	}

	$self->{request_count}++;

	return $host;
}

#####################################################################################################
# close_conn() frees the Cassandra node in the resource pool and gracefully closes the thrift client
#####################################################################################################
sub close_conn() {
	my $self = shift;

	if (defined($self->{transport})) {
		$self->{transport}->close();
		$self->{server} = undef;
		$self->{client} = undef;
	}

	return 1;
	
}

#####################################################################################################
# setup() is called to create a new Thrift Client. You should not need to call this manually
##################################################################################################### 
sub setup() {
	my ($self, $keyspace) = @_;

	if(!defined($self->{server})) {
		my $connected = 0;
		my $attempts = 0;
		while ($connected != 1) {
			my $host = $self->perlcassa::Client::get_host();

			$self->{socket} = new Thrift::Socket($host, $self->{port});
			$self->{transport} = new Thrift::FramedTransport($self->{socket},1024,1024);
			$self->{protocol} = new Thrift::XS::BinaryProtocol($self->{transport});
			$self->{client} = new Cassandra::CassandraClient($self->{protocol});

			if ($attempts >= $self->{max_retry}) {
				die("[ERROR] Max connection attempts [$attempts] to a Cassandra host exceeded for this operation");
			}

			eval {
				$self->{transport}->open();
			};

			if ($@) {
				warn("[WARNING] attempt $attempts of $self->{max_retry} - unable to connect to host $host");
				$self->perlcassa::Client::fail_host($host);
				$attempts++;
			} else {
				if ($attempts > 0) {
					warn("[WARNING] attempt $attempts of $self->{max_retry} - sucessfully connected to host $host");
				}
				$connected = 1;
			}
		}
	}

	$self->{client}->set_keyspace($keyspace);

	# let us track what keyspace this client is connected to
	# so we can determine if we need to reconnect for future calls using the same object
	$self->{keyspace_inuse} = $keyspace;

	return $self->{client};
}

sub _refresh_cf_info() {
	my ($self, %opts) = @_;

	my $current_cf = $self->{columnfamily_inuse};
	my $current_keyspace = $opts{keyspace} || $self->{keyspace_inuse};

	if (defined($current_cf)) {
		my $validators;
		# if we have a manual hash provided in the object, use that instead of fetching it from the cluster
		if (defined($self->{validators})) {
			if ($self->{debug} == 1) {
				print STDERR "[DEBUG] using manually provided column family validation information\n";
			}

			$validators = $self->{validators};			
		} else {
			# otherwise - fetch the validators
			if ($self->{debug} == 1) {
				print STDERR "[DEBUG] refreshing column family information from Cassandra\n";
			}

			$validators = $self->get_validators(columnfamily => $current_cf, keyspace => $current_keyspace);
		}

		my %validators = %$validators;

		#refresh key validation class for this connected client
		@{$self->{key_validation}{$current_cf}} = @{$validators{key}};

		#refresh comparator type for this connected client
		@{$self->{comparators}{$current_cf}} = @{$validators{comparator}};
	 
		#refresh column value for this connected client
		@{$self->{value_validation}{$current_cf}} = @{$validators{column}};

		#refresh metadata validators (if they exist)
		$self->{metadata_validation}{$current_cf} = $validators{metadata};
	}
}

#####################################################################################################
# client_setup() checks to make sure the current open client for this object was created for
# the correct keyspace and columnfamily. Because all insert(), get() requests etc can be overloaded
# with 'keyspace' => 'myNewKeyspace' or 'columnfamily' => 'myNewColumnFamily' we need to make sure
# the client was created for these cf and keyspaces or Thrift/Cassandra will throw an exception
#####################################################################################################
sub client_setup() {
	my ($self, %opts) = @_;

	if (!defined($self->{columnfamily_inuse})) {
		if (defined($opts{columnfamily})) {
			$self->{columnfamily_inuse} = $opts{columnfamily};
		}
	}
	if (!defined($self->{keyspace_inuse})) {
		if (defined($opts{keyspace})) {
			$self->{keyspace_inuse} = $opts{keyspace};
		}
	}

	# check if we have already opened a client connection
	# if the user manually passed in a keyspace or column family to the insert call
	# check if the current connection is to that keyspace and column family
	# otherwise we need to disconnect and reconnect using that column family and keyspace
	if (!defined($self->{client})) {
		$self->setup($self->{keyspace});

		if (defined($opts{columnfamily})) {
			$self->{columnfamily_inuse} = $opts{columnfamily};
		}

		$self->perlcassa::Client::_refresh_cf_info(keyspace => $self->{keyspace});
		
	} elsif (defined($self->{client}) && defined($opts{keyspace}) && $opts{keyspace} ne $self->{keyspace_inuse}) {
		my $keyspace = $opts{keyspace} || $self->{keyspace};

		# just to be safe lets close the old client
		$self->close_conn();
		$self->setup($keyspace);

		if (defined($opts{columnfamily})) {
			$self->{columnfamily_inuse} = $opts{columnfamily};
		}

		if (defined($opts{keyspace})) {
			$self->{keyspace_inuse} = $keyspace;
		}

		$self->perlcassa::Client::_refresh_cf_info(keyspace => $keyspace);
	} elsif (defined($self->{client}) && defined($opts{columnfamily}) && $opts{columnfamily} ne $self->{columnfamily_inuse}) {
		my $keyspace = $opts{keyspace} || $self->{keyspace};
		$self->setup($keyspace);

		if (defined($opts{columnfamily})) {
			$self->{columnfamily_inuse} = $opts{columnfamily};
		}
		
		if (defined($opts{keyspace})) {
			$self->{keyspace_inuse} = $keyspace;
		}


		$self->perlcassa::Client::_refresh_cf_info(keyspace => $keyspace);
	} elsif (defined($self->{client}) || $opts{keyspace} eq $self->{keyspace_inuse} || $opts{columnfamily} eq $self->{columnfamily_inuse}) {
		#no need to reconnect client as it is already ready
	} else {
		$self->close_conn();
		$self->setup($opts{keyspace});

		if (defined($opts{columnfamily})) {
			$self->{columnfamily_inuse} = $opts{columnfamily};
		}

		$self->perlcassa::Client::_refresh_cf_info(keyspace => $opts{keyspace});
	}
}

1;
