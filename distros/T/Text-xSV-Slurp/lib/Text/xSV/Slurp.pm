package Text::xSV::Slurp;

use warnings;
use strict;

use Carp 'confess', 'cluck';
use Text::CSV;
use IO::String;

use constant HOH_HANDLER_KEY            => 0;
use constant HOH_HANDLER_KEY_VALUE_PATH => 1;
use constant HOH_HANDLER_OLD_VALUE      => 2;
use constant HOH_HANDLER_NEW_VALUE      => 3;
use constant HOH_HANDLER_LINE_HASH      => 4;
use constant HOH_HANDLER_HOH            => 5;
use constant HOH_HANDLER_SCRATCH_PAD    => 6;

use base 'Exporter';

our @EXPORT = qw/ xsv_slurp /;

=head1 NAME

Text::xSV::Slurp - Convert xSV data to common data shapes.

=head1 VERSION

Version 0.22

=cut

our $VERSION = '0.22';

=head1 SYNOPSIS

C<Text::xSV::Slurp> converts xSV (typically CSV) data to nested data structures
of various shapes. It allows both column and row filtering using user defined
functions.

This brief example creates an array of hashes from a file, where each array
record corresponds to a line of the file, and each line is represented as a hash
of header-to-value pairs.

    use Text::xSV::Slurp 'xsv_slurp';
    
    my $aoh = xsv_slurp( 'foo.csv' );
    
    ## if foo.csv contains:
    ##
    ##   uid,name
    ##   342,tim
    ##   939,danboo
    ##
    ## then $aoh contains:
    ##
    ##   [
    ##     { uid => '342', name => 'tim' },
    ##     { uid => '939', name => 'danboo' },
    ##   ]
             
=head1 FUNCTIONS

=head2 C<xsv_slurp()>

C<xsv_slurp()> converts xSV (typically CSV) data to nested data structures of
various shapes. It allows both column and row filtering using user defined
functions.

Option summary:

=over

=item * C<file> - file name to be opened

=item * C<handle> - file handle to be iterated

=item * C<string> - string to be parsed

=item * C<shape> - target data structure (C<aoa>, C<aoh>, C<hoa> or C<hoh>)

=item * C<col_grep> - skip a subset of columns based on user callback

=item * C<row_grep> - skip a subset of rows based on user callback

=item * C<key> - xSV string or ARRAY used to build the keys of the C<hoh> shape

=item * C<on_store> - redefine how the C<hoh> shape should store values

=item * C<on_collide> - redefine how the C<hoh> shape should handle key collisions

=item * C<text_csv> - option hash for L<Text::CSV>/L<Text::CSV_XS> constructor

=back

The C<file>, C<handle> and C<string> options are mutually exclusive. Only one
source parameter may be passed in each call to C<xsv_slurp()>, otherwise a fatal
exception will be raised.

The source can also be provided implicitly, without the associated key, and the
source type will be guessed by examining the first item in the option list. If
the item is a reference type, it is treated as a C<handle> source. If the item
contains a newline or carriage return, it is treated as a C<string> source. If
the item passes none of the prior tests, it is treated as a C<file> source.

   ## implicit C<handle> source
   my $aoa = xsv_slurp( \*STDIN, shape => 'aoa' );

   ## implicit C<string> source
   my $aoh = xsv_slurp( "h1,h2\n" . "d1,d2\n" );

   ## implicit C<file> source
   my $aoh = xsv_slurp( 'foo.csv' );

The C<shape> parameter supports values of C<aoa>, C<aoh>, C<hoa> or C<hoh>. The
default shape is C<aoh>. Each shape affects certain parameters differently (see
below).

The C<text_csv> option can be used to control L<Text::CSV>/L<Text::CSV_XS>
parsing. The given HASH reference is passed to the L<Text::CSV> constructor. If
the C<text_csv> option is undefined, the default L<Text::CSV> constructor is
called. For example, to change the separator to a colon, you could do the
following:

   my $aoh = xsv_slurp( file => 'foo.csv',
                    text_csv => { sep_char => ':' } );

=head3 aoa

=over

example input:

   h1,h2,h3
   l,m,n
   p,q,r


example data structure:

   [
      [ qw/ h1 h2 h3 / ],
      [ qw/ l  m  n  / ],
      [ qw/ p  q  r  / ],
   ]

shape specifics:

=over

=item * C<col_grep> -  passed an ARRAY reference of indexes, should return a
                       list of indexes to be included

=item * C<row_grep> - passed an ARRAY reference of values, should return true or
                      false whether the row should be included or not

=back

full example:

   ## - convert xSV example to an array of arrays
   ## - include only rows containing values matching /[nr]/
   ## - include only the first and last columns 

   my $aoa = xsv_slurp( string   => $xsv_data,
                        shape    => 'aoa',
                        col_grep => sub { return @( shift() }[0,-1] },
                        row_grep => sub { return grep /[nr]/, @{ $_[0] } },
                      );

   ## $aoa contains:
   ##
   ##   [
   ##      [ 'l',  'n' ],
   ##      [ 'p',  'r' ],
   ##   ]

=back

=head3 aoh

=over

example input:

   h1,h2,h3
   l,m,n
   p,q,r

example data structure:

   [
      { h1 => 'l', h2 => 'm', h3 => 'n' },
      { h1 => 'p', h2 => 'q', h3 => 'r' },
   ]

shape specifics:

=over

=item * C<col_grep> - passed an ARRAY reference of column names, should return a
                      list of column names to be included

=item * C<row_grep> - passed a HASH reference of column name / value pairs,
                      should return true or false whether the row should be
                      included or not

=back

full example:

   ## - convert xSV example to an array of hashes
   ## - include only rows containing values matching /n/
   ## - include only the h3 column 

   my $aoh = xsv_slurp( string   => $xsv_data,
                        shape    => 'aoh',
                        col_grep => sub { return 'h3' },
                        row_grep => sub { return grep /n/, values %{ $_[0] } },
                      );

   ## $aoh contains:
   ##
   ##   [
   ##      { h3 => 'n' },
   ##   ]

=back

=head3 hoa

=over

example input:

   h1,h2,h3
   l,m,n
   p,q,r

example data structure:

   {
      h1 => [ qw/ l p / ],
      h2 => [ qw/ m q / ],
      h3 => [ qw/ n r / ],
   }

shape specifics:

=over

=item * C<col_grep> - passed an ARRAY reference of column names, should return a
                      list of column names to be included

=item * C<row_grep> - passed a HASH reference of column name / value pairs,
                      should return true or false whether the row should be
                      included or not

=back

full example:

   ## - convert xSV example to a hash of arrays
   ## - include only rows containing values matching /n/
   ## - include only the h3 column 

   my $hoa = xsv_slurp( string   => $xsv_data,
                        shape    => 'hoa',
                        col_grep => sub { return 'h3' },
                        row_grep => sub { return grep /n/, values %{ $_[0] } },
                      );

   ## $hoa contains:
   ##
   ##   {
   ##      h3 => [ qw/ n r / ],
   ##   }

=back

=head3 hoh

=over

example input:

   h1,h2,h3
   l,m,n
   p,q,r

example data structure (assuming a C<key> of C<'h2,h3'>):

   {
   m => { n => { h1 => 'l' } },
   q => { r => { h1 => 'p' } },
   }

shape specifics:

=over

=item * C<key> - an xSV string or ARRAY specifying the indexing column names

=item * C<col_grep> - passed an ARRAY reference of column names, should return a
                      list of column names to be included

=item * C<row_grep> - passed a HASH reference of column name / value pairs,
                      should return true or false whether the row should be
                      included or not

=item * C<on_collide> - specify how key collisions should be handled (see
                        L</HoH collision handlers>)

=back

full example:

   ## - convert xSV example to a hash of hashes
   ## - index using h1 values
   ## - include only rows containing values matching /n/
   ## - include only the h3 column 

   my $hoh = xsv_slurp( string   => $xsv_data,
                        shape    => 'hoh',
                        key      => 'h1',
                        col_grep => sub { return 'h3' },
                        row_grep => sub { return grep /n/, values %{ $_[0] } },
                      );

   ## $hoh contains:
   ##
   ##   {
   ##      l => { h3 => 'n' },
   ##      p => { h3 => 'r' },
   ##   }

=back

=head1 HoH storage handlers

Using the C<hoh> shape can result in non-unique C<key> combinations. The default
action is to simply assign the values to the given slot as they are encountered,
resulting in any prior values being lost.

For example, using C<h1,h2> as the indexing key with the default collision
handler:

   $xsv_data = <<EOXSV;
   h1,h2,h3
   1,2,3
   1,2,5
   EOXSV

   $hoh = xsv_slurp( string => $xsv_data,
                     shape  => 'hoh',
                     key    => 'h1,h2'
                   );
   
would result in the initial value in the C<h3> column being lost. The resulting
data structure would only record the C<5> value:

   {
      1 => { 2 => { h3 => 5 } },  ## 3 sir!
   }

Typically this is not very useful. The user probably wanted to aggregate the
values in some way. This is where the C<on_store> and C<on_collide> handlers
come in, allowing the caller to specify how these assignments should be
handled.

The C<on_store> handler is called for each assignment action, while the
C<on_collide> handler is only called when an actual collision occurs (i.e.,
the nested value path for the current line is the same as a prior line).

If instead we wanted to push the values onto an array, we could use the built-in
C<push> handler for the C<on_store> event as follows:

   $hoh = xsv_slurp( string   => $xsv_data,
                     shape    => 'hoh',
                     key      => 'h1,h2',
                     on_store => 'push',
                   );

the resulting C<HoH>, using the same data as above, would instead look like:

   {
      1 => { 2 => { h3 => [3,5] } },  ## 3 sir!
   }

Or if we wanted to sum the values we could us the C<sum> handler for the
C<on_collide> event:

   $hoh = xsv_slurp( string     => $xsv_data,
                     shape      => 'hoh',
                     key        => 'h1,h2',
                     on_collide => 'sum',
                   );
                   
resulting in the summation of the values:

   {
      1 => { 2 => { h3 => 8 } },
   }

=head2 builtin C<on_store> handlers

A number of builtin C<on_store> handlers are provided and can be specified
by name.

The example data structures below use the following data.

   h1,h2,h3
   1,2,3
   1,2,5

=head3 count

Count the times a key occurs.

   { 1 => { 2 => { h3 => 2 } } }

=head3 frequency

Create a frequency count of values.

   { 1 => { 2 => { h3 => { 3 => 1, 5 => 1 } } } }

=head3 push

C<push> values onto an array *always*.

   { 1 => { 2 => { h3 => [ 3, 5 ] } } }

=head3 unshift

C<unshift> values onto an array *always*.

   { 1 => { 2 => { h3 => [ 5, 3 ] } } }

=head2 builtin C<on_collide> handlers

A number of builtin C<on_collide> handlers are provided and can be specified
by name.

The example data structures below use the following data.

   h1,h2,h3
   1,2,3
   1,2,5

=head3 sum

Sum the values.

   { 1 => { 2 => { h3 => 8 } } }

=head3 average

Average the values.

   { 1 => { 2 => { h3 => 4 } } }

=head3 push

C<push> values onto an array *only on colliding*.

   { 1 => { 2 => { h3 => [ 3, 5 ] } } }

=head3 unshift

C<unshift> values onto an array *only on colliding*.

   { 1 => { 2 => { h3 => [ 5, 3 ] } } }

=head3 die

Carp::confess if a collision occurs.

   Error: key collision in HoH construction (key-value path was: { 'h1' => '1' }, { 'h2' => '2' })

=head3 warn

Carp::cluck if a collision occurs.

   Warning: key collision in HoH construction (key-value path was: { 'h1' => '1' }, { 'h2' => '2' })

=cut

my %shape_map =
   (
   'aoa' => \&_as_aoa,
   'aoh' => \&_as_aoh,
   'hoa' => \&_as_hoa,
   'hoh' => \&_as_hoh,
   );

sub xsv_slurp
   {
   my @o = @_;

   ## guess the source if there is an odd number of args
   if ( @o % 2 )
      {
      my $src = shift @o;
      if ( ref $src )
         {
         @o = ( handle => $src, @o );
         }
      elsif ( $src =~ /[\r\n]/ )
         {
         @o = ( string => $src, @o );
         }
      else
         {
         @o = ( file => $src, @o );
         }
      }

   ## convert argument list to option hash 
   my %o = @o;

   ## validate the source type   
   my @all_srcs   = qw/ file handle string /;
   my @given_srcs = grep { defined $o{$_} } @all_srcs;
   
   if ( ! @given_srcs )
      {
      confess "Error: no source given, specify one of: @all_srcs.";
      }
   elsif ( @given_srcs > 1 )
      {
      confess "Error: too many sources given (@given_srcs), specify only one.";
      }

   ## validate the shape      
   my $shape  = defined $o{'shape'} ? lc $o{'shape'} : 'aoh';
   my $shaper = $shape_map{ $shape };
   
   if ( ! $shaper )
      {
      my @all_shapes = keys %shape_map;
      confess "Error: unrecognized shape given ($shape). Must be one of: @all_shapes"
      }
      
   ## check various global options for expectations
   if ( defined $o{'col_grep'} && ref $o{'col_grep'} ne 'CODE' )
      {
      confess 'Error: col_grep must be a CODE ref';
      }
   
   if ( defined $o{'row_grep'} && ref $o{'row_grep'} ne 'CODE' )
      {
      confess 'Error: row_grep must be a CODE ref';
      }

   ## isolate the source
   my $src      = $given_srcs[0];
   
   ## convert the source to a handle
   my $handle   = _get_handle( $src => $o{$src} );
   
   ## create the CSV parser
   my $csv      = Text::CSV->new( $o{'text_csv'} || () );
   
   ## run the data conversion
   my $data     = $shaper->( $handle, $csv, \%o );
   
   return $data;
   }

## arguments:
## $handle - file handle
## $csv    - the Text::CSV parser object
## $o      - the user options passed to xsv_slurp   
sub _as_aoa
   {
   my ( $handle, $csv, $o ) = @_;
   
   my @aoa;

   my @cols;
   my $col_grep;
   
   while ( my $line = $csv->getline($handle) )
      {
      
      ## skip unwanted rows
      if ( defined $o->{'row_grep'} )
         {
         next if ! $o->{'row_grep'}->( $line );
         }
      
      ## remove unwanted cols   
      if ( defined $o->{'col_grep'} )
         {
         if ( ! $col_grep )
            {
            $col_grep++;
            @cols = $o->{'col_grep'}->( 0 .. $#{ $line } );
            }
         @{ $line } = @{ $line }[@cols];
         }

      push @aoa, $line;
      
      }
      
   if ( ! $csv->eof )
      {
      confess 'Error: ' . $csv->error_diag;
      }
   
   return \@aoa;
   }   
   
## arguments:
## $handle - file handle
## $csv    - the Text::CSV parser object
## $o      - the user options passed to xsv_slurp   
sub _as_aoh
   {
   my ( $handle, $csv, $o ) = @_;

   my @aoh;
   
   my $headers = $csv->getline($handle);
   
   return \@aoh if $csv->eof;
   
   if ( ! defined $headers )
      {
      confess 'Error: ' . $csv->error_diag;
      }
   
   my @headers = @{ $headers };

   my @grep_headers;
      
   if ( defined $o->{'col_grep'} )
      {
      @grep_headers = $o->{'col_grep'}->( @headers );
      }
      
   while ( my $line = $csv->getline($handle) )
      {
         
      my %line;
         
      @line{ @headers } = @{ $line };

      ## skip unwanted rows
      if ( defined $o->{'row_grep'} )
         {
         next if ! $o->{'row_grep'}->( \%line );
         }

      ## remove unwanted cols
      if ( defined $o->{'col_grep'} )
         {
         %line = map { $_ => $line{$_} } @grep_headers;
         }
         
      push @aoh, \%line;
      
      }
      
   if ( ! $csv->eof )
      {
      confess 'Error: ' . $csv->error_diag;
      }
   
   return \@aoh;
   }   

## arguments:
## $handle - file handle
## $csv    - the Text::CSV parser object
## $o      - the user options passed to xsv_slurp   
sub _as_hoa
   {
   my ( $handle, $csv, $o ) = @_;

   my %hoa;
   
   my $headers = $csv->getline($handle);
   
   return \%hoa if $csv->eof;
   
   if ( ! defined $headers )
      {
      confess 'Error: ' . $csv->error_diag;
      }
   
   my @headers = @{ $headers };
   
   my @grep_headers;
   
   if ( defined $o->{'col_grep'} )
      {
      @grep_headers = $o->{'col_grep'}->( @headers );
      @hoa{ @grep_headers } = map { [] } @grep_headers;
      }
   else
      {
      @hoa{ @headers } = map { [] } @headers;
      }
   
   while ( my $line = $csv->getline($handle) )
      {
      my %line;
      
      @line{ @headers } = @{ $line };

      ## skip unwanted rows
      if ( defined $o->{'row_grep'} )
         {
         next if ! $o->{'row_grep'}->( \%line );
         }

      ## remove unwanted cols
      if ( defined $o->{'col_grep'} )
         {
         %line = map { $_ => $line{$_} } @grep_headers;
         }

      for my $k ( keys %line )
         {
         push @{ $hoa{$k} }, $line{$k};
         }
         
      }
      
   if ( ! $csv->eof )
      {
      confess 'Error: ' . $csv->error_diag;
      }
   
   return \%hoa;
   }

my %named_handlers =
   (
   
## predefined methods for handling hoh storage
   on_store =>
      {

      ## count
      'count' =>  sub
         {
         return ( $_[HOH_HANDLER_OLD_VALUE] || 0 ) + 1;
         },

      ## value histogram (count occurences of each value)
      'frequency' =>  sub
         {
         my $ref = $_[HOH_HANDLER_OLD_VALUE] || {};
         $ref->{ $_[HOH_HANDLER_NEW_VALUE] } ++;
         return $ref;
         },
      
      ## push to array
      'push' =>  sub
         {
         my $ref = $_[HOH_HANDLER_OLD_VALUE] || [];
         push @{ $ref }, $_[HOH_HANDLER_NEW_VALUE]; 
         return $ref;
         },

      ## unshift to array
      'unshift' =>  sub
         {
         my $ref = $_[HOH_HANDLER_OLD_VALUE] || [];
         unshift @{ $ref }, $_[HOH_HANDLER_NEW_VALUE]; 
         return $ref;
         },
         
      },

   ## predefined methods for handling hoh collisions
   on_collide =>
      {
   
      ## sum
      'sum' =>  sub
         {
         return ( $_[HOH_HANDLER_OLD_VALUE] || 0 ) + ( $_[HOH_HANDLER_NEW_VALUE] || 0 );
         },

      ## average
      'average' =>  sub
         {
         if ( ! exists $_[HOH_HANDLER_SCRATCH_PAD]{'count'} )
            {
            $_[HOH_HANDLER_SCRATCH_PAD]{'count'} = 1;
            $_[HOH_HANDLER_SCRATCH_PAD]{'sum'}   = $_[HOH_HANDLER_OLD_VALUE];
            }
         $_[HOH_HANDLER_SCRATCH_PAD]{'count'}++;
         $_[HOH_HANDLER_SCRATCH_PAD]{'sum'} += $_[HOH_HANDLER_NEW_VALUE];
         return $_[HOH_HANDLER_SCRATCH_PAD]{'sum'} / $_[HOH_HANDLER_SCRATCH_PAD]{'count'};
         },

      ## die
      'die' =>  sub
         {
         if ( defined $_[HOH_HANDLER_OLD_VALUE] )
            {
            my @kv_pairs   = @{ $_[HOH_HANDLER_KEY_VALUE_PATH] };
            my @kv_strings = map { "{ '$_->[0]' => '$_->[1]' }" } @kv_pairs;
            my $kv_path    = join ', ', @kv_strings;
            confess "Error: key collision in HoH construction (key-value path was: $kv_path)";
            }
         },

      ## warn
      'warn' =>  sub
         {
         if ( defined $_[HOH_HANDLER_OLD_VALUE] )
            {
            my @kv_pairs   = @{ $_[HOH_HANDLER_KEY_VALUE_PATH] };
            my @kv_strings = map { "{ '$_->[0]' => '$_->[1]' }" } @kv_pairs;
            my $kv_path    = join ', ', @kv_strings;
            cluck "Warning: key collision in HoH construction (key-value path was: $kv_path)";
            }
         return $_[HOH_HANDLER_NEW_VALUE];
         },

      ## push to array
      'push' =>  sub
         {
         my $ref = ref $_[HOH_HANDLER_OLD_VALUE]
                 ? $_[HOH_HANDLER_OLD_VALUE]
                 : [ $_[HOH_HANDLER_OLD_VALUE] ];
         push @{ $ref }, $_[HOH_HANDLER_NEW_VALUE]; 
         return $ref;
         },

      ## unshift to array
      'unshift' =>  sub
         {
         my $ref = ref $_[HOH_HANDLER_OLD_VALUE]
                 ? $_[HOH_HANDLER_OLD_VALUE]
                 : [ $_[HOH_HANDLER_OLD_VALUE] ];
         unshift @{ $ref }, $_[HOH_HANDLER_NEW_VALUE]; 
         return $ref;
         },
         
      },

   );

## arguments:
## $handle - file handle
## $csv    - the Text::CSV parser object
## $o      - the user options passed to xsv_slurp   
sub _as_hoh
   {
   my ( $handle, $csv, $o ) = @_;

   my %hoh;
   
   my $headers = $csv->getline($handle);
   
   return \%hoh if $csv->eof;
   
   if ( ! defined $headers )
      {
      confess 'Error: ' . $csv->error_diag;
      }
   
   my @headers = @{ $headers };
   
   my @grep_headers;
   
   if ( defined $o->{'col_grep'} )
      {
      @grep_headers = $o->{'col_grep'}->( @headers );
      }

   my @key;
   
   if ( ref $o->{'key'} )
      {
      
      @key = @{ $o->{'key'} };
      
      }
   elsif ( defined $o->{'key'} )
      {
   
      if ( ! $csv->parse( $o->{'key'} ) )
         {
         confess 'Error: ' . $csv->error_diag;
         }
         
      @key = $csv->fields;

      }
   else
      {
      confess 'Error: no key given for hoh shape';
      }

   ## set the on_collide handler at the default level and by header
   my %storage_handlers;

   for my $header ( @headers )
      {
      
      for my $type ( qw/ on_store on_collide / )
         {
         
         my $handler = $o->{$type};

         next if ! $handler;
         
         if ( ref $handler eq 'HASH' )
            {
            $handler = $handler->{$header};
            }
         
         next if ! $handler;

         if ( ! ref $handler )
            {

            if ( ! exists $named_handlers{$type}{$handler} )
               {
               my $all_names = join ', ', sort keys %{ $named_handlers{$type} };
               confess "Error: invalid '$type' handler given ($handler). Must be one of: $all_names."
               }

            $handler = $named_handlers{$type}{$handler};
            }
            
         confess "Error: cannot set multiple storage handlers for '$header'"
            if $storage_handlers{$header};

         $storage_handlers{$header}{$type} = $handler;
         
         }

      }
      
   ## per-header scratch-pads used in collision functions
   my %scratch_pads = map { $_ => {} } @headers;

   while ( my $line = $csv->getline($handle) )
      {
         
      my %line;
      
      @line{ @headers } = @{ $line };
      
      ## skip unwanted rows
      if ( defined $o->{'row_grep'} )
         {
         next if ! $o->{'row_grep'}->( \%line );
         }

      ## step through the nested keys
      my $leaf = \%hoh;
      
      my @val;
      
      for my $k ( @key )
         {
         
         my $v         = $line{$k};
         $leaf->{$v} ||= {};
         $leaf         = $leaf->{$v};
         
         push @val, $v;
         
         }
      
      ## remove key headers from the line   
      delete @line{ @key };
      
      ## remove unwanted cols
      if ( defined $o->{'col_grep'} )
         {
         %line = map { $_ => $line{$_} } @grep_headers;
         }

      ## perform the aggregation if applicable            
      for my $key ( keys %line )
         {

         my $new_value = $line{$key};

         my $on_collide = $storage_handlers{$key}{'on_collide'};
         my $on_store   = $storage_handlers{$key}{'on_store'};
         
         if ( $on_store || $on_collide && exists $leaf->{$key} )
            {
            
            my $handler = $on_collide || $on_store;

            $new_value = $handler->(
               $key,                                         ## HOH_HANDLER_KEY
               [ map [ $key[$_] => $val[$_] ], 0 .. $#key ], ## HOH_HANDLER_KEY_VALUE_PATH
               $leaf->{$key},                                ## HOH_HANDLER_OLD_VALUE
               $new_value,                                   ## HOH_HANDLER_NEW_VALUE
               \%line,                                       ## HOH_HANDLER_LINE_HASH
               \%hoh,                                        ## HOH_HANDLER_HOH
               $scratch_pads{$key},                          ## HOH_HANDLER_SCRATCH_PAD
               );

            }

         $leaf->{$key} = $new_value;

         }
         
      }
      
   if ( ! $csv->eof )
      {
      confess 'Error: ' . $csv->error_diag;
      }
   
   return \%hoh;
   }   

## arguments:
## $src_type  - type of data source, handle, string or file
## $src_value - the file name, file handle or xSV string
sub _get_handle
   {
   my ( $src_type, $src_value ) = @_;

   if ( $src_type eq 'handle' )
      {
      return $src_value;
      }

   if ( $src_type eq 'string' )
      {
      my $handle = IO::String->new( $src_value );
      return $handle;
      }

   if ( $src_type eq 'file' )
      {
      open( my $handle, '<', $src_value ) || confess "Error: could not open '$src_value': $!";
      return $handle;
      }

   confess "Error: could not determine source type";
   }   

=head1 AUTHOR

Dan Boorstein, C<< <dan at boorstein.net> >>

=head1 TODO

=over

=item * add xsv_eruct() to dump shapes to xsv data

=item * add weighted-average collide keys and tests

=item * document hoh 'on_store/on_collide' custom keys

=item * add a recipes/examples section to cover grep and on_collide examples

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-xsv-slurp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-xSV-Slurp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::xSV::Slurp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-xSV-Slurp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-xSV-Slurp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-xSV-Slurp>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-xSV-Slurp/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Dan Boorstein.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Text::xSV::Slurp
