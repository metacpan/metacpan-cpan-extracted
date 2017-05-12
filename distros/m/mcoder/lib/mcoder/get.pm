package mcoder::get;

our $VERSION = '0.02';

use strict;
use warnings;

require mcoder;

sub import {
    my $class=shift;
    @_=($class, 'get', [@_]);
    goto &mcoder::import
}

1;
__END__

=head1 NAME

mcoder::get - Perl extension for get methods generation

=head1 SYNOPSIS

  use mcoder::get qw(runner walker jumper);
  # is equivalent to...
  # sub runner { $_[0]->{runner} };
  # sub walker { $_[0]->{walker} };
  # sub jumper { $_[0]->{jumper} };

  use mcoder::get { coder => '_coder' };
  # sub coder { $_[0]->{_coder} };

=head1 ABSTRACT

create get methods to retrieve object attributes

=head1 DESCRIPTION

look at the synopsis!

=head2 EXPORT

the get methods defined


=head1 SEE ALSO

L<Class::MethodMaker>

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
