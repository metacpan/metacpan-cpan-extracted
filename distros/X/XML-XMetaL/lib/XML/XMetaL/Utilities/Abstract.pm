#! perl

package XML::XMetaL::Utilities::Abstract;

use strict;
use warnings;
use Carp;

require Exporter;

our  @ISA = qw(Exporter);
our  @EXPORT = qw(Abstract);  

our @parameters = qw(package symbol referent attr data phase);

sub abstract {
	my ($self) = @_;
	my $strCallerClass = ref($self);
	my $strAbstractClass = (caller 0)[0];
	my $strMethod = (caller 1)[3];
	$strMethod =~ s/.*::(.*)/$1/;

	if ($strCallerClass eq $strAbstractClass) {
		croak "$strAbstractClass is an abstract base class.".
			  " Attempt to call non-existent method $strMethod";
	} else {
		die "Class $strCallerClass inherited the abstract base class $strAbstractClass ".
			  "but did not redefine the $strMethod method. ".
			  "Attempt to call non-existent method $strAbstractClass::$strMethod";
	}
}

1;