# -*- perl -*-
use strict; use warnings;
use Test::More;
my $n_tests;

use constant DEVNULL => $^O eq 'MSWin32' ? 'NUL' : '/dev/null';
use constant REDIRECT => '>' . DEVNULL . ' 2>' . DEVNULL;
use constant Q_REDIRECT => '" ' . REDIRECT;

use constant ERR_TXT => ( 'boo', 'bah');
use constant ERRFILE => {
    mine => 'my_errors',
    std  => 'errors.err',
};
# number of tests per call of run_tests()
use constant PER_CALL => @{ [ ERR_TXT]};

BEGIN { $n_tests += 2 * PER_CALL }
{{
my $command = qq($^X -Ilib -e");
$command .= qq(use Vi::QuickFix;);
$command .= qq( warn qq($_); print STDERR qq(# something else\\n);) for ERR_TXT;
$command .= Q_REDIRECT;
run_tests( 'module_use', 'std', $command);

$command = qq($^X -Ilib -MVi::QuickFix -e");
$command .= qq( warn qq($_);) for ERR_TXT;
$command .= Q_REDIRECT;
run_tests( 'module_switch', 'std', $command);

}}

BEGIN { $n_tests += 2 * PER_CALL }
{{
my $command = qq($^X -Ilib -MVi::QuickFix=*ERRFILE* -e");
$command .= qq(warn qq($_); ) for ERR_TXT;
$command .= Q_REDIRECT;
run_tests( 'module_switch', 'mine', $command);

$command = qq($^X -Ilib -e");
$command .= qq(use Vi::QuickFix "*ERRFILE*"; );
$command .= qq(warn qq($_); print STDERR qq(something else\\n); ) for ERR_TXT;
$command .= Q_REDIRECT;
run_tests( 'module_use', 'mine', $command);
}}

### If $] >= 5.008001, the above has tested "tie" mode, and we now
# want to check "sig" mode.  If $] < 5.008001, the above has tested
# "sig" mode.  Since "tie" mode can't be run, we just skip the "sig"-
# specific tests

use constant LOW_VERSION => $] < 5.008001;
use constant REASON_LOW => "already done with perl $]";

BEGIN { $n_tests += 2 * PER_CALL }
SKIP: {{
skip REASON_LOW, 2 * PER_CALL if LOW_VERSION;

my $command = qq($^X -Ilib -MVi::QuickFix=sig -e");
$command .= qq(warn qq($_); ) for ERR_TXT;
$command .= Q_REDIRECT;
run_tests( 'module_switch(sig)', 'std', $command);

$command = qq($^X -Ilib -e");
$command .= qq(use Vi::QuickFix qw( sig); );
$command .= qq(warn qq($_); print STDERR qq(# something else\\n); ) for ERR_TXT;
$command .= Q_REDIRECT;
run_tests( 'module_use(sig)', 'std', $command);
}}

BEGIN { $n_tests += 2 * PER_CALL }
SKIP: {{
skip REASON_LOW, 2 * PER_CALL if LOW_VERSION;

my $command = qq($^X -Ilib -MVi::QuickFix=sig,*ERRFILE* -e");
$command .= qq(warn qq($_); ) for ERR_TXT;
$command .= Q_REDIRECT;
run_tests( 'module_switch(sig)', 'mine', $command);

$command = qq($^X -Ilib -e");
$command .= qq(use Vi::QuickFix "sig", "*ERRFILE*"; );
$command .= qq(warn qq($_); print STDERR qq(something else\\n); ) for ERR_TXT;
$command .= Q_REDIRECT;
run_tests( 'module_use(sig)', 'mine', $command);
}}

### more non-specific tests (as to sig/warn)

# prepare input file for executable (used in two test blocks)
open my $infile, '>', 'infile' or die;
print $infile "$_ at some_file line 12.\nsomething_else\n" for ERR_TXT;
close $infile;

BEGIN { $n_tests += 2 * ( PER_CALL + 1) }
{{
my $command = qq($^X lib/Vi/QuickFix.pm infile >outfile 2>) . DEVNULL;
run_tests( 'command_file', 'std', $command);
is( -s 'outfile', -s 'infile', 'input copied to stdout');

$command = qq($^X ./lib/Vi/QuickFix.pm <infile >outfile 2>) . DEVNULL;
run_tests( 'command_stdin', 'std', $command);
is( -s 'outfile', -s 'infile', 'file copied to stdout');
}}

BEGIN { $n_tests += 2 + 2 * PER_CALL }
{{

# check -v key (version)
my $command = qq($^X lib/Vi/QuickFix.pm -v);
open my $f, "$command |";
ok( defined $f, "got a handle");
like( scalar <$f>, qr/version *\d+\.\d+/, "-v returns version");

$command = qq($^X lib/Vi/QuickFix.pm -f *ERRFILE* infile) . REDIRECT;
run_tests( 'command_file', 'mine', $command);

$command = qq($^X lib/Vi/QuickFix.pm -q *ERRFILE* <infile) . REDIRECT;
run_tests( 'command_stdin', 'mine', $command);
}}
unlink 'infile', 'outfile';

# do we catch (not catch) all types of STDERR output?
use constant CASES => (
    [ runtime_warning =>     '() = qq(a) + 0',    'Argument "a"' ],
    [ runtime_error =>       'my %h = %{ \ 0 }',  'Not a HASH'   ],
    [ compiletime_warning => 'my @y; @y = @y[0]', 'Scalar value' ],
    [ compiletime_error =>   '%',                 'syntax error' ],
    [ explicit_warning =>    'warn qq(xxx)',      'xxx'          ],
    [ explicit_error =>      'die qq(yyy)',       'yyy'          ],
);
BEGIN { $n_tests += 2*@{ [ CASES]} }
{{
for ( CASES ) {
    my ( $case, $prog, $msg) = @$_;
    unlink 'errors.err';
    my $cmd = qq($^X -Ilib -MVi::QuickFix -we "$prog" ) . REDIRECT;
    system $cmd;
    like( read_errfile(), qr/^.*:\d+:$msg/, "$case message");
}
for ( CASES ) {
    my ( $case, $prog, $msg) = @$_;
    unlink 'errors.err';
    my $cmd = qq($^X -Ilib -MVi::QuickFix -we "eval '$prog'" ) . REDIRECT;
    system $cmd;
    if ( $case =~ /_error$/ ) {
        $msg = 'QuickFix .* active';
        like( read_errfile(), qr/^.*:\d+:$msg/, "eval $case no message");
    } else {
        like( read_errfile(), qr/^.*:\d+:$msg/, "eval $case message");
    }
}
}}

# repeat these in "sig" mode, if both modes possible
BEGIN { $n_tests += 2*@{ [ CASES]} }
SKIP: {{
skip REASON_LOW, scalar 2*@{ [ CASES]} if LOW_VERSION;
for ( CASES ) {
    my ( $case, $prog, $msg) = @$_;
    unlink 'errors.err';
    my $cmd =
        qq($^X -Ilib -MVi::QuickFix=sig -we "$prog" ) . REDIRECT;
    system $cmd;
    like( read_errfile(), qr/^.*:\d+:$msg/, "$case(sig) message");
}
for ( CASES ) {
    my ( $case, $prog, $msg) = @$_;
    unlink 'errors.err';
    my $cmd =
        qq($^X -Ilib -MVi::QuickFix=sig -we "eval '$prog'" ) . REDIRECT;
    system $cmd;
    if ( $case =~ /_error$/ ) {
        $msg = 'QuickFix .* active';
        like( read_errfile(), qr/^.*:\d+:$msg/, "eval $case(sig) no message");
    } else {
        like( read_errfile(), qr/^.*:\d+:$msg/, "eval $case(sig) message");
    }
}
}}

# repeat these in "fork" mode
BEGIN { $n_tests += 2*@{ [ CASES]} }
SKIP: {{
skip "'fork' mode currently not testable", 2*@{ [ CASES]};
for ( CASES ) {
    my ( $case, $prog, $msg) = @$_;
    unlink 'errors.err';
    my $cmd = qq($^X -Ilib -MVi::QuickFix=fork -we "$prog" ) . REDIRECT;
    system $cmd;
    like( read_errfile(), qr/^.*:\d+:$msg/, "$case(fork) message");
}
for ( CASES ) {
    my ( $case, $prog, $msg) = @$_;
    unlink 'errors.err';
    my $cmd = qq($^X -Ilib -MVi::QuickFix=fork -we "eval '$prog'" ) . REDIRECT;
    system $cmd;
    if ( $case =~ /_error$/ ) {
        $msg = 'QuickFix .* active';
        like( read_errfile(), qr/^.*:\d+:$msg/, "eval $case(fork) no message");
    } else {
        like( read_errfile(), qr/^.*:\d+:$msg/, "eval $case(fork) message");
    }
}
}}

BEGIN { $n_tests += 8 }
{{
# do we get the obligatory warning?
unlink 'errors.err';
my $cmd =
    qq($^X -Ilib -MVi::QuickFix -we "warn qq(abc)" ) . REDIRECT;
system $cmd;
like( (read_errfile())[ -1],
    qr/QuickFix.*active/, "obligatory message found");

# does silent mode work?
unlink 'errors.err';
system qq($^X -Ilib -MVi::QuickFix=silent -we 'warn "abc"' ) . REDIRECT;
unlike( (read_errfile())[ -1],
    qr/QuickFix/, "silent mode message not found");

# do we get only one obwarn when we fork?
unlink 'errors.err';
system qq($^X -Ilib -MVi::QuickFix -efork ) . REDIRECT;
is( scalar( () = read_errfile()), 1, "fork one message");

# do we not get it in exec mode?
unlink 'errors.err';
system qq($^X lib/Vi/QuickFix.pm <) . DEVNULL . ' ' . REDIRECT;
ok( not( -e 'errors.err'), "no message in exec mode");

# is an empty error file removed (needs silent mode)?
system qq($^X -Ilib -MVi::QuickFix -we ';' ) . REDIRECT; # create error file
ok( -e 'errors.err', "Error file exists");
system( qq($^X -Ilib -MVi::QuickFix=silent -we";"));
ok( not( -e 'errors.err'), "Empty error file erased");

# Does it behave under -c?
unlink qw( stderr_out errors.err);
system qq($^X -c -Ilib -we"use Vi::QuickFix" 2>stderr_out);
is( -s( 'errors.err') || 0, 0, "-c: error file empty");
like( read_errfile( 'stderr_out'), qr/^-e syntax OK/, "-c: -e syntax OK");
unlink qw( stderr_out errors.err);
}}

### environment variable VI_QUICKFIX_SOURCEFILE
BEGIN { $n_tests += 2 }
{{
my $cmd = qq($^X -Ilib -MVi::QuickFix ) . REDIRECT;

delete $ENV{ VI_QUICKFIX_SOURCEFILE};
open my $p, '|-', $cmd;
print $p 'warn "boo"';
close $p;
like ( read_errfile(), qr/^-:/, 'env-var unset, found "-"');

$ENV{ VI_QUICKFIX_SOURCEFILE} = 'somefile.pl';
open $p, '|-', $cmd;
print $p 'warn "boo"';
close $p;
like ( read_errfile(), qr/^$ENV{ VI_QUICKFIX_SOURCEFILE}:/,
    "env-var set, found filename");
}}

# error behavior
BEGIN { $n_tests += 5 }
{{
# unable to create error file
require Vi::QuickFix;
local $SIG{__WARN__} = sub { die @_ };
eval { Vi::QuickFix->import( 'tie', 'gibsnich/wirdnix') };
like( $@, qr/Can't create error file/, "Warning without error file");

SKIP: {
    skip "Can't be tested with perl $]", 3 if LOW_VERSION;

    # refuse to re-tie STDERR
    require Tie::Handle;
    tie *STDERR, 'Tie::StdHandle', '>&STDERR';
    require Vi::QuickFix;
    eval { Vi::QuickFix->import( 'tie') };
    like( $@, qr/STDERR already tied/, "Refused to re-tie");
    untie *STDERR;

    # accept second use (no action then)
    Vi::QuickFix->import( 'tie', 'silent');
    ok( tied *STDERR, 'Second use: STDERR is tied');
    eval { Vi::QuickFix->import('tie') };
    like( $@, qr/^$/, 'Second use no error');
    untie *STDERR;
}

# reject "tie" mode on low version
SKIP: {
    skip "irrelevant with perl $]", 1 unless LOW_VERSION;

    # make silent, so test doesn't warn
    eval { Vi::QuickFix->import( 'tie', 'silent') };
    like( $@, qr/^Cannot use 'tie'/, 'Reject tie mode');
}

}}

BEGIN { plan tests => $n_tests }

#####################################################################

sub  run_tests {
    my ( $call, $errf, $command) = @_;
    my $errfile = ERRFILE->{ $errf};
    $command =~ s/\*ERRFILE\*/$errfile/g;
    unlink $errfile;
    system( $command);
#   don't forget PER_CALL when uncommenting
#   ok( -s $errfile, "$call $errf size");
    my @lines = read_errfile( $errfile);
    my $i;
    for ( ERR_TXT ) {
        $i ++;
        my $line = shift @lines;
        like( $line, qr/^(.*?):\d+:$_$/, "$call $errf $i");
    }
    unlink $errfile;
}

sub read_errfile {
    my $file = shift || 'errors.err';
    
    open my( $e), '<', $file or return '-';
    return join '', <$e> unless wantarray;
    return <$e>;
}
