use strict;
package Time::Warp;
use vars qw(@ISA @EXPORT_OK $VERSION);
require Exporter;
require DynaLoader;
@ISA =         qw(DynaLoader Exporter);
@EXPORT_OK   = qw(reset to scale time);
$VERSION     = '0.55';

__PACKAGE__->bootstrap($VERSION);

install_time_api();

1;
__END__

=encoding utf8

=head1 NAME

Time::Warp - control over the flow of time

=head1 SYNOPSIS

    use Time::Warp qw(scale to time);

    to(time + 5);  # 5 seconds ahead
    scale(2);      # make time flow twice normal

=head1 DESCRIPTION

Our external experience unfolds in 3 1/2 dimensions (time has a
dimensionality of 1/2).  The Time::Warp module offers developers
control over the measurement of time.

=head1 API

=over 4

=item * to($desired_time)

The theory of relativity asserts that all physical laws are enforced
relative to the observer.  Since the starting point of time is
arbitrary, it is permissible to change it.  This has the effect of
making it appear as if time is moving forwards or backward
instanteously.  For example, on some types of operating systems time
starts at Wed Dec 31 19:00:00 1969 (this will likely change as we
approach 2030 and with the acceptance of 64-bit CPUs).

  to(time + 60*60);       # 1 hour ahead

=item * scale($factor)

Changes the speed at which time is progressing.

  scale(scale * 2);   # double the speed of time

Note that it is not possible to stop time or cause it to reverse since
this is forbidden by the second law of thermodynamics.

=back

=head1 ALSO SEE

L<Time::HiRes> and L<Event>.

=head1 SUPPORT

Please direct your insights or complaints to perl-loop@perl.org.

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THIS IS NOT A
TIME MACHINE.  THIS MODULE CANNOT BE USED TO VIOLATE THE SECOND LAW OF
THERMODYNAMICS.

=head1 COPYRIGHT

Copyright © 1999, 2000 Joshua Nathaniel Pritikin.  All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
