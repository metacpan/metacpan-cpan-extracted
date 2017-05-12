use Test::More 'no_plan';
use strict;
use warnings;
use Test::ModuleVersion;

{
  my $tm = Test::ModuleVersion->new;
  $tm->modules([
    ['DBIx::Custom' => '1.01']
  ]);
  like($tm->test_script, qr/DBIx::Custom.*1.01/);
}
{
  my $tm = Test::ModuleVersion->new;
  $tm->lib(['extlib/lib/perl5']);
  $tm->modules([
    ['Object::Simple' => '3.0624'],
    ['DBIx::Custom' => '0.2107'],
    ['Validator::Custom' => '0.1426']
  ]);
  like($tm->test_script, qr/Object::Simple.*3.0624/);
  like($tm->test_script, qr/DBIx::Custom.*0.2107/);
  like($tm->test_script, qr/Validator::Custom.*0.1426/);
}

1;
