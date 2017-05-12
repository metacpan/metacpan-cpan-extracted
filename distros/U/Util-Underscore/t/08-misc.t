#!perl
use strict;
use warnings;

use Test::More tests => 6;

use Util::Underscore;

subtest 'identity tests' => sub {
    plan tests => 5;

    ok \&_::is_open == \&Scalar::Util::openhandle, "_::is_open";

    is \&_::pp, \&Data::Dump::pp, "_::pp";
    is \&_::dd, \&Data::Dump::dd, "_::dd";
    
    is \&_::process_run,   \&IPC::Run::run,   "_::process_run";
    is \&_::process_start, \&IPC::Run::start, "_::process_start";
};

sub foo { die "unimplemented" }
my $foo = sub { die "unimplemented" };

subtest '_::prototype' => sub {
    plan tests => 6;

    ok + (not defined _::prototype \&foo), 'sub prototype empty';
    ok + (not defined _::prototype $foo), 'coderef prototype empty';

    _::prototype \&foo, '$;\@@';
    _::prototype $foo, '$;\@@';

    is + (_::prototype \&foo), '$;\@@', 'sub prototype not empty';
    is + (_::prototype $foo), '$;\@@', 'coderef prototype not empty';

    _::prototype \&foo, undef;
    _::prototype $foo, undef;

    ok + (not defined _::prototype \&foo), 'sub prototype empty again';
    ok + (not defined _::prototype $foo), 'coderef prototype empty again';
};

subtest '_::Dir' => sub {
    plan tests => 1;

    my $dir = _::Dir "foo/bar", "baz";
    isa_ok $dir, 'Path::Class::Dir';
};

subtest '_::File' => sub {
    plan tests => 1;

    my $file = _::File "foo/bar", "baz.txt";
    isa_ok $file, 'Path::Class::File';
};

subtest '_::caller' => sub {
    plan tests => 3;

    my $get_instance = sub { _::caller };
    isa_ok $get_instance->(), 'Util::Underscore::CallStackFrame';
    is $get_instance->()->line, __LINE__, "correct data";
    my $get_instance2 = sub {
        (sub { _::caller shift })->(@_);
    };
    is $get_instance2->(1)->line, __LINE__, "depth handled correctly";
};

subtest '_::callstack' => sub {
    plan tests => 2;

    subtest 'impicit argument' => sub {
        my ($have, $expected) = test_callstack_implicit();
        plan tests => 1 + @$expected;

        is 0 + @$have, 0 + @$expected, 'correct callstack depth';
        for my $i (0 .. $#$expected) {
            is $have->[$i]->subroutine, $expected->[$i]->[3],
                "correct sub name frame $i";
        }
    };

    subtest 'explicit argument' => sub {
        my ($have, $expected) = test_callstack_explicit();
        plan tests => 1 + 2 * @$expected;

        is 0 + @$have, 0 + @$expected, 'correct callstack depth';
        for my $i (0 .. $#$expected) {
            is $have->[$i]->subroutine, $expected->[$i]->[3],
                "correct sub name frame $i";
            is $have->[$i]->line, $expected->[$i]->[2],
                "correct line no frame $i";
        }
    };
};

sub test_callstack_implicit {
    my $frames = sub {
        return sub {
            my @callers;
            my $i = 0;
            push @callers, [ caller $i++ ] while caller $i;
            return [_::callstack], \@callers;
        };
    };
    return $frames->()->();
}

sub test_callstack_explicit {
    my $frames = sub {
        return sub {
            my @callers;
            my $i = 1;
            push @callers, [ caller $i++ ] while caller $i;
            return [ _::callstack 1 ], \@callers;
        };
    };
    return $frames->()->();
}
