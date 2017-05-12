use strict;
use warnings;
use utf8;
use Test::More;

use UnazuSan;
my $reg = UnazuSan::_build_command_reg('unazu-san', 'echo');

subtest normal => sub {
    my $command = 'unazu-san: echo fuga piyo  qqq1';
    like $command, qr/$reg/;
    is_deeply [UnazuSan::_build_command_args($reg, $command)], [qw/fuga piyo qqq1/];
};

subtest empty => sub {
    my $command = 'unazu-san: echo';
    like $command, qr/$reg/;
    is_deeply [UnazuSan::_build_command_args($reg, $command)], [];
};

done_testing;
