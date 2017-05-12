package App::Foo;

use Getopt::Long;

sub run {
    Getopt::Long::GetOptions('foo' => \my $foo);
    $foo;
}

1;

package main;

use Test::More;

subtest 'unknown-option' => sub {
    my $stderr;
    {
        local *STDERR;
        open STDERR, '>', \$stderr;
        local @ARGV = qw/--unknown-option/;
        App::Foo::run();
    }
    like($stderr, qr/Unknown option:/);
};

subtest 'ignore case' => sub {
    local @ARGV = qw/--FOO/;
    my $foo = App::Foo::run();
    is($foo, 1);
};

done_testing;

