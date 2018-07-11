package Text::Locus;

use strict;
use warnings;
use parent 'Exporter';

use Carp;
use Clone;
use Scalar::Util qw(blessed);

our $VERSION = '1.01';

=head1 NAME

Text::Locus - text file locations

=head1 SYNOPSIS

use Text::Locus;

$locus = new Text::Locus;

$locus = new Text::Locus($file, $line);

$locus->add($file, $line);

$s = $locus->format;

$locus->fixup_names('old' => 'new');

$locus->fixup_lines(%hash);

print "$locus: text\n";

$res = $locus1 + $locus2;

=head1 DESCRIPTION

B<Text::Locus> provides a class for representing locations in text
files. A simple location consists of file name and line number.
e.g. C<file:10>. In its more complex form, the location represents a
text fragment spanning several lines, such as C<file:10-45>. Such a
fragment need not be contiguous, a valid location can also look like
this: C<file:10-35,40-48>. Moreover, it can span multiple files as
well: C<foo:10-35,40-48;bar:15,18>.

=head1 CONSTRUCTOR

    $locus = new Text::Locus($file, $line, ...);

Creates a new locus object. Arguments are optional. If given, they
indicate the source file name and line numbers this locus is to represent.    
    
=cut

sub new {
    my $class = shift;
    
    my $self = bless { _table => {}, _order => 0 }, $class;

    croak "line numbers not given" if @_ == 1;
    $self->add(@_) if @_ > 1;
    
    return $self;
}

=head1 METHODS

=head2 clone

    $locus->clone

Creates a new B<Text::Locus> which is exact copy of B<$locus>.
    
=cut

sub clone {
    my $self = shift;
    return Clone::clone($self);
}

=head2 add

    $locus->add($file, $line, [$line1 ...]);

Adds new location to the locus. Use this for statements spanning several
lines and/or files.    

Returns B<$locus>.
    
=cut

sub add {
    my ($self, $file) = (shift, shift);
    unless (exists($self->{_table}{$file})) {
	$self->{_table}{$file}{_order} = $self->{_order}++;
	$self->{_table}{$file}{_lines} = [];
    }
    push @{$self->{_table}{$file}{_lines}}, @_;
    delete $self->{_string};
    return $self;
}

=head2 union

    $locus->union($locus2);

Converts B<$locus> to a union of B<$locus> and B<$locus2>.

=cut

sub union {
    my ($self, $other) = @_;
    croak "not the same class"
	unless blessed($other) && $other->isa(__PACKAGE__);
    while (my ($file, $tab) = each %{$other->{_table}}) {
	$self->add($file, @{$tab->{_lines}});
    }
    return $self;
}	    

=head2 format

    $s = $locus->format($msg);

Returns string representation of the locus.  Argument, if supplied,
will be prepended to the formatted locus with a C<: > in between. If multiple 
arguments are supplied, their string representations will be concatenated,
separated by horizontal space characters. This is useful for formatting error
messages.

If the locus contains multiple file locations, B<format> tries to compact
them by representing contiguous line ranges as B<I<X>-I<Y>> and outputting
each file name once. Line ranges are separated by commas. File locations
are separated by semicolons. E.g.:

    $locus = new Text::Locus("foo", 1);
    $locus->add("foo", 2);
    $locus->add("foo", 3);
    $locus->add("foo", 5);
    $locus->add("bar", 2);
    $locus->add("bar", 7);
    print $locus->format("here it goes");

will produce the following:

    foo:1-3,5;bar:2,7: here it goes

=cut

sub format {
    my $self = shift;
    unless (exists($self->{_string})) {
	$self->{_string} = '';
	foreach my $file (sort {
	                    $self->{_table}{$a}{_order} <=> $self->{_table}{$b}{_order}
			  }
			  keys %{$self->{_table}}) {
	    $self->{_string} .= ';' if $self->{_string};
	    $self->{_string} .= "$file";
	    if (my @lines = @{$self->{_table}{$file}{_lines}}) {
		$self->{_string} .= ':';
		my $beg = shift @lines;
		my $end = $beg;
		my @ranges;
		foreach my $line (@lines) {
		    if ($line == $end + 1) {
			$end = $line;
		    } else {
			if ($end > $beg) {
			    push @ranges, "$beg-$end";
			} else {
			    push @ranges, $beg;
			}
			$beg = $end = $line;
		    }
		}
		
		if ($end > $beg) {
		    push @ranges, "$beg-$end";
		} else {
		    push @ranges, $beg;
		}
		$self->{_string} .= join(',', @ranges);
	    }
	}
    }
    if (@_) {
	if ($self->{_string} ne '') {
	    return "$self->{_string}: " . join(' ', @_);
	} else {
	    return join(' ', @_);
	}
    }
    return $self->{_string};
}

=head1 OVERLOADED OPERATIONS

When used in a string, the locus object formats itself. E.g. to print
a diagnostic message one can write:

    print "$locus: some text\n";

In fact, this method is preferred over calling B<$locus-E<gt>format>.

Two objects can be added:

    $loc1 + $loc2

This will produce a new B<Text::Locus> containing locations from both I<$loc1>
and I<$loc2>.

Moreover, a term can also be a string in the form C<I<file>:I<line>>:

    $loc + "file:10"

or

    "file:10" + $loc    
    
=cut

use overload
    '""' => sub { shift->format() },
    '+'  => sub {
	my ($self, $other, $swap) = @_;
	if (blessed $other) {
	    return $self->clone->union($other);
        } elsif (!ref($other) && $other =~ m/^(.+):(\d+)$/) {
	    if ($swap) {
		return new Text::Locus($1, $2) + $self;
	    } else {
		return $self->clone->add($1, $2);
	    }
	} else {
	    croak "bad argument type in locus addition";
	}
    };

=head1 FIXUPS

=head2 fixup_names

    $locus->fixup_names('foo' => 'bar', 'baz' => 'quux');

Replaces file names in B<$locus> according to the arguments. In the example
above, C<foo> becomes C<bar>, and C<baz> becomes C<quux>.

=cut

sub fixup_names {
    my $self = shift;
    local %_ = @_;
    while (my ($oldname, $newname) = each %_) {
	next unless exists $self->{_table}{$oldname};
	croak "target name already exist" if exists $self->{_table}{$newname};
	$self->{_table}{$newname} = delete $self->{_table}{$oldname};
    }
    delete $self->{_string};
}

=head2 fixup_lines

    $locus->fixup_lines('foo' => 1, 'baz' => -2);

Offsets line numbers for each named file by the given number of lines. E.g.:

     $locus = new Text::Locus("foo", 1);
     $locus->add("foo", 2);
     $locus->add("foo", 3);
     $locus->add("bar", 3);
     $locus->fixup_lines(foo => 1. bar => -1);
     print $locus->format;

will produce

     foo:2-4,bar:2

Given a single argument, the operation affects all locations. E.g.,
adding the following to the example above:

     $locus->fixup_lines(10);
     print $locus->format;

will produce

     foo:22-24;bar:22
    
=cut

sub fixup_lines {
    my $self = shift;
    return unless @_;
    if ($#_ == 0) {
	my $offset = shift;
	while (my ($file, $ref) = each %{$self->{_table}}) {
	    $ref->{_lines} = [map { $_ + $offset } @{$ref->{_lines}}];
	}
    } elsif ($#_ % 2) {
	local %_ = @_;
	while (my ($file, $offset) = each %_) {
	    if (exists($self->{_table}{$file})) {
		$self->{_table}{$file}{_lines} =
		    [map { $_ + $offset }
		         @{$self->{_table}{$file}{_lines}}];
	    }
	}
    } else {
	croak "bad number of arguments";
    }
    delete $self->{_string};
}

=head1 AUTHOR

Sergey Poznyakoff, E<lt>gray@gnu.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Sergey Poznyakoff

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

It is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this library. If not, see <http://www.gnu.org/licenses/>.    
    
=cut

1;
