package WWW::LEO;

use 5.008;
use warnings;
use strict;

use Carp;
use LWP::UserAgent;
use URI::Escape;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ();
our @EXPORT_OK = ();
our @EXPORT = qw();
our $VERSION = '0.01';

sub new {

  my ($proto, $args) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless ($self, $class);
  $self->reset;

  # set user agent string to something reasonable
  $self->{ua} = LWP::UserAgent->new(
				    agent => "Mozilla/5.0 (compatible; WWW::LEO/$VERSION)"
				   );

  # XXX[incorporate more args]
  # process args supplied to constructor
  if (defined $args) {
    $self->agent->agent($args->{agent}) if exists $args->{agent};
  }

  $self->{req} = HTTP::Request->new('GET');

  return $self;

}

sub agent {

  return $_[0]->{ua};

}

sub request {

  return $_[0]->{req};

}

sub response {

  return $_[0]->{res};

}

sub num_results {

  return $_[0]->{num_results};

}

sub maxlen_en {

  return $_[0]->{maxlen_en};

}

sub maxlen_de {

  return $_[0]->{maxlen_de};

}

sub en {

  return $_[0]->{en};

}

sub de {

  return $_[0]->{de};

}

sub en_de {

  return $_[0]->{en_de};

}

sub query {

  my ($self, $query) = @_;

  return $self->{query} unless defined $query;

  $self->reset;
  $self->{query} = $query;

  $query = uri_escape($query);
  $self->{req}->uri("http://dict.leo.org/?search=$query&relink=off");
  $self->{res} = $self->{ua}->request($self->request);

  if ($self->{res}->is_success) {

    $self->_parse_response;

  }

  return $self->{num_results};

}

sub reset {

  my $self             = shift;
  $self->{query}       = undef; # query string
  $self->{num_results} = undef; # number of results
  $self->{maxlen_en}   = undef; # length of longest string in English results
  $self->{maxlen_de}   = undef; # length of longest string in German results
  $self->{en}          = [];    # English results (array)
  $self->{de}          = [];    # German results (array)
  $self->{en_de}       = [];    # English and German result pairs (array of arrays)
                                # $self->{en_de}[$i][0]: English result
                                # $self->{en_de}[$i][1]: German result

  return $self;

}


sub _parse_response {

  my $self = shift;

  require HTML::TokeParser;
  $self->{tokep} = HTML::TokeParser->new($self->{res}->content_ref) or croak "HTML::TokeParser->new(): $!\n";

 TOKEN:
  while (my $token = $self->{tokep}->get_token) {

    if ($token->[0] eq 'T') {

      my $text = $token->[1];

      for ($text) {

	/no\s+results/ && do {
	  $self->{num_results} = 0;
	  return;
	};

	/search\s+results/ && do {
	  ($self->{num_results}) = $token->[1] =~ /(\d+)/;
	  last TOKEN;
	}

      }

    }

  }

  my ($maxlen_en, $maxlen_de) = (0, 0);

  # extract translations
  while (1) {

    $self->{tokep}->get_tag('/td');

    # get English text
    my $en = $self->{tokep}->get_trimmed_text('/td');
    # fix English text
    $en =~ s/^\xa0\x20//;
    $en =~ s/\x20\xa0$//;
    $maxlen_en = length $en if length $en > $maxlen_en;
    push @{$self->{en}}, $en;

    $self->{tokep}->get_tag('/td');

    # get German text
    my $de = $self->{tokep}->get_trimmed_text('/tr');
    # fix German text
    $de =~ s/^\xa0\x20//;
    $de =~ s/\x20\xa0$//;
    $maxlen_de = length $de if length $de > $maxlen_de;
    push @{$self->{de}}, $de;

    push @{$self->{en_de}}, [$en, $de];

    # skip </tr>
    $self->{tokep}->get_token;

    # are we at end of table yet?
    my $next = $self->{tokep}->get_token;
    $self->{tokep}->unget_token($next) unless $next->[0] eq 'T';
    $next = $self->{tokep}->get_token;
    ($next->[0] eq 'E' and $next->[1] eq 'table') ? last : $self->{tokep}->unget_token($next);

  }

  @$self{qw/maxlen_en maxlen_de/} = ($maxlen_en, $maxlen_de);

  return $self->{num_results};

}

1;
__END__

=head1 NAME

WWW::LEO - Perl interface to the English-German online dictionary at L<http://dict.leo.org>

=head1 SYNOPSIS

  use WWW::LEO;
  use Data::Dumper;

  my $leo = WWW::LEO->new;
  $leo->query("@ARGV");
  if ($leo->num_results) {
    my $i;
    foreach my $resultpair (@{$leo->en_de}) {
      printf "%3d: %-40s %s\n", ++$i, @$resultpair;
    }
  } else {
    print "Sorry, your query for '%s'gave no results.\n", $leo->query;
  }

=head1 DESCRIPTION

This module provides an interface to the English-German online dictionary located at L<http://dict.leo.org>.

=head2 METHODS

=over 4

=item C<new>

This constructs a new C<WWW::LEO> object.  You can pass a hashref with configuration info to the constructor.  Currently recognized key words are:

=over 4

=item C<agent>

sets the user agent string that is used to identify the module

=back

=item C<query>

If a scalar is supplied, queries the dictionary for the string contained within.  Returns the number of results.

If no argument is given, returns the query string of the last query.  Returns C<undef> if no query has been made yet with this object.

=item C<reset>

Resets the C<WWW::LEO> object to the state as if no query had been made.  Returns the resetted C<WWW::LEO> object.

This method shouldn't be used in normal cases.  It's there to provide the possibility of explicitely cleaning up the C<WWW::LEO> object.

=item C<agent>

Returns the C<LWP::UserAgent> object that C<WWW::LEO> uses to query the dictionary.

=item C<request>

Returns the C<HTTP::Request> object that C<WWW::LEO> passes to C<LWP::UserAgent> when quering the dictionary.

=item C<response>

Returns the C<HTTP::Response> object that results from the query to the dictionary.

=item C<num_results>

Returns the number of results of the last query.

Returns C<undef> if no query has been made.

=item C<maxlen_de>

This is a convenience method: returns the longest string in of the English results.

Returns C<undef> if no query has been made.

=item C<maxlen_en>

This is a convenience method: returns the longest string of the German results.

Returns C<undef> if no query has been made.

=item C<en_de>

Returns a reference to an array whose elements are references to arrays containing the English and German result pairs in elements 0 and 1, respectively.

=item C<en>

Convenience method: Returns an array reference containing the English results.

=item C<de>

Convenience method: Returns an array reference containing the English results.

=back

=head2 EXPORT

None, as this is an object-oriented module.

=head1 SEE ALSO

=over

=item *

the L<http://dict.leo.org> homepage

=item *

the sample clients included with this package:

=over 4

=item  F<eg/simpleclient.pl>

for a simple example

=item F<eg/leo.pl>

for a fully-fledged program

=back

=item *

LEO clients written in Perl (not using this module):

=over 4

=item *

L<ftp://ftp.daemon.de/scip/Scripts/leo>

=item *

L<http://cgi.xwolf.de/perl/leo.txt>

=item *

L<http://scripts.irssi.de/html/leodict.pl.html> (this is a plugin script for
the C<irssi> IRC client, see L<http://www.irssi.org>)

=back

=back

=head1 KNOWN BUGS AND OTHER ISSUES

=over 4

=item *

The parsing scheme used to extract the results could probably be improved to be more robust.

=back

=head1 TODO

=over 4

=item *

implement more robust parsing scheme

=item *

provide more flexibility for the user (constructor options, ...)

=item *

implement support for headlines ("Direct Matches (+ Prepositions)",  "Composed Entries", ...) and other LEO options (see the web page)

Also see the F<TODO> file contained in the module distribution.

=back

=head1 SUPPORT

Please contact the current maintainer of this module to report any
bugs or suggest changes to this module:

JE<ouml>rg Ziefle E<lt>ziefle@cpan.orgE<gt>

=head1 AUTHOR

JE<ouml>rg Ziefle E<lt>ziefle@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by JE<ouml>rg Ziefle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
