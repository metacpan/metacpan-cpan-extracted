package Text::RecordParser;

=head1 NAME

Text::RecordParser - read record-oriented files

=head1 SYNOPSIS

  use Text::RecordParser;

  # use default record (\n) and field (,) separators
  my $p = Text::RecordParser->new( $file );

  # or be explicit
  my $p = Text::RecordParser->new({
      filename        => $file,
      field_separator => "\t",
  });

  $p->filename('foo.csv');

  # Split records on two newlines
  $p->record_separator("\n\n");

  # Split fields on tabs
  $p->field_separator("\t");

  # Skip lines beginning with hashes
  $p->comment( qr/^#/ );

  # Trim whitespace
  $p->trim(1);

  # Use the fields in the first line as column names
  $p->bind_header;

  # Get a list of the header fields (in order)
  my @columns = $p->field_list;

  # Extract a particular field from the next row
  my ( $name, $age ) = $p->extract( qw[name age] );

  # Return all the fields from the next row
  my @fields = $p->fetchrow_array;

  # Define a field alias
  $p->set_field_alias( name => 'handle' );

  # Return all the fields from the next row as a hashref
  my $record = $p->fetchrow_hashref;
  print $record->{'name'};
  # or
  print $record->{'handle'};

  # Return the record as an object with fields as accessors
  my $object = $p->fetchrow_object;
  print $object->name; # or $object->handle;

  # Get all data as arrayref of arrayrefs
  my $data = $p->fetchall_arrayref;

  # Get all data as arrayref of hashrefs
  my $data = $p->fetchall_arrayref( { Columns => {} } );

  # Get all data as hashref of hashrefs
  my $data = $p->fetchall_hashref('name');

=head1 DESCRIPTION

This module is for reading record-oriented data in a delimited text
file.  The most common example have records separated by newlines and
fields separated by commas or tabs, but this module aims to provide a
consistent interface for handling sequential records in a file however
they may be delimited.  Typically this data lists the fields in the
first line of the file, in which case you should call C<bind_header>
to bind the field name (or not, and it will be called implicitly).  If
the first line contains data, you can still bind your own field names
via C<bind_fields>.  Either way, you can then use many methods to get
at the data as arrays or hashes.

=head1 METHODS

=cut

use strict;
use warnings;
use version;
use Carp qw( croak );
use IO::Scalar;
use List::MoreUtils qw( uniq );
use Readonly;
use Text::ParseWords qw( parse_line );

our $VERSION = version->new('1.6.5');

Readonly my $COMMA     => q{,};
Readonly my $EMPTY_STR => q{};
Readonly my $NEW_LINE  => qq{\n};
Readonly my $PIPE      => q{|};

# ----------------------------------------------------------------
sub new {

=pod

=head2 new

This is the object constructor.  It takes a hash (or hashref) of
arguments.  Each argument can also be set through the method of the
same name.

=over 4

=item * filename

The path to the file being read.  If the filename is passed and the fh
is not, then it will open a filehandle on that file and sets C<fh>
accordingly.  

=item * comment

A compiled regular expression identifying comment lines that should 
be skipped.

=item * data

The data to read.

=item * fh

The filehandle of the file to read.

=item * field_separator | fs

The field separator (default is comma).

=item * record_separator | rs

The record separator (default is newline).

=item * field_filter

A callback applied to all the fields as they are read.

=item * header_filter

A callback applied to the column names.

=item * trim

Boolean to enable trimming of leading and trailing whitespace from fields
(useful if splitting on whitespace only).

=back

See methods for each argument name for more information.

Alternately, if you supply a single argument to C<new>, it will be 
treated as the C<filename> argument.

=cut

    my $class = shift;

    my $args  
        = defined $_[0] && UNIVERSAL::isa( $_[0], 'HASH' ) ? shift 
        : scalar @_ == 1 ? { filename => shift } 
        : { @_ };

    my $self  = bless {}, $class;

    if ( my $fs = $args->{'fs'} ) {
        $args->{'field_separator'} = $fs;
        delete $args->{'fs'};
    }

    if ( my $rs = $args->{'rs'} ) {
        $args->{'record_separator'} = $rs;
        delete $args->{'rs'};
    }

    my $data_handles = 0;
    for my $arg ( 
        qw[ filename fh header_filter field_filter trim
            field_separator record_separator data comment
        ] 
    ) {
        next if !defined $args->{ $arg };

        if ( $arg =~ / \A (filename|fh|data) \Z /xms ) {
            $data_handles++;
        }

        $self->$arg( $args->{ $arg } );
    }

    if ( $data_handles > 1 ) {
        croak
            'Passed too many arguments to read the data. '.
            'Please choose only one of "filename," "fh," or "data."'
        ;
    }

    return $self;
}

# ----------------------------------------------------------------
sub bind_fields {

=pod

=head2 bind_fields

  $p->bind_fields( qw[ name rank serial_number ] );

Takes an array of field names and memorizes the field positions for
later use.  If the input file has no header line but you still wish to
retrieve the fields by name (or even if you want to call
C<bind_header> and then give your own field names), simply pass in the
an array of field names you wish to use.

Pass in an empty array reference to unset:

  $p->bind_field( [] ); # unsets fields

=cut

    my $self = shift;

    # using an empty arrayref to unset
    if ( ref $_[0] eq 'ARRAY' && !@{ $_[0] } ) {
        $self->{'field_pos_ordered'} = [];
        $self->{'field_pos'}         = {};
        $self->{'fields_bound'}      = 0;
    }
    elsif ( @_ ) {
        my @fields = @_;
        $self->{'field_pos_ordered'} = [ @fields ];

        my %field_pos;
        for my $i ( 0 .. $#fields ) {
            next unless $fields[ $i ];
            $field_pos{ $fields[ $i ] } = $i;
        }

        $self->{'field_pos'}    = \%field_pos;
        $self->{'fields_bound'} = 1;
    }
    else {
        croak 'Bind fields called without field list';
    }

    return 1;
}

# ----------------------------------------------------------------
sub bind_header {

=pod

=head2 bind_header

  $p->bind_header;
  my $name = $p->extract('name');

Takes the fields from the next row under the cursor and assigns the field
names to the values.  Usually you would call this immediately after 
opening the file in order to bind the field names in the first row.

=cut

    my $self = shift;

    if ( my @columns = $self->fetchrow_array ) {
        if ( my $filter = $self->header_filter ) {
            for my $i ( 0 .. $#columns ) {
                $columns[ $i ] = $filter->( $columns[ $i ] );
            }
        }

        $self->bind_fields( @columns );
    }
    else {
        croak q[Can't find columns in file '], $self->filename, q['];
    }

    return 1;
}

# ----------------------------------------------------------------
sub comment {

=pod

=head2 comment

  $p->comment( qr/^#/ );  # Perl-style comments
  $p->comment( qr/^--/ ); # SQL-style comments

Takes a regex to apply to a record to see if it looks like a comment
to skip.

=cut

    my $self = shift;

    if ( my $arg = shift ) {
        if ( ref $arg ne 'Regexp' ) {
            croak q[Argument to comment doesn't look like a regex];
        }

        $self->{'comment'} = $arg;
    }

    return defined $self->{'comment'} ? $self->{'comment'} : $EMPTY_STR;
}

# ----------------------------------------------------------------
sub data {

=pod

=head2 data

  $p->data( $string );
  $p->data( \$string );
  $p->data( @lines );
  $p->data( [$line1, $line2, $line3] );
  $p->data( IO::File->new('<data') );

Allows a scalar, scalar reference, glob, array, or array reference as
the thing to read instead of a file handle.

It's not advised to pass a filehandle to C<data> as it will read the
entire contents of the file rather than one line at a time if you set
it via C<fh>.

=cut

    my $self = shift;
    my $data;

    if (@_) {
        my $arg = shift;

        if ( UNIVERSAL::isa( $arg, 'SCALAR' ) ) {
            $data = $$arg;
        }
        elsif ( UNIVERSAL::isa( $arg, 'ARRAY' ) ) {
            $data = join $EMPTY_STR, @$arg;
        }
        elsif ( UNIVERSAL::isa( $arg, 'GLOB' ) ) {
            local $/;
            $data = <$arg>;
        }
        elsif ( !ref($arg) && @_ ) {
            $data = join $EMPTY_STR, $arg, @_;
        }
        else {
            $data = $arg;
        }
    }
    else {
        croak 'Data called without any arguments';
    }

    if ( $data ) {
        my $fh = IO::Scalar->new( \$data );
        $self->fh( $fh );
    }
    else {
        croak 'No usable data';
    }

    return 1;
}

# ----------------------------------------------------------------
sub extract {

=pod

=head2 extract

  my ( $foo, $bar, $baz ) = $p->extract( qw[ foo bar baz ] );

Extracts a list of fields out of the last row read.  The field names
must correspond to the field names bound either via C<bind_fields> or
C<bind_header>.

=cut

    my $self    = shift;
    my @fields  = @_ or return;
    my %allowed = map { $_, 1 } $self->field_list;
    my $record  = $self->fetchrow_hashref or return;

    my @data;
    foreach my $field ( @fields ) {
        if ( $allowed{ $field } ) {
            push @data, $record->{ $field };
        }
        else {
            croak "Invalid field $field for file "
                . $self->filename
                . $NEW_LINE 
                . 'Valid fields are: ' 
                . join(', ', $self->field_list) 
                . $NEW_LINE
            ;
        }
    }

    return scalar @data == 1 ? $data[0] : @data;
}

# ----------------------------------------------------------------
sub fetchrow_array {

=pod

=head2 fetchrow_array

  my @values = $p->fetchrow_array;

Reads a row from the file and returns an array or array reference 
of the fields.

=cut

    my $self    = shift;
    my $fh      = $self->fh or croak 'No filename or file handle';
    my $comment = $self->comment;
    local $/    = $self->record_separator;

    my $line;
    my $line_no = 0;
    for ( ;; ) {
        $line_no++;
        defined( $line = <$fh> ) or return;
        chomp $line;
        next if $comment and $line =~ $comment;
        $line =~ s/(?<!\\)'/\\'/g;
        last if $line;
    }

    my $separator = $self->field_separator;
    $separator eq $PIPE and $separator = '\|';
    my @fields    = map { defined $_ && $_ =~ s/\\'/'/g; $_ } (
        ( ref $separator eq 'Regexp' )
        ? parse_line( $separator, 0, $line )
        : parse_line( $separator, 1, $line )
    );

    if ( !@fields ) {
        croak "Error reading line number $line_no:\n$line";
    }

    if ( my $filter = $self->field_filter ) {
        @fields = map { $filter->( $_ ) } @fields;
    }

    if ( $self->trim ) {
        @fields = map { defined $_ && s/^\s+|\s+$//g; $_ } @fields;
    }

    while ( my ( $position, $callback ) = each %{ $self->field_compute } ) {
        next if $position !~ m/^\d+$/;
        $fields[ $position ] = $callback->( $fields[ $position ], \@fields );
    }

    return wantarray ? @fields : \@fields;
}

# ----------------------------------------------------------------
sub fetchrow_hashref {

=pod

=head2 fetchrow_hashref

  my $record = $p->fetchrow_hashref;
  print "Name = ", $record->{'name'}, "\n";

Reads a line of the file and returns it as a hash reference.  The keys
of the hashref are the field names bound via C<bind_fields> or
C<bind_header>.  If you do not bind fields prior to calling this method,
the C<bind_header> method will be implicitly called for you.

=cut

    my $self   = shift;
    my @fields = $self->field_list     or return;
    my @row    = $self->fetchrow_array or return;

    my $i = 0;
    my %return;
    for my $field ( @fields ) {
        next unless defined $row[ $i ];
        $return{ $field } = $row[ $i++ ];
        if ( my @aliases = $self->get_field_aliases( $field ) ) {
            $return{ $_ } = $return{ $field } for @aliases;
        }
    }

    while ( my ( $position, $callback ) = each %{ $self->field_compute } ) {
        $return{ $position } = $callback->( $return{ $position }, \%return );
    }

    return \%return;
}

# ----------------------------------------------------------------
sub fetchrow_object {

=pod

=head2 fetchrow_object

  while ( my $object = $p->fetchrow_object ) {
      my $id   = $object->id;
      my $name = $object->naem; # <-- this will throw a runtime error
  }

This will return the next data record as a Text::RecordParser::Object
object that has read-only accessor methods of the field names and any
aliases.  This allows you to enforce field names, further helping
ensure that your code is reading the input file correctly.  That is,
if you are using the "fetchrow_hashref" method to read each line, you
may misspell the hash key and introduce a bug in your code.  With this
method, Perl will throw an error if you attempt to read a field not
defined in the file's headers.  Additionally, any defined field
aliases will be created as additional accessor methods.

=cut

    my $self   = shift;
    my $row    = $self->fetchrow_hashref or return;
    my @fields = $self->field_list       or return;

    push @fields, map { $self->get_field_aliases( $_ ) } @fields;

    return Text::RecordParser::Object->new( \@fields, $row );
}

# ----------------------------------------------------------------
sub fetchall_arrayref {

=pod

=head2 fetchall_arrayref

  my $records = $p->fetchall_arrayref;
  for my $record ( @$records ) {
      print "Name = ", $record->[0], "\n";
  }

  my $records = $p->fetchall_arrayref( { Columns => {} } );
  for my $record ( @$records ) {
      print "Name = ", $record->{'name'}, "\n";
  }

Like DBI's fetchall_arrayref, returns an arrayref of arrayrefs.  Also 
accepts optional "{ Columns => {} }" argument to return an arrayref of
hashrefs.

=cut

    my $self   = shift;
    my %args   
        = defined $_[0] && ref $_[0] eq 'HASH' ? %{ shift() } 
        : @_ % 2 == 0 ? @_
        : ();

    my $method = ref $args{'Columns'} eq 'HASH' 
                 ? 'fetchrow_hashref' : 'fetchrow_array';

    my @return;
    while ( my $record = $self->$method() ) {
        push @return, $record;
    }

    return \@return;
}

# ----------------------------------------------------------------
sub fetchall_hashref {

=pod

=head2 fetchall_hashref

  my $records = $p->fetchall_hashref('id');
  for my $id ( keys %$records ) {
      my $record = $records->{ $id };
      print "Name = ", $record->{'name'}, "\n";
  }

Like DBI's fetchall_hashref, this returns a hash reference of hash
references.  The keys of the top-level hashref are the field values
of the field argument you supply.  The field name you supply can be
a field created by a C<field_compute>.

=cut

    my $self      = shift;
    my $key_field = shift(@_) || return croak('No key field');
    my @fields    = $self->field_list;

    my ( %return, $field_ok );
    while ( my $record = $self->fetchrow_hashref ) {
        if ( !$field_ok ) {
            if ( !exists $record->{ $key_field } ) {
                croak "Invalid key field: '$key_field'";
            }

            $field_ok = 1;
        }

        $return{ $record->{ $key_field } } = $record;
    }

    return \%return;
}

# ----------------------------------------------------------------
sub fh {

=pod

=head2 fh

  open my $fh, '<', $file or die $!;
  $p->fh( $fh );

Gets or sets the filehandle of the file being read.

=cut

    my ( $self, $arg ) = @_;

    if ( defined $arg ) {
        if ( ! UNIVERSAL::isa( $arg, 'GLOB' ) ) {
            croak q[Argument to fh doesn't look like a filehandle];
        }

        if ( defined $self->{'fh'} ) {
            close $self->{'fh'} or croak "Can't close existing filehandle: $!";
        }

        $self->{'fh'}       = $arg;
        $self->{'filename'} = $EMPTY_STR;
    }

    if ( !defined $self->{'fh'} ) {
        if ( my $file = $self->filename ) {
            open my $fh, '<', $file or croak "Cannot read '$file': $!";
            $self->{'fh'} = $fh;
        }
    }

    return $self->{'fh'};
}

# ----------------------------------------------------------------
sub field_compute {

=pod

=head2 field_compute

A callback applied to the fields identified by position (or field
name if C<bind_fields> or C<bind_header> was called).  

The callback will be passed two arguments:

=over 4

=item 1

The current field

=item 2

A reference to all the other fields, either as an array or hash 
reference, depending on the method which you called.

=back

If data looks like this:

  parent    children
  Mike      Greg,Peter,Bobby
  Carol     Marcia,Jane,Cindy

You could split the "children" field into an array reference with the 
values like so:

  $p->field_compute( 'children', sub { [ split /,/, shift() ] } );

The field position or name doesn't actually have to exist, which means
you could create new, computed fields on-the-fly.  E.g., if you data
looks like this:

    1,3,5
    32,4,1
    9,5,4

You could write a field_compute like this:

    $p->field_compute( 3,
        sub {
            my ( $cur, $others ) = @_;
            my $sum;
            $sum += $_ for @$others;
            return $sum;
        }
    );

Field "3" will be created as the sum of the other fields.  This allows
you to further write:

    my $data = $p->fetchall_arrayref;
    for my $rec ( @$data ) {
        print "$rec->[0] + $rec->[1] + $rec->[2] = $rec->[3]\n";
    }

Prints:

    1 + 3 + 5 = 9
    32 + 4 + 1 = 37
    9 + 5 + 4 = 18

=cut

    my $self = shift;

    if ( @_ ) {
        my ( $position, $callback ) = @_;

        if ( $position !~ /\S+/ ) {
            croak 'No usable field name or position';
        }

        if ( ref $callback ne 'CODE' ) {
            croak 'Callback not code reference';
        }

        $self->{'field_computes'}{ $position } = $callback;
    }

    return $self->{'field_computes'} || {};
}

# ----------------------------------------------------------------
sub field_filter {

=pod

=head2 field_filter

  $p->field_filter( sub { $_ = shift; uc(lc($_)) } );

A callback which is applied to each field.  The callback will be
passed the current value of the field.  Whatever is passed back will
become the new value of the field.  The above example capitalizes
field values.  To unset the filter, pass in the empty string.

=cut

    my ( $self, $filter ) = @_;

    if ( defined $filter ) {
        if ( $filter eq $EMPTY_STR ) {
            $self->{'field_filter'} = $EMPTY_STR; # allows nullification 
        }
        elsif ( ref $filter eq 'CODE' ) {
            $self->{'field_filter'} = $filter;
        }
        else {
            croak q[Argument to field_filter doesn't look like code];
        }
    }

    return $self->{'field_filter'} || $EMPTY_STR;
}

# ----------------------------------------------------------------
sub field_list {

=pod

=head2 field_list

  $p->bind_fields( qw[ foo bar baz ] );
  my @fields = $p->field_list;
  print join ', ', @fields; # prints "foo, bar, baz"

Returns the fields bound via C<bind_fields> (or C<bind_header>).

=cut

    my $self = shift;

    if ( !$self->{'fields_bound'} ) {
        $self->bind_header;
    }

    if ( ref $self->{'field_pos_ordered'} eq 'ARRAY' ) {
        return @{ $self->{'field_pos_ordered'} };
    }
    else {
        croak 'No fields. Call "bind_fields" or "bind_header" first.';
    }
}

# ----------------------------------------------------------------
sub field_positions {

=pod

=head2 field_positions

  my %positions = $p->field_positions;

Returns a hash of the fields and their positions bound via 
C<bind_fields> (or C<bind_header>).  Mostly for internal use.

=cut

    my $self = shift;

    if ( ref $self->{'field_pos'} eq 'HASH' ) {
        return %{ $self->{'field_pos'} };
    }
    else {
        return;
    }
}

# ----------------------------------------------------------------
sub field_separator {

=pod

=head2 field_separator

  $p->field_separator("\t");     # splits fields on tabs
  $p->field_separator('::');     # splits fields on double colons
  $p->field_separator(qr/\s+/);  # splits fields on whitespace
  my $sep = $p->field_separator; # returns the current separator

Gets and sets the token to use as the field delimiter.  Regular
expressions can be specified using qr//.  If not specified, it will
take a guess based on the filename extension ("comma" for ".txt," 
".dat," or ".csv"; "tab" for ".tab").  The default is a comma.  

=cut

    my $self = shift;

    if ( @_ ) {
        $self->{'field_separator'} = shift;
    }

    if ( !$self->{'field_separator'} ) {
        my $guess;
        if ( my $filename = $self->filename ) {
            if ( $filename =~ /\.(csv|txt|dat)$/ ) {
                $guess = q{,};
            }
            elsif ( $filename =~ /\.tab$/ ) {
                $guess = qq{\t};
            }
        }

        if ( $guess ) {
            $self->{'field_separator'} = $guess;
        }
    }

    return $self->{'field_separator'} || $COMMA;
}

# ----------------------------------------------------------------
sub filename {

=pod

=head2 filename

  $p->filename('/path/to/file.dat');

Gets or sets the complete path to the file to be read.  If a file is
already opened, then the handle on it will be closed and a new one
opened on the new file.

=cut

    my $self = shift;

    if ( my $filename = shift ) {
        if ( -d $filename ) {
            croak "Cannot use directory '$filename' as input source";
        } 
        elsif ( -f _ and -r _ ) {
            if ( my $fh = $self->fh ) {
                if ( !close($fh) ) {
                    croak "Can't close previously opened filehandle: $!\n";
                }

                $self->{'fh'} = undef;
                $self->bind_fields([]);
            }

            $self->{'filename'} = $filename;
        } 
        else {
            croak
                "Cannot use '$filename' as input source: ",
                'file does not exist or is not readable.'
            ;
        }
    }

    return $self->{'filename'} || $EMPTY_STR;
}

# ----------------------------------------------------------------
sub get_field_aliases {

=pod

=head2 get_field_aliases

  my @aliases = $p->get_field_aliases('name');

Allows you to define alternate names for fields, e.g., sometimes your
input file calls city "town" or "township," sometimes a file uses "Moniker"
instead of "name."

=cut

    my $self       = shift;
    my $field_name = shift or return;

    if ( !$self->{'field_alias'} ) {
        return;
    }

    return @{ $self->{'field_alias'}{ $field_name } || [] };
}

# ----------------------------------------------------------------
sub header_filter {

=pod

=head2 header_filter

  $p->header_filter( sub { $_ = shift; s/\s+/_/g; lc $_ } );

A callback applied to column header names.  The callback will be
passed the current value of the header.  Whatever is returned will
become the new value of the header.  The above example collapses
spaces into a single underscore and lowercases the letters.  To unset
a filter, pass in the empty string.

=cut

    my ( $self, $filter ) = @_;

    if ( defined $filter ) {
        if ( $filter eq $EMPTY_STR ) {
            $self->{'header_filter'} = $EMPTY_STR; # allows nullification
        }
        elsif ( ref $filter eq 'CODE' ) {
            $self->{'header_filter'} = $filter;

            if ( my %field_pos = $self->field_positions ) {
                my @new_order;
                while ( my ( $field, $order ) = each %field_pos ) {
                    my $xform = $filter->( $field );
                    $new_order[ $order ] = $xform;
                }

                $self->bind_fields( @new_order );
            }
        }
        else{
            croak q[Argument to field_filter doesn't look like code];
        }
    }

    return $self->{'header_filter'} || $EMPTY_STR;
}

# ----------------------------------------------------------------
sub record_separator {

=pod

=head2 record_separator

  $p->record_separator("\n//\n");
  $p->field_separator("\n");

Gets and sets the token to use as the record separator.  The default is 
a newline ("\n").

The above example would read a file that looks like this:

  field1
  field2
  field3
  // 
  data1
  data2
  data3
  //

=cut

    my $self = shift;

    if ( @_ ) {
        $self->{'record_separator'} = shift;
    }

    return $self->{'record_separator'} || $NEW_LINE;
}

# ----------------------------------------------------------------
sub set_field_alias {

=pod

=head2 set_field_alias

  $p->set_field_alias({
      name => 'Moniker,handle',        # comma-separated string
      city => [ qw( town township ) ], # or anonymous arrayref
  });

Allows you to define alternate names for fields, e.g., sometimes your
input file calls city "town" or "township," sometimes a file uses "Moniker"
instead of "name."

=cut

    my $self     = shift;
    my %args     = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;
    my %is_field = map { $_, 1 } $self->field_list;

    ARG:
    while ( my ( $field_name, $aliases ) = each %args ) {
        if ( ref $aliases ne 'ARRAY' ) {
            $aliases = [ split(/,/, $aliases) ];
        }

        if ( !$is_field{ $field_name } ) {
            push @$aliases, $field_name;
            ( $field_name ) = grep { $is_field{ $_ } } @$aliases;
            next ARG unless $field_name;
        }

        $self->{'field_alias'}{ $field_name } = [ 
            grep { $_ ne $field_name } uniq( @$aliases ) 
        ];
    }

    return 1;
}

# ----------------------------------------------------------------
sub trim {

=pod

=head2 trim

  my $trim_value = $p->trim(1);

Provide "true" argument to remove leading and trailing whitespace from
fields.  Use a "false" argument to disable.

=cut

    my ( $self, $arg ) = @_;

    if ( defined $arg ) {
        $self->{'trim'} = $arg ? 1 : 0;    
    }
    
    return $self->{'trim'};
}

1;

# ----------------------------------------------------------------
# I must Create a System, or be enslav'd by another Man's; 
# I will not Reason and Compare; my business is to Create.
#   -- William Blake, "Jerusalem"                  
# ----------------------------------------------------------------

=pod

=head1 AUTHOR

Ken Youens-Clark E<lt>kclark@cpan.orgE<gt>

=head1 SOURCE

http://github.com/kyclark/text-recordparser

=head1 CREDITS

Thanks to the following:

=over 4

=item * Benjamin Tilly 

For Text::xSV, the inspirado for this module

=item * Tim Bunce et al.

For DBI, from which many of the methods were shamelessly stolen

=item * Tom Aldcroft 

For contributing code to make it easy to parse whitespace-delimited data

=item * Liya Ren

For catching the column-ordering error when parsing with "no-headers"

=item * Sharon Wei

For catching bug in C<extract> that sets up infinite loops

=item * Lars Thegler 

For bug report on missing "script_files" arg in Build.PL

=back

=head1 BUGS

None known.  Please use http://rt.cpan.org/ for reporting bugs.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2006-10 Ken Youens-Clark.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

=cut
