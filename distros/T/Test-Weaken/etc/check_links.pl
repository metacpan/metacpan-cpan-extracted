#!perl

use strict;
use warnings;

use LWP::UserAgent;
use URI::URL;
use HTML::LinkExtor;
use English qw( -no_match_vars );
use Carp;
use IO::Handle;
use Fatal qw(open close);

my $fh;
open $fh, q{<}, 'lib/Test/Weaken.pm';
LINE: while ( my $line = <$fh> ) {
    if ($line =~ m{
            ([\$*])
            (
                ([\w\:\']*)
                \b
                VERSION
            ) \b .* \=
            }xms
        )
    {
        {

            package Test::Weaken;
            ## no critic (BuiltinFunctions::ProhibitStringyEval)
            my $retval = eval $line;
            ## use critic
            if ( not defined $retval ) {
                Carp::croak("eval of $line failed");
            }
            last LINE;
        }
    } ## end if ( $line =~ /             /xms )
} ## end while ( my $line = <$fh> )
close $fh;

my $cpan_base = 'http://search.cpan.org';
my $doc_base =
      $cpan_base
    . '/~jkegl/Test-Weaken-'
    . $Test::Weaken::VERSION
    . '/lib/Test/';

print "Starting at $doc_base\n"
    or Carp::croak("Cannot print: $ERRNO");

my @url = qw(
    Weaken.pm
);

my %link;

sub cb {
    my ( $tag, %links ) = @_;
    return unless $tag eq 'a';
    my $href = $links{href};
    return if $href =~ /^[#]/xms;
    return ( $link{$href} = 1 );
}

my %link_ok;

$OUTPUT_AUTOFLUSH = 1;

PAGE: for my $url (@url) {
    $url = $doc_base . $url;

    my $p  = HTML::LinkExtor->new( \&cb );
    my $ua = LWP::UserAgent->new;

    %link = ();

    # Request document and parse it as it arrives
    my $request_response = $ua->request( HTTP::Request->new( GET => $url ),
        sub { $p->parse( $_[0] ) } );

    my $page_response_status_line = $request_response->status_line;
    if ( $request_response->code != 200 ) {
        print 'PAGE: ', $page_response_status_line, q{ }, $url, "\n"
            or Carp::croak("Cannot print: $ERRNO");
        next PAGE;
    }

    LINK: for my $link ( keys %link ) {

        $link = 'http://search.cpan.org' . $link
            if $link =~ m{^/}xms;

        next LINK if $link_ok{$link};

        my $response = $ua->request( HTTP::Request->new( GET => $link ) );

        if ( $response->code == 200 ) {
            $link_ok{$link} = 1;
            print q{.}
                or Carp::croak("Cannot print: $ERRNO");
            next LINK;
        }

        print 'LINK: ', $response->status_line, q{ }, $link, "\n"
            or Carp::croak("Cannot print: $ERRNO");

    }

    print " PAGE: $page_response_status_line: $url\n"
        or Carp::croak("Cannot print: $ERRNO");

}
