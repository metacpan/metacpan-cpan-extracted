package XAS::Lib::Lockmgr::Flom;

our $VERSION = '0.01';

use Flom;
use Try::Tiny;
use XAS::Constants 'TRUE FALSE HASHREF';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'handle host port timeout attempts',
  utils     => 'dotid',
  vars => {
    PARAMS => {
      -key      => 1,
      -args => { optional => 1, type => HASHREF, default => {} },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub lock {
    my $self = shift;

    my $rc;
    my $timeout;
    my $count  = 0;
    my $stat   = FALSE;
    my $handle = $self->handle;

    try {

        if (($rc = Flom::handle_set_lock_mode($handle, Flom::LOCK_MODE_EX)) != Flom::RC_OK) {

            die Flom::strerror($rc);

        }

        while (($rc = Flom::handle_lock($handle)) != Flom::RC_OK) {

            $count += 1;
            $timeout = int(rand($self->timeout)) * 1000; # convert to milliseconds

            if (($rc = Flom::handle_set_resource_timeout($handle, $timeout)) != Flom::RC_OK) {

                die Flom::strerror($rc);

            }

            next if ($count < $self->attempts);
            die Flom::strerror($rc);

        }

        $stat = TRUE;

    } catch {

        my $ex = $_;
        my $msg = (ref($ex) eq 'Badger::Exception') ? $ex->info : $ex;

        $self->throw_msg(
            dotid($self->class) . '.lock',
            'lock_error',
            $self->key, $msg
        );

    };

    return $stat;

}

sub unlock {
    my $self = shift;

    my $rc;
    my $stat   = FALSE;
    my $handle = $self->handle;

    try {

        if (($rc = Flom::handle_unlock($handle)) != Flom::RC_OK) {

            die Flom::strerror($rc);

        }

        if (($rc = Flom::handle_set_lock_mode($handle, Flom::LOCK_MODE_NL)) != Flom::RC_OK) {

            die Flom::strerror($rc)

        }

        $stat = TRUE;

    } catch {

        my $ex = $_;
        my $msg = (ref($ex) eq 'Badger::Exception') ? $ex->info : $ex;

        $self->throw_msg(
            dotid($self->class) . '.unlock',
            'lock_error',
            $self->key, $msg
        );

    };

    return $stat;

}

sub try_lock {
    my $self = shift;

    my $rc;
    my $stat   = FALSE;
    my $handle = $self->handle;

    try {

        if (($rc = Flom::handle_set_lock_mode($handle, Flom::LOCK_MODE_NL)) != Flom::RC_OK) {

            die Flom::strerror($rc);

        }

        if (($rc = Flom::handle_lock($handle)) != Flom::RC_OK) {

            die Flom::strerror($rc);

        }

        if (($rc = Flom::handle_unlock($handle)) != Flom::RC_OK) {

            die Flom::strerror($rc);

        }

        $stat = TRUE;

    } catch {

        my $ex = $_;
        my $msg = (ref($ex) eq 'Badger::Exception') ? $ex->info : $ex;

        $self->throw_msg(
            dotid($self->class) . '.try_lock',
            'lock_error',
            $self->key, $msg
        );

    };

    return $stat;

}

sub exceptions {
    my $self = shift;

    my @exceptions = ();

    return \@exceptions;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $rc;
    my $key;
    my $host;
    my $port;
    my $handle;
    my $self = $class->SUPER::init(@_);

    $handle = Flom::flom_handle_t->new();

    $self->{'timeout'} = defined($self->args->{'timeout'})
                            ? $self->args->{'timeout'}
                            : 30;

    $self->{'attempts'} = defined($self->args->{'attempts'})
                            ? $self->args->{'attempts'}
                            : 30;

    $self->{'host'} = defined($self->args->{'host'})
                        ? $self->args->{'host'}
                        : '127.0.0.1';

    $self->{'port'} = defined($self->args->{'port'})
                        ? $self->args->{'port'}
                        : '28015';

    if (($rc = Flom::handle_init($handle)) != Flom::RC_OK) {

        $self->throw_msg(
            dotid($self->class) . 'init',
            'lock_error',
            $self->key, Flom::strerror($rc)
        );

    }

    $key = $self->key;

    if (($rc = Flom::handle_set_resource_name($handle, $key)) != Flom::RC_OK) {

        $self->throw_msg(
            dotid($self->class) . 'init',
            'lock_error',
            $self->key, Flom::strerror($rc)
        );

    }

    $host = $self->host;

    if (($rc = Flom::handle_set_unicast_address($handle, $host)) != Flom::RC_OK) {

        $self->throw_msg(
            dotid($self->class) . 'init',
            'lock_error',
            $self->key, Flom::strerror($rc)
        );

    }

    $port = $self->port;

    if (($rc = Flom::handle_set_unicast_port($handle, $port)) != Flom::RC_OK) {

        $self->throw_msg(
            dotid($self->class) . 'init',
            'lock_error',
            $self->key, Flom::strerror($rc)
        );

    }

    if (($rc = Flom::handle_set_lock_mode($handle, Flom::LOCK_MODE_NL)) != Flom::RC_OK) {

        $self->throw_msg(
            dotid($self->class) . 'init',
            'lock_error',
            $self->key, Flom::strerror($rc)
        );

    }

    $self->{'handle'} = $handle;
    
    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr::Flom - Use the FLoM lock manager for locking.

=head1 SYNOPSIS

 use XAS::Lib::Lockmgr;

 my $key = '/var/lock/wpm/alerts';
 my $lockmgr = XAS::Lib::Lockmgr->new();

 $lockmgr->add(
     -key    => $key,
     -driver => 'Flom',
     -args => {
        port     => 9506,
        address  => '127.0.0.1',
        timeout  => 10,
        attempts => 10,
     }
 );

 if ($lockmgr->try_lock($key)) {

     $lockmgr->lock($key);

     ...

     $lockmgr->unlock($key);

 }

=head1 DESCRIPTION

This class uses the FLoM distributed lock manager to manage locks. This 
leverages the atomicity of using a centralized lock manager and allows for 
discretionary locking of resources.

=head1 CONFIGURATION

This module uses the following fields in -args.

=over 4

=item B<attempts>

The number of attempts to aquire the lock. The default is 30.

=item B<timeout>

The number of seconds to wait between lock attempts. The default is 30.

=item B<host>

The address of the host that is presenting the lock daemon. Defaults to 127.0.0.1.

=item B<port>

The port that the lock daemon is listening on. Defaults to 28015.

=back

=head1 METHODS

=head2 lock

Attempt to aquire a lock. Returns TRUE for success, FALSE otherwise.

=head2 unlock

Remove the lock. Returns TRUE for success, FALSE otherwise.

=head2 try_lock

Check to see if a lock could be aquired. Returns FALSE if not,
TRUE otherwise.

=head2 exceptions

Returns the exceptions that you may not want to continue lock attemtps if
triggered.

=head1 SEE ALSO

=over 4

=item L<FLoM|https://sourceforge.net/projects/flom/>

=item L<XAS::Lib::Lockmgr|XAS::Lib::Lockmgr>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
