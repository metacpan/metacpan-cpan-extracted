package Text::xSV;
$VERSION = 0.21;
use strict;
use Carp;

sub alias {
  my ($self, $from, $to) = @_;
  my $field_pos = $self->{field_pos}
    or return $self->error_handler(
      "Can't call alias before headers are bound");
  unless (exists $field_pos->{$from}) {
    return $self->error_handler("'$from' is not available to alias");
  }
  $field_pos->{$to} = $field_pos->{$from};
}

sub add_compute {
  my ($self, $name, $compute) = @_;
  my $field_pos = $self->{field_pos}
    or return $self->error_handler(
      "Can't call add_compute before headers are bound");
  unless (UNIVERSAL::isa($compute, "CODE")) {
    return $self->error_handler(
      'Usage: $csv->add_compute("name", sub {FUNCTION});');
  }
  $field_pos->{$name} = $compute;
}

sub bind_fields {
  my $self = shift;
  my %field_pos;
  foreach my $i (0..$#_) {
    $field_pos{$_[$i]} = $i;
  }
  $self->{field_pos} = \%field_pos;
}

sub bind_header {
  my $self = shift;
  $self->bind_fields($self->get_row());
}

*read_headers = \&bind_header;
*read_header = \&bind_header;

sub delete {
  my $self = shift;
  my $field_pos = $self->{field_pos}
    or return $self->error_handler(
      "Can't call delete before headers are bound");
  foreach my $field (@_) {
    if (exists $field_pos->{$field}) {
      delete $field_pos->{$field};
    }
    else {
      $self->error_handler(
        "Cannot delete field '$field': it doesn't exist");
    }
  }
}

sub error_handler {
  my $self = shift;
  $self->{error_handler}->(@_);
}

sub extract {
  my $self = shift;
  my $cached_results = $self->{cached} ||= {};
  my $in_compute = $self->{in_compute} ||= {};
  my $row = $self->{row} or return $self->error_handler(
    "No row found (did you call get_row())?");
  my $lookup = $self->{field_pos}
    or return $self->error_handler(
      "Can't find field info (did you bind_fields or read_header?)");
  my @data;
  foreach my $field (@_) {
    if (exists $lookup->{$field}) {
      my $position_or_compute = $lookup->{$field};
      if (not ref($position_or_compute)) {
        push @data, $row->[$position_or_compute];
      }
      elsif (exists $cached_results->{$field}) {
        push @data, $cached_results->{$field};
      }
      elsif ($in_compute->{$field}) {
        $self->error_handler(
          "Infinite recursion detected in computing '$field'");
      }
      else {
        # Have to do compute
        $in_compute->{$field} = 1;
        $cached_results->{$field} = $position_or_compute->($self);
        push @data, $cached_results->{$field};
      }
    }
    else {
      my @allowed = sort keys %$lookup;
      $self->error_handler(
        "Invalid field $field for file '$self->{filename}'.\n" .
        "Valid fields are: (@allowed)\n"
      );
    }
  }
  return wantarray ? @data : \@data;
}

sub extract_hash {
  my $self = shift;
  my @fields = @_ ? @_ : $self->get_fields();
  my %hash;
  @hash{@fields} = $self->extract(@fields);
  wantarray ? %hash : \%hash;
}

sub fetchrow_hash {
  my $self = shift;
  return unless $self->get_row();
  $self->extract_hash(@_);
}

sub format_data {
  my $self = shift;
  my %data = @_;
  my @row;
  my $field_pos = $self->{field_pos} or $self->error_handler(
    "Can't find field info (did you bind_fields or read_header?)"
  );
  while (my ($field, $value) = each %data) {
    my $pos = $field_pos->{$field};
    if (defined($pos)) {
      $row[$pos] = $value;
    }
    else {
      $self->warning_handler("Ignoring unknown field '$field'");
    }
  }
  $self->{row} = \@row;
  my $header = $self->{header}
    or $self->error_handler("Cannot format_data when no header is set");
  $self->format_row( $self->extract( @$header ));
}

sub format_header {
  my $self = shift;
  if ($self->{header}) {
    return $self->format_row(@{$self->{header}});
  }
  else {
    $self->error_handler("Cannot format_header when no header is set");
  }
}

*format_headers = \&format_header;

sub format_row {
  my $self = shift;

  $self->{row_num}++;

  if ($self->{row_size_warning}) {
    if (not exists $self->{row_size}) {
      $self->{row_size} = @_;
    }
    elsif ( @_ != $self->{row_size}) {
      my $count = @_;
      $self->warning_handler(
        "Formatting $count fields at row $self->{row_num}, "
        . "expected $self->{row_size}"
      ); 
    }
  }

  my $sep = $self->{sep};
  my @row;
  foreach my $value (@_) {
    if (not defined($value)) {
      # Empty fields are undef
      push @row, $self->{quote_all} ? qq("") : "";
    }
    elsif ("" eq $value) {
      # The empty string has to be quoted unless dont_quote is set
      push @row, $self->{dont_quote} ? "" : qq{""};
    }
    elsif ($value =~ /\s|\Q$sep\E|"/) {
      # quote it
      local $_ = $value;
      s/"/""/g;
      # If dont_quote is set, just output the data element,
      # otherwise follow the 'proper' CSV quoted format (that breaks
      # MS SQL Server's bulk insert on date values)
      push @row, $self->{dont_quote} ? $_ : qq{"$_"};
    }
    else {
      # Unquoted is fine (that is, unless the quote_all option is set)
      push @row, $self->{quote_all} ? qq("$value") : $value;
    }
  }
  my $row = join $sep, @row;
  return $row . "\n";
}

sub get_fields {
  my $self = shift;
  my $field_pos = $self->{field_pos}
    or return $self->error_handler(
      "Can't call get_fields before headers are bound");
  return keys %$field_pos;
}

# Private block for shared variables in a small "parse engine".
# The concept here is to use pos to step through a string.
# This is the real engine, all else is syntactic sugar.
{
  my ($self, $fh, $line, $is_error);

  sub get_row {
    $self = shift;
    $is_error = 0;
    delete $self->{row};
    delete $self->{cached};
    delete $self->{in_compute};
    $fh = ($self->{fh}
      ||= $self->{filename}
        ? $self->open_file($self->{filename}, "<")
        : ($self->{filename} = "ARGV", \*ARGV)
        # Sorry for the above convoluted way to sneak in defining filename.
    );
    return unless $fh;
    defined($line = <$fh>) or return;
    if ($self->{filter}) {
      $line = $self->{filter}->($line);
    }
    chomp($line);
    my @row = _get_row();
    if ($is_error) {
      return @row[0..$#row];
    }
    if (not exists $self->{row_size}) {
      $self->{row_size} = @row;
    }
    elsif (not $self->{row_size_warning}) {
      # The user asked not to get this warning, so don't issue it.
    }
    elsif ($self->{row_size} != @row) {
      my $new = @row;
      my $where = "Line $., file $self->{filename}";
      $self->warning_handler(
        "$where had $new fields, expected $self->{row_size}" ); 
    }
    $self->{row} = \@row;
    return wantarray ? @row : [@row];
  }

  sub _get_row {
    my @row;
    my $q_sep = quotemeta($self->{sep});
    my $match_sep = qr/\G$q_sep/;
    my $start_field = qr/\G(")/;
    my $start_field_ms = qr/\G([^"$q_sep]*)/;

    # This loop is the heart of the engine
    while ($line =~ /$start_field/gc or $line =~ /$start_field_ms/gc ) {
      if ($1 eq '"') {
        push @row, _get_quoted();
      }
      else {
        # Needed for Microsoft compatibility
        push @row, length($1) ? $1 : undef;
      }
      my $pos = pos($line);
      if ($line !~ /$match_sep/g) {
        if ($pos == length($line)) {
          return @row;
        }
        elsif ($self->{strict}) {
          my $expected = "Expected '$self->{sep}'";
          $is_error = 1;
          return $self->error_handler(
            "$expected at $self->{filename}, line $., char $pos");
        }
        else {
          TRY: {
            my $expected = "Expected '$self->{sep}'";
            $self->warning_handler(
              "$expected at $self->{filename}, line $., char $pos");

            # Assume we are in non-strict mode and encountered a single "
            # so we need to recover and finish my quoted field.
            $row[-1] .= '"' . _get_quoted();
            $pos = pos($line);
            if ($line !~ /$match_sep/g) {
              if ($pos == length($line)) {
                return @row;
              }
              else {
                redo TRY;
              }
            }
          }
        }
      }
    }
    $is_error = 1;
    $self->error_handler(
      "I have no idea how parsing $self->{filename} left me here!");
  }

  sub _get_quoted {
    my $piece = "";
    my $start_line = $.;
    my $start_pos = pos($line);
  
    while(1) {
      if ($line =~ /\G([^"]+)/gc) {
        # sequence of non-quote characters
        $piece .= $1;
      } elsif ($line =~ /\G""/gc) {
        # replace "" with "
        $piece .= '"';
      } elsif ($line =~ /\G"/g) {
        # closing quote
        return $piece;  # EXIT HERE
      }
      else {
        # Must be at end of line
        $piece .= $/;
        unless(defined($line = <$fh>)) {
          croak(
            "File $self->{filename} ended inside a quoted field\n"
              . "Field started at char $start_pos, line $start_line\n"
          );
        }
        if ($self->{filter}) {
          $line = $self->{filter}->($line);
        }
        chomp($line);
      }
    }
    $is_error = 1;
    $self->error_handler(
      "I have no idea how parsing $self->{filename} left me here!");
  }
}

my @normal_accessors = qw(
  close_fh error_handler warning_handler filename filter fh
  row_size row_size_warning strict
);
foreach my $accessor (@normal_accessors) {
  no strict 'refs';
  *{"set_$accessor"} = sub {
    $_[0]->{$accessor} = $_[1];
  };
}

# These two are mutually exclusive
foreach my $accessor (qw(dont_quote quote_all)) {
  no strict 'refs';
  *{"set_$accessor"} = sub {
    my $self = shift;
    $self->{$accessor} = shift;
    if ($self->{dont_quote} and $self->{quote_all}) {
      $self->error_handler("Can't set both dont_quote and quote_all");
    }
  };
}

sub new {
  my $self = bless ({}, shift);
  my %allowed = map {
                  $_=>1
                } @normal_accessors, qw(
                  header headers row sep dont_quote quote_all
                );

  my %args = (
    error_handler => \&confess,
    filter => sub {my $line = shift; $line =~ s/\r$//; $line;},
    sep => ",",
    row_size_warning => 1,
    close_fh => 0,
    strict => 1,
    @_
  );
  # Note, must set error_handler and warning_handler first because they
  # might get called while processing the other args.
  foreach my $arg ('error_handler', 'warning_handler', keys %args) {
    unless (exists $allowed{$arg}) {
      my @allowed = sort keys %allowed;
      croak("Invalid argument '$arg', allowed args: (@allowed)");
    }
    my $method = "set_$arg";
    $self->$method($args{$arg});
  }
  return $self;
}

# Note the undocumented third argument for the mode.  Most of the time this
# will do what is wanted without requiring Perl 5.6 or better.  Users who
# supply their own metacharacters will also not be surprised at the result.
# Note the return of 0.  I cannot assume that the user's error handler dies...
sub open_file {
  my $self = shift;
  my $file = $self->{filename} = shift || return $self->error_handler(
    "No filename specified at open_file"
  );
  if ($file !~ /\||<|>/ and @_) {
    my $mode = shift;
    $file = "$mode $file";
  }
  my $fh = do {local *FH}; # Old trick, not needed in 5.6
  unless (open ($fh, $file)) {
    $self->error_handler("Cannot open '$file': $!");
    return 0;
  }
  $self->{close_fh} = 1;
  $self->{fh} = $fh;
}

sub print {
  my $self = shift;
  $self->{row_out}++;
  my $fh = ($self->{fh}
      ||= $self->{filename}
        ? $self->open_file($self->{filename}, ">")
        : ($self->{filename} = "STDOUT", \*STDOUT)
        # Sorry for the above convoluted way to sneak in defining filename.
      );
  return unless $fh;
  print $fh @_ or $self->error_handler( "Print #$self->{row_out}: $!" );
}

sub print_data {
  my $self = shift;
  $self->print($self->format_data(@_));
}

sub print_header {
  my $self = shift;
  $self->print($self->format_header(@_));
}

*print_headers = \&print_header;

sub print_row {
  my $self = shift;
  $self->print($self->format_row(@_));
}

sub set_header {
  my $self = shift;
  if (1 == @_ and UNIVERSAL::isa($_[0], 'ARRAY')) {
    $self->{header} = $_[0];
  }
  else {
    $self->{header} = \@_;
  }
  if (not exists $self->{field_pos}) {
    $self->bind_fields(@{$self->{header}});
  }
}

*set_headers = \&set_header;

sub set_sep {
  my $self = shift;
  my $sep = shift;
  # The reason for this limitation is so that $start_field in _get_row
  # will do what it is supposed to.  (I should use a negative lookahead,
  # but I'm documenting this late at night and want some sleep.)
  if (1 == length($sep)) {
    $self->{sep} = $sep;
  }
  else {
    $self->error_handler("The separator '$sep' is not of length 1");
  }
}

sub warning_handler {
  my $self = shift;
  if ($self->{warning_handler}) {
    $self->{warning_handler}->(@_);
  }
  else {
    eval { $self->{error_handler}->(@_) };
    warn $@ if $@;
  }
}

sub DESTROY {
  my $self = shift;
  if ($self->{close_fh}) {
    close($self->{fh}) or $self->error_handler(
      $! ? "Cannot close '$self->{filename}': $!"
         : "Exit status $? closing '$self->{filename}'"
    );
  }
}

1;

__END__

=head1 NAME

Text::xSV - read character separated files

=head1 SYNOPSIS

  use Text::xSV;
  my $csv = new Text::xSV;
  $csv->open_file("foo.csv");
  $csv->read_header();
  # Make the headers case insensitive
  foreach my $field ($csv->get_fields) {
    if (lc($field) ne $field) {
      $csv->alias($field, lc($field));
    }
  }
  
  $csv->add_compute("message", sub {
    my $csv = shift;
    my ($name, $age) = $csv->extract(qw(name age));
    return "$name is $age years old\n";
  });

  while ($csv->get_row()) {
    my ($name, $age) = $csv->extract(qw(name age));
    print "$name is $age years old\n";
    # Same as
    #   print $csv->extract("message");
  }

  # The file above could have been created with:
  my $csv = Text::xSV->new(
    filename => "foo.csv",
    header   => ["Name", "Age", "Sex"],
  );
  $csv->print_header();
  $csv->print_row("Ben Tilly", 34, "M");
  # Same thing.
  $csv->print_data(
    Age  => 34,
    Name => "Ben Tilly",
    Sex  => "M",
  );

=head1 DESCRIPTION

This module is for reading and writing a common variation of character
separated data.  The most common example is comma-separated.  However
that is far from the only possibility, the same basic format is
exported by Microsoft products using tabs, colons, or other characters.

The format is a series of rows separated by returns.  Within each row
you have a series of fields separated by your character separator.
Fields may either be unquoted, in which case they do not contain a
double-quote, separator, or return, or they are quoted, in which case
they may contain anything, and will encode double-quotes by pairing
them.  In Microsoft products, quoted fields are strings and unquoted
fields can be interpreted as being of various datatypes based on a
set of heuristics.  By and large this fact is irrelevant in Perl
because Perl is largely untyped.  The one exception that this module
handles that empty unquoted fields are treated as nulls which are
represented in Perl as undefined values.  If you want a zero-length
string, quote it.

People usually naively solve this with split.  A next step up is to
read a line and parse it.  Unfortunately this choice of interface
(which is made by Text::CSV on CPAN) makes it difficult to handle
returns embedded in a field.  (Earlier versions of this document
claimed impossible.  That is false.  But the calling code has to
supply the logic to add lines until you have a valid row.  To the
extent that you don't do this consistently, your code will be buggy.)
Therefore you it is good for the parsing logic to have access to the
whole file.

This module solves the problem by creating a xSV object with access to
the filehandle, if in parsing it notices that a new line is needed, it
can read at will.

=head1 USAGE

First you set up and initialize an object, then you read the xSV file
through it.  The creation can also do multiple initializations as
well.  Here are the available methods

=over 4

=item C<new>

This is the constructor.  It takes a hash of optional arguments.
They correspond to the following set_* methods without the set_ prefix.
For instance if you pass filename=>... in, then set_filename will be
called.

=over 8

=item C<set_sep>

Sets the one character separator that divides fields.  Defaults to a
comma.

=item C<set_filename>

The filename of the xSV file that you are reading.  Used heavily in
error reporting.  If fh is not set and filename is, then fh will be
set to the result of calling open on filename.

=item C<set_fh>

Sets the fh that this Text::xSV object will read from or write to.  If it
is not set, it will be set to the result of opening filename if that
is set, otherwise it will default to ARGV (ie acts like <>) or STDOUT,
depending on whether you first try to read or write.  The old default
used to be STDIN.

=item C<set_header>

Sets the internal header array of fields that is referred to in
arranging data on the *_data output methods.  If C<bind_fields> has
not been called, also calls that on the assumption that the fields
that you want to output matches the fields that you will provide.

The return from this function is inconsistent and should not be
relied on to be anything useful.

=item C<set_headers>

An alias to C<set_header>.

=item C<set_error_handler>

The error handler is an anonymous function which is expected to
take an error message and do something useful with it.  The
default error handler is Carp::confess.  Error handlers that do
not trip exceptions (eg with die) are less tested and may not work
perfectly in all circumstances.

=item C<set_warning_handler>

The warning handler is an anonymous function which is expected to
take a warning and do something useful with it.  If no warning
handler is supplied, the error handler is wrapped with C<eval>
and the trapped error is warned.

=item C<set_filter>

The filter is an anonymous function which is expected to
accept a line of input, and return a filtered line of output.  The
default filter removes \r so that Windows files can be read under
Unix.  This could also be used to, eg, strip out Microsoft smart
quotes.

=item C<set_quote_qll>

The quote_all option simply puts every output field into
double quotation marks.  This can't be set if C<dont_quote> is.

=item C<set_dont_quote>

The dont_quote option turns off the otherwise mandatory quotation marks
that bracket the data fields when there are separator characters, spaces
or other non-printable characters in the data field.  This is perhaps a
bit antithetical to the idea of safely enclosing data fields in
quotation marks, but some applications, for instance Microsoft SQL
Server's BULK INSERT, can't handle them.  This can't be set if
C<quote_all> is.

=item C<set_row_size>

The number of elements that you expect to see in each row.  It
defaults to the size of the first row read or set.  If
row_size_warning is true and the size of the row read or formatted
does not match, then a warning is issued.

=item C<set_row_size_warning>

Determines whether or not to issue warnings when the row read or set
has a number of fields different than the expected number.  Defaults
to true.  Whether or not this is on, missing fields are always read
as undef, and extra fields are ignored.

=item C<set_close_fh>

Whether or not to close fh when the object is DESTROYed.  Defaults
to false if fh was passed in, or true if the object has to open its
own fh.  (This may be removed in a future version.)

=item C<set_strict>

In strict mode a single " within a quoted field is an error.  In
non-strict mode it is a warning.  The default is strict.

=back

=item C<open_file>

Takes the name of a file, opens it, then sets the filename and fh.

=item C<bind_fields>

Takes an array of fieldnames, memorizes the field positions for later
use.  C<read_header> is preferred.

=item C<read_header>

Reads a row from the file as a header line and memorizes the positions
of the fields for later use.  File formats that carry field information
tend to be far more robust than ones which do not, so this is the
preferred function.

=item C<read_headers>

An alias for C<read_header>.  (If I'm going to keep on typing the plural,
I'll just make it work...)

=item C<bind_header>

Another alias for C<read_header> maintained for backwards compatibility.
Deprecated because the name doesn't distinguish it well enough from the
unrelated C<set_header>.

=item C<get_row>

Reads a row from the file.  Returns an array or reference to an array
depending on context.  Will also store the row in the row property for
later access.

=item C<extract>

Extracts a list of fields out of the last row read.  In list context
returns the list, in scalar context returns an anonymous array.

=item C<extract_hash>

Extracts fields into a hash.  If a list of fields is passed, that is
the list of fields that go into the hash.  If no list, it extracts all
fields that it knows about.  In list context returns the hash.  In
scalar context returns a reference to the hash.

=item C<fetchrow_hash>

Combines C<get_row> and C<extract_hash> to fetch the next row and return a
hash or hashref depending on context.

=item C<alias>

Makes an existing field available under a new name.

  $csv->alias($old_name, $new_name);

=item C<get_fields>

Returns a list of all known fields in no particular order.

=item C<add_compute>

Adds an arbitrary compute.  A compute is an arbitrary anonymous
function.  When the computed field is extracted, Text::xSV will call
the compute in scalar context with the Text::xSV object as the only
argument.

Text::xSV caches results in case computes call other computes.  It
will also catch infinite recursion with a hopefully useful message.

=item C<format_row>

Takes a list of fields, and returns them quoted as necessary, joined with
sep, with a newline at the end.

=item C<format_header>

Returns the formatted header row based on what was submitted with
C<set_header>.  Will cause an error if C<set_header> was not called.

=item C<format_headers>

Continuing the meme, an alias for format_header.

=item C<format_data>

Takes a hash of data.  Sets internal data, and then formats
the result of C<extract>ing out the fields corresponding to the
headers.  Note that if you called C<bind_fields> and then defined
some more fields with C<add_compute>, computes would be done for you
on the fly.

=item C<print>

Prints the arguments directly to fh.  If fh is not supplied but filename
is, first sets fh to the result of opening filename.  Otherwise it
defaults fh to STDOUT.  You probably don't want to use this directly.
Instead use one of the other print methods.

=item C<print_row>

Does a C<print> of C<format_row>.  Convenient when you wish to maintain
your knowledge of the field order.

=item C<print_header>

Does a C<print> of C<format_header>.  Makes sense when you will be
using print_data for your actual data because the field order is
guaranteed to match up.

=item C<print_headers>

An alias to C<print_header>.

=item C<print_data>

Does a C<print> of C<format_data>.  Relieves you from having to
synchronize field order in your code.

=back

=head1 TODO

Add utility interfaces.  (Suggested by Ken Clark.)

Offer an option for working around the broken tab-delimited output
that some versions of Excel present for cut-and-paste.

Add tests for the output half of the module.

=head1 BUGS

When I say single character separator, I mean it.

Performance could be better.  That is largely because the API was
chosen for simplicity of a "proof of concept", rather than for
performance.  One idea to speed it up you would be to provide an
API where you bind the requested fields once and then fetch many
times rather than binding the request for every row.

Also note that should you ever play around with the special variables
$`, $&, or $', you will find that it can get much, much slower.  The
cause of this problem is that Perl only calculates those if it has
ever seen one of those.  This does many, many matches and calculating
those is slow.

I need to find out what conversions are done by Microsoft products
that Perl won't do on the fly upon trying to use the values.

=head1 ACKNOWLEDGEMENTS

My thanks to people who have given me feedback on how they would like
to use this module, and particularly to Klaus Weidner for his patch
fixing a nasty segmentation fault from a stack overflow in the regular
expression engine on large fields.

Rob Kinyon (dragonchild) motivated me to do the writing interface, and
gave me useful feedback on what it should look like.  I'm not sure that
he likes the result, but it is how I understood what he said...

Jess Robinson (castaway) convinced me that ARGV was a better default
input handle than STDIN.  I hope that switching that default doesn't
inconvenience anyone.

Gyepi SAM noticed that fetchrow_hash complained about missing data at
the end of the loop and sent a patch.  Applied.

shotgunefx noticed that bind_header changed its return between versions.
It is actually worse than that, it changes its return if you call it
twice.  Documented that its return should not be relied upon.

Fred Steinberg found that writes did not happen promptly upon closing
the object.  This turned out to be a self-reference causing a DESTROY
bug.  I fixed it.

Carey Drake and Steve Caldwell noticed that the default
warning_handler expected different arguments than it got.  Both
suggested the same fix that I implemented.

Geoff Gariepy suggested adding dont_quote and quote_all.  Then found a
silly bug in my first implementation.

Ryan Martin improved read performance over 75% with a small patch.

Bauernhaus Panoramablick and Geoff Gariepy convinced me to add the
ability to get non-strict mode.

=head1 AUTHOR AND COPYRIGHT

Ben Tilly (btilly@gmail.com).  Originally posted at
http://www.perlmonks.org/node_id=65094.

Copyright 2001-2009.  This may be modified and distributed on the same
terms as Perl.
