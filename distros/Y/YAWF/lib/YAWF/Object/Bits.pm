package YAWF::Object::Bits;

use strict;
use warnings;

use YAWF;

sub _bits {
	my $self = shift;
	my $col = shift;
	my $options = shift;

	my $value = $self->get_column($col) || 0;

	return $self->{$col} if defined($self->{$col}) and defined($self->{'_'.$col}) and ($self->{'_'.$col} == $value);

	my $nr = 0;
	$self->{$col} = [map {
			{
				nr => $nr,
				text => $_,
				active => ($value & (2**($nr++))),
			};
		} (@{$options})];
	
	return $self->{$col};
}

sub from_query {
	my $self = shift;
	
	my $yawf = YAWF->SINGLETON;
	my $query = $yawf->request->query;

	for my $key (@_) {

		my $value = 0;
		for (0..31) {
			next unless $query->{$key.'_'.$_};
			$value += 2**$_;
		}
		
		$self->set_column($key,$value);
		
	}

	return 1;
}

1;
