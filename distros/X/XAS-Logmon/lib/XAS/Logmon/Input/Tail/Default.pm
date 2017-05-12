package XAS::Logmon::Input::Tail::Default;

our $VERSION = '0.01';

use Fcntl ':seek';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  mixins  => 'get init_notifier',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub get {
    my $self = shift;

    if (scalar(@{$self->{'buffer'}})){

        return shift @{$self->{'buffer'}};

    } else {

        while ($self->filename->exists) {

            $self->log->debug('processing...');
            
            my $pos  = $self->_file_position();
            my $size = ($self->filename->stat)[7];

            if ($pos < $size) {

                $self->_do_tail();

                if (scalar(@{$self->{'buffer'}})) {

                    return shift @{$self->{'buffer'}};
 
                }

            }

            $self->log->debug('waiting...');

            sleep(60);

        }

    }

    return undef;

}

sub init_notifier{
    my $self = shift;

    $self->log->debug('loading Tail::Default');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Logmon::Input::Tail::Default - The default mixin class for tailing files.

=head1 SYNOPSIS

 use XAS::Logmon::Input::Tail;
 
 my $input = XAS::Logmon::Input::Tail->new(
    -filename => File('/home/kesteb/tukwils.lg')
 );

 while (my $line = $input->get()) {
    
 }
 
=head1 DESCRIPTION

This package provides a default mixin for tailing files. It uses a fairly
simplestic method for tailing files. 

=head1 METHODS

=head2 get

Returns one line from the tailed file or undef if the file is moved or
deleted.

=head1 SEE ALSO

=over 4

=item L<XAS::Logmon::Input::Tail::Linux|XAS::Logmon::Input::Tail::Linux>

=item L<XAS::Logmon::Input::Tail::Win32|XAS::Logmon::Input::Tail::Win32>

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
