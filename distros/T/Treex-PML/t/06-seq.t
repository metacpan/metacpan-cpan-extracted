#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 32;
use Treex::PML;

{   my $s = 'Treex::PML::StandardFactory'->createSeq();
    is $s->isa('Treex::PML::Seq'), 1, 'isa';

    $s->push_element(a => 'A');
    $s->push_element_obj('Treex::PML::Seq::Element'->new(b => 'B'));

    is_deeply [$s->elements], [[a => 'A'], [b => 'B']], 'elements';
    is_deeply [$s->elements('a')], [[a => 'A']], 'elements(name)';

    {   my $r = $s->elements_list;
        is $r->isa('Treex::PML::List'), 1, 'elements_list returns a T:P:List';
        is_deeply $r, [[a => 'A'], [b => 'B']], 'elements_list';
    }

    ok ! $s->validate('c'), 'invalid pattern';
    ok $s->validate('(a|b)+'), 'valid pattern';
    $s->set_content_pattern('(a|b)+');
    ok $s->validate, 'default pattern';

    is_deeply [$s->values], [qw[ A B ]], 'values';
    is_deeply [$s->values('a')], [qw[ A ]], 'values(name)';
    is $s->values->isa('Treex::PML::List'), 1, 'values return a T:P:List';

    is_deeply [$s->names], [qw[ a b ]], 'names';
    is $s->names->isa('Treex::PML::List'), 1, 'names return a T:P:List';

    is_deeply $s->element_at(1), [b => 'B'], 'element_at_index';
    is $s->element_at(1)->isa('Treex::PML::Seq::Element'), 1, 'element isa';

    is $s->name_at(1), 'b', 'name_at';
    is $s->value_at(1), 'B', 'value_at';
}

{   my $s = 'Treex::PML::StandardFactory'->createSeq();
    $s->unshift_element(c => 'C');
    is_deeply $s->element_at(0), [c => 'C'], 'unshift_element';

    my $e = 'Treex::PML::Seq::Element'->new(d => 'D');
    $s->unshift_element_obj($e);
    is_deeply $s->element_at(0), [d => 'D'], 'unshift_element_obj';

    $s->unshift_element_obj($e);
    $s->delete_element($e);
    is_deeply $s->elements_list, [[c => 'C']], 'delete_element';

    for (1 .. 10) {
        $s->push_element(a => 'A');
        $s->push_element_obj($e);
    }
    $s->delete_value('A');
    is $s->elements, 11, 'deleted';

    is $s->index_of('D'), 1, 'index_of';
    is $s->index_of('X'), undef, 'index_of non-existent';

    $s->delete_element($e);
    is $s->elements, 1, 'deleted';

    $s->empty;
    is_deeply $s->elements_list, [], 'empty';
}

{   my $s = 'Treex::PML::StandardFactory'->createSeq();
    $s->push_element(a => 'A');
    $s->push_element(b => 'B');
    $s->push_element(c => 'C');

    $s->replace_element_at(1, 'd', 'D');
    is_deeply $s->element_at(1), [d => 'D'], 'replace_element_at';

    $s->replace_element_obj_at(0, 'Treex::PML::Seq::Element'->new(e => 'E'));
    is_deeply $s->element_at(0), [e => 'E'], 'replace_element_obj_at';

    is $s->delete_element_at(1), 1, 'delete';
    is $s->delete_element_at(2), 0, 'delete not successful';
    is_deeply $s->elements_list, [[e => 'E'], [c => 'C']], 'deleted';
}

{   my $s = 'Treex::PML::Factory'->createSeq([[a => {value => 'A'}],
                                              [b => {value => 'B'}]]);
    $s->delegate_names('N');
    is_deeply $s->value_at(0), {N => 'a', value => 'A'}, 'delegated';
}

{   my $s = 'Treex::PML::Factory'->createSeq([[a => {value => 'A'}],
                                              [b => {value => 'B'}]]);
    $s->delegate_names;
    is_deeply $s->value_at(0), {'#name' => 'a', value => 'A'},
        'delegated default';
}
