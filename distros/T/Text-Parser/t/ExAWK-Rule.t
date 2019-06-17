
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Text::Parser::Errors;

BEGIN {
    use_ok 'Text::Parser::Rule';
    use_ok 'Text::Parser';
}

throws_ok {
    my $rule = Text::Parser::Rule->new();
}
ExAWK(), 'Throws an error for no arguments';

lives_ok {
    my $rule = Text::Parser::Rule->new( if => '' );
    is( $rule->min_nf, 0, 'Min NF is 0' );
    my $parser = Text::Parser->new();
    lives_ok {
        is $rule->test(''), 0, 'Test nothing';
        is $rule->test($parser), 0, 'Test works';
        $parser->auto_split(1);
        is $rule->test($parser), 0,
            'Test fails because there is no this_line';
    }
    'auto_split not enabled and still lives';
    $rule->add_precondition('${-1} eq "ELSE"');
    is( $rule->min_nf, 1,            'At least one field needed' );
    is( $rule->action, 'return $0;', 'Default action' );
    is( $rule->min_nf, 1,            'Stays at 1' );
    $rule->add_precondition('$4 eq "SOMETHING"');
    throws_ok {
        $rule->add_precondition('${-1 eq "ELSE"');
    }
    ExAWK(), 'Throws for bad syntax';
    is( $rule->min_nf, 4, 'Min NF changes to 4' );
    $rule->action('return $5');
    is( $rule->min_nf, 5, 'Min NF changes to 5' );
    $rule->action('return $3');
    is( $rule->min_nf, 4, 'Changes back to 4' );
    is( $rule->test,   0, 'Always returns 0 if no object passed' );
    $parser = Text::Parser->new();
    lives_ok {
        is $rule->test($parser), 0, 'NF cant be done';
        $parser->auto_split(1);
        is $rule->test($parser), 0, 'NF can be done, but condition fails';
    }
    'auto_split not enabled and still lives';
    $parser->auto_split(1);
    is( $rule->test($parser), 0, 'Test fails' );
    throws_ok {
        $rule->continue_to_next(1);
    }
    ExAWK(), 'Cannot continue to next if recording output';
    $rule->dont_record(1);
}
'Empty rule starting with empty condition';

lives_ok {
    my $rule   = Text::Parser::Rule->new( if => 'undef' );
    my $parser = Text::Parser->new( auto_split => 1 );
    $parser->_set_this_line('something');
    ok( not( $rule->test($parser) ), 'Will return false' );
    $rule->add_precondition('undef');
    ok( not( $rule->test($parser) ), 'Will evaluate to false' );
}
'Does not die';

lives_ok {
    my $rule = Text::Parser::Rule->new( do => '' );
    is( $rule->min_nf,    0,   'Min NF is 0' );
    is( $rule->condition, '1', 'Default action' );
    $rule->add_precondition('$4 eq "SOMETHING"');
    is( $rule->min_nf, 4, 'Min NF changes to 4' );
    $rule->action('return $5');
    is( $rule->min_nf, 5, 'Min NF changes to 5' );
    $rule->action('return $3');
    is( $rule->min_nf, 4, 'Changes back to 4' );
    is( $rule->test,   0, 'Always returns 0 if no object passed' );
    $rule->dont_record(1);
    lives_ok {
        $rule->continue_to_next(1);
    }
    'Can continue to next if not recording';
}
'Another empty rule with empty action';

lives_ok {
    my $rule = Text::Parser::Rule->new(
        if => '$1 eq "NAME:"',
        do => 'my (@fld) = $this->field_range(1, -1); return "@fld";',
    );

    my $parser  = Text::Parser->new( auto_split => 1, );
    my $parser2 = Text::Parser->new();

    my @records = ();
    throws_ok {
        $rule->run;
    }
    ExAWK();
    is $rule->test($parser), 0, 'Wont pass';
    $rule->run($parser);
    is_deeply( [ $parser->get_records ], [], 'Store undef' );
    $parser->pop_record();
    $rule->dont_record(1);
    $rule->run($parser2);
    is_deeply( [ $parser2->get_records ], [], 'No records' );
    $rule->run($parser);
    is_deeply( [ $parser->get_records ], [], 'No records this time' );
    my $rule2 = Text::Parser::Rule->new( do => '' );
    $rule2->run($parser);
    is_deeply( [ $parser->get_records ], [], 'Nothing saved' );
}
'From the SYNOPSIS';

done_testing;

