my $skip;
BEGIN {
    eval "use Class::Accessor";
    if ($@) { $skip = 'Class::Accessor required to run this test' }
}

use strict;
use warnings;

use Config;
use Test::More $skip ? (skip_all => $skip) : ();
use IPC::Run3;
use YAML::Syck qw(LoadFile);
use Data::Dumper;

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys=1;

plan tests => 4;

my $script = 'script/umlclass.pl';
my @cmd = ($^X, '-Ilib', $script);
my ($stdout, $stderr);

{
    my $outfile = 'preload.yml';

    unlink $outfile if -f $outfile;
    ok run3( [@cmd, '--out', $outfile, '-E', $Config{archlibexp}, '-M', 'TestClassAccessor', '-I', 't/data'],
              \undef, \$stdout, \$stderr ),
        "umlclass -o $outfile -E $Config{archlibexp}";
    #warn $stdout;
    like $stdout, qr/TestClassAccessor/,
        "stdout ok - $outfile generated.";
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    #ok( (-s $outfile > 1000), "$outfile is nonempty" );
    if (-f $outfile) {
        my $dom = LoadFile($outfile);
        is Dumper($dom), <<'_EOC_';
$VAR1 = {
  'classes' => [
    {
      'methods' => [
        'blah'
      ],
      'name' => 'TestClassAccessor',
      'properties' => [
        'name',
        'role',
        'salary'
      ],
      'subclasses' => []
    }
  ]
};
_EOC_
    } else {
        fail "no yml file";
    }
}

