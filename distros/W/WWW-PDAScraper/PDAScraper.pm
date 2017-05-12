package WWW::PDAScraper;
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use Exporter;
    use vars qw($VERSION @ISA @EXPORT);
    $VERSION = 0.1;
    @ISA     = qw( Exporter );
    @EXPORT  = qw( &scrape  );
    use URI::URL;
    use HTML::TreeBuilder;
    use HTML::Template;
    use Carp;
    use LWP::UserAgent;
}

my $ua = LWP::UserAgent->new();

my $download_location = "$ENV{'HOME'}/scrape";

sub proxy {
    if ( ref( $_[0] ) eq 'WWW::PDAScraper' ) {
        my ( $self, $proxy ) = @_;
        $ua->proxy( ['http'], $proxy );
    } else {
        my $proxy = shift();
        $ua->proxy( ['http'], $proxy );
    }
}

sub download_location {
    if ( ref( $_[0] ) eq 'WWW::PDAScraper' ) {
        my ( $self, $location ) = @_;
        $download_location = $location;
    } else {
        my $location = shift();
        $download_location = $location;
    }
}

sub new {
    my $pkg = shift;
    my @submodules = map { "WWW::PDAScraper::$_" } @_;
    for ( @submodules ) {
        eval "require $_" || croak( "$@" );
    }
    bless { submodules => \@submodules }, $pkg;
}

sub scrape {
    my $self = {};
    if ( ref( $_[0] ) eq 'WWW::PDAScraper' ) {
        $self = shift;
    } else {
        my @submodules = map { "WWW::PDAScraper::$_" } @_;
        for ( @submodules ) {
            eval "require $_" || croak( "$_ - $@" );
        }
        $self->{'submodules'} = \@submodules;
    }
    for ( @{ $self->{'submodules'} } ) {
        my $obj         = $_->config();
        my $template    = undef;
        my @all_links   = ();
        my @good_links  = ();
        my $tree        = undef;
        my $chunk       = undef;
        my $file_number = 0;
        my $response    = $ua->get( $obj->{'start_from'} );
        ### get the front page which has the links
        unless ( $response->is_success() ) {
            carp(
                "$obj->{name} error: failed to get starter page: $obj->{'start_from'}"
            );
            next;
        }
        my $page = $response->content();

        if ( $obj->{'chunk_spec'} ) {
            ###   if we're parsing the HTML the Good Way using TreeBuilder
            unless ( $chunk =
                HTML::TreeBuilder->new_from_content( $page ) )
            {
                carp( "$obj->{name} - $@" );
                next;
            }

            unless ( $chunk->elementify() ) {
                carp( "$obj->{name} - $@" );
                next;
            }

            $chunk =
              $chunk->look_down( @{ $obj->{'chunk_spec'} } );
              
            unless ( defined($chunk) ) {
                carp( "$obj->{name} error: \n" 
                . "nothing on the page matches the 'chunk_spec'\n"
                . "which tells $_ where to find the links.\n");
                next;
            }


        } elsif ( $obj->{'chunk_regex'} )
        {    # not the case with the new scientist
            ###   if we're parsing the HTML the Bad Way using a regex

            $page =~ $obj->{'chunk_regex'};
            unless ( defined $1 ) {
                carp(
                    "$obj->{name} Regex failed to match on $obj->{'start_from'}"
                );
                return;
            }
            $chunk = HTML::TreeBuilder->new_from_content( $1 );
            $chunk->elementify();

        } else {
            ###   if we're just grabbing the whole page, probably not a good
            ###   idea, but see link_spec below for a way of filtering links
            $chunk =
              HTML::TreeBuilder->new_from_content( $page );
            unless ( $chunk->elementify() ) {
                carp( "$obj->{name} - $@" );
                next;
            }
        }

        if ( defined( $obj->{'link_spec'} ) ) {
            ###   If we've got a TreeBuilder link filter to grab only
            ###   the links which match a certain format
            @all_links =
              $chunk->look_down( '_tag', 'a',
                @{ $obj->{'link_spec'} } );
        } else {

            @all_links = $chunk->look_down( '_tag', 'a' );
        }
        for ( @all_links ) {
            ###   Avoid three problem conditions -- no text means
            ###   we've probably got image links (often duplicates)
            ###   -- "#" as the href means a JavaScript link --
            ###   a tags with no HREF are also no use to us:
            next
              unless ( defined( $_->attr( 'href' ) )
                && $_->as_text()      ne ''
                && $_->attr( 'href' ) ne '#' );
            my $href = $_->attr( 'href' );
            ###   It's expected that we'll need to transform
            ###   the URL from regular to print-friendly:
            my $regex_success = 0;
            if ( defined( $obj->{'url_regex'} )
                && ref( $obj->{'url_regex'}->[1] ) eq 'CODE' )
            {
                ###   PerlMonk Roy Johnson is my saviour here.
                ###   Solution to the problem of some url regexes
                ###   needing backreferences and some not.
                if (
                    $href =~ s{$obj->{'url_regex'}->[0]}
                  {${$obj->{'url_regex'}->[1]->()}}e
                  )
                {
                    $regex_success = 1;
                }
            } elsif ( defined( $obj->{'url_regex'} ) ) {
                ###   If there is a regex object at all:
                if (
                    $href =~ s{$obj->{'url_regex'}->[0]}
                  {$obj->{'url_regex'}->[1]}
                  )
                {
                    $regex_success = 1;
                }
            }
            if ( $regex_success == 0 && $obj->{'url_regex'} ) {
                carp(
                    "$obj->{name} - URL RegEx failed to transform URL: $href"
                );
            }
            ###   Transform the URL from relative to absolute:
            my $url =
              URI::URL->new( $href, $obj->{'start_from'} );
            my $abs_url = $url->abs();
            ###   Make a data structure with all the stuff we're
            ###   going to get on the next pass:
            push(
                @good_links,
                {
                    text => $_->as_text(),
                    url  => "$abs_url"
                }
            );
        }
        if ( scalar( @good_links ) == 0 ) {
            carp( "$obj->{name} No 'good' links found." );
            return;
        }
        ( my $foldername = $obj->{'name'} ) =~ s/\W//g;
        ###   Make a foldername with no non-word chars

        unless ( -e $download_location ) {
            ###   Make a scrape folder if there isn't one
            mkdir $download_location
              || croak( " __LINE__ making scrape folder $@" );
        }
        unless ( -e "$download_location/$foldername" ) {
            ###   Make a folder for this content if there isn't one
            mkdir "$download_location/$foldername"
              || croak(
                "  __LINE__ making $foldername folder $@" );
        }
        foreach ( @good_links ) {
            my $response = $ua->get( $_->{'url'} );
            unless ( $response->is_success() ) {
                warn "didn't get " . $_->{'url'} . "$!" . $/;
                $_ = undef;
                next;
            }
            my $page = $response->content();
            ###   TO DO: arbitrary number of further regexes
            ###   in case users want to clean content up more?
            ###   Filenames sprintf'd for neatness only:
            my $local_file =
              sprintf( "%03d.html", $file_number );
            ###   add a localfile value to the AoH for use in the index:
            $_->{localfile} = $local_file;
            ###   Print out the actual content page locally:
            open( PAGE,
                ">$download_location/$foldername/$local_file" )
              || croak(
                " __LINE__ $download_location/$foldername/$local_file $@"
              );
            print PAGE $page;
            close( PAGE );
            $file_number++;
        }

        @good_links = grep { defined( $_ ) } @good_links;

  # in case we had to undef a bad link in foreach ( @good_links )

        ###   [die_on_bad_params is off because the AoH contains
        ###   one item we don't need, the original URL]
        my $template_code = '<html>
<head>
<tmpl_if name="encoding">
<meta http-equiv="content-type" content="text/html; charset=<tmpl_var name=encoding>">
<tmpl_else>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
</tmpl_if>
<title><tmpl_var name="sitename"></title>
</head>
<body>
  <h1><tmpl_var name="sitename"></h1>
  <ul><tmpl_loop name="links">
    <li>
  <a href="<tmpl_var name="localfile">"><tmpl_var name="text"></a>
    </li>
  </tmpl_loop></ul>
</body>
</html>';
        $template = HTML::Template->new(
            scalarref         => \$template_code,
            debug             => 0,
            die_on_bad_params => 0
        );
        ###   Use the name and the links array to fill out the template:
        if ( exists( $obj->{'encoding'} ) ) {
            $template->param( encoding => $obj->{'encoding'} );
        }

        $template->param(
            links    => \@good_links,
            sitename => $obj->{'name'}
        );
        ###   Output the index page locally:
        open( INDEX,
            ">$download_location/$foldername/index.html" )
          || croak( "$@" );
        unless ( print INDEX $template->output() ) {
            carp( "Error in HTML::Template output" );
            return;
        }
        close( INDEX );
        ###   Clean up after HTML::Tree as recommended
        $chunk->delete();
    }
}
1;

=head1 Name

WWW::PDAScraper - Class for scraping PDA-friendly content from websites

=head1 Synopsis

  use WWW::PDAScraper;
  my $scraper = WWW::PDAScraper->new qw ( NewScientist Yahoo::Entertainment );
  $scraper->scrape();
  
or
  
  use WWW::PDAScraper;
  my $scraper = WWW::PDAScraper->new;
  $scraper->scrape qw( NewScientist Yahoo::Entertainment );

or
  
  perl -MWWW::PDAScraper -e "scrape qw( NewScientist Yahoo::Entertainment )"


=head1 Description

Having written various kludgey scripts to download
PDA-friendly content from various websites, I
decided to try and write a generalised solution
which would

* parse out the section of a news page which contains
  the links we want
   
* munge those links into the URL for the print-friendly
  version, if possible

* download those pages and make an index page for them

The moving of the pages to your PDA is not part of the 
scope of the module: the open-source browser and
"distiller", Plucker, from B<http://plkr.org/> 
is recommended. Just get it to read the index.html
file with a depth of 1 from disk, using a URL like
file:///path/to/index.html

=head1 The Sub-modules

WWW::PDAScraper uses a set of rules for scraping a 
particular website from a second module, i.e.
C<WWW::PDAScraper::Yahoo::Entertainment::TV> contains the rules for 
scraping the Yahoo TV News website:

    package WWW::PDAScraper::Yahoo::Entertainment::TV;
    # WWW::PDAScraper.pm rules for scraping the
    # Yahoo TV website
    sub config {
        return {
            name       => 'Yahoo TV',
            start_from => 'http://news.yahoo.com/i/763',
            chunk_spec => [ "_tag", "div", "id", "indexstories" ],
            url_regex => [ '$', '&printer=1' ]
        };
    }
    1;

A more or less random selection of modules is included, as well as a
full set for Yahoo, to demonstrate a logical set of modules in categories.

Creating a new sub-module ought to be relatively simple, see the
template provided, WWW::PDAScraper::Template.pm - you need C<name>, 
C<start_from>, then either C<chunk_spec> or C<url_spec>, then 
optionally a C<url_regex> for transformation into the print-friendly URL.

Then either move your new module to the same location as the other ones 
on your system, or make sure they're available to your script with a line
like C<use lib '/path/to/local/modules/PDAScraper/'>

=head1 USAGE

WWW::PDAScraper ought to be very simple to run, assuming you have
the right sub-module(s).

It only has two main methods, new() and scrape(), and two supplementary
ones, for assigning a proxy server to the user-agent and one for
over-riding the default download location.

Either object-oriented, loading the sub-module(s) as part of "new":

  use WWW::PDAScraper;
  my $scraper = WWW::PDAScraper->new qw ( NewScientist Yahoo::Entertainment );
  $scraper->scrape();

or object-oriented, loading the sub-module(s) as part of each
call to scrape():

  use WWW::PDAScraper;
  my $scraper = WWW::PDAScraper->new;
  $scraper->scrape qw( NewScientist Yahoo::Entertainment );
  $scraper->scrape qw( SomethingElse );

or procedural:

  use WWW::PDAScraper;
  scrape qw( NewScientist Yahoo::Entertainment );

or from the command line:

  perl -MWWW::PDAScraper -e "scrape qw( NewScientist Yahoo::Entertainment )"
  
The only extras involved would be adding a proxy to the user-agent
and/or over-riding the default download location of $ENV{'HOME'}/scrape/

Object-oriented:
 
  use WWW::PDAScraper;
  my $scraper = WWW::PDAScraper->new;
  $scraper->proxy('http://your.proxy.server:port/');
  $scraper->download_location("/path/to/folder/");

procedural:

  use WWW::PDAScraper;
  proxy('http://your.proxy.server:port/');
  download_location("/path/to/folder/");

=head1 I wish I didn't need this code

In the days of modern web publishing, I shouldn't
need to create this code. All websites should make
themselves PDA-friendly by the use of client detection
or smart CSS or XML. But they don't.

=head1 Bugs

The websites will certainly change, and at that time
the sub-modules will stop working. There's no way around that.

Obviously it would be useful if there were a developer/user 
community which contributed new modules and updated the old ones.

=head1 See Also

HTML::Element, for the syntax of C<chunk_spec> in sub-modules.

=head1 To do

The user-agent should really be part of the object, I guess. 
That would be neater.

And it should actually use WWW::Robot instead of LWP so it 
doesn't hammer servers.

And we could either add arbitrary numbers of
regexes for fixing up the pages of sites which
don't have a print-friendly version of the page,
or add a second level of parsing to find the
print-friendly link, for sites which don't have a
logical relationship between the regular link and
the print-friendly.

=head1 Author

	John Horner
	CPAN ID: CODYP
	
	bounce@johnhorner.nu
	http://pdascraper.johnhorner.nu/

=head1 Copyright

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.


=cut

############################################# main pod documentation end ##

