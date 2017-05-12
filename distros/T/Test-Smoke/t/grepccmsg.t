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
        { file => 'w32bcc32.log', type => 'bcc32',
          wcnt => 12, ecnt => 1, lcnt => 13 },
        { file => 'solaris.log',  type => 'solaris',
          wcnt =>  2, ecnt => 0, lcnt => 2 },
        { file => 'hpux1020.log', type => 'hpux',
          wcnt =>  1, ecnt => 0, lcnt => 1 },
        { file => 'hpux1111.log', type => 'hpux',
          wcnt =>  2, ecnt => 0, lcnt => 2 },
        { file => 'mingw.log',    type => 'gcc',
          wcnt =>  1, ecnt => 0, lcnt => 32 }, 
        { file => 'icc102.log',   type => 'icc',
          wcnt =>  5, ecnt => 2, lcnt => 7 },
        { file => 'icc102.log',   type => 'icpc',
          wcnt =>  5, ecnt => 2, lcnt => 7 },
        { file => 'linux3710g.log', type => 'gcc',
          wcnt =>  1, ecnt => 1, lcnt => 1 },
    );

    plan tests => 1 + 5 * @logs + 1;

    use_ok 'Test::Smoke::Util', 'grepccmsg';
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
    my @errors = grepccmsg( $log->{type}, $logs, $verbose );

    ok @errors, "Found messages in '$log->{file}'";
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

{
    my $file = catfile 't', 'logs', 'gcc2722.log';
    my $logs;
    if (open my $fh, '<', $file) {
        $logs = do { local $/; <$fh> };
        close $fh;
    }
    else {
        diag("Problem reading '$file': $!");
    }
    my @errors = grepccmsg( 'gcc', $logs, $verbose );
    my $report = join "\n", @errors;

    ( my $orig = get_file( $file ) ) =~ s/\n$//;
    is $report, $orig, "Got all the gcc-2.7.2.2 messages";
}
