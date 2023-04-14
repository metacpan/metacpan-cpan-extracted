package Text::ASCIITable::EasyTable;

use strict;
use warnings;

use Data::Dumper;
use JSON;
use List::Util qw(pairs);
use Scalar::Util qw(reftype);
use Text::ASCIITable;

use parent qw(Exporter);

our @EXPORT = qw(easy_table);  ## no critic (ProhibitAutomaticExportation)

our $VERSION = '1.003';

########################################################################
{
  ## no critic (RequireArgUnpacking)

  sub is_array { push @_, 'ARRAY'; goto &_is_type; }
  sub is_hash  { push @_, 'HASH';  goto &_is_type; }
  sub _is_type { return ref $_[0] && reftype( $_[0] ) eq $_[1]; }
}
########################################################################

########################################################################
sub uncamel {
########################################################################
  my ($str) = @_;

  while ( $str =~ s/^(.)(.*?)([[:upper:]])/\l$1$2_\l$3/xsmg ) { }

  return $str;
}

########################################################################
sub wordify {
########################################################################
  my ($str) = @_;

  $str = uncamel($str);

  $str =~ s/_(.)/ \u$1/xsmg;

  return ucfirst $str;
}

########################################################################
sub easy_table {
########################################################################
  my (%options) = @_;

  die "'data' must be ARRAY\n"
    if !is_array $options{data};

  my @columns;

  if ( $options{columns} ) {
    die "'columns' must be an ARRAY\n"
      if !is_array $options{columns};

    @columns = @{ $options{columns} };
  }
  elsif ( $options{rows} ) {
    die "'rows' must be ARRAY\n"
      if !is_array $options{rows};

    die "'rows' must be key/value pairs\n"
      if @{ $options{rows} } % 2;

    @columns = map { $_->[0] } pairs @{ $options{rows} };
  }
  else {
    @columns = keys %{ $options{data}->[0] };
  }

  $options{columns} = \@columns;

  my $data = _render_data( %options, columns => \@columns, );

  return _render_table( %options, data => $data )
    if !$options{json};

  # return an array of hashes
  my @json_data;

  foreach my $row ( @{$data} ) {
    my %hashed_row = map { $_ => shift @{$row} } @columns;
    push @json_data, \%hashed_row;
  }

  return JSON->new->pretty->encode( \@json_data );
}

########################################################################
sub _render_table {
########################################################################
  my (%options) = @_;

  # build a table...
  my $table_options = $options{table_options};
  $table_options //= {};

  die "'table_options' must be HASH\n"
    if !is_hash $table_options;

  $table_options->{headingText} //= 'Table';

  my $t = Text::ASCIITable->new($table_options);

  my @columns = @{ $options{columns} };

  if ( $options{fix_headings} ) {
    @columns = map { wordify $_ } @columns;
  }

  $t->setCols(@columns);

  for ( @{ $options{data} } ) {
    $t->addRow( @{$_} );
  }

  return $t;
}

########################################################################
sub _render_data {
########################################################################
  my (%options) = @_;

  my ( $data, $rows, $columns, $sort_key )
    = @options{qw(data rows columns sort_key)};

  my @sorted_data;

  if ($sort_key) {
    if ( reftype($sort_key) eq 'CODE' ) {
      @sorted_data = $sort_key->( @{$data} );
    }
    else {
      @sorted_data
        = sort { lc $a->{$sort_key} cmp lc $b->{$sort_key} } @{$data};
    }
  }
  else {
    @sorted_data = @{$data};
  }

  my %row_lu = $rows ? @{$rows} : ();

  my @rendered_data;

  my $row_count = 0;

  for my $row ( @{$data} ) {
    last
      if defined $options{max_rows} && ++$row_count > $options{max_rows};

    if ($rows) {
      push @rendered_data, [
        map {
          ref $row_lu{$_}
            && reftype( $row_lu{$_} ) eq 'CODE' ? $row_lu{$_}->( $row, $_ )
            : $row_lu{$_}                       ? $row->{ $row_lu{$_} }
            : $row->{$_}
        } @{$columns},
      ];
    }
    else {
      push @rendered_data, [ @{$row}{ @{$columns} } ];
    }
  }

  return \@rendered_data;
}

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

Text::ASCIITable::EasyTable - create ASCII tables from an array of hashes

=head1 SYNOPSIS

 use Text::ASCIITable::EasyTable;

 my $data = [
   { col1 => 'foo', col2 => 'bar' },
   { col1 => 'biz', col2 => 'buz' },
   { col1 => 'fuz', col2 => 'biz' },
 ];

 # easy
 my %index = ( ImageId => 'col1', Name => 'col2' );

 my $rows = [
   ImageId => sub { shift->{ $index{ shift() } } },
   Name    => sub { shift->{ $index{ shift() } } },
 ];
 
 print easy_table(
   data          => $data,
   rows          => $rows,
   table_options => { headingText => 'My Easy Table' },
 );

 # easier 
 print easy_table(
   data          => $data,
   columns       => [ sort keys %{ $data->[0] } ],
   table_options => { headingText => 'My Easy Table' },
 );
 
 # easiest 
 print easy_table( data => $data );


=head1 DESCRIPTION

L<Text::ASCIITable> is one of my favorite modules when I'm writing
command line scripts that sometimes need to output data in tabular
format. It's so useful that I wanted to encourage myself to use it
more often. Although, it is quite easy to use already I thought it
could be easier.

=head2 Features

=over

=item * Easily create ASCII tables using L<Text::ASCIITable> from
arrays of hashes.

=item * Define custom columns names (instead of the key names) that
also allow you to set the order of the data to be displayed in the table.

=item * Transform each element of the hash prior to insertion into the table.

=item * Sort rows by individual columns in the hashes

=item * Output JSON instead of a tableInstead of rendering a table, C<easy_table> can apply the same type of
transformations to arrays of hashes and subsequently output JSON.

=back

Exports one method C<easy_table>. 

=head1 METHODS AND SUBROUTINES

=head2 easy_table

=over 5

=item rows

Array (not hash) of key/value pairs where the key is the name of one
of the columns in the table and the value is either a subroutine
reference that returns the value of for that column, an undefined value, or the
name of a key in the hash that contains the value for that column.

 my $rows = [
   ID   => 'InstanceId',
   Name => sub { uc shift->{ImageName} },
   ];

=over 5

=item * If the value provided for the column name key is a subroutine, it will
be called with the hash for the current row being rendered and the
column name.

=item * If the value is undefined then the value for that column
will be the value of the hash member using the column name as the key.

=item *  If the value is not a code reference, then that value is assumed to
be the key to retrieve the value from the hash that will be inserted
into table.

=back

I<C<rows> is an array, not a hash in order to preserve
the order of the columns.>

=item columns

Array of column names that can represent both the keys that will be used to
extract data from the hash for each row and the labels for each column.

=item data

Array of hashes that contain the data for the table.

=item json

Instead of a table, return a JSON representation. The point here, is
to use the transformation capabilities but rather than rendering a
table, output JSON. Using this option you can transform the keys or
the values of arrays of hashes using the same techniques you would use
to transform the column names and column values in a table.

 my $data = [
   { col1 => 'foo', col2 => 'bar' },
   { col1 => 'biz', col2 => 'buz' },
   { col1 => 'fuz', col2 => 'biz' },
 ];
 
 my %index = ( ImageId => 'col1', Name => 'col2' );

 # dumb example, but the point is to transform 'some' of the data
 # in a non-trivial way
 my $rows = [
   ImageId => sub { uc shift->{ $index{ shift() } } },
   Name    => sub { uc shift->{ $index{ shift() } } },
 ];
 
 print easy_table(
   json => 1,
   data => $data,
   rows => $rows,
 );

 [
    {
       "ImageId" : "foo",
       "Name" : "bar"
    },
    {
       "Name" : "buz",
       "ImageId" : "biz"
    },
    {
       "ImageId" : "fuz",
       "Name" : "biz"
    }
 ]

=over 5

=item * I<C<easy_table()> is meant to be used on small data sets and may not
be efficient when larger data sets are used.>

=back

=item max_rows

Maximum number of rows to render.

=item fix_headings

Many data sets will contain hash keys composed of lower case letters
in what is termed I<snake case> (words separated by '_') or I<camel
case> (first letter of words in upper case). Set this to true to turn
snake and camel case into space separated 'ucfirst'ed words.

Example:

 creation_date => Creation Date
 IsTruncated   => Is Truncated

default: false

=item sort_key

Key in the hash to use for sorting the array prior to rendering.  If
C<sort_key> is a CODE reference, that method will be called prior to
rendering.

=item table_options

Same options as those supported by L<Text::ASCIITable>.

=back

I<If neither C<rows> or C<columns> is provided, the keys are assumed
to be the column names. In that case the order in which the columns
appear will be non-deterministic. If you want a specific order, provide
the C<columns> or C<rows> parameters. If you just want to see some
data and don't care about order, you can just send the C<data>
parameter and the method will more or less DWIM.>

=head1 SEE ALSO

L<Text::ASCIITable>, L<Term::ANSIColor>

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>>

=head1 LICENSE AND COPYRIGHT

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut
