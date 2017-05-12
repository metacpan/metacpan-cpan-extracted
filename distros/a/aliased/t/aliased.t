#!/usr/bin/perl -w
use warnings;
use strict;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib', 'lib/';
    require_ok 'aliased' or die;
    ok !defined &main::echo,
      '... and exported functions should not (yet) be in our namespace';
}

ok !defined &alias, 'aliased() should not be exported by default';
eval "use aliased";
is $@, '', '... trying to use aliased without a package name should not fail';
can_ok __PACKAGE__, 'alias';

eval "use aliased 'No::Such::Module'";
ok $@,   'Trying to use aliased with a module it cannot load should fail';
like $@, qr{Can't locate No/Such/Module.pm in \@INC},
  '... and it should have an appropriate error message';

use aliased 'Really::Long::Module::Name';
my $name = Name->new;
isa_ok $name, 'Really::Long::Module::Name', '... and the object it returns';

use aliased 'Really::Long::Module::Conflicting::Name' => 'C::Name', "echo";
ok defined &main::echo, '... and import items should be handled correctly';
is_deeply [ echo( [ 1, 2 ], 3 ) ], [ [ 1, 2 ], 3 ],
  '... and exhibit the correct behavior';
ok $name = C::Name->new,
'We should be able to alias to different packages, even though that is really stupid';
isa_ok $name, 'Really::Long::Module::Conflicting::Name',
  '... and the object returned';

use aliased 'Really::Long::PackageName' => 'PackageName', qw/foo bar baz/;

ok defined &PackageName,
  'We should be able to pass an array ref as an import list';
foreach my $method (qw/foo bar baz/) {
    no strict 'refs';
    is &$method, $method, '... and it should behave as expected';
}

{
  package My::Package;
  use Test::More;

  use aliased 'Really::Long::Module::Name';
  my $name = Name->new;
  isa_ok $name, 'Really::Long::Module::Name', '... a short alias works in a package';

  use aliased 'Really::Long::Module::Name' => 'A::Name';
  $name = A::Name->new;
  isa_ok $name, 'Really::Long::Module::Name', '... a long alias works in a package';
}

done_testing;
