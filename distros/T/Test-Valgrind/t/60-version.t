#!perl -T

use strict;
use warnings;

use Test::More tests => 6 + 5 + 4 * 9 + 2 * 23 + 2 * 14;

use Test::Valgrind::Version;

sub TVV () { 'Test::Valgrind::Version' }

sub sanitize {
 my $str = shift;

 $str = '(undef)' unless defined $str;
 1 while chomp $str;
 $str =~ s/\n/\\n/g;

 $str;
}

my @command_failures = (
 undef,
 'valgrind',
 '1.2.3',
 'valgrin-1.2.3',
 'VALGRIND-1.2.3',
 "doo dah doo\nvalgrind-1.2.3",
);

for my $failure (@command_failures) {
 my $desc = sanitize $failure;
 local $@;
 eval { TVV->new(command_output => $failure) };
 like $@, qr/^Invalid argument/,
          "\"$desc\" correctly failed to parse as command_output";
}

my @string_failures = (
 undef,
 'valgrind',
 'valgrind-1.2.3',
 'abc',
 'd.e.f',
);

for my $failure (@string_failures) {
 my $desc = sanitize $failure;
 local $@;
 eval { TVV->new(string => $failure) };
 like $@, qr/^Invalid argument/,
          "\"$desc\" correctly failed to parse as string";
}

my @command_valid = (
 'valgrind-1'          => '1.0.0',
 'valgrind-1.2'        => '1.2.0',
 'valgrind-1.2.3'      => '1.2.3',
 'valgrind-1.2.4-rc5'  => '1.2.4',
 'valgrind-1.2.6a'     => '1.2.6',
 'valgrind-1.2.7.'     => '1.2.7',
 'valgrind-1.2.x.8'    => '1.2.0',
 'valgrind-1.10.'      => '1.10.0',
 'valgrind-3.12.0.SVN' => '3.12.0',
);

my @string_valid = map { my $s = $_; $s =~ s/^valgrind-//; $s }
                    @command_valid;

while (@command_valid) {
 my ($output, $exp) = splice @command_valid, 0, 2;
 my $desc = sanitize $output;
 local $@;
 my $res = eval { TVV->new(command_output => $output)->_stringify };
 is $@,   '',   "\"$desc\" is parseable as command_output";
 is $res, $exp, "\"$desc\" parses correctly as command_output";
}

while (@string_valid) {
 my ($str, $exp) = splice @string_valid, 0, 2;
 my $desc = sanitize $str;
 local $@;
 my $res = eval { TVV->new(string => $str)->_stringify };
 is $@,   '',   "\"$desc\" is parseable as string";
 is $res, $exp, "\"$desc\" parses correctly as string";
}

sub tvv_s {
 my ($string) = @_;
 local $@;
 eval { TVV->new(string => $string) };
}

my @compare = (
 '1',       '1',      0,
 '1',       '1.0',    0,
 '1',       '1.0.0',  0,
 '1.1',     '1',      1,
 '1.1',     '1.0',    1,
 '1.1',     '1.0.0',  1,
 '1',       '1.1',    -1,
 '1.0',     '1.1',    -1,
 '1.0.0',   '1.1',    -1,
 '1.1',     '1.2',    -1,
 '1.1.0',   '1.2',    -1,
 '1.1',     '1.2.0',  -1,
 '1.1.0',   '1.2.0',  -1,
 '1',       '1',      0,
 '1.0.1',   '1',      1,
 '1.0.1.0', '1',      1,
 '1.0.0.1', '1',      1,
 '1.0.0.1', '1.0.1',  -1,
 '1.0.0.2', '1.0.1',  -1,
 '3.4.0',   '3.4.1',  -1,
 '3.5.2',   '3.5.1',  1,
 '3.12.0',  '3.1.0',  1,
 '3.1.0',   '3.12.0', -1,
);

while (@compare) {
 my ($left, $right, $exp) = splice @compare, 0, 3;

 my $desc = sanitize($left) . ' <=> ' . sanitize($right);

 $left  = tvv_s($left);
 $right = tvv_s($right);

 my ($err, $res) = '';
 if (defined $left and defined $right) {
  local $@;
  $res = eval { $left <=> $right };
  $err = $@;
 } elsif (defined $right) {
  $res = -2;
 } elsif (defined $left) {
  $res = 2;
 }

 is $err, '',   "\"$desc\" compared without croaking";
 is $res, $exp, "\"$desc\" compared correctly";
}

my @stringify = (
 '1',         '1.0.0',
 '1.0',       '1.0.0',
 '1.0.0',     '1.0.0',
 '1.0.0.0',   '1.0.0',
 '1.2',       '1.2.0',
 '1.2.0',     '1.2.0',
 '1.2.0.0',   '1.2.0',
 '1.2.3',     '1.2.3',
 '1.2.3.0',   '1.2.3',
 '1.2.3.4',   '1.2.3.4',
 '1.2.3.4.0', '1.2.3.4',
 '1.0.3',     '1.0.3',
 '1.0.0.4',   '1.0.0.4',
 '1.2.0.4',   '1.2.0.4',
);

while (@stringify) {
 my ($str, $exp) = splice @stringify, 0, 2;
 my $desc = sanitize($str);
 local $@;
 my $res = eval { my $v = TVV->new(string => $str); "$v" };
 is $@,   '',   "\"$desc\" stringification did not croak";
 is $res, $exp, "\"$desc\" stringified correctly";
}
