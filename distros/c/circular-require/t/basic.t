#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/basic';
use Test::More;

no circular::require;

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Foo');
    is($warnings, "Circular require detected:\n  Foo.pm\n  Baz.pm\n  Foo.pm\nCircular require detected:\n  Baz.pm\n  Bar.pm\n  Baz.pm\n", "correct warnings");

    undef $warnings;
    use_ok('Foo');
    is($warnings, undef, "using the same file twice doesn't repeat warnings");

    clear();
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Bar');
    is($warnings, "Circular require detected:\n  Baz.pm\n  Foo.pm\n  Baz.pm\nCircular require detected:\n  Bar.pm\n  Baz.pm\n  Bar.pm\n", "correct warnings");
    clear();
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Baz');
    is($warnings, "Circular require detected:\n  Baz.pm\n  Foo.pm\n  Baz.pm\nCircular require detected:\n  Baz.pm\n  Bar.pm\n  Baz.pm\n", "correct warnings");
    clear();
}

use circular::require;

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Foo');
    is($warnings, undef, "correct warnings");
    clear();
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Bar');
    is($warnings, undef, "correct warnings");
    clear();
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok('Baz');
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
