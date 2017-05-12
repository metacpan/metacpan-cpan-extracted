package ZMQ::Declare::Constants;
{
  $ZMQ::Declare::Constants::VERSION = '0.03';
}

use 5.008001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = ();
our %EXPORT_TAGS = (
  'all' => \@EXPORT_OK,
);

1;
__END__

=head1 NAME

ZMQ::Declare::Constants - Constants you can import

=head1 SYNOPSIS

  use ZMQ::Declare::Constants ...;

=head1 DESCRIPTION

=head1 SEE ALSO

L<ZMQ::Declare>

L<ZeroMQ>

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011,2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
