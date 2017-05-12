package ZMQ::Declare::ZDCF::Encoder::Storable;
{
  $ZMQ::Declare::ZDCF::Encoder::Storable::VERSION = '0.03';
}
use 5.008001;
use Moose;

use parent 'ZMQ::Declare::ZDCF::Encoder';

use Storable qw(nfreeze thaw);

sub encode {
  my $self = shift;
  return \(nfreeze(shift));
}

sub decode {
  my $self = shift;
  return thaw(${shift()});
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

ZMQ::Declare::ZDCF::Encoder::Storable - ZDCF Storable encoder

=head1 SYNOPSIS

  use ZMQ::Declare;

=head1 DESCRIPTION

Inherits from 
L<ZMQ::Declare::ZDCF::Encoder>.

Implements a Storable encoder/decoder. Use the JSON encoder instead unless
you absolutely require Storable.

=head1 SEE ALSO

The ZDCF RFC L<http://rfc.zeromq.org/spec:5>

L<ZMQ::Declare::ZDCF>

L<ZMQ::Declare::ZDCF::Encoder>,
L<ZMQ::Declare::ZDCF::Encoder::JSON>

L<ZeroMQ>

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
