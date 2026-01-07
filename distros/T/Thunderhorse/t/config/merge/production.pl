{
	base => 'production_override',
	nested => {
		prod_key => 'prod_nested',
	},
	prod_only => 'prod_value',
	'+items' => [qw(three four)],
	'-removed' => [qw(remove)],
	'=replaced' => [qw(new)],
}

