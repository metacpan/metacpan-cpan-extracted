package Test::Kantan::Suite;
use strict;
use warnings;
use utf8;
use 5.010_001;

use Moo;

has title => ( is => 'ro', required => 1 );
has root => ( is => 'ro' );
has parent => ( is => 'ro' );
has triggers => ( is => 'ro', default => sub { +{} } );

no Moo;

sub call_trigger {
    my ($self, $trigger_name) = @_;
    for my $trigger (@{$self->{triggers}->{$trigger_name}}) {
        $trigger->();
    }
}

sub add_trigger {
    my ($self, $trigger_name, $code) = @_;
    push @{$self->{triggers}->{$trigger_name}}, $code;
}

1;

