use Test2::Roo;

use MooX::Types::MooseLike::Base qw/ArrayRef/;
use Path::Tiny;

has corpus => (
    is       => 'ro',
    isa      => sub { -f shift },
    required => 1,
);

has lines => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_lines {
    my ($self) = @_;
    return [ map { lc } path( $self->corpus )->lines ];
}

test 'sorted' => sub {
    my $self = shift;
    is_deeply( $self->lines, [ sort @{$self->lines} ], "alphabetized");
};

test 'a to z' => sub {
    my $self = shift;
    my %letters = map { substr($_,0,1) => 1 } @{ $self->lines };
    is_deeply( [sort keys %letters], ["a" .. "z"], "all letters found" );
};


run_me( { corpus => "/usr/share/dict/words" } );
# ... test other corpuses ...

done_testing;
