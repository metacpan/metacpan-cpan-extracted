package Tie::Function;

use 5.006;
# use strict;
# use warnings;
no warnings;  # slience "split on uninitialized value" when $_[key] is uninit

our $VERSION = '0.02';
use Carp;

sub OBJ(){0};
sub KEY(){1};
sub TIEHASH{
	ref $_[1] eq 'CODE'
	or croak "Tie argument must be a CODE reference";
	bless $_[1];
}
sub FETCH{
	&{$_[OBJ]}(split /$;/,$_[KEY]);
}

1;
__END__

=head1 NAME

Tie::Function - wrap functions in tied hash sugar

=head1 SYNOPSIS AND EXAMPLE

  use Tie::Function 0.01; 
  tie my %a, Tie::Function => sub{join '_'x$_[0],qw/( | )/};
  print "small: $a{1}\nmedium: $a{2}\nwide: $a{3}\n"; 
  # we split on $; to recover multiple arguments
  tie my %times, Tie::Function => sub{
	$_[0] * $_[1]
  };
  print "3 times 5 is $times{3,5}\n"

=head1 DESCRIPTION

Tie::Function simplifies wrapping functions in tied hash syntax
so they can be interpolated in double-quoted
literals without messy intermediate variables.

Here's how I use it the most:

   use HTML::Entities;
   use Tie::Function;
   tie my %Entitize => 'Tie::Function' => \&encode_entities;
   ...
   print <<EOF;
   <em>$Entitize{$somethingaboutsomething}</em><br>
   <textarea name="something"
   cols="60" rows="10">$Entitize{$something}</textarea>
   EOF
   ...

=head1 EXPORT

nothing

=head1 HISTORY

=head2 0.01

initial version

=head2 0.02

relaxed stricture, turned off warnings
to silence "split on unitialized value"
warning

=head1 AUTHOR

Copyright (C) 2004,2005 david nicol davidnico@cpan.org
released under your choice of the GNU Public or Artistic licenses

=head1 SEE ALSO

L<perltie>

L<Tie::OneOff>

L<Interpolation>

L<Tie::Filter>

L<overload>

=cut

