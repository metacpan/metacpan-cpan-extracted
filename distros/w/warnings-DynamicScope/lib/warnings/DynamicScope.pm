#!perl -w
# -*- coding: utf-8-unix; tab-width: 4; -*-
package warnings::DynamicScope;

# DynamicScope.pm
# ------------------------------------------------------------------------
# Revision: $Id: DynamicScope.pm,v 1.14 2005/08/15 15:53:59 kay Exp $
# Written by Keitaro Miyazaki<kmiyazaki@cpan.org>
# Copyright 2005 Keitaro Miyazaki All Rights Reserved.

# HISTORY
# ------------------------------------------------------------------------
# 2005-08-15 Version 1.04
# 2005-08-10 Version 1.03
#            - Fixed a bug the value of $^W was not set properly in
#              BEGIN block.
# 2005-08-07 Version 1.02
#            - Defined new package variable named "$DYNAMIC_W_BITS".
#              The tied hash "%^W" no longer accesses to the variable
#              "${^WARNING_BITS}" unless it is accessed in BEGIN block.
#            - Now the variable "%^W" accepts keyword "FATAL" as value.
#              If the value is set to "FATAL", it returns 2 as value.
#            - Added "DEAD BIT", "BEGIN BLOCK", and "$^W AND %W" item
#              in POD document.
#            - Improved handling of the variable "$^W". It's value is
#              always synchronized with the value of "$^W{all}".
#            - Made "%^W" realize "-W" and "-X" command line switches.
# 2005-08-04 Version 1.01
#            - Modified POD document.
#            - Added a few tests.
# 2005-08-04 Version 1.00
#            - Initial version.

use 5.008;
use strict;
use warnings;

our $VERSION  = '1.04';
our $REVISION = '$Id: DynamicScope.pm,v 1.14 2005/08/15 15:53:59 kay Exp $';
our $DEBUG    = 0;

use Symbol::Values 'symbol';

#-------------------------------------------------------------------------
# Functions
#
sub in_begin_block {
	my($func, $i);
	
 	for ($i=2; $func = (caller($i))[3]; ++$i) {
		return 1 if $func =~ /^(?:.*::)?BEGIN$/o;
		next if $func eq '(eval)';
		return 0;
	}
	0
}


#-------------------------------------------------------------------------
# Base module(Tied Hash)
#-------------------------------------------------------------------------
package warnings::DynamicScope::WARNINGS_HASH;
use Tie::Hash;
use base "Tie::Hash";
use Symbol::Values 'symbol';

#-------------------------------------------------------------------------
# Variables
#
our (
	 $r_WARNINGS,		# original value of $^W
	 $LEXICAL_W_BITS,	# alias of ${^WARNING_BITS}
	 $DYNAMIC_W_BITS,	# Warning bits in dynamic scope.
	 %Bits,				# bitmask on/off
	 %DeadBits,			# bitmask if fatal or not.
	 %Offsets,			# bit offset beggining from the string.
	 $W_FLAG,			# if command line switch "-W" is on
	 $X_FLAG,			# if command line switch "-X" is on
	);

#-------------------------------------------------------------------------
# Some aliases
#
BEGIN {
	no warnings 'Symbol::Values';
	symbol('LEXICAL_W_BITS')->glob	= *{^WARNING_BITS};		# $LEXICAL_W_BITS
	symbol('bits')->code			= *warnings::bits;		# bits()
	symbol('in_begin_block')->code	= *warnings::DynamicScope::in_begin_block;
	symbol('Bits')->hash_ref		= *warnings::Bits;		# %Bits
	symbol('DeadBits')->hash_ref	= *warnings::DeadBits;	# %DeadBits # Fatal?
	symbol('Offsets')->hash_ref		= *warnings::Offsets;	# %Offsets
	$DYNAMIC_W_BITS = "";
}

#-------------------------------------------------------------------------
# Code
#
sub TIEHASH {
	my $self;
	my $init_val = $_[1];
	__PACKAGE__->STORE('all', $init_val);
	bless \$self
}

sub FETCH {
	my ($self, $key) = @_;
	return undef unless exists $Bits{$key};

	my $mask;
	if (in_begin_block) {
		$mask = (caller(0))[9];
	} else {
		$mask = $DYNAMIC_W_BITS;
	}
	
	my $flag  = vec($mask, $Offsets{$key}, 1);
    my $fatal = vec($mask, $Offsets{$key}+1, 1);
	
	$DEBUG && printf(STDERR "FETCH(%s): %s = %s (FATAL = %s)\n",
					 in_begin_block() ? 'lex' : 'dyn',
					 $key, $flag, $fatal);
	
	$flag = 0 if $X_FLAG; # Always false if "-X" switch is on.
	$flag = 1 if $W_FLAG; # Always true  if "-W" switch is on.
                          # NOTE: "-W" switch have a priority.

	$flag
		? $fatal ? 2 : 1
		: 0
}

sub STORE {
	my ($self, $key, $value) = @_;
	
	unless (exists $Bits{$key})
		{ warnings::Croaker("Unknown warning category '$key'")}
	
	my $is_pragma = in_begin_block();
	my $mask      = $is_pragma ? $LEXICAL_W_BITS : $DYNAMIC_W_BITS;
	my $fatal     = 0;
	my $no_fatal  = 0;
	
	$DEBUG && printf(STDERR "STORE(%s): %s = %s\n",
					 in_begin_block() ? 'lex' : 'dyn',
					 $key, $value);

	# Check if category will be set FATAL error.
	#
	if ($value && $value eq 'FATAL') {
		$fatal = 1;
	}

	# Set value
	#
	if ($value) {
		$mask |= $Bits{$key};

		# Set DeadBits
		if ($fatal) {
			$mask |= $DeadBits{$key};
		} else {
			$mask &= ~$DeadBits{$key};
		}
	
	# Unet value
	#
	} else {
		if ($is_pragma) {
			# this is just for compatibility...
			$mask &= ~($Bits{$key} | $DeadBits{$key} | $warnings::All);
		} else {
			$mask &= ~($Bits{$key} | $DeadBits{$key});
		}
	}

	# Set value of $^W if necessary.
	#
	if ($key eq 'all') {
		${$r_WARNINGS} = $value ? 1 : 0;
	}

	if ($is_pragma) {
		$LEXICAL_W_BITS = $mask;
	} else {
		$DYNAMIC_W_BITS = $mask;
	}
	
	return vec($mask, $Offsets{$key}, 2)
}

sub FIRSTKEY {
	my $self = shift;
	scalar each %Bits
}

sub NEXTKEY {
	my($self, $lastkey) = @_;
	scalar each %Bits
}

sub EXISTS {
	my($self, $key) = @_;
	exists $Bits{$key}
}

sub DELETE {
	my($self, $key) = @_;

	unless (exists $Bits{$key})
		{ warnings::Croaker("Unknown warning category '$key'")}

	# currently, delete $^W{key} will only disables the value.
	vec($LEXICAL_W_BITS, $Offsets{$key}, 1) = 0
}

sub CLEAR {
	my $self = shift;

	# set all bits and dead bets to 0
	$LEXICAL_W_BITS = $warnings::NONE;

	undef
}

sub SCALAR {
	my $self = shift;

	# this value has no meaning,
	# exists only for compatibility...
	scalar %Bits
}

#-------------------------------------------------------------------------
# $^W
#-------------------------------------------------------------------------
package warnings::DynamicScope::WARNINGS_SCALAR;
use Tie::Scalar ();
use Symbol::Values 'symbol';
use base "Tie::Scalar";

sub TIESCALAR {
	my $dummy;
	bless \$dummy;
}

sub FETCH {
	push(@_, 'all');
	goto &warnings::DynamicScope::WARNINGS_HASH::FETCH;
}

sub STORE {
	splice(@_, 1, 0, 'all');
	goto &warnings::DynamicScope::WARNINGS_HASH::STORE;
}

#-------------------------------------------------------------------------
# Initialize
#-------------------------------------------------------------------------
package warnings::DynamicScope;

my $loaded = 0;

BEGIN {
	unless ($loaded) {
		my $init_value = $^W;

		# Test if "-W" or "-X" flag was passed.
		#
		$W_FLAG = $X_FLAG = 0;

		$^W = 0; $^W && ($W_FLAG = 1);
		$^W = 1; $^W || ($X_FLAG = 1);

		$^W = $init_value;
		
		# Save original $^W
		#
		$r_WARNINGS = symbol('^W')->scalar_ref;
		my $new_val;
		symbol('^W')->scalar_ref = \$new_val;
		
		# Tie $^W and %^W
		#
		tie %^W, "warnings::DynamicScope::WARNINGS_HASH", $init_value;
		tie $^W, "warnings::DynamicScope::WARNINGS_SCALAR";

		$loaded = 1;
	}
}


# This is private function
sub report {
	my $pkg = shift;
	printf("ALL: %d, ^W: %d\n",
		   length($Bits{all}),
		   length(${^WARNING_BITS})
		  );
	if ($pkg) {
		printf("Value for \"%s\" = %d(in Bits: %d, %d/in all: %d, %d)\n",
			   $pkg,
			   $^W{$pkg},
			   vec($Bits{$pkg}, $Offsets{$pkg}, 1),
			   vec($DeadBits{$pkg}, $Offsets{$pkg}+1, 1),
			   vec($Bits{all}, $Offsets{$pkg}, 1),
			   vec($DeadBits{all}, $Offsets{$pkg}+1, 1)
			  );

	}
	foreach my $package (keys %Offsets) {
		printf("%15s[%3d] = %d, bits(%d, %d), bitsin all(%d, %d)\n",
			   $package,
			   $Offsets{$package},
			   $^W{$package},
			   vec($Bits{$package}, $Offsets{$package}, 1),
			   vec($DeadBits{$package}, $Offsets{$package}+1, 1),
			   vec($Bits{all}, $Offsets{$package}, 1),
			   vec($DeadBits{all}, $Offsets{$package}+1, 1)
			  );
	}
}

1;
__END__

=head1 NAME

warnings::DynamicScope - Provides warning categories in dynamic scope.

=head1 SYNOPSIS

  require warnings::DynamicScope;

  package GrandMother;
  use warnings::register;
  
  sub deliver {
      my $self;
      $^W{GrandMother} && warn "You have warned by grandma.";
      bless \$self;
  }
  
  package Mother;
  use base "GrandMother";
  use warnings::register;
  
  sub deliver {
      $^W{Mother} && warn "You have warned by mom.";
      $_[0]->SUPER::deliver();
  }
  
  package main;
  
  $^W = 1;
  $^W{GrandMother} = 0;
  
  my $me = Mother->deliver(); # => You have warned by mom.
  
=head1 DESCRIPTION

This module provides warning categories in dynamic scope
through the special variable "%^W".

=over 4

=item VARIABLE

This modules brings a new special variable called "%^W".
Yes, it is very similar to special variable "$^W"
in appearance, but these are different things.

But you can use it like special variable "$^W":

 require warnings::DynamicScope;

 package MyPkg;
 use warnings::register;
 
 sub my_func {
     if ($^W{MyPkg}) {
         print "Don't do it!!\n";
     } else {
         print "That's fine\n";
     }
 }
 
 package main;
 $^W = 1;

 {
     local $^W{MyPkg} = 0;
     MyPkg::my_func();
 }
 MyPkg::my_func();

This code prints:

 That's fine.
 Don't do it!!

That's all.

=item DEAD BIT

Each warning category has extra property called "Dead Bit".

The Dead Bit will be set if the string "FATAL" is passed
to the variable "%^W" as it's value for a key, and then 2
will be returned as the value for a key.

You can use it as blow:

 require warnings::DynamicScope;
 
 package MyPkg;
 use warnings::register;
 use Carp qw(carp croak);
 
 sub func1 {
     if ($^W{MyPkg} == 2) {
        # Dead Bits is on.
         croak("Fatal Error!\n");
 
     } elsif ($^W{MyPkg}) {
         carp("Non Fatal Error!\n");
     }
 }
 
 package main;
 
 $^W{MyPkg} = 'FATAL';    # Set Dead Bit.
 eval { MyPkg::func1() };
 print $@;                # => Fatal Error!
 
 $^W{MyPkg} = 1;          # Set warning bit of category "MyPkg".
 MyPkg::func1();          # => Non Fatal Error!
 
 $^W{MyPkg} = 0;          # Clear all of the bits.
 MyPkg::func1();          # <nothing happens>

=item BEGIN BLOCK

If the variable "%^W" was used in "BEGIN" block,
it behaves as compiler directive.

So, if you write like:

 BEGIN {
   $^W{uninitialized} = 0;
 }

it brings same result of:

 no warnings 'uninitialized';

=over 4

=item NOTE

All of categories predefined in Perl does not
understand warning bits in dynamic scope, so they
won't work unless it was set by warnings pragma.

=back

=item $^W AND %^W

The values of variables $^W and %^W are linked internally
by the keyword 'all':

 $^W = 1;       # is equal to $^W{all} = 1;
 $^W = 0;       # is equal to $^W{all} = 0;
 
 $^W{all} = 1;  # is equal to $^W = 1;
 $^W{all} = 0;  # is equal to $^W = 0;

=back

=head2 OBJECTIVE

The reason why I decided to write a new module which
provides capability similar to warnings pragma
is that I found the limitation of "warnings::enabled"
and "warnings::warnif" function.

While I'm writing my module, I noticed that the code like
below will not work as I intended:

  use warnings;
  
  package GrandMother;
  use warnings::register;
  
  sub deliver {
      my $self;
      warnings::warnif("GrandMother", "You have warned by grandma.");
      bless \$self;
  }
  
  package Mother;
  use base "GrandMother";
  use warnings::register;
  
  sub deliver {
      warnings::warnif("Mother", "You have warned by mom.");
      $_[0]->SUPER::deliver();
  }
  
  package main;
  no warnings "GrandMother";
  no warnings "Mother";
  
  my $me = Mother->deliver(); # => You have warned by grandma.

In this code, I intended to inhibit warning messages from each
class "GrandMother" and "Mother".

But, if I run this code, warning in "GrandMother" class will be
emitted. So that means the information by pragma
'no warnings "GrandMother"' would not be passed to "GrandMother"
class properly.

I thought this comes from nature of these function that
these functions uses warnings information in static scope.
(They gets static scope information from stack of caller function.)

So, I started write this module to make warning categories
work with dynamic scope.

=head2 TIPS

If you don't like Perl's variable abbreviation like $^W,
try:

 use English qw(WARNING);

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over 4

=item perllexwarn

Documentation about lexical warnings.

=item warnings

You can use warning categories based on lexical scope,
by using functions "warnings::enabled", etc.

=item warnings::register

You can make your warning category with "warnings::register"
pragma.

=back

=head1 AUTHOR

Keitaro Miyazaki, E<lt>kmiyazaki@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Keitaro Miyazaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
