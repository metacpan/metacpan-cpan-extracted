# Unix::Processors::Info
# See copyright, etc in below POD section.
######################################################################

=head1 NAME

Unix::Processors::Info - Interface to processor (CPU) information

=head1 SYNOPSIS

  use Unix::Processors;

  ...
  $aproc = $proc->processors[0];
      print ($aproc->id, $aproc->state, $aproc->clock);
  }

=head1 DESCRIPTION

This package provides access to per-processor (CPU) information from
the operating system in a OS independent manner.

=over 4

=item id

Return the cpu number of this processor.

=item clock

Return the clock frequency in MHz.

=item state

Return the cpu state as "online", "offline", or "poweroff".

=item type

Return the cpu type.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.org/>.

Copyright 1999-2017 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Unix::Processors>

=cut

package Unix::Processors::Info;

require DynaLoader;
@ISA = qw(DynaLoader);

use strict;
use vars qw($VERSION);

######################################################################
#### Configuration Section

$VERSION = '2.046';

######################################################################
#### Code

#It's all in C

######################################################################
#### Package return
1;
