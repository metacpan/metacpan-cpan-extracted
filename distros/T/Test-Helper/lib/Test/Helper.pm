# $Id: Helper.pm 1.7 Fri, 05 Sep 1997 16:08:15 -0400 jesse $

package Test::Helper;
use Carp;
use IO::File;
use vars qw($VERSION @ISA @EXPORT $count $output);
use Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(ok comm test runs heinous syntax_check);
# $Format: "$VERSION='$TestHelperRelease$';"$
$VERSION='0.002';

sub test(&) {
  local($count)=0;
  local($output)='';
  eval {&{+shift}};
  $count++ if $@;		# Simulate something wrong.
  print "1..$count\n$output";
  die $@ if $@;
}

sub ok($;) {
  my $isok=shift;
  $output .= 'not ' unless $isok;
  $count++;
  $output .= "ok $count\n";
}

sub comm(@) {
  my $comm=join '', @_;
  $output .= "# $comm...\n";
}

sub runs(&) {
  my $subr=shift;
  eval {&$subr()};
  not $@;
}

sub heinous(&) {
  carp "`heinous {...}' is deprecated--use `ok not runs {...} instead'";
  my $subr=shift;
  ok not &runs($subr);
}

sub syntax_check() {
  my @mani=grep {
    not /\.(t|PL)$/ and not m!^t/! and $_ ne 'test.pl'
  } map {
    chomp;
    s!^lib/!!;
    $_;
  } IO::File->new('MANIFEST')->getlines;
  print "To be checked: @mani\n";

  local($^W)=1;
  my $file; foreach $file (@mani) {
    if ($file =~ /\.pm$/) {
      comm "Requiring $file";
      eval {require $file};
      print STDERR $@ if $@;
      ok not $@;
    } elsif ($file =~ /\.pl$/ or
	     (-r $file and -x $file and
	      IO::File->new($file)->getline =~ /^\#!\S*perl/)) {
      comm "Syntax-checking $file";
      ok not system $^X, '-wc', $file;
    } else {
      comm "Skipping $file";
    }
  }
}

1;
__END__

=head1 NAME

B<Test::Helper> - easy creation of test scripts

=head1 SYNOPSIS

 use Test::Helper;
 test {
   comm 'Doing first part of test';
   ok $variable==$correct_value;
   ok not runs {this_should_die()};
 };

=head1 DESCRIPTION

Enclose the body of your test script within a B<test> block. Within that block, run
individual tests with the B<ok> function, which should be passed a scalar that you
desire to be true; this will print "ok I<number>" or "not ok I<number>" as
appropriate. Similarly, the B<runs> command will expect its body not to signal an error
when run; use it with B<ok>, negated or not. Note that the B<test> block keeps track of
how many tests there are and outputs the first line accordingly (it stores up the
messages); if an uncaught exception is raised within the body, it simulates one last
failed test and propagates the exception in order to ensure that it is counted as a
failure. B<comm> just writes out a comment to the standard output where it will be
visible in verbose testing mode. B<syntax_check> checks the syntax of modules and
scripts listed in the F<MANIFEST>.

=head1 SEE ALSO

See L<Test::Harness(3)>, for how test scripts are run; and L<ExtUtils::MakeMaker(3)>,
for where to put test scripts (usually as files F<t/*.t>) in a distribution.

=head1 AUTHORS

Jesse Glick, B<jglick@sig.bsh.com>

=head1 REVISION

X<$Format: "F<$Source$> last modified $Date$. Release $TestHelperRelease$. $Copyright$"$>
F<Test-Helper/lib/Test/Helper.pm> last modified Fri, 05 Sep 1997 16:08:15 -0400. Release 0.002. Copyright (c) 1997 Strategic Interactive Group. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
