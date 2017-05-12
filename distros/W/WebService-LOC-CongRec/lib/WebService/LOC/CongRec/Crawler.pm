package WebService::LOC::CongRec::Crawler;
our $VERSION = '0.4';
use Moose;
with 'MooseX::Log::Log4perl';

use WebService::LOC::CongRec::Util;
use WebService::LOC::CongRec::Day;
use WebService::LOC::CongRec::Page;
use DateTime;
use WWW::Mechanize;
use HTML::TokeParser;

=head1 SYNOPSIS

    use WebService::LOC::CongRec::Crawler;
    use Log::Log4perl;
    Log::Log4perl->init_once('log4perl.conf');
    $crawler = WebService::LOC::CongRec::Crawler->new();
    $crawler->congress(107);
    $crawler->oldest(1);
    $crawler->goForth();

=head1 ATTRIBUTES

=over 1

=item congress

The numbered congress to be fetched.  If this is not given, the current congress is fetched.

=cut

has 'congress' => (
    is  => 'rw',
    isa => 'Int',
);

=item issuesRoot

The root page for Daily Digest issues.

Breadcrumb path:
Library of Congress > THOMAS Home > Congressional Record > Browse Daily Issues

=cut

has 'issuesRoot' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://thomas.loc.gov/home/Browse.php?&n=Issues',
);

=item issues

A hash of issues: %issues{year}{month}{day}{section}

=cut

has 'issues' => (
    is          => 'rw',
    isa         => 'ArrayRef',
    auto_deref  => 1,
    default     => sub { [] },
);

=item mech

A WWW::Mechanize object with state that we can use to grab the page from Thomas.

=cut

has 'mech' => (
    is          => 'rw',
    isa         => 'Object',
    builder     => '_build_mech',
);

=item oldest

Boolean attribute specifying that pages are visited from earliest to most recent.

The default is 0 - that is visit most recent first.

=cut

has 'oldest' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 0,
);

=back

=cut

sub _build_mech {
    return WWW::Mechanize->new(
        agent => 'CongRec https://github.com/dinomite/WebService-LOC-CongRec; ' .
                    WWW::Mechanize->VERSION,
    );
}

=head1 METHODS

=head2 goForth()

 $crawler->goForth();
 $crawler->goForth(process => \&process_page);
 $crawler->goForth(start => $x);
 $crawler->goForth(end => $y);

Start crawling from the Daily Digest issues page, i.e.
http://thomas.loc.gov/home/Browse.php?&n=Issues

Also, for a specific congress, where NUM is congress number:
http://thomas.loc.gov/home/Browse.php?&n=Issues&c=NUM

Returns the total number of pages grabbed.

Accepts an optional processing function to perform for each page.

Accpets optional page counter start and end ranges.  If neither are
given, or given as zero, crawing starts from the beginning and
goes until all pages are visited.

=cut

sub goForth {
    my $self = shift;
    my $args = {
        process => undef,
        start   => 0,
        end     => 0,
        @_
    };
    my $n = \$args->{start};  # Page iterator
    my $grabbed = 0;  # Pages seen.
    my $seen = 0;  # Issues seen.

    my $url = $self->issuesRoot;
    $url .= '&c=' . $self->congress if $self->congress;

    $self->mech->get($url);
    $self->parseRoot($self->mech->content);

    # Go through each of the days
    foreach my $day (@{$self->issues}) {
        last if $args->{end} && $seen >= $args->{end};

        $self->log->info("Date: " . $day->date->strftime('%Y-%m-%d') . "; " . $day->house);

        # Each of the pages for day
        foreach my $pageURL (@{$day->pages}) {
            last if $args->{end} && $seen >= $args->{end};
            $seen++;  # Increment issue.
            next if $args->{start} && $seen < $args->{start};

            $self->log->debug("Getting page: $pageURL");

            my $webPage = WebService::LOC::CongRec::Page->new(
                    mech => $self->mech, 
                    url => $pageURL,
            );

            # Invoke the callback if one was provided
            eval { $args->{process}->($day, $webPage) }
                if $args->{process} && ref $args->{process} eq 'CODE';
            $self->log->warn($@) if $@;

            $$n++;  # Increment page number visited.
            $grabbed++;  # Increment total pages visited.
        }
    }

    return $grabbed;
}

=head2 parseRoot(Str $content)

Parse the the root of an issue an fill our hash of available issues

=cut

sub parseRoot {
    my ($self, $content) = @_;

    my $p = HTML::TokeParser->new(\$self->mech->content);

    # Collect the issues for each date.
    my ($text, $year, $month, $day);
    while (my $t = $p->get_token) {
        my ($ttype, $ttag) = ($t->[0], $t->[1]);

        if ($ttype eq 'S' && $ttag eq 'td') {
            $text = $p->get_trimmed_text("/$ttag");
        }
        # Old HTML type for pre-111 congress pages.
        elsif ($ttype eq 'E' && $ttag eq 'td' && $text =~ /^([A-Za-z]+)\s+(\d{4})$/) {
            ($month, $year) = ($1, $2);
            if ($year and $month and $day) {
                $month = WebService::LOC::CongRec::Util->getMonthNumberFromString($month);
                $self->_dayToIssues($year, $month, $day);
            }
        }
        elsif ($ttype eq 'E' && $ttag eq 'td' && $text =~ /^([A-Za-z]+)\s+(\d{1,2})$/) {
            ($month, $day) = ($1, $2);
        }
        # New HTML type for post-111 congress pages.
        elsif ($ttype eq 'S' && $ttag eq 'th') {
            $text = $p->get_trimmed_text("/$ttag");
        }
        elsif ($ttype eq 'E' && $ttag eq 'th' && $text =~ /^[A-Za-z]+\s+(\d{4})$/) {
            $year = $1;
        }
        elsif ($ttype eq 'E' && $ttag eq 'td' && $text =~ /^(\d+)\/(\d+)$/) {
            ($month, $day) = ($1, $2);
            if ($year and $month and $day) {
                $self->_dayToIssues($year, $month, $day);
            }
        }
    }
}

sub _dayToIssues {
    my($self, $year, $month, $day) = @_;

    # Create a Day object for each section.
    for my $section (qw(h s e d)) {
        my $date = DateTime->new(year => $year, month => $month, day => $day, time_zone => 'America/Los_Angeles');
        if ($self->oldest) {
            unshift @{$self->issues}, $self->makeDay($date, $section);
        }
        else {
            push @{$self->issues}, $self->makeDay($date, $section);
        }
    }
}


sub makeDay {
    my ($self, $date, $house) = @_;

    my $day = WebService::LOC::CongRec::Day->new(
            mech    => $self->mech,
            date    => $date,
            house   => $house,
    );

    return $day;
}

1;
