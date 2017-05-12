package WebService::Amazon::DynamoDB::Server;
# ABSTRACT: Perl implementation of the DynamoDB server API, for testing

use strict;
use warnings;

our $VERSION = '0.001';

=head1 NAME

WebService::Amazon::DynamoDB - perl server implementation for the AWS DynamoDB API

=head1 VERSION

version 0.001

=head1 DESCRIPTION

=cut

use Mixin::Event::Dispatch::Bus;

use Encode;
use Future;
use Future::Utils qw(call);
use List::Util qw(min);
use List::UtilsBy qw(extract_by sort_by);
use Time::Moment;

use WebService::Amazon::DynamoDB::Server::Table;
use WebService::Amazon::DynamoDB::Server::Item;

use constant LIST_TABLES_MAX => 100;

our %API_METHODS = map {; $_ => 1 } qw(
	list_tables
	create_table
	delete_table
	update_table
	describe_table
	get_item
	put_item
);

=head1 METHODS

=cut

=head2 new

=cut

sub new { my $class = shift; bless {@_}, $class }

=head2 list_tables

Takes the following named parameters:

=over 4

=item * ExclusiveStartTableName

=item * Limit

=back

Resolves to a hashref containing the following data:

=over 4

=item * LastEvaluatedTableName

=item * TableNames

=back

ListTables (p. 58)

=cut

sub list_tables {
	my ($self, %args) = @_;
	my $req = { %args };

	my @tables = sort_by { $_->name } @{$self->{tables}};
	if(exists $args{ExclusiveStartTableName}) {
		return $self->fail(
			list_tables => $req,
			'ValidationException: table ' . $args{ExclusiveStartTableName} . ' not found', 
		) unless $self->have_table($args{ExclusiveStartTableName});

		shift @tables while @tables && $tables[0]->name ne $args{ExclusiveStartTableName};
	}
	my $limit = min(LIST_TABLES_MAX, $args{Limit} // ());
	my %result;
	if(@tables > $limit) {
		my ($last) = splice @tables, $limit;
		$result{LastEvaluatedTableName} = $last->name;
	}
	$result{TableNames} = [ map $_->name, @tables ];
	$self->done(list_tables => \%result, $req, \@tables)
}

=head2 create_table

CreateTable (p. 22)

=cut

sub create_table {
	my ($self, %args) = @_;
	my $req = { %args };

	return $self->fail(
		create_table => $req,
		'ValidationException - no AttributeDefinitions found'
	) unless exists $args{AttributeDefinitions};

	return $self->fail(
		create_table => $req,
		'ValidationException - no KeySchema found'
	) unless exists $args{KeySchema};

	return $self->fail(
		create_table => $req,
		'ValidationException - empty KeySchema found'
	) unless @{$args{KeySchema}};

	return $self->fail(
		create_table => $req,
		'ValidationException - too many items found in KeySchema'
	) if @{$args{KeySchema}} > 2;

	return $self->fail(
		create_table => $req,
		'ValidationException - invalid KeyType, expected HASH'
	) unless ($args{KeySchema}[0]{KeyType} // '') eq 'HASH';

	return $self->fail(
		create_table => $req,
		'ValidationException - invalid KeyType, expected RANGE'
	) if @{$args{KeySchema}} > 1 && ($args{KeySchema}[1]{KeyType} // '') ne 'RANGE';

	my %attr = map {; $_->{AttributeName} => $_ } @{$args{AttributeDefinitions}};
	return $self->fail(
		create_table => $req,
		'ValidationException - attribute ' . $_ . ' not found in AttributeDefinitions'
	) for grep !exists $attr{$_}, map $_->{AttributeName}, @{$args{KeySchema}};

	return $self->fail(
		create_table => $req,
		'ValidationException - no ProvisionedThroughput found'
	) unless exists $args{ProvisionedThroughput};

	return $self->fail(
		create_table => $req,
		'ValidationException - no ProvisionedThroughput found'
	) unless exists $args{TableName};

	return $self->fail(
		create_table => $req,
		'ResourceInUseException - this table exists already'
	) if $self->have_table($args{TableName});

	$args{TableStatus} = 'CREATING';
	$args{ItemCount} = 0;
	$args{TableSizeBytes} = 0;
	$args{CreationDateTime} = Time::Moment->now;
	my $tbl = $self->add_table(%args);
	$self->done(create_table => {
		TableDescription => {
			%args,
			CreationDateTime => $args{CreationDateTime}->to_string,
		}
	}, $req, $tbl);
}

=head2 describe_table

DescribeTable (p. 47)

=cut

sub describe_table {
	my ($self, %args) = @_;
	my $req = { %args };

	my $name = delete $args{TableName};
	$self->validate_table_state($name => 'ACTIVE')->then(sub {
		my $tbl = $self->{table_map}{$name};
		$self->done(describe_table => {
			Table => $tbl
		}, $req, $tbl)
	}, sub {
		$self->fail(describe_table => $req, @_)
	})
}

=head2 update_table

UpdateTable (p. 119)

=cut

sub update_table {
	my ($self, %args) = @_;
	my $req = { %args };

	my $name = delete $args{TableName};
	$self->validate_table_state($name => 'ACTIVE')->then(sub {
		my $tbl = $self->{table_map}{$name};
		my %update;
		if(my $throughput = delete $args{ProvisionedThroughput}) {
			$update{ProvisionedThroughput}{$_} = $throughput->{$_} for grep exists $throughput->{$_}, qw(ReadCapacityUnits WriteCapacityUnits);
		}
		if(my $index = delete $args{GlobalSecondaryIndexUpdates}) {
			$update{GlobalSecondaryIndexUpdates}{$_} = $index->{$_} for keys %$index;
		}
		return $self->fail(
			update_table => $req,
			'ValidationException - invalid keys provided'
		) if keys %args;
		for my $k (keys %update) {
			$tbl->{$k}{$_} = $update{$k}{$_} for keys %{$update{$k}};
		}
		$self->table_status($name => 'UPDATING')->then(sub {
			$self->done(update_table => {
				TableDescription => $tbl
			}, $req, $tbl)
		})
	}, sub {
		$self->fail(update_table => $req, @_)
	})
}

=head2 delete_table

DeleteTable (p. 43)

=cut

sub delete_table {
	my ($self, %args) = @_;
	my $req = { %args };

	my $name = delete $args{TableName};
	$self->validate_table_state($name => qw(ACTIVE DELETING))->then(sub {
		return $self->fail(
			delete_table => $req,
			'ValidationException - invalid keys provided'
		) if keys %args;
		my $tbl = $self->{table_map}{$name};
		$self->table_status($name => 'DELETING')->then(sub {
			$self->done(delete_table => {
				TableDescription => $tbl
			}, $req, $tbl)
		})
	}, sub {
		$self->fail(delete_table => $req, @_)
	})
}

=head2 put_item

PutItem (p. 61)

=cut

sub put_item {
	my ($self, %args) = @_;
	my $req = { %args };

	my $name = delete $args{TableName};
	$self->validate_table_state($name => 'ACTIVE')->then(sub {
		my $tbl = $self->{table_map}{$name};
		$tbl->validate_id_for_item_data($args{Item})->then(sub {
			my $id = shift;
			my $new = !exists $self->{data}{$name}{$id};
			my $item = $tbl->item_from_data(delete $args{Item});
			$self->{data}{$name}{$id} = $item;

			my %result;
			Future->needs_all(
				$self->return_values(delete $args{ReturnValues}),
				$self->consumed_capacity(delete $args{ReturnConsumedCapacity}),
				$self->collection_metrics(delete $args{ReturnItemCollectionMetrics}),
			)->then(sub {
				# Only add the keys if they were requested
				for(qw(Attributes ConsumedCapacity ItemCollectionMetrics)) {
					my $k = shift;
					$result{$_} = $k if defined $k
				}

				# Commit the changes
				++$tbl->{ItemCount} if $new;
				$tbl->{TableSizeBytes} += length Encode::decode('UTF-8', $id);

				$self->done(put_item => \%result, $req, $tbl, $item);
			}, sub {
				$self->fail(put_item => $req, @_)
			});
		}, sub {
			$self->fail(put_item => $req, @_)
		})
	}, sub {
		$self->fail(put_item => $req, @_)
	})
}

=head2 get_item

GetItem (p. 52)

=cut

sub get_item {
	my ($self, %args) = @_;
	my $req = { %args };

	my $name = delete $args{TableName};
	$self->validate_table_state($name => 'ACTIVE')->then(sub {
		my $tbl = $self->{table_map}{$name};
		$tbl->validate_id_for_item_data($args{Key})->then(sub {
			my $id = shift;
			my %result;
			my $item;
			if(exists $self->{data}{$name}{$id}) {
				$item = $result{Item} = $self->{data}{$name}{$id}
			}
			return $self->consumed_capacity(delete $args{ReturnConsumedCapacity})->then(sub {
				# Only add the keys if they were requested
				for(qw(ConsumedCapacity)) {
					my $k = shift;
					$result{$_} = $k if defined $k
				}
				return $self->done(get_item => \%result, $req, $tbl, $item);
			}, sub {
				$self->fail(get_item => $req, @_)
			})
		}, sub {
			$self->fail(get_item => $req, @_)
		})
	}, sub {
		$self->fail(get_item => $req, @_)
	})
}

=head2 update_item

UpdateItem (p. 103)

=cut

sub update_item {
	my ($self, %args) = @_;
	my $req = { %args };

	my $name = delete $args{TableName};
	$self->validate_table_state($name => 'ACTIVE')->then(sub {
		my $tbl = $self->{table_map}{$name};
		$tbl->validate_id_for_item_data($args{Key})->then(sub {
			my $id = shift;
			my %result;
			my $item;
			if(exists $self->{data}{$name}{$id}) {
				$item = $result{Item} = $self->{data}{$name}{$id}
			}
			return $self->consumed_capacity(delete $args{ReturnConsumedCapacity})->then(sub {
				# Only add the keys if they were requested
				for(qw(ConsumedCapacity)) {
					my $k = shift;
					$result{$_} = $k if defined $k
				}
				return $self->done(update_item => \%result, $req, $item);
			})
		})
	})
}

=head2 METHODS - Internal

The following methods are not part of the standard DynamoDB public API,
so they are not recommended for use directly.

=cut

sub bus { shift->{bus} //= Mixin::Event::Dispatch::Bus->new }

=head2 add_table

Adds this table - called by L</create_table> if everything passes validation.

=cut

sub add_table {
	my ($self, %args) = @_;
	$args{TableName} = delete $args{name} if exists $args{name};
	my $tbl = WebService::Amazon::DynamoDB::Server::Table->new(
		%args
	);
	push @{$self->{tables}}, $tbl;
	$self->{table_map}{$tbl->name} = $tbl;
	$tbl
}

=head2 drop_table

Drops the table - called to remove a table that was previously in 'DELETING' state.

=cut

sub drop_table {
	my ($self, %args) = @_;
	$args{TableName} = delete $args{name} if exists $args{name};
	my $name = $args{TableName};
	extract_by { $_->name eq $name } @{$self->{tables}} or return Future->fail('table not found');
	delete $self->{table_map}{$name} or return Future->fail('table not found in map');
	Future->done
}

=head2 return_values

Resolves to the attributes requested for this update.

=cut

sub return_values {
	my ($self, $v) = @_;
	return Future->done(undef) if !defined($v) || $v eq 'NONE';
	if($v eq 'ALL_OLD') {
		return Future->done({ })
	} else {
		return Future->fail(
			ValidationException =>
		)
	}
}

=head2 consumed_capacity

Returns consumed capacity information if available.

=cut

sub consumed_capacity {
	my ($self, $v) = @_;
	return Future->done(undef) if !defined($v) || $v eq 'NONE';
	if($v eq 'INDEXES') {
		return Future->done({ })
	} elsif($v eq 'TOTAL') {
		return Future->done({ })
	} else {
		return Future->fail(
			ValidationException =>
		)
	}
}

=head2 collection_metrics

Resolves to collection metrics information, if available.

=cut

sub collection_metrics {
	my ($self, $v) = @_;
	return Future->done(undef) if !defined($v) || $v eq 'NONE';
	if($v eq 'SIZE') {
		return Future->done({ })
	} else {
		return Future->fail(
			ValidationException =>
		)
	}
}

my %valid_table_status = map {; $_ => 1 } qw(CREATING DELETING UPDATING ACTIVE);

=head2 table_status

Update or return current table status.

=cut

sub table_status {
	my ($self, $name, $status) = @_;
	if(defined $status) {
		return Future->fail('bad status') unless exists $valid_table_status{$status};
		$self->{table_map}{$name}{TableStatus} = $status
	}
	Future->done($self->{table_map}{$name}{TableStatus});
}

=head2 have_table

Returns true if we have this table.

=cut

sub have_table {
	my ($self, $name) = @_;
	return scalar exists $self->{table_map}{$name};
}

=head2 validate_table_state

Raises various exceptions based on table state.

=cut

sub validate_table_state {
	my ($self, $name, @allowed) = @_;

	return Future->fail(
		'ResourceNotFoundException'
	) unless defined $name;

	return Future->fail(
		'ResourceNotFoundException'
	) unless $self->have_table($name);

	my $status = $self->{table_map}{$name}{TableStatus};
	return Future->fail(
		'ResourceInUseException'
	) unless grep $status eq $_, @allowed;

	Future->done;
}

sub fail {
	my ($self, $sub, $req, $exception, @details) = @_;
	return Future->fail('invalid API name ' . $sub) unless exists $API_METHODS{$sub};
	my $f = Future->fail($exception => @details);
	$self->bus->invoke_event($sub => $req, $f);
	$self->bus->invoke_event(error => $req, $f);
	$f
}

use Carp qw(confess);
sub done {
	my ($self, $sub, $rslt, $req, @details) = @_;
	confess 'wtf' unless defined $sub;
	return Future->fail('invalid API name ' . $sub) unless exists $API_METHODS{$sub};
	my $f = Future->done($rslt);
	$self->bus->invoke_event($sub => $req, $f, @details);
	$f
}

sub DESTROY {
	my ($self) = @_;
	$self->bus->invoke_event(destroy => );
}

1;

__END__

=head1 EVENTS

The following events may be raised on the message bus used by this
class - use L<Mixin::Event::Dispatch/subscribe_to_event> to watch
for them:

 $srv->bus->subscribe_to_event(
   list_tables => sub {
     my ($ev, $tables, $req, $resp) = @_;
	 ...
   }
 );

Note that most of these include a L<Future> - the event is triggered
once the L<Future> is marked as ready, so it should be safe to call
C< get > to examine the current state:

 $srv->bus->subscribe_to_event(
   create_table => sub {
     my ($ev, $tbl, $req, $resp) = @_;
	 warn "Had a failed table creation request" unless eval { $resp->get };
   }
 );

=head2 list_tables event

List tables request.

=over 4

=item * $request - the original request, as a hashref

=item * $response - the response that will be sent back to the client, as a L<Future>

=item * $tbl - an array of L<WebService::Amazon::DynamoDB::Server::Table> instances

=back

=head2 describe_table event

Describe table request.

=over 4

=item * $request - the original request, as a hashref

=item * $response - the response that will be sent back to the client, as a L<Future>

=item * $tbl - the L<WebService::Amazon::DynamoDB::Server::Table> instance, may be undef

=back

=head2 create_table event

Called when have had a table creation request.

=over 4

=item * $request - the original request which caused the creation, as a hashref

=item * $response - the response that will be sent back to the client, as a L<Future>

=item * $tbl - the new L<WebService::Amazon::DynamoDB::Server::Table> instance, may be undef

=back

=head2 update_table event

A table update request.

=over 4

=item * $request - the original request which caused the creation, as a hashref

=item * $response - the response that will be sent back to the client, as a L<Future>

=item * $tbl - the L<WebService::Amazon::DynamoDB::Server::Table> instance, may be undef

=back

=head2 delete_table event

Called when we have had a table deletion request.

=over 4

=item * $request - the original request which caused the creation, as a hashref

=item * $response - the response that will be sent back to the client, as a L<Future>

=item * $tbl - the L<WebService::Amazon::DynamoDB::Server::Table> instance that will be deleted, may be undef

=back

=head2 get_item event

Get item request.

=over 4

=item * $request - the original request, as a hashref

=item * $response - the response that will be sent back to the client, as a L<Future>

=item * $tbl - the L<WebService::Amazon::DynamoDB::Server::Table> instance, may be undef

=item * $item - the L<WebService::Amazon::DynamoDB::Server::Item> instance, may be undef

=back

=head2 put_item event

Put item request.

=over 4

=item * $request - the original request, as a hashref

=item * $response - the response that will be sent back to the client, as a L<Future>

=item * $tbl - the L<WebService::Amazon::DynamoDB::Server::Table> instance, may be undef

=item * $item - the L<WebService::Amazon::DynamoDB::Server::Item> instance, may be undef

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
