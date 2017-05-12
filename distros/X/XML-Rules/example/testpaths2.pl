#a co takhle


use XML::Rules;

my $parser = XML::Rules->new(
    style => 'filter',
    rules => [
		CellRefinementLevel => [
			'task/params' => sub { print STDERR "yeah, the right CellRefinementLevel\n"; return $_[0] => 7},
			sub { print "Nope, a different path! ", join('/', @{$_[2]}), "\n"; return $_[0] => $_[1]; },
		],
		GridCellSizeInXDirection => [
			'task/params' => sub { print STDERR "yeah, the right GridCellSizeInXDirection\n"; return $_[0] => 100},
		],
		GridCellSizeInYDirection => [
			'task/params' => sub { print STDERR "yeah, the right GridCellSizeInYDirection\n"; return $_[0] => 100},
		],
	],
);
# internally the paths are turned into regexps


$parser->filter(\*DATA);

__DATA__
<task>
    <params>
        <CellRefinementLevel></CellRefinementLevel>
        <foo></foo>
        <GridCellSizeInXDirection>0</GridCellSizeInXDirection>
        <GridCellSizeInYDirection>1</GridCellSizeInYDirection>
    </params>
    <other>
        <CellRefinementLevel></CellRefinementLevel>
        <GridCellSizeInXDirection>0</GridCellSizeInXDirection>
    </other>
</task>
