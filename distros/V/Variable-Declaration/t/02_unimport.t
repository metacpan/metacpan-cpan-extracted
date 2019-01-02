use Test::More;
use Variable::Declaration;

eval {
    let $foo;
};
ok not $@;

no Variable::Declaration;
eval {
    let $foo;
};
ok $@ =~ /^Can't call method "let"/;

done_testing;
