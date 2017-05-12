use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More;
use Test::Kantan::Expect;
use Test::Kantan::State;
use Test::Kantan::Builder;

{
    package Test::Kantan::Reporter::Null;

    use Moo;
    extends 'Test::Kantan::Reporter::Base';

    has messages => ( is => 'rw', default => sub { [] } );

    no Moo;

    sub pass {
        my ($self, %args) = @_;
        Test::More::note($args{description});
    }
    sub fail {
        my ($self, %args) = @_;
        Test::More::note($args{description});
    }
    sub message {
        my ($self, $message) = @_;
        Test::More::note($message->as_string(reporter => $self));
    }
    sub colored { $_[2] }
}

sub expect {
    my $v = shift;
    return Test::Kantan::Expect->new(
        stuff  => $v,
        builder => Test::Kantan::Builder->new(
            reporter => Test::Kantan::Reporter::Null->new(
                color => 0,
                state => Test::Kantan::State->new(),
            )
        ),
    );
}

subtest 'to_be_defined', sub {
    ok expect(0)->to_be_defined;
    ok !expect(undef)->to_be_defined;

    is(expect(0)->not->to_be_defined, 0);
    is(expect(undef)->not->to_be_defined, 1);
};

subtest 'to_be_truthy', sub {
    is( expect(0)->to_be_truthy,     0 );
    is( expect(1)->to_be_truthy,     1 );
    is( expect(undef)->to_be_truthy, 0 );

    is( expect(0)->not->to_be_truthy,     1 );
    is( expect(1)->not->to_be_truthy,     0 );
    is( expect(undef)->not->to_be_truthy, 1 );
};

subtest 'to_be_falsy', sub {
    is( expect(0)->to_be_falsy,     1 );
    is( expect(1)->to_be_falsy,     0 );
    is( expect(undef)->to_be_falsy, 1 );

    is( expect(0)->not->to_be_falsy,     0 );
    is( expect(1)->not->to_be_falsy,     1 );
    is( expect(undef)->not->to_be_falsy, 0 );
};

subtest 'to_equal', sub {
    is( expect(0)->to_equal(0),     1 );
    is( expect(0)->to_equal(1),     0 );
};

subtest 'to_throw', sub {
    is( expect( sub { die } )->to_throw, 1 );
    is( expect( sub { } )->to_throw,     0 );
};

subtest 'to_match', sub {
    is( expect( 'a' )->to_match(qr/a/), 1 );
    is( expect( 'b' )->to_match(qr/a/), 0 );
};

subtest 'to_be_a', sub {
    {
        package A;
        our @ISA=qw(B);
    }

    {
        package B;
        sub new { bless {}, shift }
    }

    ok expect(A->new)->to_be_an('A');
    ok expect(A->new)->to_be_a('B');
    ok !expect(A->new)->to_be_a('C');
};

subtest 'to_equal_as_a_bag_of' => sub {
    is( expect( [] )->to_equal_as_a_bag_of( [] ), 1 );
    is( expect( [0, 1, 2] )->to_equal_as_a_bag_of( [0, 1, 2] ), 1 );
    is( expect( [0, 1, 2] )->to_equal_as_a_bag_of( [2, 0, 1] ), 1 );
    is( expect( [0, 1, 2, 2] )->to_equal_as_a_bag_of( [0, 1, 2] ), 0 );
    is( expect( [0, 1, 2] )->to_equal_as_a_bag_of( [1, 2, 3] ), 0 );
};

subtest 'to_equal_as_a_set_of' => sub {
    is( expect( [] )->to_equal_as_a_set_of( [] ), 1 );
    is( expect( [0, 1, 2] )->to_equal_as_a_set_of( [0, 1, 2] ), 1 );
    is( expect( [0, 1, 2] )->to_equal_as_a_set_of( [2, 0, 1] ), 1 );
    is( expect( [0, 1, 2, 2] )->to_equal_as_a_set_of( [0, 1, 2] ), 1 );
    is( expect( [0, 1, 2] )->to_equal_as_a_set_of( [1, 2, 3] ), 0 );
};

subtest 'to_be_a_sub_bag_of' => sub {
    is( expect( [] )->to_be_a_sub_bag_of( [] ), 1 );
    is( expect( [1, 0] )->to_be_a_sub_bag_of( [0, 1] ), 1 );
    is( expect( [1, 0] )->to_be_a_sub_bag_of( [0, 1, 2] ), 1 );
    is( expect( [1, 0] )->to_be_a_sub_bag_of( [0, 2] ), 0 );
    is( expect( [1, 0] )->to_be_a_sub_bag_of( [0] ), 0 );
};

subtest 'to_be_a_sub_set_of' => sub {
    is( expect( [] )->to_be_a_sub_set_of( [] ), 1 );
    is( expect( [1, 0] )->to_be_a_sub_set_of( [0, 1] ), 1 );
    is( expect( [1, 0] )->to_be_a_sub_set_of( [0, 1, 2] ), 1 );
    is( expect( [1, 0] )->to_be_a_sub_set_of( [0] ), 0 );
};

subtest 'to_be_a_super_bag_of' => sub {
    is( expect( [] )->to_be_a_super_bag_of( [] ), 1 );
    is( expect( [0, 1, 2] )->to_be_a_super_bag_of( [0, 1] ), 1 );
    is( expect( [0, 1, 2] )->to_be_a_super_bag_of( [1, 0] ), 1 );
    is( expect( [0, 1] )->to_be_a_super_bag_of( [2, 1, 0] ), 0 );
};

subtest 'to_be_a_super_set_of' => sub {
    is( expect( [] )->to_be_a_super_set_of( [] ), 1 );
    is( expect( [0, 1, 2] )->to_be_a_super_bag_of( [0, 1] ), 1 );
    is( expect( [0, 1, 2] )->to_be_a_super_bag_of( [1, 0] ), 1 );
    is( expect( [0, 1] )->to_be_a_super_bag_of( [2, 1, 0] ), 0 );
};

subtest 'to_be_a_sub_hash_of' => sub {
    is( expect( {} )->to_be_a_sub_hash_of( {} ), 1 );
    is( expect( {a => 0} )->to_be_a_sub_hash_of( {a => 0, b => 1} ), 1 );
    is( expect( {a => 0, b => 1} )->to_be_a_sub_hash_of( {a => 0} ), 0 );
};

subtest 'to_be_a_super_hash_of' => sub {
    is( expect( {} )->to_be_a_super_hash_of( {} ), 1 );
    is( expect( {a => 0, b => 1} )->to_be_a_super_hash_of( {a => 0} ), 1 );
    is( expect( {a => 0, b => 1} )->to_be_a_super_hash_of( {a => 0, c => 2} ), 0 );
};

done_testing;

