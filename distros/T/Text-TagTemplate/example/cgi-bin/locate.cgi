#!/usr/bin/perl -w
#
# TODO: Add unit tests for this example.
#
# This program is designed as corporate store-locator.
#
# It can be called in one of three ways:  as a form, where values can be
# entered to search for in the database; as an error page when an error
# condition occurs (for example, no matches); and as a list of matching
# records.

use CGI                  qw( :standard );
use Text::TagTemplate qw( :standard :config );
use strict;
use 5.004;
use CGI::Carp qw( fatalsToBrowser );
use English;

# Config (for anything more than trivial applications, I usually put this in
# another file and `require' it in).
sub HTML_DIR() { '../html'            }
sub DATAFILE() { '../data/stores.txt' }

# Find the templates.  Which templates we use depends on what call-type we
# have.
my $call_type = path_info;
$call_type =~ s/[^a-z]//g;
$call_type = 'default' unless $call_type;

my @errors = ();
if ( $call_type eq 'default' ) {
	# Don't need to do much, just display the correct template.
	
	# We'll help them by making them a convenient tag for the start of the
	# form, with the URL including the path info we're going to use.
	add_tag(
		START_FORM => start_form(
			-action => "http://@{[ server_name ]}:"
			         . "@{[ server_port ]}@{[ script_name ]}/"
				 . "search"
		)
	);

} elsif ( $call_type eq 'search' ) {
	# See which values we have to search on.

	SEARCH : {
		# Firstly, we need to open the data file and read in the first
		# line so we know what fields we can search.
		open DATA, DATAFILE or die "open @{[ DATAFILE ]} failed: $ERRNO";
		my $fields = <DATA>;
		chomp $fields;

		my @fields = split /\|/, $fields;

		# Now we find the fields supplied to us that match the fields
		# in the database and assume they're the search functions.
		my %params = map { $ARG => 1 } param;
		my %search = ();
		foreach my $field ( @fields ) {
			$search{ $field } = param( $field )
			   if exists $params{ $field };
		}

		unless ( %search ) {
			push @errors, 'No search parameters supplied.';
			last SEARCH;
		}

		# Now we search through the database looking for matches.
		my $line;
		my @matched_lines = ();
		while ( defined( $line = <DATA> ) ) {
			chomp $line;
			my @line = split /\|/, $line;
			my %line = ();
			for ( my $f = 0; $f < @fields; ++$f ) {
				$line{ $fields[ $f ] } = $line[ $f ];
				}
			my $matched = 0;
			foreach my $search_field ( keys %search ) {
				$matched = 1
				   if $search{ $search_field }
				   =~ /^\Q$line{ $search_field }\E$/i;
			}
			push @matched_lines, \%line if $matched;
		}

		if ( @matched_lines == 0 ) {
			push @errors, 'No records matched your query.';
			last SEARCH;
		}

		# Set the list of elements to the matches (we'd
		# probably sort it first if we were being tidy).
		list( @matched_lines );

		# Now we build the parsed list.  Firstly, we make the callback.
		entry_callback( sub {
			my( $line ) = @_;
			my $tags = +{};
			foreach my $field ( keys %$line ) {
				$tags->{ $field } = $line->{ $field };
			}
			return $tags;
		} );

		entry_file( HTML_DIR . '/search-entry.htmlf' );
		join_file(  HTML_DIR . '/search-join.htmlf'  );
		# We have the fragment files.  We just need to make
		# a new tag with the list.
		add_tag( RESULTS_LIST => parse_list_files );
		close DATA or die "close DATA failed: $ERRNO";
	}
}

if ( @errors ) {
	$call_type = 'error';
	list( @errors );
	entry_callback( sub {
		my( $error ) = @_;
		my $tags = +{};
		$tags->{ ERROR } = $error;
		return $tags;
	} );
	entry_file( HTML_DIR . '/error-entry.htmlf' );
	join_file(  HTML_DIR . '/error-join.htmlf'  );
	add_tag( ERROR_LIST => parse_list_files );
}

my $filename = HTML_DIR . "/$call_type.html";
# Just print a Content-type and the parsed template now.
print header;
print parse_file( $filename );
