package Text::Table::Read::RelationOn::Tiny;

use 5.010_001;
use strict;
use warnings;
use autodie;

use Carp;

# The following must be on the same line to ensure that $VERSION is read
# correctly by PAUSE and installer tools. See docu of 'version'.
use version 0.77; our $VERSION = version->declare("v2.2.4");


sub new {
  my $class = shift;
  $class = ref($class) if ref($class);
  croak("Odd number of arguments") if @_ % 2;
  my %args = @_;
  my $inc      = delete $args{inc}   // "X";
  my $noinc    = delete $args{noinc} // "";
  my $set      = delete $args{set};
  my $eqs      = delete $args{eqs};
  my $ext      = delete $args{ext};
  my $elem_ids = delete $args{elem_ids};
  croak(join(", ", sort(keys(%args))) . ": unexpected argument") if %args;
  croak("inc: must be a scalar")               if ref($inc);
  croak("noinc: must be a scalar")             if ref($noinc);
  s/^\s+// for ($inc, $noinc);
  s/\s+$// for ($inc, $noinc);
  croak("inc and noinc must be different")     if $inc eq $noinc;
  croak("'|' is not allowed for inc or noinc") if $inc eq '|' || $noinc eq '|';
  my $self = {inc    => $inc,
              noinc  => $noinc,
             };
  if (defined($set)) {
    my %seen;
    croak("set: must be an array reference") if ref($set) ne 'ARRAY';
    my $cnt = 1;
    foreach my $e (@$set) {
      if (ref($e)) {
        croak("set: entry $cnt: invalid") if ref($e) ne 'ARRAY';
        croak("set: entry $cnt: array not allowed if eqs is specified") if $eqs;
        croak("set: entry $cnt: array entry must not be empty") if !@{$e};
        foreach my $sub_e (@$e) {
          croak("set: entry $cnt: subarray contains invalid entry")
            if ref($sub_e) || !defined($sub_e);
          croak("set: '$sub_e': duplicate element") if exists($seen{$sub_e});
          $seen{$sub_e} = undef;
        }
      } else {
        croak("set: entry $cnt: invalid") if !defined($e);
        croak("set: '$e': duplicate element") if exists($seen{$e});
        $seen{$e} = undef;
      }
      ++$cnt;
    }
    $self->{prespec} = 1;
  } else {
    croak("eqs: not allowed without argument 'set'") if defined($eqs);
    $self->{prespec} = "";
  }
  if (defined($elem_ids)) {
    croak("elem_ids: not allowed without arguments 'set' and 'ext'") if !(defined($ext) &&
                                                                            defined($set));
    croak("elem_ids: must be a hash ref") if ref($elem_ids) ne 'HASH';
  }
  my $elems;
  my $tabElems;                # elems to be used in table --> indes in @elems
  my $eqIds;
  if ($ext) {
    if ($set) {
      foreach my $e (@$set) {
        croak("set: no subarray allowed if 'ext' is specified") if ref($e);
      }
      if ($elem_ids) {
        croak("elem_ids: wrong number of entries") if keys(%$elem_ids) != @$set;
        foreach my $e (@$set) {
          my $e_id = $elem_ids->{$e};
          croak("elem_ids: '$e': missing value") if !defined($e_id);
          croak("elem_ids: '$e': entry has wrong value") if ($e_id !~ /^\d$/         ||
                                                               !defined($set->[$e_id]) ||
                                                               $set->[$e_id] ne $e);
        }
      } else {
        my $idx = 0;
        $elem_ids = {map {$_ => $idx++} @$set};
      }
      $elems = $set;
    } else {
      croak("ext: not allowed without argument 'set'")
    }
    %$tabElems = %$elem_ids;
  } elsif (ref($set)) {
    my @elems;                         # elems
    my %ids;                           # indices in basic elems
    my @eqs_tmp;

    foreach my $entry (@$set) {
      if (ref($entry)) {
        push(@elems, $entry->[0]);
        $ids{$entry->[0]} = $#elems;
        for (my $j = 1; $j < @$entry; ++$j) {
          my $ent_j = $entry->[$j];
          push(@elems, $ent_j);
          $ids{$ent_j} = $#elems;
        }
        push(@eqs_tmp, $entry) if @$entry > 1;
      } else {
        push(@elems, $entry);
        $ids{$entry} = $#elems;
      }
    }
    croak("Internal error") if (defined($eqs) && @eqs_tmp); # Should never happen.
    $eqs = \@eqs_tmp if @eqs_tmp;
    ($elems, $elem_ids, $tabElems, $eqIds) = (\@elems, \%ids, {%ids}, {});
  }
  if (defined($eqs)) {
    croak("eqs: must be an array ref") if ref($eqs) ne 'ARRAY';
    my %eqIds;                         # idx => array of equivalent idxes
    my %seen;
    foreach my $eqArray (@{$eqs}) {
      croak("eqs: each entry must be an array ref") if ref($eqArray) ne 'ARRAY';
      next if !@{$eqArray};
      foreach my $entry (@{$eqArray}) {
        croak("eqs: subentry contains a non-scalar") if ref($entry);
        croak("eqs: subentry undefined")             if !defined($entry);
        croak("eqs: '$entry': unknown element")      if !exists($elem_ids->{$entry});
        croak("eqs: '$entry': duplicate element")    if exists($seen{$entry});
        $seen{$entry} = undef;
      }
      next if @{$eqArray} == 1;
      my @tmp = @{$eqArray};
      my @eqArray;
      $eqIds{$tabElems->{shift(@tmp)}} = \@eqArray;
      foreach my $e (@tmp) {
        push(@eqArray, delete $tabElems->{$e});
      }
    }
    $eqIds = \%eqIds;
  }
  @{$self}{qw(elems elem_ids tab_elems eq_ids)} = ($elems, $elem_ids, $tabElems, $eqIds);
  return bless($self, $class);
}


#
# $self->$_reset()  - set (matrix elems elem_ids tab_elems eq_ids) to
#                     empty structures
# $self->$_reset(1) - set (matrix elems elem_ids tab_elems eq_ids) to
#                     undef
my $_reset = sub {
  @{$_[0]}{qw(matrix elems elem_ids tab_elems eq_ids)} =
    $_[1] ? ( {},    [],   {},      {},       {})  : ((undef) x 5);
};


# just a function, not a method.
sub _rule_pos_array_f {
  my ($str) = @_;
  my @rule_pos;
  my $idx = index($str, '|');
  while($idx != -1) {
    push(@rule_pos, $idx);
    $idx = index($str, '|', $idx + 1);
  }
  return \@rule_pos;
}

# just a function, not a method.
sub _int_array_cmp {
  my ($arr1, $arr2) = @_;
  return !1 if @$arr1 != @$arr2;
  for (my $i = 0; $i < @$arr1; ++$i) {
    return !1 if $arr1->[$i] != $arr2->[$i];
  }
  return 1;
}

# just a function, not a method.
sub _parse_header_f {
  my ($header, $pedantic) = @_;
  $header =~ s/\s+$//;
  my @rule_pos;
  if ($pedantic) {
    substr($header, -1, 1) eq '|' or croak("'$header': Wrong header format");
  }
  $header =~ s/^\s*\|.*?\|\s*// or croak("'$header': Wrong header format");
  my @elem_array = $header eq "|" ? ('') : split(/\s*\|\s*/, $header);
  return ([], {}) if $header eq "";
  my $index = 0;
  my %elem_ids;
  foreach my $name (@elem_array) {
    croak("'$name': duplicate name in header") if exists($elem_ids{$name});
    $elem_ids{$name} = $index++;
  }
  return (\@elem_array, \%elem_ids);
}


my $_parse_row = sub {
  my $self = shift;
  my $row = shift;
  my ($inc, $noinc) = @{$self}{qw(inc noinc)};
  $row =~ s/^\|\s*([^|]*?)\s*\|\s*// or croak("Wrong row format: '$row'");
  my $rowElem = $1;
  my @rowContents;
  if ($row ne "") {
    $row =~ s/\s*\|\s*$//;
    my @entries = $row eq "" ? ("") : split(/\s*\|\s*/, $row, -1);
    foreach my $entry (@entries) {
      if ($entry eq $inc) {
        push(@rowContents, 1);
      } elsif ($entry eq $noinc) {
        push(@rowContents, "");
      } else {
        croak("'$entry': unexpected entry");
      }
    }
  }
  return ($rowElem, \@rowContents);
};


my $_parse_table = sub {
  my $self = shift;
  my ($lines, $allow_subset, $pedantic) = @_;
  my $index = 0;
  for (; $index < @$lines; ++$index) { # skip heading empty lines
    last if $lines->[$index] =~ /\S/;
  }
  if ($index == @$lines) {
    $self->$_reset(1);
    return;
  }
  my ($h_elems, $h_ids) = _parse_header_f($lines->[$index], $pedantic);
  my ($sep_line, $rule_pos);
  if ($pedantic) {
    ($sep_line = $lines->[$index]) =~ s/\s+$//;
    $rule_pos = _rule_pos_array_f($sep_line);
    for (my $i = 0; $i < @$rule_pos - 1; ++$i) {
      my ($b, $e) = @{$rule_pos}[$i, $i + 1];
      substr($sep_line, $b, 1, '+') if $i;
      my $d = $e - $b;
      next unless $d > 1;
      --$d;
      substr($sep_line, $b + 1, $d, '-' x $d);
    }
  }
  my $elem_ids;
  my %rows;
  my @rowElems;                 # To keep oder of additional row elements, if any.
  for (++$index; $index < @$lines; ++$index) {
    (my $line = $lines->[$index]) =~ s/\s+$//;
    last if $line eq q{};
    if ($pedantic) {
      $line =~ /\S/;
      $-[0] == $rule_pos->[0] or croak("Wrong indentation at line " . ($index + 1));
    }
    if ($line =~ /^\s*\|-/) {
      if ($pedantic) {
        $line eq $sep_line or croak("Invalid row separator at line " . ($index + 1));
      }
      next;
    }
    if ($pedantic) {
      _int_array_cmp(_rule_pos_array_f($line), $rule_pos) or
        croak("Wrong row format at line " . ($index + 1));
    }
    $line =~ s/^\s*//;
    my ($rowElem, $rowContent) = $self->$_parse_row($line);
    croak("'$rowElem': duplicate element in first column") if exists($rows{$rowElem});
    $rows{$rowElem} = $rowContent;
    push(@rowElems, $rowElem);
  }
  if ($self->{prespec}) {
    my $tab_elems = $self->{tab_elems};
    $elem_ids     = $self->{elem_ids};
    foreach my $elem (keys(%{$h_ids})) {
      croak("'$elem': unknown element in table") if !exists($tab_elems->{$elem});
    }
    foreach my $elem (keys(%rows)) {
      croak("'$elem': unknown element in table") if !exists($tab_elems->{$elem});
    }
    if (!$allow_subset) {
      foreach my $elem (keys(%{$tab_elems})) {
        croak("'$elem': column missing for element") if !exists($h_ids->{$elem});
        croak("'$elem': row missing for element"   ) if !exists($rows{$elem});
      }
    }
  } else {
    if ($allow_subset) {
      foreach my $rowElem (@rowElems) {
        if (!exists($h_ids->{$rowElem})) {
          $h_ids->{$rowElem} = @{$h_elems};
          push(@{$h_elems}, $rowElem);
        }
      }
    } else {
      croak("Number of elements in header does not match number of elemens in row")
        if keys(%{$h_ids}) != keys(%rows);
      foreach my $elem (keys(%{$h_ids})) {
        croak("'$elem': row missing for element") if !exists($rows{$elem});
      }
    }
    my %tmp = %{$h_ids};
    @{$self}{qw(elems elem_ids tab_elems eq_ids)} = ($h_elems, $h_ids, \%tmp, {});
    $elem_ids = $h_ids;
  }
  my $eq_ids = $self->{eq_ids};
  my %matrix;
  while (my ($rowElem, $rowContents) = each(%rows)) {
    my %new_row;
    for (my $i = 0; $i < @{$rowContents}; $i++) {
      if ($rowContents->[$i]) {
        my $e_id = $elem_ids->{$h_elems->[$i]};
        $new_row{$e_id} = undef;
        if (exists($eq_ids->{$e_id})) {
          foreach my $eq_id (@{$eq_ids->{$e_id}}) {
            $new_row{$eq_id} = undef
          }
        }
      }
    }
    if (%new_row) {
      $matrix{$elem_ids->{$rowElem}} = \%new_row;
      if (exists($eq_ids->{$rowElem})) {
        foreach my $eq_id (@{$eq_ids->{$rowElem}}) {
          $matrix{$eq_id} = {%new_row};
        }
      }
    }
  }
  $self->{matrix} = \%matrix;
  return;
};


sub get {
  my $self = shift;
  croak("Odd number of arguments") if @_ % 2;
  my %args = @_;
  my $allow_subset = delete $args{allow_subset};
  my $pedantic     = delete $args{pedantic};
  croak("Missing argument 'src'") if !@_;
  my $src          = delete $args{src}          // croak("Invalid value argument for 'src'");
  croak(join(", ", sort(keys(%args))) . ": unexpected argument") if %args;
  my $inputArray;
  if (ref($src)) {
    croak("Invalid value argument for 'src'") if ref($src) ne 'ARRAY';
    foreach my $e (@{$src}) {
      croak("src: each entry must be a defined scalar") if (ref($e) || !defined($e));
    }
    $inputArray = $src;
  } elsif ($src !~ /\n/) {
    open(my $h, '<', $src);
    $inputArray = [<$h>];
    close($h);
  } else {
    $inputArray = [split(/\n/, $src)];
  }
  $self->$_reset() if !$self->{prespec};
  $self->$_parse_table($inputArray, $allow_subset, $pedantic);
  return wantarray ? @{$self}{qw(matrix elems elem_ids)} : $self;
}


sub inc         {croak("Unexpected argument(s)") if @_ > 1; $_[0]->{inc};}
sub noinc       {croak("Unexpected argument(s)") if @_ > 1; $_[0]->{noinc};}
sub prespec     {croak("Unexpected argument(s)") if @_ > 1; $_[0]->{prespec};}
sub elems       {croak("Unexpected argument(s)") if @_ > 1; $_[0]->{elems};}
sub elem_ids    {croak("Unexpected argument(s)") if @_ > 1; $_[0]->{elem_ids};}
sub tab_elems   {croak("Unexpected argument(s)") if @_ > 1; $_[0]->{tab_elems};}
sub eq_ids      {croak("Unexpected argument(s)") if @_ > 1; $_[0]->{eq_ids};}


sub matrix {
  my $self = shift;
  croak("Odd number of arguments") if @_ % 2;
  my %args = @_;
  my $bless = delete $args{bless};
  croak("Unexpected argument(s)") if %args;
  return if !$self->{matrix};
  bless($self->{matrix}, "Text::Table::Read::RelationOn::Tiny::_Relation_Matrix") if $bless;
  return $self->{matrix};
}


sub matrix_named {
  my $self = shift;
  croak("Odd number of arguments") if @_ % 2;
  my %args = @_;
  my $bless = delete $args{bless};
  croak("Unexpected argument(s)") if %args;

  my ($matrix, $elems) = @{$self}{qw(matrix elems)};
  return if !$matrix;
  my $matrix_named = {};
  bless($matrix_named, "Text::Table::Read::RelationOn::Tiny::_Relation_Matrix") if $bless;
  while (my ($rowElemIdx, $rowContents) = each(%{$matrix})) {
    $matrix_named->{$elems->[$rowElemIdx]} = {map {$elems->[$_] => undef} keys(%{$rowContents})};
  }
  return $matrix_named;
}



{
  package Text::Table::Read::RelationOn::Tiny::_Relation_Matrix;

  sub related { return exists($_[0]->{$_[1]}) && exists($_[0]->{$_[1]}->{$_[2]}); }
}


1; # End of Text::Table::Read::RelationOn::Tiny



__END__


=pod


=head1 NAME

Text::Table::Read::RelationOn::Tiny - Read binary "relation on (over) a set" from a text table.



=head1 VERSION

Version v2.2.4


=head1 SYNOPSIS

    use Text::Table::Read::RelationOn::Tiny;

    my $obj = Text::Table::Read::RelationOn::Tiny->new();
    my ($matrix, $elems, $ids) = $obj->get('my-table.txt');


=head1 DESCRIPTION

Minimum version of perl required to use this module: C<v5.10.1>.

This module implements a class that reads a binary I<relation on a set>
(I<homogeneous relation>, see
L<https://en.wikipedia.org/wiki/Binary_relation#Homogeneous_relation>) from a
text table.

The table format must look like this:


   | x\y     | this | that | foo bar |
   |---------+------+------+---------|
   | this    | X    |      | X       |
   |---------+------+------+---------|
   | that    |      |      | X       |
   |---------+------+------+---------|
   | foo bar |      | X    |         |
   |---------+------+------+---------|

=over

=item *

Tables are read by method C<get>, see below.

=item *

Only two different table entries are possible, these are C<X> and the empty
string (this is default and can be changed, see description of C<new>).

=item *

The entry in the table's upper left corner is simply ignored and may be empty,
but you cannot omit the upper left C<|> character.

=item *

The hotizontal rules are optional.

=item *

By default, there is not something like a format check for the horizontal
rules or the alignment. Any line starting with C<|-> is simply ignored,
regardless of the other subsequent characters, if any. Also, the C<|>
characters need not to be aligned, and heading spaces are ignored.

However, a format check can be enabled by specifying C<get> argument
C<pedantic> with a true value.

=item *

If you have not specified a base set in the construcor call, the entries
(names) in the table header are the element names of the set. Of course, they
must be unique. One of these names may be the empty string. Names my contain
spaces or punctuation chars. The C<|>, of course, cannot be part of a name.

=item *

The names of the columns (header line) and the rows (first entry of each row)
must be unique, but they don't have to appear in the same order. By default,
the set of the header names and the set of the row names must be equal, but
this can be changed by argument C<allow_subset> of method C<get>.

=back


=head2 METHODS

=head3 new

The constructor takes the following optional named scalar arguments:

=over

=item C<inc>

A string. Table entry that flags that the corresponding elements are
related. C<|> is not allowed, the value must be different from value of
C<noinc>. Heading and trailing spaces are removed.

Default is "X".

=item C<noinc>

A string. Table entry that flags that the corresponding elements are B<not>
related. C<|> is not allowed, the value must be different from value of
C<inc>. Heading and trailing spaces are removed.

Default is the empty set.

=item C<set>

If specified, then this must be an array of unique strings specifying the
elements of the set for your relation (it may also contain arrays, see
below). When the constructor was called with this argument, then method
C<elems> will return a reference to a copy of it, and C<elem_ids> will return
a hash mapping each element to its array index (otherwise both methods would
return C<undef> before the first call to C<get>).

Method C<get> will check if the elements in the input table are the same as
those specified in the array. Furthermore, the indices in C<matrix> will
always refer to the indices in the C<elems> array constructed from C<set>, and
C<elems> and C<elem_ids> will always return the same, regardless of the order
of rows and columns in the input table.

It may happen that there are elements that are identical with respect to the
relation and you do not want to write duplicate rows and columns in your
table. To cover such a case, it is allowed that entries of C<set> are
references to array of strings again (another way is using argument C<eqs>).

Example:

  [[qw(a a1 a2 a3)], 'b', [qw(c c1)], 'd']

In this case, the elements you write in your table are C<a>, C<b>, C<c>, and
C<d> (in case of a subarray the first element is always taken). Method C<get>
will add corresponding rows and columns for C<a1>, C<a2>, C<a3>, and C<c1> to
the incidence matrix. Method C<elems> will return this (the nested arrays are
flattened):

  [qw(a a1 a2 a3 b c c1 d)]

Method C<elem_ids> will return:

  {
   'a'  => '0',
   'a1' => '1',
   'a2' => '2',
   'a3' => '3',
   'b'  => '4',
   'c'  => '5',
   'c1' => '6',
   'd'  => '7'
   }

Method C<tab_elems> will return:

   {
    a => 0,
    b => 4,
    c => 5,
    d => 7
    }

And method C<eq_ids> will return:

   0 => [1, 2, 3],
   5 => [6]

=item C<eqs>

This argument takes a reference to an array of array references. It can only
be used if argument C<set> is specified, too. If C<eqs> is specified, then the
array passed via C<set> cannot contain arrays again.

This constructor call:

   Text::Table::Read::RelationOn::Tiny->new(set => [qw(a a1 a2 a3 b c c1 d)],
                                            eqs => [[qw(a a1 a2 a3)],
                                                    [qw(c c1)]]);

produces the same as this (see description of argument C<set>):

   Text::Table::Read::RelationOn::Tiny->new(set => [[qw(a a1 a2 a3)], 'b',
                                                    [qw(c c1)], 'd']);

However, the benefit of C<eqs> is that you can separate the declaration of the
base set and the equivalent elements, meaning that you can enforce an order of
the elements independent from what elements are equivalent in your relation.

=item C<ext>

"External data". If this boolean option is true, then the array referenced by
C<set> is not copied. Instead, the contructor uses directly the reference you
passed by C<set> and C<elems> will return this reference. This means, that you
must specify C<set> if you set C<ext> to true.

You can also specify C<elem_ids> along with C<set> and C<ext>. In this case,
the constructor first checks this hash for consistency and then uses the data
without copying it. See description of C<set> for more details about the
C<elem_ids> hash.

Restriction: you can't use array references as entries in the C<set> array if
you set C<ext> to true. However, you can still use C<eqs> if you want to
specify equivalent elements.

Default is false.


=item C<elem_ids>

This can only be specified in conjunction with C<ext> and C<set>. See
description of argument C<set>.

=back


=head3 get

The method reads and parses a table. It takes the following named arguments:

=over

=item C<src>

Mandatory. The source from which the table is to be read. May be either a file
name, an array reference or a string containing newline characters. 

=over

=item Argument is an array reference

The method treats the array entries as the rows of the table.

=item Argument is a string containing newlines

The method treats the argument as a string representation of the table and
parses it.

=item Argument is a string B<not> containing newlines

The method treats the argument as a file name and tries to read the table from
that file.

=back

=item C<allow_subset>

Optional. Takes a boolean value. If I<true>, then rows and columns need not to
be equal and may contain a subset of the relation's base set only. This way
you can omit rows and columns not containing any incidences.

=item C<pedantic>

Optional. Takes a boolean value. If I<true>, then some additional table format
checks are done:

=over

=item * Each row (incl. the header) must have a trailing C<|> character

=item * C<|> characters (and C<+> characters of row seperators) must be aligned.

=item * Row separators are also checked, but they are still optional.

=item * Indentation (if any) must be the same for all table rows.

=back

Default is I<false>.

=back

Note that the method will stop parsing if it recognizes a line containing not
any non-white character and will ignore any subsequent lines.

If you did not specify a base set in the constructor call, then C<get> will
create the set from the table. Then, it creates a hash of hashes representing
the relation (incidence matrix): each key is an integer which is an index in
the element array created before. Each corresponding value is again a hash
where the keys are the array indices of the elements being in relation; the
values do not matter and are always C<undef>. This hash will never contain
empty subhashes. (you can obtain this hash from the returned list or from
method C<matrix>).

C<get> will add identical rows and columns to the resulting incidence matrix
for elements that have been specified to be equivalent (see description of
C<new>).


B<Example>

This table:

    | x\y   | norel |      | foo | bar |
    |-------+-------+------+-----+-----|
    | norel |       |      |     |     |
    |-------+-------+------+-----+-----|
    |       |       | X    | X   |     |
    |-------+-------+------+-----+-----|
    | foo   |       |      |     | X   |
    |-------+-------+------+-----+-----|
    | bar   |       |      | X   |     |
    |-------+-------+------+-----+-----|

will result in this array:

  ('norel', '', 'foo', 'bar')

this hash:

  ('norel' => 0, '' => 1, 'foo' => 2, 'bar' => 3)

and in this hash representing the incidence matrix:

  1 => {
           1 => undef,
           2 => undef
         },
  3 => {
           2 => undef
         },
  2 => {
           3 => undef
         }

Note that element C<norel> (id 0), which is not in any relation, does not
appear in this hash (it would be C<< 0 => {} >> but as said, empty subhashes
are not contained).


B<Return value>:

In scalar context, the method returns simply the object.

In list context, the method returns a list containing three references
corresponding to the accessor methods C<matrix>, C<elems> and C<elem_ids>: the
hash representing the incidence matrix, the element array and the element
index (id) hash. Thus, wirting:

  my ($matrix, $elems, $elem_ids) = $obj->get($my_input);

is the same as writing

   $obj->get($my_input);
   my $matrix   = $obj->matrix;
   my $elems    = $obj->elems;
   my $elem_ids = $obj->elem_ids;

However, the first variant is shorter and needs only one method call.


=head3 C<inc>

Returns the current value of C<inc>. See description of C<new>.


=head3 C<noinc>

Returns the current value of C<noinc>. See description of C<new>.


=head3 C<prespec>

Returns 1 (true) if you specified constructor argument C<set> when calling the
constructor, otherwise it returns an empty string (false).


=head3 C<elems>

Returns a reference to the array of elements (names from the table's header
line), or C<undef> if you did neither call C<get> for the current object nor
specified option C<set> when calling the constructor. See description of
C<get> and C<new>.

B<Note>: This returns a reference to an internal member, so don't change the
content!


=head3 C<elem_ids>

Returns a reference to a hash mapping elements to ids (indices in array
returned by C<elems>), or C<undef> if you did neither call C<get> for the
current object nor specified argument C<set> when calling the constructor.

B<Note>: This returns a reference to an internal member, so don't change the
content!


=head3 C<tab_elems>

Returns a reference to a hash whose keys are the elements that may appear in
the table. If you did not specify equivalent elements (see description of
C<new>), then the contents of this hash is identical with C<elem_ids>.

B<Note>: This returns a reference to an internal member, so do not change the
contents!


=head3 C<eq_ids>

Returns a reference to a hash. If you specified equivalent elements (see
description of C<new>), then the keys are the indices (see C<elem_ids> and
C<elems>) of the representants and each value is an array of indices of the
corresponding equivalent elements (without the representant).

If you did not specify equivalent elements, the this method return C<undef>
after the constructor call, but the first call to C<get> sets it to an empty
hash.

B<Note>: This returns a reference to an internal member, so don't change the
content!


=head3 C<matrix>

Returns the incidence matrix (reference to a hash of hashes) produced by the
most recent call of C<get>, or C<undef> if you did not yet call C<get> for the
current object. See description of C<get>.

It takes a single optional boolean named argument C<bless>. If true, then the
matrix is blessed with
C<Text::Table::Read::RelationOn::Tiny::_Relation_Matrix> Then you can use the
matrix as an object having exactly one method named C<related>. This method
again takes two arguments (integers) and check if these are related with
respect to the incidence C<matrix>. Note that C<related> does not do any
parameter check.

Example:

  my $matrix = $rel_obj->matrix(bless => 1);
  if ($matrix->related(2, 5)) {
    # ...
  }

B<Note>: This returns a reference to an internal member, so don't change the
content!


=head3 C<matrix_named>

Returns an incidence matrix just as C<matrix> does, but the keys are the
element names rather than their indices. It takes a single optional boolean
named argument C<bless> doing a job corresponding to the C<bless> argument of
C<matrix>.

B<Note>: Unlike C<matrix> the matrix returned by C<matrix_named> is not a data
member and thus it is computed everytime you call this method. This also means
that you can change the content of the returned matrix without damaging
anything.


=head2 PITFALLS

Basically, you do not need spaces around the C<|> separators. This table, for
example, is perfectly fine:

     |.|a|b|c|
     |-+-+-+-|
     |c| |X| |
     |-+-+-+-|
     |b| | | |
     |-+-+-+-|
     |a| | |X|

However, if you have element names with a dash at the beginning, then you need
a space at least after the first C<|> character. Example:

=over

=item B<WRONG>


    | x\y   | this | that |-blah   |-    |
    |-------+------+------+--------+-----|
    | this  | X    |      | X      |  X  |
    |-------+------+------+--------+-----|
    | that  |      |      | X      |     |
    |-------+------+------+--------+-----|
    |-blah  |      | X    |        |     |
    |-------+------+------+--------+-----|
    |-      |      |      |        |     |
    |-------+------+------+--------+-----|


=item B<RIGHT>


    | x\y   | this | that |-blah   |-    |
    |-------+------+------+--------+-----|
    | this  | X    |      | X      |  X  |
    |-------+------+------+--------+-----|
    | that  |      |      | X      |     |
    |-------+------+------+--------+-----|
    | -blah |      | X    |        |     |
    |-------+------+------+--------+-----|
    | -     |      |      |        |     |
    |-------+------+------+--------+-----|

=back



=head1 AUTHOR

Abdul al Hazred, C<< <451 at gmx.eu> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-table-read-relationon-tiny at rt.cpan.org>, or through the web
interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Table-Read-RelationOn-Tiny>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Table::Read::RelationOn::Tiny


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Table-Read-RelationOn-Tiny>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Text-Table-Read-RelationOn-Tiny>

=item * Search CPAN

L<https://metacpan.org/release/Text-Table-Read-RelationOn-Tiny>

=item * GitHub Repository

L<https://github.com/AAHAZRED/perl-Text-Table-Read-RelationOn-Tiny>


=back



=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Abdul al Hazred.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut
