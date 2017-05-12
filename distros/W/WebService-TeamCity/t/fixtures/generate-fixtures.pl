use v5.10;
use strict;
use warnings;
use autodie qw( :all );

use Archive::Zip;
use Cpanel::JSON::XS qw( decode_json );
use Data::Visitor::Callback;
use File::pushd qw( pushd );
use HTTP::Cookies;
use HTTP::Headers;
use List::Util qw( first );
use LWP::UserAgent;
use Path::Tiny qw( path tempdir );
use URI;

my $fixtures_dir = path('t/fixtures');
my $uri_base     = 'https://teamcity.jetbrains.com';
my @uris         = map { URI->new( $uri_base . $_ ) } (
      @ARGV
    ? @ARGV
    : qw(
        /httpAuth/app/rest/projects
        /httpAuth/app/rest/buildTypes
        )
);

my $h = HTTP::Headers->new;
$h->header( 'Accept' => 'application/json' );
my $ua = LWP::UserAgent->new(
    cookie_jar      => HTTP::Cookies->new,
    default_headers => $h,
);

$ua->get( $uri_base . '?guest=1' );

my %seen;
for my $uri (@uris) {
    say $uri or die;
    my $res = $ua->get($uri);
    unless ( $res->is_success ) {
        say $res->content or die;
        next;
    }

    $seen{$uri} = 1;

    ( my $path = $uri ) =~ s{^\Q$uri_base\E(?:/httpAuth)?/app/rest/}{};
    $path =~ s{/$}{};

    my $file = $fixtures_dir->file( $path . '.json' );

    ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
    $file->parent->mkpath( 0, 0755 );
    ## use critic

    my $raw = $res->decoded_content;
    $file->spew($raw);

    next if $uri =~ /\.zip$/;

    my $json = decode_json($raw);
    Data::Visitor::Callback->new(
        hash => sub {
            shift;
            my $node = shift;

            return $node unless $node->{href};

            my $uri = URI->new( $uri_base . $node->{href} );
            return $node if $seen{$uri};
            return
                if $uri =~ m{/rest/projects/id:}
                && $uri !~ /id:(?:_Root|TeamCityPluginsByJetBrains_Git)/;

            return
                if $uri =~ m{/rest/buildTypes/id:}
                && $uri
                !~ /id:(?:TeamCityPluginsByJetBrains_Git_JetBrainsGitPluginTeamCity91x)/;

            return
                if $uri =~ m{/rest/builds/id:}
                && $uri !~ m{/rest/builds/id:(?:667885|666188|661984)};

            push @uris, $uri;
            return $node;
        },
    )->visit($json);
}

## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
{
    # Make a fake set of artifacts for one build
    my $temp = tempdir();
    my $dir  = $temp->child('test-results');
    $dir->mkpath(
        {
            verbose => 0,
            mode    => 0755,
        },
    );
    $dir->child('result-1.json')->spew(qq[{ "foo": 42 }\n]);
    $dir->child('result-2.txt')->spew("Some text in a file\n");

    {
        my $pushed = pushd($temp);
        system( 'zip', '-r', '-q', 'artifacts.zip', $dir->basename );
    }

    my $artifacts_dir = $fixtures_dir->child('builds/id:661984/artifacts/');
    $artifacts_dir->mkpath(
        {
            verbose => 0,
            mode    => 0755,
        },
    );

    # We want to simulate bizarro permissions I've seen in downloaded archives
    # where some dirs have 0660 perms.
    my $zip_file = $artifacts_dir->child('archived');
    $temp->child('artifacts.zip')->copy($zip_file);

    my $az = Archive::Zip->new;
    $az->read( $zip_file->stringify );
    my $member = first { $_->fileName eq 'test-results/' } $az->members;
    $member->unixFileAttributes(0644);
    $az->overwrite;
}
