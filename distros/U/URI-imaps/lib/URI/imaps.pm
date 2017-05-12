package URI::imaps;

use strict;

use vars qw[$VERSION];
$VERSION = "1.03";

use base qw[URI::_server];

sub default_port { 993 }

sub secure { 1 }

1;

__END__

=head1 NAME

URI::imaps - Support IMAPS URI

=head1 DESCRIPTION

Support IMAPS schemas with L<URI|URI>.

=head1 SEE ALSO

L<URI>.

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2004,2012 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
