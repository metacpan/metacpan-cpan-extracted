package Test::Pockito::Exported;

use Exporter 'import';
use Test::Pockito;

use strict;
use warnings;


=head1 NAME

Test::Pockito::Exported - A version of Pockito that's more terse.

=head1 SETUP

=head1 SYNOPSIS

Creates a package level $pocket object within Test::Pockito::Exported and exports subs to interact with it.  Saves on typing.

=head1 DESCRIPTION

$pocket is handled for you.  Subs are exported into your namespace that interact with it.  Available to you without a reference to a Pockito object are

=over 1

=item * mock( @_ )

=item * when( .. )

=item * report_expected_calls

=item * expected_calls

=back

Some calls are created to access properties such as 'go', 'warn' and the underlying Pockito object itself.

=over 1

=item * setup( @_ ) performs a Test::Pockito->new( @_ ) and stores the object internally.

=item * whine sets 'warn' to 1 (on).

=item * go sets 'go' to 1

=item * stop sets 'stop' to 1

=head1 DESCRIPTION

=cut

our @EXPORT =
  qw(stop go setup whine mock when report_expected_calls expected_calls add_mock_strategy);
our @EXPORT_OK = @EXPORT;

our $object = Test::Pockito->new("_Pockito");

sub setup { $object = Test::Pockito->new(@_); }
sub mock  { $object->mock(@_) }
sub when  { $object->when(@_) }
sub report_expected_calls { $object->report_expected_calls(@_) }
sub expected_calls        { $object->expected_calls(@_) }
sub whine                 { $object->{'warn'} = 1 }
sub go                    { $object->{'go'} = 1 }
sub stop                  { $object->{'go'} = 0 }
1;
