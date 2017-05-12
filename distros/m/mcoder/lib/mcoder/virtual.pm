package mcoder::virtual;

our $VERSION = '0.01';

use strict;
use warnings;

require mcoder;

sub import {
    my $class=shift;
    @_=($class, 'virtual', [@_]);
    goto &mcoder::import
}

1;
__END__

=head1 NAME

mcoder::virtual - Perl extension for virtual method generation

=head1 SYNOPSIS

  use mcoder::virtual qw(runner walker jumper);

=head1 ABSTRACT

create virtual methods that throw and error when called if they have
not been redefined on child classes.

=head1 DESCRIPTION

look at the synopsis!

=head2 EXPORT

the virtual methods defined

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
