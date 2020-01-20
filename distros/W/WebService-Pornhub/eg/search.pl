use v5.14.0;
use strict;
use warnings;
use WebService::Pornhub;
use JSON::MaybeXS;
use Log::Fast;

my $logger = Log::Fast->new(
    {
        level  => 'DEBUG',
        prefix => '%D %T [%L] ',
        type   => 'fh',
        fh     => \*STDOUT,
    }
);

my $pornhub = WebService::Pornhub->new(
    logger => $logger,
);

my $videos = $pornhub->search(
    search => 'hard',
    'tags[]' => ['asian', 'young'],
    thumbsizes => 'medium',
);

for my $video (@$videos) {
    say encode_json (
        {
            title => $video->{title},
            url => $video->{url},
            pornstars => $video->{pornstars},
            tags => $video->{tags},
        }
    );
}
