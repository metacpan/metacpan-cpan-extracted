package forks::BerkeleyDB::shared::hash;

$VERSION = 0.060;
use strict;
use warnings;
use BerkeleyDB 0.27;
use vars qw(@ISA);
@ISA = qw(BerkeleyDB::Btree);

#---------------------------------------------------------------------------
sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	return bless($self, $class);
}

# standard Perl feature methods implemented:
#	TIEHASH
#	FETCH, STORE
#	CLEAR, DELETE
#	EXISTS
#	FIRSTKEY, NEXTKEY
#	SCALAR
#	UNTIE, DESTROY

#---------------------------------------------------------------------------
*TIEHASH = *TIEHASH = \&new;

#---------------------------------------------------------------------------
sub FETCH {
	my $value = undef;
    $_[0]->db_get($_[1], $value);
	return $value;
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
sub DELETE {
	my $self = shift;
	return undef unless @_;
	my $key = shift;
	my $value = undef;
	my $cursor = $self->db_cursor(DB_WRITECURSOR);
	return undef unless $cursor->c_get($key, $value, DB_SET) == 0;	#set cursor position
	$cursor->c_del();
	$cursor->c_close();
	return $value;
}

sub CLEAR {
	my $self = shift;
	my $count = 0;
	$self->truncate($count);
	return defined $count && $count > 0 ? 1 : 0;
}

#---------------------------------------------------------------------------
#sub EXISTS {}	#use BerkeleyDB.pm method

#---------------------------------------------------------------------------
#sub FIRSTKEY {}	#use BerkeleyDB.pm method

#sub NEXTKEY {}	#use BerkeleyDB.pm method

#---------------------------------------------------------------------------
#sub SCALAR {}	#use BerkeleyDB.pm method (or FIRSTKEY if SCALAR not defined)

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

forks::BerkeleyDB::shared::hash - class for tie-ing hashes to BerkeleyDB Btree

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
