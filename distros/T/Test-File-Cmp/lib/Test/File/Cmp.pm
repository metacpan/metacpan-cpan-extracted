package Test::File::Cmp;

use 5.010;
use strict;
use warnings;

use File::Spec;

use Test::Builder;

use Exporter 'import';


our $VERSION = '0.05';

our @EXPORT_OK = qw(file_is);

my $Test = Test::Builder->new;

sub file_is($$;$) {
  my ($got_f, $exp_f, $name) = (_resolve(shift), _resolve(shift), shift);
  $name //= "compare file '$got_f' with '$exp_f'";
  my @got_lines = split(/\r?\n/, do { local (*ARGV, $/); @ARGV = ($got_f); <> });
  my @exp_lines = split(/\r?\n/, do { local (*ARGV, $/); @ARGV = ($exp_f); <> });
  if (@got_lines != @exp_lines) {
    $Test->ok(0, $name);
    $Test->diag("    Different number of lines");
    return 0;
  }
  my $n = @got_lines;
  for (my $i = 0; $i < $n; ++$i) {
    my ($got, $exp) = ($got_lines[$i], $exp_lines[$i]);
    if ($got ne $exp) {
      $Test->ok(0, $name);
      $Test->diag("    Files differ at line " . ($i + 1));
      return 0;
    }
  }
  return $Test->ok(1, $name);
}


sub _resolve {
  $_[0] =~ m{/} ? File::Spec->catfile(split(m{/}, shift)) : shift;
}



1; # End of Test::File::Cmp


__END__


=head1 NAME

Test::File::Cmp - Test routine for file comparison independent of CRLF or LF line endings.

=head1 VERSION

Version 0.05


=head1 SYNOPSIS

    use Test::File::Cmp qw(file_is);

    # ...
    file_is(got_file, $expected_file);
    # ...

=head1 DESCRIPTION

For testing files and their contents, L<Test::File::Contents> is a good
choice. But I missed one feature: what if you need to run tests on both
systems, Windows and Linux, B<and> the "expected" files might be created on
one or the other system and you don't know that in advance? Then there are
ugly problems with line endings when comparing the contents of two files, and
the C<encoding> argument does not really resolve this.

For this situation I have created a file comparison function provided by this
module, description see below.

=head2 Subroutines

This module exports a single function on demand.

=over

=item C<file_is(I<GOT>, I<EXPECTED>, I<TEST_NAME>)>

=item C<file_is(I<GOT>, I<EXPECTED>)>

This function compares the contents of I<C<GOT>> and I<C<EXPECTED>> line by
line, but replaces each CRLF line ending with LF before the comparison. If the
number of lines differ, then the diagnostic "Different number of lines" is
printed and the test fails without any further comparison. Otherwise, the
files are compared line by line. If a difference is found, then the dignostic
"Files differ at line I<C<n>>" is printed and the test fails.

The test is only successful if there is no difference.

The optional argument I<C<TEST_NAME>> specifies the test name. Default is
"compare file I<C<GOT>> with I<C<EXPECTED>>".

=back


=head1 AUTHOR

Abdul al Hazred, C<< <451 at gmx.eu> >>

=head1 BUGS

Currently there are no known bugs.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::File::Cmp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-File-Cmp>

=item * Search CPAN

L<https://metacpan.org/release/Test-File-Cmp>

=item * GitHub Repository

L<https://github.com/AAHAZRED/perl-Test-File-Cmp.git>


=back



=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Abdul al Hazred.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 SEE ALSO

L<Test::Builder>,
L<Test::File::Contents>,
L<Test::More>


=cut


