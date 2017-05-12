#!/usr/bin/perl
#
# Tie::HashVersion
# Copyright 1999 M-J. Dominus.  (mjd-perl-hashhistory@plover.com)
# You may distribute  
#

package Tie::HashHistory;
$VERSION = '0.03';

sub SEQ () { ".S" };

# If you change this, you'll have to alter _inc and **!!** below.
# It assumes these values.
my $width = 8;
my $words = $width/4;
my $ZERO = "\0" x $width;

sub TIEHASH {
  my $package = shift;
  my $subpackage = shift;
  my %fakehash;
  my $self = tie %fakehash => $subpackage, @_;
  return unless $self;
  _setup($self);
  bless \$self => $package;
}

sub _setup {
  my ($hash) = @_;
  unless ($hash->FETCH(SEQ)) {
    my $one = $ZERO;
    ++vec($one, $words-1, 32);
    $hash->STORE(SEQ, $one);
  }
}

sub new {
  goto &TIEHASH;
}

sub FETCH {
  my ($self, $key) = @_;
  substr($$self->FETCH("$key.$ZERO"), $width);
}

sub STORE {
  my ($self, $key, $value) = @_;
  my $seq = $$self->FETCH(SEQ);
  my $old = $$self->FETCH("$key.$ZERO");
  $$self->STORE("$key.$seq", $old);
  $$self->STORE("$key.$ZERO", $seq . $value);
  ++vec($seq, 1, 32) or ++vec($seq, 0, 32); # LOD  # **!!**
  $$self->STORE(SEQ, $seq);
}

sub FIRSTKEY {
  my ($self) = @_;
  my $key = $$self->FIRSTKEY;
  until ($key =~ s/\.$ZERO$//o || !defined $key) {
    $key = $$self->NEXTKEY($key);
  }
  $key;
}

sub NEXTKEY {
  my ($self, $key) = @_;
  until ($key =~ s/\.$ZERO$//o || ! defined $key) {
    $key = $$self->NEXTKEY($key);
  }
  $key;
}

sub DELETE {
  my ($self) = @_;
  my $pack = ref $self;
  require Carp;
  Carp::croak("`delete' unimplemented for $pack; aborting");
}

sub CLEAR {
  my ($self) = @_;
  $$self->CLEAR();
  _setup($$self);
}

sub EXISTS {
  my ($self, $ley) = @_;
  $$self->EXISTS("$key.$ZERO");
}

sub DESTROY {			# Not necessary to do anything
}

sub history {
  my ($self, $key) = @_;
  my $seq = $ZERO;
  my @result;
  for (;;) {
    my $val = $$self->FETCH("$key.$seq");
    last unless $val;
    push @result, substr($val, $width);
    $seq = substr($val, 0, $width);
  }
  @result;
}

sub _inc {
  ++vec($_[0], 1, 32) or ++vec($_[0], 0, 32); # LOD
}

1;

=head1 NAME 

Tie::HashHistory - Track history of all changes to a tied hash

=head1 VERSION

This file documents C<Tie::HashHistory> version B<0.03>

=head1 SYNOPSIS

	my $hh = tie %hash => Tie::HashHistory, PACKAGE, ARGS...;

	@values = $hh->history(KEY);

=head1 DESCRIPTION

C<Tie::HashHistory> interposes itself between your program and another
tied hash.  Fetching and storing to the hash looks completely normal,
but C<Tie::HashHistory> is keeping a record of all the changes to the
each key, and can Tie::HashHistory will give you a list of all the
values the key has ever had, in chronological order.

The arguments to the C<tie> call should be C<Tie::HashHistory>, 
and then the arguments that you I<would> have given to C<tie> to tie
the hash without the history feature.  For example, suppose you wanted
to store your hash data in an NDBM file named C<database>.  Normally,
you would say:

	tie %hash => NDBM_File, 'database', $flags, $mode;
	

to get this history feature, just add C<Tie::HashHistory> before
C<NDBM_File>:

	my $hh = tie %hash => Tie::HashHistory, 
		NDBM_File, 'database', $flags, $mode;

The data will still be stored in C<database>, and it will still be an
C<NDBM> file.  All the fetching and storing will look the same, but
the change history of each key will be available.

The C<tie> call will return an object; to find out the history of a
key, use the C<history> method on this object.  It takes one argument,
which is a key string.  It will return a list of all the values that
have ever been associated with the key, in chronological order,
starting with the most recent.  For example:

	$hash{a} = 'first';
	$hash{b} = 'second';
	$hash{a} = 'third';    # Overwrites old value

	# Prints "third second" as you would expect
	print "$hash{a} $hash{b}\n";  

	@values = $hh->history('a');
	# @values now contains ('third', 'first')	

	@values = $hh->history('b');
	# @values now contains ('second')


At present, if called in scalar context, the C<history()> method will
return the number of items in the history.  This behavior may change
in future versions.
	
The underlying hash can be any tied hash class at all.  To use a
regular in-memory hash, use Tie::StdHash (distributed with Perl) as the
underlying implementation:

	use Tie::Hash;  # *NOT Tie::StdHash*
	my $hh = tie %hash => Tie::HashHistory, Tie::StdHash;

This is not as efficient as it could be because fetches and stores on
C<%hash> still go through two layers of tieing.  I may fix this in a
future release. 

=head1 Bugs and Caveats

You cannot use C<delete> on a C<Tie::HashHistory> hash, because it is
not clear yet what it should do.  It could revert the value to the
previous version (this would be easy to implement) or it could record
in the history that the key was deleted.  (This is more difficult.)  A
future version of this package may provide subclasses with one or the
other functionality.

This module needs some more test files.

=head1 Author

Mark-Jason Dominus, Plover Systems

Please send questions and other remarks about this software to
C<mjd-perl-hashhistory@pobox.com>

For updates, visit C<http://www.plover.com/~mjd/perl/HashHistory/>.

Thanks to Randal Schwartz and Chris Nandor for their assistance with
the C<**!!**> line.

=cut

