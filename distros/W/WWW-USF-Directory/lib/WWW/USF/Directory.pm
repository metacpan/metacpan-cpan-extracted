package WWW::USF::Directory;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.003001';

###########################################################################
# MOOSE
use Moose 0.89;
use MooseX::StrictConstructor 0.08;

###########################################################################
# MOOSE TYPES
use MooseX::Types::Moose qw(
	Bool
);
use MooseX::Types::URI qw(
	Uri
);

###########################################################################
# MODULE IMPORTS
use HTML::HTML5::Parser 0.101;
use List::MoreUtils 0.07;
use Net::SAJAX 0.102;
use Const::Fast 0.004 qw(const);
use WWW::USF::Directory::Entry;
use WWW::USF::Directory::Entry::Affiliation;
use WWW::USF::Directory::Exception;

###########################################################################
# PRIVATE CONSTANTS
const my $FACULTY_BIT  => 1;
const my $STAFF_BIT    => 2;
const my $STUDENTS_BIT => 4;

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# ATTRIBUTES
has 'directory_url' => (
	is  => 'rw',
	isa => Uri,

	documentation => q{This is the URL of the directory page were the requests are made},
	coerce  => 1,
	default => 'http://directory.acomp.usf.edu/',
	trigger => sub { shift->_sajax->url(shift); }, # Update the SAJAX URL
);
has 'include_faculty' => (
	is  => 'rw',
	isa => Bool,

	documentation => q{This determines if faculty should be returned in the search results},
	default => 1,
);
has 'include_staff' => (
	is  => 'rw',
	isa => Bool,

	documentation => q{This determines if staff should be returned in the search results},
	default => 1,
);
has 'include_students' => (
	is  => 'rw',
	isa => Bool,

	documentation => q{This determines if students should be returned in the search results},
	default => 0,
);

###########################################################################
# PRIVATE ATTRIBUTES
has '_advanced_search_parameters' => (
	is  => 'rw',
	isa => 'HashRef',

	builder => '_build_advanced_search_parameters',
	lazy    => 1,
);
has '_sajax' => (
	is  => 'rw',
	isa => 'Net::SAJAX',

	builder => '_build_sajax',
	lazy    => 1,
	handles => {
		user_agent => 'user_agent',
	},
);

###########################################################################
# METHODS
sub campus_list {
	my ($self) = @_;

	# Return the list of campuses
	return $self->_advanced_search_parameter_list('campus');
}
sub college_list {
	my ($self) = @_;

	# Return the list of colleges
	return $self->_advanced_search_parameter_list('college');
}
sub department_list {
	my ($self) = @_;

	# Return the list of departments
	return $self->_advanced_search_parameter_list('department');
}
sub search {
	my ($self, %args) = @_;

	# Unwrap the name from the arguments
	my $name = $args{name};

	if (!defined $name) {
		# "name" is a required argument
		WWW::USF::Directory::Exception->throw(
			class    => 'MethodArguments',
			message  => 'The argument "name" is required',
			argument => 'name',
			method   => 'search',
		);
	}

	if (length $name == 0) {
		# "name" cannot be empty
		WWW::USF::Directory::Exception->throw(
			class          => 'MethodArguments',
			message        => 'The argument "name" cannot be an empty string',
			argument       => 'name',
			argument_value => $name,
			method         => 'search',
		);
	}

	# Get the inclusion from the arguments
	my ($include_faculty, $include_staff, $include_students) =
		@args{qw(include_faculty include_staff include_students)};

	# Determine the inclusion of faculty
	if (!defined $include_faculty) {
		$include_faculty = $self->include_faculty
	}

	# Determine the inclusion of staff
	if (!defined $include_staff) {
		$include_staff = $self->include_staff;
	}

	# Determine the inclusion of students
	if (!defined $include_students) {
		$include_students = $self->include_students;
	}

	# Get the bit mask for the inclusion to send
	my $inclusion_bitmask = _inclusion_bitmask(
		include_faculty  => $include_faculty,
		include_staff    => $include_staff,
		include_students => $include_students,
	);

	# Get the advanced search parameters
	my ($campus, $college, $department) =
		map { length($_) ? $_ : $args{$_} } # Restore to original if it didn't exist
		map { $self->_advanced_search_parameter_id($_ => $args{$_}) }
		qw(campus college department);

	# Make a SAJAX call for the results HTML
	my $search_results = $self->_sajax->call(
		function  => 'liveSearch',
		arguments => [$name, $inclusion_bitmask, $campus, $college, $department],
	);

	if (ref $search_results ne q{}) {
		# The response was not a plain string
		WWW::USF::Directory::Exception->throw(
			class         => 'UnknownResponse',
			message       => 'The response from the server was not a plain string',
			ajax_response => $search_results,
		);
	}

	# Return the results
	return _parse_search_results_table($search_results);
}

###########################################################################
# PRIVATE METHODS
sub _advanced_search_parameter_id {
	my ($self, $category, $name) = @_;

	if (!defined $name) {
		# Undefined parameter name has a blank value
		return q{};
	}

	# Get the category list
	my $list = $self->_advanced_search_parameters->{$category};

	if (!defined $list) {
		# The category doesn't exist
		WWW::USF::Directory::Exception->throw(
			class          => 'MethodArguments',
			message        => 'The category provided for the advanced search parameter does not exist',
			argument       => 'category',
			argument_value => $category,
			method         => '_advanced_search_parameter_id',
		);
	}

	if (!exists $list->{$name}) {
		# The name doesn't exist
		WWW::USF::Directory::Exception->throw(
			class          => 'MethodArguments',
			message        => sprintf 'Unable to locate the given %s', $category,
			argument       => 'name',
			argument_value => $name,
			method         => '_advanced_search_parameter_id',
		);
	}

	# Return the lookup
	return $list->{$name};
}
sub _advanced_search_parameter_list {
	my ($self, $category) = @_;

	# Get the sorted list of names
	my @names = sort keys %{$self->_advanced_search_parameters->{$category}};

	# Return the list nof keys in the category
	return @names;
}
sub _get_advanced_categories {
	my ($self) = @_;

	# Make a SAJAX call for the results HTML
	my $advanced_menu_html = $self->_sajax->call(
		function  => 'advSearch',
		arguments => [q{}, q{}, q{}],
	);

	if (ref $advanced_menu_html ne q{}) {
		# The response was not a plain string
		WWW::USF::Directory::Exception->throw(
			class         => 'UnknownResponse',
			message       => 'The response from the server was not a plain string',
			ajax_response => $advanced_menu_html,
		);
	}

	# Create a new HTML parser
	my $parser = HTML::HTML5::Parser->new;

	# Parse the HTML into a document
	my $document = $parser->parse_string($advanced_menu_html);

	# Select ID -> nice name map
	my %nice_name_of = (
		camp => 'campus',
		colg => 'college',
		dept => 'department',
	);

	# This will hold the options
	my %categories;

	# Cycle through all the select elements on the page
	SELECT: foreach my $select ($document->getElementsByTagName('select')) {
		if (!$select->hasAttribute('id')) {
			# Go to the next select element, as this is not important
			next SELECT;
		}

		# Get the element's ID
		my $id = $select->getAttribute('id');

		if (exists $nice_name_of{$id}) {
			# Get the select as key value pair
			my %menu = _select_node_to_hash($select);

			# Delete the "Any" entry
			delete $menu{Any};

			# Save this to the categories under the nice name
			$categories{$nice_name_of{$id}} = \%menu;
		}
	}

	# Return a hash reference to the categories
	return \%categories;
}

###########################################################################
# PRIVATE BUILDERS
sub _build_advanced_search_parameters {
	# This will get the advanced categories and save them in the attribute
	return shift->_get_advanced_categories;
}
sub _build_sajax {
	my ($self) = @_;

	# This will return a SAJAX object with default options
	return Net::SAJAX->new(
		url => $self->directory_url->clone,
	);
}

###########################################################################
# PRIVATE FUNCTIONS
sub _clean_node_text {
	my ($node) = @_;

	# Make a copy of the node so modifications don't affect the original node.
	$node = $node->cloneNode(1);

	# Find all the line breaks
	foreach my $br ($node->getElementsByTagName('br')) {
		# Replace the line breaks with a text node with a new line
		$br->replaceNode($node->ownerDocument->createTextNode('{NEWLINE}'));
	}

	# Get the text of the node
	my $text = $node->textContent;

	# Transform all the horizontal space into ASCII spaces
	$text =~ s{\s+}{ }gmsx;

	# Truncate leading and trailing horizontal space
	$text =~ s{^\s+|\s+$}{}gmsx;

	# Change the new-lines back
	$text =~ s{{NEWLINE}}{\n}gmsx; # Because perl < 5.10 cannot do \v and \h

	# Return the text
	return $text;
}
sub _clean_node_text_as_perl_name {
	my ($node) = @_;

	# Get the cleaned text as lowercase
	my $text = lc _clean_node_text($node);

	# Change all space into underscores
	$text =~ s{\p{IsSpace}+}{_}gmsx;

	# Return the text
	return $text;
}
sub _inclusion_bitmask {
	my (%args) = @_;

	# Create a default bitmask where nothing is selected
	my $bitmask = 0;

	if ($args{include_faculty}) {
		# OR in the faculty bit
		$bitmask |= $FACULTY_BIT;
	}

	if ($args{include_staff}) {
		# OR in the staff bit
		$bitmask |= $STAFF_BIT;
	}

	if ($args{include_students}) {
		# OR in the students bit
		$bitmask |= $STUDENTS_BIT;
	}

	# Return the bitmask
	return $bitmask;
}
sub _parse_search_results_table {
	my ($search_results_html) = @_;

	# Create a new HTML parser
	my $parser = HTML::HTML5::Parser->new;

	# Parse the HTML into a document
	my $document = $parser->parse_string($search_results_html);

	# Get the first heading level 3 element
	my $heading = $document->getElementsByTagName('h3')->get_node(1);

	if (defined $heading) {
		# Determine if the response thinks there are too many results
		if ($heading->textContent eq 'Too many results') {
			# Get the first paragraph element in the content
			my $paragraph = $document->getElementsByTagName('p')->get_node(1);

			if (defined $paragraph && $paragraph->textContent =~ m{(\d+) \s+ matches}msx) {
				# Store the max results from the regular expression
				my $max_results = $1;

				# Throw a TooManyResults exception
				WWW::USF::Directory::Exception->throw(
					class       => 'TooManyResults',
					message     => 'The search returned too many results',
					max_results => $max_results,
				);
			}
		}
		# Determine if the response had no results
		elsif ($heading->textContent eq '0 matches found') {
			# Return nothing
			return;
		}
	}

	# Get the first table in the response
	my $search_results_table = $document->getElementsByTagName('table')->shift;

	if (!defined $search_results_table) {
		# Don't know how to handle the response, so throw exception
		WWW::USF::Directory::Exception->throw(
			class         => 'UnknownResponse',
			message       => 'The response from the server did not contain a results table',
			ajax_response => $search_results_html,
		);
	}

	# Get all the table rows
	my $table_rows = $search_results_table->getChildrenByTagName('tbody')->shift
	                                      ->getChildrenByTagName('tr');

	# Get an array of table headers
	my @table_header = map { _clean_node_text_as_perl_name($_) }
		$table_rows->shift->getChildrenByTagName('td');

	# Get the table's content as array of entries
	my @results = map { _table_row_to_entry($_, \@table_header) }
		$table_rows->get_nodelist;

	return @results;
}
sub _select_node_to_hash {
	my ($select_node) = @_;

	return map { ($_->getAttribute('value'), _clean_node_text($_)) }
		grep { $_->hasAttribute('value') }
		$select_node->getChildrenByTagName('option');
}
sub _table_row_to_entry {
	my ($tr_node, $table_header) = @_;

	# Get the row's text content as an array
	my @row_content = map { _clean_node_text($_) }
		$tr_node->getChildrenByTagName('td');

	# Make a hash with the headers as the keys
	my %row = List::MoreUtils::mesh @{$table_header}, @row_content;

	# Delete all keys with blank content
	delete @row{grep { $row{$_} =~ m{\A \p{IsSpace}* \z}msx } keys %row};

	if (exists $row{given_name}) {
		# Split on vertical whitespace
		my @given_names = split m{[\r\n]+}msx, $row{given_name};

		# The first two given names are as follows
		my ($first_name, $middle_name) = @given_names;

		if (defined $first_name) {
			# Set the first name
			$row{first_name} = $first_name;
		}

		if (defined $middle_name) {
			# Set the middle name
			$row{middle_name} = $middle_name;
		}
	}

	if (exists $row{affiliation}) {
		# There could be zero or more affiliations seperated by vertical space
		my @affiliations = split m{\s*[\r\n]+\s*}msx, delete $row{affiliation};

		# Change the affiliation to objects
		foreach my $affiliation (@affiliations) {
			$affiliation = WWW::USF::Directory::Entry::Affiliation->new($affiliation);
		}

		# Store the affiliations
		$row{affiliations} = \@affiliations;
	}

	# Remove vertical whitespace from all non-reference values
	foreach my $value (values %row) {
		if (ref $value eq q{}) {
			# A string, so remove vertical whitespace
			$value =~ s{\s*[\r\n]+\s*}{ }gmsx;
		}
	}

	if (exists $row{campus_phone}) {
		# Remove all non-letters and non-numbers
		$row{campus_phone} =~ s{[^a-z0-9]+}{}gimsx;

		# Remove the U.S. country code if present
		$row{campus_phone} =~ s{\A \+ 1}{}msx;

		# Reformat the phone number
		$row{campus_phone} =~ s{\A (\d{3}) (\d{3}) (\d{4}) \z}{+1 $1 $2 $3}msx;
	}

	if (exists $row{email}) {
		# USF is not too bright at preventing unwanted text from coming through
		if (List::MoreUtils::any { $_ eq $row{email} } qw[null undefined]) {
			# This is an invalid address
			delete $row{email};
		}
	}

	# Make a new entry for the result
	my $entry = WWW::USF::Directory::Entry->new(%row);

	# Return the entry
	return $entry;
}

###########################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WWW::USF::Directory - Access to USF's online directory

=head1 VERSION

This documentation refers to version 0.003001

=head1 SYNOPSIS

  # Make a directory object
  my $directory = WWW::USF::Directory->new();

  # Make all searches return only staff
  $directory->include_faculty(0);
  $directory->include_staff(1);
  $directory->include_students(0);

  # Search for people with the name "Jimmy"
  foreach my $staff ($directory->search(name => 'Jimmy')) {
      # Full Name: email@address
      print $staff->full_name, ': ', $staff->email_address, "\n";
  }

  # This search will also include students
  foreach my $entry ($directory->search(name => 'Barnes',
                                        include_students => 1)) {
      print $entry->full_name, "\n";

  # This search will be in the Tampa campus
  foreach my $entry ($directory->search(name => 'Williams',
                                        campus => 'Tampa')) {
      print $entry->full_name, "\n";
  }

  # Print out the list of colleges
  print join "\n", $directory->college_list, q{};

=head1 DESCRIPTION

This provides a way in which you can interact with the online directory at the
University of South Florida.

=head1 CONSTRUCTOR

This is fully object-oriented, and as such before any method can be used, the
constructor needs to be called to create an object to work with.

=head2 new

This will construct a new object.

=over

=item B<new(%attributes)>

C<%attributes> is a HASH where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item B<new($attributes)>

C<$attributes> is a HASHREF where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=back

=head1 ATTRIBUTES

  # Set an attribute
  $object->attribute_name($new_value);

  # Get an attribute
  my $value = $object->attribute_name;

=head2 directory_url

This is the URL that commands are sent to in order to interact with the online
directory. This can be a L<URI|URI> object or a string. This will always
return a L<URI|URI> object.

=head2 include_faculty

This a Boolean of whether or not to include faculty in the search results. The
default is true.

=head2 include_staff

This a Boolean of whether or not to include staff in the search results. The
default is true.

=head2 include_students

This a Boolean of whether or not to include students in the search results. The
default is false.

=head2 user_agent

This is the user agent that will be used to make the HTTP requests. This
internally maps to the user agent in the L<Net::SAJAX|Net::SAJAX> object
and the default is the default for L<Net::SAJAX|Net::SAJAX>.

=head1 METHODS

=head2 campus_list

This will return a list of strings that are the names of the campuses.

=head2 college_list

This will return a list of strings that are the names of the colleges.

=head2 department_list

This will return a list of strings that are the names of the departments.

=head2 search

This will search the online directory and return an array of
L<WWW::USF::Directory::Entry|WWW::USF::Directory::Entry> objects as the
results of the search. This method takes a HASH as the argument with the
following keys:

=over 4

=item campus

This is the string name of the campus to search in. A list of possible entries
can be retrieved using L</campus_list>. The default to to search all campuses.

=item college

This is the string name of the college to search in. A list of possible entries
can be retrieved using L</college_list>. The default is to search all colleges.

=item department

This is the string name of the department to search in. A list of possible
entries can be retrieved using L</department_list>. The default is to search
all departments.

=item name

B<Required>. The name of the person to search for.

=item include_faculty

This a Boolean of whether or not to include faculty in the search results. The
default is the value of the L</include_faculty> attribute.

=item include_staff

This a Boolean of whether or not to include staff in the search results. The
default is the value of the L</include_staff> attribute.

=item include_students

This a Boolean of whether or not to include students in the search results. The
default is the value of the L</include_students> attribute.

=back

=head1 DIAGNOSTICS

This module will throw
L<WWW::USF::Directory::Exception|WWW::USF::Directory::Exception> objects on
errors as well as any upstream exception objects like
L<Net::SAJAX::Exception|Net::SAJAX::Exception>. This means that all method
return values are guaranteed to be correct. Please read the relevant
exception classes to find out what objects will be thrown.

=over 4

=item * L<WWW::USF::Directory::Exception|WWW::USF::Directory::Exception>
for general exceptions not in other categories and the base class.

=item * L<WWW::USF::Directory::Exception::MethodArguments|WWW::USF::Directory::Exception::MethodArguments>
for exceptions related to the values of arguments given to methods.

=item * L<WWW::USF::Directory::Exception::TooManyResults|WWW::USF::Directory::Exception::TooManyResults>
for searches returning too many results.

=item * L<WWW::USF::Directory::Exception::UnknownRespose|WWW::USF::Directory::Exception::UnknownRespose>
for responses from the server that were not known when the module was written.

=back

=head1 DEPENDENCIES

=over 4

=item * L<Const::Fast|Const::Fast> 0.004

=item * L<HTML::HTML5::Parser|HTML::HTML5::Parser> 0.101

=item * L<List::MoreUtils|List::MoreUtils> 0.07

=item * L<Moose|Moose> 0.89

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.08

=item * L<MooseX::Types::URI|MooseX::Types::URI>

=item * L<Net::SAJAX|Net::SAJAX> 0.102

=item * L<namespace::clean|namespace::clean> 0.04

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
