package Webservice::Rosary::API;

use v5.10;
use strict;
use warnings;

use Util::H2O::More qw/baptise d2o/;
use HTTP::Tiny qw//;
use JSON qw/decode_json/;
use Scalar::Util qw/reftype/;

our $VERSION = "0.1.9";

use constant {
  BASEURL  => "https://the-rosary-api.vercel.app/v1",
  DAILYURL => "https://dailyrosary.cf",
};

sub new {
  my $pkg = shift;
  my %params = @_;

  $params{timeout}        = 10  if not exists $params{timeout};
  $params{cache_ttl}      = 300 if not exists $params{cache_ttl};
  $params{stale_if_error} = 1   if not exists $params{stale_if_error};
  $params{cache}          = {}  if not exists $params{cache};
  $params{ua}             = _new_default_ua($params{timeout})
    if not exists $params{ua};

  return baptise \%params, $pkg,
    qw/ua timeout cache cache_ttl stale_if_error/;
}


sub _new_default_ua {
  my $timeout = shift;

  # HTTP::Tiny honors proxy environment variables. Some environments leave
  # those variables defined but empty; older HTTP::Tiny releases treat that
  # as an invalid proxy URL. Ignore only empty proxy values locally.
  local %ENV = %ENV;
  foreach my $name (qw/http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY/) {
    delete $ENV{$name} if exists $ENV{$name} and not length $ENV{$name};
  }

  return HTTP::Tiny->new(timeout => $timeout);
}

sub clear_cache {
  my $self = shift;
  %{ $self->cache } = ();
  return $self;
}

sub _decode_content {
  my ($self, $content, $URL) = @_;

  die "Rosary API returned an empty response from $URL\n"
    if not defined $content or $content !~ /\S/;

  my $decoded = eval { decode_json($content) };
  if (not defined $decoded or $@) {
    my $error = $@ || q{unknown JSON decoding error};
    chomp $error;
    die "Rosary API returned invalid JSON from $URL: $error\n";
  }

  return d2o -autoundef, $decoded;
}

sub _cached_content {
  my ($self, $URL, $fresh_only) = @_;
  return if not $self->cache_ttl or $self->cache_ttl <= 0;

  my $entry = $self->cache->{$URL} or return;
  return if $fresh_only and (time - $entry->{stored_at}) > $self->cache_ttl;
  return $entry->{content};
}

sub _cache_content {
  my ($self, $URL, $content) = @_;
  return if not $self->cache_ttl or $self->cache_ttl <= 0;

  $self->cache->{$URL} = {
    content   => $content,
    stored_at => time,
  };
  return;
}

sub _fallback_or_die {
  my ($self, $URL, $error) = @_;
  chomp $error;

  if ($self->stale_if_error) {
    my $cached = $self->_cached_content($URL, 0);
    if (defined $cached) {
      warn "$error; using cached Rosary API response\n";
      return $self->_decode_content($cached, $URL);
    }
  }

  die "$error\n";
}

sub _make_call {
  my ($self, $when) = @_;
  $when = lc $when;
  my $URL = sprintf "%s/%s", BASEURL, $when;

  # Repeated requests are cheap locally, but preserve the semantics of
  # /random by never satisfying it from a fresh cache entry.
  if (lc($when) ne q{random}) {
    my $cached = $self->_cached_content($URL, 1);
    return $self->_decode_content($cached, $URL) if defined $cached;
  }

  my $response = eval { $self->ua->get($URL) };
  if ($@) {
    my $error = $@;
    chomp $error;
    return $self->_fallback_or_die(
      $URL,
      "Rosary API request to $URL failed: $error",
    );
  }

  if (ref($response) ne q{HASH}) {
    return $self->_fallback_or_die(
      $URL,
      "Rosary API request to $URL returned an invalid HTTP response",
    );
  }

  if (not $response->{success}) {
    my $status = defined $response->{status} ? $response->{status} : q{unknown};
    my $reason = defined $response->{reason} ? $response->{reason} : q{HTTP error};
    return $self->_fallback_or_die(
      $URL,
      "Rosary API request to $URL failed: HTTP $status $reason",
    );
  }

  my $content = $response->{content};
  my $decoded = eval { $self->_decode_content($content, $URL) };
  if ($@) {
    my $error = $@;
    chomp $error;
    return $self->_fallback_or_die($URL, $error);
  }

  $self->_cache_content($URL, $content);
  return $decoded;
}

sub mp3Link {
  my ($self, $when) = @_;
  my @mp3 = qw/today yesterday tomorrow random/;
  return "" if not defined $when or not grep { m/^\Q$when\E$/i } @mp3;

  my $resp = $self->_make_call($when);
  my $type = reftype($resp) || q{};
  my $item;

  if ($type eq q{ARRAY}) {
    $item = $resp->[0] if @$resp;
  }
  elsif ($type eq q{HASH}) {
    $item = $resp;
  }

  if ($item and (reftype($item) || q{}) eq q{HASH}) {
    my $file = $item->{mp3Link};
    return sprintf "%s/%s", DAILYURL, $file if defined $file and length $file;
  }

  warn "\nNo MP3 content in response from the Rosary API ... try the following links:\n";
  warn <<'EOF_LINKS';

    https://www.discerninghearts.com/catholic-podcasts/holy-rosary/

      + https://www.discerninghearts.com/Devotionals/Rosary-Joyful-Mysteries.mp3

      + https://www.discerninghearts.com/Devotionals/Rosary-Luminous-Mysteries.mp3

      + https://www.discerninghearts.com/Devotionals/Rosary-Sorrowful-Mysteries.mp3

      + https://www.discerninghearts.com/Devotionals/Rosary-Glorious-Mysteries.mp3

... please try back again later
EOF_LINKS
  die "Rosary API returned no MP3 link\n";
}

sub day {
  my ($self, $when) = @_;
  my @days = qw/sunday monday tuesday wednesday thursday friday saturday/;
  return "" if not defined $when or not grep { m/^\Q$when\E$/i } @days;

  my $resp = $self->_make_call($when);
  my $type = reftype($resp) || q{};
  return $resp->[0] if $type eq q{ARRAY} and @$resp;
  return $resp      if $type eq q{HASH};
  return "";
}

# Get detailed recitations
sub details {
  my ($self, $when) = @_;
  my @mysteries = qw/joyful glorious sorrowful luminous/;
  return "" if not defined $when or not grep { m/^\Q$when\E$/i } @mysteries;
  return $self->_make_call($when);
}

1;

__END__

=head1 NAME

Webservice::Rosary::API - Perl API client for the Rosary API at
L<https://the-rosary-api.vercel.app> and L<https://dailyrosary.cf>.

=head1 SYNOPSIS

  use v5.10;
  use warnings;
  my $Rosary = Webservice::Rosary::API->new;

  my $mp3URL = $Rosary->mp3Link("random");
  say $mp3URL;

=head1 DESCRIPTION

This is an API client for L<https://the-rosary-api.vercel.app>, which powers
L<https://dailyrosary.cf>*; the API requires no authentication, so the
client here simply wraps most of the calls for convenient use in Perl programs.

It is meant to facilitate a couple of things. One is the generation of a
full URL that may be used to download an audio file of the specified Mystery
being said, as an C<.mp3> file. This means you may do something like what
is done at L<https://dailyrosary.cf>.

The second thing it is meant to do is to return the text of a full recitation
of the Rosary, which is what the provided C<avemaria> commandline utility
uses to lead the user through the recitation of the specified Mystery.

For more information on the Rosary itself, please see the very end of this
documentation.

The Rosary API is profiled at L<https://www.freepublicapis.com/the-rosary-api>.

Contributed as part of the B<FreePublicPerlAPIs> Project described at,
L<https://github.com/oodler577/FreePublicPerlAPIs>.

* - the module author is not affiliated with these sites

=head1 METHODS

=over 4

=item C<new(param1 => $val1, ...)>

Constructor. By default it creates an L<HTTP::Tiny> user agent with a
10-second timeout and enables a small per-instance in-memory cache with a
300-second TTL. The following optional parameters are recognized:

=over 4

=item C<ua>

An HTTP-compatible object providing C<get>. This is useful for testing and for
applications that need to supply their own configured user agent.

=item C<timeout>

Timeout used when constructing the default L<HTTP::Tiny> instance. Default: 10.

=item C<cache_ttl>

Number of seconds successful responses may be served from memory. Set to C<0>
to disable caching. Default: 300. The C<random> endpoint is never satisfied from
a fresh cache entry, so repeated random requests remain random.

=item C<stale_if_error>

If true, a previously cached response may be used when the network request
fails, even after its normal TTL has expired. Default: true.

=item C<cache>

Optional hash reference used as the per-instance in-memory cache. Most callers
can leave this unspecified; supplying one is primarily useful for tests or for
applications that want to inspect or preseed the cache explicitly. Cache
contents are not written to disk and are not shared between objects unless the
same hash reference is supplied to more than one object.

=back

  my $Rosary = Webservice::Rosary::API->new;
  my $NoCache = Webservice::Rosary::API->new(cache_ttl => 0);

=item C<mp3Link("today" | "tomorrow" | "yesterday" | "random")>

Given the string describing I<when>, returns the full URL of the MP3
recording reported by the API service.

  my $Rosary = Webservice::Rosary::API->new;
  my $mp3URL = $Rosary->mp3Link("random");
  say $mp3URL;

See the C<avemaria> commandline client for an example of using this in
combination with C<curl> to automatically download the C<.mp3> file.

B<Error Handling>

Network failures, non-success HTTP responses, empty responses, and malformed
JSON result in descriptive exceptions unless a stale cached response is
available and C<stale_if_error> is enabled. An otherwise valid response that
contains no MP3 link still C<die>s after printing the known direct MP3 sources.

B<MP3 Source Note>

All recordings are actually freely available at the site,

L<https://www.discerninghearts.com/catholic-podcasts/holy-rosary/>

=over 4

=item L<https://www.discerninghearts.com/Devotionals/Rosary-Joyful-Mysteries.mp3>

=item L<https://www.discerninghearts.com/Devotionals/Rosary-Luminous-Mysteries.mp3>

=item L<https://www.discerninghearts.com/Devotionals/Rosary-Sorrowful-Mysteries.mp3>

=item L<https://www.discerninghearts.com/Devotionals/Rosary-Glorious-Mysteries.mp3>

=back

=item C<day("Sunday" | "Monday" | "Tuesday" | ... | "Thursday" | "Friday" | "Saturday")>

Given the day, returns the Mystery of the Rosary traditionally associated
with the day of the week. This module I<does> include the Luminous Mysteries
(associated with Thursdays*).

This method doesn't accept the name of a particular Mystery because this
can be achieved using a look up table that maps each Mystery to a particular
day, e.g.:

  my $Convert = {
    luminous  => "thursday",
    sorrowful => "friday",
    joyful    => "saturday",
    glorious  => "sunday",
  };

Then the day of the week obtained via C<$Convert->{$mystery}> can be used
to derive the proper day to be used with this call.

* - although, any Mystery may be said on any day

B<Error Handling>

Invalid day names return an empty string without making an HTTP request. Network
failures, HTTP errors, empty responses, and malformed JSON result in a
descriptive exception unless stale-cache fallback is available.

=item C<details("joyful" | "glorious" | "sorrowful" | "luminous")>

Returns the detailed recitation data for the named Mystery. The C<avemaria>
client uses this data to present each decade's Mystery title and Fruit of the
Mystery during ordinary prayer mode; C<--fully> additionally displays the
longer meditation text supplied by the API. Invalid Mystery names return an
empty string without making an HTTP request. Network and decoding failures are
handled in the same way as C<day>.

  my $details = $Rosary->details("joyful");

=item C<clear_cache>

Empties the per-instance response cache and returns the object.

  $Rosary->clear_cache;

=back

Rosary API calls that are not currently supported:

=over 4

=item C</v1/list>

=item C</v1/date/:MMDDYY>

=item C</v1/novena>

=item C</v1/novena/:MMDDYY>

=item C</v1/54daynovena>

=back

=head1 THE C<avemaria> UTILITY

The C<avemaria> commandline Rosary client is installed with this distribution.
It uses this API module for remote Rosary data, L<Webservice::Rosary::Stream>
for timed interactive text streaming, and L<Webservice::Rosary::Tradition> for
small pieces of traditional presentation metadata that are not supplied by the
remote API.

Commandline options may continue to evolve as the prayer UX is refined.

=head2 Quick Start

With no arguments, C<avemaria> selects today's Mystery and enters prayer mode:

  avemaria

Prayer-oriented options may also be supplied without an explicit day or
Mystery; today's Mystery is selected automatically. For example:

  avemaria --scroll --color

An explicit day or Mystery without a prayer-mode option prints its Mystery
summary instead:

  avemaria Monday
  avemaria Sorrowful

Valid day values are Sunday through Saturday. Valid Mystery names are
C<Joyful>, C<Sorrowful>, C<Glorious>, and C<Luminous>.

=head2 Help and Background

  avemaria help
  avemaria --help
  avemaria about
  avemaria --about

C<help> prints command usage. C<about> prints background information about the
Rosary.

=head2 MP3 Commands

The following commands print the full URL of the corresponding MP3 recording to
STDOUT:

  avemaria today
  avemaria yesterday
  avemaria tomorrow
  avemaria random

This makes the command convenient to combine with another program, for example:

  curl -O "$(avemaria random)"

=head2 Prayer Mode

The general prayer form is:

  avemaria [DAY_OR_MYSTERY] [--pray] [--unceasingly]
           [--scroll] [--fully] [-i] [-t]
           [--sleep=0.N] [--speed=N] [--between=N]
           [--nocontrols]
           [--color [--dark | --light]]

C<--pray> streams the selected Rosary prayer by prayer.

C<--unceasingly> continuously prays until the user stops it. It implies
C<--pray>, so these are both valid:

  avemaria --unceasingly
  avemaria --pray --unceasingly

Using both is intentionally redundant rather than an error. When no day or
Mystery is supplied explicitly, the calendar day is checked at the boundary
between complete Rosaries. If midnight has passed, the next Rosary uses the
Mysteries for the new day. An explicitly selected day or Mystery remains fixed
for every cycle. Live speed changes are retained between cycles, and API/cache
data is reused except when a calendar-day change requires the next day's data.

=head2 Mystery and Intention Presentation

Mystery-set headings are displayed in uppercase. During prayer mode each new
decade presents its individual Mystery title and its Fruit of the Mystery from
the API. C<--fully> additionally displays the longer meditation text for that
decade.

The introductory intentions are local traditional presentation metadata rather
than fields supplied by the remote API. The introductory Our Father is presented
as being offered:

  For the intentions and well-being of Pope Leo XIV.

The first three Hail Marys are presented for an increase in Faith, Hope, and
Charity, respectively. These values are kept in
L<Webservice::Rosary::Tradition> rather than being represented as remote API
data.

If the secondary Mystery-details request fails, C<avemaria> warns and continues
the basic Rosary instead of making the entire prayer unusable.

=head2 Scrolling and Reduced-Clutter Presentation

C<--scroll> keeps previous prayer text visible instead of clearing the terminal
between prayers. It is intentionally quieter than the non-scrolling display:
the overall Mystery heading and live-control reminder are shown initially, and
section headings are shown again when a new decade begins rather than before
every individual prayer.

With C<--unceasingly --scroll>, the overall heading is shown again when a new
Rosary cycle starts, while ordinary repeated prayers remain uncluttered.

Without C<--scroll>, the terminal is cleared as the client advances through the
Rosary.

=head2 Detailed and Manual-Pacing Options

=over 4

=item C<--fully>

Adds the full decade meditation to the Mystery title and Fruit of the Mystery
that are already shown in normal prayer mode.

=item C<-i>

Requires C<E<lt>RETURNE<gt>> after each prayer. When C<--fully> is in use, the
meditation presentation is also included in the manual pacing flow.

=item C<-t>

Requires C<E<lt>RETURNE<gt>> after each decade description. C<-t> requires
C<--fully>.

=back

=head2 Timing and Live Controls

The timing options are independent of presentation options:

=over 4

=item C<--sleep=SECONDS>

Sets the base delay before each streamed character. The default is 0.04
seconds. The value must be zero or greater.

=item C<--speed=MULTIPLIER>

Sets the initial text-speed multiplier. The default is 1.0 and the value must be
greater than zero. Live speed changes are relative to this starting value.

=item C<--between=SECONDS>

Sets the pause between prayers. The default is 0.75 seconds and the value must
be zero or greater.

=item C<--nocontrols>

Disables the live single-key controls. C<-i> and C<-t> Return prompts still
work. In C<--unceasingly --nocontrols> mode, use C<Ctrl-C> to stop.

=back

When live controls are enabled and STDIN is interactive, the following keys are
available while text is streaming and while timed waits are in progress:

  SPACE or p   pause or resume
  + or =       speed up immediately
  - or _       slow down immediately
  0            reset to the initial --speed value
  q            ask: Quit y/N?

A negative response to the quit prompt resumes the prayer. A confirmed quit
restores the terminal, prints:

  Pray the Rosary every day, +JMJ+

and exits successfully.

The terminal is also restored when the client handles C<SIGINT> or C<SIGTERM>,
so interactive terminal mode should not be left altered after interruption.

=head2 Color

Color is strictly opt-in:

  avemaria --color
  avemaria --color --dark
  avemaria --color --light

C<--color> by itself uses the dark-background profile. C<--dark> and C<--light>
are mutually exclusive and are meaningful only with C<--color>. No color is
emitted when C<--color> is absent. Color is also suppressed for non-terminal
output, C<TERM=dumb>, or when the C<NO_COLOR> environment variable is present.

The palette is organized by devotional role rather than applying arbitrary
color to every line:

=over 4

=item *

Hail Marys alternate between a light Marian blue and a neutral foreground,
starting with blue for the introductory Hail Marys and again at the beginning
of each decade. The neutral alternate is soft white on the dark-background
profile and charcoal on the light-background profile. Joyful Mystery headings
remain light Marian blue.

=item *

Our Fathers use a subdued green.

=item *

Sorrowful Mystery headings use a dark red or maroon family.

=item *

Glorious Mystery headings use a warm yellow or gold family.

=item *

Luminous Mystery headings use a gentle violet or lavender family.

=item *

Each individual Mystery title is bold in the color of its Mystery family.

=item *

The Apostles' Creed, Hail Holy Queen, and the closing C<O God, Whose Only
Begotten Son...> prayer use a bold neutral treatment: near-white on the dark
profile and near-black on the light profile.

=back

The closing C<O God, Whose Only Begotten Son...> prayer is folded to 72 columns
for readability in the terminal.

=head2 Examples

Pray today's Rosary with the low-clutter scrolling presentation:

  avemaria --scroll

Use the dark-background color profile (the default profile for C<--color>):

  avemaria --scroll --color

Use a light-background terminal profile:

  avemaria --scroll --color --light

Pray the Sorrowful Mysteries with the full decade meditations:

  avemaria Sorrowful --pray --fully --scroll

Pause after each decade description:

  avemaria Friday --pray --fully -t

Pray continuously, following the calendar when no day/Mystery is explicit:

  avemaria --unceasingly --scroll --color

=head2 Option Composition

The options are intended to compose rather than define unrelated modes.
C<--unceasingly> controls repetition and implies prayer mode. Without an
explicit day/Mystery it follows calendar changes between complete Rosaries;
with an explicit selection it remains fixed. C<--scroll> only changes screen
presentation; C<--fully> controls meditation detail; the timing options control
pacing; and the color options control styling. Consequently a command such as:

  avemaria Luminous --unceasingly --scroll --fully --color --light --speed=1.25

has a straightforward meaning: repeatedly pray the Luminous Mysteries, preserve
prior text, include full decade meditations, use the light-background color
profile, and start at 1.25 times the normal text speed.

=head1 ENVIRONMENT

There is no set up other than a working Perl environment and required modules.

=head1 BUGS AND SUPPORT

Please report bugs to the Github issue tracker; also report back how to improve
this library and the commandline utility:

L<https://github.com/oodler577/p5-Webservice-Rosary-API/issues>

=head1 BACKGROUND ON THE ROSARY

The Rosary is a traditional Catholic prayer devotion that involves the
repetition of prayers and meditation on key events from the lives of Jesus
Christ and the Virgin Mary. The prayer is structured around a set of beads,
each representing a specific prayer. These include the Our Father, Hail Mary,
and Glory Be, which are recited while reflecting on the Mysteries-twenty
key moments in the lives of Jesus and Mary, grouped into four categories:
the Joyful, Sorrowful, Glorious, and Luminous Mysteries. The Rosary is both
a contemplative prayer and a way to focus on the essential aspects of the
Catholic faith, helping the faithful deepen their relationship with God.

The history of the Rosary dates back to the Middle Ages, with its roots often
linked to St. Dominic, who is traditionally credited with receiving the Rosary
from the Virgin Mary in the 13th century. The Rosary evolved over several
centuries. One of its early forms was connected to the Psalter of Our Lady,
where the faithful would pray 150 Hail Marys, reflecting the 150 Psalms of
the Old Testament. This practice was common among laypeople who could not
read the Psalms themselves but still wanted to engage in a structured form
of prayer. Over time, the Rosary's prayers and structure were refined, and
by the 16th century, it became formally established by the Catholic Church
as a central devotion, with the mysteries of the Rosary added to provide a
scriptural basis for the prayers.

=head2 Biblical Foundations of the Hail Mary

For Catholics, the Rosary is a deeply meaningful prayer practice that helps
them draw closer to God by reflecting on the pivotal moments of salvation
history. Its biblical foundations are grounded in scripture, with the Hail Mary
drawn from the Angel Gabriel's greeting to Mary in Luke 1:28 and Elizabeth's
words in Luke 1:42.

The first part of the Hail Mary comes from Luke 1:28 and Luke 1:42 in the
Douay-Rheims translation:

=over 4

=item * Luke 1:28

  And the angel being come in, said unto her: Hail, full of grace, the Lord
  is with thee: blessed art thou among women.

L<https://drbo.org/cgi-bin/d?b=drb&bk=49&ch=1&l=28-#x>

=item * Luke 1:42

  And she cried out with a loud voice, and said: Blessed art thou among women,
  and blessed is the fruit of thy womb.

L<https://drbo.org/cgi-bin/d?b=drb&bk=49&ch=1&l=42-#x>

=back

These biblical words form the Angelic Salutation, which Catholics begin the
Rosary with:

  Hail Mary, full of grace, the Lord is with thee: blessed art thou
  among women, and blessed is the fruit of thy womb, Jesus.

=head2 The Second Part of the Hail Mary

The second part of the Hail Mary, which was added later to the prayer,
invokes Mary's intercession. This part is drawn from the Catholic tradition
and reflects the Church's desire for Mary's prayers to be a source of strength
and protection for all the faithful. The second part reads:

  Holy Mary, Mother of God, pray for us sinners, now and at the hour
  of our death. Amen.

This petition is based on Mary's role as Mother of God (as declared in Luke
1:43, when Elizabeth calls her the "Mother of my Lord") and her ongoing role
as intercessor for the Church. It is the second part of the Hail Mary that
Catholics use to seek her intercession, especially in times of trial.

L<https://drbo.org/cgi-bin/d?b=drb&bk=49&ch=1&l=43-#x>

=head2 The Our Father

The Our Father comes directly from Jesus' teaching in the Gospel of Matthew
6:9-13:

=over 4

=item * Matthew 6:9-13

  Thus therefore shall you pray: Our Father who art in heaven, hallowed be Thy
  name. Thy kingdom come. Thy will be done, on earth as it is in heaven. Give
  us this day our daily bread. And forgive us our trespasses, as we forgive
  those who trespass against us. And lead us not into temptation, but deliver
  us from evil.

L<https://drbo.org/cgi-bin/d?b=drb&bk=47&ch=6&l=9-13#x>

=back

By meditating on the Mysteries of the Rosary, Catholics invite the presence
of Jesus into their lives, contemplating His birth, death, resurrection, and
the role of Mary in His story. These meditations, grouped into the Joyful,
Sorrowful, Glorious, and Luminous Mysteries, help to guide the faithful
through the essential moments of Christ's life and His salvation work.

=head2 The Rosary as a Communal Devotion

The Rosary is seen not just as a personal prayer, but as a communal devotion
that fosters a deeper understanding of God's love and a powerful means of
seeking His intercession. It is often prayed in groups, in parishes, or even
in families, helping to build unity within the faith community. Through its
rich combination of prayer and meditation, the Rosary has become a beloved
devotion for Catholics around the world, encouraging spiritual growth and
reflection on the central mysteries of the Christian faith.

The importance of daily prayer of the Rosary was emphasized by Our Lady
during the Apparitions at Fatima in 1917, where she specifically urged the
children to "pray the Rosary every day" for peace in the world and for the
salvation of souls, making it a call for all the faithful to embrace this
prayer as a tool for spiritual strength and intercession.  For more information
on Fatima, look up, "the Miracle of the Sun."

=head1 LICENSE AND COPYRIGHT

This module and utility is released under the same terms as Perl/perl.

=head1 REQUEST FOR COMMENTS

I have no idea how this is going to be used, and the way someone says the
Rosary tends to be highly personal; so please let me know what kind of
"--pray" controls would be helpful.

=head1 AUTHOR

Brett Estrade L<< <oodler@cpan.org> >>

+Deo Gratias+
