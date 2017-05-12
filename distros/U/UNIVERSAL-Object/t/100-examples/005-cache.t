#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object');
}

=pod
{
    package Cache;
    use Moose;

    has fetcher => (is => 'ro', required => 1);
    has data => (
        is        => 'rw',
        lazy      => 1,
        builder   => '_fetch_data',
        predicate => 'has_data',
        clearer   => 'clear'
    );

    sub _fetch_data {
        (shift)->fetcher->()
    }
}
=cut

{
    package Cache;
    use strict;
    use warnings;

    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
    our %HAS; BEGIN {
        %HAS = (
            fetcher => sub { die 'fetcher is required' },
            data    => sub { undef }
        )
    }

    sub data {
        my $self = $_[0];
        # lazyily fetch data
        $self->{data} = $self->_fetch_data 
            unless defined $self->{data};
        $self->{data}
    }

    sub has_data { defined $_[0]->{data} }
    sub clear    {   undef $_[0]->{data} }

    sub _fetch_data { $_[0]->{fetcher}->() }
}

my @data = qw[
    one
    two
    three
];

{
    my $c = Cache->new( fetcher => sub { shift @data } );
    isa_ok($c, 'Cache');

    is($c->data, 'one', '... the data we got is correct');
    ok($c->has_data, '... we have data');

    $c->clear;

    is($c->data, 'two', '... the data we got is correct (cache has been cleared)');
    is($c->data, 'two', '... the data is still the same');
    ok($c->has_data, '... we have data');

    $c->clear;

    is($c->data, 'three', '... the data we got is correct (cache has been cleared)');
    ok($c->has_data, '... we have data');

    $c->clear;

    ok(!$c->has_data, '... we no longer have data');
    is($c->data, undef, '... the cache is empty now');
}


