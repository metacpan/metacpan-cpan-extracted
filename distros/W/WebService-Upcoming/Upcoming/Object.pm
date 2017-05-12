# *****************************************************************************
# *                                                                           *
# * WebService::Upcoming::Object                                              *
# *                                                                           *
# *****************************************************************************


# Package *********************************************************************
package WebService::Upcoming::Object;


# Exports *********************************************************************
our $VERSION = '0.05';


# Code ************************************************************************
sub new
{
	my $clas;
	my $args;
	my $vers;
	my $self;

	($clas,$args,$vers) = @_;
	$self = {};
	bless($self,$clas);
	$self->{'version'} = $vers || '1.0';
	foreach (keys(%{$args}))
	{
		$self->{$_} = $args->{$_};
	}
	foreach ('version',$self->_list($self->{'version'}))
	{
		my $meth;

		# Duuuude!
		$meth = $_;
		*{$clas.'::'.$meth} = sub { return shift->{$meth}; }
			if (!defined(*{$clas.'::'.$meth}));
	}

	return $self;
}
sub _name { return ''; }
sub _list { return (); }
sub _fill { return;    }
1;
__END__

=head1 NAME

WebService::Upcoming::Object - Virtual response object to the Upcoming API

=head1 AUTHOR

Copyright (C) 2005, Greg Knauss, E<lt>greg@eod.comE<gt>

=head1 SEE ALSO

L<WebService::Upcoming>

=cut
