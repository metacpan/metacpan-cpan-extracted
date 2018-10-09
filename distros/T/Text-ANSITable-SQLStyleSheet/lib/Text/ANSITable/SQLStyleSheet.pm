package Text::ANSITable::SQLStyleSheet;
use 5.018000;
use strict;
use warnings;
use version;
use Text::ANSITable;
use JSON;
use DBI;
use DBD::SQLite;

our $VERSION = '0.05';

our $Json = JSON->new;

sub _sqlite_type_from_sth_ix {

  my ($dbh, $sth, $ix) = @_;

  my $sth_type = $sth->{TYPE}[ $ix ];

  # NOTE: It seems that as of 2018-10-06 DBD::SQLite returns the
  # wrong kind of value for TYPE. It also does not implement the 
  # type_info method.
  # 
  # Worse, for something like `SELECT 1, TYPEOF(1)` SQLite itself
  # considers the first to be an `integer`, but DBD::SQLite returns
  # `VARCHAR` in $sth->{TYPE}.
  #
  # Reported in <https://github.com/DBD-SQLite/DBD-SQLite/issues/36>.
  # 
  # Other drivers may have similar issues, so this is best-effort
  # guesswork.
  #
  # SQLite will do further guesswork on the type we pass to it, per
  # <https://www.sqlite.org/datatype3.html>.

  if (defined $sth_type) {

    my $type_info = $dbh->type_info($sth_type);

    if ( $type_info and exists $type_info->{TYPE_NAME} ) {

      return $type_info->{TYPE_NAME};

    } elsif ($sth_type !~ /^\d+$/) {

      return $sth_type;

    }

  }

  return 'TEXT';

}

sub _from_sth_sql {

  my ($class, $sth, $sql_or_code) = @_;

  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:');

  local $dbh->{sqlite_allow_multiple_statements} = 1;

  $dbh->do(q{
    PRAGMA synchronous  = OFF;
    PRAGMA journal_mode = OFF;
    PRAGMA locking_mode = EXCLUSIVE;
  });

  my $fields = join(',', map {
    sprintf(
      'CAST(NULL AS %s) AS %s',
      _sqlite_type_from_sth_ix($dbh, $sth, $_),
      $dbh->quote_identifier(undef, undef, $sth->{NAME}[$_]))
  } 0 .. @{ $sth->{NAME} } - 1);

  my $create_sth = $dbh->prepare(sprintf(q{
    CREATE TABLE data AS SELECT %s LIMIT 0
  }, $fields));

  $create_sth->execute();

  my $insert_sth = $dbh->prepare(sprintf(q{
    INSERT INTO data VALUES(%s)
  }, join(',', map { '?' } 0 .. @{ $sth->{NAME} } - 1)));

  $dbh->begin_work;

  while (my $row = $sth->fetchrow_arrayref()) {
    $insert_sth->execute(@$row);
  }

  $dbh->commit;

#  $dbh->sqlite_backup_to_file('DEBUG.sqlite');

  if ( 'CODE' eq ref( $sql_or_code ) ) {

    return $class->from_sth( $sql_or_code->($dbh) );

  } else {

    my $final_sth = $dbh->prepare( $sql_or_code );
    $final_sth->execute();
    return $class->from_sth( $final_sth );

  }

}

sub from_sth {

  my ($class, $sth, $sql_or_code) = @_;

  return _from_sth_sql(@_) if defined $sql_or_code;

  my %col2ix;
  $col2ix{$_} = keys %col2ix
    for @{ $sth->{NAME} };

  # filter out __*_style columns
  my @wanted = sort { $a <=> $b } map {
    /^__(\w+)_style$/ ? () : $col2ix{$_}
  } keys %col2ix;

  my $t = Text::ANSITable->new;

  $t->columns([ map { $sth->{NAME}[$_] } @wanted ]);

  my $nth = 0;
  
  while (my $row = $sth->fetchrow_arrayref) {

    $t->add_row([ @{ $row }[ @wanted ] ]);
  
    if ( $nth == 0 ) {
      _column_style( $t, $row, \%col2ix, $col2ix{__column_style} );
    }
  
    _row_style( $t, $nth, $row, \%col2ix, $col2ix{__row_style} );
    _cell_styles( $t, $nth, $row, \%col2ix, $col2ix{__cell_style} );
  
    $nth += 1;

  }
  
  return $t;

}

sub _get_hashref {
  my ($row, $ix) = @_;

  return unless defined $ix;
  return unless defined $row->[ $ix ];

  my $h = $Json->decode( $row->[ $ix ] );

  return unless 'HASH' eq ref( $h );

  delete @$h{ grep !defined($h->{$_}), keys %$h };
  
  return $h;

}

sub _column_style {
  
  my ($t, $row, $col2ix, $ix) = @_;

  return unless my $style = _get_hashref( $row, $ix );

  for my $column ( grep { exists $col2ix->{$_} } keys %$style ) {
    $t->set_column_style( $column, %{ $style->{ $column } } );
  }

}

sub _row_style {
  
  my ($t, $nth_row, $row, $col2ix, $ix) = @_;

  return unless my $style = _get_hashref( $row, $ix );

  $t->set_row_style( $nth_row, %$style );

}

sub _cell_styles {
  
  my ($t, $nth_row, $row, $col2ix, $ix) = @_;

  return unless my $style = _get_hashref( $row, $ix );

  for my $column ( grep { exists $col2ix->{$_} } keys %$style ) {

    my %cell_style = %{ $style->{ $column } };

    # override cell contents if pseudo-style `text` is specified
    if ( exists $cell_style{value} ) {
      $t->set_cell( $nth_row, $column, $cell_style{value} );
      delete $cell_style{value};
    }

    $t->set_cell_style(
      $nth_row,
      $column,
      %cell_style
    );

  }

}

1;

__END__

=head1 NAME

Text::ANSITable::SQLStyleSheet - Pretty tables with SQL-generated styles

=head1 SYNOPSIS

  use Text::ANSITable::SQLStyleSheet;
  use DBI;

  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:');

  my $sth = $dbh->prepare(q{
    WITH RECURSIVE
    ints AS (
      SELECT 1 AS value
      UNION ALL
      SELECT value + 1 AS value FROM ints
    )
    SELECT value FROM ints LIMIT 10
  });

  $sth->execute();

  my $t = Text::ANSITable::SQLStyleSheet->from_sth($sth, q{
    SELECT
      *,
      JSON_OBJECT(
        'fgcolor',
        PRINTF(
          '%02x%02x%02x',
          ABS(RANDOM()) % 256,
          ABS(RANDOM()) % 256,
          ABS(RANDOM()) % 256
        )
      ) AS __row_style
    FROM
      data
  });

  # a table with integers in random colours.
  print $t->draw;

=begin HTML

<p><img src="data:image/png;base64,
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
" /></p>

=end HTML

=head1 DESCRIPTION

When you frequently look at report tables from SQL queries in your
terminal and wish for a little bit of extra style, this module
allows you to specify styles as (part of) SQL queries.

You can do this either quick and dirty in your data queries, or by
letting this module store your data temporarily in an in-memory 
SQLite database before your "style sheet" is applied.

=head1 CONSTRUCTOR

=over

=item from_sth( $sth, $query )

Fetches all rows from C<$sth> into a C<data> table in a temporary
in-memory SQLite database and then executes C<$query> in that
database.

The C<$query> argument is optional; if omitted, data and styles are 
taken directly from C<$sth> as if you had called

  from_sth($sth, 'SELECT * FROM data')

but no temporary database is created. This tight coupling between 
data and style computation can be more convenient in some situations.

NOTE: While C<$query> will always be executed against SQLite, this 
module does not care which database driver C<$sth> is associated 
with. It does try to create the temporary table with the right type
affinity so SQLite does not suddenly treat integers as strings or 
otherwise, but that depends on cooperation on part of the driver.

The style sheet query is expected to add columns named
C<__column_style>, C<__row_style>, C<__cell_style> to the result set.
Values in these columns are JSON-encoded objects, see the template 
below for reference. The structure of the JSON objects mirrors the
configurable styles that C<Text::ANSITable> supports. Styles with
a C<NULL> value are ignored and are not passed to C<Text::ANSITable>.
All C<style> columns are optional. Column styles are taken only from
the first row.

In addition to the styles supported by C<Text::ANSITable>, this 
module supports an additional pseudo-style for cells named C<value>.
If specified, the value overrides the value that would otherwise be 
used for the cell. This allows you, for instance, to work with the 
full data in the "style sheet", and abbreviate or otherwise transform
it for display.

The C<$query> argument can also be a C<CODE> reference. The code
will be executed after the temporary database has been created with
the database handle as only argument, and is expected to return an
executed statement handle. That gives callers a chance to install
additional functions onto the handle or pass arguments to the query.

  my $t = Text::ANSITable::SQLStyleSheet->from_sth($sth, sub {
    my ($dbh) = @_;

    $dbh->sqlite_create_function('truncate', 2, sub {
      my ($string, $max_length) = @_;
      ...
    });

    my $sth = $dbh->prepare(q{
      WITH 
      args AS (
        SELECT ? AS max_length
      )
      SELECT
        ... truncate(long_text, args.max_length) ...
      FROM  
        data
          JOIN args
    });

    $sth->execute( 100 );

    return $sth;
  });

The return value is a C<Text::ANSITable> object.

=back

=head1 TEMPLATE FOR SQLITE

  WITH 
  data AS (
    SELECT
    ...
  )
  SELECT
    *
    ,
    JSON_OBJECT(
      'column_name',
      JSON_OBJECT(
        -- 'fgcolor', NULL,
        -- 'bgcolor', NULL,
        -- 'align', NULL,
        -- 'valign', NULL,
        -- 'formats', NULL
        -- pseudo-style not passed to Text::ANSITable
        -- 'value', NULL 
      )
      ,
      'other_column',
      JSON_OBJECT(
        ...
      )
    ) AS __cell_style
    ,
    JSON_OBJECT(
      -- 'align', NULL,
      -- 'valign', NULL,
      -- 'height', NULL,
      -- 'vpad', NULL,
      -- 'tpad', NULL,
      -- 'bpad', NULL,
      -- 'fgcolor', NULL,
      -- 'bgcolor', NULL
    ) AS __row_style
    ,
    JSON_OBJECT(
      'column_name',
      JSON_OBJECT(
        -- 'align', NULL,
        -- 'valign', NULL,
        -- 'pad', NULL,
        -- 'lpad', NULL,
        -- 'rpad', NULL,
        -- 'width', NULL,
        -- 'formats', NULL,
        -- 'fgcolor', NULL,
        -- 'bgcolor', NULL,
        -- 'type', NULL,
        -- 'wrap', NULL
      )
      ,
      'other_column',
      JSON_OBJECT(
        ...
      )
    ) AS __column_style
  FROM
    data

=head1 TODO

Unfortunately L<https://github.com/DBD-SQLite/DBD-SQLite/issues/36>
affects this module when your data query (the $sth handle you pass 
in) is executed against a SQLite database. The columns in the 
temporary database might then be associated with the wrong column
affinity, which can result in odd behavior in your style sheet 
query.

=head1 BUG REPORTS

=over

=item * L<https://github.com/hoehrmann/Text-ANSITable-SQLStyleSheet/issues>

=item * L<mailto:bug-Text-ANSITable-SQLStyleSheet@rt.cpan.org>

=item * L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-ANSITable-SQLStyleSheet>

=back

=head1 SEE ALSO

  * Text::ANSITable

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2018 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
