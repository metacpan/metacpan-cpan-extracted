package XAS::Lib::Lockmgr::KeyedMutex;

our $VERSION = '0.01';

use Try::Tiny;
use KeyedMutex;
use XAS::Constants 'TRUE FALSE HASHREF';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'host port timeout attempts mutex',
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

    my $count = 0;
    my $stat  = TRUE;
    my $key   = $self->key;

    try {

        while (! $self->mutex->lock($key)) {

            $count++;

            if ($count < $self->attempts) {

                sleep int(rand($self->timeout));

            } else {

                $stat = FALSE;
                last;

            }

        }

    } catch {

        my $ex = $_;
        my $msg = (ref($ex) eq 'Badger::Exception') ? $ex->info : $ex;

        $self->throw_msg(
            dotid($self->class) . '.lock',
            'lock_error',
            $key, $msg
        );

    };

    return $stat;

}

sub unlock {
    my $self = shift;

    my $stat = FALSE;
    my $key  = $self->key;

    try {

        $stat = $self->mutex->release($key);

    } catch {

        my $ex = $_;
        my $msg = (ref($ex) eq 'Badger::Exception') ? $ex->info : $ex;

        $self->throw_msg(
            dotid($self->class) . '.unlock',
            'lock_error',
            $key, $msg
        );

    };

    return $stat;

}

sub try_lock {
    my $self = shift;

    my $stat = FALSE;
    my $key  = $self->key;

    try {

        $stat = $self->mutex->locked($key) ? FALSE : TRUE;

    } catch {

        my $ex = $_;
        my $msg = (ref($ex) eq 'Badger::Exception') ? $ex->info : $ex;

        $self->throw_msg(
            dotid($self->class) . '.try_lock',
            'lock_error',
            $key, $msg
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

    my $self = $class->SUPER::init(@_);

    $self->{'host'} = defined($self->args->{'host'})
                        ? $self->args->{'host'}
                        : '127.0.0.1';

    $self->{'port'} = defined($self->args->{'port'})
                        ? $self->args->{'port'}
                        : '9507';

    $self->{'timeout'} = defined($self->args->{'timeout'})
                            ? $self->args->{'timeout'}
                            : 30;

    $self->{'attempts'} = defined($self->args->{'attempts'})
                            ? $self->args->{'attempts'}
                            : 30;

    $self->{'mutex'} = KeyedMutex->new({
        sock => $self->host . ':' . $self->port,
    });

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr::KeyedMutex - Use the keymutexd lock manager for locking.

=head1 SYNOPSIS

 use XAS::Lib::Lockmgr;

 my $key = '/var/lock/wpm/alerts';
 my $lockmgr = XAS::Lib::Lockmgr->new();

 $lockmgr->add(
     -key    => $key,
     -driver => 'KeyedMutex',
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

This class uses the keymutexd daemon to manage locks. This leverages the
atomicity of using a centralized lock manager and allows for discretionary
locking of resources.

=head1 CONFIGURATION

This module uses the following fields in -args.

=over 4

=item B<attempts>

The number of attempts to aquire the lock. The default is 30.

=item B<timeout>

The number of seconds to wait between lock attempts. The default is 30.

=item B<host>

The address of the host that is presenting the lock daemon. Defaults to 
127.0.0.1.

=item B<port>

The port that the lock daemon is listening on. Defaults to 9507.

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

=item L<KeyedMutex|https://metacpan.org/pod/KeyedMutex>

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
