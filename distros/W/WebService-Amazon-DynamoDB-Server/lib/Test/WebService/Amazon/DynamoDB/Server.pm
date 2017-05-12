package Test::WebService::Amazon::DynamoDB::Server;
$Test::WebService::Amazon::DynamoDB::Server::VERSION = '0.001';
use strict;
use warnings;

use parent qw(Exporter);

=head1 NAME

Test::WebService::Amazon::DynamoDB - functions for testing the DynamoDB code

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Mostly intended as convenience functions for the 
L<WebService::Amazon::DynamoDB::Server> test suite.

=cut

BEGIN {
	our @EXPORT = our @EXPORT_OK = qw(
		fmap_over
		ddb_server
		expect_events
		add_table
	);
}

use WebService::Amazon::DynamoDB::Server;

use Test::More;
use Future::Utils qw(fmap repeat call);

our $SRV;

sub fmap_over(&;@) {
	my ($code, %args) = @_;
	my @result;
	(repeat {
		(shift || Future->done)->then(sub {
			my $last = shift;
			call {
				$code->($last)->on_done(sub {
					push @result, @_
				})
			}
		})
	} (exists $args{while}
		? (
			while => sub {
				!@_ || $args{while}->(shift->get)
			}
		) :()
	))->transform(done => sub {
		$args{map} ? (map $args{map}->($_), @result) : @result
	})
}

=head2 ddb_server

Runs a block of code with a custom L<WebService::Amazon::DynamoDB::Server> instance.

Primarily intended as a visual aid to allow setting
up the test spec:

 my $srv = ddb_server {
  add_table name => 'xyz', ...;
  expect_events {
   put_item => 3,
   get_item => 4,
   describe_table => 1
  }
 };
 ...

Returns that instance when done.

=cut

sub ddb_server(&;@) {
	my ($code) = shift;
	local $SRV = new_ok('WebService::Amazon::DynamoDB::Server');
	$code->($SRV);
	$SRV
}

=head2 add_table

Adds the given table spec.

=cut

sub add_table(@) {
	my %args = @_;
	$SRV->add_table(%args);
}

=head2 expect_events

Indicates that we're expecting certain events to fire.

 expect_events {
  create_table => 7,
  delete_table => 2,
  put_item => 5
 }

=cut

sub expect_events($) {
	my $stat = shift;

	my $event_info = {
		create_table => sub {
			my ($tbl) = @_;
			isa_ok($tbl, 'WebService::Amazon::DynamoDB::Server::Table') or note explain $tbl;
		},
		delete_table => sub {
			my ($tbl) = @_;
			isa_ok($tbl, 'WebService::Amazon::DynamoDB::Server::Table') or note explain $tbl;
		},
		update_table => sub {
			my ($tbl) = @_;
			isa_ok($tbl, 'WebService::Amazon::DynamoDB::Server::Table') or note explain $tbl;
		},
		describe_table => sub {
			my ($tbl) = @_;
			isa_ok($tbl, 'WebService::Amazon::DynamoDB::Server::Table') or note explain $tbl;
		},
		list_tables => sub {
			my ($tables) = @_;
			isa_ok($tables, 'ARRAY') or note explain $tables;
			for(grep !$_->isa('WebService::Amazon::DynamoDB::Server::Table'), @$tables) {
				fail("unexpected entry in tables");
				note explain $_;
			}
		},
		get_item => sub {
			my ($tbl, $item) = @_;
			isa_ok($tbl, 'WebService::Amazon::DynamoDB::Server::Table') or note explain $tbl;
			isa_ok($item, 'WebService::Amazon::DynamoDB::Server::Item') or note explain $item;
		},
		put_item => sub {
			my ($tbl, $item) = @_;
			isa_ok($tbl, 'WebService::Amazon::DynamoDB::Server::Table') or note explain $tbl;
			isa_ok($item, 'WebService::Amazon::DynamoDB::Server::Item') or note explain $item;
		}
	};
	for (sort keys %$event_info) {
		my $k = $_;
		my $code = $event_info->{$k};
		$SRV->bus->subscribe_to_event(
			$k => sub {
				my ($ev, $req, $rslt, @extra) = @_;
				note "Had $k event";
				# Reduce pending count for this type - we're aiming for 0
				--$stat->{$k} if exists $stat->{$k};
				isa_ok($req, 'HASH') or note explain $req;
				isa_ok($rslt, 'Future') or note explain $rslt;
				ok($rslt->is_ready, '... and it is ready');
				if($rslt->failure) {
					like($rslt->failure, qr/Exception/, 'had the word "exception" somewhere');
				} else {
					$code->(@extra);
				}
			}
		);
	}

	# Report on status when our object is cleaned up
	$SRV->bus->subscribe_to_event(
		destroy => sub {
			my ($ev, $srv) = @_;
			is($stat->{$_}, 0, $_ . ' events triggered as expected') for sort keys %$stat;
		}
	)
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
