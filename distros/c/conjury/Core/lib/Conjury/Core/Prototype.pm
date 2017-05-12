# Copyright (c) 1999-2000, James H. Woodyatt
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#   Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in
#   the documentation and/or other materials provided with the
#   distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE. 

require 5.005;
use strict;

package Conjury::Core::Prototype;
use Carp qw/&croak/;

sub new($%) {
    my ($this) = @_;

    croak __PACKAGE__, '::new-- unexpected arguments' if (@_ > 1);
    
    my $class = ref $this || $this;
    $this =
      {Required => { },
       Optional => { }};

    bless $this, $class;
}

sub required_arg {
    my ($this, $key, $value) = @_;
    croak __PACKAGE__, "::required_arg-- '$key' not a SCALAR"
      unless (defined $key and !ref $key);
    croak __PACKAGE__, "::required_arg-- '$value' not a CODE reference"
      unless (defined $value and ref $value eq 'CODE');
    croak __PACKAGE__, "::required_arg-- '$key' already an argument"
      unless (!exists $this->{Required}{$key}
	      and !exists $this->{Optional}{$key});

    $this->{Required}{$key} = $value;
    undef;
}

sub optional_arg {
    my ($this, $key, $value) = @_;
    croak __PACKAGE__, "::optional_arg-- '$key' not a SCALAR"
      unless (defined $key and !ref $key);
    croak __PACKAGE__, "::optional_arg-- '$value' not a CODE reference"
      unless (defined $value and ref $value eq 'CODE');

    $this->{Optional}{$key} = $value;
    undef;
}

sub validate {
    my ($this, $argvref) = @_;
    croak __PACKAGE__, "::validate-- argument mismatch"
      unless (ref $this
	      and defined $argvref
	      and ref $argvref eq 'HASH'
	      and $this->UNIVERSAL::isa('Conjury::Core::Prototype'));

    my $result = undef;

    if (scalar keys %$argvref) {
	my ($key, $value);

	my %required_arg = %{$this->{Required}};
	my %optional_arg = %{$this->{Optional}};

	while (($key, $value) = each %$argvref) {
	    unless (exists $this->{Required}{$key}
		    or exists $this->{Optional}{$key}) {
		$result = "'$key' unexpected argument";
		last;
	    }

	    my $function = undef;
	    if (exists $required_arg{$key}) {
		$function = $required_arg{$key};
		delete $required_arg{$key};
	    }
	    elsif (exists $optional_arg{$key}) {
		$function = $optional_arg{$key};
		delete $optional_arg{$key};
		next if (!defined $value);
	    }
	    else {
		$result = "'$key' used multiple times";
		last;
	    }

	    my $error = &$function($value);
	    if ($error) {
		$result = "'$key' $error";
		last;
	    }
	}
    }

    return $result;
}

sub validate_scalar {
    my ($x, $y) = (shift, undef);
    $y = 'not a SCALAR' unless (defined $x and !ref $x);
    return $y
}

sub validate_hash {
    my ($x, $y) = (shift, undef);
    $y = 'not a HASH' unless (ref $x eq 'HASH');
    return $y
}

sub validate_array {
    my ($x, $y) = (shift, undef);
    $y = 'not an ARRAY' unless (ref $x eq 'ARRAY');
    return $y
}

sub validate_hash_of_scalars {
    my ($x, $y) = (shift, undef);
    $y = 'not a HASH of SCALAR values'
      unless (ref $x eq 'HASH' and !(grep ref, values(%$x))); 
    return $y;
}

sub validate_array_of_scalars {
    my ($x, $y) = (shift, undef);
    $y = 'not an ARRAY of SCALAR values'
      unless (ref $x eq 'ARRAY' and !(grep ref, @$x)); 
    return $y;
}

sub validate_code {
    my ($x, $y) = (shift, undef);
    $y = 'not a CODE' unless (ref $x eq 'CODE');
    return $y
}

1;

__END__

=head1 NAME

Conjury::Core::Prototype - function prototype checking in Conjury

=head1 SYNOPSIS

  require Conjury::Core::Prototype;
  use Carp qw/&croak/;

  $prototype = Conjury::Core::Prototype->new;

  $prototype->required_arg
    (foo_arg1 => sub {
	 my ($x, $y) = (shift, undef);
	 $y = 'not a HASH reference' unless (ref $x eq 'HASH');
	 return $y;
     });

  $prototype->optional_arg
     foo_arg2 => sub {
	 my ($x, $y) = (shift, undef);
	 $y = 'not a CODE reference' unless (ref $x eq 'CODE');
	 return $y;
     });

  sub foo($%) {
      my ($this, %arg) = @_;
      my $error = $prototype->validate(\%arg);
      croak __PACKAGE__, "::foo-- $error" if $error;

      # use $arg{foo_arg1} with confidence that it exists and its value
      # is a HASH reference, and that $arg{foo_arg2} either does not exist,
      # or it exists and its value is a CODE reference.
  }

=head1 DESCRIPTION

The F<Conjury::Core::Prototype> module is a general purpose function
prototype verifier, included in the Conjury distribution as a convenience.

Use the C<Conjury::Core::Prototype->new> method to construct an instance
of the prototype verifier for a particular function.

Use the C<required_arg> method to add a required argument to the function
prototype.  Use the C<optional_arg> method to add an optional argument to the
function prototype.  Both methods require two parameters, the name of the
argument, and a reference to a subroutine that validates the argument and
returns a descriptive message if the argument violates the prototype.

When the C<validate> method is called on the prototype (with a reference to
a hash containing the function arguments), each argument is passed to the
parameter verifier function that was associated with the parameter name
when the prototype was constructed.  If none of the verifiers return a
value then the argument list fits the prototype and the C<validate> method
returns undefined.  Otherwise, the C<validate> method returns an error code
suitable for use in a call to C<croak>.

=head1 AUTHOR

James Woodyatt <F<jhw@wetware.com>>
