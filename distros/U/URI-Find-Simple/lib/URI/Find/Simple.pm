package URI::Find::Simple;
use warnings;
use strict;
use 5.006;

use URI::Find;
use Carp qw(croak);
use Encode qw( encode );


our @ISA = qw( Exporter );
our @EXPORT_OK = qw( list_uris change_uris );

our $VERSION = 1.06;

our $CHARSET = "utf-8";

sub list_uris {
  my $text = shift;
  croak "expected a text string" unless defined($text);

  my @list;
  my $uri_find = URI::Find->new( sub {
    my ($object, $text) = @_;
    push @list, $object->as_string;
    return $text;
  } );
  
  if ($CHARSET) {
    my $copy = encode($CHARSET, $text);
    $copy =~ s/([^\000-\177])/'%' . sprintf("%x", ord($1))/eg;
    $text = $copy;
  }
  $uri_find->find(\$text);
  return @list;
}

sub change_uris {
  my $text = shift;
  my $sub = shift;
  croak "expected a text string" unless defined($text);
  croak "expected a code ref" unless ref($sub) eq 'CODE';

  my $uri_find = URI::Find->new( sub {
    my ($object, $text) = @_;
    return $sub->($object->as_string);
  } );
  $uri_find->find(\$text);
  return $text;
}

1;

__END__

=head1 NAME

URI::Find::Simple - a simple interface to URI::Find

=head1 SYNOPSIS

  use URI::Find::Simple qw( list_uris );
  my @list = list_uris($text);

  my $html = change_uris($text, sub { "<a href=\"$_[0]\">$_[0]</a>" } );

=head1 DESCRIPTION

L<URI::Find> is all very well, but sometimes you just want a list of the
links in a given piece of text, or you want to change all the urls in
some text somehow, and don't want to mess with callback interfaces.

This module uses URI::Find, but hides the callback interface, providing two
functions - one to list all the uris, and one to change all the uris.

=head2 list_uris( text )

returns a list of all the uris in the passed string, in the form output by
the URI->as_string function, not the form that they exist in the text.

=head2 change_uris( text, sub { code } )

the passed sub is called for every found uri in the text, and it's return
value is substituted into the string. Returns the changed string.

=head1 CAVEATS, BUGS, ETC

The change_uris function is only just nicer than the callback interface. In
some ways it's worse. I's prefer to just pass an s/// operator somehow, but
I don't think that's possible.

The list_uris function returns the stringified versions of the URI objects,
this seemed to be the sensible thing. To present a consistent interface, the
change_uris function operates on these strings as well, which are not the same
as the strings actually present in the original. Therefore this code:

  my $text = change_uris($text, sub { shift } );

may not return the same thing you pass it. URIs such as <URI:http://jerakeen.org>
will be converted to the string 'http://jerakeen.org'.

=head1 SEE ALSO

L<URI::Find>, L<URI::Find::Iterator>, L<URI>, L<HTML::LinkExtor>, L<HTML::LinkExtractor>.

=head1 REPOSITORY

L<https://github.com/neilbowers/URI-Find-Simple>

=head1 AUTHOR

Tom Insam E<lt>tom@jerakeen.orgE<gt>
inspired by Paul Mison E<lt>paul@husk.orgE<gt>

This module is now maintained by Neil Bowers E<lt>neilb@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004 Tom Insam E<lt>tom@jerakeen.orgE<gt>.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

