package MyUA;

use Test::Override::UserAgent for => 'configuration';

use URI::QueryParam;

my %dispatch = (
	advSearch  => \&_handle_advSearch,
	liveSearch => \&_handle_liveSearch,
);

our @campus_list  = qw(Tampa Lakeland Sarasota StPete);
our @college_list = qw(Architecture Education Engineering Nursing);
our @department_list = qw(Advising);
our $TooManyResults_Name = 'TOO_MANY';
our $UnknownResponse_Name = 'UNKNOWN';
our $ZeroMatches_Name = 'ZERO';
our $Matches_Name = 'SOME';

override_request
	path => '/',
	sub {
		my ($request) = @_;

		# Get the SAJAX function
		my $function = $request->uri->query_param('rs');

		if (!exists $dispatch{$function}) {
			# Return a SAJAX error
			return [200, ['Content-Type' => 'text/html'], ['-:**** not callable']];
		}

		# Get the content from the handling function
		my $content = $dispatch{$function}->($request);

		# Return the content
		return [200, ['Content-Type' => 'text/html'], [$content]];
	};

sub _handle_advSearch {
	my ($request) = @_;

	# Build the campus select element
	my $campus_select = join q{},
		q{<select id="camp" class="selgroup" name="camp">},
		q{<option value="Any">Any</option>},
		(map { sprintf q{<option value="%s">%s</option>}, $_, $_ } @campus_list),
		q{</select>};

	# Build the college select element
	my $college_select = join q{},
		q{<select id="colg" class="selgroup" name="colg">},
		q{<option value="Any">Any</option>},
		(map { sprintf q{<option value="%s">%s</option>}, $_, $_ } @college_list),
		q{</select>};

	# Build the department select element
	my $department_select = join q{},
		q{<select id="dept" class="selgroup" name="dept">},
		q{<option value="Any">Any</option>},
		(map { sprintf q{<option value="%s">%s</option>}, $_, $_ } @department_list),
		q{</select>};

	return q{+:var res = '<form><table>}
	      .qq{<tr><td>$campus_select Campus</td></tr>}
	      .qq{<tr><td>$college_select College</td></tr>}
	      .qq{<tr><td>$department_select Department</td></tr>}
	      .q{</table></form>'; res;};
}

sub _handle_liveSearch {
	my ($request) = @_;

	# Get the query parameters
	my ($name) = $request->uri->query_param('rsargs[]');

	if ($name eq $TooManyResults_Name) {
		# Return too many results response
		return q{+:var res = '<h3>Too many results</h3><p>Your search returned more than 25 matches.You may want to narrow your search with Advanced Search Options</p>'; res;};
	}
	elsif ($name eq $UnknownResponse_Name) {
		# Some random crap
		return q{+:var res = 'CRAP'; res;};
	}
	elsif ($name eq $ZeroMatches_Name) {
		# No matches found
		return q{+:var res = '<h3>0 matches found</h3><p>You may want to narrow your search with Advanced Search Options</p>'; res;};
	}
	else {
		return q{+:var res = '<h3>3 matches found</h3><table class=\'sortable\' id=\'srchtble\'><tr><td class=\"toprow\">Family Name</td><td class=\"toprow\">Given Name</td><td class=\"toprow\">Affiliation</td><td class=\"toprow\">College</td><td class=\"toprow\">Campus</td><td class=\"toprow\">Email</td><td class=\"toprow\">Campus Phone</td><td class=\"toprow\">Campus Mailstop</td></tr><tr bgcolor=#dfd0a5 align=left><td class=\"leftcell\">Barber</td><td>Holly<br/>L.</td><td>Sr Laboratory Animal Tech : Comparative Medicine<br/></td><td>Arts and Sciences</td><td>&nbsp;</td><td><a href=\"mailto:hbarber@mail.usf.edu\">hbarber@mail.usf.edu</td><td><a href=\"tel:1-813-972-2000\">813/972-2000</a></td><td><a href=\"http://www.usf.edu/Campuses/\">MDC20</a></td><tr bgcolor=#ffffff align=left><td class=\"leftcell\">Barber</td><td>Michael<br/>J</td><td>Faculty : Molecular Medicine</td><td>&nbsp;</td><td>&nbsp;</td><td><a href=\"mailto:mbarber@health.usf.edu\">mbarber@health.usf.edu</td><td><a href=\"tel:1-813-974-9702\">813/974-9702</a></td><td><a href=\"http://www.usf.edu/Campuses/\">MDC7</a></td><tr bgcolor=#dfd0a5 align=left><td class=\"leftcell\">Barber</td><td>Thalia<br/>E</td><td>Clerical and Secretarial : Environmental & Occupational Health<br/></td><td>Business Administration</td><td>&nbsp;</td><td><a href=\"mailto:tbarber3@mail.usf.edu\">tbarber3@mail.usf.edu</td><td><a href=\"tel:1-813-974-3144\">813/974-3144</a></td><td><a href=\"http://www.usf.edu/Campuses/\">MDC0056</a></td></table>'; res;};
	}
}

1;
