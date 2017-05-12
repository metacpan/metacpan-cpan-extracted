use strict;
use warnings;
use utf8;
use Test::More;
use Text::Sprintf::Zenkaku qw(sprintf);
use Test::Trap;
use Test::Exception;

use Term::Encoding qw(term_encoding);
eval {
    my $encoding = term_encoding;
    binmode STDOUT => "encoding($encoding)";
    binmode STDERR => "encoding($encoding)";
};

subtest "complex width pattern" => sub {
    is sprintf('[%6s][%6s]', 'あ', 'いう'), '[    あ][  いう]';
    is sprintf('[%6s][%*3$s]', 'あ', 'いう', 6), '[    あ][  いう]';
    is sprintf('[%*3$s][%*3$s]', 'あ', 'いう', 6), '[    あ][  いう]';

    is sprintf('[%1$*3$s][%2$*3$s]', 'あ', 'いう', 6), '[    あ][  いう]';
    is sprintf('[%2$*1$s][%3$*s]', 6, 'あ', 'いう'), '[    あ][  いう]';

    is sprintf('[%3$*1$s][%*s]', 6, 'い', 'あ'), '[    あ][    い]';
    TODO: {
        local $TODO = 'xx';
        is sprintf('[%3$*1$s][%*s]', 6, 'いう', 'あ'), '[    あ][  いう]';
    };

    is sprintf('[%1$s]', 'あ'), '[あ]';
};

done_testing;

