#!perl
# PODNAME: subsonic_import_ratings.pl
# ABSTRACT: Import Ratings from an iTunes Library XML Export to a Subsonic Server
use strict;
use warnings;
use utf8;

use CLI::Helpers qw(:output);
use Data::Printer;
use Getopt::Long::Descriptive;
use HTML::Entities;
use Path::Tiny;
use Storable qw(retrieve store dclone);
use WWW::Subsonic;

my ($opt,$usage) = describe_options('%c - %o iTunesLibrary.xml',
    ["Subsonic API Details"],
    ['url|U=s',        "Subsonic Server name, default localhost", { default => 'http://localhost:4000' } ],
    ['username|user|u=s', "Subsonic Username, required." ],
    ['password-file|p=s', "File containing the password for the subsonic user, default: ~/.subsonic_password",
        { default => "$ENV{HOME}/.subsonic_password", callback => { 'must be a valid file' => sub { -f $_[0] } } }
    ],
    ['api-version=s',     "Specify the API Version, defaults to using the WWW::Subsonic default."],
    [],
    ["Import Behavior"],
    ["star-rating",  "If 0-5 rating is greater or equal to this, also 'star' this item, default: 4",
        { default => 4, callbacks => { "must be a positive number between 0 and 5" => sub { $_[0] =~ /^[0-5](?:\.[0-9]+)?/ } } }
    ],
    [],
    ["Caching Behavior"],
    ['cache=s',     "Default Cache Location, default: $ENV{HOME}/.subsonic_cache", { default => "$ENV{HOME}/.subsonic_cache" }],
    ['clear-cache', "Remove the cache file before processing"],
    [],
    ['help', "Display this help", { shortcircuit => 1 }],
);
if( $opt->help ) {
    print $usage->text;
    exit 0;
}

if( $opt->clear_cache ) {
    unlink $opt->cache
        if -f $opt->cache;
}

# Grab the Password
my $password;
if( -f $opt->password_file ) {
    $password = path($opt->password_file)->slurp;
    chomp($password);
}

# Instantiate the API Object
my $subsonic = WWW::Subsonic->new(
    url      => $opt->url,
    $opt->username    ? ( username => $opt->username )       : (),
    $password         ? ( password => $password )            : (),
    $opt->api_version ? ( api_version => $opt->api_version ) : (),
);

my %SongsByArtist;
if( -f $opt->cache ) {
    verbose({color=>'blue'}, "Loading data from the cache.");
    eval {
        %SongsByArtist = %{ retrieve( $opt->cache ) };
        1;
    } or do {
        my $err = $@;
        output({color=>'red',stderr=>1}, sprintf "Failed loading cache %s: %s",
            $opt->cache,
            $@,
        );
    };
}
unless( keys %SongsByArtist ) {
    my $artists = $subsonic->api_request('getArtists');
    debug_var($artists);
    foreach my $idx ( @{ $artists->{artists}{index} } ) {
        debug({color=>'magenta'}, "Index:$idx->{name}");
        foreach my $i (@{ $idx->{artist} })  {
            my $artist     = $i->{name};
            my $normArtist = normalize($artist);
            output({clear=>1},"$i->{id} - $artist ($normArtist)");
            my $artres = $subsonic->api_request(getArtist => { id => $i->{id} } );
            debug_var($artres);
            my $albums = $artres->{artist}{album};
            foreach my $album (
                sort { $a->{year} <=> $b->{year} }
                map  { $_->{year} //= 0; $_ }
               @{ $albums }
            ) {
                output({indent=>1}, sprintf "%04d - %s by %s",
                    $album->{year},
                    $album->{name},
                    $album->{artist},
                );
                my $normAlbum = normalize($album->{name});
                my $albres = $subsonic->api_request(getAlbum => { id => $album->{id} });
                debug_var($albres);
                my $songs = $albres->{album}{song};
                foreach my $song (
                    sort { $a->{track} <=> $b->{track} }
                    map  { $_->{track} ||= 0; $_ }
                    @{ $songs }
                ) {
                    output({indent=>2}, sprintf "%02d - %s",
                        $song->{track},
                        $song->{title},
                    );

                    my $normTitle = normalize($song->{title});
                    $SongsByArtist{$normArtist} ||= {};
                    $SongsByArtist{$normArtist}->{$normAlbum}{$normTitle} ||= [];
                    push @{ $SongsByArtist{$normArtist}->{$normAlbum}{$normTitle} }, $song->{id};
                }
            }
        }
    }
    store( \%SongsByArtist, $opt->cache );
}
debug_var(\%SongsByArtist);

my ($section,%song,%TRACKS);
while(<<>>) {
    chomp;
    next unless /^\t/;
    if( my ($capture) = m{^\t<key>(\w+(?:\s+\w+)*)</key>$} ) {
        $section = $capture;
        next;
    }
    next unless $section;

    # Handle Tracks Section
    if( $section eq 'Tracks' ) {
        if(m{^\t\t<\/dict>}) {
            # End of Track
            if( exists $song{"Track ID"} ) {
                $TRACKS{$song{"Track ID"}} = dclone( \%song );
            }
            if( exists $song{Rating} ) {
                my %normal = ();
                foreach my $k (qw(Artist Album Name)) {
                    next unless exists $song{$k};
                    $normal{$k} = normalize($song{$k});
                }
                if( exists $SongsByArtist{$normal{Artist}} ) {
                    my $Albums = $SongsByArtist{$normal{Artist}};
                    my @ScanAlbums = exists $normal{Album} ? ( $normal{Album} ) : keys %{ $Albums };
                    my @sids = ();
                    foreach my $album ( @ScanAlbums ) {
                        next unless exists $Albums->{$album};
                        next unless exists $Albums->{$album}{$normal{Name}};
                        push @sids, @{ $Albums->{$album}{$normal{Name}} };
                    }
                    if(@sids) {
                        verbose({color=>'green'}, sprintf "%d tracks found for %s - %s - %s",
                            scalar(@sids),
                            map { $_ || 'n/a' } @song{qw(Artist Album Name)},
                        );
                        my $rating = int($song{Rating} / 20);
                        foreach my $song_id ( @sids ) {
                            my $result = $subsonic->api_request('setRating.view' => { id => $song_id, rating => $rating });
                            if( $rating >= $opt->star_rating ) {
                                my $result = $subsonic->api_request( star => { id => $song_id } );
                            }
                        }
                    }
                    else {
                        output({color=>'red'}, sprintf "No tracks found for %s - %s - %s",
                            map { $_ || 'n/a' } @normal{qw(Artist Album Name)},
                        );
                    }
                }
            }
            %song=();
        }
        elsif(m{^\t\t\t<key>(?<key>\w+(?:\s+\w+)*)</key><\w+>(?<value>.+)</\w+>$}n) {
            debug("$_");
            $song{$+{key}} = $+{value}; # }}
        }
    }
}

sub normalize {
    my ($string) = @_;
    my $normalized = lc( $string );
    decode_entities($normalized);
    $normalized =~ s/[^\w\d\s]//g;
    $normalized =~ s/^the\b//;
    $normalized =~ s/^\s+//;
    $normalized =~ s/\s+$//;
    $normalized =~ s/\s{2,}/ /g;
    return $normalized;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

subsonic_import_ratings.pl - Import Ratings from an iTunes Library XML Export to a Subsonic Server

=head1 VERSION

version 0.010

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
