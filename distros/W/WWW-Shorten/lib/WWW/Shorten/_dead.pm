package WWW::Shorten::_dead;

use strict;
use warnings;

our $VERSION = '3.093';
$VERSION = eval $VERSION;

die <<'EOF';

This WWW::Shorten service is inactive.
Please use a different one.

EOF

1;

=head1 NAME

WWW::Shorten::_dead - Where dead link-shortening services go

=head1 SYNOPSIS

  # just change your service to look like this:
  package WWW::Shorten::SomeDeadService;
  use strict;
  use warnings;

  our $VERSION = '1.001';
  $VERSION = eval $VERSION;

  # ensure a common error message will be given to the user
  require WWW::Shorten::_dead;

  1;

=head1 DESCRIPTION

This is just a module that we use for link-shortening services that
we used to support but which no longer exist.

=head1 AUTHOR

Iain Truskett <spoon@cpan.org>

=head1 SEE ALSO

L<WWW::Shorten>

=cut
