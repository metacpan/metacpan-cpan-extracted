# $Id: General.pm,v 1.2 2003/03/22 17:06:17 cwest Exp $
package POEST::Config::General;

=pod

=head1 NAME

POEST::Config::General - Configuration via Config::General

=head1 ABSTRACT

A poest configurator based on Config::General, a file based
configuration.

=head1 DESCRIPTION

The description of the configuration file is explained in
L<Config::General>.  This configuration class conforms to the
specification explained in L<POEST::Config>.

=head2 Example Configuration

  Hostname localhost
  Port 2525
  
  Plugin POEST::Plugin::General
  Plugin POEST::Plugin::Check::Hostname

  RequireHost Yes
  AllowedHost localhost
  AllowedHost example.com

If no configuration file is passed, a list of reasonable default
directories are checked for C<poest.conf>.


 /usr/local/etc
 /usr/local/etc/poest
 /etc/poest
 ./
 ./etc
 ~/
 ~/etc
 ~/.poest

=cut

use strict;
$^W = 1;

use vars qw[$VERSION];
$VERSION = (qw$Revision: 1.2 $)[1];

use Config::General;
use base qw[POEST::Config];
use Carp;

sub new {
	my ($class, %args) = @_;

	ATTEMPT: unless ( $args{ConfigFile} ) {
		my @locations = qw[
			/usr/local/etc
			/usr/local/etc/poest
			/etc/poest
			./
			./etc
			~/
			~/etc
			~/.poest
		];
		
		foreach ( @locations ) {
			if ( -e "$_/poest.conf" && -f _ && -s _ ) {
				$args{ConfigFile} = "$_/poest.conf";
				last ATTEMPT;
			}
		}
	}

	croak 'ConfigFile is empty' unless $args{ConfigFile};

	my $self = { ParseConfig(
		-ConfigFile     => $args{ConfigFile},
		-LowerCaseNames => 1,
	) };
	
	return bless $self, $class;
}

1;

__END__

=pod

=head1 AUTHOR

Casey West, <F<casey@dyndns.org>>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 DynDNS.org

You may distribute this package under the terms of either the GNU
General Public License or the Artistic License, as specified in the Perl
README file, with the exception that it may not be placed on physical
media for distribution without the prior written approval of the author.

THIS PACKAGE IS PROVIDED WITH USEFULNESS IN MIND, BUT WITHOUT GUARANTEE
OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. USE IT AT YOUR
OWN RISK.

For more information, please visit http://opensource.dyndns.org

=head1 SEE ALSO

L<perl>, L<POEST::Server>, L<POEST::Config>, L<Config::General>.

=cut
