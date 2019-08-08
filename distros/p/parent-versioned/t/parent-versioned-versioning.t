#!/usr/bin/perl -w

use strict;
use Test::More; # tests => 9

use_ok('parent::versioned');

package No::Version;

our $Foo;
sub dummy {1}

package Has::Version;

BEGIN { $Has::Version::VERSION = '42' };

package Has::Version2;

BEGIN { $Has::Version2::VERSION = '0.05' };


package Test::Version;

{
    local $@;
    eval "use parent::versioned -norequire, ['Has::Version' => 42];";
    ::ok !$@, 'No exception for in-range version number.' or ::diag $@;
    ::isa_ok 'Test::Version', 'Has::Version';
}

package Test::Version2;

{
    local $@;
    eval "use parent::versioned -norequire, ['Has::Version' => 84];";
    ::like $@, qr/^Has::Version version 84 required--this is only version 42/, 'Correct exception for out of range version.';
    ::ok !Test::Version2->isa('Has::Version'), 'We did not inherit, because version was out of range.';
}

package Test::Version3;

{
    local $@;
    eval "use parent::versioned -norequire, ['No::Version' => 42];";
    ::like $@, qr/^No::Version does not define \$No::Version::VERSION--version check failed/,
        'Correct exception if VERSION has not been defined.';
    ::ok !Test::Version3->isa('No::Version'), 'We did not inherit, because we required a version but no version was defined.';
}

package Test::Version4;

{
    local $@;
    eval "use parent::versioned -norequire, 'No::Version', ['Has::Version' => 42];";
    ::ok !$@, 'No exception for in-range version number combined with non-versioned inheritance.';
    ::ok(Test::Version4->isa('No::Version'), 'We inherited from non-versioned.');
    ::ok(Test::Version4->isa('Has::Version'), 'We inherited from versioned.');
}

package Test::Version5;

{
    local $@;
    eval "use parent::versioned -norequire, 'No::Version', ['Has::Version' => 84];";
    ::like $@, qr/^Has::Version version 84 required--this is only version 42/, 'Combining non-versioned with versioned, out of range, correct exception.';
    ::ok(!Test::Version5->isa('Has::Version'), 'We did not inherit from out of range versioned module.');
    ::ok(!Test::Version5->isa('No::Version'), 'We did not inherit from any module.');
}

package Test::Version6;

{
    local $@;
    eval "use parent::versioned -norequire, ['Has::Version' => 42], ['Has::Version2' => 0.05];";
    ::ok !$@, 'No exception for dual versioned inheritance in-range.' or ::diag $@;
}

package Test::Version7;

{
    local $@;
    eval "use parent::versioned -norequire, ['Has::Version' => 42], ['Has::Version2' => 0.10];";
    ::like $@, qr/^Has::Version2 version 0\.1 required--this is only version 0\.05/,
        'Found out of range module in dual versioned import.';
    ::ok(!Test::Version7->isa('Has::Version'), 'Importing of in-range module blocked if an out-of-range occurred.');
    ::ok(!Test::Version7->isa('Has::Version2'), 'Importing of out of range module blocked.');
}

package Test::Version8;

{
    use FindBin qw($Bin);
    use lib "$Bin/lib";
    local $@;
    eval "use parent::versioned ['Dummy' => 5.562];";
    ::ok !$@, 'No exception while loading in-range module from filesystem.';
    ::ok(Test::Version8->isa('Dummy'), 'Inherited from filesystem-based module.');
}

package Test::Version9;

{
    use FindBin qw($Bin);
    use lib "$Bin/lib";
    local $@;
    eval "use parent::versioned ['Dummy' => 6];";
    ::like $@, qr/^Dummy version 6 required--this is only version 5\.562/,
        'Correct error message for out of range filesystem-based module.';
    ::ok(!Test::Version9->isa('Dummy'), 'Inheritance blocked for filesystem out of range module.');
}

::done_testing();
