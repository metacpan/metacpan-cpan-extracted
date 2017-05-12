package WebService::Amazon::DynamoDB::20120810;
$WebService::Amazon::DynamoDB::20120810::VERSION = '0.005';
use strict;
use warnings;

use parent qw(WebService::Amazon::DynamoDB);

=head1 NAME

WebService::Amazon::DynamoDB::20120810 - interact with DynamoDB using API version 20120810

=head1 VERSION

version 0.005

=head1 DESCRIPTION

=cut

use Future;
use Future::Utils qw(try_repeat);
use POSIX qw(strftime);
use JSON::MaybeXS;
use Scalar::Util qw(reftype);
use B qw(svref_2object);
use HTTP::Request;

use WebService::Amazon::Signature;

=head2 new

Instantiates the API object.

Expects the following named parameters:

=over 4

=item * implementation - the object which provides a Future-returning C<request> method,
see L<WebService::Amazon::DynamoDB::NaHTTP> for example.

=item * uri - the base URI for constructing requests

=item * security - 'iam' or 'key'

=item * access_key - the access key for signing requests (only for security=key)

=item * secret_key - the secret key for signing requests (only for security=key)

=item * role - the role to use for requests (only for security=iam, usually autodetected from EC2 instance metadata)

=item * algorithm - which signing algorithm to use, default AWS4-HMAC-SHA256

=back

=cut

sub new {
	my $class = shift;
	bless { @_ }, $class
}

sub implementation { shift->{implementation} }
sub host { shift->{host} }
sub port { shift->{port} }
sub algorithm { 'AWS4-HMAC-SHA256' }
sub access_key { shift->{access_key} }
sub secret_key { shift->{secret_key} }
sub api_version { '20120810' }
sub json { shift->{json} //= JSON::MaybeXS->new }

=head2 security_token

=cut

sub security_token { shift->{security_token} }


=head2 create_table

Creates a new table. It may take some time before the table is marked
as active - use L</wait_for_table> to poll until the status changes.

Named parameters:

=over 4

=item * table - the table name

=item * read_capacity - expected read capacity units (optional, default 5)

=item * write_capacity - expected write capacity units (optional, default 5)

=item * fields - an arrayref specifying the fields, in pairs of (name, type),
where type is N for numeric, S for string, SS for string sequence, B for binary
etc.

=item * primary - the primary keys as an arrayref of pairs indicating (name, type),
default type is hash so ['pkey'] would create a single HASH primary key

=back

=cut

sub create_table {
	my $self = shift;
	my %args = @_;
	my %payload = (
		TableName => $args{table},
		ProvisionedThroughput => {
			ReadCapacityUnits => $args{read_capacity} || 5,
			WriteCapacityUnits => $args{write_capacity} || 5,
		}
	);
	my @fields = @{$args{fields}};
	my %field;
	while(my ($k, $type) = splice @fields, 0, 2) {
		$field{$k} = $type;
		push @{$payload{AttributeDefinitions} }, {
			AttributeName => $k,
			AttributeType => $type || 'S',
		}
	}
	my @primary = @{$args{primary} || []};
	while(my ($k, $type) = splice @primary, 0, 2) {
		die "Unknown field $k" unless exists $field{$k};
		push @{$payload{KeySchema} }, {
			AttributeName => $k,
			KeyType       => $type || 'HASH',
		}
	}
	$self->make_request(
		target => 'CreateTable',
		payload => \%payload,
	)->then(sub {
		$self->_request(shift)
	})
}

=head2 describe_table

Describes the given table.

Takes a single named parameter:

=over 4

=item * table - the table name

=back

and returns the table spec.

=cut

sub describe_table {
	my $self = shift;
	my %args = @_;
	my %payload = (
		TableName => $args{table},
	);
	$self->make_request(
		target => 'DescribeTable',
		payload => \%payload,
	)->then(sub {
		$self->_request(shift)->transform(
			# Sadly not the same key as used in DeleteTable
			done => sub { my $content = shift; $self->json->decode($content)->{Table}; }
		);
	})
}

=head2 delete_table

Delete a table entirely.

Takes a single named parameter:

=over 4

=item * table - the table name

=back

=cut

sub delete_table {
	my $self = shift;
	my %args = @_;
	my %payload = (
		TableName => $args{table},
	);
	$self->make_request(
		target => 'DeleteTable',
		payload => \%payload,
	)->then(sub {
		$self->_request(shift)->transform(
			# Sadly not the same key as used in DescribeTable
			done => sub { my $content = shift; $self->json->decode($content)->{TableDescription} }
		)
	})
}

=head2 wait_for_table

Waits for the given table to be marked as active.

Takes a single named parameter:

=over 4

=item * table - the table name

=back

=cut

sub wait_for_table {
	my $self = shift;
	my %args = @_;
	try_repeat {
		$self->describe_table(%args)
	} until => sub {
		my $f = shift;
		my $status = $f->get->{TableStatus};
#		warn "status: " . $status; 
		$status eq 'ACTIVE'
	};
}

=head2 each_table

Run code for all current tables.

Takes a coderef as the first parameter, will call this for each table found.

=cut

sub each_table {
	my $self = shift;
	my $code = shift;
	my %args = @_;
	my %payload;
	my $last_table;
	try_repeat {
		$payload{ExclusiveStartTableName} = $args{start} if defined $args{start};
		$payload{Limit} = $args{limit} if defined $args{limit};
		$self->make_request(
			target => 'ListTables',
			payload => \%payload,
		)->then(sub {
			$self->_request(shift)
		})->on_done(sub {
			my $rslt = shift;
			my $data = $self->json->decode($rslt);
			for my $tbl (@{$data->{TableNames}}) {
				$code->($tbl);
			}
			$last_table = $data->{LastEvaluatedTableName};
			$args{start} = $last_table;
		});
	} while => sub {
#		warn "Checking @_ => $last_table\n";
		defined $last_table
	};
}

=head2 list_tables

Returns a L<Future> which will resolve with a list of all tables.

Takes no parameters.

 $ddb->list_tables->on_done(sub {
  my @tbl = @_;
  print "Table: $_\n" for @tbl;
 });

=cut

sub list_tables {
	my $self = shift;
	my @tbl;
	$self->each_table(sub {
		push @tbl, shift
	})->transform(
		done => sub { @tbl }
	);
}

=head2 put_item

Writes a single item to the table.

Takes the following named parameters:

=over 4

=item * table - the table name

=item * fields - the field spec, as a { key => value } hashref

=back

=cut

sub put_item {
	my $self = shift;
	my %args = @_;

	my %payload = (
		TableName => $args{table},
		ReturnConsumedCapacity => $args{capacity} ? 'TOTAL' : 'NONE',
	);
	foreach my $k (keys %{$args{fields}}) {
		my $v = $args{fields}{$k};	
		$payload{Item}{$k} = { type_and_value($v) };
	}

	$self->make_request(
		target => 'PutItem',
		payload => \%payload,
	)->then(sub {
		$self->_request(shift)->transform(
			# Sadly not the same key as used in DeleteTable
			done => sub { $self->json->decode(shift)->{Table}; }
		);
	})
}

=head2 update_item

Updates a single item in the table.

Takes the following named parameters:

=over 4

=item * table - the table name

=item * item - the item to update, as a{ key => value } hashref

=item * fields - the field spec, as a { key => value } hashref

=back

=cut

sub update_item {
	my $self = shift;
	my %args = @_;

	my %payload = (
		TableName => $args{table},
		ReturnConsumedCapacity => $args{capacity} ? 'TOTAL' : 'NONE',
	);
	foreach my $k (keys %{$args{item}}) {
		my $v = $args{item}{$k};	
		$payload{Key}{$k} = { type_and_value($v) };
	}
	foreach my $k (keys %{$args{fields}}) {
		my $v = $args{fields}{$k};	
		$payload{AttributeUpdates}{$k} = {
			Action => $args{action} || 'PUT',
			Value => { type_and_value($v) }
		};
	}

	my $req = $self->make_request(
		target => 'UpdateItem',
		payload => \%payload,
	)->then(sub {
		$self->_request(shift)->transform(
			done => sub { $self->json->decode(shift) }
		);
	})
}

=head2 delete_item

Deletes a single item from the table.

Takes the following named parameters:

=over 4

=item * table - the table name

=item * item - the item to delete, as a { key => value } hashref

=back

=cut

sub delete_item {
	my $self = shift;
	my %args = @_;

	my %payload = (
		TableName => $args{table},
		ReturnConsumedCapacity => $args{capacity} ? 'TOTAL' : 'NONE',
	);
	foreach my $k (keys %{$args{item}}) {
		my $v = $args{item}{$k};	
		$payload{Key}{$k} = { type_and_value($v) };
	}

	my $req = $self->make_request(
		target => 'DeleteItem',
		payload => \%payload,
	)->then(sub {
		$self->_request(shift)->transform(
			done => sub { $self->json->decode(shift) }
		);
	})
}

=head2 batch_get_item

Retrieve a batch of items from one or more tables.

Takes a coderef which will be called for each found item, followed by
these named parameters:

=over 4

=item * items - the search spec, as { table => { attribute => 'value', ... }, ... }

=back

=cut

sub batch_get_item {
	my $self = shift;
	my $code = shift;
	my %args = @_;
	my %payload = (
		ReturnConsumedCapacity => $args{capacity} ? 'TOTAL' : 'NONE',
	);
	for my $tbl (keys %{$args{items}}) {
		my $item = $args{items}{$tbl};
		my @keys = @{$item->{keys}};
		$payload{RequestItems}{$tbl}{Keys} = [];
		while(my ($k, $v) = splice @keys, 0, 2) {
			push @{$payload{RequestItems}{$tbl}{Keys}}, {
				$k => {
					type_and_value($v)
				}
			};
		}
	}

	my $finished = 0;
	try_repeat {
		my $req = $self->make_request(
			target => 'BatchGetItem',
			payload => \%payload,
		)->then(sub {
			$self->_request(shift)
		})->on_done(sub {
			my $rslt = shift;
			my $data = $self->json->decode($rslt);
			my @resp = %{$data->{Responses}};
			# { Something => [ { Name => { S => 'text' } } ] }
			while(my ($k, $v) = splice @resp, 0, 2) {
				for my $entry (@$v) {
					$code->($k => {
						map {; $_ => values %{$entry->{$_}} } keys %$entry
					});
				}
			}
			$args{RequestItems} = $data->{UnprocessedKeys};
			$finished = 1 unless keys %{$data->{UnprocessedKeys}};
		});
	} until => sub { $finished };
}

=head2 scan

Scan a table for values with an optional filter expression.

=cut

sub scan {
	my $self = shift;
	my $code = shift;
	my %args = @_;
	my %payload = (
		TableName => $args{table},
		ReturnConsumedCapacity => $args{capacity} ? 'TOTAL' : 'NONE',
	);
	$payload{AttributesToGet} = $args{fields};
	$payload{Limit} = $args{limit} if exists $args{limit};
	my %filter;
	for my $f (@{$args{filter}}) {
		$filter{$f->{field}} = {
			AttributeValueList => [ {
				type_and_value($f->{value})
			} ],
			ComparisonOperator => $f->{compare} || 'EQ',
		}
	}
	$payload{ScanFilter} = \%filter if %filter;
	my $finished = 0;
	my $count = 0;
	try_repeat {
		$self->make_request(
			target => 'Scan',
			payload => \%payload,
		)->then(sub {
			$self->_request(shift)
		})->on_done(sub {
			my $rslt = shift;
			my $data = $self->json->decode($rslt);
			for my $entry (@{$data->{Items}}) {
				$code->({
					map {; $_ => values %{$entry->{$_}} } keys %$entry
				});
			}
			$count += $data->{Count};
			$args{ExclusiveStartKey} = $data->{LastEvaluatedKey};
			$finished = 1 unless keys %{$data->{LastEvaluatedKey}};
		});
	} until => sub { $finished };
}

=head1 METHODS - Internal

The following methods are intended for internal use and are documented
purely for completeness - for normal operations see L</METHODS> instead.

=cut

sub scope {
	my $self = shift;
	join '/', strftime('%Y%m%d', gmtime), $self->region, qw(dynamodb aws4_request)
}

sub region { shift->{region} //= 'us-west-1' }

=head1 FUNCTIONS - Internal

=head2 type_for_value

Returns an appropriate type (N, S, SS etc.) for the given
value.

Rules are similar to L<JSON> - if you want numeric, numify (0+$value),
otherwise you'll get a string.

=cut

sub type_for_value {
	my $v = shift;
	if(my $ref = reftype($v)) {
		# An array maps to a sequence
		if($ref eq 'ARRAY') {
			my $flags = B::svref_2object(\$v)->FLAGS;
			# Any refs mean we're sending binary data
			return 'BS' if grep ref($_), @$v;
			# Any stringified values => string data
			return 'SS' if grep $_ & B::SVp_POK, map B::svref_2object(\$_)->FLAGS, @$v;
			# Everything numeric? Send as a number
			return 'NS' if @$v == grep $_ & (B::SVp_IOK | B::SVp_NOK), map B::svref_2object(\$_)->FLAGS, @$v;
			# Default is a string sequence
			return 'SS';
		} else {
			return 'B';
		}
	} else {
		my $flags = B::svref_2object(\$v)->FLAGS;
		return 'S' if $flags & B::SVp_POK;
		return 'N' if $flags & (B::SVp_IOK | B::SVp_NOK);
		return 'S';
	}
}

=head2 type_and_value

Returns a pair of (type, value), using L</type_for_value>.

=cut

sub type_and_value {
	my $v = shift;
	my $type = type_for_value($v);
	return $type, "$v" unless my $ref = ref $v;
	return $type, [ map "$_", @$v ] if $ref eq 'ARRAY';
	return $type, { map {; $_ => ''.$v->{$_} } keys %$v } if $ref eq 'HASH';
	return $type, "$v";
}

sub validate_table_name {
	my ($self, $name) = @_;
	die 'Table name is undefined' unless defined $name;
	die 'Name too short' if length($name) < 3;
	die 'Name too long' if length($name) > 255;
	die 'Invalid characters in name' if $name =~ /[^a-zA-Z0-9_.-]/;
	return 1;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
