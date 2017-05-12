package XAS::Lib::Lockmgr::Nolock;

our $VERSION = '0.01';

use Try::Tiny;
use XAS::Constants 'TRUE FALSE HASHREF';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'host port timeout attempts mutex',
  vars => {
    PARAMS => {
      -key  => 1,
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

        $stat = TRUE;

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

        $stat = TRUE;

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

        $stat = TRUE;

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

sub destroy {
    my $self = shift;
    
}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr::Nolock - Use no locking at all.

=head1 SYNOPSIS

 use XAS::Lib::Lockmgr;

 my $key = '/var/lock/xas/alerts';
 my $lockmgr = XAS::Lib::Lockmgr->new();

 $lockmgr->add(
     -key    => $key,
     -driver => 'Nolock',
 );

 if ($lockmgr->try_lock($key)) {

     $lockmgr->lock($key);

     ...

     $lockmgr->unlock($key);

 }

=head1 DESCRIPTION

This class uses nothing to manage locks. This is a placeholder and allows
for fake discretionary locking of resources.

=head1 CONFIGURATION

This module uses the following fields in -args.

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
