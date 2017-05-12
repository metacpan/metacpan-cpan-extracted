#!perl

use strict;
use warnings;

use Test::More tests => 5;

use lib 't/lib';
use VPIT::TestHelpers 'capture';

BEGIN { delete $ENV{PERL_INDIRECT_PM_DISABLE} }

sub compile_err_code {
 my ($fatal) = @_;

 if ($fatal) {
  $fatal = 'no indirect q[fatal]; sub foo { \$bar }';
 } else {
  $fatal = 'no indirect;';
 }

 return "use strict; use warnings; $fatal; baz \$_; sub qux { \$ook }";
}

my $indirect_msg = qr/Indirect call of method "baz" on object "\$_"/;
my $core_err1    = qr/Global symbol "\$bar"/;
my $core_err2    = qr/Global symbol "\$ook"/;
my $aborted      = qr/Execution of -e aborted due to compilation errors\./;
my $failed_req   = qr/Compilation failed in require/;
my $line_end     = qr/[^\n]*\n/;
my $compile_err_warn_exp  = qr/$indirect_msg$line_end$core_err2$line_end/o;
my $compile_err_fatal_exp = qr/$core_err1$line_end$indirect_msg$line_end/o;

SKIP: {
 my ($stat, $out, $err) = capture_perl compile_err_code(0);
 skip CAPTURE_PERL_FAILED($out) => 1 unless defined $stat;
 like $err, qr/\A$compile_err_warn_exp$aborted$line_end\z/o,
            'no indirect warn does not hide compilation errors outside of eval';
}

SKIP: {
 my $code = compile_err_code(0);
 my ($stat, $out, $err) = capture_perl "eval q[$code]; die \$@ if \$@";
 skip CAPTURE_PERL_FAILED($out) => 1 unless defined $stat;
 like $err, qr/\A$compile_err_warn_exp\z/o,
             'no indirect warn does not hide compilation errors inside of eval';
}

SKIP: {
 my ($stat, $out, $err) = capture_perl compile_err_code(1);
 skip CAPTURE_PERL_FAILED($out) => 1 unless defined $stat;
 like $err, qr/\A$compile_err_fatal_exp\z/o,
           'no indirect fatal does not hide compilation errors outside of eval';
}

{
 local $@;
 eval compile_err_code(1);
 like $@, qr/\A$compile_err_fatal_exp\z/o,
            'no indirect fatal does not hide compilation errors inside of eval';
}

{
 local $@;
 eval { require indirect::TestCompilationError };
 like $@, qr/\A$compile_err_fatal_exp$failed_req$line_end\z/o,
         'no indirect fatal does not hide compilation errors inside of require';
}
