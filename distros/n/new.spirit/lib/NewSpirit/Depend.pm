package NewSpirit::Depend;

use strict;
use NewSpirit::LKDB;
use File::Find;

sub new {
	my ($type) = shift;

	my ($depend_dir) = @_;

	my $dependants_file = "$depend_dir/##dependents";
	my $depends_on_file = "$depend_dir/##depends_on";

	my $lkdb_dependants = new NewSpirit::LKDB ($dependants_file);
	my $lkdb_depends_on = new NewSpirit::LKDB ($depends_on_file);

	my $self = {
		depend_dir 	=> $depend_dir,
		dependants_file	=> $dependants_file,
		depends_on_file => $depends_on_file,
		lkdb_dependants => $lkdb_dependants,
		lkdb_depends_on	=> $lkdb_depends_on,
		dependants 	=> $lkdb_dependants->{hash},
		depends_on	=> $lkdb_depends_on->{hash},
	};

	return bless $self, $type;
}

sub put_depends_on {
	my $self = shift;

	my ($object, $depends_on) = @_;

	my $record;
	if ( ref $depends_on eq 'HASH' ) {
		$record = join ("\t", keys %{$depends_on});
	} else {
		$record = join ("\t", @{$depends_on});
	}

	if ( $record ne '' ) {
		$self->{depends_on}->{$object} = $record;
	} else {
		delete $self->{depends_on}->{$object};
	}

	1;
}

sub get_depends_on {
	my $self = shift;

	my ($object) = @_;

	return unless defined $self->{depends_on}->{$object};

	my @list = split ("\t", $self->{depends_on}->{$object});
	my %hash;
	@hash{@list} = (1) x @list;
	
	return \%hash;
}

sub get_depends_on_resolved {
	my $self = shift;
	
	my ($object, $result_href) = @_;
	
	my $href = $self->get_depends_on ($object);
	
	return unless $href;

	foreach my $obj ( keys %{$href} ) {
		next if $result_href->{$obj};
		$result_href->{$obj} = 1;
		$self->get_depends_on_resolved ( $obj, $result_href );
	}
	
	1;
}

sub put_dependants {
	my $self = shift;

	my ($object, $dependants) = @_;

	my $record;
	if ( ref $dependants eq 'HASH' ) {
		$record = join ("\t", keys %{$dependants});
	} else {
		$record = join ("\t", @{$dependants});
	}

	if ( $record ne '' ) {
		$self->{dependants}->{$object} = $record;
	} else {
		delete $self->{dependants}->{$object};
	}

	1;
}

sub get_dependants {
	my $self = shift;

	my ($object) = @_;

#	print STDERR "get_dependants: object=$object\n";

	return unless defined $self->{dependants}->{$object};

	my @list = split ("\t", $self->{dependants}->{$object});
	my %hash;
	@hash{@list} = (1) x @list;
	
	return \%hash;
}

sub get_dependants_resolved {
	my $self = shift;
	
	my ($object, $result_href) = @_;

	# get direct dependants
	my $href = $self->get_dependants ($object);
	
	return unless $href;

	# now iterate over the dependants and go into
	# recursion
	foreach my $obj ( keys %{$href} ) {
		# abort if we visited this object already
		next if exists $result_href->{$obj};
		
		# mark entry in result hash
		$result_href->{$obj} = 1;
		
		# go into recursion
		$self->get_dependants_resolved ($obj, $result_href);
	}

	1;
}

sub DIESABLED_get_dependants_resolved {
	my $self = shift;
	
	my ($object, $result_href) = @_;

	#-------------------------------------------------------
	# WARNING:
	#-------------------------------------------------------
	# Actually not *all* objects, which depend on $object,
	# are returned. Only such types, which are listed
	# in the objecttypes.conf to be relevant for dependency
	# processing are determined. This is somewhat dirty,
	# because originally this class should not need to
	# know such specials things about object types and
	# their relationships. Maybe this will change in future.
	#-------------------------------------------------------
	
	
	# get direct dependants
	my $href = $self->get_dependants ($object);
	
	return unless $href;

	# determine type of this object
	$object =~ /:(.*)/;
	my $object_type = $1;
	print "<p>my ot=$object_type<br>\n";
		
	# now iterate over the dependants and go into
	# recursion, if necessary.
	foreach my $obj ( keys %{$href} ) {
		# abort if we visited this object already
		next if exists $result_href->{$obj};

		# mark this if we find this object type
		# in the depend_install_object_types list
		# for this object type
		my $this_dep_lref = $NewSpirit::Object::object_types
				->{$object_type}
				->{depend_install_object_types};
		
		$obj =~ /:(.*)/;
		my $dep_obj_type = $1;
		print "dep_obj=<b>$obj</b><br>\n";
		
		my $go_deeper;
		foreach my $type ( @{$this_dep_lref} ) {
			print "found ot=$type<br>\n";
			if ( $dep_obj_type eq $type ) {
				$go_deeper = 1;
				last;
			}
		}

		print "go_deeper=<b>$go_deeper</b><br>\n";
		$result_href->{$obj} = $go_deeper ? 1 : 0;

		print "<p>go deeper: $obj<p>\n";
		$self->get_dependants_resolved ($obj, $result_href);
	}

	1;
}

sub delete_object {
	my $self = shift;
	
	my ($object) = @_;
	
	my $depends_on_href = $self->get_depends_on ($object);

	# All objects, on which this object depends, must be notified,
	# that this object not exist any longer

	my $o;
	foreach $o ( keys %{$depends_on_href} ) {
		my $href = $self->get_dependants ($o);
		delete $href->{$object};
		$self->put_dependants ($o, $href);
	}

	# Finally we delete the entry in the depends_on hash
	delete $self->{depends_on}->{$object};
	
	1;
}

sub update {
	my $self = shift;

	my ($object, $depends_on) = @_;

	$depends_on ||= {};
	
	# First remove all entries from the depends_on hash,
	# from which we are not dependant any longer

	my $old_depends_on = $self->get_depends_on ($object);

	foreach my $o ( keys %{$old_depends_on} ) {
		if ( ! defined $depends_on->{$o} ) {
			my $href = $self->get_dependants ($o);
			delete $href->{$object};
			$self->put_dependants ($o, $href);
		}
	}

	# Now add the new dependencies to the dependants
	# hashes of the objects we depend on now

	foreach my $o ( keys %{$depends_on} ) {
		if ( ! defined $old_depends_on->{$o} ) {
			my $href = $self->get_dependants ($o);
			$href->{$object} = 1;
			$self->put_dependants ($o, $href);
		}
	}

	# Finally update the depends_on entry for this object
	
	$self->put_depends_on ($object, $depends_on);

	return;
}

sub truncate {
	my $self = shift;
	
	my $dependants_file = $self->{dependants_file};
	my $depends_on_file = $self->{depends_on_file};
	
	$self->{lkdb_dependants} = undef;
	$self->{lkdb_depends_on} = undef;
	
	unlink $dependants_file;
	unlink $depends_on_file;
	
	my $lkdb_dependants = new NewSpirit::LKDB ($dependants_file);
	my $lkdb_depends_on = new NewSpirit::LKDB ($depends_on_file);
	
	$self->{lkdb_dependants} = $lkdb_dependants;
	$self->{lkdb_depends_on} = $lkdb_depends_on;
	
	1;
}

1;
