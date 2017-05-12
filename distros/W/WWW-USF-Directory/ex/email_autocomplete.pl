#!/usr/bin/perl

package # No CPAN indexing
	Directory;

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
			name => scalar $self->query->param('q'),
		);

		# Remove all results without e-mail addresses
		@results = grep { $_->has_email } @results;

		# Change results to be the name and e-mail address
		@results = map { +{ $_->full_name => $_->email } } @results;

		# Return the JSON-encoded results to print
		$response = JSON->new->encode(\@results);
	}
	catch {
		# Return an empty JSON list
		$response = JSON->new->encode([]);
	};

	# Return the response
	return $response;
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

email_autocomplete.pl - Example USF directory e-mail auto-completion.

=head1 VERSION

Version 0.001

=head1 USAGE

  email_autocomplete.pl q="<thing to complete>"

      Running the file directly as a script, you can specify q=value
      parameter and CGI output will be given with the search result.
      The ideal use is to place this in your cgi-bin and access it by
      /cgi-bin/email_autocomplete.pl?q=name%20to%20complete

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
