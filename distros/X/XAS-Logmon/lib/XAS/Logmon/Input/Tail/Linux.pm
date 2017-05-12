package XAS::Logmon::Input::Tail::Linux;

our $VERSION = '0.01';

use Linux::Inotify2;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'dotid',
  mutators  => '_in_move _in_modify _in_delete _in_create',
  constant => {
    FMASK => IN_MODIFY | IN_MOVE_SELF | IN_DELETE_SELF,
    DMASK => IN_CREATE | IN_MOVED_FROM | IN_MOVED_TO,
  },
  mixins => 'get init_notifier FMASK DMASK _in_move _in_modify _in_delete
             _in_create _set_watchers _set_file_watcher _set_dir_watcher',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub get {
    my $self = shift;

    if (scalar(@{$self->{'buffer'}})){

        $self->log->debug('processing...');

        return shift @{$self->{'buffer'}};

    } else {

        $self->log->debug('waiting...');

        while (my $count = $self->notifier->poll()) {

            $self->log->debug('processing...');

            last if ($self->_in_delete);
            last if ($self->_in_move);

            next if ($self->_in_create);

            if ($self->_in_modify) {

                if (scalar(@{$self->{'buffer'}})) {

                    return shift @{$self->{'buffer'}};
 
                }

            }

        }

    }

    return undef;

}

sub init_notifier {
    my $self = shift;

    $self->_in_move(0);
    $self->_in_modify(0);
    $self->_in_delete(0);
    $self->_in_create(0);

    $self->{'notifier'} = Linux::Inotify2->new() or
        $self->throw_msg(
            dotid($self->class) . '.inotify',
            'logmon_notifier',
            $!
        );

    $self->_set_watchers();

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _set_watchers {
    my $self = shift;

    $self->_set_file_watcher;
    $self->_set_dir_watcher;

}

sub _set_file_watcher {
    my $self = shift;

    $self->notifier->watch(
        $self->filename->path,
        FMASK,
        sub {
            my $event = shift;

            $self->_in_move(0);
            $self->_in_modify(0);
            $self->_in_delete(0);
            $self->_in_create(0);

            if ($event->IN_MODIFY) {

                $self->log->debug('IN_MODIFY');
                $self->_in_modify(1);
                $self->_do_tail();

            }

            if ($event->IN_DELETE_SELF) {

                $self->log->debug('IN_DELETE_SELF');

                $event->w->cancel;
                $self->_in_delete(1);
                $self->statefile->delete if ($self->statefile->exists);

            }

        }
    );

}

sub _set_dir_watcher {
    my $self = shift;

    $self->notifier->watch(
        $self->filename->directory,
        DMASK,
        sub {
            my $event = shift;

            $self->_in_move(0);
            $self->_in_modify(0);
            $self->_in_delete(0);
            $self->_in_create(0);

            if ($event->IN_MOVED_FROM &&
                ($event->fullname eq $self->filename->path)) {

                $self->log->debug('IN_MOVED_FROM');

                $event->w->cancel;
                $self->_in_move(1);
                $self->statefile->delete if ($self->statefile->exists);

            }

            if ($event->IN_MOVED_TO &&
                ($event->fullname eq $self->filename->path)) {

                $self->log->debug('IN_MOVED_TO');

                $self->_write_state(0);
                $self->_set_file_watcher;
                $self->_in_create(1);

            }

            if ($event->IN_CREATE &&
                ($event->fullname eq $self->filename->path)) {

                $self->log->debug('IN_CREATE');  

                $self->_write_state(0);
                $self->_set_file_watcher;
                $self->_in_create(1);

            }

        }
    );

}

1;

__END__

=head1 NAME

XAS::Logmon::Input::Tail::Linux - A mixin for Linux specific file tailing

=head1 DESCRIPTION

This method is autoloaded when running on a Linux platform. It uses
L<Linux::Inotify2|https://metacpan.org/pod/Linux::Inotify2> to monitor 
the file.

=head1 METHODS

=head2 get

Returns one line from the tailed file or undef if the file is moved or
deleted.

=head2 init_notifier

Initialize Linux::Inotify2 and start the file monitoring.

=head1 SEE ALSO

=over 4

=item L<XAS::Logmon::Input::Tail::Default|XAS::Logmon::Input::Tail::Default>

=item L<XAS::Logmon::Input::Tail::Win32|XAS::Logmon::Input::Tail::Win32>

=item L<XAS::Logmon::Input::Tail|XAS::Logmon::Input::Tail>

=item L<XAS::Logmon|XAS::Logmon>

=item L<XAS|XAS>

=back

Based on code from L<File::Tail::Inotify2|https://metacpan.org/pod/File::Tail::Inotify2>.

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
