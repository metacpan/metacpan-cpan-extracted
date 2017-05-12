use Test::More;

use URL::List;

my $list = URL::List->new(
    urls => [qw(
        http://www.businessinsider.com/1.html
        http://www.businessinsider.com/2.html
        http://www.businessinsider.com/3.html
        http://www.engadget.com/1.html
        http://www.engadget.com/2.html
        http://www.engadget.com/3.html
        http://www.engadget.com/4.html
        http://www.independent.co.uk/1.html
        http://www.independent.co.uk/2.html
        http://www.pcmag.com/1.html
        http://www.pcmag.com/2.html
        http://www.pcmag.com/3.html
        http://www.technologyreview.com/1.html
        http://www.technologyreview.com/2.html
        http://www.technologyreview.com/3.html
        http://www.technologyreview.com/4.html
        http://www.zdnet.com/1.html
        http://www.zdnet.com/2.html
        http://www.zdnet.com/3.html
    )],
);

is_deeply(
    $list->blocks_by_host,
    [
        [qw(
            http://www.businessinsider.com/1.html
            http://www.engadget.com/1.html
            http://www.independent.co.uk/1.html
            http://www.pcmag.com/1.html
            http://www.technologyreview.com/1.html
            http://www.zdnet.com/1.html
        )],

        [qw(
            http://www.businessinsider.com/2.html
            http://www.engadget.com/2.html
            http://www.independent.co.uk/2.html
            http://www.pcmag.com/2.html
            http://www.technologyreview.com/2.html
            http://www.zdnet.com/2.html
        )],

        [qw(
            http://www.businessinsider.com/3.html
            http://www.engadget.com/3.html
            http://www.pcmag.com/3.html
            http://www.technologyreview.com/3.html
            http://www.zdnet.com/3.html
        )],

        [qw(
            http://www.engadget.com/4.html
            http://www.technologyreview.com/4.html
        )],
    ],
    'blocks',
);

done_testing;
