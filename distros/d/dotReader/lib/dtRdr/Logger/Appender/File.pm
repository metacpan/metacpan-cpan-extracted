package dtRdr::Logger::Appender::File;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use dtRdr;

use File::Spec;
use base 'Log::Log4perl::Appender::File';

=head1 NAME

dtRdr::Logger::Appender::File - Log::Log4perl::Appender::File subclass

=head1 SYNOPSIS

=cut


=head2 new

  dtRdr::Logger::Appender::File->new(blahblah);

=cut

sub new {
  my $class = shift;
  (@_ % 2) and croak('odd number of elements in argument list');
  my (%options) = @_;

  # all we needed, but Log::Log4perl::Appender::File doesn't use it's
  # own filename() accessor, so bah
  $options{filename} = dtRdr->user_dir . $options{filename};

  my $self = $class->SUPER::new(%options);

  # while we're at it
  my $time = time;
  $self->log(message =>
    join("\n",
      '',
      "#"x72,
      'BEGIN LOGGING AT ' . scalar(localtime($time)) . " ($time)",
      "#"x72,
      ''
    )
  );
  return($self);
} # end subroutine new definition
########################################################################





=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;
