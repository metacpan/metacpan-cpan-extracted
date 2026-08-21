package WWW::Garden::Design::Controller::Flower;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

use WWW::Garden::Design::Util::ValidateForm;

our $VERSION = '0.97';

# -----------------------------------------------

sub format_details
{
	my($self, $item) = @_;

	$self -> app -> log -> debug('Flower.format_details(...)');

	my($html) = "<tr>\n";

	for my $name (qw/common_name scientific_name aliases height width/)
	{
		$html .= "<td class = 'generic_border'>$$item{$name}</td>\n";
	}

	$html .= "</tr>\n";

	return $html;

} # End of format_details.

# -----------------------------------------------

sub format_errors
{
	my($self, $params) = @_;

	$self -> app -> log -> debug('Flower.format_errors(...)');

	my($html) = '';

	my($errors);

	for my $name (sort keys %{$$params{errors} })
	{
		$errors	= $$params{errors}{$name};
		$html	.= <<EOS;
<tr>
	<td class = 'generic_border'>$name</td>
	<td class = 'generic_border'>$$errors[0]</td>
	<td class = 'generic_border'>$$errors[1]</td>
	<td class = 'generic_border'>$$errors[2]</td>
</tr>
EOS
	}

	return $html;

} # End of format_errors.

# -----------------------------------------------
# https://github.com/kraih/mojo/wiki/Request-data.

sub process
{
	my($self) = @_;

	$self -> app -> log -> debug('Flower.process()');

	my($defaults)	= $self -> app -> defaults;
	my($validator)	= WWW::Garden::Design::Util::ValidateForm -> new;
	my($params)		= $validator -> flower_details($self, $defaults);

	if ($$params{success})
	{
#		$$defaults{db} -> add_flower($params);

		$self -> stash(error	=> undef);
		$self -> stash(details	=> $self -> format_details($params) );
		$self -> stash(message	=> $$params{message});
	}
	else
	{
		$self -> stash(error	=> $self -> format_errors($params) );
		$self -> stash(details	=> undef);
		$self -> stash(message	=> $$params{message});
		$self -> app -> log -> error($$params{message});
	}

	$self -> render;

} # End of process.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Garden::Design::Controller::Flower - Manage the 'flowers' database

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
