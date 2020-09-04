#!perl
# PODNAME: subsonic_starred_m3u.pl
# ABSTRACT: Generate an M3U file based on your starred songs
use strict;
use warnings;

use CLI::Helpers qw(:output);
use Getopt::Long::Descriptive;
use List::Util qw( sum );
use Path::Tiny;
use WWW::Subsonic;

my %DEFAULT = (
    name => 'Subsonic Starred',
);

my ($opt,$usage) = describe_options('%c - %o <target_directory>',
    ["Subsonic API Details"],
    ['url|U=s',           "Subsonic Server url, default http://localhost:4000", { default => 'http://localhost:4000' } ],
    ['username|user|u=s', "Subsonic Username, required." ],
    ['password-file|p=s', "File containing the password for the subsonic user, default: ~/.subsonic_password",
        { default => "$ENV{HOME}/.subsonic_password", callback => { 'must be a valid file' => sub { -f $_[0] } } }
    ],
    ['api-version=s',     "Specify the API Version, defaults to using the WWW::Subsonic default."],
    [],
    ["Playlist Options"],
    ["name|n=s", "Playlist name, default: $DEFAULT{name}", { default => $DEFAULT{name} }],
    [],
    ["Starred Media Options"],
    ["all|A",     "Sync all starred media", { implies => [qw(artists albums songs)] }],
    ["artists|a", "Sync all songs from starred artists" ],
    ["albums|b",  "Sync all songs from starred albums" ],
    ["songs|s",   "Sync all starred songs" ],
    [],
    ['help', "Display this help", { shortcircuit => 1 }],
);
if( $opt->help ) {
    print $usage->text;
    exit 0;
}

# Grab Target Directory
my $target_directory = shift;
if( !defined $target_directory || !-d $target_directory ) {
    print $usage->text;
    output({stderr=>1,color=>'red',clear=>1},
        "Must specify a valid target directory that exists."
    );
    exit 1;
}

# Process the Password
my $password = path($opt->password_file)->slurp;
chomp($password);

# Build the API Object
my $subsonic = WWW::Subsonic->new(
    url      => $opt->url,
    $opt->username    ? ( username => $opt->username ) : (),
    $password         ? ( password => $password )      : (),
    $opt->api_version ? ( api_version => $opt->api_version ) : (),
);

# Keep count of how many songs we add
my $Starred = 0;

# Start Wide, circle back
my $playlist_file = sprintf "%s/%s.m3u", $target_directory, $opt->name;
my $response = $subsonic->api_request('getStarred');
open( my $m3u, ">", $playlist_file )
    or die "Unable to write to '$playlist_file'";

print $m3u "#EXTM3U\n";

debug_var({data=>1}, [sort keys %{$response->{starred}}]);
if( exists $response->{starred} ) {
    my $starred = $response->{starred};
    debug("Processing starred items");
    processBranch($starred->{artist}) if exists $starred->{artist} && $opt->artists;
    processBranch($starred->{album})  if exists $starred->{album}  && $opt->albums;
    processBranch($starred->{song})   if exists $starred->{song}   && $opt->songs;
}
output({color=>'green'},
    sprintf "Created '%s' playlist with %d items.",
        $opt->name, $Starred
);

sub processBranch {
    my ($branch) = @_;
    debug_var($branch);

    foreach my $node (@{ $branch }) {
        # MadSonic API doesn't format Artists the same as Subsonic
        if( !exists $node->{artist} && exists $node->{name} ) {
            $node->{artist} = $node->{name};
            $node->{isDir} = 'true';
        }
        verbose({level=>2,color=>'cyan'}, sprintf "Processing Branch: %s",
            join(' - ',
                map  { $node->{$_} }
                grep { exists $node->{$_} } qw( artist album title )
            ),
        );
        if( exists $node->{isDir} && $node->{isDir} eq 'true' ) {
            my $resp = $subsonic->api_request( getMusicDirectory => { id => $node->{id} } );
            processBranch( $resp->{directory}{child} ) if exists $resp->{directory}{child};
        }
        else {
            processLeaf($node);
        }
    }
}

sub processLeaf {
    my ($leaf) = @_;
    debug_var($leaf);

    if( $leaf->{path} ) {
        printf $m3u "#EXTINF:%d,%s - %s\n%s\n",
            @{ $leaf }{qw(duration title artist path)};
        $Starred++;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

subsonic_starred_m3u.pl - Generate an M3U file based on your starred songs

=head1 VERSION

version 0.010

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
