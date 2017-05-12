package mcoder::array::get;

our $VERSION = '0.01';

use strict;
use warnings;

require mcoder;

sub import {
    my $class=shift;
    @_=($class, 'array_get', [@_]);
    goto &mcoder::import
}

1;
__END__

=head1 NAME

mcoder::array::get - Perl extension for array_get method generation

=head1 SYNOPSIS

  use mcoder::array::get qw(runners walkers jumpers);
  use mcoder::array::get { coders => '_coders' };

  my @coders = $this->coders;

=head1 ABSTRACT

create get methods to retrieve object array attributes.

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
