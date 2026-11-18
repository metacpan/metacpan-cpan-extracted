#!/usr/bin/env perl
# k20: the SYNOPSIS of lib/Text/Nunjucks.pm must be a tested example.
#
# The first verbatim block after "=synopsis" is extracted from the POD source,
# run as a program (`$^X -Ilib`) and its STDOUT compared, as bytes, with the
# "expected" of the corpus case "SYNOPSIS of Text::Nunjucks" in
# t/corpus/render-synopsis.json (written by maint/corpus-regen from the oracle,
# never by hand). A second run, with a recorder preloaded, captures the
# template, context and opts the SYNOPSIS really passes to the Environment and
# compares them with the corpus case's, so the oracle-checked case is the
# SYNOPSIS's and not a lookalike.
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use File::Temp qw( tempdir );
use File::Spec;

my $pm     = 'lib/Text/Nunjucks.pm';
my $corpus = 't/corpus/render-synopsis.json';

sub slurp {
  my ($f) = @_;
  open my $fh, '<:raw', $f or die "$f: $!";
  local $/;
  return scalar <$fh>;
}

# The block: after the "=synopsis" (or "=head1 SYNOPSIS") command, the leading
# run of indented lines up to the first unindented prose line; the closing
# "This prints" prose and its block are not code.
my @lines = split /\n/, slurp($pm), -1;
my ($start) = grep { $lines[$_] =~ /^=(?:synopsis|head1\s+SYNOPSIS)\b/ } 0 .. $#lines;
ok( defined $start, 'the POD has a SYNOPSIS section' ) or BAIL_OUT('no SYNOPSIS in ' . $pm);

my @code;
for my $i ( $start + 1 .. $#lines ) {
  my $l = $lines[$i];
  last if $l =~ /^=/;
  last if $l =~ /^\S/;
  push @code, $l =~ /^ {4}(.*)$/ ? $1 : $l =~ /^\s*$/ ? '' : $l =~ s/^\t//r;
}
my $code = join "\n", @code;
$code =~ s/\A\s+|\s+\z//g;
ok( length $code, 'the SYNOPSIS code block is non-empty' ) or BAIL_OUT('empty SYNOPSIS');
like( $code, qr/render_string/, 'the SYNOPSIS renders something' );

my ($case) = grep { $_->{name} =~ /^SYNOPSIS of Text::Nunjucks/ } @{ JSON::PP->new->decode( slurp($corpus) ) };
ok( $case, 'the corpus has the SYNOPSIS case' ) or BAIL_OUT('no corpus case');

# The POD's "This prints" block: the indented lines after the "This prints"
# paragraph, up to the next POD command. The POD indents verbatim blocks by 4
# spaces (stripped here) and the block carries no trailing newline of its own
# (a verbatim block ends at its last line), while the program's output ends
# with "\n" after the last line: the expected output is compared with the block
# plus that one newline, explicitly.
my ($prints) = grep { $lines[$_] =~ /^This prints\b/ } $start .. $#lines;
ok( defined $prints, 'the POD has a "This prints" block' ) or BAIL_OUT('no "This prints" in ' . $pm);
my @shown;
for my $i ( $prints + 1 .. $#lines ) {
  last if $lines[$i] =~ /^=/;
  push @shown, $lines[$i] =~ /^ {4}(.*)$/ ? $1 : $lines[$i];
}
my $shown = join "\n", @shown;
$shown =~ s/\A\s+|\s+\z//g;
is( "$shown\n", $case->{expected}{output}, 'the POD "This prints" block equals the corpus expected output' );

my $dir = tempdir( CLEANUP => 1 );
my $prog = File::Spec->catfile( $dir, 'synopsis.pl' );
open my $out, '>:raw', $prog or die $!;
print {$out} $code, "\n";
close $out;

# Run 1: the program's plain STDOUT.
my $got = qx{"$^X" -Ilib "$prog" 2>"$dir/stderr"};
is( $? >> 8, 0, 'the SYNOPSIS runs and exits 0' );
is( slurp("$dir/stderr"), '', 'the SYNOPSIS prints nothing to STDERR' );
is( $got, $case->{expected}{output}, 'the SYNOPSIS output equals the oracle-generated corpus expected' );

# Run 2: record what the SYNOPSIS passes in.
my $rec  = File::Spec->catfile( $dir, 'Recorder.pm' );
my $dump = File::Spec->catfile( $dir, 'recorded.json' );
open my $r, '>:raw', $rec or die $!;
print {$r} <<'PERL';
package Recorder;
use strict; use warnings; use JSON::PP ();
use Text::Nunjucks::Environment;
my %seen;
{
  no warnings 'redefine'; no strict 'refs';
  my $new = \&Text::Nunjucks::Environment::new;
  *Text::Nunjucks::Environment::new = sub { $seen{opts} = { %{ $_[2] // {} } }; goto &$new };
  my $rs = \&Text::Nunjucks::Environment::render_string;
  *Text::Nunjucks::Environment::render_string = sub { @seen{qw(template context)} = @_[1,2]; goto &$rs };
}
END {
  open my $fh, '>:raw', $ENV{SYNOPSIS_DUMP} or die $!;
  print {$fh} JSON::PP->new->canonical->allow_nonref->encode( \%seen );
}
1;
PERL
close $r;

{
  local $ENV{SYNOPSIS_DUMP} = $dump;
  my $null = File::Spec->devnull;
  system( "\"$^X\" -Ilib -I\"$dir\" -MRecorder \"$prog\" >\"$null\"" ) == 0 or fail('recorded run failed');
}
my $seen = -e $dump ? JSON::PP->new->decode( slurp($dump) ) : {};
my $j = JSON::PP->new->canonical;
is( $seen->{template}, $case->{template}, 'the SYNOPSIS template is the corpus case template' );
is( $j->encode( $seen->{context} // {} ), $j->encode( $case->{context} // {} ), 'the SYNOPSIS context is the corpus case context' );
# The SYNOPSIS passes Perl 1 where the corpus has JSON true: compare booleans by value.
my $norm = sub { my $h = shift // {}; +{ map { $_ => ( JSON::PP::is_bool( $h->{$_} ) ? ( $h->{$_} ? 1 : 0 ) : $h->{$_} ) } keys %$h } };
is( $j->encode( $norm->( $seen->{opts} ) ), $j->encode( $norm->( $case->{opts} ) ), 'the SYNOPSIS opts are the corpus case opts' );

done_testing;
