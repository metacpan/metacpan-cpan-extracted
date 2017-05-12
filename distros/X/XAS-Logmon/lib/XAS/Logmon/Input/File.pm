package XAS::Logmon::Input::File;

our $VERSION = '0.01';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'fh',
  vars => {
    PARAMS => {
      -filename => { isa => 'Badger::Filesystem::File' },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub get {
    my $self = shift;

    return $self->fh->getline();

}

sub DESTROY {
    my $self = shift;

    $self->fh->close();

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'fh'} = $self->filename->open('r');

    return $self;

}

1;

__END__

=head1 NAME

XAS::Logmon::Input::File - A class to read log files.

=head1 SYNOPSIS

 use XAS::Logmon::Input::File;

 my $input = XAS::Logmon::Input::File->new(
    -filename = File('/home/kesteb/tukwils.lg')
 );
 
 while (my $line = $input->get()) {
    
    
 }
 
=head1 DESCRIPTION

This method will read the entire contents of a file.

=head1 METHODS

=head2 get

This method will return a line from the file.

=head1 SEE ALSO

=over 4

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
