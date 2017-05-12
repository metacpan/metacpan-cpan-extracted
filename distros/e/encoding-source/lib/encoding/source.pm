package encoding::source;

use 5.009005;
use strict;
use warnings;
use Encode qw(find_encoding);

our $VERSION = 0.03;

our $SINGLETON = bless {}, __PACKAGE__;

sub croak {
    require Carp;
    Carp::croak(__PACKAGE__ . ": @_");
}

my $LATIN1 = find_encoding('iso-8859-1')
    or croak("Can't load latin-1");

sub _find_encoding {
    my $name = shift;
    return $SINGLETON->{$name} // find_encoding($name);
}

sub import {
    my ($class, $name) = @_;
    my $enc = _find_encoding($name);
    if (!defined $enc) {
	croak("Unknown encoding '$name'");
    }
    # canonicalize the encoding name
    $name = $enc->name;
    # associate it to the currently compiled lexical unit
    $^H{$class} = $name;
    # remember the Encode object for that encoding
    $SINGLETON->{$name} //= $enc;
    # make sure to install our encoding handler
    ${^ENCODING} = $SINGLETON;
}

sub unimport {
    my $class = shift;
    undef $^H{$class};
}

# now, the three methods called by the core on ${^ENCODING}

# returns the name of the encoding which is in effect in the
# caller's lexical unit

sub name {
    my $level = $_[1] // 0;
    my $hinthash = (caller($level))[10];
    return $hinthash->{"" . __PACKAGE__};
}

# the other methods are just forwarded to the appropriate
# Encode object, retrieved in the $SINGLETON

for my $method (qw(decode cat_decode)) {
    no strict 'refs';
    *$method = sub {
	use strict;
	my $self = shift;
	my $name = $self->name(1);
	if ($name) {
	    my $enc = $self->{$name};
	    if (!defined $enc) {
		croak("Can't find compiled encoding for '$name'");
	    }
	    $enc->$method(@_);
	}
	else {
	    $LATIN1->$method(@_);
	}
    };
}

1;

__END__

=head1 NAME

encoding::source - allows you to write your script in non-ascii or non-utf8

=head1 DEPRECATION NOTICE

B<NOTE>: This module relies on the internal perl variable C<${^ENCODING}>,
which is deprecated in perl 5.22.0. In this perl version the C<encoding> pragma
has been made lexical, which removes the usefulness of this module.

=head1 SYNOPSIS

    use encoding::source 'utf8';
    no encoding::source; # back to latin-1

    {
      use encoding::source 'utf8';
      # ...
    }
    # back to latin-1

=head1 DESCRIPTION

This pragma allows to change the default encoding for string literals in the
current lexical compilation unit (block or file).

This is like the C<encoding> pragma (pre-5.22.0), but done right:

=over 4

=item *

It doesn't mess with the STDIN and STDOUT filehandles.

=item *

It's lexically scoped and its effect doesn't leak into other files.

=back

=head1 SEE ALSO

L<Encode>, L<encoding>

=head1 COPYRIGHT

(c) Copyright 2007 by Rafael Garcia-Suarez.

Most test files are adapted from the tests of C<encoding>,
maintained by Dan Kogai as part of the C<Encode> distribution.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
