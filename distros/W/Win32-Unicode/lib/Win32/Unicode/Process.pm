package Win32::Unicode::Process;

use strict;
use warnings;
use 5.008003;
use Carp ();
use Exporter 'import';

use Win32::Unicode::Util;
use Win32::Unicode::Constant;
use Win32::Unicode::XS;

# export subs
our @EXPORT    = qw/systemW execW/;
our @EXPORT_OK = qw//;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

our $VERSION = '0.38';

# cmd path
my $SHELL = do {
    my $path = catfile($ENV{ComSpec} || 'C:/WINDOWS/system32/cmd.exe');
    utf8_to_utf16($path) . NULL;
};

sub systemW {
    my $pi = _create_process(@_) or return 1;
    close_handle($pi->{thread_handle});
    wait_for_input_idle($pi->{process_handle});
    wait_for_single_object($pi->{process_handle});
    my $exit_code = get_exit_code($pi->{process_handle});
    close_handle($pi->{process_handle});

    return defined $exit_code ? $exit_code : 1;
}

sub execW {
    my $pi = _create_process(@_) or return 1;
    close_handle($pi->{thread_handle});
    close_handle($pi->{process_handle});

    return 0;
}

sub _create_process {
    my $cmd = shift || return;
    my @args;
    for (@_) {
        my $arg = $_;
        $arg =~ s/^"|"$//g;     # trim qquote
        $arg =~ s/"/\"/g;       # escape qquote
        push @args, qq{"$arg"};
    }

    $cmd = utf8_to_utf16("/x /c $cmd " . join q{ }, @args) . NULL; # mybe security hole :-(

    return create_process($SHELL, $cmd);
}

1;

__END__
=head1 NAME

Win32::Unicode::Process - manipulate processes.

=head1 SYNOPSIS

  use Win32::Unicode::Process;

  systemW "echo $flagged_utf8_string";
  systemW 'perl', '-e', 'print "ok"';

  execW "echo $flagged_utf8_string";
  execW 'perl', '-e', 'print "ok"';

=head1 DESCRIPTION

B<THIS MODULE IS ALPHA LEVEL AND MANY BUGS>.

Win32::Unicode::Process is Unicode friendly manipulate process.
But always use the SHELL.
That could become a security hole.

=head1 FUNCTIONS

=over

=item B<systemW>

like CORE::system.

  systemW "echo $flagged_utf8_string";
  systemW 'perl', '-e', 'print "ok"';

=item B<execW>

like CORE::exec

  execW "echo $flagged_utf8_string";
  execW 'perl', '-e', 'print "ok"';

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@cpan.orgE<gt>

=head1 SEE ALSO

L<Win32::Process>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
