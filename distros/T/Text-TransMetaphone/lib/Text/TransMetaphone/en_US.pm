package Text::TransMetaphone::en_US;
use base qw( DynaLoader );

use strict;
use Carp;
use vars qw( $VERSION $LocaleRange );

$VERSION = '0.01';

bootstrap Text::TransMetaphone::en_US $VERSION;

$LocaleRange = qr/\p{InBasicLatin}/;



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Text::TransMetaphone::en_US - Transcribe American English words into IPA symbols.

=head1 SYNOPSIS

This module is used by L<Text::TransMetaphone> and need not be used
directly.

=head1 DESCRIPTION

This module is a simple port of Maurice Aubrey's Text::DoubleMetaphone
module to work under the TransMetaphone premise.

=head1 AUTHOR

Copyright 2000, Maurice Aubrey E<lt>maurice@hevanet.comE<gt>.
All rights reserved.  Modified for IPA symbols by Daniel Yacob.

This code is based heavily on the C++ implementation by
Lawrence Philips, and incorporates several bug fixes courtesy
of Kevin Atkinson E<lt>kevina@users.sourceforge.netE<gt>.

This module is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.  

=head1 STATUS

The module is only partially ported to TransMetaphone.  Only two keys are
returned at this time I<NOT> including a terminal regex key. A "reverse_key"
function has not yet been implemented.

=head1 SEE ALSO

=head2 Man Pages

L<Text::Metaphone>, L<Text::Soundex>

=head2 Additional References

Philips, Lawrence. I<C/C++ Users Journal>, June, 2000.
http://www.cuj.com/articles/2000/0006/0006d/0006d.htm?topic=articles

Philips, Lawrence. I<Computer Language>, Vol. 7, No. 12 (December), 1990.

Kevin Atkinson (author of the Aspell spell checker) maintains
a page dedicated to the Metaphone and Trans Metaphone algorithms at 
<http://aspell.sourceforge.net/metaphone/>

=cut
