package Unix::Groups;

use 5.008008;
use strict;
use warnings;

use Exporter qw/import/;

our %EXPORT_TAGS=(all=>[qw/NGROUPS_MAX getgroups setgroups/],);
our @EXPORT_OK=@{$EXPORT_TAGS{all}};

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Unix::Groups', $VERSION);

1;
__END__

=encoding utf8

=head1 NAME

Unix::Groups - Perl to support C<getgroups> and C<setgroups> syscalls

=head1 SYNOPSIS

 use Unix::Groups qw/:all/;

 $ngroups_max=NGROUPS_MAX;
 @gids=getgroups;
 $success=setgroups(@gids);

=head1 DESCRIPTION

This module implements a very thin layer around the L<getgroups(2)> and
L<setgroups(2)> syscalls. See your system manual for more information.

Note, the module is written and tested on Linux. For other UNIX-like systems
there are good chances that it will work at least if it compiles properly.

=head2 Functions

=head3 $n=NGROUPS_MAX

returns the max. number of arguments that C<setgroups> will accept.

=head3 @gids=getgroups

returns the list of supplementary group IDs of the current process.
It is very similar to the C<$(> variable. But C<$(> is a string and
its first element is the current effective GID.

=head3 $success=setgroups @gids

sets the list of supplementary group IDs of the current process.
On most systems this is a privileged operation. On Linux C<CAP_SETGID>
is required.

=head2 EXPORT

None by default.

On demand all functions are exported.

=head3 Export tags

=over 4

=item :all

export all functions.

=back

=head1 SEE ALSO

Linux manual.

=head1 AUTHOR

Torsten Förtsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
