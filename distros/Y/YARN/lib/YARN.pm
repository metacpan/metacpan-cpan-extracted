package YARN;

# TODO: Write better/more test cases

use 5.006;
use strict;
use warnings;

use REST::Client;
use JSON;

use Data::Dumper;

use YARN::YarnClient;

BEGIN {
	$YARN::VERSION = '0.1';
}

our $client = '';

my %apis = (
	info => 'clusterInfo', 
	metrics => 'clusterMetrics', 
	scheduler => 'scheduler',
	apps => 'apps',
	);

sub new {
	my ($this, %opts) = @_;
	
	my $self = +{
		host => $opts{host} || 'localhost',
		port => $opts{port} || 8088,
		endpoint => $opts{endpoint} || '/ws/v1/cluster',
	};
	
	$client = YARN::YarnClient->createYarnClient( $self );
	
	return bless $self, $this;
}

# TODO: Rename below method to something meaningful
sub __req_api {
	my ($self, $api, $element) = @_;
	
	my $req = $client->connect( $self );
	my $rest = $req->GET( $client->api_path( $self, $api ) )->responseContent();
	
	if (defined $element) {
		return $self->findElementInJSON( $rest, $apis{$api}, $element );
	} else {
		return $rest;
	}
}

sub info		{ shift->__req_api( 'info', @_ ); }
sub metrics		{ shift->__req_api( 'metrics', @_ ); }
sub scheduler	{ shift->__req_api( 'scheduler', 'schedulerInfo', @_ ); }

sub getAllQueues {
	my $self = shift;
	
	my $req = $self->scheduler();
	
	my @queues;
	$queues[0] = $req->{'queueName'};
	
	push @queues, $self->recurse( $req, 'queues', $req->{'queueName'} );
	
	return @queues;
}

my @allQueues;

sub recurse {
	my ($self, $req, $element, $parent) = @_;
	
	if ( defined $req->{$element} ) {
		my @queues = @{ $req->{$element}->{'queue'} };
		
		foreach my $queue ( @queues ) {
			my $queueName = $parent . "." . $queue->{'queueName'};
			
			push @allQueues, $queueName;
			
			$self->recurse( $queue, 'queues', $queueName );
		}
	}
	
	return @allQueues;
}

sub getRootQueueInfos {
	my $self = shift;
	
	my $req = $self->scheduler();
}

sub findElementInJSON {
	my ($self, $rest, $root, $element) = @_;
	
	my $res = decode_json $rest;
	
	return $res->{$root}->{$element};
}

=head1 NAME

YARN - short for Yet Another Resource Negotiator (or if you prefer recursive acronyms, YARN Application Resource Negotiator).

=head2 VERSION

Version 0.01

=head1 SYNOPSIS

    use YARN;

    my $yarn = YARN->new( host => "hadoop-master.example.com" );
    
    print $client->info('id');

=head1 Methods

=head2 Construction and setup

=head3 new

Construct a new YARN.

=head2 ResourceManager REST API's

The ResourceManager REST API's allow the user to get information about the cluster - status on the cluster, metrics on the cluster, scheduler information, information about nodes in the cluster, and information about applications on the cluster.

=head3 info

The cluster information resource provides overall information about the cluster. Use this method to get general information about the cluster.
	
	# Returns a JSON String with the elements of the clusterInfo object
	$client->info();
	
	# Returns the value of an element from the clusterInfo object
	$client->info('id');

=head3 metrics

The cluster metrics resource provides some overall metrics about the cluster. Use this method to get metrics about the cluster.

	# Returns a JSON String with the elements of the clusterMetrics object
	$client->metrics();
	
	# Returns the value of an element from the metrics object
	$client->metrics('totalNodes');

=head3 scheduler

A scheduler resource contains information about the current scheduler configured in a cluster. It currently supports both the Fifo and Capacity Scheduler. 
You will get different information depending on which scheduler is configured so be sure to look at the type information.

# TODO: Fix 4 lines below
	# Returns a JSON String with the elements of the scheduler object
	$client->scheduler();
	
	# Returns the value of an element from the scheduler object
	$client->scheduler('XXX');

=head3 apps

With the Applications API, you can obtain a collection of resources, each of which represents an application. When you run a GET operation on this resource, you obtain a collection of Application Objects.

	# Returns a JSON String with the elements of the apps object
	$client->apps();
	
	# Returns the value of an element from the apps object
	$client->apps('XXX');

=head3 nodes

With the Nodes API, you can obtain a collection of resources, each of which represents a node. When you run a GET operation on this resource, you obtain a collection of Node Objects. 
Use this method to get a report of all nodes in the cluster.

	# Returns a JSON String with the elements of the nodes object
	$client->nodes();
	
	# Returns the value of an element from the nodes object
	$client->nodes('XXX');

=head3 node

A node resource contains information about a node in the cluster. Use this method to get a report of a node in the cluster.

	# Returns a JSON String with the elements of the node object
	$client->node();
	
	# Returns the value of an element from the node object
	$client->node('XXX');

=head3 getAllQueues

Returns an array with all queues defined in the scheduler.
	
	print Dumper $client->getAllQueues();
	$VAR1 = 'root';
	$VAR2 = 'root.parent1';
	$VAR3 = 'root.parent1.child1';
	$VAR5 = 'root.foo';
	$VAR6 = 'root.foo.f1';
	$VAR7 = 'root.foo.f2';
	$VAR8 = 'root.foo.f718';
	$VAR9 = 'root.bar';

=head3 getRootQueueInfos

Get information about top level queues.

=head1 AUTHOR

Ahmed Ossama, C<< <ahmed at aossama.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-yarn at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=YARN>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc YARN


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=YARN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/YARN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/YARN>

=item * Search CPAN

L<http://search.cpan.org/dist/YARN/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Ahmed Ossama.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


=cut

1; # End of YARN
