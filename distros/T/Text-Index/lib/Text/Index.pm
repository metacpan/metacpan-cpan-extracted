package Text::Index;

use 5.006;
use strict;
use warnings;
use Carp qw/croak/;
use Params::Util qw/_INSTANCE _ARRAY/;

our $VERSION = '0.01';

=head1 NAME

Text::Index - Create indices of a set of pages using a set of keywords

=head1 SYNOPSIS

  use Text::Index;
  my $index = Text::Index->new;
  
  $index->add_page($content);
  $index->add_pages(@strings);
  my @pages = $index->pages;
  
  # Add keyword with equivalent derivates
  $index->add_keyword('Hamilton function', 'Hamiltonian');
  $index->add_keywords([$keyword, @derivates], ...);
  my @keywords = $i->keywords;
  # ->keywords returns an array reference for each keyword
  # (see ->add_keywords syntax)
  
  my $index = $i->generate_index;
  
  # Or for a single keyword:
  my @page_list  = $i->find_keyword($keyword);
  my @page_list2 = $i->find_keyword($keyword, @derivates);

=head1 DESCRIPTION

This (simple) module searches for keywords in a set of pages and creates
an index.

=head2 EXPORT

None.

=head2 METHODS

This is a list of public methods.

=over 2

=item new

Returns a new Text::Index object. When called on an
existing object, C<new> clones that object (deeply).

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto)||$proto;
	
	my $self = {
		keywords => {},
		pages => [],
	};
	
	if (_INSTANCE($proto, __PACKAGE__)) {
		@{$self->{pages}} = $proto->pages;
		foreach ($proto->keywords) {
			my $clone =  {
				key => $_->[0],
				deriv => [ @{ $_->[1] } ],
			};
			$self->{keywords}{$_->[0]} = $clone;
		}
	}

	return bless $self => $class;
}

=item add_page

Adds a page to the index object. The page is expected to be
a string of text passed in as first argument.

Returns the Text::Index object for convenience of
method chaining.

=cut

sub add_page {
	my $self = shift;
	my $page = shift;
	push @{$self->{pages}}, $page;
	return $self;
}

=item add_pages

Adds a number of pages to the index object.

All arguments are treated as pages. See C<add_page>.

=cut

sub add_pages {
	my $self = shift;
	push @{$self->{pages}}, @_;
	return $self;
}

=item pages

Returns all registered pages as a list.

=cut

sub pages {
	my $self = shift;
	return @{$self->{pages}};
}

=item add_keyword

Adds a new keyword to the index. First argument must be the
keyword to add. Following the keyword may be any number of
alternative names / string which should be treated to be equal
to the keyword.

Returns the Text::Index object for convenience.

=cut

sub add_keyword {
	my $self = shift;
	my $keyword = shift;
	my @deriv = @_;

	croak("add_keyword requires a keyword as first argument.")
	  if not defined $keyword;
	
	$self->{keywords}{$keyword} = {
		key => $keyword, deriv => \@deriv,
	};
	
	return $self;
}

=item add_keywords

Works like C<add_keyword> except that its arguments must be
a number of array references each referencing an array containing
a keyword and its associated derivates.

Returns the Text::Index object for convenience.

=cut

sub add_keywords {
	my $self = shift;
	croak("add_keywords takes only array references as arguments")
	  if grep {!_ARRAY($_)} @_;
	$self->add_keyword(@$_) for @_;
	return $self;
}


=item keywords

Returns all registered keywords as a list of array references.
Each of those references an array containing the keyword followed
by any possible derivates.

=cut

sub keywords {
	my $self = shift;
	return( map {[$_->{key}, @{$_->{deriv}}]} values(%{$self->{keywords}}) );
}


sub _search {
	my $self = shift;
	my $key = shift;
	my $pages = $self->{pages};

	my @regexes = map {
		my @w = map {quotemeta($_)} split /\s+/, $_;
		my $str = join '\s+', @w;
		qr/$str/i
	} @$key;
	
	my @onpage;
	
	foreach my $page_no (1..@$pages) {
		my $page = $pages->[$page_no-1];
		study($page) if @regexes > 1;
		foreach my $regex (@regexes) {
			push(@onpage, $page_no), last if $page =~ $regex;
		}
	}

	return @onpage;
}

=item generate_index

Generates an index from the registered keywords and pages.
It returns an index of the form:

  {
    'keyword' => [ @pages_containing_keyword ],
    ...
  }

The search for the keywords is performed case and whitespace insensitively.

=cut

sub generate_index {
	my $self = shift;

	my $index = {};
	foreach my $key (values %{$self->{keywords}}) {
		$index->{$key->{key}} = [
			$self->_search( [ $key->{key}, @{$key->{deriv}} ] )
		];
	}
	return $index;
}



=item find_keyword

This method works like C<generate_index> only that it searches for
just one keyword which is provided as argument in the style of
C<add_keyword>. It ignores any registered keywords and searches just
for the one given as argument.

Returns a list of page number on which the keyword was found. The
list will be the empty list if the keyword wasn't found at all.

=cut

sub find_keyword {
	my $self = shift;
	my $key = shift;
	my @deriv = @_;
	
	croak("keyword requires a keyword as first argument.")
	  if not defined $key;
	
	push @deriv, $key;

	return $self->_search(\@deriv);
}

1;

__END__

=back

=head1 SEE ALSO


=head1 AUTHOR

Steffen Müller, E<lt>modules at steffen-mueller dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
