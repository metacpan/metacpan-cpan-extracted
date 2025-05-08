package Tk::ListBrowser::Data;

=head1 NAME

Tk::ListBrowser::Data - Class for list data.

=cut

use strict;
use warnings;
use vars qw($VERSION $AUTOLOAD);
use Carp;

$VERSION =  0.04;

use Tk::ListBrowser::Item;

=head1 DESCRIPTION

=cut

sub new {
	my ($class, $lb) = @_;

	my $self = {
		LISTBROWSER => $lb,
		POOL => [],
	};
	bless($self, $class);
	return $self
}

sub add {
	my ($self, $name, %options) = @_;
	if ($self->exists($name)) {
		croak "Entry '$name' already exists";
		return
	}

	my $sep = $self->separator;
	if ($sep ne '') {
		if (my $parent = $self->decodeParent($name)) {
			unless ($self->infoExists($parent)) {
				croak "Parent for $name does not exist";
				return
			}
			if (my $a = $options{'-after'}) {
				my $p = $self->infoParent($a);
				if ($p ne $parent) {
					croak "Invalid '-after' option, $name and $a do not share the same parent";
					return
				}
			} elsif (my $b = $options{'-before'}) {
				my $p = $self->infoParent($b);
				if ($p ne $parent) {
					croak "Invalid '-before' option, $name and $b do not share the same parent";
					return
				}
			} else {
				my @c = $self->infoChildren($parent);
				if (@c) {
					my $last = $c[@c - 1];
					my @sc = $self->infoChildren($last);
					if (@sc) {
						$options{'-after'} = pop @sc
					} else {
						$options{'-after'} = pop @c
					}
				} else {
					$options{'-after'} = $parent
				}
			}
		}
	}

	my $after = delete $options{'-after'};
	my $before = delete $options{'-before'};
	my $item = new Tk::ListBrowser::Item(
		%options,
		-listbrowser => $self->listbrowser,
		-name => $name,
	);
	my $pool = $self->pool;
	if (defined $after) {
		my $index = $self->index($after);
		splice(@$pool, $index + 1, 0, $item) if defined $index;
		croak "Entry for -after '$after' not found" unless defined $index;
	} elsif (defined $before) {
		my $index = $self->index($before);
		splice(@$pool, $index, 0, $item) if defined $index;
		croak "Entry for -before '$before' not found" unless defined $index;
	} else {
		push @$pool, $item
	}
	return $item
}

sub clear {
	my $self = shift;
	my $pool = $self->pool;
	grep { $_->clear } @$pool;
}

sub decodeParent {
	my ($self, $name) = @_;
	my $sep = $self->separator;
	$sep = quotemeta($sep);
	my $parent;
	if ($name =~ /$sep/) {
		$name =~ /^(.*)$sep/;
		$parent = $1 if defined $1;
	}
	return $parent
}

sub delete {
	my ($self, $name) = @_;
	my $pool = $self->pool;
	my $index = $self->index($name);
	if (defined $index) {
		my ($del) = splice(@$pool, $index, 1);
		$del->clear;
		return
	}
	croak "Entry '$name' not found"
}

sub deleteAll {
	my $self = shift;
	my $pool = $self->pool;
	grep { $self->delete($_->name) } @$pool;
}

sub exists {
	my ($self, $name) = @_;
	my $a = $self->get($name);
	return defined $a;
}

sub first {
	my $self = shift;
	return $self->pool->[0]
}

sub get {
	my ($self, $name) = @_;
	my $pool = $self->pool;
	my @hit = grep { $_->name eq $name } @$pool;
	return $hit[0]
}

sub getAll {
	my ($self, $name) = @_;
	my $pool = $self->pool;
	return @$pool
}

sub getColumn {
	my ($self, $col) = @_;
	my $pool = $self->pool;
	my @hits = grep { (defined $_->column) and ($_->column eq $col) } @$pool;
	return @hits
}

sub getIndex {
	my ($self, $index) = @_;
	return undef unless defined $index;
	my $pool = $self->pool;
	if (($index < 0) or ($index > @$pool - 1)) {
		croak "Index '$index' out of range";
		return undef ;
	}
	return $pool->[$index];
}

sub getRow {
	my ($self, $row) = @_;
	my $pool = $self->pool;
	my @hits = grep { (defined $_->row ) and ($_->row eq $row) } @$pool;
	return @hits
}

sub hide {
	my ($self, $name) = @_;
	my $a = $self->get($name);
	$a->hidden(1) if defined $a
}

sub index {
	my ($self, $name) = @_;
	my $pool = $self->pool;
	my ($index) = grep { $pool->[$_]->name eq $name } 0 .. @$pool - 1;
	return $index
}

sub infoChildren {
	my ($self, $name) = @_;
	my $sep = quotemeta($self->listbrowser->cget('-separator'));
	my $test = quotemeta($name) . $sep;
#	print "testing for $test\n";
	my $pool = $self->pool;
	my @r;
	for (@$pool) {
		my $item = $_;
		my $nm = $item->name;
		if ($nm =~ /^$test(.*)/) {
			push @r, $item->name unless $1 =~ /$sep/;
		}
	}
	return  @r;
}

sub indexColumnRow {
	my ($self, $column, $row) = @_;
	my $pool = $self->pool;
	my ($index) = grep {
		(defined $pool->[$_]->column) and
		(defined $pool->[$_]->row) and
		($pool->[$_]->column eq $column) and
		($pool->[$_]->row eq $row)
	} 0 .. @$pool - 1;
	return $index
}

sub indexLast {
	my $self = shift;
	my $pool = $self->pool;
	my $last = @$pool - 1;
	return $last
}

sub infoData {
	my ($self, $name) = @_;
	my $a = $self->get($name);
	return $a->data if defined $a;
	croak "Entry '$name' not found";
	return undef
}

sub infoExists {
	my ($self, $name) = @_;
	my $a = $self->get($name);
	return defined $a;
}

sub infoFirst {
	my $self = shift;
	my $pool = $self->pool;
	return undef unless @$pool;
	return $pool->[0]->name
}

sub infoFirstVisible {
	my $self = shift;
	my $pool = $self->pool;
	for (@$pool) {
		return $_->name unless $_->hidden
	}
}

sub infoHidden {
	my ($self, $name) = @_;
	my $a = $self->get($name);
	if (defined $a) {
		my $flag = $a->hidden;
		$flag = '' if $flag eq 0;
		return $flag
	}
	croak "Entry '$name' not found";
	return undef
}

sub infoLast {
	my $self = shift;
	my $pool = $self->pool;
	return undef unless @$pool;
	return $pool->[@$pool - 1]->name
}

sub infoLastVisible {
	my $self = shift;
	my $pool = $self->pool;
	for (reverse @$pool) {
		return $_->name unless $_->hidden
	}
}

sub infoList {
	my ($self, $flag) = shift;
	my $pool = $self->pool;
	my @list;
	for (@$pool) {
		my $name = $_->name;
		push @list, $name;
		if ($flag) {
			my @c = $self->infoChildren($name);
			push @list,  @c
		}
	}
	return @list
}

sub infoNext {
	my ($self, $name) = @_;
	my $pool = $self->pool;
	my $a = $self->index($name);
	unless (defined $a) {
		croak "Entry '$name' not found";
		return
	}
	return undef if $a eq @$pool - 1;
	return $pool->[$a + 1]->name;
}

sub infoNextVisible {
	my ($self, $name) = @_;
	my $pool = $self->pool;
	my $a = $self->index($name);
	unless (defined $a) {
		croak "Entry '$name' not found";
		return
	}
	for ($a .. @$pool - 1) {
		return $pool->[$_]->name unless $pool->[$_]->hidden
	}
}

sub infoParent {
	my ($self, $name) = @_;
	unless ($self->infoExists($name)) {
		croak "Entry '$name' does not exist";
		return
	}
	my $parent = $self->decodeParent($name);
	return undef unless defined $parent;
	return $parent if $self->infoExists($parent);
	return undef
}

sub infoPrev {
	my ($self, $name) = @_;
	my $pool = $self->pool;
	my $a = $self->index($name);
	unless (defined $a) {
		croak "Entry '$name' not found";
		return
	}
	return undef if $a eq 0;
	return $pool->[$a - 1]->name;
}

sub infoPrevVisible {
	my ($self, $name) = @_;
	my $pool = $self->pool;
	my $a = $self->index($name);
	unless (defined $a) {
		croak "Entry '$name' not found";
		return
	}
	for (reverse 0 .. $a) {
		return $pool->[$_]->name unless $pool->[$_]->hidden
	}
}

sub infoRoot {
	my $self = shift;
	my $pool = $self->pool;
	my $sep = $self->listbrowser->cget('-separator');
	$sep = quotemeta($sep);
	my @root;
	for (@$pool) {
		my $name = $_->name;
		push @root, $name unless $name =~ /$sep/;
	}
#	print "root: $sep\n";
#	for (@root) {
#		print $_, "\n"
#	}
	return @root
}

sub initem {
	my ($self, $x, $y) = @_;
	my $pool = $self->pool;
	for (@$pool) {
		if ($_->inregion($x, $y)) {
			return $_;
		}

	}
	return undef
}
sub inregion {
}

sub itemCget {
	my ($self, $name, $option) = @_;
	my $i = $self->get($name);
	unless (defined $i) {
		croak "Entry '$name' not found";
		return
	}
	my $val = $i->cget($option);
	return $val
}

sub itemConfigure {
	my ($self, $name, %options) = @_;
	my $i = $self->get($name);
	unless (defined $i) {
		croak "Entry '$name' not found";
		return
	}
	for (keys %options) {
		$i->configure($_, $options{$_})
	}
}

sub lastColumnInRow {
	my ($self, $row) = @_;
	my $pool = $self->data->pool;
	my @row = $self->getRow($row);
	return $row[@row - 1]->column;
}

sub lastRowInColumn {
	my ($self, $column) = @_;
	my @column = $self->getColumn($column);
	return $column[@column - 1]->row;
}

sub listbrowser { return $_[0]->{LISTBROWSER} }

sub opened {
	my $self = shift;
	$self->{OPENED} = shift if @_;
	return $self->{OPENED}
}

sub pool {
	my $self = shift;
	$self->{POOL} = shift if @_;
	return $self->{POOL}
}

sub selectAll {
	my $self = shift;
	return if $self->listbrowser->cget('-selectmode') eq 'single';
	my $pool = $self->pool;
	grep { $_->select } @$pool;
}

sub selectionClear {
	my $self = shift;
	my $pool = $self->pool;
	grep { $_->select(0) } @$pool;
}

sub selectionFlip {
	my ($self, $begin, $end) = @_;
	($begin, $end) = $self->selectionIndex($begin, $end);
	my $pool = $self->pool;
	for ($begin .. $end) {
		my $i = $pool->[$_];
		if ($i->selected) {
			$self->selectionClear if $self->listbrowser->cget('-selectmode') eq 'single';
			$i->select(0);
		} else {
			$self->selectionClear if $self->listbrowser->cget('-selectmode') eq 'single';
			$i->select;
		}
	}
}

sub selectionGet {
	my $self = shift;
	my @list;
	my $pool = $self->pool;
	for (@$pool) { push @list, $_->name  if $_->selected }
	return @list;
}

sub selectionIndex {
	my ($self, $begin, $end) = @_;
	$end = $begin unless defined $end;
	$begin = $self->index($begin);
	$end = $self->index($end);
	if ($begin > $end) {
		my $t = $begin;
		$begin = $end;
		$end = $t;
	}
	return ($begin, $end)
}

sub selectionSet {
	my ($self, $begin, $end) = @_;
	my @pool = $self->getAll;
	if ($self->listbrowser->cget('-selectmode') eq 'single') {
		$self->selectionSingle($begin);
	} else {
		($begin, $end) = $self->selectionIndex($begin, $end);
		for ($begin .. $end) {
			my $i = $pool[$_];
			$i->select(1) unless $i->hidden;
		}
	}
}

sub selectionSingle {
	my ($self, $name) = @_;
	$self->selectionClear;
	$self->selectionSet($name);
}

sub selectionUnSet {
	my ($self, $begin, $end) = @_;
	$end = $begin unless defined $end;
	($begin, $end) = $self->selectionIndex($begin, $end);
	my $pool = $self->pool;
	for ($begin .. $end) {
		my $i = $pool->[$_];
		$i->select(0) unless $i->hidden;
	}
}

sub separator {	return $_[0]->listbrowser->cget('-separator') }

sub show {
	my ($self, $name) = @_;
	my $a = $self->get($name);
	$a->hidden(0) if defined $a
}


=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

If you find any bugs, please report them here: L<https://github.com/haje61/Tk-ListBrowser/issues>.

=cut

1;