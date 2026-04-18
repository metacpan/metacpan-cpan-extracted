package Test2::Harness2::ChildSubReaper;
use 5.014000;
use strict;
use warnings;

our $VERSION = '0.000003';

use XSLoader;
XSLoader::load('Test2::Harness2::ChildSubReaper', $VERSION);

use Exporter qw/import/;
our @EXPORT_OK = qw/set_child_subreaper have_subreaper_support subreaper_mechanism/;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness2::ChildSubReaper - Cross-platform wrapper to mark the current process as a child subreaper.

=head1 DESCRIPTION

This distribution exists solely to let L<Test2::Harness2> ask the kernel
to make the current process a "subreaper" for its descendants.

A process with the subreaper flag set becomes the adoptive parent of
any descendant that gets orphaned (its immediate parent exits, as in
a double-fork or C<setsid> + parent exit), instead of that descendant
reparenting to C<init(1)>. This lets long-running services such as the
Test2-Harness2 service reliably C<waitpid> grandchildren and guarantee
cleanup on a hard stop.

The surface area is intentionally minimal: this module exposes exactly
this one kernel concept, mapped to the native primitive on each
supported platform, and nothing else.

=head2 Supported backends

=over 4

=item Linux (3.4+)

C<prctl(PR_SET_CHILD_SUBREAPER, ...)>.
C<subreaper_mechanism()> returns C<"prctl">.

=item FreeBSD (10.2+), DragonFlyBSD

C<procctl(P_PID, getpid(), PROC_REAP_ACQUIRE | PROC_REAP_RELEASE, NULL)>.
C<subreaper_mechanism()> returns C<"procctl">.

=item Any other OS (macOS, OpenBSD, NetBSD, Windows, ...)

The module installs and loads cleanly, but no backend compiles in.
C<have_subreaper_support()> returns C<0>, C<subreaper_mechanism()>
returns C<undef>, and C<set_child_subreaper> returns C<0> with
C<$!> set to C<ENOSYS>.

=back

=head1 SYNOPSIS

    use Test2::Harness2::ChildSubReaper qw/
        set_child_subreaper
        have_subreaper_support
        subreaper_mechanism
    /;

    if (have_subreaper_support()) {
        set_child_subreaper(1)
            or warn "subreaper setup failed: $!";
        warn "subreaper backend: " . subreaper_mechanism();
    }

=head1 EXPORTS

None of the functions are exported by default. Request them explicitly.

=over 4

=item $bool = have_subreaper_support()

Returns C<1> if this build of the module was compiled with a real
backend (Linux C<PR_SET_CHILD_SUBREAPER> or BSD C<PROC_REAP_ACQUIRE>).
Returns C<0> otherwise.

Safe to call on any platform. Does not make any syscalls.

=item $name = subreaper_mechanism()

Returns a short string identifying the compiled-in backend:
C<"prctl"> on Linux, C<"procctl"> on FreeBSD/DragonFlyBSD, or
C<undef> when no backend is available.

Invariant: C<< !!have_subreaper_support() == defined(subreaper_mechanism()) >>.

Useful for startup logs and for diagnostics where the caller wants
to surface which path the kernel is actually taking.

=item $ok = set_child_subreaper($bool)

Enables (truthy argument) or disables (falsy argument) the subreaper
flag on the current process.

Returns C<1> on success, C<0> on failure with C<$!> (C<errno>) set by
the kernel. On platforms where no backend was compiled in, returns
C<0> and sets C<$!> to C<ENOSYS>.

Follows the Perl syscall convention: does not throw on runtime
failures such as C<EPERM>. The caller chooses whether to warn, die,
or carry on.

=back

=head1 PORTABILITY

The module installs cleanly on any platform Perl can build XS on, so
listing it as an optional or suggested dependency will not cause
installation failures. Platform resolution happens at compile time via
C<#ifdef __linux__>, C<#ifdef __FreeBSD__>, and C<#ifdef __DragonFly__>
guards, plus macro checks for the specific kernel operations. Any
platform not matched falls through to a stub that always returns C<0>
with C<$!> set to C<ENOSYS>.

=head1 SEE ALSO

L<Test2::Harness2>, L<prctl(2)>, L<procctl(2)>.

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
