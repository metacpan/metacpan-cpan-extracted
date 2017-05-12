use URI::duri;

my $u = URI::duri->new("duri:2001-01-01T12:34:56.789+01:http://example.net/foo#bar");

my @fields = qw(
	scheme opaque path fragment as_string as_iri canonical secure authority
	path path_query query userinfo host ihost port host_port default_port
	datetime datetime_string embedded_uri
);

foreach my $field (@fields)
{
	if (not $u->can($field))
	{
		printf "%16s : can't\n" => $field;
		next;
	}
	
	my $value = eval { $u->$field };
	if (defined $value)
		{ $value = qq{"$value"} }
	else
		{ $value = 'undef' }
	
	printf "%16s : %s\n" => $field, $value;
}

