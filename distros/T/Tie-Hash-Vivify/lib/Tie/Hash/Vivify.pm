package Tie::Hash::Vivify;

use 5.006001;
use strict;
use warnings;

our $VERSION = "1.04";

sub new {
    my ($class, $defsub, %params) = @_;
    tie my %hash => $class, $defsub, %params;
    \%hash;
}

sub TIEHASH {
    my ($class, $defsub, %params) = @_;
    bless [{}, $defsub, \%params], $class;
}

sub FETCH {
    my ($self, $key) = @_;
    my ($hash, $defsub) = @$self;
    if (exists $hash->{$key}) {
        $hash->{$key};
    }
    else {
        $hash->{$key} = $defsub->();
    }
}

sub STORE {
  my($self, $key, $value) = @_;
  
  # print STDERR "ref(\$value):    ".ref($value)."\n";
  # print STDERR "infect_children: ".($self->[2]->{infect_children} ? 1 : 0)."\n";
  # if(ref($value) eq 'HASH') { print STDERR "tied:            ".!!tied(%{$value})."\n" }
  # print STDERR "\n";
  if(
    ref($value) eq 'HASH' &&
    $self->[2]->{infect_children} &&
    !tied(%{$value})
    # this would re-tie anything except a THV
    # !(tied(%{$value}) && tied(%{$value})->isa(__PACKAGE__))
  ) {
    $self->[0]->{$key} = __PACKAGE__->new($self->[1], %{$self->[2]});
    $self->[0]->{$key}->{$_} = $value->{$_} foreach(keys(%{$value}));
    $self->[0]->{$key};
  } else {
    $self->[0]->{$key} = $value;
  }
}

# copied from Tie::ExtraHash in perl-5.10.1/lib/Tie/Hash.pm
sub FIRSTKEY { my $a = scalar keys %{$_[0][0]}; each %{$_[0][0]} }
sub NEXTKEY  { each %{$_[0][0]} }
sub EXISTS   { exists $_[0][0]->{$_[1]} }
sub DELETE   { delete $_[0][0]->{$_[1]} }
sub CLEAR    { %{$_[0][0]} = () }
sub SCALAR   { scalar %{$_[0][0]} }

1;


=head1 NAME

Tie::Hash::Vivify - Create hashes that autovivify in interesting ways.

=head1 DESCRIPTION

This module implements a hash where if you read a key that doesn't exist, it
will call a code reference to fill that slot with a value.

=head1 SYNOPSIS

    use Tie::Hash::Vivify;

    my $default = 0;
    tie my %hash => 'Tie::Hash::Vivify', sub { "default" . $default++ };
    print $hash{foo};   # default0
    print $hash{bar};   # default1
    print $hash{foo};   # default0
    $hash{baz} = "hello";
    print $hash{baz};   # hello

    my $hashref = Tie::Hash::Vivify->new(sub { "default" });
    $hashref->{foo};    # default
    # ...

=head1 OBJECT-ORIENTED INTERFACE

You can also create your magic hash in an objecty way:

=head2 new

    my $hashref = Tie::Hash::Vivify->new(sub { "my default" });

=head1 "INFECTING" CHILD HASHES

By default, hashes contained within your hash do *not* inherit magical
vivification behaviour.  If you want them to, then pass some extra
params thus:

  tie my %hash => 'Tie::Hash::Vivify', sub { "default" . $default++ }, infect_children => 1;

  my $hashref = Tie::Hash::Vivify->new(sub { "my default" }, infect_children => 1);

This will not, however, work if the child you insert is already tied - that
would require re-tieing it, which would lose whatever magic behaviour the
original had.

=head1 BUGS

C<scalar(%tied_hash)> appears to not work properly on perl 5.8.2 and
earlier. I don't really care, and frankly nor should you. In the
unlikely event that you do care, please submit a patch.

=head1 AUTHORS

Luke Palmer, lrpalmer gmail com (original author)

David Cantrell E<lt>david@cantrell.org.ukE<gt> (current maintainer)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Luke Palmer

Some parts Copyright 2010 David Cantrell E<lt>david@cantrell.org.ukE<gt>.

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut
