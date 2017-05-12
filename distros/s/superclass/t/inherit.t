use strict;
use Test::More tests => 10;
use lib 't/lib';

require_ok 'superclass';

package No::Version;

use vars qw($Foo);
sub VERSION { 42 }

package Test::Version;

use superclass -norequire, 'No::Version';
::is( $No::Version::VERSION, undef, '$VERSION gets left alone' );

# Test Inverse: superclass.pm should not clobber existing $VERSION
package Has::Version;

BEGIN { $Has::Version::VERSION = '42' }

package Test::Version2;

use superclass -norequire, 'Has::Version';
::is( $Has::Version::VERSION, 42 );

package main;

my $eval1 = q{
  {
    package Eval1;
    {
      package Eval2;
      use superclass -norequire, 'Eval1';
      $Eval2::VERSION = "1.02";
    }
    $Eval1::VERSION = "1.01";
  }
};

eval $eval1;
is( $@, '' );

# String comparisons, just to be safe from floating-point errors
is( $Eval1::VERSION, '1.01' );

is( $Eval2::VERSION, '1.02' );

eval q{use superclass 'reallyReAlLyNotexists'};
like(
    $@,
    q{/^Can't locate reallyReAlLyNotexists.pm in \@INC/},
    'baseclass that does not exist'
);

eval q{use superclass 'reallyReAlLyNotexists'};
like(
    $@,
    q{/^Can't locate reallyReAlLyNotexists.pm in \@INC/},
    '  still failing on 2nd load'
);
{
    my $warning;
    local $SIG{__WARN__} = sub { $warning = shift };
    eval q{package HomoGenous; use superclass 'HomoGenous';};
    like(
        $warning,
        q{/^Class 'HomoGenous' tried to inherit from itself/},
        '  self-inheriting'
    );
}

{
    BEGIN { $Has::Version_0::VERSION = 0 }

    package Test::Version3;

    use superclass -norequire, 'Has::Version_0';
    ::is( $Has::Version_0::VERSION, 0, '$VERSION==0 preserved' );
}

