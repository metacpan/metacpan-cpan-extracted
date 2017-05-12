package Test::Mock::Mango::Collection;

use v5.10;
use strict;
use warnings;

our $VERSION = '0.04';

use Test::Mock::Mango::Cursor;
use Mango::BSON::ObjectID;

# ------------------------------------------------------------------------------

sub new {
	my $class = shift;
	my $name  = $_[-1]; pop;
	my $db    = shift;

	bless {
		name => $name,
		db	 => $db||undef,
	}, $class;
}

# ------------------------------------------------------------------------------

# aggregate
#
# Fake an "aggregated result" by returning the current fake collection
#
sub aggregate {
	my $self = shift;
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

	my $docs = undef;
	my $err  = undef;

	if (defined $Test::Mock::Mango::error) {
		$err                      = $Test::Mock::Mango::error;
		$Test::Mock::Mango::error = undef;
	}
	else {
		$docs = $Test::Mock::Mango::data->{collection};
	}

	return $cb->($self,$err,$docs) if $cb;
	return $docs;
}

# ------------------------------------------------------------------------------

# create
#
# Doesn't do anything. Just return with or without error as specified
#
sub create {
	my $self = shift;
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

	my $err = undef;
	if (defined $Test::Mock::Mango::error) {
		$err                      = $Test::Mock::Mango::error;
		$Test::Mock::Mango::error = undef;
	}

	return $cb->($self,$err) if $cb;
	return;
}

# ------------------------------------------------------------------------------

# drop
#
# Doesn't do anything. Just return with or without error as specified
#
sub drop {
	my $self = shift;
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

	my $err = undef;
	if (defined $Test::Mock::Mango::error) {
		$err                      = $Test::Mock::Mango::error;
		$Test::Mock::Mango::error = undef;
	}

	return $cb->($self,$err) if $cb;
	return;	
}

# ------------------------------------------------------------------------------

# find_one
#
# By default we return the first document from the fake data collection
#
sub find_one {
	my ($self, $query) = (shift,shift);
	
	my $cb  = ref $_[-1] eq 'CODE' ? pop : undef;
	my $doc = undef;
	my $err = undef;
	
	if (defined $Test::Mock::Mango::error) {		
		$err                      = $Test::Mock::Mango::error;
		$Test::Mock::Mango::error = undef;
	}
	else {
		# Return the first fake document
		$doc = $Test::Mock::Mango::data->{collection}->[0] || undef;
	}

	return $cb->($self, $err, $doc) if $cb;	# Non blocking
	return $doc;							# Blocking
}

# ------------------------------------------------------------------------------

# find
#
# returns a new fake cursor
#
sub find {	
	return Test::Mock::Mango::Cursor->new; # Not actually passing any values
										   # through as we're not using them :-p
}

# ------------------------------------------------------------------------------

# full_name
#
# returns a concat of db.collection
#
sub full_name {
	my ($self) = @_;
	my $db = $self->{db}||{name=>undef};

	my $name = $db->{name};
	   $name .= $name ? '.' : '';
	   $name .= $self->{name};

	return $name;
}

# ------------------------------------------------------------------------------

sub insert {
	my ($self, $docs) = (shift,shift);

	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

	my $oids 		= [];
	my $err  		= undef;
	my $return_oids = '';

	if (defined $Test::Mock::Mango::error) {
		$return_oids 			  = undef;
		$err 					  = $Test::Mock::Mango::error;
		$Test::Mock::Mango::error = undef;
	}
	else {
		# Get how many docs we're "inserting" so we can return the right number of oids
		my $num_docs = 1;
		if (ref $docs eq 'ARRAY') {
			$num_docs = scalar @$docs;
			for (0..$num_docs-1) {				
				push @$oids, $docs->[$_]->{_id} // Mango::BSON::ObjectID->new;				
				push @{$Test::Mock::Mango::data->{collection}}, $docs->[$_];
			}
			$return_oids = $oids;
		}
		else {
			push @$oids, $docs->{_id} // Mango::BSON::ObjectID->new;
			push @{$Test::Mock::Mango::data->{collection}}, $docs;
			$return_oids = $oids->[0];
		}
	}
	
	return $cb->($self,$err,$return_oids) if $cb;
	return $return_oids;	
}

# ------------------------------------------------------------------------------

sub remove {
	my $self = shift;
	my $query = ref $_[0] eq 'CODE' ? {} : shift // {};
	my $flags = ref $_[0] eq 'CODE' ? {} : shift // {};

	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

	my $doc = undef; # TODO What should this return?
	my $err = undef;

	if (defined $Test::Mock::Mango::error) {
		$err                      = $Test::Mock::Mango::error;
		$Test::Mock::Mango::error = undef;
	}
	else {		
		$doc->{n} = $Test::Mock::Mango::n // 1;
	}

	$Test::Mock::Mango::n = undef;

	return $cb->($self,$err,$doc) if $cb;
	return $doc;
}

# ------------------------------------------------------------------------------

sub update {
	my ($self,$query,$changes) = (shift,shift,shift);

	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

	my $err = undef;
	my $doc = undef;

	if (defined $Test::Mock::Mango::error) {
		$err                      = $Test::Mock::Mango::error;
		$Test::Mock::Mango::error = undef;
	}
	else {
		$doc = $changes;	
		$doc->{n} = $Test::Mock::Mango::n // 1;
	}

	$Test::Mock::Mango::n = undef;

	return $cb->($self,$err,$doc) if $cb;
	return $doc;
}

# ------------------------------------------------------------------------------

sub find_and_modify {
	my ($self, $opts) = (shift,shift);
	
	my $cb  = ref $_[-1] eq 'CODE' ? pop : undef;
	my $doc = undef;
	my $err = undef;
	
	if (defined $Test::Mock::Mango::error) {		
		$err                      = $Test::Mock::Mango::error;
		$Test::Mock::Mango::error = undef;
	}
	else {
		# Return the first fake document
		$doc = $Test::Mock::Mango::data->{collection}->[0] || undef;
	}

	return $cb->($self, $err, $doc) if $cb;	# Non blocking
	return $doc;							# Blocking
}

# ------------------------------------------------------------------------------

1;

=encoding utf8

=head1 NAME

Test::Mock::Mango::Collection - fake Mango::Collection

=head1 DESCRIPTION

Simulated mango collection for unit testing as part of L<Test::Mock::Mango>.

=cut
