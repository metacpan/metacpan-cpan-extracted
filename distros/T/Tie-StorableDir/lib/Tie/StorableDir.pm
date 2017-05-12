package Tie::StorableDir;

use 5.008;
use strict;
use warnings;

use Carp;
use Tie::Hash;
use File::Spec;
use File::Spec::Functions;
use Storable;
use IO::Dir;
use Scalar::Util qw(weaken);
use Tie::StorableDir::Slot;

our @ISA = qw(Tie::Hash);
our $VERSION = 0.075;

# if $not_exiting = 0, we don't save anything. This is set at the end of the
# END {} block lower. This prevents gc ordering problems from trashing the data.
our $not_exiting = 1;

our %instances;

sub _path_encode {
	my $path = shift;
	$path =~ s{([^0-9a-zA-Z. -])}{sprintf "_%02x", ord $1}ge;
	return 'k'.$path;
}

sub _path_decode {
	my $path = shift;
	$path =~ s/^k// or return undef;
	$path =~ s{_([0-9a-zA-Z]{2})}{chr hex $1}ge;
	return $path;
}

sub TIEHASH {
	my ($class, %opts) = @_;
	$class = ref $class || $class;
	my $self = {};
	bless $self, $class;

	if (!exists $opts{dirname}) {
		croak "Missing required parameter dirname";
	}
	if (!-d $opts{dirname}) {
		croak "dirname '$opts{dirname}' is not a directory.";
	}
	$self->{dirname} = File::Spec->rel2abs(delete $opts{dirname});
	$self->{backedkeys} = {};
	if (%opts) {
		carp "One or more unrecognized options";
	}
	$instances{$self} = $self;
	return $self;
}

sub STORE {
	my ($self, $key, $value) = @_;
	unless ($not_exiting && defined $self->{dirname}) {
		carp "Exiting; STORE ignored.";
		return;
	}
	my $ekey = _path_encode($key);
	my $path = catfile($self->{dirname}, $ekey);
	eval {
		store \$value, $path
			or die $!;
	};
	if ($@) {
		croak "Error storing: $!";
	}
	if (defined $self->{backedkeys}{$key}) {
		my $slot = $self->{backedkeys}{$key};
		$slot->disconnect if defined $slot;
		delete $self->{backedkeys}{$key};
	}
}

sub FETCH {
	my ($self, $key) = @_;
	if (defined $self->{backedkeys}{$key}) {
		my $slot = $self->{backedkeys}{$key};
		return $slot->getvalue;
	}
	my $ekey = _path_encode($key);
	my $path = catfile($self->{dirname}, $ekey);
	return undef if (!-e $path);
	my $ref;
	eval {
		$ref = retrieve($path);
	};
	if (!defined $ref && $@) {
		croak "Error retrieving: $@";
	}
	if (!ref $$ref) {
		return $$ref;
	}
	my $slot = new Tie::StorableDir::Slot($key, $$ref, $self);
	my $v = $slot->getvalue;
	$self->{backedkeys}{$key} = $slot;
	weaken($self->{backedkeys}{$key});
	return $v;
}

sub EXISTS {
	my ($self, $key) = @_;
	$key = _path_encode($key);
	my $path = catfile($self->{dirname}, $key);
	return -e $path;
}

sub FIRSTKEY {
	my ($self) = @_;
	delete $self->{iterator};
	return $self->NEXTKEY;
}

sub NEXTKEY {
	my ($self) = @_;
	if (!defined $self->{iterator}) {
		$self->{iterator} = new IO::Dir($self->{dirname})
			or croak "Cannot open directory for read: $!";
	}
	while (1) {
		$! = 0;
		my $ent = $self->{iterator}->read;
		if (!defined $ent) {
			if ($! != 0 && !($! =~ /file desc/)) {
				croak "Cannot read directory entry: $!";
			}
			delete $self->{iterator};
			return undef;
		}
		my $path = catfile($self->{dirname}, $ent);
		next if (!-r $path || !-f $path);
		my $key = _path_decode($ent);
		next unless defined $key;
		return $key;
	}
}

sub DELETE {
	my ($self, $key) = @_;
	my $oldv = $self->FETCH($key);
	my $path = catfile($self->{dirname}, _path_encode($key));
	return undef if (!-e $path);
	unlink $path
		or croak "Cannot unlink key: $!";
	if (defined $self->{backedkeys}{$key}) {
		my $slot = $self->{backedkeys}{$key};
		$slot->disconnect if defined $slot;
		delete $self->{backedkeys}{$key};
	}
	return $oldv;
}

sub CLEAR {
	my ($self) = @_;
	my $dirh = new IO::Dir($self->{dirname})
		or croak "Cannot open directory: $!";
	while (defined($_ = $dirh->read)) {
		my $path = catfile($self->{dirname}, $_);
		next unless -f $path;
		unlink $path
			or croak "Cannot unlink $path: $!";
	}
	for (values %{$self->{backedkeys}}) {
		my $slot = $_;
		$slot->disconnect if defined $slot;
	}
	$self->{backedkeys} = {};
}

sub SCALAR {
	my ($self) = @_;
	return $self;
}

sub UNTIE {
	my ($self) = @_;
	for (values %{$self->{backedkeys}}) {
		next unless defined $_;
		$_->writeback;
		$_->disconnect;
	}
	delete $self->{backedkeys};
	delete $self->{dirname};
	delete $instances{$self};
}

sub DESTROY {
	my $self = shift;
	delete $instances{$self};
}

END {
	for (values %instances) {
		for (values %{$_->{backedkeys}}) {
			next unless defined $_;
			$_->writeback;
			$_->disconnect;
		}
		delete $_->{backedkeys};
	}
	$not_exiting = 0;
}

1;

__END__

=head1 NAME

Tie::StorableDir - Perl extension for tying directories with Storable files

=head1 SYNOPSIS

  use Tie::StorableDir;
  
  tie %hash, 'Tie::StorableDir', dirname => 'foo/';
  $hash{foo} = 42;

=head1 DESCRIPTION

Tie::StorableDir is a module which ties hashes to a backing directory
containing Storable.pm files. Any basic perl data type can be stored.
Values retrieved from the hash are tied so changes will be written back
either when all references to values under a key are removed, or the main
hash is untied.

=head1 ON-DISK FORMAT

Each value in the hash is stored in a file under the directory passed as
'dirname' to tie, with a filename derived from the key as follows:

 * Prepend 'k'
 * Replace characters outside the set [a-zA-Z0-9. -] with _(hex code)

The format of the files themselves is that of a reference to the scalar
value, serialized by Storable::store.

=head1 BUGS AND CAVEATS


=over

=item *

This module will most likely break under taint mode.


=item *

Most filesystems impose a length limit on files and paths.
This will restrict the maximum length of hash keys.
 
=item * 

The hash must be untie-d before exiting, or data corruption may result.

=back

=head1 AUTHOR

Bryan Donlan, E<lt>bdonlan@gmail.comE<gt>


=head1 SEE ALSO

L<Storable>, L<perltie>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Bryan Donlan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
