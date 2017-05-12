package WWW::Sitemap;

#==============================================================================
#
# Start of POD
#
#==============================================================================

=head1 NAME

WWW::Sitemap - functions for generating a site map for a given site URL.

=head1 SYNOPSIS

    use WWW::Sitemap;
    use LWP::UserAgent;

    my $ua = new LWP::UserAgent;
    my $sitemap = new WWW::Sitemap(
        EMAIL       => 'your@email.address',
        USERAGENT   => $ua,
        ROOT        => 'http://www.my.com/'
    );

    $sitemap->url_callback(
        sub {
            my ( $url, $depth, $title, $summary ) = @_;
            print STDERR "URL: $url\n";
            print STDERR "DEPTH: $depth\n";
            print STDERR "TITLE: $title\n";
            print STDERR "SUMMARY: $summary\n";
            print STDERR "\n";
        }
    );
    $sitemap->generate();
    $sitemap->option( 'VERBOSE' => 1 );
    my $len = $sitemap->option( 'SUMMARY_LENGTH' );

    my $root = $sitemap->root();
    for my $url ( $sitemap->urls() )
    {
        if ( $sitemap->is_internal_url( $url ) )
        {
            # do something ...
        }
        my @links = $sitemap->links( $url );
        my $title = $sitemap->title( $url );
        my $summary = $sitemap->summary( $url );
        my $depth = $sitemap->depth( $url );
    }
    $sitemap->traverse(
        sub {
            my ( $sitemap, $url, $depth, $flag ) = @_;
            if ( $flag == 0 )
            {
                # do something at the start of a list of sub-pages ...
            }
            elsif( $flag == 1 )
            {
                # do something for each page ...
            }
            elsif( $flag == 2 )
            {
                # do something at the end of a list of sub-pages ...
            }
        }
    )


=head1 DESCRIPTION

The C<WWW::Sitemap> module creates a sitemap for a site, by traversing the
site using the WWW::Robot module. The sitemap object has methods to access a
list of all the urls in the site, and a list of all the links for each of these
urls. It is also possible to access the title of each url, and a summary
generated from each url. The depth of each url can also be accessed; the depth
is the minimum number of links from the root URL to that page.

=head1 CONSTRUCTOR

=head2 WWW::Sitemap->new [ $option => $value ] ...

Possible option are:

=over 4

=item USERAGENT

User agent used to do the robot traversal. Defaults to LWP::UserAgent.

=item VERBOSE

Verbose flag, for printing out useful messages during traversal [0|1]. Defaults
to 0.

=item SUMMARY_LENGTH

Maximum length of (automatically generated) summary.

=item EMAIL

E-Mail address robot uses to identify itself with. This option is required.

=item DEPTH

Maximum depth of traversal.

=item ROOT

Root URL of the site for which the sitemap is being created. This option is
required.

    my $sitemap = new WWW::Sitemap(
        EMAIL       => 'your@email.address',
        USERAGENT   => $ua,
        ROOT        => 'http://www.my.com/'
    );

=head1 METHODS

=head2 generate( )

Method for generating the sitemap, based on the constructor options.

    $sitemap->generate();

=head2 url_callback( sub { ... } )

This method allows you to define a callback that will be invoked on every URL
that is traversed while generating the sitemap. This is basically to allow
bespoke verbose reporting. The callback should be of the form:

    sub {
        my ( $url, $depth, $title, $summary ) = @_;

        # do something ...

    }

=head2 option( $option [ => $value ] )

Iterface to get / set options after object construction.

    $sitemap->option( 'VERBOSE' => 1 );
    my $len = $sitemap->option( 'SUMMARY_LENGTH' );

=head2 root()

returns the root URL for the site.

    my $root = $sitemap->root();

=head2 urls()

Returns a list of all the URLs on the sitemap.

    for my $url ( $sitemap->urls() )
    {
        # do something ...
    }

=head2 is_internal_url( $url )

Returns 1 if $url is an internal URL (i.e. if C<$url =~ /^$root/>.

    if ( $sitemap->is_internal_url( $url ) )
    {
        # do something ...
    }

=head2 links( $url )

Returns a list of all the links from a given URL in the site map.

    my @links = $sitemap->links( $url );

=head2 title( $url )

Returns the title of the URL.

    my $title = $sitemap->title( $url );

=head2 summary( $url )

Returns a summary of the URL - either from the C<<META NAME=DESCRIPTION>> tag
or generated automatically using HTML::Summary.

    my $summary = $sitemap->summary( $url );
    
=head2 depth( $url )

Returns the minimum number of links to traverse from the root URL of the site
to this URL.

    my $depth = $sitemap->depth( $url );

=head2 traverse( \&callback )

The travese method traverses the sitemap, starting at the root node, and
visiting each URL in the order that they would be displayed in a sequential
sitemap of the site. The callback is called in a number of places in the
traversal, indicated by the $flag argument to the callback:

=over 4

=item  $flag = 0

Before each set of daughter URLs of a given URL.

=item  $flag = 1

For each URL.

=item  $flag = 2

After each set of daughter URLs of a given URL.

=back

See the sitemapper.pl script distributed with this module for an example of the
use of the traverse method.

    $sitemap->traverse(
        sub {
            my ( $sitemap, $url, $depth, $flag ) = @_;
            if ( $flag == 0 )
            {
                # do something at the start of a list of sub-pages ...
            }
            elsif( $flag == 1 )
            {
                # do something for each page ...
            }
            elsif( $flag == 2 )
            {
                # do something at the end of a list of sub-pages ...
            }
        }
    );

=head1 SEE ALSO

    LWP::UserAgent
    HTML::Summary
    WWW::Robot

=head1 AUTHOR

Ave Wrigley E<lt>Ave.Wrigley@itn.co.ukE<gt>

=head1 COPYRIGHT

Copyright (c) 1997 Canon Research Centre Europe (CRE). All rights reserved.
This script and any associated documentation or files cannot be distributed
outside of CRE without express prior permission from CRE.

=cut

#==============================================================================
#
# End of POD
#
#==============================================================================

#==============================================================================
#
# Pragmas
#
#==============================================================================

require 5.003;
use strict;

#==============================================================================
#
# Modules
#
#==============================================================================

use WWW::Robot;
use HTML::Summary;
use HTML::TreeBuilder;
use Digest::MD5 qw( md5_hex );

#==============================================================================
#
# Public globals
#
#==============================================================================

use vars qw( $VERSION );

$VERSION = '0.002';

#==============================================================================
#
# Private globals
#
#==============================================================================

my %OPTIONS = (
    'VERBOSE'           => 0,
    'SUMMARY_LENGTH'    => 200,
    'DEPTH'             => undef,
    'EMAIL'             => undef,
    'USERAGENT'         => new LWP::UserAgent,
    'ROOT'              => undef,
);

my %REQUIRED = (
    'EMAIL'             => 1,
    'ROOT'              => 1,
);

#==============================================================================
#
# Public methods
#
#==============================================================================

#------------------------------------------------------------------------------
#
# new - constructor. Configuration through "hash" type arguments, i.e.
# my $sitemap = new WWW::Sitemap( VAR1 => 'foo', VAR2 => 'bar' );
#
#------------------------------------------------------------------------------

sub new
{
    my $class = shift;
    my $self = bless { }, $class;
    return $self->initialize( $class, @_ );
}

#------------------------------------------------------------------------------
#
# root - returns the root url for the site
#
#------------------------------------------------------------------------------

sub root
{
    my $self = shift;

    return $self->{ 'ROOT' };
}

#------------------------------------------------------------------------------
#
# is_internal_url - returns TRUE if $url is an internal URL, FALSE otherwise
#
#------------------------------------------------------------------------------

sub is_internal_url
{
    my $self = shift;
    my $url  = shift;

    return $url =~ /$self->{ ROOT }/;
}

#------------------------------------------------------------------------------
#
# urls - returns a list of the URLs in the sitemap
#
#------------------------------------------------------------------------------

sub urls
{
    my $self = shift;

    return keys %{ $self->{ 'urls' } };
}

#------------------------------------------------------------------------------
#
# links - returns a list of the links from a given URL in the sitemap
#
#------------------------------------------------------------------------------

sub links
{
    my $self = shift;
    my $url = shift;

    return keys %{ $self->{ 'link' }{ $url } };
}

#------------------------------------------------------------------------------
#
# depth - returns the depth of a given URL
#
#------------------------------------------------------------------------------

sub depth
{
    my $self = shift;
    my $url = shift;

    return $self->{ 'depth' }{ $url };
}

#------------------------------------------------------------------------------
#
# title - returns the title of a given URL
#
#------------------------------------------------------------------------------

sub title
{
    my $self = shift;
    my $url = shift;

    return $self->{ 'title' }{ $url };
}

#------------------------------------------------------------------------------
#
# summary - returns the summary of a given URL
#
#------------------------------------------------------------------------------

sub summary
{
    my $self = shift;
    my $url = shift;

    return $self->{ 'summary' }{ $url };
}

#------------------------------------------------------------------------------
#
# option - get / set configuration option
#
#------------------------------------------------------------------------------

sub option
{
    my $self    = shift;
    my $option  = shift;
    my $val     = shift;

    die "No WWW::Sitemap option name given" unless defined $option;
    die "$option is not an WWW::Sitemap option" unless 
        grep { $_ eq $option } keys %OPTIONS
    ;

    if ( defined $val )
    {
        $self->{ $option } = $val;
    }

    return $self->{ $option } = $val;
}

#------------------------------------------------------------------------------
#
# url_callback - specify a callback for each URL visited in generating the
# sitemap. This is basically to allow some status output for traversing big
# sites
#
#------------------------------------------------------------------------------

sub url_callback
{
    my $self = shift;
    my $callback = shift;

    return unless ref( $callback ) eq 'CODE';
    $self->{ 'url-callback' } = $callback;
}

#------------------------------------------------------------------------------
#
# generate - generate the sitemap
#
#------------------------------------------------------------------------------

sub generate
{
    my $self = shift;

    $self->{ 'ROOT' } = "$self->{ 'ROOT' }/"
        unless $self->{ 'ROOT' } =~ m{/$}
    ;

    # Create HTML::Summary

    $self->{ 'summarizer' } = 
        new HTML::Summary LENGTH => $self->{ 'SUMMARY_LENGTH' }
    ;

    # Create WWW::Robot

    $self->{ 'robot' } = new WWW::Robot(
        'NAME'                  => 'WWW::Sitemap',
        'VERSION'               => $VERSION,
        'EMAIL'                 => $self->{ EMAIL },
        'TRAVERSAL'             => 'breadth',
        'USERAGENT'             => $self->{ USERAGENT },
        'CHECK_MIME_TYPES'      => 0,
        'VERBOSE'               => $self->{ VERBOSE } >= 2 ? 1 : 0,
    );

    $self->{ 'robot' }->addHook( 
        'invoke-on-get-error', 
        sub {
            my( $robot, $hook, $url, $response, $structure ) = @_;
            $self->{ 'urls' }{ $url }++;
            $self->{ 'title' }{ $url } = 'Error ' . $response->code();
            $self->{ 'summary' }{ $url } = $response->message();
        }
    );

    $self->{ 'robot' }->addHook( 
        'invoke-on-contents', 
        sub {
            my( $robot, $hook, $url, $response, $structure ) = @_;
            my $contents = $response->content();
            $contents =~ s{<(script|style).*?>.*?</\1>}{}sgi;
            my $element = new HTML::TreeBuilder;
            $element->parse( $contents );
            my $MD5_digest = md5_hex( $contents );
            if ( exists( $self->{ 'MD5_digest' }{ $MD5_digest } ) )
            {
                $self->{ 'equiv' }{ $url } 
                    = $self->{ 'MD5_digest' }{ $MD5_digest }
                ;
            }
            else
            {
                $self->{ 'MD5_digest' }{ $MD5_digest } = $url;
                $self->{ 'urls' }{ $url }++;
                $self->get_title( $url, $element );
                $self->{ 'summary' }{ $url } = 
                    $self->{ 'summarizer' }->generate( $element ) ||
                    'NO SUMMARY'
                ;
                shrink_whitespace( $self->{ 'summary' }{ $url } );
                $self->{ 'url-callback' }->( 
                    $url,
                    $self->{ 'depth' }{ $url },
                    $self->{ 'title' }{ $url },
                    $self->{ 'summary' }{ $url } 
                ) if defined $self->{ 'url-callback' };
                $self->verbose( "url: ", $url );
                $self->verbose( "depth: ", $self->{ 'depth' }{ $url } );
                $self->verbose( "title: ", $self->{ 'title' }{ $url } );
                $self->verbose( "summary: ", $self->{ 'summary' }{ $url } );
            }
        }
    );

    $self->{ 'robot' }->addHook( 
        'invoke-on-link', 
        sub {
            my( $robot, $hook, $from_url, $to_url ) = @_;
            # don't add links that don't look like HTML links
            return unless $to_url =~ m{(?:/|\.s?html?)$};
            if ( not defined( $self->{ 'depth' }{ $to_url } ) )
            {
                my $from = $self->{ 'depth' }{ $from_url };
                $self->{ 'depth' }{ $to_url } = $from + 1;
            }
            # check the current depth, if the DEPTH option is set
            return if ( 
                defined $self->{ DEPTH } and
                defined $self->{ 'depth' }{ $to_url } and
                $self->{ 'depth' }{ $to_url } >= $self->{ DEPTH }
            );
            $self->{ 'link' }{ $from_url }{ $to_url }++;
            $self->verbose( "link: $from_url -> $to_url" );
        }
    );

    $self->{ 'robot' }->addHook( 
        'add-url-test',
        sub {
            my( $robot, $hook, $url ) = @_;
            # don't follow links that aren't internal to the site
            return 0 unless $self->is_internal_url( $url );
            # don't follow links that don't look like HTML links
            return 0 unless $url =~ m{(?:/|\.s?html?)$};
            # check the current depth, if the DEPTH option is set
            return 0 if (
                defined $self->{ DEPTH } and
                defined $self->{ 'depth' }{ $url } and
                $self->{ 'depth' }{ $url } >= $self->{ DEPTH }
            );
            return 1;
        } 
    );

    $self->{ 'robot' }->addHook( 
        'follow-url-test',
        sub {
            my( $robot, $hook, $url ) = @_;
            # don't follow links that aren't internal to the site
            return 0 unless $self->is_internal_url( $url );
            # don't follow links that don't look like HTML links
            return 0 unless $url =~ m{(?:/|\.s?html?)$};
            # check the current depth, if the DEPTH option is set

            return 0 if ( 
                defined $self->{ DEPTH } and
                $self->{ 'depth' }{ $url } >= $self->{ DEPTH }
            );
            return 1;
        } 
    );

    $self->{ 'robot' }->addUrl( $self->{ 'ROOT' } );
    $self->{ 'depth' }{ $self->{ 'ROOT' } } = 0;
    $self->{ 'robot' }->run();

    # Substitute equivilent links

    for my $from_url ( keys %{ $self->{ 'link' } } )
    {
        for my $to_url ( keys %{ $self->{ 'link' }{ $from_url } } )
        {
            if ( 
                exists( $self->{ 'equiv' }{ $from_url } ) or 
                exists( $self->{ 'equiv' }{ $to_url } ) 
            )
            {
                my $no = delete $self->{ 'link' }{ $from_url }{ $to_url };
                $from_url = $self->{ 'equiv' }{ $from_url } || $from_url;
                $to_url = $self->{ 'equiv' }{ $to_url } || $to_url;
                $self->{ 'link' }{ $from_url }{ $to_url } += $no;
            }
        }
    }
}

#------------------------------------------------------------------------------
#
# traverse - traverse the sitemap
#
#------------------------------------------------------------------------------

sub traverse
{
    my $self            = shift;
    my $callback        = shift;
    my $url             = shift || $self->root();
    my $depth           = shift || 0;

    $self->{ 'visited' } = () if $depth == 0;
    &$callback( $self, $url, $depth, 1 );
    $self->{ 'visited' }{ $url }++;

    # Build up a list of non-external, not already visited, links from this URL

    my @links = ();
    for( $self->links( $url ) )
    {
        # This is not the minimum depth for this URL ... leave it
        # so that it will be visited later

        next unless $self->depth( $_ ) == $depth + 1;
        next unless $self->is_internal_url( $_ );
        next if $self->{ 'visited' }{ $_ };
        push( @links, $_ );
    }

    &$callback( $self, $url, $depth, 0 ) if @links;
    for ( @links )
    {
        $self->traverse( $callback, $_, $depth+1 );
    }
    &$callback( $self, $url, $depth, 2 ) if @links;
}

#==============================================================================
#
# Private methods
#
#==============================================================================

#------------------------------------------------------------------------------
#
# initialize - supports sub-classing
#
#------------------------------------------------------------------------------

sub initialize
{
    my $self = shift;
    my $class = shift;

    return undef unless @_ % 2 == 0;    # check that config hash has even no.
                                        # of elements

    %{ $self } = ( %OPTIONS, @_ );     # set options from defaults / config.
                                        # hash passed as arguments

    for ( keys %{ $self } )
    {
        unless ( exists( $OPTIONS{ $_ } ) )
        {
            print STDERR "$_ is not a valid $class option\n";
            return undef;
        }
    }
    for ( keys %REQUIRED )              # Check that required options are
    {                                   # present
        unless ( defined $self->{ $_ } )
        {
            print STDERR "the $_ option is required\n";
            return undef;
        }
    }
    return $self;
}

#------------------------------------------------------------------------------
#
# get_title - get the title for an HTML string
#
#------------------------------------------------------------------------------

sub get_title
{
    my $self = shift;
    my $url = shift;
    my $structure = shift;

    $structure->traverse( 
        sub {
            my $node        = shift;
            my $start_flag  = shift;                    # NOT USED
            my $depth       = shift;                    # NOT USED

            return 1 if $node->tag ne 'title';
            return 0 if $start_flag == 0;

            if (
                defined( $node->content ) and
                ref( $node->content ) eq 'ARRAY'
            )
            {
                foreach my $bit ( @{ $node->content } )
                {
                    next if not defined $bit || ref( $bit ) ne '';
                    $self->{ 'title' }{ $url } = 
                        ( 
                            defined $self->{ 'title' }{ $url } ? 
                                "$self->{ 'title' }{ $url } $bit" 
                            :
                                $bit 
                        )
                    ;
                }
            }
        },
        1
    );

    if ( defined( $self->{ 'title' }{ $url } ) )
    {
        shrink_whitespace( $self->{ 'title' }{ $url } );
    }
    $self->{ 'title' }{ $url } ||= 'NO TITLE';
}

#------------------------------------------------------------------------------
#
# shrink_whitespace - clean up text - remove leading / trailing whitespace,
# and multiple spaces
#
#------------------------------------------------------------------------------

sub shrink_whitespace
{
    $_[ 0 ] =~ s!\240=! !g;
    $_[ 0 ] =~ s!^\s*!!; 
    $_[ 0 ] =~ s!\s*$!!;
    $_[ 0 ] =~ s!\s+! !g;
    $_[ 0 ] =~ s!\r!!g;
}

#------------------------------------------------------------------------------
#
# verbose - generate verbose error messages, if the VERBOSE option has been
# selected
#
#------------------------------------------------------------------------------

sub verbose
{
    my $self = shift;

    return unless $self->{ VERBOSE };
    print STDERR @_, "\n";
}

1;
