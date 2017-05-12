#! perl -w
use strict;
$| = 1;

my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
use TestLib;

use File::Spec::Functions;
use Test::More;

my @logs;
BEGIN {
    @logs = ( 
        { file => 'w32bcc32.log',   type => 'bcc32',
          wcnt =>  0, ecnt => 0, lcnt => 0 },
        { file => 'solaris.log',    type => 'solaris',
          wcnt =>  0, ecnt => 0, lcnt => 0 },
        { file => 'hpux1020.log',   type => 'hpux',
          wcnt =>  0, ecnt => 0, lcnt => 0 },
        { file => 'hpux1111.log',   type => 'hpux',
          wcnt =>  0, ecnt => 0, lcnt => 0 },
        { file => 'mingw.log',      type => 'gcc',
          wcnt =>  0, ecnt => 0, lcnt => 0 }, 
        { file => 'icc102.log',     type => 'icc',
          wcnt =>  0, ecnt => 0, lcnt => 0 },
        { file => 'icc102.log',     type => 'icpc',
          wcnt =>  0, ecnt => 0, lcnt => 0 },
        { file => 'linux3710g.log', type => 'gcc',
          wcnt =>  0, ecnt => 0, lcnt => 1 },
    );

    plan tests => 1 + 4 * @logs;

    use_ok 'Test::Smoke::Util', 'grepnonfatal';
}

my $verbose = $ENV{SMOKE_VERBOSE} || 0;

for my $log ( @logs ) {
    my $file = catfile "t", "logs", $log->{file};
    ok -f $file, "logfile($file) exists";

    my $logs;
    if (open my $fh, '<', $file) {
        $logs = do { local $/; <$fh> };
        close $fh;
    }
    else {
        diag("Problem reading '$file': $!");
    }
    my @errors = grepnonfatal( $log->{type}, $logs, $verbose );

    is scalar @errors, $log->{lcnt},
       "Lines extracted from $log->{file}: $log->{lcnt}"
         or diag join "\n",@errors;

    my $wcnt = grep /\bwarning\b/i => @errors;
    is $wcnt, $log->{wcnt},
       "Number of warnings: $log->{wcnt}";

    my $ecnt = grep /\berror\b/i => @errors;
    is $ecnt, $log->{ecnt},
       "Number of errors: $log->{ecnt}";
}
