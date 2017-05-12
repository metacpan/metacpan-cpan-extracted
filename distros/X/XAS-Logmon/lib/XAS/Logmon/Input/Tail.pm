package XAS::Logmon::Input::Tail;

our $VERSION = '0.01';

my $mixin;

BEGIN {
    $mixin = 'XAS::Logmon::Input::Tail::Default';
    $mixin = 'XAS::Logmon::Input::Tail::Linux' if ($^O eq 'linux');
    $mixin = 'XAS::Logmon::Input::Tail::Win32' if ($^O eq 'MSWin32');
}

use Fcntl ':seek';

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  mixin      => $mixin,
  utils      => 'dotid trim',
  accessors  => 'notifier statefile',
  filesystem => 'File',
  vars => {
    PARAMS => {
      -filename => { isa => 'Badger::Filesystem::File' },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _do_tail {
    my $self = shift;

    my $pos = $self->_file_position();
    $self->log->debug("_do_tail - pos = $pos");

    my $fh = $self->filename->open('r');
    $fh->seek($pos, SEEK_SET);

    while (my $line = $fh->getline()) {

        push(@{$self->{'buffer'}}, trim($line));

    }

    $pos = $fh->tell();
    $self->_write_state($pos);

    $fh->close();

    $self->log->debug("_do_tail - pos = $pos");

}

sub _file_position {
    my ($self) = @_;

    my $state;
    my @lines;
    my $pos = 0;
    my @stat = $self->filename->stat;

    if ($self->statefile->exists) {

        @lines = $self->statefile->read;
        foreach my $line (@lines) {

            my ($key, $value) = split('\s*=\s*', $line);
            chop $value;
            $state->{$key} = $value;

        }

        if (($stat[0] eq $state->{'device'}) and
            ($stat[1] eq $state->{'inode'})) {

            $pos = $state->{'position'};

        }

    } else {

        $self->_write_state($pos);

    }

    return $pos;

}

sub _write_state {
    my $self = shift;
    my $pos  = shift;

    my @stat = $self->filename->stat;
    my $fh   = $self->statefile->open('w');

    $fh->printf("inode = %s\n", $stat[1]);
    $fh->printf("device = %s\n", $stat[0]);
    $fh->printf("position = %s\n", $pos);

    $fh->close;

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'buffer'} = [];
    $self->{'statefile'} = File($self->filename->volume, $self->filename->directory, '.' . $self->filename->basename . '.logmon');

    $self->init_notifier();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Logmon::Input::Tail - A class to tail a file 

=head1 SYNOPSIS

 use XAS::Logmon::Input::Tail;

 my $input = XAS::Logmon::Input::Tail->new(
    -filename => File(/home/kesteb/tukwils.lg')
 );
 
 while (my $line = $input->get()) {

 }

=head1 DESCRIPTION

This package tails a file. It will autoload mixins to handle the actual
file tailing. These mixins may be specific to a particular platform.
Housekeeping for file positioning is kept in "state" files. This is to
allow for process restarts.

The assumption is that these are "text" files. Where a specific line
terminator marks the end of the "line".

=head1 METHODS

=head2 get

Returns one line from the tailed file or undef if the file is moved or
deleted.

=head2 init_notifier

Perform the neccessary initializtion for the notifier.

=head1 SEE ALSO

=over 4

=item L<XAS::Logmon::Input::File|XAS::Logmon::Input::File>

=item L<XAS::Logmon::Input::Tail::Default|XAS::Logmon::Input::Tail::Default>

=item L<XAS::Logmon::Input::Tail::Linux|XAS::Logmon::Input::Tail::Linux>

=item L<XAS::Logmon::Input::Tail::Win32|XAS::Logmon::Input::Tail::Win32>

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
