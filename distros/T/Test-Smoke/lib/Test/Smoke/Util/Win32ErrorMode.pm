package Test::Smoke::Util::Win32ErrorMode;
use warnings;
use strict;

our $VERSION = '0.001';

BEGIN {
    if ($^O eq 'MSWin32') {
        require Win32::API;
        require Win32;
    }
    else {
        warn "# This is not MSWin32, don't try to use this module on $^O\n";
    }
}

sub lower_error_settings {
    return if $^O ne 'MSWin32';
    # Call kernel32.SetErrorMode(SEM_FAILCRITICALERRORS):
    # "The system does not display the critical-error-handler message box.
    # Instead, the system sends the error to the calling process." and
    # "A child process inherits the error mode of its parent process."
    {
        my $SetErrorMode = Win32::API->new('kernel32', 'SetErrorMode', 'I', 'I');
        my $SEM_FAILCRITICALERRORS = 0x0001;
        my $SEM_NOGPFAULTERRORBOX  = 0x0002;
        $SetErrorMode->Call($SEM_FAILCRITICALERRORS | $SEM_NOGPFAULTERRORBOX);
    }

    # Set priority just below normal (on Win2K and later)
    {
        my (undef, $major, undef, undef, $id) = Win32::GetOSVersion();
        if ($id == 2 && $major >= 5 && eval { require Win32::Process }) {
            Win32::Process::Open(my $proc, $$, 0);

            # constant not defined by older Win32::Process versions
            my $BELOW_NORMAL_PRIORITY_CLASS = 0x00004000;
            $proc->SetPriorityClass($BELOW_NORMAL_PRIORITY_CLASS);
        }
    }
}

1;

=head1 NAME

Test::Smoke::Util::Win32ErrorMode - Utility function to switch off the error-popup for the current process.

=head1 DESCRIPTION

This patch was provided in
L<RT-39138|https://rt.cpan.org/Ticket/Display.html?id=39138>. The code has
changed quite a bit since then (9 years ago). But it still looked good and sane,
so we decided to give it a place in the code.

=head2 lower_error_settings()

This calls C<kernel32::SetErrorMode> with the flags: C<SEM_FAILCRITICALERRORS>
and C<SEM_NOGPFAULTERRORBOX> to prevent popups during crashes.

It also calls C<< Win32::Process::Open()->SetPriorityClass() >> as a way to
C<renice()> the process.

=head1 COPYRIGHT

(c) MMVIII Jan Dubois <jdb@cpan.org> original patch

(c) MMXVII Abe Timmerman <abeltje@cpan.org> integration into Test::Smoke.

=cut
