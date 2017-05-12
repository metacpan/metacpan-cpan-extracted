package UUID::Random;

require 5.006_001;
use strict;
use warnings;


our $VERSION = '0.04';

sub generate {
  my @chars = ('a'..'f',0..9);
  my @string;
  push(@string, $chars[int(rand(16))]) for(1..32);
  splice(@string,8,0,'-');
  splice(@string,13,0,'-');
  splice(@string,18,0,'-');
  splice(@string,23,0,'-');
  return join('', @string);
}

1;
__END__

=head1 NAME

UUID::Random - Generate random uuid strings

=head1 SYNOPSIS

  use UUID::Random;
  my $uuid = UUID::Random::generate;

=head1 DESCRIPTION

This module generates random uuid strings. It does not satisfy any of the points listed in RFC 4122 (L<http://tools.ietf.org/html/rfc4122>) but the default format.



=head1 SEE ALSO

If you need RFC compliant UUID strings have a look at L<Data::UUID>

=head1 AUTHOR

Moritz Onken, E<lt>onken@houseofdesign.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Moritz Onken

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
