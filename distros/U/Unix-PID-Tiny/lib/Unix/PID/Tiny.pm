package Unix::PID::Tiny;

use strict;
use warnings;

our $VERSION = '0.95';

sub new {
    my ( $self, $args_hr ) = @_;

    my %DEFAULTS = (
        'keep_open'           => 0,
        'check_proc_open_fds' => 0
    );

    $args_hr ||= {};
    %{$args_hr} = ( %DEFAULTS, %{$args_hr} );
    $args_hr->{'minimum_pid'} = 11 if !exists $args_hr->{'minimum_pid'} || $args_hr->{'minimum_pid'} !~ m{\A\d+\z}ms;    # this does what one assumes m{^\d+$} would do

    if ( defined $args_hr->{'ps_path'} ) {
        $args_hr->{'ps_path'} .= '/' if $args_hr->{'ps_path'} !~ m{/$};
        if ( !-d $args_hr->{'ps_path'} || !-x "$args_hr->{'ps_path'}ps" ) {
            $args_hr->{'ps_path'} = '';
        }
    }
    else {
        $args_hr->{'ps_path'} = '';
    }

    return bless {
        'ps_path'             => $args_hr->{'ps_path'},
        'minimum_pid'         => $args_hr->{'minimum_pid'},
        'keep_open'           => $args_hr->{'keep_open'},
        'check_proc_open_fds' => $args_hr->{'check_proc_open_fds'},
        'open_handles'        => []
    }, $self;
}

sub kill {
    my ( $self, $pid, $give_kill_a_chance ) = @_;
    $give_kill_a_chance = int $give_kill_a_chance if defined $give_kill_a_chance;
    $pid = int $pid;
    my $min = int $self->{'minimum_pid'};
    if ( $pid < $min ) {

        # prevent bad args from killing the process group (IE '0')
        # or general low level ones
        warn "kill() called with integer value less than $min";
        return;
    }

    # CORE::kill 0, $pid : may be false but still running, see `perldoc -f kill`
    if ( $self->is_pid_running($pid) ) {

        # RC from CORE::kill is not a boolean of if the PID was killed or not, only that it was signaled
        # so it is not an indicator of "success" in killing $pid
        _kill( 15, $pid );    # TERM
        _kill( 2,  $pid );    # INT
        _kill( 1,  $pid );    # HUP
        _kill( 9,  $pid );    # KILL

        # give kill() some time to take effect?
        if ($give_kill_a_chance) {
            sleep($give_kill_a_chance);
        }
        return if $self->is_pid_running($pid);
    }
    return 1;
}

sub is_pid_running {
    my ( $self, $check_pid ) = @_;

    $check_pid = int $check_pid;
    return if !$check_pid || $check_pid < 0;

    return 1 if $> == 0 && _kill( 0, $check_pid );    # if we are superuser we can avoid the the system call. For details see `perldoc -f kill`

    # If the proc filesystem is available, it's a good test. If not, continue on to system call
    return 1 if -e "/proc/$$" && -r "/proc/$$" && -r "/proc/$check_pid";

    # even if we are superuser, go ahead and call ps just in case CORE::kill 0's false RC was erroneous
    my @outp = $self->_raw_ps( 'u', '-p', $check_pid );
    chomp @outp;
    return 1 if defined $outp[1];
    return;
}

sub pid_info_hash {
    my ( $self, $pid ) = @_;
    $pid = int $pid;
    return if !$pid || $pid < 0;

    my @outp = $self->_raw_ps( 'u', '-p', $pid );
    chomp @outp;
    my %info;
    @info{ split( /\s+/, $outp[0], 11 ) } = split( /\s+/, $outp[1], 11 );
    return wantarray ? %info : \%info;
}

sub _raw_ps {
    my ( $self, @ps_args ) = @_;
    my $psargs = join( ' ', @ps_args );
    my @res = `$self->{'ps_path'}ps $psargs`;
    return wantarray ? @res : join '', @res;
}

sub get_pid_from_pidfile {
    my ( $self, $pid_file ) = @_;

    # if this function is ever changed to use $self as a hash object, update pid_file() to not do a class method call
    return 0 if !-e $pid_file;

    open my $pid_fh, '<', $pid_file or return;
    chomp( my $pid = <$pid_fh> );
    close $pid_fh;

    return int( abs($pid) );
}

sub _sets_match {
    my ( $left, $right ) = @_;

    my $count = scalar @{$left};

    return 0 unless scalar @{$right} == $count;

    for ( my $i = 0; $i < $count; $i++ ) {
        return 0 unless $left->[$i] eq $right->[$i];
    }

    return 1;
}

sub is_pidfile_running {
    my ( $self, $pid_file, $since ) = @_;
    my $pid = $self->get_pid_from_pidfile($pid_file) || return;

    my @pidfile_st = stat $pid_file or return;

    if ( defined $since ) {
        return if $pidfile_st[9] < $since;
    }

    if ( $self->{'check_proc_open_fds'} ) {
        my $dir   = "/proc/$pid/fd";
        my $found = 0;

        opendir my $dh, $dir or return;

        while ( my $dirent = readdir $dh ) {
            next if $dirent eq '.' || $dirent eq '..';

            my $path = "$dir/$dirent";
            my $dest = readlink $path or next;
            my @st   = stat $dest or next;

            if ( _sets_match( [ @pidfile_st[ 0, 1 ] ], [ @st[ 0, 1 ] ] ) ) {
                $found = 1;

                last;
            }
        }

        closedir $dh;

        return unless $found;
    }
    else {
        return unless $self->is_pid_running($pid);
    }

    return $pid;
}

sub pid_file {
    my ( $self, $pid_file, $newpid, $retry_conf ) = @_;
    $newpid = $$ if !$newpid;

    my $rc = $self->pid_file_no_unlink( $pid_file, $newpid, $retry_conf );
    if ( $rc && $newpid == $$ ) {

        # prevent forked childrens' END from killing parent's pid files
        #   'unlink_end_use_current_pid_only' is undocumented as this may change, feedback welcome!
        #   'carp_unlink_end' undocumented as it is only meant for testing (rt57462, use Test::Carp to test END behavior)
        if ( $self->{'unlink_end_use_current_pid_only'} ) {
            eval 'END { unlink $pid_file if $$ eq ' . $$ . '}';    ## no critic qw(ProhibitStringyEval)
            if ( $self->{'carp_unlink_end'} ) {

                # eval 'END { require Carp;Carp::carp("[info] $$ !unlink $pid_file (current pid check)") if $$ ne ' . $$ . '}'; ## no critic qw(ProhibitStringyEval)
                eval 'END { require Carp;Carp::carp("[info] $$ unlink $pid_file (current pid check)") if $$ eq ' . $$ . '}';    ## no critic qw(ProhibitStringyEval)
            }
        }
        else {
            eval 'END { unlink $pid_file if Unix::PID::Tiny->get_pid_from_pidfile($pid_file) eq $$ }';                          ## no critic qw(ProhibitStringyEval)
            if ( $self->{'carp_unlink_end'} ) {

                # eval 'END { require Carp;Carp::carp("[info] $$ !unlink $pid_file (pid file check)") if Unix::PID::Tiny->get_pid_from_pidfile($pid_file) ne $$ }'; ## no critic qw(ProhibitStringyEval)
                eval 'END { require Carp;Carp::carp("[info] $$ unlink $pid_file (pid file check)") if Unix::PID::Tiny->get_pid_from_pidfile($pid_file) eq $$ }';    ## no critic qw(ProhibitStringyEval)
            }
        }
    }

    return 1 if defined $rc && $rc == 1;
    return 0 if defined $rc && $rc == 0;
    return;
}

no warnings 'once';

# more intuitively named alias
*pid_file_no_cleanup = \&pid_file_no_unlink;
use warnings 'once';

sub pid_file_no_unlink {
    my ( $self, $pid_file, $newpid, $retry_conf ) = @_;
    $newpid = $$ if !$newpid;

    if ( ref($retry_conf) eq 'ARRAY' ) {
        $retry_conf->[0] = int( abs( $retry_conf->[0] ) );
        for my $idx ( 1 .. scalar( @{$retry_conf} ) - 1 ) {
            next if ref $retry_conf->[$idx] eq 'CODE';
            $retry_conf->[$idx] = int( abs( $retry_conf->[$idx] ) );
        }
    }
    elsif ( ref($retry_conf) eq 'HASH' ) {
        $retry_conf->{'num_of_passes'} ||= 3;
        $retry_conf->{'passes_config'} ||= [ 1, 2 ];
        $retry_conf = [ int( $retry_conf->{'num_of_passes'} ), @{ $retry_conf->{'passes_config'} } ];
    }
    else {
        $retry_conf = [ 3, 1, 2 ];
    }

    my $passes = 0;
    require Fcntl;

  EXISTS:
    $passes++;
    if ( -e $pid_file ) {
        my $curpid = $self->get_pid_from_pidfile($pid_file);

        # TODO: narrow even more the race condition where $curpid stops running and a new PID is put in
        # the file between when we pull in $curpid above and check to see if it is running/unlink below

        return 1 if int $curpid == $$ && $newpid == $$;    # already setup
        return if int $curpid == $$;                       # can't change it while $$ is alive
        return if $self->is_pid_running( int $curpid );

        unlink $pid_file;                                  # must be a stale PID file, so try to remove it for sysopen()
    }

    # write only if it does not exist:
    my $pid_fh = _sysopen($pid_file);
    if ( !$pid_fh ) {
        return 0 if $passes >= $retry_conf->[0];
        if ( ref( $retry_conf->[$passes] ) eq 'CODE' ) {
            $retry_conf->[$passes]->( $self, $pid_file, $passes );
        }
        else {
            sleep( $retry_conf->[$passes] ) if $retry_conf->[$passes];
        }
        goto EXISTS;
    }

    syswrite( $pid_fh, int( abs($newpid) ) );

    if ( $self->{'keep_open'} ) {
        push @{ $self->{'open_handles'} }, $pid_fh;
    }
    else {
        close $pid_fh;
    }

    return 1;
}

sub _sysopen {
    my ($pid_file) = @_;
    sysopen( my $pid_fh, $pid_file, Fcntl::O_WRONLY() | Fcntl::O_EXCL() | Fcntl::O_CREAT() ) || return;
    return $pid_fh;
}

sub _kill {    ## no critic(RequireArgUnpacking
    return CORE::kill(@_);    # goto &CORE::kill; is problematic
}

1;

__END__

=encoding utf-8

=head1 NAME

Unix::PID::Tiny - Subset of Unix::PID functionality with smaller memory
footprint

=head1 VERSION

This document describes Unix::PID::Tiny version 0.95.

=head1 SYNOPSIS

    use Unix::PID::Tiny;
    my $pid = Unix::PID::Tiny->new();

    print Dumper( $pid->pid_info_hash( $misc_pid ) );

    if ($pid->is_pid_running($misc_pid)) {
        $pid->kill( $misc_pid ) or die "Could not stop $misc_pid";
    }

=head1 DESCRIPTION

Like Unix::PID but supplies only a few key functions.

=head1 INTERFACE

=head2 new(I<[$args_hr]>)

See L<Unix::PID>'s new().  The following options can be provided in the
optional HASH, I<$args_hr>, to enable certain extensions:

=over

=item B<keep_open>

When a true value is provided, PID files created with pid_file() will remain
open.

=item B<check_proc_open_fds>

When a true value is provided, this option will cause is_pidfile_running() to
traverse C</proc/$pid/fd> to ensure a current file descriptor is held by a
given process for the specified PID file.

This option is only useful when the PID in the pidfile still holds an open
file descriptor to the pid file. I<If it does not then this will always
return false.>

To accomplish this in processes that use C<pid_file()> you must create the
C<Unix::PID::Tiny> object w/ B<keep_open> set to true.

=back

=head2 kill()

See L<Unix::PID>'s kill()

=head2 pid_info_hash()

See L<Unix::PID>'s pid_info_hash()

=head2 is_pid_running(I<$pid_file>, I<[$since]>)

See L<Unix::PID>'s is_pid_running().  The optional argument I<$since> may be
provided, which will cause this function to not return true if the mtime of
I<$pid_file> is earlier than the value provided in I<$since>.

=head2 pid file related

=head3 get_pid_from_pidfile()

See L<Unix::PID>'s get_pid_from_pidfile()

=head3 is_pidfile_running()

See L<Unix::PID>'s is_pidfile_running()

=head3 pid_file()

See L<Unix::PID>'s pid_file()

The  "retry" configuration can also be hash ref w/ the optional keys:

=over 4

=item B<num_of_passes>

This number corresponds to the the array ref version’s “first item”. Defaults to 3.

=item B<passes_config>

This array ref corresponds to the the array ref version’s “additional arguments”. Defaults to [1,2].

=back

=head3 pid_file_no_unlink()

See L<Unix::PID>'s pid_file_no_unlink()

=head3 pid_file_no_cleanup()

Alias of pid_file_no_unlink(). Some folks like this name better.

=head2 _raw_ps()

See L<Unix::PID>'s _raw_ps()

If $self->{'ps_path'} is ever set to anything invalid at any point it is simply not used and 'ps' by itself will be used.

=head1 DIAGNOSTICS

See L<Unix::PID>'s DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Unix::PID::Tiny requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-unix-pid-tiny@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
