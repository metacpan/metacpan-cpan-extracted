use strict;
use warnings;

use lib './lib';
use WebService::Readwise;
use DateTime;
use DateTime::Format::ISO8601;
use utf8::all;

#use Data::Dumper;

$|++;

# This is an example script that exprts all your highlights from
# Readwise.io and writes Markdown files for your Zettelkasten notes
# system.
# This was the module author's original use case.
#
# Assumes that the WEBSERVICE_READWISE_TOKEN environment variable is set
# has been set

my $rw     = WebService::Readwise->new;
my $result = $rw->export;

my @entries;
push @entries, @{ $result->{results} };
while ( $result->{nextPageCursor} ) {
    $result = $rw->export( pageCursor => $result->{nextPageCursor} );
    push @entries, @{ $result->{results} };
}

for my $entry (@entries) {
    #warn Dumper [ sort keys %$entry ];
    for my $h ( @{ $entry->{highlights} } ) {
#        warn Dumper [ sort keys %$h ];

        my @tags = sort map { $_->{name} } @{ $h->{tags} };
        push @tags, 'readwise';

        my $dt = DateTime::Format::ISO8601->parse_datetime(
            $h->{highlighted_at}
            || $h->{created_at}
        );
        my $zettel_id
            = $dt->ymd('')
            . sprintf( '%02d', $dt->hour )
            . sprintf( '%02d', $dt->minute )
            . sprintf( '%03d', $dt->fractional_second * 10 );

            $h->{text} =~ s/\n/\n> /g;

        my $text = sprintf(
            <<'END',
# %s
(Author: %s)

ZettelID: %s

%s

> %s

%s 

SOURCE: [%s](%s)

%s

Date Highlighted: %s
END
            $entry->{readable_title},
            $entry->{author} || '',
            $zettel_id,
            @tags
            ? 'Tags: #' . join( " #", @tags )
            : '',
            $h->{text},
            $h->{note} ? 'NB: ' . $h->{note} : '',
            $h->{readwise_url},
            $h->{readwise_url},
            $entry->{source_url} ? '[' . $entry->{source_url} .'](' . $entry->{source_url} . ')': '',
            $h->{highlighted_at},
        );

        open my $out, '>', './z/' .$zettel_id . '.md';
        print $out $text;
        close $out;
    }
}
