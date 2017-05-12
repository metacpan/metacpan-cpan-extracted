package WWW::ActiveState::PPM;

=pod

=head1 NAME

WWW::ActiveState::PPM - Scrape build status from the ActiveState build farm

=head1 DESCRIPTION

B<THIS MODULE IS CONSIDERED EXPERIMENTAL>

B<API OR FUNCTIONALITY MAY CHANGE WITHOUT NOTICE>

B<YOU HAVE BEEN WARNED!>

This module is used to extract the build state of all the modules from the
ActiveState PPM website, located at L<http://ppm.activestate.com/>.

=head1 METHODS

=cut

use 5.006;
use strict;
use LWP::Simple ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

my $BASEURI = "http://ppm.activestate.com/BuildStatus/";





#####################################################################
# Constructor

=pod

=head2 new

  my $scraper = WWW::ActiveState::PPM->new(
      trace   => 0,
      version => '5.10',
  );

The C<new> constructor creates a new website scraping object.

The optional boolean C<trace> param (off by default) is
supplied to make the scraping object print status to STDOUT
as it runs.

The optional C<version> param (5.10 by default) is used to
set the version of Perl that the scraper should target.
Legal values are '5.6', '5.8' and '5.10'.

Returns a new B<WWW::ActiveState::PPM> object, or throws an
exception on error.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self->{version} ||= '5.10';
	$self->{trace}     = !! $self->{trace};
	$self->{dists}     = {};
	return $self;
}

=pod

=head2 trace

The C<trace> accessor is used to discover if tracing is enabled
for the object.

=cut

sub trace {
	$_[0]->{trace};
}

=pod

=head2 version

The C<version> accessor returns the version of Perl that the scraper
is targetting.

=cut

sub version {
	$_[0]->{version};
}

=pod

=head2 run

The C<run> method is used to kick off the parsing process.

Returns true when all packages have been checked, or throws an
exception if an error occurs.

=cut

sub run {
	my $self = shift;
	foreach my $letter ( 'A' .. 'Z' ) {
		my $uri = "$BASEURI$self->{version}-$letter.html";
		print "Processing letter $letter...\n" if $self->trace;
		$self->_scrape( $uri );
	}
	return 1;	
}

sub _scrape {
	my $self    = shift;
	my $uri     = shift;
	my $content = LWP::Simple::get($uri);
	unless ( defined $content ) {
		die "Failed to fetch $uri";
	}

	# Get the table
	unless ( $content =~ m/\<table id\=\"packages\"\>(.+?)\<\/table\>/s ) {
		die "Failed to find packages table";
	}
	my $table = $1;

	# Separate out the rows
	my @rows = $table =~ m/\<tr\b[^>]*\>(.+?)\<\/tr\>/sg;
	unless ( @rows ) {
		die "Failed to find rows";
	}

	# Get the platforms
	my $headers   = $rows[0];
	my @platforms = $headers =~ m/\<th class\=\"platform\"\>(\w+)\<\/th\>/sg;
	unless ( @platforms ) {
		die "Failed to find platforms";
	}

	# Process the rows
	foreach my $rownum ( 0 .. $#rows ) {
		my $row    = $rows[$rownum];
		my $record = {};

		# Skip headers
		next if $row =~ /\<th/;

		# Parse the row
		unless ( $row =~ m/\<td class\=\"package\"\>(.+?)\<\/td\>/s ) {
			die "Failed to find package on row $rownum";
		}
		my $pkg = $record->{package} = $1;
		unless ( $row =~ m/\<td class\=\"package\"\>(.+?)\<\/td\>/s ) {
			die "Failed to find version on row $rownum";
		}
		$record->{version} = $1;
		my @results = $row =~ m/\<td class\=\"(pass|fail|core)\"\>.+?\<\/td\>/sg;
		unless ( @results = @platforms ) {
			die "Failed to find expected results on row $rownum";
		}
		foreach ( 0 .. $#platforms ) {
			$record->{$platforms[$_]} = $results[$_];
		}

		# Add to the collection
		$self->{dists}->{$pkg} = $record;
	}

	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-ActiveState-PPM>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ppm.activestate.com>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
