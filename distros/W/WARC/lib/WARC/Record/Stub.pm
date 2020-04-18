package WARC::Record::Stub;					# -*- CPerl -*-

use strict;
use warnings;

our @ISA = qw(WARC::Record::FromVolume);

use WARC; *WARC::Record::Stub::VERSION = \$WARC::VERSION;

use Carp;

require WARC::Record::FromVolume;

# This implementation uses a hash as the underlying structure.

# Instances of this class carry only two keys:  volume and offset.

# Other method calls result in loading the full object.

sub new {
  my $class = shift;
  my $volume = shift;
  my $offset = shift;

  croak "unbalanced key/value pairs" if scalar @_ % 2;

  my $ob = {volume => $volume, offset => $offset, @_};

  bless $ob, $class;
}

sub _load_and_forward {
  my $self = shift;
  my $method = shift;

  my $new = _read WARC::Record::FromVolume ($self->volume, $self->offset);

  $self->{$_} = $new->{$_} for keys %$new;
  bless $self, ref $new;

  $self->$method(@_)
}

BEGIN {
  no strict 'refs';
  foreach my $sub (qw/ fields protocol next open_block replay open_payload /)
    { *{$sub} = sub { (shift)->_load_and_forward($sub => @_)} }
}

1;
__END__

=head1 NAME

WARC::Record::Stub - WARC record delayed loading stub

=head1 SYNOPSIS

  use WARC::Record;

=head1 DESCRIPTION

This is an internal class used to delay loading of
C<WARC::Record::FromVolume> objects returned from searching indexes.  All
but the most trivial of accesses to these objects result in loading the
actual record and replacing the object with the full object.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC::Record>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
