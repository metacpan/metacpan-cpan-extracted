package URI::imap;
# $Id: imap.pm,v 1.1 2004/08/07 19:17:46 cwest Exp $
use strict;

use vars qw[$VERSION];
$VERSION = sprintf "%d.%02d", split m/\./, (qw$Revision: 1.1 $)[1];

use base qw[URI::_server];

sub default_port { 143 }

1;

__END__

=head1 NAME

URI::imap - Support IMAP URI

=head1 DESCRIPTION

Support IMAP schemas with L<URI|URI>.

=head1 SEE ALSO

L<URI>.

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2004 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
