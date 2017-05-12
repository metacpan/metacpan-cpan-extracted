#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 13;

#use FindBin qw($Bin);
#use lib "$Bin/lib";

BEGIN {
    use_ok ( 'Text::ECSV' ) or exit;
}

exit main();

sub main {
    basic();
    combine();
    dup_keys_strategy();
    
    return 0;
}

sub basic {
    my $ecsv = Text::ECSV->new();
    isa_ok($ecsv, 'Text::CSV_XS');
    
    ok($ecsv->parse('a=1,b=2,c=3'), 'parse line');

    is_deeply(
        $ecsv->fields_hash,
        {
            'b' => 2,
            'c' => 3,
            'a' => 4,
            'a' => 1,
        },
        'line should be decoded to hash'
    );
    
    is_deeply(
        [
            $ecsv->field_named('c'),
            $ecsv->field_named('b'),
            $ecsv->field_named('a'),
        ],
        [ 3, 2, 1],
        'check value of fields using field_named()',
    );

    ok($ecsv->parse('whatever= 1 == 0.5+0.5,"F=ma2",E=E=mc2=E'), 'parse another line');

    is_deeply(
        [
            $ecsv->field_named('whatever'),
            $ecsv->field_named('F'),
            $ecsv->field_named('E'),
            $ecsv->field_named('a'),
        ],
        [ ' 1 == 0.5+0.5', 'ma2', 'E=mc2=E', undef ],
        'check value of fields having = using field_named()',
    );
}

sub combine {
    my $ecsv = Text::ECSV->new();

    ok(    
        $ecsv->combine(
            'b' => 2,
            'a' => 1,
            'c' => 3,
        ),
        'combine_hash status'
    );
    is(
        $ecsv->string,
        'b=2,a=1,c=3',
        'create ECSV line with combine_hash()',
    );
}

sub dup_keys_strategy {
    my $ecsv = Text::ECSV->new();
    $ecsv->dup_keys_strategy(sub {
        my $name      = shift;
        my $old_value = shift;
        my $new_value = shift;
        
        return $old_value.';'.$new_value;
    });
    
    ok($ecsv->parse('a=1,b=2,a=3'), 'parse line with dup keys');
    is_deeply(
        $ecsv->fields_hash,
        {
            'b' => 2,
            'a' => '1;3',
        },
        'values with the same key should be joined'
    );
    
    $ecsv->dup_keys_strategy(sub {
        my $name      = shift;
        my $old_value = shift;
        my $new_value = shift;
        
        $old_value = [ $old_value ]
            if (not ref $old_value eq 'ARRAY');
        
        push @$old_value, $new_value;

        return $old_value;
    });
    
    ok($ecsv->parse('a=1,b=2,a=3,b=4,c=5'), 'parse line with dup keys');
    is_deeply(
        $ecsv->fields_hash,
        {
            'b' => [ 2, 4 ],
            'a' => [ 1, 3 ],
            'c' => 5,
        },
        'values with the same key should be now joined to array'
    );    
}
