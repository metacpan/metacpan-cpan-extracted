#!perl -w

use strict;
use Test::More;

use File::Spec::Functions qw( catfile );
use Test::Vars;

my $file = catfile( qw( t lib Warned1.pm ) );
my @unused;
my $handler = sub {
    push @unused, [@_];
};

{
    @unused = ();
    test_vars($file, $handler);

    my @tb_output = (
        [
            'note',
            'checking Warned1 in Warned1.pm ...'
        ],
        [
            'diag',
            '$an_unused_var is used once in &Warned1::foo at t/lib/Warned1.pm line 6'
        ]
    );

    is_deeply(\@unused, [["t/lib/Warned1.pm", 256, \@tb_output]], 'test_vars called handler with expected results');
}

{
    @unused = ();
    test_vars('t/lib/Warned1.pm', $handler, ignore_vars => { '$an_unused_var' => 1 });

    my @tb_output = (
        [
            'note',
            'checking Warned1 in Warned1.pm ...'
        ],
    );
    is_deeply(\@unused, [['t/lib/Warned1.pm', 0, \@tb_output]], 'test_vars called handler with expected results - ignore_vars');
}

{
    @unused = ();
    test_vars('t/lib/Warned1.pm', $handler, ignore_if => sub{ /unused/ });

    my @tb_output = (
        [
            'note',
            'checking Warned1 in Warned1.pm ...'
        ],
    );
    is_deeply(\@unused, [['t/lib/Warned1.pm', 0, \@tb_output]], 'test_vars called handler with expected results - ignore_if');
}

done_testing;

