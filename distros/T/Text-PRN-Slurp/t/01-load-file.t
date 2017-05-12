#!perl -T
use 5.006;
use strict;
use warnings;

use lib '../lib';

use Test::More tests => 5;
use Test::Warn;
use Text::PRN::Slurp;

BEGIN {
    use_ok( 'Text::PRN::Slurp' ) || print "Bail out!\n";
}

my $object = Text::PRN::Slurp->new ();
isa_ok ($object, 'Text::PRN::Slurp');

{
    my $slurp = Text::PRN::Slurp->new->load(
        'file' => 't/data/sample_2.prn',
        'file_headers' => [ q{ID}, q{Type}, q{Description} ]
    );

    is_deeply(
        $slurp,
        [
            {
                'Description' => 'Active Server Pages',
                'Type' => 'ASP',
                'ID' => '1'
            },
            {
                'ID' => '2',
                'Type' => 'JSP',
                'Description' => 'JavaServer Pages'
            },
            {
                'Description' => 'Portable Network Graphics',
                'ID' => '3',
                'Type' => 'PNG'
            },
            {
                'Type' => 'GIF',
                'ID' => '4',
                'Description' => 'Graphics Interchange Format'
            },
            {
                'Description' => 'Windows Media Video',
                'Type' => 'WMV',
                'ID' => '5'
            }
        ],
        "PRN file parsed correctly"
    );
}

# With extra column
{
    my $slurp;
    warning_like {
        $slurp = Text::PRN::Slurp->new->load(
            'file' => 't/data/sample_2.prn',
            'file_headers' => [ q{ID}, q{Type}, q{Description}, q{JAI} ]
        );
    }
    qr/Columns doesn't seems to be matching/i,
    'warning when extra colum supplied';

    is_deeply(
        $slurp,
        [
            {
                'Type' => 'ASP',
                'Description' => 'Active Server Pages',
                'ID' => '1'
            },
            {
                'Description' => 'JavaServer Pages',
                'Type' => 'JSP',
                'ID' => '2'
            },
            {
                'Description' => 'Portable Network Graphics',
                'Type' => 'PNG',
                'ID' => '3'
            },
            {
                'Description' => 'Graphics Interchange Format',
                'Type' => 'GIF',
                'ID' => '4'
            },
            {
                'Type' => 'WMV',
                'Description' => 'Windows Media Video',
                'ID' => '5'
            }
        ],
        "PRN file parsed correctly"
    );
}
