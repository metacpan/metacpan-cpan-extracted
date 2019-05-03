use strict;
use warnings;

use Test::More 0.88;
use B::Deparse;
use signatures;

# This doesn't need to do anything, just return nothing.
sub MODIFY_CODE_ATTRIBUTES { }

{
    no strict 'vars';   # do not croak because we don't understand this signature
    no warnings 'once';
    sub test ($self, $c) :Local Does(Dummy) {
        $c->{ok} = 1;
    }
}

my $c = {};
__PACKAGE__->test($c);
ok($c->{ok}, 'managed to parse the signature and run the code')
    or diag(B::Deparse->new->coderef2text(\&test));

done_testing;
