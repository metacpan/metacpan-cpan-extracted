package Tie::Static;

use Exporter;
@EXPORT_OK = 'static';
@ISA = 'Exporter';
$VERSION = 0.04;

use strict;
use vars qw(%call_count);
use Carp;

sub static {
  my $call = join "|", caller();
  
  if ($call_count{$call}) {
    tie_all($call, @_);
  }
  else {
    my @init = map {
      (ref($_) eq "SCALAR" or ref($_) eq "REF") ? $$_
        : (ref($_) eq "ARRAY") ? [@$_]
        : (ref($_) eq "HASH") ? { %$_ }
        : bad_ref($_);
    } @_;
    
    tie_all($call, @_);
    
    foreach my $to_replace(@_) {
      my $saved = shift @init;
      if (ref($to_replace) eq "SCALAR" or ref($to_replace) eq "REF") {
        $$to_replace = $saved;
      }
      elsif (ref($to_replace) eq "ARRAY") {
        @$to_replace = @$saved;
      }
      elsif (ref($to_replace) eq "HASH") {
        %$to_replace = %$saved;
      }
      else {
        $Carp::Verbose = 1;
        bad_ref($to_replace);
      }
    }
  }
  
  return $call_count{$call}++;
}

# The first argument is the value of $called to use, the
# rest are references to the variables to tie.  It ties
# the variables to the appropriate static.
sub tie_all {
  my $call = shift;
  my $uniq = 0;
  for (@_) {
    if (ref($_) eq "SCALAR" or ref($_) eq "REF") {
      tie ($$_, 'Tie::Static::Scalar', $call, $uniq++);
    }
    elsif (ref($_) eq "ARRAY") {
      tie (@$_, 'Tie::Static::Array', $call, $uniq++);
    }
    elsif (ref($_) eq "HASH") {
      tie (%$_, 'Tie::Static::Hash', $call, $uniq++);
    }
    else {
      bad_ref($_);
    }
  }
}  

# Message for a bad reference in the argument.
sub bad_ref {
  my $thing = shift;
  if (my $ref = ref($thing)) {
    croak("Cannot create static of unknown type $ref");
  }
  else {
    croak("Arguments to static must be references!");
  }
}

# Implement the ties
foreach my $type (qw(Hash Array Scalar)) {
  my $meth = uc($type);
  my $pack = "Tie::Static::$type";
  eval qq(
    package $pack;
    require Tie::$type;
    \@$pack\::ISA = 'Tie::Std$type';
    
    sub TIE$meth {
      my \$class = shift;
      my \$call = join "|", \@_ ? \@_ : caller();
      return \$$pack\::preserved{\$call}
        ||= \$class->SUPER::TIE$meth();
    }
    
    sub Tie::Static::TIE$meth {
      shift;
      unshift \@_, 'Tie::Static::$type';
      goto &$pack\::TIE$meth;
    }
    
  ) or die $@;
}

1;

__END__

=head1 NAME

Tie::Static - create static lexicals

=head1 SYNOPSIS

  # The tie-based approach
  use Tie::Static;
  sub foo {
    tie (my $static_scalar, 'Tie::Static');
    tie (my @static_array, 'Tie::Static');
    tie (my %static_hash, 'Tie::Static');
    # do whatever you want
  }
  
  # The function call approach
  use Tie::Static qw(static);
  sub bar {
    static \ my ($scalar, @array, %hash);
    # etc
  }

=head1 DESCRIPTION

This module makes it easy to produce static variables.

A static variable is a variable whose value will remain
constant from invocation to invocation.  The usual way
to produce this is to create an enclosing scope which
contains a lexically scoped variable.  For instance the
first example could be written as:

  {
    my $static_scalar;
    my @static_array;
    my %static_hash;
    
    sub foo {
      # Do whatever you want
    }
  }

But while this works, many people find it cumbersome
to have to produce new scopes manually just to get a
static variables.  This module provides an alternate
solution by providing a way to make lexical variables
be what they used to be.

There are two interfaces.  The low-level interface is
to I<tie> your variable directly.  But most of the time
you will want to use the exportable I<static> function.

If you I<tie> and do not pass any arguments, it will use
the feedback from caller() to decide whether to tie
you to a fresh variable, or whether to hand you back
an old one.  If you pass the I<tie> arguments, it will
join them with "|" and use that key to decide what
object to hand you back.  This allows you to create
static variables which are shared between functions in
any way you want.

What I<static> does is take a list of references to
variables, tie them, and then report how many
times they were previously tied.  If the variables had
not been tied before, I<static> will initialize the tied
variables to the values they had before being tied.
Therefore if you want to have default values for your
static variables you can either initialize them before
calling I<static>, or do the initialization if I<static>
returns a false value.  Here are examples:

  # Pre-initializing a static.
  my @array = 1..10;
  my %hash = (Hello => "World", Greetings => "Earthlings");
  static \(@array, %hash);
  
  # Testing the return of static
  my $handle;
  unless (static(\$handle)) {
    $handle = complex_initialization();
  }
  
  # Initializing while calling, only works with scalars
  static \(my $foo = "Hello", my $bar = "World");

=head1 LIMITATIONS AND NOTES

This module relies on the output of [caller] to decide
which value to give back.  Specifically, it makes its
decisions based on Perl's idea of the current package,
filename, and line-number.  Normally this is correct.
But sometimes it is wrong.  And occasionally it is
very wrong.  It is correct if there is only one call
on any given line, and you want that call to always
give you back the same values.  It is wrong if you
put 2 separate calls to I<static> or try to I<tie>
the same data-type twice on one line.  It is very wrong
if you want to play with closures.  It has no way to
distinguish them.

This only allows static scalars, arrays, and hashes.

If you want to overload the implementation of a static,
please note that scalars, arrays, and hashes are not
tied to the package Tie::Static.  Instead they are tied
to the private packages Tie::Static::Scalar,
Tie::Static::Array, and Tie::Static::Hash.

=head1 CREDITS

Thanks go to several people at http://www.perlmonks.org
for discussions on how to implement this and what the
API should look like.  In particular "MeowChow" for
analyzing the gotchas that people need to be aware of.
Jeff "japhy" Pinyan (japhy@pobox.com) for discussion on
implementations and the idea of I<static>.  And
"HyperZonk" and Charles "Wog" Reiss for general
discussion.  The idea of initializing scalars as you
call I<static> is Wog's.

And a particular note should be made of all of the
people on p5p, PerlMonks, and elsewhere who saw the
behaviour of

  my $foo if 0;

as a feature rather than a bug.  Without you I would not
have been inspired to write an (intentional)
implementation of statics for Perl.

=head1 TODO

Add tests for the improvements since version 0.01.

=head1 ACKNOWLEDGEMENTS

My thanks for useful discussions on the API and features
with posters at perlmonks, particularly including
MeowChow and japhy.  See
http://www.perlmonks.org/index.pl?node_id=96832.

=head1 AUTHOR AND COPYRIGHT

Ben Tilly (btilly@gmail.com)

Copyright 2001-2003.  This may be modified and distributed
on the same terms as Perl.
