package WebService::Amazon::DynamoDB::Server::Table;
$WebService::Amazon::DynamoDB::Server::Table::VERSION = '0.001';
use strict;
use warnings;

use Future;
use Future::Utils qw(repeat);

use WebService::Amazon::DynamoDB::Server::Item;
use Mixin::Event::Dispatch::Bus;

use constant DYNAMODB_INDEX_OVERHEAD => 100;

=head2 new

=cut

sub new { my $class = shift; bless {@_}, $class }

=head2 bus

The event bus used by this instance.

=cut

sub bus { shift->{bus} //= Mixin::Event::Dispatch::Bus->new }

=head2 name

=cut

sub name { shift->{TableName} // die 'invalid table - no name' }

sub state { shift->{TableStatus} }

=head2 item_by_id

=cut

sub item_by_id {
	my ($self, @id) = @_;
	my $k = $self->key_for_id(@id) // return Future->fail('bad key');
	exists $self->{items}{$k} or return Future->fail('item not found');
	Future->done($self->{items}{$k});
}

=head2 key_for_id

=cut

sub key_for_id {
	my ($self, @id) = @_;
	join "\0", map Encode::encode("UTF-8", $_), @id;
}

=head2 bytes_used

=cut

sub bytes_used {
	my ($self) = @_;
	$self->{bytes_used} //= do {
		my $total = 0;
		(repeat {
			shift->bytes_used->on_done(sub {
				$total += DYNAMODB_INDEX_OVERHEAD + shift
			})
		} foreach => [ @{$self->{items}} ],
		  otherwise => sub { Future->done($total) })
	}
}

=head2 validate_id_for_item_data

=cut

sub validate_id_for_item_data {
	my ($self, $data) = @_;
	my @id_fields = map $_->{AttributeName}, @{$self->{KeySchema}};
	return Future->fail(
		ValidationException =>
	) for grep !exists $data->{$_}, @id_fields;

	my ($id) = join "\0", map values %{$data->{$_}}, @id_fields;
	Future->done($id);
}

sub item_from_data {
	my ($self, $data) = @_;
	WebService::Amazon::DynamoDB::Server::Item->new(
		attributes => $data
	);
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

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.

