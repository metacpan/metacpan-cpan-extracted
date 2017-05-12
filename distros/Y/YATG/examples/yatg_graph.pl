#my ($xtitle, $totaltime, $timefmt, $step, $major, $xlbloffset,
#        $rulecols, $xtickcols)
{
    'day'   => [
        'Last 24 Hours', 86400, 'hh:nn', 300, 3600, 0,
        [0x00eeeeee, 0x00eeeeee, 0x00ffffff, 0x00ffffff],
        [0x00000000, 0x00eeeeff],
    ],
    'week'  => [
        'Last Week', 604800, 'w', 2100, 86400, 43200,
        [0x00eeeeee, 0x00cccccc, 0x00eeeeee, 0x00eeeeee],
        [0x00000000, 0x00eeeeff]
    ],
    'month' => [
        'Last Month', 2419200, 'dd', 8400, 259200, 43200,
        [0x00eeeeee, 0x00eeeeee, 0x00eeeeee, 0x00eeeeee],
        [0x00000000, 0x00000000]
    ],
};
