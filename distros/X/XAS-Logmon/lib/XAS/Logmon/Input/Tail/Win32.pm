package XAS::Logmon::Input::Tail::Win32;

our $VERSION = '0.01';

use Win32;
use Win32::ChangeNotify;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  mixins     => 'get init_notifier',
  utils      => 'dotid compress',
  filesystem => 'Dir',
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

        if (defined(my $rc = $self->notifier->wait())) {

            $self->notifier->reset;

            if ($rc > 0) {

                $self->log->debug('processing...');

                unless ($self->filename->exists) {

                    $self->statefile->delete if ($self->statefile->exists);
                    $self->_write_state(0);

                }

                $self->_do_tail();

                if (scalar(@{$self->{'buffer'}})) {

                    return shift @{$self->{'buffer'}};

                }

            } elsif ($rc < 0) {

                $self->throw_msg(
                    dotid($self->class) . '.get.badmutex',
                    'logmon_badmutex',
                );

            }

        } else {

            $self->throw_msg(
                dotid($self->class) . '.get.unknownerror',
                'unknownerror',
                _get_error()
            );

        }

    }

    return undef;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init_notifier {
    my $self = shift;

    my $notifier;
    my $flags = "SIZE LAST_WRITE FILE_NAME";
    my $dir   = Dir($self->filename->volume, $self->filename->directory)->absolute;

    unless (defined($notifier = Win32::ChangeNotify->new($dir, 0, $flags))) {

        $self->throw_msg(
            dotid($self->class) . '.init_notifier',
            'logmon_nonotifier',
            $dir
        );

    }

    $self->{'notifier'} = $notifier;
    $self->notifier->reset;

}

sub _get_error {

    return(compress(Win32::FormatMessage(Win32::GetLastError())));

}

1;

__END__

=head1 NAME

XAS::Logmon::Input::Tail::Win32 - A mixin for Win32 specific file tailing

=head1 DESCRIPTION

This method is autoloaded when running on a Win32 platform. It uses
L<Win32::FileNotify|https://metacpan.org/pod/Win32::FileNotify> to monitor 
the file.

=head2 get

Returns one line from the tailed file or undef if the file is moved or
deleted.

=head2 init_notifier

Initialize Win32::FileNotify and start the file monitoring.

=head1 SEE ALSO

=over 4

=item L<XAS::Logmon::Input::Tail::Default|XAS::Logmon::Input::Tail::Default>

=item L<XAS::Logmon::Input::Tail::Linux|XAS::Logmon::Input::Tail::Linux>

=item L<XAS::Logmon::Input::Tail|XAS::Logmon::Input::Tail>

=item L<XAS::Logmon|XAS::Logmon>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
