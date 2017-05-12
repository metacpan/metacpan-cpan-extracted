use strict;

my %PARAMS;
$PARAMS{'Task/Params/CellRefinementLevel'}=7;
$PARAMS{'Task/Params/GridCellSizeInXDirection'}=100;
$PARAMS{'Task/Params/GridCellSizeInYDirection'}=100;

my %rules;
while ( my ($tag, $val) = each %PARAMS) {
	$val = '=' . $val unless ref $val;

	if ($tag =~ m{^(.*)/(.*)$}) {
		my ($path, $tagname) = ($1, $2);

		if (exists $rules{$tagname} and ref($rules{$tagname}) eq 'ARRAY') {
			if (@{$rules{$tagname}} % 2) {
				push @{$rules{$tagname}}, $path, $val;
			} else {
				splice @{$rules{$tagname}}, -1, 0, $path, $val;
			}
		} else {
			$rules{$tagname} = [ $path => $val]
		}

	} elsif (exists $rules{$tag} and ref($rules{$tag}) eq 'ARRAY') {
		push @{$rules{$tag}}, $val;
	} else {
		$rules{$tag} = $val
	}
}

use Data::Dumper;
print Dumper(\%rules);

use XML::Rules;

my $parser = XML::Rules->new(
    style => 'filter',
    rules => \%rules
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
