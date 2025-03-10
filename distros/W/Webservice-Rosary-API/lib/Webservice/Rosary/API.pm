package Webservice::Rosary::API;

use v5.10;
use strict;

use Util::H2O::More qw/baptise ddd HTTPTiny2h2o h2o o2d/;
use HTTP::Tiny qw//;

our $VERSION = "0.1.5";

use constant {
  BASEURL  => "https://the-rosary-api.vercel.app/v1",
  DAILYURL => "https://dailyrosary.cf",
};

sub new {
  my $pkg = shift;
  my $params = { @_, ua => HTTP::Tiny->new };
  my $self = baptise $params, $pkg, qw//;
  return $self;
}

sub _make_call {
  my ($self, $when) = @_;
  my $URL = sprintf "%s/%s", BASEURL, $when;
  my $resp = HTTPTiny2h2o $self->ua->get($URL);
  return $resp->content;
}

sub mp3Link {
  my ($self, $when) = @_;
  my @mp3 = qw/today yesterday tomorrow random/;
  # invalid
  return "" if (not grep { m/^$when$/i } @mp3);
  # valid
  my $resp = $self->_make_call($when);
  my $ref = $resp->shift;
  # the problem here is that this API call in the past has returned
  # a JSON hash rather than an array in some cases; in other cases
  # it has returned an empty JSON array
  if (my $ref = $resp->shift) {
    return sprintf "%s/%s", DAILYURL, $ref->mp3Link;
  }
  elsif (ref o2d $resp ne "ARRAY" and my $file = $resp->mp3Link) {
    return sprintf "%s/%s", DAILYURL, $file;
  }
  else {
    warn "\nNo content in response from https://therosaryapi.cf ... try the following links:\n";
    warn <<EOF;

    https://www.discerninghearts.com/catholic-podcasts/holy-rosary/ - 

      + https://www.discerninghearts.com/Devotionals/Rosary-Joyful-Mysteries.mp3

      + https://www.discerninghearts.com/Devotionals/Rosary-Luminous-Mysteries.mp3

      + https://www.discerninghearts.com/Devotionals/Rosary-Sorrowful-Mysteries.mp3

      + https://www.discerninghearts.com/Devotionals/Rosary-Glorious-Mysteries.mp3

... please try back again later
EOF
    die "\n";
  }
}

sub day {
  my ($self, $when) = @_;
  my @days = qw/sunday monday tuesday wednesday thursday friday/;
  return "" if (not grep { m/^$when$/i } @days);
  return $self->_make_call($when)->get(0);
}

# Get detailed recitations
sub details {
  my ($self, $when) = @_;
  my @mysteries = qw/joyful glorious sorrowful luminous/;
  return "" if (not grep { m/^$when$/i } @mysteries);
  return $self->_make_call($when);
}

123

__END__

=head1 NAME

Webservice::Rosary::API - Perl API client for the Rosary API at
L<https://therosaryapi.cf> and L<https://dailyrosary.cf>.

=head1 SYNOPSIS

  use v5.10;
  use warnings;
  my $Rosary = Webservice::Rosary::API->new;
   
  my $mp3File = $Rosary->mp3Link("random");
  printf "https://dailyrosary.cf/%s", $mp3File;

=head1 DESCRIPTION

This is an API client for L<https://therosaryapi.cf>, which powers
L<https://dailyrosary.cf>*; the API requires no authentication, so the
client here simply wraps most of the calls for convient use in Perl programs.

It is meant to faciliate a couple of things. One is the generation of a
full URL that may be used to download an audio file of the specified Mystery
being said, as an C<.mp3> file.  This means you may do something like what
is done at L<https://dailyrosary.cf>.

The second this it is meant to do is to return the text of a full recitation
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

Constructor, accepts any number of parameters and makes them available
during execution time; but doesn't do anything internally with them. Instance
construction consists of creating a C<ua> instance via L<HTTP::Tiny>.

  my $Rosary = Webservice::Rosary::API->new; ...

=item C<mp3Link("today" | "tomorrow" | "yesterday" | "random")>

Given the string describing I<when>, returns the file name return by the
API service.  It is not documented, but the base URL for the actual file is,
L<https://dailyrosary.cf>.

  my $Rosary = Webservice::Rosary::API->new; my $mp3File =
  $Rosary->mp3Link("random"); ...

See the C<avemaria> commandline client to see how the full URL is constructed
and for an example of using this incombination with C<curl> to automatically
download the C<.mp3> file.

B<Error Handling>

If the server responds, but has not content (which has been experienced
during the creation of this module), this method will C<die> and print
an appropriate message to C<STDERR> unless caught. C<avemaria> doesn't
try to catch this case. 

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

Then the day of the week obtained via `$Convert->{$mystery}` can be used
used to derive the proper day to be used with this call.

* - although, any Mystery may be said on any day

B<Error Handling>

None.

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

The C<avemaria> commandline Rosary client is installed with this module. The
following is essentially verbatim from the client using the C<help> command.

Note: Commandline options may change to accomodate feedback. This note will
be removed once the cli UX settles.

B<Quick Start>

  > avemaria                         # no arguments
  > ... runs through the recitation of the Rosary for today, equivalent,
    to,

  > avemaria $(date "+%A") --pray -t # `date` commands prints out today's day of week

B<Getting Help>

  > avemaria help
  > ... prints help section

B<Learning More>

  > avemaria about
  > ... prints an "about" section

B<Functional Commands>

There are 2 types of functional commands. One set of commands returns a URL
for an MP3, which may then be piped into another program to download it. The
other set of commands displays the specified Mystery (by day of the week
or actual name of the Mystery), so that the user may be guided through the
specified Mystery of the Rosary - from start to finish.

B<Usage - to print MP3 URL to STDIN:>

  avemaria [today | yesterday | tomorrow | random]

I<Example 1>

  > avemaria today
  > https://dailyrosary.cf/audio-rosary-sorrowful-mysteries.mp3
   
I<Example 2>

  > curl -O \$(avemaria random) -w "\\nDownloaded file: %{filename_effective}\\n"
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                   Dload  Upload   Total   Spent    Left  Speed
  100 31.5M  100 31.5M    0     0  2374k      0  0:00:13  0:00:13 --:--:-- 5043k
  
  Downloaded file: audio-rosary-sorrowful-mysteries.mp3
  >

B<Usage - to Pray the Rosary in the commandline:>

  avemaria DAY_OR_MYSTERY [--pray] [-i] [-t] [--fully] [--sleep=0.N] 

  Valid DAY_OR_MYSTERY values:

    Joyful, Sorrowful, Luminous, Glorious, Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, or Saturday

  Optional flags:

  --pray   : automatically prints prayers, character by character to the screen; default delay is 0.4 seconds.
   -i      : user must hit <RETURN> after each prayer (and description, if used with "--fully"
   -t      : user must hit <RETURN> after each description (requires --fully)
  --fully  : prints the full description of the current Mystery's Decade, including the Fruit of the Mystery
  --sleep  : affects the delay taken before each new character is printed (when used with --pray). Default is 0.4 seconds.

I<Example 3>

  Used without options, it just prints the name of the Mystery

  > avemaria Monday
  > Monday - The Joyful Mysteries
  >

  > avemaria Sorrowful
  > Friday - The Sorrowful Mysteries
  >

I<Example 4>

  > avemaria Friday --pray -t --fully
  > .. clears screen, the plays the specified Mystery (Sorrowful in this case),
    while pausing only at the beginning of each Mystery after the description has
    been printed.

I<Example 5>

  Run with absolutely no subcommands or flags, runs "--pray" for today's Mystery,

  > avemaria
  > .. clears screen, the plays the specified Mystery for today ...

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
