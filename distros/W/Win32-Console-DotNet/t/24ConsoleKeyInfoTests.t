# https://github.com/dotnet/runtime/blob/116f5fd624c6981a66c2a03c5ea5f8fa037ef57f/src/libraries/System.Console/tests/ConsoleKeyInfoTests.cs
# Licensed to the .NET Foundation under one or more agreements.
# The .NET Foundation licenses this file to you under the MIT license.
use 5.014;
use warnings;

use Test::More tests => 30;
use Test::Exception;

use constant FALSE  => !!'';
use constant TRUE   => !!1;

BEGIN {
  use_ok 'Win32::Console::DotNet';
  use_ok 'System';
  use_ok 'ConsoleKey';
  use_ok 'ConsoleKeyInfo';
  use_ok 'ConsoleModifiers';
}

subtest 'Ctor_DefaultCtor_PropertiesReturnDefaults' => sub {
  plan tests => 3;
  my $cki = ConsoleKeyInfo->new();
  is $cki->Key, ConsoleKey->None, 'Equal';
  is $cki->KeyChar, chr(0), 'Equal';
  is $cki->Modifiers, ConsoleModifiers->None, 'Equal';
};

subtest 'Ctor_ValueCtor_ReturnsNoneForDefault' => sub {
  plan tests => 3;
  my $cki = ConsoleKeyInfo->new(';', 0, FALSE, FALSE, FALSE);

  is $cki->Key, ConsoleKey->None, 'Equal';
  is $cki->KeyChar, ';', 'Equal';
  is $cki->Modifiers, ConsoleModifiers->None, 'Equal';
};

AllCombinationsOfThreeBools: {
  for my $shift ( TRUE, FALSE ) {
  for my $alt   ( TRUE, FALSE ) {
  for my $ctrl  ( TRUE, FALSE ) {

  subtest 'Ctor_ValueCtor_ValuesPassedToProperties' => sub {
    plan tests => 5;

    my $cki = ConsoleKeyInfo->new('a', ConsoleKey->A, $shift, $alt, $ctrl);

    is $cki->Key, ConsoleKey->A, 'Equal';
    is $cki->KeyChar, 'a', 'Equal';

    is(
      ($cki->Modifiers & ConsoleModifiers->Shift) == ConsoleModifiers->Shift, 
      $shift, 'Equal'
    );
    is(
      ($cki->Modifiers & ConsoleModifiers->Alt) == ConsoleModifiers->Alt, 
      $alt, 'Equal'
    );
    is(
      ($cki->Modifiers & ConsoleModifiers->Control) == ConsoleModifiers->Control
      , $ctrl, 'Equal'
    );
  };

  }}}
}

my $SampleConsoleKeyInfos = [
  ConsoleKeyInfo->new(),
  ConsoleKeyInfo->new('a', ConsoleKey->A, TRUE, FALSE, TRUE),
  ConsoleKeyInfo->new('b', ConsoleKey->B, FALSE, TRUE, TRUE),
  ConsoleKeyInfo->new('c', ConsoleKey->C, TRUE, TRUE, FALSE),
];

foreach my $cki ( @$SampleConsoleKeyInfos ) {
  subtest 'Equals_SameData' => sub {
    plan tests => 5;

    my $other = $cki;

    ok $cki->Equals($other), 'True';
    ok $cki->Equals($other), 'True';
    ok !!($cki eq $other), 'True';
    ok !($cki ne $other), 'False';

    SKIP: { 
      skip 'GetHashCode() not implemented', 1, unless $cki->can('GetHashCode');
      cmp_ok $cki->GetHashCode(), '==', $other->GetHashCode(), 'Equal';
    };
  };
}

my $NotEqualConsoleKeyInfos = [
  ConsoleKeyInfo->new('a', ConsoleKey->A, TRUE, TRUE, TRUE), 
    ConsoleKeyInfo->new('b', ConsoleKey->A, TRUE, TRUE, TRUE), 
  ConsoleKeyInfo->new('a', ConsoleKey->A, TRUE, TRUE, TRUE), 
    ConsoleKeyInfo->new('a', ConsoleKey->B, TRUE, TRUE, TRUE), 
  ConsoleKeyInfo->new('a', ConsoleKey->A, TRUE, TRUE, TRUE), 
    ConsoleKeyInfo->new('a', ConsoleKey->A, FALSE, TRUE, TRUE), 
  ConsoleKeyInfo->new('a', ConsoleKey->A, TRUE, TRUE, TRUE), 
    ConsoleKeyInfo->new('a', ConsoleKey->A, TRUE, FALSE, TRUE), 
  ConsoleKeyInfo->new('a', ConsoleKey->A, TRUE, TRUE, TRUE), 
    ConsoleKeyInfo->new('a', ConsoleKey->A, TRUE, TRUE, FALSE), 
];

for (my $i = 0; $i <= $#$NotEqualConsoleKeyInfos; $i += 2) {
  my ($left, $right) = @$NotEqualConsoleKeyInfos[$i..$i+1];
  subtest 'NotEquals_DifferentData' => sub {
    plan tests => 4;

    ok !$left->Equals($right), 'False';
    ok !$left->Equals($right), 'False';
    ok !($left eq $right), 'False';
    ok !!($left ne $right), 'True';
  };
}

for (my $i = 0; $i <= $#$NotEqualConsoleKeyInfos; $i += 2) {
  my ($left, $right) = @$NotEqualConsoleKeyInfos[$i..$i+1];
  subtest 'HashCodeNotEquals_DifferentData' => sub {
    plan tests => 1;

    SKIP: { 
      skip 'GetHashCode() not implemented', 1, unless $left->can('GetHashCode');
      cmp_ok $left->GetHashCode(), '!=', $right->GetHashCode(), 'NotEqual';
    };
  };
}

subtest 'NotEquals_Object' => sub {
  plan tests => 2;
  ok !ConsoleKeyInfo->new()->Equals(undef), 'False';
  ok !ConsoleKeyInfo->new()->Equals(bless {}), 'False';
};

done_testing;
