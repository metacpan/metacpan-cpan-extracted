use strict;

my %PARAMS;
$PARAMS{'Task/Params/CellRefinementLevel'}=7;
$PARAMS{'Task/Params/GridCellSizeInXDirection'}=100;
$PARAMS{'Task/Params/GridCellSizeInYDirection'}=100;

foreach my $val (values %PARAMS) {
	$val = '=' . $val unless ref $val;
}

use XML::Rules qw(paths2rules);

my $parser = XML::Rules->new(
    style => 'filter',
    rules => paths2rules(\%PARAMS)
);

$parser->filter(\*DATA);

__DATA__
<Task>
    <Params>
        <CellRefinementLevel></CellRefinementLevel>
        <foo></foo>
        <GridCellSizeInXDirection>0</GridCellSizeInXDirection>
        <GridCellSizeInYDirection>1</GridCellSizeInYDirection>
    </Params>
    <other>
        <CellRefinementLevel></CellRefinementLevel>
    </other>
</Task>
