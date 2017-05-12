package mcoder::bool::set;

our $VERSION = '0.01';

use strict;
use warnings;

require mcoder;

sub import {
    my $class=shift;
    @_=($class, 'bool_set', [@_]);
    goto &mcoder::import
}

1;
__END__

=head1 NAME

mcoder::bool::set - Perl extension for set methods generation

=head1 SYNOPSIS

  use mcoder::bool::set qw(good bad);
  # is equivalent to...
  # sub set_runner { $_[0]->{good}=1 };
  # sub set_walker { $_[0]->{bad}=1 };

  use mcoder::bool::set { coder => '_coder' };
  # sub set_coder { $_[0]->{_coder}=1 };

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
