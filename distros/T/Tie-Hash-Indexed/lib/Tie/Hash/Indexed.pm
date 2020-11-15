################################################################################
# 
# Copyright (c) 2002-2016 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# 
################################################################################

package Tie::Hash::Indexed;
use 5.004;
use strict;
use DynaLoader;
use Tie::Hash;
use vars qw($VERSION @ISA);

@ISA = qw(DynaLoader Tie::Hash);
$VERSION = '0.06';

bootstrap Tie::Hash::Indexed $VERSION;

1;

__END__

=head1 NAME

Tie::Hash::Indexed - Ordered hashes for Perl

=head1 SYNOPSIS

  use Tie::Hash::Indexed;

  tie my %hash, 'Tie::Hash::Indexed';

  %hash = ( I => 1, n => 2, d => 3, e => 4 );
  $hash{x} = 5;

  print keys %hash, "\n";    # prints 'Index'
  print values %hash, "\n";  # prints '12345'

=head1 DESCRIPTION

Tie::Hash::Indexed is very similar to Tie::IxHash. However,
it is written completely in XS and usually about twice as
fast as Tie::IxHash. It's quite a lot faster when it comes
to clearing or deleting entries from large hashes.
Currently, only the plain tying mechanism is supported.

=head1 ENVIRONMENT

=head2 C<THI_DEBUG_OPT>

If Tie::Hash::Indexed is built with debugging support, you
can use this environment variable to specify debugging
options. Currently, the only useful values you can pass
in are C<d> or C<all>, which both enable debug output for
the module.

=head1 PROBLEMS

As the data of Tie::Hash::Indexed objects is hidden inside
the XS implementation, cloning/serialization is problematic.
Tie::Hash::Indexed implements hooks for Storable, so cloning
or serializing objects using Storable is safe.

Tie::Hash::Indexed tries very hard to detect any corruption
in its data at runtime. So if something goes wrong, you'll
most probably receive an appropriate error message.

=head1 BUGS

If you find any bugs, Tie::Hash::Indexed doesn't seem to
build on your system or any of its tests fail, please use
the CPAN Request Tracker at L<http://rt.cpan.org/> to create
a ticket for the module. Alternatively, just send a mail
to E<lt>mhx@cpan.orgE<gt>.

=head1 TODO

If you're interested in what I currently plan to improve
(or fix), have a look at the F<TODO> file.

=head1 COPYRIGHT

Copyright (c) 2003-2016 Marcus Holland-Moritz. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

See L<perltie> and L<Tie::IxHash>.

=cut

