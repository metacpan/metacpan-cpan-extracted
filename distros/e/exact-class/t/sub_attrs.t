use Test::Most;

my $counter = 0;

package Thing {
    use exact 'class';

    has data => sub {
        return ++$counter;
    };
}

my $thing = Thing->new;

is( $thing->data, $thing->data, 'sub-generated attr value generated on first access' );
isnt( Thing->new->data, Thing->new->data, 'sub-generated attr value not same across objs' );

done_testing();
