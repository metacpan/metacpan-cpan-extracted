#!/usr/bin/env perl

use Test::Most;
use Test::Mock::Object qw(create_mock read_only add_method);

sub get_fresh_mock {
    return create_mock(
        package => 'Apache2::RequestRec',
        methods => {
            uri        => read_only('/foo/bar'),
            status     => 200,
            print      => undef,
            headers_in => {},
            param      => sub {
                my ( $self, $param ) = @_;
                my %value_for = (
                    process_order => 1,
                    cust_id       => 1001,
                );
                return $value_for{$param};
            },
        },
        method_chains => [
            [qw/some_object is_verified 1/],
            [qw/foo bar baz quux/],
            [ qw/foo this that/, 23 ],
        ],
    );
}

subtest 'custom subs' => sub {
    my $r = get_fresh_mock();
    explain $r;
    is $r->param('cust_id'), 1001,
      'We should be able to use our own custom subroutines';
    eq_or_diff $r->{param},
      { times_called => 1, times_with_args => 1, times_without_args => 0 },
      '... and still have tracking of the number of times it was called';

    add_method( $r, 'answer', 42 );
    is $r->answer, 42,
      'We should be able to add new methods to an existing object';
    eq_or_diff $r->{answer},
      { times_called => 1, times_with_args => 0, times_without_args => 1 },
      '... and still get correct "times_called" information';
};

subtest 'read write methods' => sub {
    my $r = get_fresh_mock;

    ok !defined $r->print, 'some methods can start undefined';
    is $r->status, 200, '... while others will start with a value';

    $r->print('floof');
    $r->status(500);
    is $r->print, 'floof', 'We should be able to set their values';
    is $r->status, 500, '... regardless of whether or not they started defined';

    $r->status;    # calling it again to change its times_called count
    eq_or_diff $r->{print},
      { times_called => 3, times_with_args => 1, times_without_args => 2 },
      '... and we should be able to see how many times it was called';
    eq_or_diff $r->{status},
      { times_called => 4, times_with_args => 1, times_without_args => 3 },
      '... and we should be able to see how many times it was called';
};

subtest 'read only methods' => sub {
    my $r = get_fresh_mock;

    is $r->uri, '/foo/bar', 'our uri should be correct';
    throws_ok { $r->uri('/foo/baz') }
    qr/Apache2::RequestRec->uri is read-only/,
      'Setting a read-only value should throw an exception';
    is $r->{uri}{times_called},       2, '->uri should have been called twice';
    is $r->{uri}{times_with_args},    1, '... once with args';
    is $r->{uri}{times_without_args}, 1, '... and once without args';
};

subtest 'miscellaneous' => sub {
    my $r = get_fresh_mock;

    ok $r->isa('Apache2::RequestRec'),
      'isa() will lie and tell you it is the object you are mocking';
    isnt ref $r, 'Apache2::RequestRec',
      '... but we are safely in a new namespace';
    throws_ok { $r->unknown_method }
qr/Can't locate object method "unknown_method" via package.*Apache2_RequestRec/,
      '... and there is no awful AUTOLOAD or similar nastiness going on';

    lives_ok { require Apache2::RequestRec }
    'Attempting to load the original module should succeed';
    is $INC{'Apache2/RequestRec.pm'}, 'Mocked by Test::Mock::Object',
      '... but we can see it was mocked by Test::Mock::Object';
    eq_or_diff \%Apache2::RequestRec::, {},
      '... and we can see that the Apache2::RequestRec namespace is empty';
};

subtest 'methods chains' => sub {
    my $r = get_fresh_mock();
    ok $r->some_object->is_verified,
      'We should be able to create method chains';
    is $r->foo->bar->baz,   'quux', '... of arbitrary depth';
    is $r->foo->this->that, 23,     '... and different roots';
    is $r->foo->bar( answer => 42 )->baz, 'quux',
      '... even if arguments are passed to the methods';
    is $r->foo( answer => 42 )->bar->baz, 'quux',
      '... even if arguments are passed to the methods';
    throws_ok { $r->some_object->no_such_method }
    qr/Unknown method 'no_such_method' called in method chain/,
      '... but only the methods we define should exist';
};

subtest 'overriding isa ' => sub {
    my $mock = create_mock(
        package => ' Toy::Soldier ',
        methods => {
            name   => ' Ovid ',
            rank   => ' Private ',
            serial => ' 123 - 456 - 789 ',
            isa    => sub {
                my ( $self, $class ) = @_;
                return $class eq ' Toy::Soldier ' || $class eq ' Toy ';
            },
        }
    );
    ok $mock->isa(' Toy::Soldier '), ' Our isa() is called ';
    ok $mock->isa(' Toy '),          ' Our isa() is called ';
    ok !$mock->isa(' Test::Mock::Object '), ' Our isa() is called ';
};

subtest 'no leaks' => sub {
  SKIP: {
        eval { require Test::LeakTrace; 1 }
          or do { skip "Test::LeakTrace not available", 1 };
        Test::LeakTrace::no_leaks_ok(
            sub {
                my $mock = get_fresh_mock();
                undef $mock;
            },
            'no leaks'
        );
    }
};

done_testing;
