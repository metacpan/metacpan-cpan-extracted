use Test::More 'no_plan';
use strict;
use warnings;
use Test::ModuleVersion;
use FindBin;
use lib "$FindBin::Bin/extlib/lib/perl5";

{
  my $tm = Test::ModuleVersion->new;
  $tm->lib('../extlib/lib/perl5');
  my $modules = $tm->detect(ignore => [qw/Perl Test::ModuleVersion Object::Simple TimeDate Mail LWP/]);
  $tm->modules($modules);
  my $file = "$FindBin::Bin/output/module_auto.t.output";
  open my $fh, '>', $file
    or die qr/Can't open file "$file": $!/;
  
  my $script = $tm->test_script;
  unlike($script, qr/\Qrequire_ok('Perl/);
  unlike($script, qr/\Qrequire_ok('Object::Simple/);
  unlike($script, qr/\Qrequire_ok('Test::ModuleVersion/);

  my $output;
  $| = 1;
  print $fh $script;
  $output = `perl $file`;
  like($output, qr/ok \d/);
  unlike($output, qr/not ok/);
}
