#line 1
package Module::Package::Dist::RDF;

use 5.008003;
BEGIN {
	$Module::Package::Dist::RDF::AUTHORITY = 'cpan:TOBYINK';
	$Module::Package::Dist::RDF::VERSION   = '0.005';
}

package Module::Package::Dist::RDF::standard;

use 5.008003;
use strict;
use base qw[Module::Package::Dist];
BEGIN {
	$Module::Package::Dist::RDF::standard::AUTHORITY = 'cpan:TOBYINK';
	$Module::Package::Dist::RDF::standard::VERSION   = '0.005';
}

sub _main
{
	my ($self) = @_;
	$self->mi->trust_meta_yml;
	$self->mi->auto_install;
}

1;
