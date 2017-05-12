package TiVo::HME;

use 5.008;
use strict;
use warnings;
use vars qw(@INC);

our $VERSION = '1.3';

use TiVo::HME::Server;

use POSIX qw(:sys_wait_h setsid);

sub start {
    my($class, $inc_dirs) = @_;
    my $self;

    push @INC, @$inc_dirs if (ref $inc_dirs eq 'ARRAY');

    TiVo::HME::Server->new->start;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

TiVo::HME - Startup server for pure Perl implementation of TiVo's HME protocol

=head1 SYNOPSIS

  use TiVo::HME;
  TiVo::HME->start(<ARRAY REF OF INCLUDE DIRECTORIES]);

=head1 DESCRIPTION

This modules just sets @INC to find your HME apps & then starts up
the server - it will NOT return.  Then point your simulator at
http://localhost/<app name> (assuming you're running the simulator and
this on the same box).
This basically just gets the party started - perldoc TiVo::HME::Application
for how to actually write an HME app.

=head1 SEE ALSO

http://tivohme.sourceforge.net
TiVo::HME::Application

=head1 AUTHOR

Mark Ethan Trostler, E<lt>mark@zzo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Mark Ethan Trostler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
