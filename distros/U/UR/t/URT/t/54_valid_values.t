#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 25;

class Game::Card {
    has => [
        suit    => { is => 'Text', valid_values => [qw/heart diamond club spade/], },
        color   => { is => 'Text', valid_values => [qw/red blue green/], is_mutable => 0 },
        owner   => { is => 'Text', is_optional => 1 },
        pips    => { is => 'Integer', is_optional => 0 },
    ],
};

for my $class (qw/Game::Card/) {

    my $c1 = $class->create(suit => 'spade', color => 'red', pips => 4);
    ok($c1, "created an object with a valid property");

    my @i1 = $c1->__errors__;
    is(scalar(@i1), 0, "no cases of invalididy") 
        or diag(Data::Dumper::Dumper(\@i1));

    my $c2 = $class->create(suit => 'badsuit', color => 'blue', pips => 9);
    ok($c2, "created an object with an invalid property");

    my $pips_is_integer = $class->__meta__->properties(property_name => 'pips', data_type => 'Integer');
    ok($pips_is_integer, 'pips is Integer (not Number) so Integer checks are performed');

    my $c5 = $class->create(suit => 'heart', color => 'blue', pips => '0 but true');
    ok($c5, "created an object with an invalid property");
    my @i5 = $c5->__errors__;
    is(scalar(@i5), 0, 'got no errors on c5 object');

    my $c6 = $class->create(suit => 'heart', color => 'blue', pips => '0buttrue');
    ok($c6, "created an object with an invalid property");
    my @i6 = $c6->__errors__;
    is(scalar(@i6), 1, 'got one error on c6 object');
    is($i6[0]->type, 'invalid', 'got an invalid error on c6 object');
    is(($i6[0]->properties)[0], 'pips', 'got an invalid error for `pips` on c6 object');

    my @i2 = $c2->__errors__;
    is(scalar(@i2), 1, "one expected cases of invalididy") 
        or diag(Data::Dumper::Dumper(\@i2));
    is($i2[0]->__display_name__,
       qq(INVALID: property 'suit': The value badsuit is not in the list of valid values for suit.  Valid values are: heart, diamond, club, spade),
       'Error text is corect');

    $c2->suit('heart');
    @i2 = $c2->__errors__;
    is(scalar(@i2), 0, "zero cases of invalididy after fix") 
        or diag(Data::Dumper::Dumper(\@i2));

    my $c3 = $class->create(suit => 'spade', color => 'red');
    ok($c3, 'Created color with missing required param');
    my @i3 = $c3->__errors__;
    is(scalar(@i3), 1, 'one expected cases of invalididy')
        or diag(Data::Dumper::Dumper(\@i3));
    is($i3[0]->__display_name__,
       qq(INVALID: property 'pips': No value specified for required property),
         'Error text is corect');

    my $c4 = $class->create(suit => 'badsuit', color => 'blue');
    ok($c4, 'Created object with invalid property value and missing required param');
    my @i4 = sort { $a->__display_name__ cmp $b->__display_name__ }
                  $c4->__errors__;

    is(scalar(@i4), 2, 'two expected cases of invalididy')
        or diag(Data::Dumper::Dumper(\@i4));
    is($i4[0]->__display_name__,
       qq(INVALID: property 'pips': No value specified for required property),
       'First error text is corect');
    is($i4[1]->__display_name__,
       qq(INVALID: property 'suit': The value badsuit is not in the list of valid values for suit.  Valid values are: heart, diamond, club, spade),
       'second error text is corect');

    my $context = UR::Context->current;

    $context->dump_error_messages(0);
    $context->queue_error_messages(1);
    ok(!UR::Context->commit, 'Commit fails as expected');

    my @error_messages = sort {$a cmp $b } UR::Context->current->error_messages();
    is(scalar(@error_messages), 4, 'commit generated 4 error messages');
    is($error_messages[-1],    # This one prints first, but is last
       'Invalid data for save!',
       'First error message is correct');
    my $c4_id = $c4->id;
    like($error_messages[-2],
       qr/Game::Card identified by $c4_id has problems on\s+INVALID: property 'pips': No value specified for required property\s+INVALID: property 'suit': The value badsuit is not in the list of valid values for suit.  Valid values are: heart, diamond, club, spade\s+Current state:\s+\$VAR1 = bless\( \{/s,
       'Second error message is correct');
    my $c3_id = $c3->id;
    like($error_messages[-3],
       qr/Game::Card identified by $c3_id has problems on\s+INVALID: property 'pips': No value specified for required property\s+Current state:\s+\$VAR1 = bless\( \{/s,
       'Third error message is correct');
}

