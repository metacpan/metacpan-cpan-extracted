use strict;
use warnings;

package Counter;
use self;

sub new { bless { n => 1}, shift };

sub v {
    return $self->{n}
}

sub m {
    return self->{n}
}

package main;
use Benchmark qw(:all);

my $c = new Counter;

cmpthese(500000, {
    '$self' => sub { $c->v },
    'self' => sub { $c->m },
})
