package Net::LastFMAPI;
use strict;
use warnings;
use v5.10;
use LWP::UserAgent;
use Digest::MD5 'md5_hex';
use JSON::XS;
use YAML::Syck;
use File::Slurp;
use File::Path 'make_path';
use File::HomeDir 'my_home';
use URI;
use Exporter 'import';
our @EXPORT = ('lastfm', 'lastfm_config', 'lastfm_iter');
use Carp;

our $VERSION = "0.63";
our $url = 'http://ws.audioscrobbler.com/2.0/';
our $api_key = 'dfab9b1c7357c55028c84b9a8fb68880';
our $secret = 'd004c86dcfa8ef4c3977b04f558535f2';
our $session_key; # see load_save_sessionkey()
our $ua = new LWP::UserAgent(agent => "Net::LastFMAPI/$VERSION");
our $username; # not important
our $xml = 0;
our $cache = 0;
our $cache_dir = my_home()."/.net-lastfmapi-cache/";
our $sk_savefile = my_home()."/.net-lastfmapi-sessionkey";

sub load_save_sessionkey { # see get_session_key()
    my $key = shift;
    if ($key) {
        write_file($sk_savefile, $key);
    }
    else {
        $key = eval{ read_file($sk_savefile) };
    }
    $session_key = $key;
}

sub lastfm_config {
    my %configs = @_;
    for my $k (qw{api_key secret session_key ua xml cache cache_dir sk_savefile}) {
        my $v = delete $configs{$k};
        if (defined $v) {
            no strict 'refs';
            ${$k} = $v;
        }
    }
    croak "invalid config items: ".join(", ", keys %configs) if keys %configs;
}

sub dumpfile {
    my $file = shift;
    my $json = encode_json(shift);
    write_file($file, $json);
}
sub loadfile {
    my $file = shift;
    my $json = read_file($file);
    decode_json($json);
}
#{{{
our $methods = {
    'album.addtags' => {auth => 1, post => 1, signed => 1, id => 302},
    'album.getbuylinks' => {id => 429},
    'album.getinfo' => {id => 290},
    'album.getshouts' => {page => 1, id => 450},
    'album.gettags' => {auth => 1, signed => 1, id => 317},
    'album.gettoptags' => {id => 438},
    'album.removetag' => {auth => 1, post => 1, signed => 1, id => 314},
    'album.search' => {page => 1, id => 357},
    'album.share' => {auth => 1, post => 1, signed => 1, id => 436},
    'artist.addtags' => {auth => 1, post => 1, signed => 1, id => 303},
    'artist.getcorrection' => {id => 446},
    'artist.getevents' => {page => 1, id => 117},
    'artist.getimages' => {page => 1, id => 407},
    'artist.getinfo' => {id => 267},
    'artist.getpastevents' => {page => 1, id => 428},
    'artist.getpodcast' => {id => 118},
    'artist.getshouts' => {page => 1, id => 397},
    'artist.getsimilar' => {id => 119},
    'artist.gettags' => {auth => 1, signed => 1, id => 318},
    'artist.gettopalbums' => {page => 1, id => 287},
    'artist.gettopfans' => {id => 310},
    'artist.gettoptags' => {id => 288},
    'artist.gettoptracks' => {page => 1, id => 277},
    'artist.removetag' => {auth => 1, post => 1, signed => 1, id => 315},
    'artist.search' => {page => 1, id => 272},
    'artist.share' => {auth => 1, post => 1, signed => 1, id => 306},
    'artist.shout' => {auth => 1, post => 1, signed => 1, id => 408},
    'auth.getmobilesession' => {signed => 1, id => 266},
    'auth.getsession' => {signed => 1, id => 125},
    'auth.gettoken' => {signed => 1, id => 265},
    'chart.gethypedartists' => {page => 1, id => 493},
    'chart.gethypedtracks' => {page => 1, id => 494},
    'chart.getlovedtracks' => {page => 1, id => 495},
    'chart.gettopartists' => {page => 1, id => 496},
    'chart.gettoptags' => {page => 1, id => 497},
    'chart.gettoptracks' => {page => 1, id => 498},
    'event.attend' => {auth => 1, post => 1, signed => 1, id => 307},
    'event.getattendees' => {page => 1, id => 391},
    'event.getinfo' => {id => 292},
    'event.getshouts' => {page => 1, id => 399},
    'event.share' => {auth => 1, post => 1, signed => 1, id => 350},
    'event.shout' => {auth => 1, post => 1, signed => 1, id => 409},
    'geo.getevents' => {page => 1, id => 270},
    'geo.getmetroartistchart' => {id => 421},
    'geo.getmetrohypeartistchart' => {id => 420},
    'geo.getmetrohypetrackchart' => {id => 422},
    'geo.getmetrotrackchart' => {id => 423},
    'geo.getmetrouniqueartistchart' => {id => 424},
    'geo.getmetrouniquetrackchart' => {id => 425},
    'geo.getmetroweeklychartlist' => {id => 426},
    'geo.getmetros' => {id => 435},
    'geo.gettopartists' => {page => 1, id => 297},
    'geo.gettoptracks' => {page => 1, id => 298},
    'group.gethype' => {id => 259},
    'group.getmembers' => {page => 1, id => 379},
    'group.getweeklyalbumchart' => {id => 293},
    'group.getweeklyartistchart' => {id => 294},
    'group.getweeklychartlist' => {id => 295},
    'group.getweeklytrackchart' => {id => 296},
    'library.addalbum' => {auth => 1, post => 1, signed => 1, id => 370},
    'library.addartist' => {auth => 1, post => 1, signed => 1, id => 371},
    'library.addtrack' => {auth => 1, post => 1, signed => 1, id => 372},
    'library.getalbums' => {page => 1, id => 321},
    'library.getartists' => {page => 1, id => 322},
    'library.gettracks' => {page => 1, id => 323},
    'library.removealbum' => {auth => 1, post => 1, signed => 1, id => 523},
    'library.removeartist' => {auth => 1, post => 1, signed => 1, id => 524},
    'library.removescrobble' => {auth => 1, post => 1, signed => 1, id => 525},
    'library.removetrack' => {auth => 1, post => 1, signed => 1, id => 526},
    'playlist.addtrack' => {auth => 1, post => 1, signed => 1, id => 337},
    'playlist.create' => {auth => 1, post => 1, signed => 1, id => 365},
    'radio.getplaylist' => {auth => 1, signed => 1, id => 256},
    'radio.search' => {id => 418},
    'radio.tune' => {auth => 1, post => 1, signed => 1, id => 160},
    'tag.getinfo' => {id => 452},
    'tag.getsimilar' => {id => 311},
    'tag.gettopalbums' => {page => 1, id => 283},
    'tag.gettopartists' => {page => 1, id => 284},
    'tag.gettoptags' => {id => 276},
    'tag.gettoptracks' => {page => 1, id => 285},
    'tag.getweeklyartistchart' => {id => 358},
    'tag.getweeklychartlist' => {id => 359},
    'tag.search' => {page => 1, id => 273},
    'tasteometer.compare' => {id => 258},
    'tasteometer.comparegroup' => {id => 500},
    'track.addtags' => {auth => 1, post => 1, signed => 1, id => 304},
    'track.ban' => {auth => 1, post => 1, signed => 1, id => 261},
    'track.getbuylinks' => {id => 431},
    'track.getcorrection' => {id => 447},
    'track.getfingerprintmetadata' => {id => 441},
    'track.getinfo' => {id => 356},
    'track.getshouts' => {page => 1, id => 453},
    'track.getsimilar' => {id => 319},
    'track.gettags' => {auth => 1, signed => 1, id => 320},
    'track.gettopfans' => {id => 312},
    'track.gettoptags' => {id => 289},
    'track.love' => {auth => 1, post => 1, signed => 1, id => 260},
    'track.removetag' => {auth => 1, post => 1, signed => 1, id => 316},
    'track.scrobble' => {auth => 1, post => 1, signed => 1, id => 443},
    'track.search' => {page => 1, id => 286},
    'track.share' => {auth => 1, post => 1, signed => 1, id => 305},
    'track.unban' => {auth => 1, post => 1, signed => 1, id => 449},
    'track.unlove' => {auth => 1, post => 1, signed => 1, id => 440},
    'track.updatenowplaying' => {auth => 1, post => 1, signed => 1, id => 454},
    'user.getartisttracks' => {page => 1, id => 432},
    'user.getbannedtracks' => {page => 1, id => 448},
    'user.getevents' => {page => 1, id => 291},
    'user.getfriends' => {page => 1, id => 263},
    'user.getinfo' => {auth => 1, id => 344},
    'user.getlovedtracks' => {page => 1, id => 329},
    'user.getneighbours' => {id => 264},
    'user.getnewreleases' => {id => 444},
    'user.getpastevents' => {page => 1, id => 343},
    'user.getpersonaltags' => {page => 1, id => 455},
    'user.getplaylists' => {id => 313},
    'user.getrecentstations' => {auth => 1, signed => 1, page => 1, id => 414},
    'user.getrecenttracks' => {page => 1, id => 278},
    'user.getrecommendedartists' => {auth => 1, signed => 1, page => 1, id => 388},
    'user.getrecommendedevents' => {auth => 1, signed => 1, page => 1, id => 375},
    'user.getshouts' => {page => 1, id => 401},
    'user.gettopalbums' => {page => 1, id => 299},
    'user.gettopartists' => {page => 1, id => 300},
    'user.gettoptags' => {id => 123},
    'user.gettoptracks' => {page => 1, id => 301},
    'user.getweeklyalbumchart' => {id => 279},
    'user.getweeklyartistchart' => {id => 281},
    'user.getweeklychartlist' => {id => 280},
    'user.getweeklytrackchart' => {id => 282},
    'user.shout' => {auth => 1, post => 1, signed => 1, id => 411},
    'venue.getevents' => {id => 394},
    'venue.getpastevents' => {page => 1, id => 395},
    'venue.search' => {page => 1, id => 396},
};
#}}}
our %last_params;
our $last_response;
our %last_response_meta;
sub lastfm {
    my ($method, @params) = @_;
    $method = lc($method);

    my %params;
    my $i = 0;
    while (my $p = shift @params) {
        if (ref $p eq "HASH") {
            while (my ($k,$v) = each %$p) {
                $params{$k."[".$i."]"} = $v;
            }
            croak "too multitudinous (limit 50)" if $i > 49;
            $i++
        }
        else {
            $params{$p} = shift @params;
        }
    }
    $params{method} = $method;
    $params{api_key} = $api_key;
    $params{format} = "json" unless $params{format} || $xml;
    delete $params{format} if $params{format} && $params{format} eq "xml";

    unless (exists $methods->{$method}) {
        carp "method $method is not known to Net::LastFMAPI"
    }
    elsif (defined $params{page} && !$methods->{$method}->{page}) {
        carp "method $method is not known to be paginated, but hey"
    }

    sessionise(\%params);

    sign(\%params);

    %last_params = %params;

    my $cache = $cache;
    if ( $cache ) {
        unless ( -d $cache ) {
            $cache = $cache_dir;
            make_path( $cache );
        }
        my $cache_key_json = encode_json( [ map { $_, $params{$_} } sort keys %params ] );
        my $file = "$cache/" . md5_hex( $cache_key_json );
        if ( -f $file ) {
            my $data = loadfile( $file );
            return _rowify_content( $data->{content} );
        }

        $cache = $file;
    }

    my $res;
    if ($methods->{$method}->{post}) {
        $res = $ua->post($url, Content => \%params);
    }
    else {
        my $uri = URI->new($url);
        $uri->query_form(%params);
        $res = $ua->get($uri);
    }

    $params{format} ||= "xml";
    my $content = $res->decoded_content;
    croak "Last.fm contains faulty data for a piece of data you requested and "
      . "is unable to return a useful reply. Will be treated as an empty reply."
      if $content eq qq|""\n|;

    my $decoded_json = sub { $content = decode_json($content); };
    unless ($res->is_success &&
        ($params{format} eq "json" && !exists($decoded_json->()->{error})
        || $params{format} eq "xml" && $content =~ /<lfm status="ok">/)) {

        my @clues;
        if ($res->is_success) {
            if ($res->decoded_content =~ /Invalid session key - Please re-authenticate/) {
                push @clues, "Set NET_LASTFMAPI_REAUTH=1 to re-authenticate";
            }
            elsif ($methods->{$method}) {
                push @clues, "Documentation for the '$method' method:\n"
                    ."    http://www.last.fm/api/show/?service=$methods->{$method}->{id}"
            }
        }

        if (ref $content eq "HASH") {
            $content = "Content translated JSON->YAML:\n".Dump($content);
        }
        else {
            $content = "Content:\n$content";
        }

        croak join("\n",
            "Something went wrong.",
            "HTTP Status: ".$res->status_line,
            @clues,
            "",
            $content,
            ""
        );
    }

    if ($cache) {
        dumpfile($cache, {content => $content});
    }
    $last_response = $content;
    return _rowify_content( $content );
}

sub _rowify_content {
    my ( $content ) = @_;
    return extract_rows( $content ) if wantarray;
    return $content;
}

sub extract_rows {
    my ( $content ) = @_;
    if (!$last_params{format}) {
        croak "returning rows from xml is not supported";
    }
    my @main_keys = keys %{$content};
    my $main_data = $content->{$main_keys[0]};
    my @data_keys = sort keys %{$main_data};
    unless (@main_keys == 1 && @data_keys == 2 && $data_keys[0] eq '@attr') {
        my ( $text, $total ) = ( $main_data->{'#text'}, $main_data->{total} );
        return if defined $text && $text =~ /^\s+$/ && defined $total && $total == 0; # no rows
        carp "extracting rows may be broken";
    }
    %last_response_meta = %{ $main_data->{$data_keys[0]} };
    my $rows = $main_data->{$data_keys[1]};
    if (ref $rows ne "ARRAY") {
        # schemaless translation of xml to data creates these cases
        if (ref $rows eq "HASH") { # 1 row
            $rows = [ $rows ];
        }
        elsif ($rows =~ /^\s+$/) { # no rows
            $rows = [];
            carp "got whitespacey string instead of empty row array, this happens"
        }
        else {
            carp "not an array of rows... '$rows' returning ()";
        }
    }
    return @$rows;
}

sub lastfm_iter {
    my @rows = lastfm(@_, page => 1);
    my $params = { %last_params };
    if (!$params->{format}) {
        croak "paginating xml is not supported";
    }
    if (@rows == 0) {
        return sub { };
    }
    my $page = $last_response_meta{page};
    my $totalpages = $last_response_meta{totalPages};
    my $next_page = sub {
        return () if $page++ >= $totalpages;
        my %params = %$params;
        $params{page} = $page;
        my $method = delete $params{method};
        my @rows = lastfm($method, %params);
        return @rows;
    };
    return sub {
        unless (@rows) {
            push @rows, $next_page->();
        }
        return shift @rows;
    }
}

sub sessionise {
    my $params = shift;
    my $m = $methods->{$params->{method}};
    unless (delete $params->{auth} || $m && $m->{auth}) {
        return
    }
    $params->{sk} = get_session_key();
}

sub get_session_key {
    unless (defined $session_key) {
        load_save_sessionkey()
    }
    unless (defined $session_key) {
        my $key;
        eval { $key = request_session(); };
        if ($@) {
            die "--- Died while making requests to get a session:\n$@";
        }
        load_save_sessionkey($key);
    }
    return $session_key || die "unable to acquire session key...";
}

sub request_session {
    my $res = lastfm("auth.gettoken", format => "xml");

    my ($token) = $res =~ m{<token>(.+)</token>}
        or die "no foundo token: $res";

    talk_authorisation($token);

    my $sess = lastfm("auth.getSession", token => $token, format => "xml");

    ($username) = $sess =~ m{<name>(.+)</name>}
        or die "no name!? $sess";
    my ($key) = $sess =~ m{<key>(.+)</key>}
        or die "no key!? $sess";
    return $key;
}


sub talk_authorisation {
    my $token = shift;
    say "Sorry about this but could you go over here: "
        ."http://www.last.fm/api/auth/?api_key="
        .$api_key."&token=".$token;
    say "Hit enter to continue...";
    <STDIN>;
}

sub sign {
    my $params = shift;
    return unless $methods->{$params->{method}}->{signed};
    my $jumble = join "", map { $_ => $params->{$_} }
        grep { !($_ eq "format" || $_ eq "callback") } sort keys %$params;
    my $hash = md5_hex($jumble.$secret);
    $params->{api_sig} = $hash;
}

if ($ENV{NET_LASTFMAPI_REAUTH}) {
    say "Re-authenticatinging...";
    if (-e $sk_savefile) {
        unlink($sk_savefile);
    }
    undef $session_key;
    get_session_key();
    say "Got session key: $session_key";
    say "Unsetting NET_LASTFMAPI_REAUTH...";
    delete $ENV{NET_LASTFMAPI_REAUTH};
    say "Done";
    exit;
}

1;

__END__

=head1 NAME

Net::LastFMAPI - LastFM API 2.0

=head1 SYNOPSIS

  use Net::LastFMAPI;
  my $perl_data = lastfm("artist.getSimilar", artist => "Robbie Basho");

  # sets up a session/gets authorisation when needed for write actions:
  my $res = lastfm(
      "track.scrobble",
      artist => "Robbie Basho",
      track => "Wounded Knee Soliloquy",
      timestamp => time(),
  );
  $success = $res->{scrobbles}->{'@attr'}->{accepted} == 1;

  my $xml = lastfm(...); # with config value: xml => 1
  my $xml = lastfm(..., format => "xml");
  $success = $xml =~ m{<scrobbles accepted="1"};

  # paginated data can be iterated through per row
  my $iter = lastfm_iter("artist.getTopTracks", artist => "John Fahey");
  while (my $row = $iter->()) {
      say $row->{playcount} .": ". $row->{name};
      my $whole_response = $Net::LastFMAPI::last_response;
  }

  # wantarray? tries to extract the rows of data for you
  my @rows = lastfm(...);

  # see also:
  # bin/cmd.pl album.getInfo artist=Laddio Bolocko album=As If In Real Time
  # bin/scrobble.pl Artist - Track
  # bin/portablog-scrobbler.pl

=head1 DESCRIPTION

Makes requests to http://ws.audioscrobbler.com/2.0/ and returns the result.

Takes care of POSTing to write methods, doing authorisation when needed.

Dies if something went obviously wrong.

Can return xml if you like, defaults to returning perl data (requesting json).
Beware of "@attr" and empty elements turned into whitespace strings instead of
empty arrays, single elements turned into a hash instead of an array of one hash.

=head1 SESSION KEY AND AUTHORISATION

  lastfm_config(
      session_key => $key,
  );

The session key will be sought when an authorised request is needed. See L<CONFIG>.

If it is not configured or saved then on-screen instructions should be followed to
authorise in a web browser with whoever is logged in to L<last.fm>.
See L<http://www.last.fm/api/desktopauth>.

It is saved in the file B<File::HomeDir::my_home()/.net-lastfmapi-sessionkey>
by default. This is probably fine.

Consider altering the subroutines B<talk_authentication>, B<load_save_sessionkey>,
or simply configuring (see L<CONFIG>) before needing it.

=head1 CACHING

  lastfm_config(
      # to enable caching
      cache => 1,
      # default:
      cache_dir => File::HomeDir::my_home()."/.net-lastfmapi-cache/",
  );

Good for development.

=head1 RETURNING ROWS

  my @artists = lastfm("artist.getSimilar", ...);

Call C<lastfm> in list context. Attempts to extract for you the rows inside the
response. The whole response is in C<$Net::LastFMAPI::last_response>. See also
L<PAGINATION>

=head1 RETURN XML

  lastfm_config(xml => 1);
  # or
  lastfm(..., format => "xml"):

This will return an xml string to you. You can also set B<format =E<gt> "xml">
for a particular request. Default format is JSON, as getting perl data is much
from the C<lastfm> method is more casual.

=head1 PAGINATION

  my $iter = lastfm_iter(...);
  while (my $row = $iter->()) {
      ...
  }

Will attempt to extract rows from a response, passing you one at a time,
keeping going into the next page, and the next...

=head1 CONFIG

  lastfm_config(
      # associates the request with a user
      # got with their permission initially
      session_key => $key,

      # these are explained elsewhere in this pod
      xml => 1,
      cache => 1,
      cache_dir => $path,


      # for your own api account see http://www.last.fm/api/account
      # you can use this module's (default) api account fine
      api_key => $your_api_key,
      secret => $your_secret,

      # LWP::UserAgent-sorta thing
      ua => $ua,

      # default File::HomeDir::my_home()/.net-lastfmapi-sessionkey
      sk_savefile => $path,
  );

B<cache> and B<cache_dir> are likely most popular, see L<CACHING>.

This module can handle the B<session_key> fine, see L<SESSION KEY AND AUTHORISATION>.

B<api_key> and B<secret> are for representing this module on the page where the
user authorises their account in the process of acquiring a new B<session_key>.
You might want to have your own identity in there.

=head1 SEE ALSO

L<Net::LastFM> doesn't handle sessions for you, won't POST to write methods

I had no luck with the 1.2 API modules: L<WebService::LastFM>,
L<Music::Audioscrobbler::Submit>, L<Net::LastFM::Submission>

=head1 BUGS/CODE

L<https://github.com/st3vil/Net-LastFMAPI>

=head1 AUTHOR

Steev Eeeriumn <drsteve@cpan.org>

=head1 COPYRIGHT

   Copyright (c) 2011, Steev Eeeriumn. All Rights Reserved.
 This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
     (see http://www.perl.com/perl/misc/Artistic.html)
