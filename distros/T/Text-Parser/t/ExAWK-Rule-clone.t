
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'Text::Parser::Rule';
    use_ok 'Text::Parser';
}

lives_ok {
    my $rule = Text::Parser::Rule->new( if => '' );
    isa_ok( $rule, 'Text::Parser::Rule' );
    my $r2 = $rule->clone();
    isa_ok( $r2, 'Text::Parser::Rule' );
    my $r3 = $r2->clone( do => 'return $2;' );
    isa_ok( $r3, 'Text::Parser::Rule' );
    my $r4 = $rule->clone( if => '$1 eq "something"' );
    isa_ok( $r4, 'Text::Parser::Rule' );
    my $r5 = $r4->clone( dont_record => 1 );
    isa_ok( $r5, 'Text::Parser::Rule' );
    my $r6 = $r5->clone( continue_to_next => 1 );
    isa_ok( $r6, 'Text::Parser::Rule' );
    my $r7 = $r3->clone( dont_record => 1 );
    isa_ok( $r7, 'Text::Parser::Rule' );
    my $r8 = $rule->clone( if => '1 eq 1;', add_precondition => '1;' );
    isa_ok( $r8, 'Text::Parser::Rule' );
}
'No exceptions in trying these lines';

done_testing;
