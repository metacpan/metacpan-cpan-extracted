package forks::BerkeleyDB::shared::array;

$VERSION = 0.060;
use strict;
use warnings;
use BerkeleyDB 0.27;
use forks::BerkeleyDB::ElemNotExists;
use vars qw(@ISA);
@ISA = qw(BerkeleyDB::Recno);

#---------------------------------------------------------------------------
sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	return bless($self, $class);
}

# standard Perl feature methods implemented:
#	TIEARRAY
#	FETCH, STORE
#	FETCHSIZE, STORESIZE
#	EXTEND
#	EXISTS, DELETE
#	CLEAR
#	PUSH, POP
#	SHIFT, UNSHIFT
#	SPLICE
#	UNTIE, DESTROY

#---------------------------------------------------------------------------
*TIEARRAY = *TIEARRAY = \&new;

sub _exists_elem ($) {
	my $value = shift;
	return defined $value && UNIVERSAL::isa($value, 'forks::BerkeleyDB::ElemNotExists') ? 0 : 1;
}

sub _db_filter_array_elem_not_exists_to_undef ($) {
	my $value = shift;
	return defined $value && UNIVERSAL::isa($value, 'forks::BerkeleyDB::ElemNotExists') ? undef : $value;
}

#---------------------------------------------------------------------------
sub FETCH { 
	my $value = undef;
	$_[0]->db_get($_[1], $value);
	return defined $value && UNIVERSAL::isa($value, 'forks::BerkeleyDB::ElemNotExists') ? undef : $value;	#_db_filter_array_elem_not_exists_to_undef
}

sub STORE { 
	if (defined $_[2]) {
		return undef unless $_[0]->db_put($_[1], $_[2]) == 0;
	} else {
		no warnings 'uninitialized';
		return undef unless $_[0]->db_put($_[1], $_[2]) == 0;
	}
	return $_[2]; 
}

#---------------------------------------------------------------------------
#sub FETCHSIZE {} 	#use BerkeleyDB.pm method

sub STORESIZE {
	my $self = shift;
	my $count = shift;
	my $nkeys = $self->FETCHSIZE();
#warn "STORESIZE: count=$count; nkeys=$nkeys";
	if ($nkeys < $count) { #add undef elements
		my $value = forks::BerkeleyDB::ElemNotExists->instance();
		$self->db_put($_, $value, DB_APPEND) for ($nkeys..($count - 1));
	}
	elsif ($nkeys > $count) { #trim elements
		my $value = undef;
		my $cursor = $self->db_cursor(DB_WRITECURSOR);
		for (($count - 1)..($nkeys - 1)) {
			return $self->FETCHSIZE() unless $cursor->c_get($_, $value, DB_LAST) == 0;	#optimized: using DB_LAST prevents database renumbering
			return $self->FETCHSIZE() unless $cursor->c_del() == 0;
		}
	}
	return $self->FETCHSIZE();
}

#---------------------------------------------------------------------------
sub EXTEND {
	return $_[1];	#no need for pre-allocation
}

#---------------------------------------------------------------------------
sub EXISTS {	#test that this works after delete
	my $self = shift;
	my $key = shift;
	my $value = undef;
	return 0 unless $self->db_get($key, $value) == 0;
	return _exists_elem($value) ? 1 : 0;
}

sub DELETE {	#doesn't appear to support deleting entire array (delete @a[0..$#a] == DB truncate)?
	my $self = shift;
	return undef unless @_;
	my $key = shift;
	my $value = undef;
#warn "DELETE: key=$key";
	my $cursor = $self->db_cursor(DB_WRITECURSOR);
	return undef unless $cursor->c_get($key, $value, DB_SET) == 0;	#set cursor position
	if ($key == $self->FETCHSIZE() - 1) {	#if this is last key, delete element
		return undef unless $cursor->c_del() == 0;
	}
	else { #initialize element to "not exists" state
		my $new_value = forks::BerkeleyDB::ElemNotExists->instance();
#warn "DELETE: success!";
		return undef unless $cursor->c_put($key, $new_value, DB_CURRENT) == 0;
	}
	
	### delete any other "not exists" elements, starting from last element ###
	my ($cur_key, $cur_value) = (0, '');
	while ($cursor->c_get($key, $value, DB_LAST) == 0) {
		if (_exists_elem($value)) {	last; }
		else {
			return undef unless $cursor->c_del() == 0;
		}
	}
	
	$cursor->c_close();
#warn "DELETE: success!";
	return _db_filter_array_elem_not_exists_to_undef($value);
}

#---------------------------------------------------------------------------
sub CLEAR {
	my $self = shift;
	my $count = 0;
	$self->truncate($count);
	return defined $count && $count > 0 ? 1 : 0;
}

#---------------------------------------------------------------------------
sub PUSH {
	my $self = shift;
	my $key = 0;
	no warnings 'uninitialized';
	foreach (@_) {
		return $self->FETCHSIZE() unless $self->db_put($key, $_, DB_APPEND) == 0;
	}
	return $self->FETCHSIZE();
}

sub POP {
	my $self = shift;
	my $value = $self->SUPER::POP(@_);
	return defined $value && UNIVERSAL::isa($value, 'forks::BerkeleyDB::ElemNotExists') ? undef : $value;	#_db_filter_array_elem_not_exists_to_undef
}

#---------------------------------------------------------------------------
sub SHIFT {
	my $self = shift;
	my $value = $self->SUPER::SHIFT(@_);
	return defined $value && UNIVERSAL::isa($value, 'forks::BerkeleyDB::ElemNotExists') ? undef : $value;	#_db_filter_array_elem_not_exists_to_undef
}

sub UNSHIFT {
	my $self = shift;
	return undef unless @_;
	$self->SUPER::UNSHIFT(@_);
	return $self->FETCHSIZE();
}

#---------------------------------------------------------------------------
sub SPLICE {
	my $self = shift;
	my $offset = shift || 0;
	my $length = shift;
	
	my $nkeys = $self->FETCHSIZE();
	my $p_offset = $offset < 0 ? $nkeys + $offset : $offset;
	$p_offset = $nkeys - 1 if $p_offset > $nkeys - 1;
	
	### handle warnings ###
	unless (defined $length) {
		warnings::warnif('uninitialized', 'Use of uninitialized value in splice');
		$length = $nkeys - $offset;
	}
	warnings::warnif('misc', 'splice() offset past end of array') if $offset > $nkeys - 1;
	die "Modification of non-creatable array value attempted, subscript $offset"
		if $offset < 0 && abs($offset) > $nkeys;

	### remove elements ###
	my @removed;
#warn "length=$length";		
	if ($length > 0) {
		my $cursor = $self->db_cursor(DB_WRITECURSOR);
		my $max_idx = $p_offset + $length - 1 > $nkeys - 1 ? $nkeys - 1 : $p_offset + $length - 1;
		for ($p_offset..$max_idx) {
			my $key = $p_offset;
			my $value = undef;
			my $status = $cursor->c_get($key, $value, DB_SET) == 0;	#set cursor position
			next if $status == DB_NOTFOUND || $status == DB_KEYEMPTY;
			push @removed, _db_filter_array_elem_not_exists_to_undef($value);
			return @removed unless $cursor->c_del() == 0;
			$nkeys--;
		}
		$cursor->c_close();
	}
	
	### insert elements ###
	if (@_) {
		my $num_vals = scalar @_;
#warn "num_vals to insert=$num_vals";		
		### extend database to new size ###
		$nkeys = $self->STORESIZE($nkeys + $num_vals);
#warn "new size=",$nkeys;		
		
		### insert elements starting at offset (and temporarily save old ones) ###
		my @values_to_move;
		my $cursor = $self->db_cursor(DB_WRITECURSOR);
		my $max_idx = $p_offset + ($num_vals - 1) > $nkeys - 1 ? $nkeys - 1 : $p_offset + ($num_vals - 1);
#warn "insert: range=$p_offset..$max_idx";		
		for my $key ($p_offset..$max_idx) {
			my $value = undef;
			my $new_value = shift;
			my $status = $cursor->c_get($key, $value, DB_SET) == 0;	#set cursor position
			next if $status == DB_NOTFOUND || $status == DB_KEYEMPTY;
			push @values_to_move, $value;
#warn "insert: key=$key";		
			return @removed unless $cursor->c_put($key, $new_value, DB_CURRENT) == 0;
#warn "insert success! (status=$status)";
		}
		
		### move elements shifted by splice ###
#warn "move: values=(",join(',', @values_to_move),")";
#warn "move: range=",($p_offset + $num_vals)."..".($nkeys - 1);		
		for my $key (($p_offset + $num_vals)..($nkeys - 1)) {
#warn "move: key=$key";		
			my $value = undef;
			my $status = $cursor->c_get($key, $value, DB_SET) == 0;	#set cursor position
			next if $status == DB_NOTFOUND || $status == DB_KEYEMPTY;
			push @values_to_move, $value;
			return @removed unless $cursor->c_put($key, shift @values_to_move, DB_CURRENT) == 0;
		}
		$cursor->c_close();
	}
	
	return @removed;
}

#---------------------------------------------------------------------------
sub UNTIE {
	eval { $_[0]->db_sync(); };
}

sub DESTROY {
#	eval { $_[0]->db_sync(); };
	$_[0]->SUPER::DESTROY(@_) if $_[0];
}

#---------------------------------------------------------------------------
1;

__END__
=pod

=head1 NAME

forks::BerkeleyDB::shared::array - class for tie-ing arrays to BerkeleyDB Recno

=head1 DESCRIPTION

Helper class for L<forks::BerkeleyDB::shared>.  See documentation there.

=head1 AUTHOR

Eric Rybski <rybskej@yahoo.com>.

=head1 COPYRIGHT

Copyright (c) 2006-2009 Eric Rybski <rybskej@yahoo.com>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<forks::BerkeleyDB::shared>, L<forks::shared>.

=cut
