package WWW::SimpleRobot;

#==============================================================================
#
# Standard pragmas
#
#==============================================================================

require 5.005_62;
use strict;
use warnings;

#==============================================================================
#
# Required modules
#
#==============================================================================

use URI;
use LWP::Simple;
use HTML::LinkExtor;

#==============================================================================
#
# Private globals
#
#==============================================================================

our $VERSION = '0.07';
our %OPTIONS = (
    URLS                => [],
    FOLLOW_REGEX        => '',
    VISIT_CALLBACK      => sub {},
    BROKEN_LINK_CALLBACK=> sub {},
    VERBOSE             => 0,
    DEPTH               => undef,
    TRAVERSAL           => 'depth',
);

#==============================================================================
#
# Private methods
#
#==============================================================================

sub _verbose
{
    my $self = shift;

    return unless $self->{VERBOSE};
    print STDERR @_;
}

#==============================================================================
#
# Constructor
#
#==============================================================================

sub new
{
    my $class = shift;
    my %args = ( %OPTIONS, @_ );

    for ( keys %args )
    {
        die "Unknown option $_\n" unless exists $OPTIONS{$_};
    }
    unless ( $args{TRAVERSAL} =~ /^(depth|breadth)$/ )
    {
        die "option TRAVERSAL should be either 'depth' or 'breadth'\n";
    }

    my $self = bless \%args, $class;

    return $self;

}

#==============================================================================
#
# Public methods
#
#==============================================================================

sub traverse
{
    my $self = shift;

    die "No URLS specified in constructor\n" unless @{$self->{URLS}};
    $self->_verbose( 
        "Creating list of files to index from @{$self->{URLS}}...\n"
    );
    my @pages;
    my %seen;
    for my $url ( @{$self->{URLS}} )
    {
        my $uri = URI->new( $url );
        die "$uri is not a valid URL\n" unless $uri;
        die "$uri is not a valid URL\n" unless $uri->scheme;
        die "$uri is not a web page\n" unless $uri->scheme eq 'http';
        die "can't HEAD $uri\n" unless
            my ( $content_type, $document_length, $modified_time ) =
                head( $uri )
        ;
        $uri = $uri->canonical->as_string;
        $seen{$uri}++;
        my $page = { 
            modified_time => $modified_time,
            url => $uri,
            depth => 0,
            linked_from => $url,
        };
        push( @pages, $page );
    }
    while ( my $page = shift( @pages ) )
    {
        my $url = $page->{url};
        $self->_verbose( "GET $url\n" );
        my $html = get( $url );
        unless( $html )
        {
            $self->{BROKEN_LINK_CALLBACK}( $url, $page->{linked_from}, $page->{depth} );
        }
        $self->_verbose( "Extract links from $url\n" );
        my $linkxtor = HTML::LinkExtor->new( undef, $url );
        $linkxtor->parse( $html );
        my @links = $linkxtor->links;
        $self->{VISIT_CALLBACK}( $url, $page->{depth}, $html, \@links );
        next if defined( $self->{DEPTH} ) and $page->{depth} == $self->{DEPTH};
        for my $link ( @links )
        {
            my ( $tag, %attr ) = @$link;
            next unless $tag eq 'a';
            next unless my $href = $attr{href};
            $href =~ s/[#?].*$//;
            next unless $href = URI->new( $href );
            $href = $href->canonical->as_string;
            next unless $href =~ /$self->{FOLLOW_REGEX}/;
            my ( $content_type, undef, $modified_time ) = head( $href );
            next unless $content_type;
            next unless $content_type eq 'text/html';
            next if $seen{$href}++;
            my $npages = @pages;
            my $nseen = keys %seen;
            my $page = { 
                modified_time => $modified_time, 
                url => $href,
                depth => $page->{depth}+1,
            };
            splice( 
                @pages, 
                $self->{TRAVERSAL} eq 'depth' ? 0 : @pages, 
                # depth first ... unshift, breadth first ... push
                0, 
                $page 
            );
            $self->_verbose( 
                "$nseen/$npages : $url : $href",
                " : ", join( ' ', map { $_->{url} } @pages ),
                "\n" 
            );
        }
    }
    $self->{pages} = \@pages;
    $self->{urls} = [ map { $_->{url} } @pages ];
}

#==============================================================================
#
# AUTOLOADed accessor methods
#
#==============================================================================

sub AUTOLOAD
{
    my $self = shift;
    my $value = shift;
    use vars qw( $AUTOLOAD );
    my $method_name = $AUTOLOAD;
    $method_name =~ s/.*:://;
    $self->{$method_name} = $value if defined $value;
    return $self->{$method_name};
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

WWW::SimpleRobot - a simple web robot for recursively following links on web
pages.

=head1 SYNOPSIS

    use WWW::SimpleRobot;
    my $robot = WWW::SimpleRobot->new(
        URLS            => [ 'http://www.perl.org/' ],
        FOLLOW_REGEX    => "^http://www.perl.org/",
        DEPTH           => 1,
        TRAVERSAL       => 'depth',
        VISIT_CALLBACK  => 
            sub { 
                my ( $url, $depth, $html, $links ) = @_;
                print STDERR "Visiting $url\n"; 
                print STDERR "Depth = $depth\n"; 
                print STDERR "HTML = $html\n"; 
                print STDERR "Links = @$links\n"; 
            }
        ,
        BROKEN_LINK_CALLBACK  => 
            sub { 
                my ( $url, $linked_from, $depth ) = @_;
                print STDERR "$url looks like a broken link on $linked_from\n"; 
                print STDERR "Depth = $depth\n"; 
            }
    );
    $robot->traverse;
    my @urls = @{$robot->urls};
    my @pages = @{$robot->pages};
    for my $page ( @pages )
    {
        my $url = $page->{url};
        my $depth = $page->{depth};
        my $modification_time = $page->{modification_time};
    }

=head1 DESCRIPTION

    A simple perl module for doing robot stuff. For a more elaborate interface,
    see WWW::Robot. This version uses LWP::Simple to grab pages, and
    HTML::LinkExtor to extract the links from them. Only href attributes of
    anchor tags are extracted. Extracted links are checked against the
    FOLLOW_REGEX regex to see if they should be followed. A HEAD request is
    made to these links, to check that they are 'text/html' type pages. 

=head1 BUGS

    This robot doesn't respect the Robot Exclusion Protocol
    (http://info.webcrawler.com/mak/projects/robots/norobots.html) (naughty
    robot!), and doesn't do any exception handling if it can't get pages - it
    just ignores them and goes on to the next page!

=head1 AUTHOR

Ave Wrigley <Ave.Wrigley@itn.co.uk>

=head1 COPYRIGHT

Copyright (c) 2001 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut
