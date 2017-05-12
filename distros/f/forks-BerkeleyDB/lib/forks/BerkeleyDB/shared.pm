package forks::BerkeleyDB::shared;

$VERSION = 0.060;

package
	CORE::GLOBAL;	#hide from PAUSE
use subs qw(fork);
{
	no warnings 'redefine';
	*fork = \&forks::BerkeleyDB::shared::_fork;
}

package forks::BerkeleyDB::shared;

use strict;
use warnings;
use vars qw(@ISA);
@ISA = 'forks::shared';

use forks::BerkeleyDB::Config;
use BerkeleyDB 0.27;
use Storable qw(freeze thaw);
use Tie::Restore 0.11;
use Scalar::Util qw(blessed reftype weaken);

use constant DEBUG => forks::BerkeleyDB::Config::DEBUG();
use constant ENV_PATH => forks::BerkeleyDB::Config::ENV_PATH();
#use Data::Dumper;

our %object_refs;	#refs of all shared objects (for CLONE use, and weak refs: allow shared vars to hold other shared vars as values; END{...} cleanup in all threads)
our @shared_cache;	#tied BDB array that stores shared variable objects for other threads to use to reconstitute if they were created outside their scope
our @shared_cache_attr_bless;	#tied BDB array that stores shared variable object attribute bless

use constant TERMINATOR => "\0";
use constant ELEM_NOT_EXISTS => "!";	#indicates element does not exist (used for arrays)

########################################################################
sub _filter_fetch_value {
#warn "output: '$_', defined=",defined $_,",length=",length $_ if DEBUG;
	if (!defined $_ || length $_ == 0) { $_ = undef; }
	elsif (length $_ == 1 && $_ eq ELEM_NOT_EXISTS) {
		$_ = forks::BerkeleyDB::ElemNotExists->instance();
	}
	else {
		if (substr($_, -1) eq TERMINATOR) {	#regular data value
			chop($_);
		}
		else {	#is a shared var, retie to same shared ordinal
#warn Dumper($_, $object_refs{$_}, defined $shared_cache[$_] ? thaw($shared_cache[$_]) : undef) if DEBUG;
			my $obj;
			if (!defined $object_refs{$_} || !defined $object_refs{$_}->{bdb_is_connected} || !$object_refs{$_}->{bdb_is_connected}) {	#shared var created outside scope of this thread or needs to be reloaded: load object from shared var cache & reconnect to db
				$obj = defined $object_refs{$_} && defined $object_refs{$_}->{bdb_module} 
					? $object_refs{$_}
					: eval { @{thaw($forks::BerkeleyDB::shared::shared_cache[$_])}[0] };
#warn "*********".threads->tid().": _filter_fetch_value -> obj \#$_ recreated: $obj\n"; #if DEBUG;
				_croak( "Unable to load object state for shared variable \#$_" ) unless defined $obj;
				my $sub = '_tie'.$obj->{type};
				{
					no strict 'refs';
					&{$sub}($obj);
				}
			} else {
				$obj = $object_refs{$_};
			}
			my $class = $shared_cache_attr_bless[$_];
			if ($obj->{'type'} eq 'scalar')
				{ my $s; tie $s, 'Tie::Restore', $obj; $_ = $class ? CORE::bless(\$s, $class) : \$s; }
			elsif ($obj->{'type'} eq 'array')
				{ my @a; tie @a, 'Tie::Restore', $obj; $_ = $class ? CORE::bless(\@a, $class) : \@a; }
			elsif ($obj->{'type'} eq 'hash')
				{ my %h; tie %h, 'Tie::Restore', $obj; $_ = $class ? CORE::bless(\%h, $class) : \%h; }
#			elsif ($obj->{'type'} eq 'handle')
#				{ my *h; tie *h, 'Tie::Restore', $obj; $_ = $class ? CORE::bless(\*h, $class) : \*h; }
			else {
				_croak( "Unable to restore shared variable \#$_: ".ref($obj) );
			}
		}
	}
}

sub _filter_store_value {
#warn "input: '$_', defined=",defined $_,",length=",length $_ if DEBUG;
	if (defined $_) {
		if (ref($_)) {	#does this support both share(@a) and share(\@_)?
			if (UNIVERSAL::isa($_, 'forks::BerkeleyDB::ElemNotExists')) { $_ = ELEM_NOT_EXISTS; }
			else {
				my $tied = reftype($_) eq 'SCALAR' ? tied ${$_} 
					: reftype($_) eq 'ARRAY' ? tied @{$_} 
					: reftype($_) eq 'HASH' ? tied %{$_} 
					: reftype($_) eq 'GLOB' ? tied *{$_} : undef;
#warn "input: ".Dumper(ref $_, reftype $_, blessed $_, $tied, $_) if DEBUG;
				if (UNIVERSAL::isa($tied, 'threads::shared')) {	#store shared ref ordinal
					$_ = $tied->{'ordinal'};
				}
				else {	#future: transparently bless any type of object across all threads?
					_croak( "Invalid value for shared scalar: ".(reftype($_) || $_) );
				}
			}
		}
		else {
			$_ .= TERMINATOR();
		}
	}
#warn "input final: defined=",defined $_,",length=",length $_ if DEBUG;
}

########################################################################
BEGIN {
	require forks::shared;
	die "forks::shared version 0.18 required--this is only version $forks::shared::VERSION"
		unless defined $forks::shared::VERSION && $forks::shared::VERSION >= 0.18;
	use forks::BerkeleyDB::shared::array;
	
	*_croak = *_croak = \&threads::shared::_croak;
	
	_croak( "Must first 'use forks::BerkeleyDB'\n" ) unless $INC{'forks/BerkeleyDB.pm'};

	#need to store separate, serialized, db-disconnected copy in a separate database, so other threads can re-create arrayrefs and hashrefs
	sub _tie_shared_cache () {
		tie @shared_cache, 'forks::BerkeleyDB::shared::array', (
			-Filename => ENV_PATH.'/shared.bdb',
			-Flags    => DB_CREATE,
			-Mode     => forks::BerkeleyDB::BDB_ENV_CHMOD_OCTVAL(),
			-Env      => forks::BerkeleyDB::bdb_env,
		);

		tie @shared_cache_attr_bless, 'forks::BerkeleyDB::shared::array', (
			-Filename => ENV_PATH.'/shared_attr_bless.bdb',
			-Flags    => DB_CREATE,
			-Mode     => forks::BerkeleyDB::BDB_ENV_CHMOD_OCTVAL(),
			-Env      => forks::BerkeleyDB::bdb_env,
		);
	}
	
	sub _untie_shared_cache () {
		untie @shared_cache;
		untie @shared_cache_attr_bless;
	}
	
	sub _fork {
		### safely sync/close databases ###
		{
			local $@;
			foreach my $key (keys %object_refs) {
				if ($object_refs{$key}->{bdb_is_connected}) {
#					eval { $object_refs{$key}->{bdb}->db_sync(); };	#disabled: db_close expected to sync
					eval { $object_refs{$key}->{bdb}->db_close(); };
					$object_refs{$key}->{bdb} = undef;
					$object_refs{$key}->{bdb_is_connected} = 0;
				}
				$object_refs{$key}->{bdb_is_connected} = 0;	#hint that this object must be recreated from cache
			}
		}
		_untie_shared_cache();
		
		### do the fork ###
		my $pid = forks::BerkeleyDB::_fork();

		if (!defined $pid || $pid) { #in parent
			### immediately retie to critical databases ###
			_tie_shared_cache();
#			foreach my $key (keys %object_refs) {
#				my $sub = 'forks::BerkeleyDB::shared::_tie'.$object_refs{$key}->{type};
#				{
#					no strict 'refs';
#					$object_refs{$key} = &{$sub}($object_refs{$key});
#				}
#			}
		}
				
		return $pid;
	};
	
	*import = *import = \&forks::shared::import;
	
	*_ORIG_CLONE = *_ORIG_CLONE = \&forks::BerkeleyDB::CLONE;
	{
		no warnings 'redefine';
		*forks::BerkeleyDB::CLONE = \&_CLONE;
	}

	sub _CLONE {	#reopen environment and immediately retie to critical databases
		_ORIG_CLONE(@_);
		_tie_shared_cache();
	#	local $@;
	#	foreach my $key (keys %object_refs) {
	#		if ($object_refs{$key}->{bdb_is_connected}) {
	##			eval { $object_refs{$key}->{bdb}->db_sync(); };	#disabled: db_close expected to sync
	#			eval { $object_refs{$key}->{bdb}->db_close(); };
	#			$object_refs{$key}->{bdb_is_connected} = 0;
	#		}
	#warn "In clone (tid #".threads->tid."): $key -> ".ref($object_refs{$key}) if DEBUG;
	#		my $sub = '_tie'.$object_refs{$key}->{type};
	#		{
	#			no strict 'refs';
	#			&{$sub}($object_refs{$key});
	#		}
	#	}
	}

	### create the base environment ###
	_tie_shared_cache();
}

END {
	local $@;
	foreach my $key (keys %object_refs) {
		if ($object_refs{$key}->{bdb_is_connected}) {
#			eval { $object_refs{$key}->{bdb}->db_sync(); };	#disabled: db_close expected to sync
			eval { $object_refs{$key}->{bdb}->db_close(); };
			$object_refs{$key}->{bdb_is_connected} = 0;
		}
	}
	eval { _untie_shared_cache(); };
}

########################################################################
sub _tiescalar ($) {
	my $obj = shift;
	return $obj unless ref($obj);
	$shared_cache[$obj->{ordinal}] = freeze([$obj]) unless defined $obj->{bdb_module};
	
	### create the database and store as additional property in the object ###
	$obj->{bdb_module} = __PACKAGE__.'::'.$obj->{type};
	(my $module_inc = $obj->{bdb_module}) =~ s/::/\//go; 
	eval "use $obj->{bdb_module}" unless exists $INC{$module_inc};
	my $bdb_path = ENV_PATH.'/'.$obj->{ordinal}.".bdb";
	$obj->{bdb} = $obj->{bdb_module}->new(
		-Filename => $bdb_path,
		-Flags    => DB_CREATE,
		-Mode     => 0666,
		-Env      => forks::BerkeleyDB::bdb_env,
	) or _croak( "Can't create bdb $bdb_path: $!; $BerkeleyDB::Error" );
	$obj->{bdb}->filter_fetch_value(\&_filter_fetch_value);
	$obj->{bdb}->filter_store_value(\&_filter_store_value);
	$obj->{bdb_is_connected} = 1;

	### store ref in package variable ###
	$object_refs{$obj->{ordinal}} = $obj;
	weaken($object_refs{$obj->{ordinal}});
	
	return $obj;
}

sub _tiearray ($) {
	my $obj = shift;
	return $obj unless ref($obj);
	$shared_cache[$obj->{ordinal}] = freeze([$obj]) unless defined $obj->{bdb_module};

	### create the database and store as additional property in the object ###
	$obj->{bdb_module} = __PACKAGE__.'::'.$obj->{type};
	(my $module_inc = $obj->{bdb_module}) =~ s/::/\//go; 
	eval "use $obj->{bdb_module}" unless exists $INC{$module_inc};
	my $bdb_path = ENV_PATH.'/'.$obj->{ordinal}.".bdb";
	$obj->{bdb} = $obj->{bdb_module}->new(
		-Filename => $bdb_path,
		-Flags    => DB_CREATE,
		-Property => DB_RENUMBER,
		-Mode     => 0666,
		-Env      => forks::BerkeleyDB::bdb_env,
	) or _croak( "Can't create bdb $bdb_path: $!; $BerkeleyDB::Error" );
	$obj->{bdb}->filter_fetch_value(\&_filter_fetch_value);
	$obj->{bdb}->filter_store_value(\&_filter_store_value);
	$obj->{bdb_is_connected} = 1;
	
	### store ref in package variable ###
	$object_refs{$obj->{ordinal}} = $obj;
	weaken($object_refs{$obj->{ordinal}});

	return $obj;
}

sub _tiehash ($) {
	my $obj = shift;
	return $obj unless ref($obj);
	$shared_cache[$obj->{ordinal}] = freeze([$obj]) unless defined $obj->{bdb_module};

	### create the database and store as additional property in the object ###
	$obj->{bdb_module} = __PACKAGE__.'::'.$obj->{type};
	(my $module_inc = $obj->{bdb_module}) =~ s/::/\//go; 
	eval "use $obj->{bdb_module}" unless exists $INC{$module_inc};
	my $bdb_path = ENV_PATH.'/'.$obj->{ordinal}.".bdb";
	$obj->{bdb} = $obj->{bdb_module}->new(
		-Filename => $bdb_path,
		-Flags    => DB_CREATE,
		-Mode     => 0666,
		-Env      => forks::BerkeleyDB::bdb_env,
	) or _croak( "Can't create bdb $bdb_path: $!; $BerkeleyDB::Error" );
	$obj->{bdb}->filter_fetch_value(\&_filter_fetch_value);
	$obj->{bdb}->filter_store_value(\&_filter_store_value);
	$obj->{bdb_is_connected} = 1;
	
	### store ref in package variable ###
	$object_refs{$obj->{ordinal}} = $obj;
	weaken($object_refs{$obj->{ordinal}});

	return $obj;
}

sub _tiehandle ($) {
	my $obj = shift;
	return $obj unless ref($obj);
	$shared_cache[$obj->{ordinal}] = freeze([$obj]) unless defined $obj->{bdb_module};

	$obj->{bdb_module} = __PACKAGE__.'::'.$obj->{type};
	$obj->{bdb} = undef;
	$obj->{bdb_is_connected} = 1;
	
	### store ref in package variable ###
	$object_refs{$obj->{ordinal}} = $obj;
	weaken($object_refs{$obj->{ordinal}});

	return $obj;
}

########################################################################
### overload some subs and methods in forks and forks::shared ###
{
	no warnings 'redefine';	#allow overloading without warnings

	sub threads::shared::_bless {
		my $it  = shift;
		my $ref = reftype $it;
		my $class = shift;
		my $object;
		
		if ($ref eq 'SCALAR') {
			$object = tied ${$it};
		} elsif ($ref eq 'ARRAY') {
			$object = tied @{$it};
		} elsif ($ref eq 'HASH') {
			$object = tied %{$it};
		} elsif ($ref eq 'GLOB') {
			$object = tied *{$it};
		}

		if (defined $object && blessed $object && $object->isa('threads::shared')) {
			my $ordinal = $object->{'ordinal'};
			$shared_cache_attr_bless[$object->{ordinal}] = $class;
		}
	}
	
	my $old_tie = \&threads::shared::_tie;
	*threads::shared::_tie = sub {
		my $class = shift;
		my $type = shift;
		my $self = shift || {};

		# Call parent tie
		my $obj;
		{
			local $threads::shared::CLONE_TIED = 0;	#just register with shared process; don't store
			$obj = $old_tie->( $class,$type,$self,@_ );
		}
		
		# Perform tie to BDB resources
		if ($type eq 'scalar') {
			forks::BerkeleyDB::shared::_tiescalar($obj);
		} elsif ($type eq 'array') {
			forks::BerkeleyDB::shared::_tiearray($obj);
		} elsif ($type eq 'hash') {
			forks::BerkeleyDB::shared::_tiehash($obj);
		} elsif ($type eq 'handle') {
			forks::BerkeleyDB::shared::_tiehandle($obj);
		} else {
			_croak("Unknown tie type $type");
		}
		
		# Clone any existing data
		my $data = shift;
		if ($threads::shared::CLONE_TIED) {
			if ($type eq 'scalar' && ref($data) eq 'SCALAR' && defined ${$data}) {
				$obj->STORE(ref(${$data}) ? threads::shared::shared_clone(${$data}) : ${$data});
			#TODO else handle other clone cases here
			} elsif ($type eq 'array' && ref($data) eq 'ARRAY' && @{$data}) {
				for (my $i = 0; $i < @{$data}; $i++) {
					$obj->STORE($i, ref($data->[$i]) ? threads::shared::shared_clone($data->[$i]) : $data->[$i]);
				}
			} elsif ($type eq 'hash' && ref($data) eq 'HASH' && %{$data}) {
				foreach (keys %{$data}) {
					$obj->STORE($_, ref($data->{$_}) ? threads::shared::shared_clone($data->{$_}) : $data->{$_});
				}
			}
		}
		
		return $obj;
	};

	sub threads::shared::AUTOLOAD {
		my $self = shift;
		my $obj;
		if (!defined $self->{bdb_is_connected} || !$self->{bdb_is_connected}) {	#shared var needs to be reloaded: load shared var cache & connect to db
#warn "*********".threads->tid().": threads::shared::AUTOLOAD -> obj \#$self->{ordinal}\n"; #if DEBUG;
			$obj = defined $object_refs{$self->{ordinal}} && defined $object_refs{$self->{ordinal}}->{bdb_module} 
				? $object_refs{$self->{ordinal}}
				: eval { @{thaw($forks::BerkeleyDB::shared::shared_cache[$self->{ordinal}])}[0] };
			_croak( "Unable to load object state for shared variable \#$self->{ordinal}" ) unless defined $obj;
			my $sub = 'forks::BerkeleyDB::shared::_tie'.$obj->{type};
			{
				no strict 'refs';
				$self = &{$sub}($obj);
			}
		} else {
			$obj = $object_refs{$self->{ordinal}};
		}
		(my $sub = $threads::shared::AUTOLOAD) =~ s/^.*::/$self->{'bdb_module'}::/;
#warn "$sub, $self->{ordinal}" if DEBUG;
#warn Dumper(\@_) if DEBUG;
		my @result;
		@result = $self->{'bdb'}->$sub(@_) if defined $self->{'bdb'};
		wantarray ? @result : $result[0];
	}
	
# Define generic perltie proxy methods for most scalar, array, hash, and handle events

	no strict 'refs';
	foreach my $method (qw/BINMODE CLEAR CLOSE EOF EXTEND FETCHSIZE FILENO GETC
		OPEN POP PRINT PRINTF READ READLINE SCALAR SEEK SHIFT STORESIZE TELL UNSHIFT WRITE
		PUSH/) {
		*{"threads::shared::$method"} = sub {
			$threads::shared::AUTOLOAD = 'threads::shared::'.$method;
			threads::shared::AUTOLOAD(@_);
		};
	}

	foreach my $method (qw/DELETE EXISTS FIRSTKEY NEXTKEY/) {
		*{"threads::shared::$method"} = sub {
			my $self = shift;
			my $sub = $self->{'module'}.'::'.$method;
			if ($self->{'type'} eq 'hash' && ref($_[0]) eq 'CODE') {
				$_[0] = "$_[0]";
			}
			$threads::shared::AUTOLOAD = 'threads::shared::'.$method;
			threads::shared::AUTOLOAD($self, @_);
		};
	}

	sub threads::shared::STORE {
		my $self = shift;

		# If this is a scalar and to-be stored value is a reference
		#  Obtain the object
		#  Die if the reference is not a threads::shared tied object
		my $val = $_[$self->{'type'} eq 'scalar' ? 0 : 1];
		if (my $ref = reftype($val)) {
			my $object;
			if ($ref eq 'SCALAR') {
				$object = tied ${$val};
			} elsif ($ref eq 'ARRAY') {
				$object = tied @{$val};
			} elsif ($ref eq 'HASH') {
				$object = tied %{$val};
			} elsif ($ref eq 'GLOB') {
				$object = tied *{$val};
			}
			Carp::croak "Invalid value for shared scalar"
				unless defined $object && $object->isa('threads::shared');
		}

		# If we're a hash and the key is a code reference
		#  Force key stringification, to insure remote server uses same key value as thread
		if ($self->{'type'} eq 'hash' && ref($_[0]) eq 'CODE') {
			$_[0] = "$_[0]";
		}
		$threads::shared::AUTOLOAD = 'threads::shared::STORE';
		threads::shared::AUTOLOAD($self, @_);
	}
	
	sub threads::shared::FETCH {

		# If we're a hash and the key is a code reference
		#  Force key stringification, to insure remote server uses same key value as thread

		my $self = shift;
			if ($self->{'type'} eq 'hash' && ref($_[0]) eq 'CODE') {
			$_[0] = "$_[0]";
		}
		$threads::shared::AUTOLOAD = 'threads::shared::FETCH';
		threads::shared::AUTOLOAD($self, @_);
	}

	sub threads::shared::SPLICE {
		# Die now if running in thread emulation mode
		Carp::croak('Splice not implemented for shared arrays') if eval {forks::THREADS_NATIVE_EMULATION()};
		$threads::shared::AUTOLOAD = 'threads::shared::SPLICE';
		threads::shared::AUTOLOAD(@_);
	}

	sub threads::shared::UNTIE {
		my $self = shift;
		return if $self->{'CLONE'} != $threads::shared::CLONE;
		if (defined $self->{'bdb_module'}) {
			my $sub = "$self->{'bdb_module'}::UNTIE";
			my @result;
			{
				no strict 'refs';
				@result = &{$sub}(@_);
			}
		}
		delete $object_refs{$self->{ordinal}};
		threads::shared::_command( '_untie',$self->{'ordinal'} );
	}

	sub threads::shared::DESTROY {
		my $self = shift;
		return if $self->{'CLONE'} != $threads::shared::CLONE;
		if (defined $self->{'bdb_module'}) {
			my $sub = "$self->{'bdb_module'}::DESTROY";
			my @result;
			{
				no strict 'refs';
				@result = &{$sub}(@_);
			}
			$self->{bdb_is_connected} = 0;
		}
		delete $object_refs{$self->{ordinal}};
		threads::shared::_command( '_tied',$self->{'ordinal'},$self->{'module'}.'::DESTROY' );
	}
}

1;

__END__
=pod

=head1 NAME

forks::BerkeleyDB::shared - high-performance drop-in replacement for threads::shared

=head1 SYNOPSYS

  use forks::BerkeleyDB;
  use forks::BerkeleyDB::shared;

  my $variable : shared;
  my @array    : shared;
  my %hash     : shared;

  share( $variable );
  share( @array );
  share( %hash );

  lock( $variable );
  cond_wait( $variable );
  cond_wait( $variable, $lock_variable );
  cond_timedwait( $variable, abs time );
  cond_timedwait( $variable, abs time, $lock_variable );
  cond_signal( $variable );
  cond_broadcast( $variable );

=head1 DESCRIPTION

forks::BerkeleyDB::shared is a drop-in replacement for L<threads::shared>, written as an
extension of L<forks::shared>.  The goal of this module improve upon the core performance
of L<forks::shared> at a level reasonably comparable to native ithreads (L<threads::shared>).

=head1 USAGE

See L<forks::shared> for common usage information.

=head2 Location of database files

This module will use $ENV{TMPDIR} (unless taint is on) or /tmp for all back-end database and
other support files.  See L<forks::BerkeleyDB/"TMPDIR"> for more information.

For the most part, BerkeleyDB will use shared memory for as much frequently
accesed data as possible, so you probably won't notice drive-based performance hits.  For optimal
performance with large shared datastructures, use a partition with a dedicated drive for temporary
space usage.  For best performance overall, use a ramdisk partition.

=head1 NOTES

Currently only SCALAR, ARRAY, and HASH shared variables are optimized.  HANDLE type is supported 
using the default method implemented by L<forks::shared>.

Shared variable access and modification are NOT guaranteed to be handled as atomic events.  
This correctly models the expected behavior of L<threads> but deviates from undocumented
L<forks> behavior, where these events are atomic.  Thus, don't forget to lock() 
your shared variable before using them concurrently in multiple threads; otherwise, results
may not be what you expect.

Variables retain their pre-existing values after being shared.  This may cause slow sharing
of a variable if the variable contained many (large) values, or may trigger errors if the
variable contained value(s) that are not valid for sharing.  This differs from the default
behavior of L<threads>; see L<forks/"Native threads 'to-the-letter' emulation mode"> if you
wish to make C<forks::BerkeleyDB> clear array/hash values just like native L<threads>.
Rule of thumb: always undef a variable before sharing it, unless you trust any pre-existing
value(s) to be sharable.

=head1 TODO

Add support for shared circular references (REF).

Monitor number of connected shared variables per thread and dynamically disconnect uncommonly
used vars based on last usage and/or frequency of usage (to meet BDB environment lock limits).

Allow for configurable lock limits (detault is 1000).  Maybe simple DB_CONFIG file in env with:
set_lk_max_locks N
set_lk_max_objects N

Implement shared variable locks, signals, and waiting with BerkeleyDB.

=head1 AUTHOR

Eric Rybski <rybskej@yahoo.com>.

=head1 COPYRIGHT

Copyright (c) 2006-2009 Eric Rybski <rybskej@yahoo.com>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<forks::shared>, L<threads::shared>

=cut
