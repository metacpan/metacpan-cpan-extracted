#!perl -T
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.
# Test XML::Axk::Object::TinyDefaults

package TinyDefaults;

use AxkTest;
use parent 'Test::Class';

sub class { "XML::Axk::Object::TinyDefaults" };

sub startup :Tests(startup=>1) {
    my $test = shift;
    use_ok $test->class;
    diag( "Testing XML::Axk::Object::TinyDefaults $XML::Axk::Object::TinyDefaults::VERSION, Perl $], $^X" );
}

# No defaults ===================================================== {{{1
package NoDefaults {
    use XML::Axk::Object::TinyDefaults qw(foo bar);
}

sub no_defaults :Tests {
    my $x = NoDefaults->new();
    isa_ok($x, 'NoDefaults');
    isa_ok($x, 'XML::Axk::Object::TinyDefaults');
    ok(!$x->foo, 'No default => falsy (foo)');
    ok(!$x->bar, 'No default => falsy (bar)');
    $x->{foo} = 42;
    $x->{bar} = 'yes';
    is($x->foo, 42, 'numeric assignment');
    is($x->bar, 'yes', 'string assignment');
}

# }}}1
# Defaults and field names ======================================== {{{1
package DefaultsAndNames {
    use XML::Axk::Object::TinyDefaults { foo => 'default' }, qw(foo bar);
}

sub defaults_and_names :Tests {
    my $x = DefaultsAndNames->new();
    isa_ok($x, 'DefaultsAndNames');
    isa_ok($x, 'XML::Axk::Object::TinyDefaults');
    is($x->foo, 'default', 'default (foo)');
    ok(!$x->bar, 'no default => falsy (bar)');
    $x->{foo} = 42;
    $x->{bar} = 'yes';
    is($x->foo, 42, 'numeric assignment');
    is($x->bar, 'yes', 'string assignment');
}

# }}}1
# Defaults and field names; some names only in defaults =========== {{{1
package DefaultsWithNamesAndNames {
    use XML::Axk::Object::TinyDefaults { quux => 'default' }, qw(foo bar);
}

sub defaults_with_names_and_names :Tests {
    my $x = DefaultsWithNamesAndNames->new();
    isa_ok($x, 'DefaultsWithNamesAndNames');
    isa_ok($x, 'XML::Axk::Object::TinyDefaults');
    is($x->quux, 'default', 'default (quux)');
    ok(!$x->foo, 'no default => falsy (foo)');
    ok(!$x->bar, 'no default => falsy (bar)');
    $x->{quux} = [];
    $x->{foo} = 42;
    $x->{bar} = 'yes';
    is(ref $x->{quux}, 'ARRAY', 'arrayref assignment');
    is($x->foo, 42, 'numeric assignment');
    is($x->bar, 'yes', 'string assignment');
}

# }}}1
# Defaults only =================================================== {{{1
package DefaultsOnly {
    use XML::Axk::Object::TinyDefaults { quux => 'default', foo=>42 };
}

sub defaults_only :Tests {
    my $x = DefaultsOnly->new();
    isa_ok($x, 'DefaultsOnly');
    isa_ok($x, 'XML::Axk::Object::TinyDefaults');
    is($x->quux, 'default', 'default (quux)');
    is($x->foo, 42, 'default (foo)');
    $x->{quux} = 'yes';
    $x->{foo} = 'indeed';
    is($x->quux, 'yes', 'string assignment (quux)');
    is($x->foo, 'indeed', 'string assignment (foo)');
}

# }}}1

1;
# vi: set ts=4 sts=4 sw=4 et ai fdm=marker fdl=0: #
