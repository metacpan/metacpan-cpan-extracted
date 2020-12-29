package XS::Tutorial;
BEGIN { our $VERSION = 0.04 }
1;

=encoding utf8

=head1 NAME

XS::Tutorial - documentation with examples for learning Perl XS

=over 4

=item * L<XS::Tutorial::One> - how to pass to and return basic values from C functions

=item * L<XS::Tutorial::Two> - working with more than one value at a time

=item * L<XS::Tutorial::Three> - utility routines that are good to know

=back

=head1 SOURCES OF INFORMATION

=head3 XS Mechanics by Steven W. McDougall

A clear L<introduction|http://world.std.com/~swmcd/steven/perl/pm/xs/intro/> to XS programming.

=head3 Extending and Embedding Perl (Manning) by Simon Cozens and Tim Jenness

A thorough L<introduction|https://www.manning.com/books/extending-and-embedding-perl>, with many examples. Outdated in parts (mostly data structures) but still an excellent reference.

=head3 perldoc

=over 4

=item * L<perlxs|http://perldoc.perl.org/perlxs.html>: syntax of xsubs

=item * L<perlapi|http://perldoc.perl.org/perlapi.html> : C macros used to interact with Perl data structures (and the interpreter)

=item * L<perlguts|http://perldoc.perl.org/perlguts.html>: Perl data structures

=item * L<perlxstypemap|http://perldoc.perl.org/perlxstypemap.html>: typemap syntax (translating C types into Perl)

=item * L<perlcall|http://perldoc.perl.org/perlcall.html>: how to call Perl subroutines and methods from XS

=item * L<perlxstut|http://perldoc.perl.org/perlxstut.html>: another XS tutorial

=back

=head3 ExtUtils::MakeMaker

The L<documentation|https://metacpan.org/pod/ExtUtils::MakeMaker> explains all of the options in C<Makefile.PL>. Useful if you need to pass additional flags or options to the C compiler.

=head3 ppport.h

A header file, needed for compatibility across Perl versions. See L<Devel::PPPort|https://metacpan.org/pod/Devel::PPPort>.

=head3 Perl source code

if you can’t find an answer in documentation, grep the L<source|https://www.perl.org/get.html>.

=cut
