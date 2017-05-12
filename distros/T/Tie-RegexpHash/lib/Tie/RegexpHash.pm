package Tie::RegexpHash;

require 5.005;
use strict;

use vars qw( $VERSION @ISA );

$VERSION = '0.17';

use Carp;
use Data::Dumper;

# This is what stringified qrs seem to look like.
# It captures flags in $1 and pattern in $2
my $SERIALIZE_RE;

# To try to keep this working as far back as 5.5 we're using $]
if ($] < 5.013_006) {
    $SERIALIZE_RE = qr/^\(\?([ismx]{0,4})-[ismx]*:(.*)\)$/;
}
else {
    $SERIALIZE_RE = qr/^\(\?\^([ismx]{0,4}(?:-[ismx]{1,4})?):(.*)\)$/;
}

# This is what the serialized version looks like.
# It also captures flags in $1 and pattern in $2
my $DESERIALIZE_RE = qr/^([ismx]{0,4}):(.*)$/;

# Creates a new 'Tie::RegexpHash' object. We use an underlying array rather
# than a hash because we want to search through the hash keys in the order
# that they were added.
#
# See the _find() and add() routines for more details.
sub new {
    my ($class) = @_;

    my $self = {
      KEYS   => [ ], # array of Regexp keys
      VALUES => [ ], # array of corresponding values
      COUNT  => 0,   # the number of hash/key pairs (is this necessary?)
    };

    bless $self, $class;
}

# Embed any modifiers used with qr// in the pattern.
sub _convert_key {
    my ($key) = shift;

    my ($flags,$pat) = ($key =~ $SERIALIZE_RE);
    ($key = qr/(?$flags:$pat)/) if $flags;
    return $key;
}
    
# Sequentially goes through the hash keys for Regexps which match the given
# key and returns the index. If the hash is empty, or a matching key was not
# found, returns undef.
sub _find {
    my ($self, $key) = @_;

    unless ($self->{COUNT}) {
        return;
    }

    if (ref($key) eq 'Regexp') {
        my $i = 0;
        $key = _convert_key($key); 
        while (($i < $self->{COUNT}) and ($key ne $self->{KEYS}->[ $i ])) {
            $i++;
        }

        if ($i == $self->{COUNT}) {
            return;
        }
        else {
            return $i;
        }
    }
    else {
        my $i = 0;
        while (($i < $self->{COUNT}) and ($key !~ m/$self->{KEYS}->[ $i ]/)) {
            $i++;
        }

        if ($i == $self->{COUNT}) {
            return;
        }
        else {
            return $i;
        }
    }
}

# If a key exists the value will be replaced. (If the Regexps are not the same
# but match, a warning is displayed.) If the key is new, then a new key/value
# pair is added.
sub add {
    my ($self, $key, $value) = @_;

    ($key = _convert_key($key)) if (ref($key) eq 'Regexp');

    my $index = _find $self, $key;
    if (defined($index)) {
        if ($key ne $self->{KEYS}->[ $index ]) {
            carp "\'$key\' is not the same as \'",
                  $self->{KEYS}->[$index], "\'";
        }
        $self->{VALUES}->[ $index ] = $value;
    }
    else {
        $index = $self->{COUNT}++;

        ($key = qr/$key/) unless (ref($key) eq 'Regexp');

        $self->{KEYS}->[ $index ]   = $key;
        $self->{VALUES}->[ $index ] = $value;
    }
}


# Does a key exist or does it match any Regexp keys?
sub match_exists {
    my ($self, $key) = @_;
    return defined( _find $self, $key );
}

# Returns the value of a key or any matches to Regexp keys.
sub match {
    my ($self, $key) = @_;

    my $index = _find $self, $key;

    if (defined($index)) {
        return $self->{VALUES}->[ $index ];
    }
    else {
        return;
    }
}

# Removes a key or Regexp key and associated value from the hash. If the key
# is not the same as the Regexp, a warning is displayed.
sub remove {
    my ($self, $key) = @_;

    ($key = _convert_key($key)) if (ref($key) eq 'Regexp');

    my $index = _find $self, $key;

    if (defined($index)) {
        if ($key ne $self->{KEYS}->[ $index ]) {
            carp "'`$key\' is not the same as '`",
              $self->{KEYS}->[$index], "\'";
        }

        my $value = $self->{VALUES}->[ $index ];
        splice @{ $self->{KEYS} },   $index, 1;
        splice @{ $self->{VALUES} }, $index, 1;
        $self->{COUNT}--;
        return $value;
    }
    else {
        carp "Cannot delete a nonexistent key: \`$key\'";
        return;
    }
}

# Clears the hash.
sub clear {
    my ($self) = @_;

    $self->{KEYS}   = [ ];
    $self->{VALUES} = [ ];
    $self->{COUNT}  = 0;

}

BEGIN {
    # make aliases...
    no strict;
    *TIEHASH = \ &new;
    *STORE   = \ &add;
    *EXISTS  = \ &match_exists;
    *FETCH   = \ &match;
    *DELETE  = \ &remove;
    *CLEAR   = \ &clear;
}

# Returns the first key
sub FIRSTKEY {
    my ($self) = @_;

    unless ($self->{COUNT}) {
        return;
    }

    return $self->{KEYS}->[0];

}

# Returns the next key
sub NEXTKEY {
    my ($self, $lastkey) = @_;

    unless ($self->{COUNT}) {
        return;
    }

    my $index = _find $self, $lastkey;

    unless (defined($index)) {
        confess "Invalid \$lastkey";
    }

    $index++;

    if ($index == $self->{COUNT}) {
        return;
    }
    else {
        return $self->{KEYS}->[ $index ];
    }
}

# serialize object
sub STORABLE_freeze {
    my ($self, $cloning) = @_;

    my @keystrings;

    {
        local *_;
        @keystrings = map { join(':', ($_ =~ $SERIALIZE_RE)); } @{$self->{KEYS}};
    }
    
    my $sref = {
        KEYSTRINGS => \@keystrings,
        VALUES     => $self->{VALUES},
        COUNT      => $self->{COUNT},
    };

    return (0,$sref);
}

# deserialize
sub STORABLE_thaw {
    my($self, $cloning, $serialized, $sref) = @_;

    $self->{KEYS}   = [ ];
    $self->{VALUES} = $sref->{VALUES};
    $self->{COUNT}  = $sref->{COUNT};

    {
        local *_;
        @{$self->{KEYS}} = map {
             my ($flags,$pat) = ($_ =~ $DESERIALIZE_RE);
             $pat = ($flags) ? "(?$flags:$pat)" : $pat;
             qr/$pat/;
        } @{$sref->{KEYSTRINGS}};
    }
}

1;
__END__

=head1 NAME

Tie::RegexpHash - Use regular expressions as hash keys

=begin readme

=head1 REQUIREMENTS

L<Tie::RegexpHash> is written for and tested on Perl 5.14.0, but should run as
far back as Perl 5.005. (Because it uses Regexp C<qr//> variables it cannot run
on earlier versions of Perl.)

It uses only standard modules. Serialization is supported through Storable, but
Storable is not required for normal operation.

=head2 Installation

Installation can be done using the traditional Makefile.PL or the newer Build.PL
methods.

Using Makefile.PL:

  perl Makefile.PL
  make test
  make install

(On Windows platforms you should use C<nmake> instead.)

Using Build.PL (if you have Module::Build installed):

  perl Build.PL
  perl Build test
  perl Build install

=end readme

=head1 SYNOPSIS

  use Tie::RegexpHash;

  my %hash;

  tie %hash, 'Tie::RegexpHash';

  $hash{ qr/^5(\s+|-)?gal(\.|lons?)?/i } = '5-GAL';

  $hash{'5 gal'};     # returns "5-GAL"
  $hash{'5GAL'};      # returns "5-GAL"
  $hash{'5  gallon'}; # also returns "5-GAL"

  my $rehash = Tie::RegexpHash->new();

  $rehash->add( qr/\d+(\.\d+)?/, "contains a number" );
  $rehash->add( qr/s$/,          "ends with an \`s\'" );

  $rehash->match( "foo 123" );  # returns "contains a number"
  $rehash->match( "examples" ); # returns "ends with an `s'"

=head1 DESCRIPTION

This module allows one to use regular expressions for hash keys, so that
values can be associated with anything that matches the key.

Hashes can be operated on using the standard tied hash interface in Perl, as
described in the SYNOPSIS, or using an object-oriented interface described below.

=for readme stop

=head2 Methods

=over

=item new

  my $obj = Tie::RegexpHash->new()

Creates a new "RegexpHash" (Regular Expression Hash) object.

=item add

  $obj->add( $key, $value );

Adds a new key/value pair to the hash. I<$key> can be a Regexp or a string
(which is compiled into a Regexp).

If I<$key> is already defined, the value will be changed. If C<$key> matches
an existing key (but is not the same), a warning will be shown if warnings
are enabled.

=item match

  $value = $obj->match( $quasikey );

Returns the value associated with I<$quasikey>. (I<$quasikey> can be a string
which matches an existing Regexp or an actual Regexp.)  Returns 'undef' if
there is no match.

Regexps are matched in the order they are defined.

=item match_exists

  if ($obj->match_exists( $quasikey )) ...

Returns a true value if there exists a matching key.

=item remove

  $value = $obj->remove( $quasikey );

Deletes the key associated with I<$quasikey>.  If I<$quasikey> matches
an existing key (but is not the same), a warning will be shown.

Returns the value associated with the key.

=item clear

  $obj->clear();

Removes all key/value pairs.

=back

=for readme continue

=begin readme

=head1 REVISION HISTORY

A brief list of changes since the previous release:

=for readme include file="Changes" start="0.17" stop="0.14" type="text"

For a detailed history see the F<Changes> file included in this distribution.

=end readme

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>, previous maintainer.

=head1 MAINTAINER

Alastair McGowan-Douglas <altreus@cpan.org>

=for readme stop

=head2 Acknowledgments

Russell Harrison <rch at cpan.org> for patches adding support
for serialization.

Simon Hanmer <sch at scubaplus.co.uk> & Bart Vetters <robartes at nirya.eb>
for pointing out a bug in the logic of the _find() routine in v0.10

=for readme continue

=head1 BUGS

Please report bugs on the
L<github issues tracker|https://github.com/Altreus/Tie-RegexpHash/issues>.
Request Tracker tickets will probably go unseen.

=head1 LICENSE


Copyright (c) 2001-2002, 2005-2006 Robert Rothenberg. All rights reserved.

Portions Copyright (c) 2014-2015 Alastair McGowan-Douglas.

Portions Copyright (c) 2006 Russell Harrison. All rights reserved.

This program is free software. You can redistribute it under the terms of the
L<Artistic Licence|http://dev.perl.org/licenses/artistic.html>.

=head1 SEE ALSO

L<Tie::Hash::Regex> is a module with a complementary function. Rather than
a hash with Regexps as keys that match against fetches, it has standard keys
that are matched by Regexps in fetches.

L<Regexp::Match::Any> matches many Regexps against a variable.

L<Regexp::Match::List> is similar, but supports callbacks and various
optimizations.

=cut
