package Test::More::Prefix::TB1;
$Test::More::Prefix::TB1::VERSION = '0.007';
# Load Test::More::Prefix for early versions of Test::Builder

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(test_prefix);

our $prefix = '';

sub import { __PACKAGE__->export_to_level(2, @_); }

sub test_prefix {
    $prefix = shift();
}

package Test::More::Prefix::ModifierRole;
$Test::More::Prefix::ModifierRole::VERSION = '0.007';
use strict;
use warnings;
use Moose::Role;

requires '_print_comment';
requires 'done_testing';

around '_print_comment' => sub {
    my ($orig, $self, $fh, @args) = @_;
    if ( $prefix && length( $prefix ) ) {
        @args = map {
            defined $_ ? "$prefix: $_" : $_
        } @args;
    }
    return $self->$orig( $fh, @args );
};

before 'done_testing' => sub {
    undef($prefix);
};

# mst told me to do this :-)
package Test::Builder;
$Test::Builder::VERSION = '0.007';
use Moose;
with 'Test::More::Prefix::ModifierRole';

1;