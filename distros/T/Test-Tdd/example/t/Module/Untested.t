use strict;
use warnings;

use Test::Spec;
use Test::Tdd::Generator;
use Module::Untested;
use File::Basename qw/dirname/;

describe 'Module::Untested' => sub {
    it 'returns params plus foo' => sub {
        my $input = Test::Tdd::Generator::load_input(dirname(__FILE__) . "/input/Untested_returns_params_plus_foo.dump");
        Test::Tdd::Generator::expand_globals($input->{globals});

        my $result = Module::Untested::untested_subroutine(@{$input->{args}});

        is($result, "fixme");
    };

    it 'returns the first param' => sub {
        my $input = Test::Tdd::Generator::load_input(dirname(__FILE__) . "/input/Untested_returns_the_first_param.dump");
        my $result = Module::Untested::another_untested_subroutine(@{$input->{args}});

        is($result, "fixme");
    };
};

runtests;
