package Tie::UrlEncoder;

use 5.006;
no warnings;

our $VERSION = '0.02';

# sub PACK(){0};
sub KEY(){1};
# sub VALUE(){2};
my $b;
sub TIEHASH{bless \$b}
sub FETCH{
	my $result = $_[KEY];
	use bytes;
	$result =~ s{([^ 0-9a-zA-Z\$\-_\.\!\*\(\)\,])}
		    {sprintf("%%%02X",ord($1))}ge;
        no bytes;
	$result =~ tr/ /+/;
	$result
}

sub import{ no strict;
	tie %{caller().'::urlencode'}, __PACKAGE__
}


1;
__END__

=head1 NAME

Tie::UrlEncoder - interpolatably URL-encode strings

Syntactic sugar for URL-Encoding strings. Tie::UrlEncoder imports
a tied hash C<%urlencode> into your package, which delivers a RFC 1738
URL Encoded string of whatever is given to it, for easy embedding
of URL-Encoded strings into doublequoted templates.

=head1 SYNOPSOZAMPLE

  our %urlencode;	# make use strict happy
  use Tie::UrlEncoder 0.01; # import ties %urlencode
  ...
  print "To add $id to your list, click here:\n";
  print "http://listmonger.example.com/listadd?id=$urlencode{$id}\n";

=head1 DESCRIPTION

No longer must you clutter up your CGI program with endless repetitions
of line noise code that performs this tricky function.  Simply use
Tie::UrlEncoder and you instantly get a magic C<%urlencode> hash that
gives you an Url Encoded version of the key:
C<$urlencode{$WhatYouWantToEncode}> is ready to interpolate in double-quoted
literals without messy intermediate variables.

=head1 EXPORT

you get C<our %urlencode> imported into your package by default.

Defeat this wanton pollution (perhaps if you already have something
called C<%urlencode>)
by invoking C<use> with an empty list and tieing a different hash.

  use Tie::UrlEncoder 0.01 ();
  tie my %MagicUrlEncodingHash, 'Tie::UrlEncoder';
  ...
  qq( <a href="add_data.pl?data=$MagicUrlEncodingHash{$SpecialData}">
      Click here to add your special data <em>$SpecialData</em></a> );

=head1 HISTORY

=head2 0.01

I was setting this up for a project I am working on and
thought, it's useful in general so why not publish it.

=head2 0.02

silence a warning that has appeared with 5.10 (rt #35807)

=head1 A Companion Piece

A hash-tieing interface for HTML escapes 
is available as L<HTML::Entities::Interpolate>

=head2 I18n

RFC 1738 says:

   In addition, octets may be encoded by a character triplet consisting
   of the character "%" followed by the two hexadecimal digits (from
   "0123456789ABCDEF") which forming the hexadecimal value of the octet.
   (The characters "abcdef" may also be used in hexadecimal encodings.)

   Octets must be encoded if they have no corresponding graphic
   character within the US-ASCII coded character set, if the use of the
   corresponding character is unsafe, or if the corresponding character
   is reserved for some other interpretation within the particular URL
   scheme.

so, 0.2 includes a C<use bytes> before the substitution operator.  Research indicates that
the C<bytes> pragma first appeared in 5.006, which is the version of perl that v0.01
wants already, so the techniques at L<http://www.perlmonks.org/?node_id=294501> are not
needed.

=head1 AUTHOR

Copyright (C) 2004, 2009 david nicol davidnico@cpan.org
released under your choice of the GNU Public or Artistic licenses

=head1 SEE ALSO

Google for "URL Encoding"

RFC 1738

L<URI::Escape>

L<HTML::Mason::Escapes>

=cut
