use XML::Rules;

my $parser =XML::Rules->new(rules =>[], ident => ' ', style => 'filter', reformat_all => 1);

print $parser->ToXML(
chart => {
	caption => 'Monthly Sales Summary',
	subcaption => 'For the year 2006',
	xAxisName => 'Month',
	yAxisName => 'Sales',
	numberPrefix => '$',
	_content => [ "\n  ",
		[ set => {label => 'January', value => '17400'}], "\n  ",
		[ set => {label => 'February', value => '19800'}], "\n  ",
		[ set => {label => 'March', value => '21800'}], "\n  ",
		[ set => {label => 'April', value => '23800'}], "\n  ",
		[ set => {label => 'May', value => '29600'}], "\n  ",
		[ set => {label => 'June', value => '27600'}], "\n  ",
		[ set => {label => 'July', value => '31800'}], "\n  ",
		[ set => {label => 'August', value => '39700'}], "\n  ",
		[ set => {label => 'September', value => '37800'}], "\n  ",
		[ set => {label => 'October', value => '21900'}], "\n  ",
		[ set => {label => 'November', value => '32900'}], "\n  ",
		[ set => {label => 'December', value => '39800'}], "\n",
	]
}
)
