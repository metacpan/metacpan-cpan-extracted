use Test::More 'no_plan';
use strict;
use warnings;
use Test::ModuleVersion;
use FindBin;

my $lwp_exists = eval { require LWP::UserAgent; 1};
die "LWP::UserAgent must not be installed!" if $lwp_exists;

{
  # privates
  my $tm = Test::ModuleVersion->new;
  $tm->lib(['../extlib/lib/perl5']);
  $tm->privates({
    'Some::Module' => 'http://localhost/~kimoto/%M.tar.gz'
  });
  $tm->modules([
    ['Some::Module' => '0.01']
  ]);
  my $file = "$FindBin::Bin/output/module.t.output";
  open my $fh, '>', $file
    or die qr/Can't open file "$file": $!/;
  
  my $output;
  
  $| = 1;
  print $fh $tm->test_script;
  $output = `perl $file list --no-lwp`;
  like($output, qr#http://localhost/~kimoto/Some-Module-0.01.tar.gz#);
  $output = `perl $file list --lwp`;
  like($output, qr#http://localhost/~kimoto/Some-Module-0.01.tar.gz#);
  $output = `perl $file list`;
  like($output, qr#http://localhost/~kimoto/Some-Module-0.01.tar.gz#);
}

{
  # privates with distnames
  my $tm = Test::ModuleVersion->new;
  $tm->distnames({
    'Some::Module' => 'somemod'
  });
  $tm->privates({
    'Some::Module' => 'http://localhost/~kimoto/%M.tar.gz'
  });
  $tm->modules([
    ['Some::Module' => '0.01']
  ]);
  my $file = "$FindBin::Bin/output/module.t.output";
  open my $fh, '>', $file
    or die qr/Can't open file "$file": $!/;
  
  my $output;
  
  $| = 1;
  print $fh $tm->test_script;
  $output = `perl $file list --no-lwp`;
  like($output, qr#http://localhost/~kimoto/somemod-0.01.tar.gz#);
}

{
  # Basci test
  my $tm = Test::ModuleVersion->new;
  $tm->before(<<'EOS');
use 5.008007;
use ___Module1 '0.05';

=pod

You can create this script(t/module.t) by the following command.

  perl mvt.pl

=cut

EOS
  $tm->lib(['../extlib/lib/perl5']);
  $tm->modules([
    ['Object::Simple' => '3.0625'],
    ['Validator::Custom' => '0.1401'],
    ['___NotExitst' => '0.1'],
  ]);
  like($tm->test_script, qr/use 5.008007/);
  like($tm->test_script, qr#\Qperl mvt.pl#);
  
  my $file = "$FindBin::Bin/output/module.t.output";
  open my $fh, '>', $file
    or die qr/Can't open file "$file": $!/;
  print $fh $tm->test_script;
  close $fh;
  
  my $output = `perl $file`;
  like($output, qr/1\.\.6/);
  like($output, qr/ok 1/);
  like($output, qr/ok 2/);
  like($output, qr/ok 3/);
  like($output, qr/not ok 4/);
  like($output, qr/not ok 5/);
  like($output, qr/not ok 6/);

  $output = `perl $file list --no-lwp`;
  like($output, qr/http/);
  like($output, qr/Object-Simple-3.0625/);
  like($output, qr/Validator-Custom-0.1401/);
  unlike($output, qr/___NotExitst/);
  unlike($output, qr/\d\.\.\d/);

  $output = `perl $file list --no-lwp 2>&1 >/dev/null`;
  like($output, qr/___NotExitst-0.1 is unknown/);

  $output = `export TEST_MODULEVERSION_REQUEST_FAIL=1;perl $file list --no-lwp 2>&1 >/dev/null`;
  like($output, qr/Request to metaCPAN fail\(200 OK\).*___NotExitst-0.1/);
  like($output, qr/HTTP::Tiny/);
  $output = `export TEST_MODULEVERSION_REQUEST_FAIL=1;perl $file list --lwp 2>&1 >/dev/null`;
  like($output, qr/Request to metaCPAN fail\(200 OK\).*___NotExitst-0.1/);
  like($output, qr/LWP::UserAgent/);
  $output = `export TEST_MODULEVERSION_REQUEST_FAIL=1;perl $file list 2>&1 >/dev/null`;
  like($output, qr/Request to metaCPAN fail\(200 OK\).*___NotExitst-0.1/);
  like($output, qr/LWP::UserAgent/);
  
  $output = `perl $file list --no-lwp --fail`;
  like($output, qr/http/);
  unlike($output, qr/Object-Simple/);
  like($output, qr/Validator-Custom-0.1401/);
  unlike($output, qr/___NotExitst/);
  
  # HTTP::Tiny use if LWP is not exists
  open $fh, '>', $file
    or die qr/Can't open file "$file": $!/;
  $tm->before('');
  $tm->lib([]);
  print $fh $tm->test_script;
  close $fh;
  $output = `export TEST_MODULEVERSION_REQUEST_FAIL=1;perl $file list 2>&1 >/dev/null`;
  like($output, qr/Request to metaCPAN fail\(200 OK\).*___NotExitst-0.1/);
  like($output, qr/HTTP::Tiny/);
}

{
  # string lib
  my $tm = Test::ModuleVersion->new;
  $tm->lib('../extlib/lib/perl5');
  $tm->modules([
    ['Object::Simple' => '3.0625'],
    ['Validator::Custom' => '0.1401'],
    ['___NotExitst' => '0.1'],
  ]);
  my $file = "$FindBin::Bin/output/module.t.output";
  open my $fh, '>', $file
    or die qr/Can't open file "$file": $!/;
  print $fh $tm->test_script;
  close $fh;
  
  my $output = `perl $file`;
  like($output, qr/1\.\.6/);
  like($output, qr/ok 1/);
  like($output, qr/ok 2/);
  like($output, qr/ok 3/);
  like($output, qr/not ok 4/);
  like($output, qr/not ok 5/);
  like($output, qr/not ok 6/);
}

{
  # distnames
  my $tm = Test::ModuleVersion->new;
  $tm->distnames({
    'LWP' => 'libwww-perl',
    'IO::Compress::Base' => 'IO-Compress',
    'Cwd' => 'PathTools',
    'File::Spec' => 'PathTools',
    'List::Util' => 'Scalar-List-Utils',
    'Scalar::Util' => 'Scalar-List-Utils'
  });
  $tm->modules([
    ['LWP' => '6.03'],
    ['IO::Compress::Base' => '2.048'],
    ['Cwd' => '3.33'],
    ['File::Spec' => '3.33'],
    ['List::Util' => '1.23'],
    ['Scalar::Util' => '1.23'],
  ]);
  my $file = "$FindBin::Bin/output/module.t.output";
  $| = 1;
  $tm->test_script(output => $file);
  
  my $output = `perl $file list --no-lwp`;
  like($output, qr/libwww-perl-6.03/);
  like($output, qr/IO-Compress-2.048/);
  like($output, qr/PathTools-3.33.*PathTools-3.33/ms);
  like($output, qr/Scalar-List-Utils-1.23.*Scalar-List-Utils-1.23/ms);
}

