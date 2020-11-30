use strict;
use warnings;

package Base1;
use Text::Parser::RuleSpec;
extends 'Text::Parser';
use Test::Exception;

lives_ok {
    applies_rule rule1 => ( if => '# is_rule1?', );

    applies_rule rule2 => ( if => '# is_rule2?', );
}
'Base1 rules loaded';

package Base2;
use Text::Parser::RuleSpec;
extends 'Text::Parser';
use Test::Exception;

lives_ok {
    applies_rule rule1 => ( if => '# is_rule1', );

    applies_rule rule2 => ( if => '# is_rule2', );
}
'Base2 rules loaded';

package Blend1;
use Text::Parser::RuleSpec;
extends 'Base2';
use Test::Exception;

throws_ok {
    applies_cloned_rule 'UnknownClass/nonexistent_rule' =>
        ( if => '# something' );
}
'Text::Parser::Error',
    'Produces an error if trying to clone a non-existent rule';

throws_ok {
    applies_cloned_rule 'if' => '# something';
}
'Text::Parser::Error',
    'Produces an error if applies_cloned_rule is called without orig rule name';

throws_ok {
    applies_cloned_rule { something => 1 };
}
'Text::Parser::Error', 'Bad first arg to applies_cloned_rule';

throws_ok {
    applies_cloned_rule;
}
'Text::Parser::Error', 'Bad call for applies_cloned_rule';

lives_ok {
    applies_cloned_rule 'Base1/rule1' => ( if => '# is_cloned_rule1', );
}
'Cloned Base1/rule1';

lives_ok {
    applies_cloned_rule 'rule1' => ( do => 'return $2;' );
}
'Clones Blend1/rule1 by naming it Blend1/rule1@2';

package main;

use Test::More;

use Text::Parser::RuleSpec;

done_testing;
