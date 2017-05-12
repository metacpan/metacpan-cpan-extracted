# Copyright 2001 Simon Wistow <simon@twosortplanks.com>
# Distributed under the same terms as Perl itself

package Tie::Hash::Layered;

require 5.005_62;
use strict;
use warnings;

use Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our $VERSION = '0.9';



# -- Tie ourselves into a hash
# We set up a list of other hashes 
# so that we can check from L to R
sub TIEHASH
{
	# get our class
	my $class = shift;
	
	my $self = {};

	
	# we assume the rest of our arguments are arrays
	$self->{_HASHES} =  \@_;
	$self->{_OFFSET} = 0;
	$self->{_KEYSSEEN} = {};

	return bless $self, $class; 
}


sub FETCH
{
	my ($self, $key) = @_;
	
	# right, we have the key we need to check for
	# so we iterate down our list of arrays and 
 	# check to see if the value exists 

	

	
	foreach my $hashref (reverse @{$self->{_HASHES}})
	{
		return $hashref->{$key} if defined $hashref->{$key};
	}


	# hmm, none of our hashes have that key,
	# /shurg/ (sic), return undef;
	return undef;

}


sub STORE 
{
	my ($self,$key, $value) = @_;


	# this is dead easy, we just store it in the first
	return $self->{_HASHES}->[_get_max($self)]->{$key} = $value;
	


}

sub DELETE 
{
	my ($self, $key) = @_;
	
	# just delete the first key in the the first hash
	my $res = delete $self->{_HASHES}->[_get_max($self)]->{$key};
	return $res;
}

sub CLEAR 
{
	my ($self) = @_;
	my %hash = ();

	
	pop @{$self->{_HASHES}};
	push @{$self->{_HASHES}}, \%hash;

}

sub EXISTS
{
	my ($self, $key) = @_;

	# again with the iteration :)
	

	foreach my $hashref (reverse @{$self->{_HASHES}})
	{
		return 1 if (exists $hashref->{$key});
	}

	return 0;
}

sub FIRSTKEY
{
	my ($self) = @_;



	$self->{_OFFSET} = 0;
	$self->{_KEYSSEEN} = {};
	my $a = keys %{$self->{_HASHES}->[0]};
	each (%{$self->{_HASHES}->[0]});
	

	
}


sub NEXTKEY
{
	my ($self) = @_;

	my $key;


	my %keys = %{$self->{_KEYSSEEN}};

	do
	{
	 	$key = each %{ $self->{_HASHES}->[$self->{_OFFSET}] };
		if (defined $key)
		{
			$key = undef if ($self->{_KEYSSEEN}->{$key}++);
			
		}
		#print "Offset : ".$self->{_OFFSET};
		#print " Key = $key" if (defined $key);
		#print "\n";

	}
	until (defined $key || ++$self->{_OFFSET} >  _get_max($self));

	#return undef if ($self->{_OFFSET}==_get_max($self));
	
	return $key;

}


sub _get_max 
{
	my ($self) = @_;

	my $arrref = $self->{_HASHES};
	my @arr   = @$arrref;

	return $#arr;


}

sub push
{
	my ($self, $val) = @_;
	return push @{$self->{_HASHES}}, $val;
}

sub pop
{
	my ($self) = @_;
	return pop @{$self->{_HASHES}};
}

sub shift
{
	my ($self) = @_;
	return shift @{$self->{_HASHES}};
}

sub unshift
{
	my ($self, $val) = @_;
	return unshift @{$self->{_HASHES}}, $val;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Tie::Hash::Layered - Perl extension for layerable hash values

=head1 SYNOPSIS

  use Tie::Hash::Layered;
  

  my %hash;
  my %test1 = ( foo => 'bar', bob => 'sprite' );
  my %test2 = ( bob => 'joey');

  # tie the new hash with the initialised hashes above
  tie %hash, 'Tie::Hash::Layered', (\%test1, \%test2);

  # because the hash values are layered 
  # left to right is bottom to top so ...
  # $hash{'bob'} eq 'joey' 
  # $hash{'foo'} eq 'bar' 
  # ... which is pretty cool

  $hash{'foo'} = 'flam';
  # this sets 'foo' in the top most layer so ...
  # $hash{'foo'} now eq 'flam' 

  delete $hash{'bob'};

  # this deletes $hash{'bob'} in the top layer so ...
  # $hash{'bob'} now eq 'sprite'

  # let's clear the hash 
  %hash = ();

  # which clears the top layer so that ..
  # $hash{'foo'} now eq 'bar'

  # set foo and quux in the top layer
  $hash{'foo'} = 'flam';
  $hash{'quux'} = 'fleeg';
  
  # the keys of %hash are now ... 
  # foo, bob and  quux notice the lack of duplicates
 
  # setting mutt in the bottom later hash ...
  $test1{'mutt'} = 'ley';
  # ... also sets it in %hash
  # so $hash{'mutt'} eq 'ley'

  $test2{'mutt'} = 'mail';
  # and $hash{'mutt'} now eq 'mail'

  # you can access the stack of hashes 
  # like a normal array ...
  
  tied(%hash}->push( { slub => 'slob' } );
  # $hash{'slub'} eq 'slob'

  tied(%hash)->unshift( { slub => 'slab' } );
  # $hash{'slub'} eq 'slab'

  tied(%hash}->shift();
  # $hash{'slub'} eq 'slob'

  tied(%hash)->pop();
  # $hash{'slub'} is now not defined

  

=head1 DESCRIPTION

This module lets you layer hashes on top of each other
opaquely so that top most layers obscure bottom ones.

Think of it like sheets of OHP transparencies, if a 
value is set in a top and bottom layer then that's 
you when you access that key you get the value from
the top layer but if you access something not set in
the top layer but set in the bottom layer then you
get the value from the bottom layer ...

... and breathe.

In short :

Tied Hash :   foo=>'bob'  , quux=>'fleeg'
                 |              |     
                 ^              |
Layer 1   :   foo=>'bob'        ^
Layer 2   :   foo=>'bar'  , quux=>'fleeg'



So why is this useful? Well, the obvious application
is for preferences. In a CGI app you could tie in the 
bottom most hash to a database with default all-users' 
preferences, the second layer with the current user's 
preferences, the layer above that with the per-session 
preferences and the layer above that with the 
per-request values.

=head1 AUTHOR

Simon Wistow <simon@twoshortplanks.com>

=head1 COPYING

This is distributed under the same terms as Perl itself

=head1 SEE ALSO

L<perl>, L<Tie::Hash> 

=cut

