package WWW::AdventCalendar 1.114;
# ABSTRACT: a calendar for a month of articles (on the web)

use Moose;

use MooseX::StrictConstructor;

use autodie;
use Calendar::Simple 2; # the default start_day has changed
use Color::Palette 0.100002; # optimized_for, as_strict_css_hash
use Color::Palette::Schema;
use DateTime::Format::W3CDTF;
use DateTime;
use DateTime;
use File::Basename;
use File::Copy qw(copy);
use File::Path 2.07 qw(remove_tree);
use File::ShareDir;
use Gravatar::URL ();
use HTML::Mason::Interp;
use Moose::Util::TypeConstraints;
use Path::Class ();
use WWW::AdventCalendar::Article;
use XML::Atom::SimpleFeed;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This is a library for producing Advent calendar websites.  In other words, it
#pod makes four things:
#pod
#pod =for :list
#pod * a page saying "first door opens in X days" the calendar starts
#pod * a calendar page on and after the calendar starts
#pod * a page for each day in the month with an article
#pod * an Atom feed
#pod
#pod This library was originally written just for RJBS's Perl Advent Calendar, so it
#pod assumed you'd always be publishing from Dec 1 to Dec 24 or so.  It has recently
#pod been retooled to work across arbitrary ranges, as long as they're within one
#pod month.  This feature isn't well tested.  Neither is the rest of the code, to be
#pod perfectly honest, though...
#pod
#pod =head1 OVERVIEW
#pod
#pod To build an Advent calendar:
#pod
#pod =for :list
#pod 1. create an advent.ini configuration file
#pod 2. write articles and put them in a directory
#pod 3. schedule F<advcal> to run nightly
#pod
#pod F<advent.ini> is easy to produce.  Here's the one used for the original RJBS
#pod Advent Calendar:
#pod
#pod   title  = RJBS Advent Calendar
#pod   year   = 2009
#pod   uri    = http://advent.rjbs.manxome.org/
#pod   editor = Ricardo Signes
#pod   category = Perl
#pod   category = RJBS
#pod
#pod   article_dir = rjbs/articles
#pod   share_dir   = share
#pod
#pod These should all be self-explanatory.  Only C<category> can be provided more
#pod than once, and is used for the category listing in the Atom feed.
#pod
#pod These settings all correspond to L<calendar attributes/ATTRIBUTES> described
#pod below.  A few settings below are not given above.
#pod
#pod Articles are easy, too.  They're just files in the C<article_dir>.  They begin
#pod with an email-like set of headers, followed by a body written in Pod.  For
#pod example, here's the beginning of the first article in the original calendar:
#pod
#pod   Title:  Built in Our Workshop, Delivered in Your Package
#pod   Topic: Sub::Exporter
#pod
#pod   =head1 Exporting
#pod
#pod   In Perl, we organize our subroutines (and other stuff) into namespaces called
#pod   packages.  This makes it easy to avoid having to think of unique names for
#pod
#pod The two headers seen above, title and topic, are the only headers required,
#pod and correspond to those attributes in the L<WWW::AdventCalendar::Article>
#pod object created from the article file.
#pod
#pod Finally, running L<advcal> is easy, too.  Here is its usage:
#pod
#pod   advcal [-aot] [long options...]
#pod     -c --config       the ini file to read for configuration
#pod     -a --article-dir  the root of articles
#pod     --share-dir       the root of shared files
#pod     -o --output-dir   output directory
#pod     --today           the day we treat as "today"; default to today
#pod
#pod     -y --year-links   place year links at the bottom of the page
#pod
#pod Options given on the command line override those loaded form configuration.  By
#pod running this program every day, we cause the calendar to be rebuilt, adding any
#pod new articles that have become available.
#pod
#pod =head1 ATTRIBUTES
#pod
#pod =for :list
#pod = title
#pod The title of the calendar, to be used in headers, the feed, and so on.
#pod = tagline
#pod A tagline for the calendar, used in some templates.  Optional.
#pod = uri
#pod The base URI of the calendar, including trailing slash.
#pod = editor
#pod The name of the calendar's editor, used in the feed.
#pod = default_author
#pod The name of the calendar's default author, used for articles that provide none.
#pod = year
#pod The calendar year.  Optional, if you provide C<start_date> and C<end_date>.
#pod = start_date
#pod The start of the article-containing period.  Defaults to Dec 1 of the year.
#pod = end_date
#pod The end of the article-containing period.  Defaults to Dec 24 of the year.
#pod = categories
#pod An arrayref of category names for use in the feed.
#pod = article_dir
#pod The directory in which articles can be found, with names like
#pod F<YYYY-MM-DD.html>.
#pod = share_dir
#pod The directory for templates, stylesheets, and other static content.
#pod = output_dir
#pod The directory into which output files will be written.
#pod = today
#pod The date to treat as "today" when deciding how much of the calendar to publish.
#pod
#pod =cut

has title  => (is => 'ro', required => 1);
has uri    => (is => 'ro', required => 1);
has editor => (is => 'ro', required => 1);
has tagline => (is => 'ro', predicate => 'has_tagline');
has categories => (is => 'ro', default => sub { [ qw() ] });

has article_dir => (is => 'rw', required => 1);
has share_dir   => (is => 'rw', required => 1);
has output_dir  => (is => 'rw', required => 1);
has year_links  => (is => 'rw', required => 1, default => 0);

has default_author => (
  is  => 'ro',
  isa => 'Maybe[Str]', # should be using UndefTolerant instead!
                       # -- rjbs, 2011-11-08
);

has year       => (
  is   => 'ro',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    return $self->start_date->year if $self->_has_start_date;
    return $self->end_date->year   if $self->_has_end_date;

    return (localtime)[5] + 1900;
  },
);

class_type('DateTime', { class => 'DateTime' });
coerce  'DateTime', from 'Str', via \&_parse_isodate;

has start_date => (
  is   => 'ro',
  isa  => 'DateTime',
  lazy => 1,
  coerce  => 1,
  default => sub { DateTime->new(year => $_[0]->year, month => 12, day => 1) },
  predicate => '_has_start_date',
);

has end_date => (
  is   => 'ro',
  isa  => 'DateTime',
  lazy => 1,
  coerce  => 1,
  default => sub { DateTime->new(year => $_[0]->year, month => 12, day => 24) },
  predicate => '_has_end_date',
);

has today      => (is => 'rw');

class_type('Color::Palette', { class => 'Color::Palette' });

has color_palette => (
  is  => 'ro',
  isa => 'Color::Palette',
  required => 1,
);

has css_hrefs => (
  traits  => [ 'Array' ],
  handles => { css_hrefs => 'elements' },
  default => sub { [] },
);

sub _masonize {
  my ($self, $comp, $args) = @_;

  my $str = '';

  my $interp = HTML::Mason::Interp->new(
    comp_root  => [
      [ user  => $self->share_dir->subdir('templates')->absolute->stringify ],
      [ stock => Path::Class::dir(
          File::ShareDir::dist_dir('WWW-AdventCalendar') )
          ->subdir('templates')->absolute->stringify
      ],
    ],
    out_method => \$str,
    allow_globals => [ '$calendar' ],
  );

  $interp->set_global('$calendar', $self);

  $interp->exec($comp,
    year_links => $self->year_links,
    %$args
  );

  return $str;
}

sub _parse_isodate {
  my ($date, $time_from) = @_;

  my ($y, $m, $d) = $date =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/;
  die "can't parse date: $date\n" unless $y and $m and $d;

  $time_from ||= [ (0) x 10 ];

  return DateTime->new(
    year   => $y,
    month  => $m,
    day    => $d,
    hour   => $time_from->[2],
    minute => $time_from->[1],
    second => $time_from->[0],
    time_zone => 'local',
  );
}

sub BUILD {
  my ($self) = @_;

  $self->today(
    $self->today
    ? _parse_isodate($self->today, [localtime])
    : DateTime->now(time_zone => 'local')
  );

  confess "start_date, end_date, and year do not all agree"
    unless $self->year == $self->start_date->year
    and    $self->year == $self->end_date->year;

  confess "range from start_date to end_date must not cross a month boundary"
    if $self->start_date->month != $self->end_date->month;

  for (map { "$_\_dir" } qw(article output share)) {
    $self->$_( Path::Class::Dir->new($self->$_) );
  }
}

#pod =method build
#pod
#pod   $calendar->build;
#pod
#pod This method does all the work: it reads in the articles, decides how many to
#pod show, writes out the rendered pages, the index, and the atom feed.
#pod
#pod =cut

my $SCHEMA = Color::Palette::Schema->new({
  required_colors => [ qw(
    bodyBG
    bodyFG
    blotterBG
    blotterBorder
    contentBG
    contentBorder

    feedLinkFG

    headerFG

    linkFG

    linkDisabledFG

    linkHoverFG
    linkHoverBG

    quoteBorder

    sectionBorder

    taglineBG
    taglineFG
    taglineBorder

    titleFG

    calendarHeaderCellBorder
    calendarHeaderCellBG

    calendarIgnoredDayBG

    calendarPastDayBG
    calendarPastDayFG

    calendarPastDayHoverBG
    calendarPastDayHoverFG

    calendarTodayBG
    calendarTodayFG

    calendarTodayHoverBG
    calendarTodayHoverFG

    calendarFutureDayBG
    calendarFutureDayFG

    calendarMissingDayFG
    calendarMissingDayBG

    codeBG
    codeFG

    codeNumbersBG
    codeNumbersFG
    codeNumbersBorder
  ) ],
});

sub build {
  my ($self) = @_;

  $self->output_dir->rmtree;
  $self->output_dir->mkpath;

  my $share = $self->share_dir;
  copy "$_" => $self->output_dir
    for grep { ! $_->is_dir } $self->share_dir->subdir('static')->children;

  my $opt_palette = $self->color_palette->optimized_for($SCHEMA);

  $self->output_dir->file("style.css")->openw->print(
    $self->_masonize('/style.css', {
      color => $opt_palette->as_strict_css_hash,
    }),
  );

  my $feed = XML::Atom::SimpleFeed->new(
    title   => $self->title,
    id      => $self->uri,
    link    => {
      rel  => 'self',
      href => $self->uri . 'atom.xml',
    },
    updated => $self->_w3cdtf($self->today),
    author  => $self->editor,
  );

  my %month;
  for (
    1 .. DateTime->last_day_of_month(
      year  => $self->year,
      month => $self->start_date->month
    )->day
  ) {
    $month{$_} = DateTime->new(
      year  => $self->year,
      month => $self->start_date->month,
      day   => $_,
      time_zone => 'local',
    );
  }

  if ($self->start_date > $self->today) {
    my $dur  = $self->start_date->subtract_datetime_absolute( $self->today );
    my $days = int($dur->delta_seconds / 86_400  +  1);
    my $str  = $days != 1 ? "$days days" : "1 day";

    $self->output_dir->file("index.html")->openw->print(
      $self->_masonize('/patience.mhtml', {
        days => $str,
        year => $self->year,
      }),
    );

    $feed->add_entry(
      title     => $self->title . " is Coming",
      link      => $self->uri,
      id        => $self->uri,
      summary   => "The first door opens in $str...\n",
      updated   => $self->_w3cdtf($self->today),

      (map {; category => $_ } @{ $self->categories }),
    );

    $feed->print( $self->output_dir->file('atom.xml')->openw );

    return;
  }

  my $article = $self->read_articles;

  {
    my $d = $month{1};
    while (
      $d->ymd le (sort { $a cmp $b } ($self->end_date->ymd, $self->today->ymd))[0]
    ) {
      warn "no article written for " . $d->ymd . "!\n"
        if $d >= $self->start_date && ! $article->{ $d->ymd };

      $d = $d + DateTime::Duration->new(days => 1 );
    }
  }

  $self->output_dir->file('index.html')->openw->print(
    $self->_masonize('/calendar.mhtml', {
      today  => $self->today,
      year   => $self->year,
      month  => \%month,
      calendar => scalar calendar(12, $self->year, 0),
      articles => $article,
    }),
  );

  my @dates = sort keys %$article;
  for my $i (0 .. $#dates) {
    my $date = $dates[ $i ];

    my $output;

    print "processing article for $date...\n";
    my $txt = $self->_masonize('/article.mhtml', {
      article => $article->{ $date },
      date    => $date,
      next    => ($i < $#dates ? $article->{ $dates[ $i + 1 ] } : undef),
      prev    => ($i > 0       ? $article->{ $dates[ $i - 1 ] } : undef),
      year    => $self->year,
    });

    my $bytes = Encode::encode('utf-8', $txt);
    $self->output_dir->file("$date.html")->openw->print($bytes);
  }

  for my $date (reverse @dates){
    my $article = $article->{ $date };

    $feed->add_entry(
      title     => HTML::Entities::encode_entities($article->title),
      link      => $self->uri . "$date.html",
      id        => $article->atom_id,
      summary   => $article->body_html,
      updated   => $self->_w3cdtf($article->date),
      (map {; category => $_ } @{ $self->categories }),

      author => { name => $article->author_name },
    );
  }

  $feed->print( $self->output_dir->file('atom.xml')->openw );
}

sub _w3cdtf {
  my ($self, $datetime) = @_;
  DateTime::Format::W3CDTF->new->format_datetime($datetime);
}

#pod =method read_articles
#pod
#pod   my $article = $calendar->read_articles;
#pod
#pod This method reads in all the articles for the calendar and returns a hashref.
#pod The keys are dates (in the format C<YYYY-MM-DD>) and the values are
#pod L<WWW::AdventCalendar::Article> objects.
#pod
#pod =cut

sub read_articles {
  my ($self) = @_;

  my %article;

  for my $file (grep { ! $_->is_dir } $self->article_dir->children) {
    my ($name, $path) = fileparse($file);
    $name =~ s{\..+\z}{}; # remove extension

    open my $fh, '<:encoding(utf-8)', $file;
    my $content = do { local $/; <$fh> };
    my ($header, $body) = split /\n{2,}/, $content, 2;

    my %header;
    for my $line (split /\n/, $header) {
      my ($name, $value) = split /\s*:\s*/, $line, 2;
      $header{lc $name} = $value;
    }

    my $isodate  = $name;

    die "no title set in $file\n" unless $header{title};

    my $article  = WWW::AdventCalendar::Article->new(
      body   => scalar $body,
      date   => scalar _parse_isodate($isodate),
      title  => $header{title},
      topic  => $header{topic},
      author => $header{author}
             // scalar $self->default_author,
      calendar => $self,
    );

    next unless $article->date < $self->today;

    die "already have an article for " . $article->date->ymd
      if $article{ $article->date->ymd };

    $article{ $article->date->ymd } = $article;
  }

  return \%article;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::AdventCalendar - a calendar for a month of articles (on the web)

=head1 VERSION

version 1.114

=head1 DESCRIPTION

This is a library for producing Advent calendar websites.  In other words, it
makes four things:

=over 4

=item *

a page saying "first door opens in X days" the calendar starts

=item *

a calendar page on and after the calendar starts

=item *

a page for each day in the month with an article

=item *

an Atom feed

=back

This library was originally written just for RJBS's Perl Advent Calendar, so it
assumed you'd always be publishing from Dec 1 to Dec 24 or so.  It has recently
been retooled to work across arbitrary ranges, as long as they're within one
month.  This feature isn't well tested.  Neither is the rest of the code, to be
perfectly honest, though...

=head1 OVERVIEW

To build an Advent calendar:

=over 4

=item 1

create an advent.ini configuration file

=item 2

write articles and put them in a directory

=item 3

schedule F<advcal> to run nightly

=back

F<advent.ini> is easy to produce.  Here's the one used for the original RJBS
Advent Calendar:

  title  = RJBS Advent Calendar
  year   = 2009
  uri    = http://advent.rjbs.manxome.org/
  editor = Ricardo Signes
  category = Perl
  category = RJBS

  article_dir = rjbs/articles
  share_dir   = share

These should all be self-explanatory.  Only C<category> can be provided more
than once, and is used for the category listing in the Atom feed.

These settings all correspond to L<calendar attributes/ATTRIBUTES> described
below.  A few settings below are not given above.

Articles are easy, too.  They're just files in the C<article_dir>.  They begin
with an email-like set of headers, followed by a body written in Pod.  For
example, here's the beginning of the first article in the original calendar:

  Title:  Built in Our Workshop, Delivered in Your Package
  Topic: Sub::Exporter

  =head1 Exporting

  In Perl, we organize our subroutines (and other stuff) into namespaces called
  packages.  This makes it easy to avoid having to think of unique names for

The two headers seen above, title and topic, are the only headers required,
and correspond to those attributes in the L<WWW::AdventCalendar::Article>
object created from the article file.

Finally, running L<advcal> is easy, too.  Here is its usage:

  advcal [-aot] [long options...]
    -c --config       the ini file to read for configuration
    -a --article-dir  the root of articles
    --share-dir       the root of shared files
    -o --output-dir   output directory
    --today           the day we treat as "today"; default to today

    -y --year-links   place year links at the bottom of the page

Options given on the command line override those loaded form configuration.  By
running this program every day, we cause the calendar to be rebuilt, adding any
new articles that have become available.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 build

  $calendar->build;

This method does all the work: it reads in the articles, decides how many to
show, writes out the rendered pages, the index, and the atom feed.

=head2 read_articles

  my $article = $calendar->read_articles;

This method reads in all the articles for the calendar and returns a hashref.
The keys are dates (in the format C<YYYY-MM-DD>) and the values are
L<WWW::AdventCalendar::Article> objects.

=head1 ATTRIBUTES

=over 4

=item title

The title of the calendar, to be used in headers, the feed, and so on.

=item tagline

A tagline for the calendar, used in some templates.  Optional.

=item uri

The base URI of the calendar, including trailing slash.

=item editor

The name of the calendar's editor, used in the feed.

=item default_author

The name of the calendar's default author, used for articles that provide none.

=item year

The calendar year.  Optional, if you provide C<start_date> and C<end_date>.

=item start_date

The start of the article-containing period.  Defaults to Dec 1 of the year.

=item end_date

The end of the article-containing period.  Defaults to Dec 24 of the year.

=item categories

An arrayref of category names for use in the feed.

=item article_dir

The directory in which articles can be found, with names like
F<YYYY-MM-DD.html>.

=item share_dir

The directory for templates, stylesheets, and other static content.

=item output_dir

The directory into which output files will be written.

=item today

The date to treat as "today" when deciding how much of the calendar to publish.

=back

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Dave Cross Len Jaffe Ricardo Signes Shoichi Kaji

=over 4

=item *

Dave Cross <dave@davecross.co.uk>

=item *

Len Jaffe <lenjaffe@jaffesystems.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Shoichi Kaji <skaji@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
