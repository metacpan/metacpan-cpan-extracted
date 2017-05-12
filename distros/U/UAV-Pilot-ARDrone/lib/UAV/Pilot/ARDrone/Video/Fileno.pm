# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package UAV::Pilot::ARDrone::Video::Fileno;
$UAV::Pilot::ARDrone::Video::Fileno::VERSION = '1.1';
use v5.14;
use warnings;
use Moose;
use namespace::autoclean;
use Fcntl;

extends 'UAV::Pilot::ARDrone::Video';


sub BUILDARGS
{
    my ($class, $args) = @_;
    my $io = $class->_build_io( $args );

    $$args{'_io'} = $io;
    delete $$args{'host'};
    delete $$args{'port'};
    return $args;
}

sub fileno
{
    my ($self, $do_clear_close_on_exec) = @_;
    $do_clear_close_on_exec //= 1;

    my $in = $self->_io;
    my $fd = 'MSWin32' eq $^O
        ? $self->_get_fd_win32( $in, $do_clear_close_on_exec )
        : $self->_get_fd_unixy( $in, $do_clear_close_on_exec );

    return $fd;
}

sub init_event_loop
{
    # Do nothing, successfully
}


sub _get_fd_unixy
{
    my ($self, $in, $do_clear_close_on_exec) = @_;

    if( $do_clear_close_on_exec ) {
        # This code may not compile on Windows, so wrap it in an eval(STRING)
        eval <<'END_EVAL';
            use Fcntl;
            my $flags = fcntl( $in, F_GETFD, 0 )
                or die "fcntl F_GETFD: $!";
            fcntl( $in, F_SETFD, $flags & ~FD_CLOEXEC )
                or die "fcntl F_SETFD: $!";
END_EVAL
        die "Could not set close-on-exec flag: $@\n" if $@;
    }

    return CORE::fileno( $in );
}

sub _get_fd_win32
{
    my ($self, $in, $do_clear_close_on_exec) = @_;
    # No close-on-exec flag for Windows, so ignore it

    # This code won't compile on anything but Windows, so wrap it in 
    # an eval(STRING)
    my $fd = eval <<'END_EVAL';
        use Win32::File 'FdGetOsFHandle';
        FdGetOsFHandle( fileno( $in ) );
END_EVAL
    die "Could not get raw FD: $@\n" if $@;

    return $fd;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::ARDrone::Video::Fileno

=head1 DESCRIPTION

A version of C<UAV::Pilot::ARDrone::Video> that launches an external process 
and hands it a raw filehandle with C<fileno()>.  This is done in a 
cross-platform way.  Note that on Windows, this requires C<Win32::File> to be 
installed.

Since no reading of the video stream is actual done, C<init_event_loop()> is 
a NOP.

=cut
