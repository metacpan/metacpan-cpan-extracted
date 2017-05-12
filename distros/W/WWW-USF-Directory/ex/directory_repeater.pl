#!/usr/bin/perl

package Directory;

use 5.008;
use strict;
use warnings 'all';

use parent 'CGI::Application';

use JSON 2.00; # The API was changed
use Try::Tiny;
use WWW::USF::Directory;

sub setup {
	my ($self) = @_;

	# Create a directory object for use later
	$self->{directory} = WWW::USF::Directory->new(
		include_faculty  => 1,
		include_staff    => 1,
		include_students => 0,
	);

	# Start in search mode, which is the only mode
	$self->start_mode('search');
	$self->run_modes(search => 'search');

	return;
}

sub search {
	my ($self) = @_;

	# Hold the results and response
	my (@results, $response);

	# Set the header to specity JSON
	$self->header_add(-type => 'application/json');

	try {
		# Search the directory
		@results = $self->{directory}->search(
			name => scalar $self->query->param('name'),
		);

		foreach my $result (@results) {
			# Change the ::Directory::Entry object into a hash of its attributes
			$result = _moose_object_as_hash($result);

			if (exists $result->{affiliations}) {
				$result->{affiliations} = [map {
					_moose_object_as_hash($_);
				} @{$result->{affiliations}}];
			}
		}

		# Return the JSON-encoded results to print
		$response = JSON->new->encode({
			results => \@results,
		});
	}
	catch {
		# Get the error
		my $error = $_;

		# Return a JSON with the error
		$response = JSON->new->encode({
			error   => "$error",
			results => [],
		});
	};

	# Return the response
	return $response;
}

sub _moose_object_as_hash {
	my ($object) = @_;

	# Convert a Moose object to a HASH with the attribute_name => attribute_value
	my $hash = { map {
		($_->name, $_->get_value($object))
	} $object->meta->get_all_attributes };

	return $hash;
}

1;

## no critic (Modules::ProhibitMultiplePackages)
package main;

use 5.008;
use strict;
use warnings 'all';

our $VERSION = '0.001';

# Start and tun the application
Directory->new->run();

__END__

=head1 NAME

directory_repeater.pl - Example USF directory repeater.

=head1 VERSION

Version 0.001

=head1 USAGE

  directory_repeater.pl name="<name to search for>"

      Running the file directly as a script, you can specify name=value
      parameter and CGI output will be given with the search result.
      The ideal use is to place this in your cgi-bin and access it by
      /cgi-bin/directory_repeater.pl?name=name%20to%20search

=head1 DESCRIPTION

This is an example CGI script that will take a name to search for in the
query string and return a JSON-encoded response with the results (or error).

=head1 OPTIONS

This takes name-value pairs separated by an equal sign C<=> and maps that
to query string name-value pairs.

=head1 DIAGNOSTICS

This script utilizes L<CGI::Application|CGI::Application> and thus all
diagnostics are up to that module.

=head1 EXIT STATUS

Normal exist status will always be C<0> unless a required Perl module
(listed in L</DEPENDENCIES>) is not found.

=head1 CONFIGURATION

There are no configuration options for this script.

=head1 DEPENDENCIES

=over 4

=item * L<CGI::Application|CGI::Application>

=item * L<JSON|JSON> 2.00

=item * L<Try::Tiny|Try::Tiny>

=item * L<WWW::USF::Directory|WWW::USF::Directory>

=item * L<parent|parent>

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

There are no intended limitations, and so if you find a feature in the USF
directory that is not implemented here, please let me know.

Please report any bugs or feature requests to
C<bug-www-usf-directory at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-USF-Directory>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc WWW::USF::Directory

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-USF-Directory>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-USF-Directory>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-USF-Directory>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-USF-Directory/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Douglas Christopher Wilson, all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
