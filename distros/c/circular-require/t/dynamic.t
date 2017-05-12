#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/basic';

{
    no circular::require;

    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Foo');
    is($warnings, "Circular require detected:\n  Foo.pm\n  Baz.pm\n  Foo.pm\nCircular require detected:\n  Baz.pm\n  Bar.pm\n  Baz.pm\n", "correct warnings");

    clear();
}

{
    no circular::require;
    use circular::require;

    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Foo');
    is($warnings, undef, "correct warnings");

    clear();
}

{
    no circular::require;

    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Foo');
    is($warnings, "Circular require detected:\n  Foo.pm\n  Baz.pm\n  Foo.pm\nCircular require detected:\n  Baz.pm\n  Bar.pm\n  Baz.pm\n", "correct warnings");

    clear();
    undef $warnings;

    {
        use circular::require;

        use_ok('Foo');
        is($warnings, undef, "correct warnings");

        clear();
        undef $warnings;

        {
            no circular::require;

            use_ok('Foo');
            is($warnings, "Circular require detected:\n  Foo.pm\n  Baz.pm\n  Foo.pm\nCircular require detected:\n  Baz.pm\n  Bar.pm\n  Baz.pm\n", "correct warnings");
        }

    }
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Foo');
    is($warnings, undef, "correct warnings");

    clear();
}

sub clear {
    for (qw(Foo Bar Baz)) {
        no strict 'refs';
        delete $::{$_};
        delete ${$_ . '::'}{quux};
        delete $INC{"$_.pm"};
    }
}

done_testing;
