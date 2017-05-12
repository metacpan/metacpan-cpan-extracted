###########################################################################
### Trinket::DataType
###
### Default object datatype handler
###
### $Id: Object.pm,v 1.3 2001/02/19 20:01:53 deus_x Exp $
###
### TODO:
###
###
###########################################################################

package Trinket::DataType;

BEGIN {
	our $VERSION = "0.0";
    our @ISA = qw( Exporter );
}

use strict;
use Trinket::Object;
use Carp qw(cluck);

sub install_methods {
	no strict 'refs';
	no warnings;
	
	my ($pkg, $self, $name) = @_;

	my $class = ref($self) ? ref($self) : $self;
	
	if (!UNIVERSAL::can($class, "get_".$name) ) {
		*{$class."::get_".$name} = sub {
			return ($pkg)->get($_[0], $name, @_[1..scalar(@_)]);
		};
	}
	if (!UNIVERSAL::can($class, "set_".$name) ) {
		*{$class."::set_".$name} = sub {
			return ($pkg)->set($_[0], $name, @_[1..scalar(@_)]);
		};
	}
}

sub uninstall_methods {
	no strict 'refs';
	no warnings;

	my ($pkg, $self, $name) = @_;

	my $class = ref($self) ? ref($self) : $self;

	if (UNIVERSAL::can($class, "set_".$name) ) {
		*{$class."::set_".$name} = sub {
			die "No such property '$name' to set for $self";
		};
	}
	if (UNIVERSAL::can($class, "get_".$name) ) {
		*{$class."::get_".$name} =  sub {
			die "No such property '$name' to get for $self";
		};
	}
}

1;

__END__
