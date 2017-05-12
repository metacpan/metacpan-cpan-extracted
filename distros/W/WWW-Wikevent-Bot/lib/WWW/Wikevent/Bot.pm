package WWW::Wikevent::Bot;
#
# Copyright 2007 Mark Jaroski
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either:
# 
# a) the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version,
# or
# b) the "Artistic License" which comes with this Kit.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
# 
# You should have received a copy of the Artistic License with this Kit,
# in the file named "Artistic".
# 
# You should also have received a copy of the GNU General Public License
# along with this program in the file named "Copying". If not, write to
# the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA 02111-1307, USA or visit their web page on the internet at
# http://www.gnu.org/copyleft/gpl.html.

use warnings;
use strict;
use WWW::Mediawiki::Client;
use WWW::Wikevent::Event;
use Date::Format;
use Digest::MD5 qw(md5_hex);
use Encode;
use utf8;

use base 'Exporter';
our %EXPORT_TAGS = (
	options => [qw(OPT_YES OPT_NO OPT_DEFAULT OPT_KEEP)],
);
our @EXPORT_OK = map { @{$EXPORT_TAGS{$_}} } keys %EXPORT_TAGS;

our $VERSION = 0.2.0;

=head1 NAME

WWW::Wikevent::Bot

=cut

=head1 SYNOPSIS

  use WWW::Wikevent::Bot;
  use HTML::TreeBuilder;
  use utf8;

  my $bot = WWW::Wikevent::Bot->new();
  $bot->name( 'HideoutBot' );
  $bot->url( 'http://www.hideoutchicago.com/schedule.html' );
  $bot->sample( 'sample.html' );
  $bot->encoding( 'utf8' );

  $bot->parser( sub {
      my ( $bot, $html ) = @_;
      
      # Use HTML::TreeBuilder and HTML::Element, or if you prefer
      # HTML::TokeParser to parse the HTML down to whatever elements
      # contains events, then ...
      foreach my $container ( @event_containers ) {
          my $event = $bot->add_event();

          # build up the event using methods of L<HTML::Wikevent::Event>
      }

      # Figure out the next page to scrape (not needed if you are parsing
      # by month) and set

      $bot->url( $next_page_to_scrape );
  });
  
  $bot->scrape();
  $bot->upload();
  
=cut

=head1 DESCRIPTION

WWW::Wikevent::Bot is a package which will help you write scraper scripts
for gathering events from venue and artist websites and for inclusion in
the Free content events compendium, Wikevent.

The module takes care of the tedium of interaction with the website, and
leaves to you the fun work of writing the scraper subroutine for the venue
or artist you are interested in.

=cut

=head1 CONSTANTS

item $SEEN_FILE

=cut

my $SEEN_FILE = '.processed_events';

my $Mvs = WWW::Mediawiki::Client->new();
my $Ua = LWP::UserAgent->new();

my @Events;


=head1 CONSTRUCTORS

=cut

=head2 new

Creates a new bot object.

=cut

sub new {
    my $pkg = shift;
    my %init = @_;
    my $self = bless {};
    foreach my $key ( keys %init ) {
        if ( $key eq 'name' ) {
            $self->name( $init{$key} );
        } elsif ( $key eq 'parser' ) {
            $self->parser( $init{$key} );
        } elsif ( $key eq 'url' ) {
            $self->url( $init{$key} );
        }
    }
    $self->{'events'} = [];
    $self->{'months'} = 3;
    $self->{'last_url'} = '';
    $self->load_remembered_events();
    return $self;
}

=head1 ACCESSORS

=cut

=head2 name
  
  $bot->name( $bot_name );

The name of your bot.

This setting will be used to control where your bot will submit information
about itself and the list of events it scrapes on each run.

=cut

sub name {
    my ( $self, $name ) = @_;
    if ( $name ) {
        $self->{'name'} = $name;
        $self->user_dir( "User:$self->{'name'}" );
        $self->user_page( "User:$self->{'name'}.wiki" );
        $self->shows_page( "User:$self->{'name'}/Shows.wiki" );
    }
    return $self->{'name'};
}

=head2 events

  my @events = $bot->events()

or

  my $event_ref = $bot->events()

The list of events which this bot has scraped (so far).

=cut 

sub events {
    my $self = shift;
    return wantarray ? @{$self->{'events'}} : $self->{'events'};
}

=head2 sample

  $bot->sample( 'somepage.html' );

A local file containing a sample page to scrape while you are building and
debugging your parser subroutine.

=cut

sub sample {
    my ( $self, $sample ) = @_;
    $self->{'sample'} = $sample if $sample;
    return $self->{'sample'};
}

=head2 charset
  
  $bot->charset( 'utf8' );

The charset of the target site/page.

Sometimes the charset is detected incorrectly, or even set incorrectly in
venue and artist webpages.  This lets you override.

=cut

sub charset {
    my ( $self, $charset ) = @_;
    $self->{'charset'} = $charset if $charset;
    return $self->{'charset'};
}

=head2 encoding

An alias for charset, if you prefer.

=cut

sub encoding {
    my ( $self, $charset ) = @_;
    $self->{'charset'} = $charset if $charset;
    return $self->{'charset'};
}

=head2 url

  $bot->url( 'http://venue.com/schedule.html' );

The next URL to scrape.

Initially you should set this to the first page which your scraper bot
should look at.  Afterwords if there are more pages to scrape you'll set it
again in your parser subroutine.

If the site you're scraping has calendar pages with elements of the date in
the URL you can put Date::Format placeholders in the your URL string, as
in:

  $bot->url( 'http://venue.com/calendar.html?year=%Ymonth=%L' );

.. and your bot will scrape C<months> months ahead from the current month,
whatever that is.  You can of course override this behaviour by specifying
a new URL to parse in the parser subroutine, but then you'll have to do all
of the date calculation yourself.

=cut

sub url {
    my ( $self, $url ) = @_;
    $self->{'url'} = $url if $url;
    return $self->{'url'};
}

=head2 months

  $bot->months( $int );
  my $int = $bot->months();

The number of months to scrape if C<url> is a Date::Format specification.

Defaults to 3.

=cut

sub months {
    my ( $self, $months ) = @_;
    $self->{'months'} = $months if $months;
    return $self->{'months'};
}

sub parser {
    my ( $self, $parser ) = @_;
    $self->{'parser'} = $parser if $parser;
    return $self->{'parser'};
}

=head2 user_dir

  my $dir = $bot->user_dir( $dir );

The directory to which your events will be dumped.

Normally this is set as a side-effect of setting the C<name> accessor,
however it can be optionally set to something else I<after> setting
C<name>.

=cut

sub user_dir {
    my ( $self, $user_dir ) = @_;
    $self->{'user_dir'} = $user_dir if $user_dir;
    return $self->{'user_dir'};
}

=head2 user_page

  my $page = $bot->user_page( $page );

The page on which information about your bot is to be found.

Normally this is set as a side-effect of setting the C<name> accessor,
however it can be optionally set to something else I<after> setting
C<name>.

=cut

sub user_page {
    my ( $self, $user_page ) = @_;
    $self->{'user_page'} = $user_page if $user_page;
    return $self->{'user_page'};
}

=head2 shows_page

  my $page = $bot->shows_page( $page );

The page to which events scraped by your bot will be uploaded.

Normally this is set as a side-effect of setting the C<name> accessor,
however it can be optionally set to something else I<after> setting
C<name>.

=cut

sub shows_page {
    my ( $self, $shows_page ) = @_;
    $self->{'shows_page'} = $shows_page if $shows_page;
    return $self->{'shows_page'};
}

=head1 METHODS

=cut

=head2 add_event

  my $e = $bot->add_event();

Create a new event and return it.

This is a convenience method which both creates a new event, adds it to
C<events> list (see above) and returns a refernce to which you may
manipulate as necessary.

=cut

sub add_event {
    my $self = shift;
    my $event = WWW::Wikevent::Event->new();
    push @{$self->{'events'}}, $event;
    return $event;
}

=head2 parse

  my @events = $bot->parse( $html );

or 

  my $events_ref = $bot->parse( $html );

Run the user supplised C<parser> subroutine against the argument HTML and
return any events found.  This is used internally by C<scrape>.

=cut

sub parse {
    my ( $self, $html ) = @_;
    $self->parser->( $self, $html );
    return wantarray ? @{$self->events()} : $self->events();
}

=head2 check_allowed

   $bot->check_allowed();

Check the user page of this bot to see if it is currently allowed to run.
This will be indicated by the text:

  run = true

at the top of the page.  If that text is present return true, other wise
die with an error.  This method is called internally by C<upload> so you
don't have to call it, but you do have to make sure that the above text
appears on the bot's user page.

=cut

sub check_allowed {
    my $self = shift();
    $Mvs->do_login();
    # check to see if run = true
    $Mvs->do_update( $self->{'user_page'} );
    open UP, $self->{'user_page'};
    my $go = undef;
    while ( <UP> ) {
        next if m{^\s*$};
        last if m{^\s*==[^=]*==\s*$};
        if ( m{^\s*run\s*=\s*(\w+)\s*$} ) {
            $go = $1;
        }
    }
    die "Not allowed to run, according to user page."
        unless $go;
    close UP;
}

sub create_account {
}

=head2 scrape_sample

  $bot->scrape_sample();

Runs the C<parser> against the supplied C<sample> HTML page.

=cut

sub scrape_sample {
    my $self = shift;
    my $file = $self->sample();
    my $in;
    if ( $self->charset() ) {
        my $c = $self->charset();
        open( $in, "<:encoding($c)", $file )
                or die "Could not open sample file '$file'. $!\n";
    } else {
        open( $in, "<", $file )
                or die "Could not open sample file '$file'. $!\n";
    }
    local $/ = undef;
    my $html = <$in>;
    close $in;
    $self->events( $self->parse( $html ) );
}

sub find_month_urls {
    my $self = shift;
    my @calendar_urls;
#   from perlfunc:
#   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
#   thus:  0    1     2     3    4     5     6     7      8
    my @lt = localtime(time);
    for ( my $i = 0; $i < $self->months(); $i++ ) {
        my $url = strftime( $self->url(), @lt );
        $lt[4]++;
        if ( $lt[4] > 11 ) {
            $lt[4] = 0;
            $lt[5]++;
        }
        push @calendar_urls, $url;
    }
    return wantarray ? @calendar_urls : \@calendar_urls;
}

=head2 scrape

  $bot->scrape();

Starts scraping at the supplied C<url> and continues as long as C<url>
changes.
    
=cut

sub scrape {
    my $self = shift;
    if ( $self->url() =~ m{%[A-z]} ) {
        foreach my $url ( $self->find_month_urls() ) {
            $self->scrape_page( $url );
        }
    } else {
        while ( $self->url() and ( $self->url() ne $self->{last_url} ) ) {
            $self->{last_url} = $self->url();
            $self->scrape_page( $self->url() );
        }
    }
}

=head2 scrape_page

  $bot->scrape_page( $url );

Scrapes a single page of HTML found at the given URL.  This method is
called internally by C<scrape>.

=cut

sub scrape_page {
    my ( $self, $url ) = @_;
    my $html;
    print "fetching $url\n"; #FIXME
    my $res = $Ua->get( $url );
    die "couldn't fetch $url." unless $res->is_success();
    if ( $self->charset() ) {
        $html = $res->decoded_content( charset => $self->charset() );
    } else {
        $html = $res->decoded_content();
    }
    $self->parse( $html );
}

=head2 dump

  $bot->dump();

Dumps the contents of C<events> as text to standard out.

=cut

sub dump {
    my $self = shift;
    foreach my $e ( $self->events() ) {
        print $e;
    }
    return 1;
}

=head2 remember
  
  $bot->remember( $event );

Records an md5sum of the given event, so as to not repeat it again when
running C<dump_to_file>.

=cut

sub remember {
    my ( $self, $event ) = @_;
    my $token = md5_hex( encode( "iso-8859-1", $event->to_string() ) );
    $self->{known_events}->{$token} = 1;
    open OUT, ">>$SEEN_FILE"
            or die 'could not open file for seen events';
    print OUT "$token\n";
    close OUT;
}

=head2 load_remembered_events

  $bot->load_remembered_events

Loads in the md5sums of previously C<remember>ed events.  This is called
internally by C<new> so it's unlikely that you will need to call it.

=cut

sub load_remembered_events {
    my ( $self, $event ) = @_;
    unless ( open SEEN, $SEEN_FILE ) { 
        open SEEN, ">$SEEN_FILE" 
                or die 'could not open file for seen events';
        print SEEN "\n";
        close SEEN;
        open SEEN, $SEEN_FILE
                or die 'could not open file for seen events';
    }
    while ( my $token = <SEEN> ) {
        chomp( $token );
        $self->{known_events}->{$token} = 1;
    }
    close SEEN;
}

=head2 is_new

  my $bool = $bot->is_new( $event );

Checks to see if the md5sum of an event is in our list of C<remember>ed
events.

=cut

sub is_new {
    my ( $self, $event ) = @_;
    my $token = md5_hex( encode( "iso-8859-1", $event->to_string() ) );
    if ( $self->{known_events}->{$token} ) {
        return 0;
    } else {
        return 1;
    }
}

=head2 dump_to_file
  
  $bot->dump_to_file

Prints out the events in their final form to the appropriate .wiki file for
upload to the bot's event page.  This is called internally by C<upload> but
is also useful for the last stages of writing and debugging your bot.

=cut

sub dump_to_file {
    my $self = shift;
    if ( ! -e $self->user_dir() ) {
        mkdir $self->user_dir()
                or die "could not make directory: " . $self->user_dir() .  "\n";
    }
    open my $out, ">:encoding(utf-8)",  $self->shows_page()
            or die "could not open wiki file: " . $self->shows_page() . "\n";
    foreach my $e ( $self->events() ) {
        if ( $self->is_new( $e ) ) {
            print $out $e;
            $self->remember( $e );
        }
    }
    close $out;
    return 1;
}

=head2 upload

  $bot->upload();

This is the method which interacts with the Wikevent server, first checking
to see if the bot is allowed to proceed, then doing an update, printing out
the bot's C<events> and then proceeding to do the upload.

=cut

sub upload {
    my $self = shift;
    $self->check_allowed();
    $Mvs->do_update( $self->shows_page() );
    $self->dump_to_file();
    $Mvs->watch(0);
    $Mvs->minor_edit(0);
    $Mvs->commit_message( "scraping results" );
    $Mvs->do_commit( $self->shows_page() );
}

1;

__END__

=head1 BUGS

Please submit bug reports to the CPAN bug tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=www-wikevent-bot>.

=head1 DISCUSSION

Discussion should take place on the Wiki, probably on the page 
L<http://wikevent.org/en/Wikevent:Perl library>

=head1 AUTHORS

=over

=item Mark Jaroski <mark@geekhive.net> 

Original author, maintainer

=back

=head1 LICENSE

Copyright (c) 2004-2005 Mark Jaroski. 

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

whatever that is.  You can of course override this behaviour by specifying
a new URL to parse in the parser subroutine, but then you'll have to do all
of the date calculation yourself.

=cut

sub url {
    my ( $self, $url ) = @_;
    $self->{'url'} = $url if $url;
    return $self->{'url'};
}

=head2 months

  $bot->months( $int );
  my $int = $bot->months();

The number of months to scrape if C<url> is a Date::Format specification.

Defaults to 3.

=cut

sub months {
    my ( $self, $months ) = @_;
    $self->{'months'} = $months if $months;
    return $self->{'months'};
}

sub parser {
    my ( $self, $parser ) = @_;
    $self->{'parser'} = $parser if $parser;
    return $self->{'parser'};
}

=head2 user_dir

  my $dir = $bot->user_dir( $dir );

The directory to which your events will be dumped.

Normally this is set as a side-effect of setting the C<name> accessor,
however it can be optionally set to something else I<after> setting
C<name>.

=cut

sub user_dir {
    my ( $self, $user_dir ) = @_;
    $self->{'user_dir'} = $user_dir if $user_dir;
    return $self->{'user_dir'};
}

=head2 user_page

  my $page = $bot->user_page( $page );

The page on which information about your bot is to be found.

Normally this is set as a side-effect of setting the C<name> accessor,
however it can be optionally set to something else I<after> setting
C<name>.

=cut

sub user_page {
    my ( $self, $user_page ) = @_;
    $self->{'user_page'} = $user_page if $user_page;
    return $self->{'user_page'};
}

=head2 shows_page

  my $page = $bot->shows_page( $page );

The page to which events scraped by your bot will be uploaded.

Normally this is set as a side-effect of setting the C<name> accessor,
however it can be optionally set to something else I<after> setting
C<name>.

=cut

sub shows_page {
    my ( $self, $shows_page ) = @_;
    $self->{'shows_page'} = $shows_page if $shows_page;
    return $self->{'shows_page'};
}

=head1 METHODS

=cut

=head2 add_event

  my $e = $bot->add_event();

Create a new event and return it.

This is a convenience method which both creates a new event, adds it to
C<events> list (see above) and returns a refernce to which you may
manipulate as necessary.

=cut

sub add_event {
    my $self = shift;
    my $event = WWW::Wikevent::Event->new();
    push @{$self->{'events'}}, $event;
    return $event;
}

=head2 parse

  my @events = $bot->parse( $html );

or 

  my $events_ref = $bot->parse( $html );

Run the user supplised C<parser> subroutine against the argument HTML and
return any events found.  This is used internally by C<scrape>.

=cut

sub parse {
    my ( $self, $html ) = @_;
    $self->parser->( $self, $html );
    return wantarray ? @{$self->events()} : $self->events();
}

=head2 check_allowed

   $bot->check_allowed();

Check the user page of this bot to see if it is currently allowed to run.
This will be indicated by the text:

  run = true

at the top of the page.  If that text is present return true, other wise
die with an error.  This method is called internally by C<upload> so you
don't have to call it, but you do have to make sure that the above text
appears on the bot's user page.

=cut

sub check_allowed {
    my $self = shift();
    $Mvs->do_login();
    # check to see if run = true
    $Mvs->do_update( $self->{'user_page'} );
    open UP, $self->{'user_page'};
    my $go = undef;
    while ( <UP> ) {
        next if m{^\s*$};
        last if m{^\s*==[^=]*==\s*$};
        if ( m{^\s*run\s*=\s*(\w+)\s*$} ) {
            $go = $1;
        }
    }
    die "Not allowed to run, according to user page."
        unless $go;
    close UP;
}

sub create_account {
}

=head2 scrape_sample

  $bot->scrape_sample();

Runs the C<parser> against the supplied C<sample> HTML page.

=cut

sub scrape_sample {
    my $self = shift;
    my $file = $self->sample();
    my $in;
    if ( $self->charset() ) {
        my $c = $self->charset();
        open( $in, "<:encoding($c)", $file )
                or die "Could not open sample file '$file'. $!\n";
    } else {
        open( $in, "<", $file )
                or die "Could not open sample file '$file'. $!\n";
    }
    local $/ = undef;
    my $html = <$in>;
    close $in;
    $self->events( $self->parse( $html ) );
}

sub find_month_urls {
    my $self = shift;
    my @calendar_urls;
#   from perlfunc:
#   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
#   thus:  0    1     2     3    4     5     6     7      8
    my @lt = localtime(time);
    for ( my $i = 0; $i < $self->months(); $i++ ) {
        my $url = strftime( $self->url(), @lt );
        $lt[4]++;
        if ( $lt[4] > 11 ) {
            $lt[4] = 0;
            $lt[5]++;
        }
        push @calendar_urls, $url;
    }
    return wantarray ? @calendar_urls : \@calendar_urls;
}

=head2 scrape

  $bot->scrape();

Starts scraping at the supplied C<url> and continues as long as C<url>
changes.
    
=cut

sub scrape {
    my $self = shift;
    if ( $self->url() =~ m{%[A-z]} ) {
        foreach my $url ( $self->find_month_urls() ) {
            $self->scrape_page( $url );
        }
    } else {
        while ( $self->url() and ( $self->url() ne $self->{last_url} ) ) {
            $self->{last_url} = $self->url();
            $self->scrape_page( $self->url() );
        }
    }
}

=head2 scrape_page

  $bot->scrape_page( $url );

Scrapes a single page of HTML found at the given URL.  This method is
called internally by C<scrape>.

=cut

sub scrape_page {
    my ( $self, $url ) = @_;
    my $html;
    print "fetching $url\n"; #FIXME
    my $res = $Ua->get( $url );
    die "couldn't fetch $url." unless $res->is_success();
    if ( $self->charset() ) {
        $html = $res->decoded_content( charset => $self->charset() );
    } else {
        $html = $res->decoded_content();
    }
    $self->parse( $html );
}

=head2 dump

  $bot->dump();

Dumps the contents of C<events> as text to standard out.

=cut

sub dump {
    my $self = shift;
    foreach my $e ( $self->events() ) {
        print $e;
    }
    return;
}

=head2 remember
  
  $bot->remember( $event );

Records an md5sum of the given event, so as to not repeat it again when
running C<dump_to_file>.

=cut

sub remember {
    my ( $self, $event ) = @_;
    my $token = md5_hex( encode( "iso-8859-1", $event->to_string() ) );
    $self->{known_events}->{$token} = 1;
    open OUT, ">>$SEEN_FILE";
    print OUT "$token\n";
    close OUT;
}

=head2 load_remembered_events

  $bot->load_remembered_events

Loads in the md5sums of previously C<remember>ed events.  This is called
internally by C<new> so it's unlikely that you will need to call it.

=cut

sub load_remembered_events {
    my ( $self, $event ) = @_;
    unless ( open SEEN, $SEEN_FILE ) { 
        open SEEN, ">$SEEN_FILE";
        print SEEN "\n";
        close SEEN;
        open SEEN, $SEEN_FILE;
    }
    while ( my $token = <SEEN> ) {
        chomp( $token );
        $self->{known_events}->{$token} = 1;
    }
    close SEEN;
}

=head2 is_new

  my $bool = $bot->is_new( $event );

Checks to see if the md5sum of an event is in our list of C<remember>ed
events.

=cut

sub is_new {
    my ( $self, $event ) = @_;
    my $token = md5_hex( encode( "iso-8859-1", $event->to_string() ) );
    if ( $self->{known_events}->{$token} ) {
        return 0;
    } else {
        return 1;
    }
}

=head2 dump_to_file
  
  $bot->dump_to_file

Prints out the events in their final form to the appropriate .wiki file for
upload to the bot's event page.  This is called internally by C<upload> but
is also useful for the last stages of writing and debugging your bot.

=cut

sub dump_to_file {
    my $self = shift;
    if ( ! -e $self->user_dir() ) {
        mkdir $self->user_dir()
                or die "could not make directory: " . $self->user_dir() .  "\n";
    }
    open my $out, ">:encoding(utf-8)",  $self->shows_page()
            or die "could not open wiki file: " . $self->shows_page() . "\n";
    foreach my $e ( $self->events() ) {
        if ( $self->is_new( $e ) ) {
            print $out $e;
            $self->remember( $e );
        }
    }
    close $out;
    return;
}

=head2 upload

  $bot->upload();

This is the method which interacts with the Wikevent server, first checking
to see if the bot is allowed to proceed, then doing an update, printing out
the bot's C<events> and then proceeding to do the upload.

=cut

sub upload {
    my $self = shift;
    $self->check_allowed();
    $Mvs->do_update( $self->shows_page() );
    $self->dump_to_file();
    $Mvs->watch(0);
    $Mvs->minor_edit(0);
    $Mvs->commit_message( "scraping results" );
    $Mvs->do_commit( $self->shows_page() );
}

1;

__END__

=head1 BUGS

Please submit bug reports to the CPAN bug tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=www-wikevent-bot>.

=head1 DISCUSSION

Discussion should take place on the Wiki, probably on the page 
L<http://wikevent.org/en/Wikevent:Perl library>

=head1 AUTHORS

=over

=item Mark Jaroski <mark@geekhive.net> 

Original author, maintainer

=back

=head1 LICENSE

Copyright (c) 2004-2005 Mark Jaroski. 

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

