package mcoder::array::set;

our $VERSION = '0.01';

use strict;
use warnings;

require mcoder;

sub import {
    my $class=shift;
    @_=($class, 'array_set', [@_]);
    goto &mcoder::import
}

1;
__END__

=head1 NAME

mcoder::array::set - Perl extension for array_set method generation

=head1 SYNOPSIS

  use mcoder::array::set qw(runners walkers jumpers);
  use mcoder::array::set { coders => '_coders' };

  $this->set_coders(qw(foo bar me));

=head1 ABSTRACT

create set methods for array attributes.

=head1 DESCRIPTION

look at the synopsis!

=head2 EXPORT

the set methods defined

=head1 SEE ALSO

L<Class::MethodMaker>

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
