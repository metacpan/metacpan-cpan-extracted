package WWW::MSA::Hadith;

# $Id: Hadith.pm,v 1.3 2003/06/21 09:03:22 sherzodr Exp $

use strict;
use Carp;
use vars qw($VERSION $PROXY $HADITH_URLF);

$VERSION     = '1.01';
$PROXY       = 'http://www.usc.edu/cgi-bin/msasearch';
$HADITH_URLF = 'http://www.usc.edu/dept/MSA/fundamentals/hadithsunnah/%s/%03d.sbt.html';


# Preloaded methods go here.



sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    _USER_AGENT => undef,
    _QUERY      => "",
    _RESULTS    => [],
  };

  return bless ($self, $class);
}



sub DESTROY { }


sub query {
  my ($self, $str) = @_;

  if ( defined $str ) {
    $self->{_QUERY} = $str;
  }

  return $self->{_QUERY};
}


sub submit {
  my $self = shift;

  unless ( defined $self->query ) {
    croak "You didn't call query() yet";
  }

  my $user_agent = $self->user_agent();
  my %form_ref = (
    querystring => $self->query(),
    database    => 'bukhari',
    dbpath      => '/www/dept/MSA/reference/indices',
    logpath     => '/www/dept/MSA/reference/indices/logfile',
    xpath       => '/www/dept/MSA/reference/xfile'
  );

  my $response = $user_agent->post($PROXY, \%form_ref);
  if ( $response->is_error ) {
    croak "couldn't fetch the results: " . $response->status_line;
  }

  $self->{_CONTENT} = $response->content_ref;
  return $self->_parse_response($response);
}



sub _parse_response {
  my ($self, $response) = @_;

  my $content = ${$self->{_CONTENT}};

  require HTML::TreeBuilder;
  my $html = new HTML::TreeBuilder();
  $html->parse($content);

  for my $a ( $html->look_down(\&_is_hadith) ) {
    my $href = $a->attr('href');
    my $abs_href = URI->new_abs($href, $response->base);
    my $id = $abs_href->fragment;
    my ($volume, $book, $report) = $id =~ m/^(\d+)\.(\d+)\.(\d+w?)/;

    push @{$self->{_RESULTS}}, {
      id => $id,
      url => $abs_href->as_string,
      book => $book,
      volume => $volume,
      report => $report
    };
  }
  $html->delete();
}






sub get_result {
  my $self = shift;

  return shift @{$self->{_RESULTS}};
}



sub read {
  my ($self, $id) = @_;

  my $text = "";

  my ($volume, $book, $report) = $id =~ m/^(\d+)\.(\d+)\.(\d+\w?)$/;
  my $url = sprintf($HADITH_URLF, 'bukhari', $book);

  my $user_agent = $self->user_agent();
  my $response = $user_agent->get($url);
  if ( $response->is_error ) {
    die $response->status_line;
  }
  require HTML::TokeParser;
  my $html = HTML::TokeParser->new($response->content_ref) or die $!;

  my $header = 0;
  my $inside = 0;
  while ( my $token = $html->get_token() ) {
    if ( !$header && ($token->[0] eq 'S') && ($token->[1] eq 'a')
            && ($token->[2]->{name}) && ($token->[2]->{name} eq $id) ) {
      $header = 1;
      next;
    }
    $header or next;
    if ( ($token->[0] eq 'E') && ($token->[1] eq 'blockquote') ) {
      $header = 0;
      $inside = 0;
      last;
    }
    if ( ($token->[0] eq 'S') && ($token->[1] eq 'blockquote') ) {
      $inside = 1;
      next;
    }
    $inside or next;

    if ( ($token->[0] eq 'S') && ($token->[1] eq 'p') ) {
      $text .= "\n";
    } elsif ( $token->[0] eq 'T' ) {
      $text .= $token->[1];
    }
  }
  return $text;
}



sub result_count {
  my $self = shift;

  unless ( $self->{_RESULTS} ) {
    return 0;
  }
  return scalar @{$self->{_RESULTS}};
}


sub _is_hadith {
  my $el = shift;

  $el->tag() eq 'a' or return;
  $el->attr('href') or return;

  return $el->attr('href') =~ m!bukhari!;
}










sub user_agent {
  my $self = shift;

  if ( defined $self->{_USER_AGENT} ) {
    return $self->{_USER_AGENT};
  }
  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new(from => 'sherzodr@handalak.com');
  $ua->agent( sprintf("%s (%s/%s)", $ua->agent(), ref($self), $self->VERSION) );

  $self->{_USER_AGENT} = $ua;
  return $self->user_agent();
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

WWW::MSA::Hadith

=head1 SYNOPSIS

  use WWW::MSA::Hadith;

  my $h = new WWW::MSA::Hadith();
  $h->query('(paradise or heaven) and laugh and man and last');
  $h->submit();

  while ( my $result = $h->get_result() ) {
    print $h->read( $result->{id} );
    print "-" x 32;
    print "\n";
  }

=head1 DESCRIPTION

WWW::MSA::Hadith is Perl interface to MSA-USC's Classic Hadith Search engine
located at http://www.usc.edu/dept/MSA/reference/searchhadith.html

As of this release, only Sahih Bukhari database is supported. Will try to
add other databases in subsequent releases.

=head1 PROGRAMMING STYLE

Searching Hadith database is very straight-forward, and consists of the following
steps:

=over 4

=item 1

Create WWW::MSA::Hadith object:

  my $h = new WWW::MSA::Hadith();

=item 2

Define the search query:

  $h->query("warn and peace");

=item 3

Submit the search to remote server:

  $h->submit();

=item 4

Iterate through the results:

  while (my $result = $h->get_result() ) {
    # do something....
  }

=back

get_result() method, as seen above, results the next result fetched from the
database. To iterate over all the results, you should use it in a while() loop or
alternative.

Return value of get_result() is a reference to a hash-table. Hash consists of such
keys as I<id> - unique id for the returned Hadith, I<url> - address of the resource,
I<volume> - volume number of the hadith, I<book> - book number of the hadith and I<report> -
report number of the hadith.

As you noticed, returned result does not include the full content. To fetch the full content
for a specific hadith, you need to call read() method and pass it I<id> field of the result:

  $full_text = $h->read($result->{id});

To view the demo of this library, send an e-mail to hadith@handalak.com and submit the
search keyword in the subject of the mail. You will receive the results in the reply.

result_count() method can be used to retrieve how many results were fetched.
user_agent()   method returned UserAgent object, although you may not need it. In case you do,
here it is.

=head1 TODO

I've been thinking of creating better programming interface through XML-RPC API.

=head1 SEE ALSO

http://www.usc.edu/dept/MSA/reference/searchhadith.html

=head1 AUTHOR

Sherzod B. Ruzmetov, E<lt>sherzodr@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Sherzod B. Ruzmetov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
