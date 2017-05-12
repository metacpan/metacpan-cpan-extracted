=head1 NAME








Telephone::Mnemonic::Phone - Abstract Telephone Object

=cut
package Telephone::Mnemonic::Phone;
use strict;
use warnings;
use Data::Dumper;
use Moose;
use namespace::autoclean;

use 5.010000;
our $VERSION   = '0.07';

 #requires 'sound';

has 'num'      => (is =>'rw');


#sub pretty { confess "you should implement beautify\n" };
#

no Moose;
__PACKAGE__->meta->make_immutable;

1;
=pod

=head1 SYNOPSIS

 Not intended to be used directly

=head1 DESCRIPTION

=head2 Abstract Telephone Object


=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Tie::Dict>

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Ioannis Tambouras E<lt>ioannis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
