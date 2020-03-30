#!perl
# PODNAME: subsonic_sync_starred.pl
# ABSTRACT: Download and/or sync starred media to a target directory
use strict;
use warnings;

use CLI::Helpers qw(:output);
use Getopt::Long::Descriptive;
use List::Util qw( sum );
use Path::Tiny;
use WWW::Subsonic;

my ($opt,$usage) = describe_options('%c - %o <target_directory>',
    ["Subsonic API Details"],
    ['url|U=s',           "Subsonic Server url, default http://localhost:4000", { default => 'http://localhost:4000' } ],
    ['username|user|u=s', "Subsonic Username, required." ],
    ['password-file|p=s', "File containing the password for the subsonic user, default: ~/.subsonic_password",
        { default => "$ENV{HOME}/.subsonic_password", callback => { 'must be a valid file' => sub { -f $_[0] } } }
    ],
    ['api-version=s',     "Specify the API Version, defaults to using the WWW::Subsonic default."],
    [],
    ["Media Directories"],
    ["local-media-dir|local|l=s", "Local directory which might contain media files we can sync."],
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

# This is where we'll store information
# about the files we've sync'd
my %SyncComplete = ();

# Start Wide, circle back
my $response = $subsonic->api_request('getStarred');
debug_var({data=>1}, [sort keys %{$response->{starred}}]);
if( exists $response->{starred} ) {
    my $starred = $response->{starred};
    debug("Processing starred items");
    processBranch($starred->{artist}) if exists $starred->{artist} && $opt->artists;
    processBranch($starred->{album})  if exists $starred->{album}  && $opt->albums;
    processBranch($starred->{song})   if exists $starred->{song}   && $opt->songs;
}
output({color=>'green'},
    sprintf "Sync complete with %d items, %d bytes.",
        keys %SyncComplete ? scalar(keys %SyncComplete) : 0,
        keys %SyncComplete ? sum(values %SyncComplete) : 0,
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
        my $dst = path($target_directory)->child($leaf->{path});
        unless( $dst->exists ) {
            # Create the Directory
            $dst->parent->mkpath;
            if( $opt->local_media_dir ) {
                my $src = path($opt->local_media_dir)->child($leaf->{path});
                if( $src->exists ) {
                    # Copy the file
                    my $copied = $src->copy($dst->absolute->stringify);
                    # Record how much data we copied
                    my $bytes = $copied->stat->size;
                    verbose({color=>'green'},
                        sprintf "%s - %d bytes copied",
                            $copied->absolute->stringify,
                            $bytes,
                    );
                    $SyncComplete{$leaf->{path}} = $bytes;
                }
            }
            if( !exists $SyncComplete{$leaf->{path}} ) {
                my $data = $subsonic->api_request( download => { id => $leaf->{id} } );
                if( $data ) {
                    $dst->spew_raw($data);
                    my $bytes = length $data;
                    verbose({color=>'magenta'},
                        sprintf "%s - %d bytes downloaded",
                            $dst->absolute->stringify,
                            $bytes,
                    );
                    $SyncComplete{$leaf->{path}} = $bytes;
                }
            }
        }
        else {
            verbose({color=>'bright_black'}, $dst->absolute->stringify . " exists");
        }
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

subsonic_sync_starred.pl - Download and/or sync starred media to a target directory

=head1 VERSION

version 0.009

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
