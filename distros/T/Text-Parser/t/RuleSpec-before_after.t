use strict;
use warnings;

package OneParser;
use Text::Parser::RuleSpec;
extends 'Text::Parser';
use Test::Exception;

lives_ok {
    applies_rule rule1 => ( if => 'uc($1) eq "HELLO"', );
}
'Makes some rule';

lives_ok {
    applies_rule rule2 => ( if => 'uc($1) eq "HELLO"', );
}
'Makes another rule';

package AnotherParser;
use Text::Parser::RuleSpec;
extends 'Text::Parser';
use Test::Exception;

lives_ok {
    applies_rule my_rule => (
        if => '#something',
        do => '#something else',
    );
}
'Empty rule really';

package MyParser;
use Text::Parser::RuleSpec;
extends 'OneParser';
use Test::Exception;

use AnotherParser;

throws_ok {
    applies_rule random_rule => ( before => 'OneParser/rule1', );
}
'Text::Parser::Error';

throws_ok {
    applies_rule random_rule => (
        if     => 'uc($1) eq "HELLO"',
        before => 'NonExistent::Class/rule',
    );
}
'Text::Parser::Error';

throws_ok {
    applies_rule random_rule => (
        if     => '# something else',
        before => 'something',
        after  => 'something_else',
    );
}
'Text::Parser::Error';

throws_ok {
    applies_rule random_rule => (
        if     => '# something else',
        before => 'something',
    );
}
'Text::Parser::Error';

throws_ok {
    applies_rule random_rule => (
        if    => '# something else',
        after => 'AnotherParser/my_rule',
    );
}
'Text::Parser::Error';

lives_ok {
    applies_rule simple_rule => ( do => '# nothing', );
}
'Just to check next test';

throws_ok {
    applies_rule random_rule => (
        if    => '# something else',
        after => 'MyParser/simple_rule',
    );
}
'Text::Parser::Error';

lives_ok {
    applies_rule random_rule => (
        if     => '# something',
        before => 'OneParser/rule1',
    );
}
'Finally works';

lives_ok {
    applies_rule another_random_rule => (
        if    => '# something more',
        after => 'OneParser/rule1',
    );
}
'Test after clause also';

package main;
use Test::More;

is_deeply(
    [ Text::Parser::RuleSpec->class_rule_order('MyParser') ],
    [   'MyParser/random_rule',         'OneParser/rule1',
        'MyParser/another_random_rule', 'OneParser/rule2',
        'MyParser/simple_rule',
    ],
    'set rules in correct order'
);

is_deeply(
    [ Text::Parser::RuleSpec->class_rule_order('OneParser') ],
    [qw(OneParser/rule1 OneParser/rule2)],
    'leave rules of base class in same order'
);

done_testing;
