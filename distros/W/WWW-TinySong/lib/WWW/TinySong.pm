package WWW::TinySong;

=head1 NAME

WWW::TinySong - Get free music links from tinysong.com

=head1 SYNOPSIS

  # basic use

  use WWW::TinySong qw(search);

  for(search("we are the champions")) {
      printf("%s", $_->{songName});
      printf(" by %s", $_->{artistName});
      printf(" on %s", $_->{albumName}) if $_->{albumName};
      printf(" <%s>\n", $_->{tinysongLink});
  }

  # customize the user agent

  use LWP::UserAgent;

  my $ua = new LWP::UserAgent;
  $ua->timeout(10);
  $ua->env_proxy;

  WWW::TinySong->ua($ua);

  # customize the service

  WWW::TinySong->service('http://tinysong.com/');

  # tolerate some server errors

  WWW::TinySong->retries(5);

=head1 DESCRIPTION

tinysong.com is a web app that can be queried for a song and returns a tiny
URL, allowing you to listen to the song for free online and share it with
friends.  L<WWW::TinySong> is a Perl interface to this service, allowing you
to programmatically search its underlying database.

=cut

use 5.006;
use strict;
use warnings;

use Carp;
use Exporter;
use CGI;
use HTML::Parser;

our @EXPORT_OK = qw(link search);
our @ISA       = qw(Exporter);
our $VERSION   = '1.01';

my($ua, $service, $retries);

=head1 FUNCTIONS

The do-it-all function is C<search>.  If you just want a tiny URL, use C<link>.
These two functions may be C<import>ed and used like any other function. 
C<call> and C<parse> are provided so that you can (hopefully) continue to use
this module if the tinysong.com API is extended and I'm too lazy or busy to
update, but you will probably not need to use them otherwise.  The other public
functions are either aliases for one of the above or created to allow the
customization of requests issued by this module. 

=over 4

=item link( $SEARCH_TERMS )

=item WWW::TinySong->link( $SEARCH_TERMS )

=cut

sub link {
    unshift @_, __PACKAGE__ # add the package name unless already there
        unless defined($_[0]) && UNIVERSAL::isa($_[0], __PACKAGE__);
    return shift->a(@_);
}

=item WWW::TinySong->a( $SEARCH_TERMS )

Returns the short URL corresponding to the top result of searching with the
specified song and artist name terms or C<undef> if no song was found.

=cut

sub a {
    my($pkg, $search_terms) = @_;
    my $ret = $pkg->call('a', $search_terms);
    $ret =~ s/\s+//g;
    return $ret =~ /^NSF;?$/ ? undef : $ret;
}

=item search( $SEARCH_TERMS [, $LIMIT ] )

=item WWW::TinySong->search( $SEARCH_TERMS [, $LIMIT ] )

=cut

sub search {
    unshift @_, __PACKAGE__ # add the package name unless already there
        unless defined($_[0]) && UNIVERSAL::isa($_[0], __PACKAGE__);
    return shift->s(@_);
}

=item WWW::TinySong->s( $SEARCH_TERMS [, $LIMIT ] )

Searches for the specified song and artist name terms, giving up to $LIMIT
results.  $LIMIT defaults to 10 if not C<defined>.  Returns an array in list
context or the top result in scalar context.  Return elements are hashrefs with
keys C<qw(tinysongLink songID songName artistID artistName albumID albumName
groovesharkLink)> as given by C<parse>.  Here's a quick script to demonstrate:

  #!/usr/bin/perl

  use WWW::TinySong qw(search);
  use Data::Dumper;

  print Dumper search("three little birds", 3);

...and its output on my system at the time of this writing:

  $VAR1 = {
            'artistName' => 'Bob Marley',
            'albumName' => 'Legend',
            'songName' => 'Three Little Birds',
            'artistID' => '139',
            'tinysongLink' => 'http://tinysong.com/eg9',
            'songID' => '1302',
            'albumID' => '97291',
            'groovesharkLink' => 'http://listen.grooveshark.com/song/Three_Little_Birds/1302'
          };
  $VAR2 = {
            'artistName' => 'Bob Marley',
            'albumName' => 'One Love: The Very Best Of Bob Marley & The Wailers',
            'songName' => 'Three Little Birds',
            'artistID' => '139',
            'tinysongLink' => 'http://tinysong.com/lf2',
            'songID' => '3928811',
            'albumID' => '221021',
            'groovesharkLink' => 'http://listen.grooveshark.com/song/Three_Little_Birds/3928811'
          };
  $VAR3 = {
            'artistName' => 'Bob Marley & The Wailers',
            'albumName' => 'Exodus',
            'songName' => 'Three Little Birds',
            'artistID' => '848',
            'tinysongLink' => 'http://tinysong.com/egc',
            'songID' => '3700',
            'albumID' => '2397306',
            'groovesharkLink' => 'http://listen.grooveshark.com/song/Three_Little_Birds/3700'
          };

=cut

sub s {
    my($pkg, $search_terms, $limit) = @_;

    if(wantarray) {
        $limit = 10 unless defined $limit;
    }
    else {
        $limit = 1; # no point in searching for more if only one is needed
    }
    
    my @ret = $pkg->parse($pkg->call('s', $search_terms,
        {limit => $limit}));

    return wantarray ? @ret : $ret[0];
}

=item WWW::TinySong->b( $SEARCH_TERMS )

Searches for the specified song and artist name terms, giving the top result.
I'm not really sure why this is part of the API because the same result can be
obtained by limiting a C<search> to one result, but it's included here for
completeness.

=cut

sub b {
    my($pkg, $search_terms) = @_;
    return ($pkg->parse($pkg->call('b', $search_terms)))[0];
}

=item WWW::TinySong->call( $METHOD , $SEARCH_TERMS [, \%EXTRA_PARAMS ] )

Calls API "method" $METHOD using the specified $SEARCH_TERMS and optional
hashref of extra parameters.  Whitespace sequences in $SEARCH_TERMS will be
converted to pluses.  Returns the entire response as a string.  Unless you're
just grabbing a link, you will probably want to pass the result through
C<parse>.

=cut

sub call {
    my($pkg, $method, $search_terms, $param) = @_;
    croak 'Empty method not allowed' unless length($method);

    $search_terms =~ s/[\s\+]+/+/g;
    $search_terms =~ s/^\+//;
    $search_terms =~ s/\+$//;
    croak 'Empty search terms not allowed' unless length($search_terms);
    my $url = join('/', $pkg->service, CGI::escape($method), $search_terms);

    $param ||= {};
    $param = join('&', map
        { sprintf('%s=%s', CGI::escape($_), CGI::escape($param->{$_})) }
        keys %$param);
    $url .= "?$param" if $param;

    return $pkg->_get($url);
}

=item WWW::TinySong->parse( [ @RESULTS ] )

Parses all the lines in the given list of results according to the specs,
building and returning a (possibly empty) list of hashrefs with the keys
C<qw(tinysongLink songID songName artistID artistName albumID albumName
groovesharkLink)>, whose meanings are hopefully self-explanatory.

=cut

sub parse {
    my $pkg = shift;
    return map {
        /^(http:\/\/.*); (\d*); (.*); (\d*); (.*); (\d*); (.*); (http:\/\/.*)$/
            or croak 'Result in unexpected format';
        {
            tinysongLink    => $1,
            songID          => $2,
            songName        => $3,
            artistID        => $4,
            artistName      => $5,
            albumID         => $6,
            albumName       => $7,
            groovesharkLink => $8,
        }
    } grep { !/^NSF;\s*$/ } map {chomp; split(/\n/, $_)} @_;
}

=item WWW::TinySong->scrape( $QUERY_STRING [, $LIMIT ] )

Searches for $QUERY_STRING by scraping, giving up to $LIMIT results.  $LIMIT
defaults to 10 if not C<defined>.  Returns an array in list context or the
top result in scalar context.  Return elements are hashrefs with keys
C<qw(albumName artistName songName tinysongLink)>.  Their values will be the
empty string if not given by the website.  As an example, executing:

  #!/usr/bin/perl
  
  use WWW::TinySong;
  use Data::Dumper;
  
  print Dumper(WWW::TinySong->scrape("we can work it out", 3));

...prints something like:

  $VAR1 = {
            'artistName' => 'The Beatles',
            'tinysongLink' => 'http://tinysong.com/5Ym',
            'songName' => 'We Can Work It Out',
            'albumName' => 'The Beatles 1'
          };
  $VAR2 = {
            'artistName' => 'The Beatles',
            'tinysongLink' => 'http://tinysong.com/uLd',
            'songName' => 'We Can Work It Out',
            'albumName' => 'We Can Work It Out / Day Tripper'
          };
  $VAR3 = {
            'artistName' => 'The Beatles',
            'tinysongLink' => 'http://tinysong.com/2EaX',
            'songName' => 'We Can Work It Out',
            'albumName' => 'The Beatles 1967-70'
          };

This function is how the primary functionality of the module was implemented in
the 0.0x series.  It remains here as a tribute to the past, but should be
avoided because scraping depends on the details of the response HTML, which may
change at any time (and in fact did at some point between versions 0.05 and
0.06).  Interestingly, this function does currently have one advantage over the
robust alternative: whereas C<search> is limited to a maximum of 32 results by
the web service, scraping doesn't seem to be subjected to this requirement.

=cut

sub scrape {
    my($pkg, $query_string, $limit) = @_;
    if(wantarray) {
        $limit = 10 unless defined $limit;
    }
    else {
        $limit = 1; # no point in searching for more if only one is needed
    }

    my $service = $pkg->service;

    my $response = $pkg->_get(sprintf('%s?s=%s&limit=%d', $service,
        CGI::escape($query_string), $limit));

    my @ret           = ();
    my $inside_list   = 0;
    my $current_class = undef;

    my $start_h = sub {
        my $tagname = lc(shift);
        my $attr    = shift;
        if(    $tagname eq 'ul' 
            && defined($attr->{id})
            && lc($attr->{id}) eq 'results')
        {
            $inside_list = 1;
        }
        elsif($inside_list) {
            if($tagname eq 'span') {
                my $class = $attr->{class};
                if(    defined($class)
                    && $class =~ /^(?:album|artist|song title)$/i) {
                    $current_class = lc $class;
                    croak 'Unexpected results while parsing HTML'
                        if !@ret || defined($ret[$#ret]->{$current_class});
                }
            }
            elsif($tagname eq 'a' && $attr->{class} eq 'link') {
                my $href = $attr->{href};
                croak 'Bad song link' unless defined $href;
                croak 'Song link doesn\'t seem to match service'
                    unless substr($href, 0, length($service)) eq $service;
                push @ret, {tinysongLink => $href};
            }
        }
    };

    my $text_h = sub {
        return unless $inside_list && $current_class;
        my $text = shift;
        $ret[$#ret]->{$current_class} = $text;
        undef $current_class;
    };

    my $end_h = sub {
        return unless $inside_list;
        my $tagname = lc(shift);
        if($tagname eq 'ul') {
            $inside_list = 0;
        }
        elsif($tagname eq 'span') {
            undef $current_class;
        }
    };

    my $parser = HTML::Parser->new(
        api_version     => 3,
        start_h         => [$start_h, 'tagname, attr'],
        text_h          => [$text_h, 'text'],
        end_h           => [$end_h, 'tagname'],
        marked_sections => 1,
    );
    $parser->parse($response);
    $parser->eof;

    for my $res (@ret) {
    	$res = {
    	    albumName    => $res->{album} || '',
    	    artistName   => $res->{artist} || '',
    	    songName     => $res->{'song title'} || '',
    	    tinysongLink => $res->{tinysongLink} || '',
    	};
        $res->{albumName}  =~ s/^\s+on\s//;
        $res->{artistName} =~ s/^\s+by\s//;
    }

    return wantarray ? @ret : $ret[0];
}

=item WWW::TinySong->ua( [ $USER_AGENT ] )

Returns the user agent object used by this module for web retrievals, first
setting it to $USER_AGENT if it's specified.  Defaults to a C<new>
L<LWP::UserAgent>.  If you explicitly set this, you don't have to use a
LWP::UserAgent, it may be anything that can C<get> a URL and return a
response object.

=cut

sub ua {
    if($_[1]) {
        $ua = $_[1];
    }
    elsif(!$ua) {
        eval {
            require LWP::UserAgent;
            $ua = new LWP::UserAgent;
        };
        carp 'Problem setting user agent' if $@;
    }
    return $ua;
}

=item WWW::TinySong->service( [ $URL ] )

Returns the web address of the service used by this module, first setting
it to $URL if it's specified.  Defaults to <http://tinysong.com/>.

=cut

sub service {
    return $service = $_[1] ? $_[1] : $service || 'http://tinysong.com/';
}

=item WWW::TinySong->retries( [ $COUNT ] )

Returns the number of consecutive internal server errors the module will ignore
before failing, first setting it to $COUNT if it's specified.  Defaults to 0
(croak, do not retry in case of internal server error).  This was created
because read timeouts seem to be a common problem with the web service.  The
module now provides the option of doing something more useful than immediately
failing.

=cut

sub retries {
    return $retries = $_[1] ? $_[1] : $retries || 0;
}

=back

=cut

################################################################################

sub _get {
    my($response, $pkg, $url) = (undef, @_);
    for(0..$pkg->retries) {
        $response = $pkg->ua->get($url);
        last if $response->is_success;
        croak $response->message || $response->status_line
            if $response->is_error && $response->code != 500;
    }
    return $response->decoded_content || $response->content;
}

1;

__END__

=head1 BE NICE TO THE SERVERS

Please don't abuse the tinysong.com web service.  If you anticipate making
a large number of requests, don't make them too frequently.  There are
several CPAN modules that can help you make sure your code is nice.  Try,
for example, L<LWP::RobotUA> as the user agent:

  use WWW::TinySong qw(search link);
  use LWP::RobotUA;

  my $ua = LWP::RobotUA->new('my-nice-robot/0.1', 'me@example.org');

  WWW::TinySong->ua($ua);

  # search() and link() should now be well-behaved

=head1 SEE ALSO

L<http://tinysong.com/>, L<LWP::UserAgent>, L<LWP::RobotUA>

=head1 BUGS

Please report them!  The preferred way to submit a bug report for this module
is through CPAN's bug tracker:
L<http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-TinySong>.  You may
also create an issue at L<http://elementsofpuzzle.googlecode.com/> or drop
me an e-mail.

=head1 AUTHOR

Miorel-Lucian Palii, E<lt>mlpalii@gmail.comE<gt>

=head1 VERSION

Version 1.01  (June 26, 2009)

The latest version is hosted on Google Code as part of
L<http://elementsofpuzzle.googlecode.com/>.  Significant changes are also
contributed to CPAN: L<http://search.cpan.org/dist/WWW-TinySong/>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Miorel-Lucian Palii

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
