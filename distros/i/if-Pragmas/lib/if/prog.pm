package if::prog;

our $DATE = '2014-10-09'; # DATE
our $VERSION = '0.01'; # VERSION

sub work {
  my $method = shift() ? 'import' : 'unimport';
  die "Too few arguments to 'use if::prog'"
    unless @_ >= 2;

  return unless $0 =~ shift;

  my $p = $_[0];		# PACKAGE
  (my $file = "$p.pm") =~ s!::!/!g;
  require $file;		# Works even if $_[0] is a keyword (like open)
  my $m = $p->can($method);
  goto &$m if $m;
}

sub import   { shift; unshift @_, 1; goto &work }
sub unimport { shift; unshift @_, 0; goto &work }

1;
# ABSTRACT: C<use> a Perl module if program matches

__END__

=pod

=encoding UTF-8

=head1 NAME

if::prog - C<use> a Perl module if program matches

=head1 VERSION

This document describes version 0.01 of if::prog (from Perl distribution if-Pragmas), released on 2014-10-09.

=head1 SYNOPSIS

In Perl script:

 use if::prog 'foo|bar', MODULE => ARGUMENTS;

On command-line:

 perl -Mif::prog='foo,Devel::EndStats::LoadedMods' foo ...

In crontab:

 PERL5OPT='-Mif::prog=foo,Devel::EndStats::LoadedMods'

 # this Perl program will load Devel::EndStats::LoadedMods
 0 0 * * * foo some arg
 # this Perl program won't
 1 1 * * * bar other args

=head1 DESCRIPTION

 use if::prog $prog, MODULE => ARGUMENTS;

is a shortcut for:

 use if $0 =~ $prog, MODULE => ARGUMENTS;

The reason this pragma is created is to make it easier to specify on
command-line (especially using the C<-M> perl switch or in C<PERL5OPT>).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/if-Pragmas>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-if-Pragmas>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=if-Pragmas>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
