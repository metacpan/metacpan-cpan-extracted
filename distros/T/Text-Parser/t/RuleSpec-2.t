
use strict;
use warnings;

package ParserClass;

use Test::Exception;
use Text::Parser::Error;
use Text::Parser::RuleSpec;

extends 'Text::Parser';

lives_ok {
    applies_rule empty_rule => ( if => '$1 eq "NOTHING"', do => 'print;' );
}
'Creates a basic rule';

package Parser2;

use Test::Exception;
use Text::Parser::Error;
use Text::Parser::RuleSpec;

extends 'Text::Parser';

lives_ok {
    applies_rule empty_rule => ( if => '$1 =~ /[*]/', do => 'print;' );
}
'Creates another basic rule';

package AnotherClass;

use Test::Exception;
use Text::Parser::Error;
use Text::Parser::RuleSpec;
extends 'ParserClass', 'Parser2';

lives_ok {
    applies_rule get_names => ( if => '$1 eq "NAME:"' );
}
'Creates a rule get_names';

lives_ok {
    applies_rule get_address => ( if => '$1 eq "ADDRESS:"', do => 'print;' );
}
'Creates a second rule';

package DisablerClass;

use Test::Exception;
use Text::Parser::RuleSpec;
extends 'AnotherClass';

throws_ok {
    disables_superclass_rules;
}
'Text::Parser::Error', 'Fails to disable - no args';

throws_ok {
    disables_superclass_rules 'empty_rule';
}
'Text::Parser::Error', 'Fails to disable - no classname in arg';

throws_ok {
    disables_superclass_rules 'DisablerClass/some_rule';
}
'Text::Parser::Error', 'Fails to disable same class rules';

lives_ok {
    disables_superclass_rules qr/AnotherClass/, 'RandomClass/some_rule',
        sub { my ( $c, $r ) = split /\//, shift; $c eq 'ParserClass'; };
}
'Disables properly';

lives_ok {
    disables_superclass_rules 'Parser2/empty_rule';
}
'Disables even the last remaining one';

package main;
use Test::Exception;
use Text::Parser::RuleSpec;
use Test::More;

BEGIN {
    use_ok 'Text::Parser::RuleSpec';
    use_ok 'Text::Parser::Error';
}

lives_ok {
    my $h = Text::Parser::RuleSpec->_class_rule_order;
    is_deeply(
        $h,
        {   ParserClass  => [qw(ParserClass/empty_rule)],
            AnotherClass => [
                qw(ParserClass/empty_rule Parser2/empty_rule AnotherClass/get_names AnotherClass/get_address)
            ],
            Parser2       => ['Parser2/empty_rule'],
            DisablerClass => [],
        },
        'Has the right classes and rules'
    );
    is_deeply(
        [ Text::Parser::RuleSpec->class_rule_order('AnotherClass') ],
        [   qw(ParserClass/empty_rule Parser2/empty_rule AnotherClass/get_names AnotherClass/get_address)
        ],
        'Correct rule order for AnotherClass',
    );
    is_deeply( [ Text::Parser::RuleSpec->class_rule_order() ],
        [], 'Empty rule order for no argument' );
    isnt( Text::Parser::RuleSpec->class_has_rules(),
        1, 'No argument returns 1' );
    isnt( Text::Parser::RuleSpec->class_has_rules('Unknown'),
        1, 'Unknown class name returns 1' );
    isnt( Text::Parser::RuleSpec->class_has_rules('AnotherClass'),
        1, 'AnotherClass class_has_rules is not 1' );
    is_deeply( [ Text::Parser::RuleSpec->class_rules() ],
        [], 'Empty array of objects for no argument call of class_rules' );
    is_deeply( [ Text::Parser::RuleSpec->class_rules('Random') ],
        [],
        'Empty array of objects for random argument call of class_rules' );
    lives_ok { Text::Parser::RuleSpec->populate_class_rules(); } 'All fine 1';
    lives_ok { Text::Parser::RuleSpec->populate_class_rules('Random'); }
    'All fine 2';
    lives_ok { Text::Parser::RuleSpec->populate_class_rules('AnotherClass'); }
    'All fine 3';
}
'Ran checks on Text::Parser::RuleSpec';

done_testing;
