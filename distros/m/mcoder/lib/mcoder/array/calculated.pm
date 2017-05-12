package mcoder::array::calculated;

our $VERSION = '0.01';

use strict;
use warnings;

require mcoder;

sub import {
    my $class=shift;
    @_=($class, 'array_calculated', [@_]);
    goto &mcoder::import
}

1;
__END__

=head1 NAME

mcoder::array::calculated - Perl extension for array_calculated method generation

=head1 SYNOPSIS

  use mcoder::array::calculated qw(runners walkers jumpers);
  use mcoder::array::calculated { coders => '_coders' };

  sub _calculate_runners { qw(one two three) }
  sub _calculate_walkers { ... }
  sub _calculate_jumpers { ... }
  sub _calculate_coders { ... }

=head1 ABSTRACT

create get methods to retrieve object attributes that automatically
call a _calculate_* method when the attribute doesn' exist.

=head1 DESCRIPTION

look at the synopsis!

=head2 EXPORT

the get methods defined


=head1 SEE ALSO

L<Class::MethodMaker>

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
