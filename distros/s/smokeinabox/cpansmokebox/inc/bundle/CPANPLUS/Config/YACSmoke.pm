package CPANPLUS::Config::YACSmoke;

use strict;
use File::Spec;
use vars qw($VERSION);

$VERSION = '0.58';

sub setup {
  my $conf = shift;
  $conf->set_conf( base => File::Spec->catdir( $ENV{PERL5_YACSMOKE_BASE}, '.cpanplus' ) )
	if $ENV{PERL5_YACSMOKE_BASE};
  return 1;
}

'YACSmoking';

__END__

=head1 NAME

CPANPLUS::Config::YACSmoke - Set the environment for YACSmoking

=head1 SYNOPSIS

  export PERL5_YACSMOKE_BASE=/home/moo/perls/conf/perl-5.8.9/

=head1 DESCRIPTION

CPANPLUS::Config::YACSmoke is a L<CPANPLUS::Config> file that allows the CPAN Tester to
specify where L<CPANPLUS::YACSmoke> and L<CPANPLUS> get their configuration from.

Setting the environment variable C<PERL5_YACSMOKE_BASE> to a path location, determines 
where the C<.cpanplus> directory will be located.

=head1 METHODS

=over

=item C<setup>

Called by L<CPANPLUS::Configure>.

=back

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

Contributions and patience from Jos Boumans the L<CPANPLUS> guy!

=head1 LICENSE

Copyright E<copy> Chris Williams and Jos Boumans.

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<CPANPLUS>

=cut
