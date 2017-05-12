package ZMQ::Declare::ZDCF::Encoder::JSON;
{
  $ZMQ::Declare::ZDCF::Encoder::JSON::VERSION = '0.03';
}
use 5.008001;
use Moose;

use parent 'ZMQ::Declare::ZDCF::Encoder';

use JSON ();

my $json = JSON->new;
$json->utf8(1);
$json->pretty(1);

sub encode {
  my $self = shift;
  return \($json->encode(shift));
}

sub decode {
  my $self = shift;
  return $json->decode(${shift()});
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

ZMQ::Declare::ZDCF::Encoder::JSON - ZDCF JSON encoder

=head1 SYNOPSIS

  use ZMQ::Declare;

=head1 DESCRIPTION

Inherits from 
L<ZMQ::Declare::ZDCF::Encoder>.

Implements a JSON encoder/decoder.

=head1 SEE ALSO

The ZDCF RFC L<http://rfc.zeromq.org/spec:5>

L<ZMQ::Declare::ZDCF>

L<ZMQ::Declare::ZDCF::Encoder>

L<ZeroMQ>

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
