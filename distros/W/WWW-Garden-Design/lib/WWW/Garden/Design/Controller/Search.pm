package WWW::Garden::Design::Controller::Search;

use Mojo::Base 'Mojolicious::Controller';

use boolean;

use Moo;

our $VERSION = '0.97';

# -----------------------------------------------

sub display
{
	my($self)				= @_;
	my($defaults)			= $self -> app -> defaults;
	my($db)					= $$defaults{db};
	my($csrf_token)			= $self -> param('csrf_token')	|| '';
	my($search_text)		= $db -> trim($self -> param('search_text')	|| '');
	my($ids)				= $$defaults{search_attribute_ids};
	my(%search_attributes)	= map{($_ => ($self -> param($_) || '') )} map{@$_} @$ids;
	my($search_attributes)	= join('', values %search_attributes);
	my($must_have)			= ( (length($search_text) > 0) || ($search_attributes =~ /true/) ) ? true : false;

	if ($must_have -> isTrue)
	{
		my($constants_table)			= $$defaults{constants_table};
		my($search_result, $request)	= $db -> search($defaults, $constants_table, \%search_attributes, $search_text);
		my($match_count)				= 0;
		my($result_html)				= '';

		my($message);

		if ($$request{text_is_clean} -> isTrue)
		{
			($match_count, $result_html) = $self -> format($constants_table, $db, $search_result);
		}
		else
		{
			$message		= "The search text '$search_text' can't be used!";
			$result_html	= '';

			$self -> app -> log -> error($message);
		}

		$self -> stash(elapsed_time	=> sprintf('%.2f', $$request{time_taken}) );
		$self -> stash(error		=> $message);
		$self -> stash(match_count	=> $match_count);
		$self -> stash(result_html	=> $result_html);
	}
	else
	{
		my($message) = 'Please supply some search text or select some attributes';

		$self -> stash(elapsed_time	=> 0);
		$self -> stash(error		=> $message);
		$self -> stash(match_count	=> 0);
		$self -> stash(result_html	=> undef);
		$self -> app -> log -> error($message);
	}

	$self -> render;

} # End of display.

# -----------------------------------------------

sub format
{
	my($self, $constants_table, $db, $search_results) = @_;
	my($count)	= 0;
	my($html)	= '';

	my($attribute);
	my($native);

	for my $item (@$search_results)
	{
		$count++;

		# Find which of the flower's attributes is 'Native'.

		my($native) = 'N/A';

		for $attribute (@{$$item{attributes} })
		{
			$native = $$attribute{range} if ($$attribute{name} eq 'Native');
		}

		# Note: Every time you add a column, you must update:
		# o templates/initialize/homepage.html.ep.
		# o templates/search/display.html.ep.

		$html .= <<EOS;
<tr>
	<td>$count</td>
	<td>$native</td>
	<td>$$item{scientific_name}</td>
	<td>$$item{common_name}</td>
	<td>$$item{aliases}</td>
	<td>$$item{hxw}</td>
	<td>$$item{publish}</td>
	<td>
		<button class = 'button' onClick='populate_details($$item{id})'>
			<img src = '$$item{thumbnail_url}' width = '$$constants_table{cell_width}' height = '$$constants_table{cell_height}'/>
		</button>
	</td>
</tr>
EOS
	}

	return ($count, $html);

} # End of format.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Garden::Design::Controller::Search - Manage the 'flowers' database

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/WWW-Garden-Design>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Garden::Design>.

=head1 Author

L<WWW::Garden::Design> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2014.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2018, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
