
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Text::Parser');
}

my $parser = Text::Parser->new();
isa_ok( $parser, 'Text::Parser' );
lives_ok {
    $parser->prestash( err_lines => [] );
    $parser->prestash( del_1     => 1 );
    $parser->prestash( del_2     => 2 );
}
'Pre-stashing goes well';

lives_ok {
    $parser->BEGIN_rule( do => '~count=0; ~del_me=1;' );
    $parser->add_rule(
        if               => '$1 eq "NAME:"',
        do               => '~count++;',
        dont_record      => 1,
        continue_to_next => 1,
    );
    $parser->add_rule(
        if => '$1 eq "NAME:" and $this->NF==1',
        do => 'push @{~err_lines}, $this->lines_parsed; delete ~del_me;'
    );
}
'Set up of rules goes well';

lives_ok {
    $parser->read('t/names.txt');
}
'No errors in reading file - pass 1';
is( $parser->has_stashed('count'), 1, 'count is a stashed variable' );
is( $parser->stashed('count'),     5, '5 times' );
is_deeply(
    $parser->stashed('err_lines'),
    [ 6, 7 ],
    '1st matches the err_lines'
);
isnt( $parser->has_stashed('del_me'), 1, 'del_me no longer exists' );

$parser->forget;
isnt( $parser->has_stashed('count'), 1, 'No longer has count' );
is( $parser->has_stashed('del_1'), 1, 'Still has del_1' );
is( $parser->has_stashed('del_2'), 1, 'Still has del_2' );
$parser->forget('del_2');
is( $parser->has_stashed('del_1'), 1, 'Still has del_1' );
isnt( $parser->has_stashed('del_2'), 1, 'del_2 now forgotten' );
lives_ok {
    $parser->forget('non_existent');
}
'Does not die when you try to forget a non-existent variable';

lives_ok {
    $parser->read('t/names.txt');
}
'No errors in reading file - pass 2';
is( $parser->stashed('count'), 5, '5 times' );
is_deeply(
    $parser->stashed('err_lines'),
    [ 6, 7, 6, 7 ],
    '2nd matches the err_lines'
);
isnt( $parser->has_empty_stash, 1, 'Not an empty stash' );
$parser->forget('count');
isnt( $parser->has_stashed('count'), 1, 'count removed now' );
isnt( $parser->has_stashed('del_2'), 1, 'del_2 not present' );
is( $parser->has_stashed('del_1'), 1, 'del_1 still present' );

done_testing;

