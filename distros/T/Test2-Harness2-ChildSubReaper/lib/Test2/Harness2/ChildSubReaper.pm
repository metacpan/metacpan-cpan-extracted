package Test2::Harness2::ChildSubReaper;
use 5.014000;
use strict;
use warnings;

our $VERSION = '0.000001';

use XSLoader;
XSLoader::load('Test2::Harness2::ChildSubReaper', $VERSION);

use Exporter qw/import/;
our @EXPORT_OK = qw/set_child_subreaper have_subreaper_support/;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness2::ChildSubReaper - Tiny XS wrapper around Linux's PR_SET_CHILD_SUBREAPER prctl.

=head1 DESCRIPTION

This distribution exists solely to let L<Test2::Harness2> ask the Linux
kernel to make the current process a "subreaper" for its descendants.

On Linux (kernel 3.4 or newer), a process that sets
C<PR_SET_CHILD_SUBREAPER> becomes the adoptive parent of any descendant
process that gets orphaned, instead of that descendant reparenting to
C<init(1)>. This lets long-running services such as the Test2-Harness2
service reliably C<waitpid> grandchildren and guarantee cleanup when a
test double-forks or calls C<setsid> followed by a parent exit.

The surface area is intentionally minimal: this module exposes exactly
one prctl operation and nothing else. It is meant to replace
L<Linux::Prctl> as an optional runtime dependency of Test2-Harness2
without pulling in the full prctl(2) surface.

=head1 SYNOPSIS

    use Test2::Harness2::ChildSubReaper qw/set_child_subreaper have_subreaper_support/;

    if (have_subreaper_support()) {
        set_child_subreaper(1) or warn "prctl failed: $!";
    }

=head1 EXPORTS

Neither function is exported by default. Request them explicitly.

=over 4

=item $bool = have_subreaper_support()

Returns C<1> if this build of the module was compiled with support for
C<PR_SET_CHILD_SUBREAPER> (i.e. compiled on Linux with the macro
available in F<< <sys/prctl.h> >>). Returns C<0> otherwise.

Safe to call on any platform. Does not make any syscalls.

=item $ok = set_child_subreaper($bool)

Enables (truthy argument) or disables (falsy argument) the subreaper
flag on the current process.

Returns C<1> on success, C<0> on failure with C<$!> (C<errno>) set by
the kernel. On platforms where support was not compiled in, returns
C<0> and sets C<$!> to C<ENOSYS>.

No exception is thrown for runtime failures such as C<EPERM>; the
caller chooses whether to warn, die, or carry on.

=back

=head1 PORTABILITY

The module installs cleanly on any platform Perl can build XS on, so
listing it as an optional or suggested dependency will not cause
installation failures on non-Linux systems. The XS file guards the
real prctl call with C<< #ifdef __linux__ >> and
C<< #ifdef PR_SET_CHILD_SUBREAPER >>; platforms without the macro get
a stub that always returns C<0> with C<$!> set to C<ENOSYS>.

=head1 SEE ALSO

L<Test2::Harness2>, L<prctl(2)>, L<Linux::Prctl>.

=head1 SOURCE

The source code repository for Test2-Harness2-ChildSubReaper can be
found at L<https://github.com/Test-More/Test2-Harness2-ChildSubReaper/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
