
package Tie::File::Hashify;

use strict;
use warnings;

use Carp;
use IO::File;

our $VERSION = '0.03';


sub TIEHASH {
	my ($class, $path, %options) = @_;

	my $self = bless {
		hash => {},
		format => $options{format},
		parse => $options{parse},
		path => $path,
		ro => $options{ro},
		dirty => 0,
	}, $class;

	if($path and -e $path and $options{parse}) {
		my $io = new IO::File($path) or croak "Can't read $path. $!.\n";

		while(my $line = $io->getline) {
			next unless defined $line and length($line);

			my ($key, $value);

			# Use callback for parsing.
			if(ref($options{parse}) eq 'CODE') {
				($key, $value) = &{$options{parse}}($line);
			}

			# Parse line using a regular expression.
			elsif(ref($options{parse}) eq '' or uc(ref($options{parse})) eq 'REGEXP') {
				my $re = ref($options{parse}) ? $options{parse} : qr/^$options{parse}$/;
				($key, $value) = ($line =~ $re);
			}

			# Croak.
			else {
				croak 'Can\'t use ', lc(ref($options{parse})), " for parsing.\n";
			}

			if(defined $key and length $key) {
				$self->{hash}->{$key} = $value if(length $key);
			}
		}

		$io->close;
	}

	return $self;
}


sub FETCH {
	my ($self, $key) = @_;
	return $self->{hash}->{$key};
}


sub STORE {
	my ($self, $key, $value) = @_;

	croak "Can't store in read-only mode" if($self->{ro});

	$self->{dirty} = !0;

	return $self->{hash}->{$key} = $value;
}


sub EXISTS {
	my ($self, $key) = @_;
	return exists($self->{hash}->{$key});
}


sub DELETE {
	my ($self, $key) = @_;

	croak "Can't delete in read-only mode" if($self->{ro});

	$self->{dirty} = !0;

	return delete($self->{hash}->{$key});
}


sub CLEAR {
	my ($self) = @_;

	croak "Can't clear in read-only mode" if($self->{ro});

	$self->{dirty} = !0;

	%{$self->{hash}} = ();
}


sub FIRSTKEY {
	my ($self) = @_;
	my ($key) = each %{$self->{hash}};
	return $key;
}


sub NEXTKEY {
	my ($self) = @_;

	my ($k, $v) = each %{$self->{hash}};

	return $k;
}


sub SCALAR {
	my ($self) = @_;

	my $format = $self->{format};

	if(defined $format) {
		my $text = '';

		values %{$self->{hash}};

		while(my ($key, $value) = each %{$self->{hash}}) {
			# Format using callback.
			if(ref($format) eq 'CODE') {
				$text .= &{$format}($key, $value) . "\n";
			}

			# Format using sprintf and a format string.
			elsif(ref($format) eq '') {
				$text .= sprintf($format, $key, $value) . "\n";
			}

			# Croak.
			else {
				croak 'Can\'t use ' . ref($format) . " as format.\n";
			}
		}

		return $text;
	}

	else {
		return %{$self->{hash}};
	}
}


sub _store {
	my ($self) = @_;

	my $path = $self->{path};

	if($path and $self->{dirty} and $self->{format} and !$self->{ro}) {
		my $io = new IO::File('>' . $path) or croak "Can't write $path. $!.\n";

		$io->print($self->SCALAR);
		$io->close;

		$self->{dirty} = 0;
	}
}


sub UNTIE {
	my ($self) = @_;

	$self->_store;
}


sub DESTROY {
	my ($self) = @_;

	$self->_store;
}


!0;

__END__

=head1 NAME

TIe::File::Hashify - Parse a file and tie the result to a hash.

=head1 SYNOPSIS

	use Tie::File::Hashify;

	my %rc;
	my $path = "$ENV{HOME}/.some.rc";

	# Parse lines like 'foo = bar':
	sub parse { $_[0] =~ /^\s*(\S+)\s*=\s*(.*?)\s*$/ };

	# Format pairs as 'key = value':
	sub format { "$_[0] = $_[1]" };

	tie(%rc, 'Tie::File::Hashify', $path, parse => \&parse, format => \&format);

	print "option 'foo' = $rc{foo}\n";

	# Add new option.
	$rc{bar} = 'moo';

	# Save file.
	untie %rc;

=head1 DESCRIPTION

This module helps parsing simple text files and mapping it's contents to a
plain hash. It reads a file line by line and uses a callback or expression you
provide to parse a key and a value from it. The key/value pairs are then
available through the generated hash. You can also provide another callback or
format string that formats a key/value pair to a line to be stored back to the
file.

=head1 METHODS

=over 4

=item B<tie>(%hash, 'Tie::File::Hashify', $path, %options)

The third argument (after the hash itself and the package name of course) is
the path to a file. The file does not really have to exist, but using a path to
a non-existent file does only make sense if you provide a format-callback to
write a new file.

After the second argument, a list of options may/should follow:

=over 4

=item B<parse>

Either a code reference, which will be called with a line as argument and
should return the key and the value for the hash element; or a string or
compiled regular expression (qr//). The expression will be applied to every
line and $1 and $2 will be used as key/value afterwards.

=item B<format>

This is used for formatting the hash into something that can be written back to
the file. It may be a code reference that takes two arguments (key and value)
as arguments and returns a string (without trailing line-break - it will be
added automatically), or a format string that is forwarded to B<sprintf>
together with the key and the value.

=item B<ro>

If this is true, changing the hash will make it croak, and the content will not
be written back to the file.

=back

All arguments are optional. If you don't give any arugments, you get a plain
normal hash.

=back

=head1 COPYRIGHT

Copyright (C) 2008 by Jonas Kramer <jkramer@cpan.org>. Published under the
terms of the Artistic License 2.0.

"read-only" functionality by Marco Emilio Poleggi.

=cut

