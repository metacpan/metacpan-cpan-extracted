package XML::miniXQL::Parser;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);
$VERSION = '0.01';

1;
__END__
# This class allows comparison of current paths

=pod

OK, here's some things we need to support:

/bar/foo (contents of foo element beneeth the bar root element)

author (contents of author element after previous query - if prev query was relative, look at same level,
otherwise look at child of previous)

/myroot (any text at start of root element)

//author (contents of author elements anywhere within XML)

book[/bookstore/author/@genre != @genre] (a book relative query, where the author's genre
attribute is not the same as the book's genre. The /bookstore/authors MUST be in the same hierarchy
as the book element. i.e. the following XML will not result in a hit:

<bookstore>
	<author genre="horror">
		<name>Stephen King</name>
	</author>
	<book genre="comedy">
		<name>Blott on the Landscape</name>
	</book>
</bookstore>

Whereas the following would:

<bookstore>
	<author genre="horror">
		<name>Stephen King</name>
		<book genre="sci-fi">
			<name>The Running Man</name>
		</book>
	</author>
</bookstore>

This is simply a restriction of this module - not of XQL. Normally XQL would be fine with that
query. Sorry)

book/@genre (contents of genre attribute on the book element)

/bookstore//title (contents of title element that is a descendant of bookstore)

/bookstore/*/title (contents of title element that is a grandchild (and no deeper) of bookstore)

/bookstore//book/excerpt//emph (work it out <g>)

.//title (relative query - dot needed because we have the preceeding //)

author/* (all author's children - returns element names?)

*[@speciality] (contents of all elements with a speciality attribute)

==========

Specific things we don't support:

author[degree and publication] (contents of author elements that have a degree and publication child)

ne and eq for != and = respectively. Why bother.

Content comparisons (only attribute comparisons supported)


=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self;
	$self->{_path} = $_[0];
	$self->{_fullpath} = [];
	bless ($self, $class);          # reconsecrate
	if ($self->{_path}) {
		$self->buildSelf($_[1] || new $class);
	}
	return $self;
}

sub buildSelf {
	my $self = shift;
	my $prev = shift;

	if ($self->{_path} =~ s/\*$//) {
		$self->{_repeat} = 1;
	}

#	warn "Building from ", $self->{_path}, "\n";


	my @parts = split('/', $self->{_path});
	my @fullpath;
	$self->{Relative} = 0;

	if ($self->{_path} !~ /^\//) {
		# It's a relative path

		$self->{_relative} = 1;
		@fullpath = @{$prev->{_fullpath}};

		if ($prev->isRelative) {
			# prev was a relative path so remove top item
			pop @fullpath;
		}
		foreach ( @parts ) {
			if ($_ eq "..") {
				pop @fullpath;
			}
			else {
				push @fullpath, $_;
			}
		}
	}
	else {
		# remove crap from beginning (empty because of preceding "/")
		shift @parts;
		@fullpath = @parts;
	}

	if ($fullpath[$#fullpath] =~ /^\@(\w+)$/) {
		pop @fullpath;
		pop @parts;
		$self->{_attrib} = $1;
	}

	$self->{Parts} = \@parts;
	$self->{_fullpath} = \@fullpath;

#	warn "Built: ", $self->FullPath, "\n";

}

sub rebuildSelf {
	my $self = shift;
	$self->buildSelf(new XML::miniXQL::Parser);
}

sub isRelative {
	$_[0]->{_relative};
}

sub isRepeat {
	$_[0]->{_repeat};
}

sub isChildPath {
	my $self = shift;
	my $compare = shift;

	# Now compare each level of the tree, and throw away attributes.
	my @a = @{$self->{_fullpath}};
	my @b = @{$compare->{_fullpath}};

	if (@a >= @b) {
		return 0;
	}
	foreach ($#a..0) {
		$a[$_] =~ s/\[.*\]//;
		$b[$_] =~ s/\[.*\]//;
		return 0 if ($a[$_] ne $b[$_]);
	}
	return 1;
}

sub Attrib {
	$_[0]->{_attrib};
}

sub isEqual {
	my $self = shift;
	my $compare = shift;

	my @a = @{$self->{_fullpath}};
	my @b = @{$compare->{_fullpath}};

#	warn "Comparing: ", $self->FullPath, "\nTo      : ", $compare->FullPath,
#	"\n";
	if (scalar @a != scalar @b) {
		return 0;
	}
	foreach (0..$#a) {
#		$a[$_] =~ s/\[.*\]//;
#		$b[$_] =~ s/\[.*\]//;
		if (!_comparePart($a[$_], $b[$_])) {
			return 0;
		}
	}
#	warn "*** FOUND ***\n";
	return 1;
}

sub Append {
	my $self = shift;
	my $element = shift;
	my %attribs = @_;
	if (%attribs) {
		$element .= "[";

		$element .= join " and ",
					(map "\@$_=\"$attribs{$_}\"", (keys %attribs));
		$element .= "]";
	}
	push @{$self->{_fullpath}}, $element;
	push @{$self->{Parts}}, $element;
	$self->{_path} .= "/". $element;
}

sub Pop {
	my $self = shift;
	pop @{$self->{_fullpath}};
	$self->{_path} =~ s/^(.*)\/.*?$/$1/;
	pop @{$self->{Parts}};
}

sub Path {
	$_[0]->{_path};
}

sub FullPath {
	my $self = shift;
	my $path = "/" . (join "/", @{$self->{_fullpath}});
	$path .= ($self->Attrib ? "/\@" . $self->Attrib : '');
	$path;
}

sub _comparePart {
	my ($a, $b) = @_;

	my $a_elem;
	my $a_attribs = '';
	my $a_attribs_ref;

	if ($a =~ /(.*)\[(.*)\]/) {
		$a_elem = $1;
		$a_attribs = $2;
	}
	else {
		$a_elem = $a;
	}

	my $b_elem;
	my $b_attribs = '';
	my $b_attribs_ref;

	if ($b =~ /(.*)\[(.*)\]/) {
		$b_elem = $1;
		$b_attribs = $2;
	}
	else {
		$b_elem = $b;
	}

	return 0 if !defined $b_elem;
	if ($a_elem ne $b_elem) {
		return 0;
	}

	if (!$b_attribs && !$a_attribs) {
		return 1;
	}

	# Element is same - now split attribs
	foreach (split /\s+and\s+/, $a_attribs) {
		my ($key, $value) = split /\s*=\s*/;
		$a_attribs_ref->{$key} = $value;
	}

	foreach (split /\s+and\s+/, $b_attribs) {
		my ($key, $value) = split /\s*=\s*/;
		$b_attribs_ref->{$key} = $value;
	}

	foreach (keys (%{$a_attribs_ref})) {
		if (!defined($b_attribs_ref->{$_})) {
			return 0;
		}
		if ($a_attribs_ref->{$_} ne $b_attribs_ref->{$_}) {
			return 0;
		}
	}

	return 1;

}

1;
