package URI::Match::TestMatch;
sub new { bless {}, shift }
sub match { $_[1] eq 'http' }

package main;
use strict;
use Test::More (tests => 17);

BEGIN
{
    use_ok("URI");
    use_ok("URI::Match");
}

{ # interface
    my $uri = URI->new( "http://search.cpan.org/dist/URI-Match" );
    ok( $uri );
    isa_ok( $uri, "URI" );
    can_ok( $uri, "match_parts" );
}

{ # positive cases 
    my $uri = URI->new( "http://search.cpan.org/dist/URI-Match" );
    ok( $uri->match_parts( scheme => '^http$' ), "match against a simple scalar" );
    ok( $uri->match_parts( scheme => qr{^http$} ), "match against a regular expression" );
    ok( $uri->match_parts( scheme => sub { $_[0] eq 'http' } ), "match against a subroutine" );
    ok( $uri->match_parts( scheme => URI::Match::TestMatch->new() ), "match against an object" );
}

{ # negative cases
    my $uri = URI->new( "file:///Users/daisuke/foobar.txt" );
    ok( ! $uri->match_parts( scheme => '^http$' ), "match fails against a simple scalar" );
    ok( ! $uri->match_parts( scheme => qr{^http$} ), "match fails against a regular expression" );
    ok( ! $uri->match_parts( scheme => sub { $_[0] eq 'http' } ), "match fails against a subroutine" );
    ok( ! $uri->match_parts( scheme => URI::Match::TestMatch->new() ), "match fails against an object" );
}

{ # multiple conditions
    my $uri = URI->new( "http://search.cpan.org/dist/URI-Match" );

    ok( $uri->match_parts( scheme => '^http$', host => '\.cpan\.org$' ), "match multiple conditions" );
    ok( ! $uri->match_parts( scheme => '^http$', host => '\.perl\.org$' ), "match fails multiple conditions" );
}

{ # match against entire URI
    my $uri = URI->new( "http://search.cpan.org/dist/URI-Match" );

    ok( $uri->match_parts( '\.cpan\.org/.+/.+-Match$' ), "match entire URI" );
    ok( ! $uri->match_parts( '\.perl\.org/.+/.+-Match$' ), "match fails against entire URI" );
}

