package ZMQ::Declare::ZDCF::Encoder::DumpEval;
{
  $ZMQ::Declare::ZDCF::Encoder::DumpEval::VERSION = '0.03';
}
use 5.008001;
use Moose;

use parent 'ZMQ::Declare::ZDCF::Encoder';

use Data::Dumper qw(Dumper);

sub encode {
  my $self = shift;
  return \(Dumper(shift));
}

sub decode {
  my $self = shift;
  my $textref = shift;
  my $out;
  SCOPE: {
    no strict 'vars';
    $out = eval $$textref;
  }
  return $out;
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

ZMQ::Declare::ZDCF::Encoder::DumpEval - ZDCF Data::Dumper encoder

=head1 SYNOPSIS

  use ZMQ::Declare;

=head1 DESCRIPTION

Inherits from 
L<ZMQ::Declare::ZDCF::Encoder>.

Implements an encoder/decoder using Data::Dumper and eval.
Prefer the JSON encoder unless you have no choice -- this one can execute
arbitrary input code thanks to the eval.

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
