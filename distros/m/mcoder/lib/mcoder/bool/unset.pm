package mcoder::bool::unset;

our $VERSION = '0.01';

use strict;
use warnings;

require mcoder;

sub import {
    my $class=shift;
    @_=($class, 'bool_unset', [@_]);
    goto &mcoder::import
}

1;
__END__

=head1 NAME

mcoder::bool::unset - Perl extension for unset methods generation

=head1 SYNOPSIS

  use mcoder::bool::unset qw(good tall);
  # is equivalent to...
  # sub unset_runner { $_[0]->{good}=undef };
  # sub unset_walker { $_[0]->{tall}=undef };

  use mcoder::bool::unset { coder => '_coder' };
  # sub unset_coder { $_[0]->{_coder}=undef };

=head1 ABSTRACT

create set methods to change object attributes

=head1 DESCRIPTION

look at the synopsis!

=head2 EXPORT

the set methods defined


=head1 SEE ALSO

L<Class::MethodMaker>

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
