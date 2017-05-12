
# Time-stamp: "2004-04-03 20:20:51 ADT"
require 5;
package Text::Shoebox;
use strict;
use integer; # we don't need noninteger math in here
use Carp qw(carp croak);
use vars qw(@ISA @EXPORT $Debug $VERSION %p);
require Exporter;
require UNIVERSAL;
@ISA = qw(Exporter);
@EXPORT = qw(read_sf write_sf are_hw_keys_uniform are_hw_values_unique);

$Debug = 0 unless defined $Debug;
$VERSION = "1.02";

=head1 NAME

Text::Shoebox - read and write SIL Shoebox Standard Format (.sf) files

=head1 SYNOPSIS

  use Text::Shoebox;
  my $lex = [];
  foreach my $file (@ARGV) {
    read_sf(
      from_file => $file, into => $lex,
    ) or warn "read from $file failed\n";
  }
  print scalar(@$lex), " entries read.\n";
  
  die "hw field-names differ\n"
   unless are_hw_keys_uniform($lex);
  warn "hw field-values aren't unique\n"
   unless are_hw_values_unique($lex);
  
  write_sf(from => $lex, to_file => "merged.sf")
   or die "Couldn't write to merged.sf: $!";

=head1 DESCRIPTION

The Summer Institute of Linguistics (C<http://www.sil.org/>) makes a
piece of free software called "the Linguist's Shoebox", or just
"Shoebox" for short.  It's a simple database program generally used
for making lexicon databases (altho it can also be used for databases
of field notes, etc.).

Shoebox can export its databases to SF (Standard Format) files, a
simple text format.  Reading and writing those SF files is what this
Perl module, Text::Shoebox, is for.  (I have heard that Standard Format
predates Shoebox quite a bit, and is used by other programs.  If you
use SF files with something other than Shoebox, I'd be interested in
hearing about it, particularly about whether such files and
Text::Shoebox are happily compatible.)

=head1 OBJECT-ORIENTED INTERFACE

This module provides a functional interface.  If you want an
object-oriented interface, with a bit more convenience, then see
the classes L<Text::Shoebox::Lexicon> and  L<Text::Shoebox::Entry>.


=head1 FUNCTIONS

=over

=item $lex_lol = read_sf(...options...)

Reads entries in Standard Format from the source specified.  If no
entries were read, returns false.  Otherwise, returns a reference to
the array that the entries were added to (which will be a new array,
unless the "into" option is set).  If there's an I/O error while reading
(like if you specify an unreadable file), then this routine dies.

The options are:

=over

=item from_file => STRING

This specifies that the source of the SF data is a file, whose
filespec is given.

=item from_handle => FILEHANDLE

This specifies that the source of the SF data is a given filehandle.
(Examples of filehandle values: a global filehandle passed either
like C<*MYFH{IO}> or C<*MYFH>; or an object value from an IO class like
IO::Socket or IO::Handle.)

The filehandle isn't closed when all its data is read.

=item rs => STRING

This specifies that the given string should be used as the record
separator (newline string) for the data source being read from.

If the SF source is specified by a "from_file" option, and you don't
specify an "rs" option, then Text::Shoebox will try guessing the line
format of the file by reading the first 2K of the file and looking for
a CRLF ("\cm\cj"), an LF ("\cj"), or a CR ("\cm").  If you need to
stop it from trying to guess, just stipulate an "rs" value of C<$/>.

If the SF source is specified by a "from_handle" option, and you don't
specify an "rs" option, then Text::Shoebox will just use the value in
the Perl variable C<$/> (the global RS value).

=item into => ARRAYREF

If this option is stipulated, then entries read will be pushed to the
end of the array specified.  Otherwise the entries will be put into a
new array.

=back

Example use:

  use Text::Shoebox;
  my $lexicon = read_sf(from_file => 'foo.sf')
   || die "No entries?";
  print scalar(@$lexicon), " entries read.\n";
  print "First entry has ",
   @{ $lexicon->[0] } / 2 , " fields.\n";

=cut

sub read_sf {
  my(%options) = @_;

  my($target);
  if(exists $options{'into'} ) {
    $target = $options{'into'};
  } else {
    $target = [];
  }

  local $/ = $/;
  my($fh, $to_close);
  if( exists $options{'from_handle'}) {
    $fh = $options{'from_handle'};
    $/ = $options{'rs'} if exists $options{'rs'};
     # otherwise use default $/ value
  } elsif(exists $options{'from_file'}) {
    local *IN;
    my $from_file = $options{'from_file'};
    open(IN, "<$from_file") or croak "Can't read-open $from_file: $!";
    binmode(IN);
    $fh = *IN{IO};
    $to_close = 1;

    if(exists $options{'rs'}) {
      $/ = $options{'rs'};
    } else {
      my $chunk;
      read($fh, $chunk, 2048); # should be plenty long enough!
      seek($fh, 0,0); # rewind
      
      # All the NL formats I know about...
      if(defined $chunk and $chunk =~ m<(\cm\cj|\cm|\cj)>s) {
        $/ = $1;
      } else {
        print "Couldn't set \$/ for some reason.\n" if $Debug;
        # Otherwise let it stand.
      }
    }
  } else {
    croak "read_sf needs an option specifying input source";
  }

  print "\$/ is ", unpack("H*", $/), "\n" if $Debug;

  #my $lines_so_far = 0;
  my $line;  # current line
  my $hw_field;  # set from the first real field name we see
  my @new_entries;  # to fill up with new things from this file
  my $Debug = $Debug; # lexical for speed
  my $last_field_was_comment = 0;

  while(defined($line = <$fh>)) {
    chomp($line);
    #next if !defined($hw_field) and
    ##   ++$lines_so_far == 1 and
    if(length $line > 1 and substr($line,0,2) eq '\_') {
      $last_field_was_comment = 1;
      next;
    }

    if($line =~ m<^\\(\S+) ?(.*)>s) {  # It's a normal "\foo val" line...
      # This is the typical line in typical .sf files

      # That RE matches either "\foo" or "\foo bar..."
      # (Because the \S+ stops either at end-of-string, or at ' '.
      # Note that in either case, $2 is never undef.

      print "<$line> parses as <$1> = <$2>\n" if $Debug > 1;
      $last_field_was_comment = 0;
      if(@new_entries) {
        if($1 eq $hw_field) { # it's a non-initial new entry
          # A new entry means that the preceding entry's last value got
          #  one too many \n's at the end.  So chop it.
          # (Assumes "\n" is a single byte long; safe, I hope.)
          chop($new_entries[-1][-1])
            if substr($new_entries[-1][-1], -1, 1) eq "\n";

          # Start off a new entry
          push @new_entries, [$1, $2];
        } else {
          push @{$new_entries[-1]}, $1, $2;
           # This is all that happens to typical lines:
           # Just tack more items to the end of the last entry.
        }
      } else { # No entries seen yet
        $hw_field = $1;
        # First field ever seen (ignoring _sh).
        # That must be the headword field!  Note it as such.

        # Now start off a new entry (the first, it so happens)
        push @new_entries, [$1, $2];
      }

    } else { # It's a continuation line...
      next if $last_field_was_comment; # just toss this.

      print "<$line> is a continuation line.\n" if $Debug > 1;
      if(@new_entries) { # expected case!
        $line =~ s<^ \\><\\>s;
         # Continuations starting with '\' get a leading space put on
         #  the front them -- so take it off.  (Even tho it could have
         #  originated as a real ' \'.)
         
        $new_entries[-1][-1] .= "\n" . $line;
         # So, yes, newline in the file ($/) turns into "\n".
         # Tack this line onto the end of the last value in the last new entry
         
      } else { # most unexpected -- continuation of nothing!
        warn "line \"$line\" is a continuation, but of what?"
          if $line =~ m<\S>s;
         # (but forgive such things if they're pure whitespace)
      }
    } # end of continuation line
  } # end while() over the lines
  
  close($fh) if $to_close;
  
  print "All read: ", scalar(@new_entries), " entries read.\n" if $Debug;
  
  return 0 unless @new_entries;
  
  push @$target, @new_entries;
  
  return $target;
}

#--------------------------------------------------------------------------

=item write_sf(...options...)

This writes the given lexicon, in Standard Format, to the destination
specified.  If all entries were written, returns true; otherwise (in
case of an IO error), returns false, in which case you should
check C<$!>.  Note that this routine I<doesn't> die in the case of
an I/O error, so you should always check the return value of this
function, as with:

  write_sf(...) || die "Couldn't write: $!";

The options are:

=over

=item from => ARRAYREF

This option must be present, to specify the lexicon that you want to
write out.

=item to_file => STRING

This specifies that the SF data is to be written to the file
specified.  (Note that the file is opened in overwrite mode, not
append mode.)

=item to_handle => FILEHANDLE

This specifies that the destination for the SF data is the given
filehandle.

The filehandle isn't closed when all the data is written to it.

=item rs => STRING

This specifies that the given string should be used as the record
separator (newline string) for the SF data written.

If not specified, defaults to "\n".

=back

=cut

sub write_sf {
  my(%options) = @_;
  my $from;
  if(exists $options{'from'}) {
    $from = $options{'from'};
  } else {
    croak("'from' should be a reference")
     unless defined $from and ref $from;
  }

  my($fh, $to_close);
  if(exists $options{'to_handle'}) {
    $fh = $options{'to_handle'};
    print "Writing to $fh from object $from\n" if $Debug;
  } elsif(exists $options{'to_file'}) {
    # passed a filespec
    local *OUT;
    my $dest = $options{'to_file'};
    print "Writing to $dest from object $from\n" if $Debug;
    open(OUT, ">$dest") or return 0;
    $fh = *OUT{IO};
    binmode($fh);
  } else {
    croak "write_sf needs either a to_handle or a to_file option";
  }

  my $nl;
  if(exists $options{'rs'}) {
    $nl = $options{'rs'};
    # Some sanity checks:
    croak "rs can't be undef" unless defined $nl;
    croak "rs can't be empty-string" unless length $nl;
    croak "rs can't be a reference" if ref $nl;
  } else {
    $nl = "\n";
  }

  my $qnl = quotemeta $nl;

  my $nl_is_weird = 0;
  $nl_is_weird = 1 unless $nl =~ m<^[\cm\cj]+$>s;

  my $am_first_entry = 1;
  my($k, $v, $i, $i_entry, $e); # scratch vars

 Entry:
  for($i_entry = 0; $i_entry < @$from; ++$i_entry) {
    unless(defined(
      $e = $from->[$i_entry]  # copy the entry ref
     ) and (
       ref $e eq 'ARRAY'
       or UNIVERSAL::isa($e, 'ARRAY')
     )
    ) {
      print "Skipping $e -- not an entry\n" if $Debug;
      Carp::cluck "Skipping $e -- not an entry";
      next Entry;
    }
    unless(@$e) {
      print "Skipping $e -- a null entry\n" if $Debug;
      next Entry;
    }

    if($am_first_entry) {
      $am_first_entry = undef;  # do nothing but turn it off.
    } else {  # print a NL before every entry except the first
      return 0 unless print $fh $nl;
    }

   Field:
    for($i = 0; $i < @$e; $i += 2) { # iterate across keys
      unless(defined(
        $k = $e->[$i]  # copy the key
       ) and length $k
      ) {
        next Field;
      }

      if($nl_is_weird) {
        $k =~ s<$qnl><>g; # basic attempt at sanity.
        $k =~ tr< ><>d;
         # Up to the user to keep [\cm\cj\t] out of the keys!
      } else {
        $k =~ tr<\cm\cj\t ><>d; # basic sanity for any sane NL value
      }

      unless(length $k) {
        carp "Key field in lexicon->[ $i_entry ][ $i ] is null!\n" if $Debug;
        next Field;
      }

      if(defined(
        $v = $e->[1 + $i]  # copy value
      )) {
        if(length $v) {
          $v =~ s<\n\\><\n \\>g;
          $v =~ s<\n><$nl>g if $nl ne "\n"; # swap NL
        }
      } else {
        $v = '';
      }

      return 0 unless   # return if there's an error in printing
       length($v) ? (print $fh "\\", $k, ' ', $v, $nl)   # "\foo bar" + NL
                  : (print $fh "\\", $k, $nl)            # "\foo"     + NL
      ;
    }
  }
  close($fh) if $to_close;
  return 1;
}

#--------------------------------------------------------------------------

=item are_hw_keys_uniform($lol)

This function returns true iff all the entries in the lexicon have the
same key for their headword fields (i.e., the first field per record).
This will always be true if you read the lexicon from one file; but if
you read it from several, it's possible that the different files have
different keys marking headword fields.

=cut

sub are_hw_keys_uniform {
  carp('Wrong number of arguments to are_hw_keys_uniform'), return 0
   unless @_ == 1;
  my $lex = $_[0];
  $Debug && carp('Argument to are_hw_keys_uniform isn\'t a listref'), return 0
   unless defined $lex and ref $lex eq 'ARRAY';
  $Debug && carp('Empty lexicon to are_hw_keys_uniform'), return 0
   unless @$lex;

  my($hw_key, $e, $i);
  for(my $i = 0; $i < @$lex; ++$i) {
    next unless @{$e = $lex->[$i]}; # just skip null entries, I guess.
    $Debug && carp("Entry $i has an undef headword"), return 0
     unless defined $e->[0];
    if(defined($hw_key)) {
      if($e->[0] ne $hw_key) {
        carp("Entry $i\'s hw key \"" . $e->[0] .
          "\" differs from previous hw key \"$hw_key\"") if $Debug;
        return 0;
      }
    } else {
      $hw_key = $e->[0];
    }
  }
  $Debug && carp("Entry $i\'s hw key \"" . $e->[0]), return 0
   unless defined $hw_key;
  
  return 1; # all fine.
}

#--------------------------------------------------------------------------

=item are_hw_values_unique($lex_lol)

This function returns true iff all the headword values in all non-null
entries in the lexicon $lol are unique -- i.e., if no two (or more)
entries have the same values for their headword fields.  I don't know
if uniqueness is a requirement for SF lexicons that you'd want to
import into Shoebox, but some tasks you put lexicons to might require
it.

=cut

sub are_hw_values_unique {
  my %seen;
  foreach my $e (@{$_[0]}) {
    return 0 if @$e and $seen{  defined($e->[1]) ? $e->[1] : ''  }++;
  }
  return 1; # no duplicates found
}

#--------------------------------------------------------------------------
%p = (
  ( map {; (chr($_), sprintf('\x%02X',$_)) }  0.. 255 ),
  "\a" => '\a', # ding!
  "\b" => '\b', # BS
  "\e" => '\e', # ESC
  "\f" => '\f', # FF
  "\t" => '\t', # tab
  "\cm" => '\cm',
  "\cj" => '\cj',
  "\n" => '\n', # presumably overrides one of either \cm or \cj
  '"' => '\"',
  '\\' => '\\\\',
  '$' => '\\$',
  '@' => '\\@',
  '%' => '\\%',
  '#' => '\\#',
);

sub _dump {
  my $lol = $_[0];

  print "[   #", scalar(@$lol), " entries...\n";

  my $safe;
  my $toggle = 0;
  foreach my $e (@$lol) {
    next unless defined $e and ref $e and UNIVERSAL::isa($e, 'ARRAY');
    print "  [ ";
    foreach my $v (@$e) {
      ($safe = $v) =~ 
              s<([^\x20\x21\x23\x27-\x3F\x41-\x5B\x5D-\x7E\xA1-\xFE])>
               <$p{$1}>eg;
      print(
        ($toggle ^= 1) ? qq{"$safe" => } : qq{"$safe", \n    } 
      );
    }
    print "],\n";
  }
  print "];\n";
}

#--------------------------------------------------------------------------

=back

=head1 A NOTE ABOUT VALIDITY

I make very few assumptions about what characters can be in a field
key in SF files.  Just now, I happen to assume they can't start with
an underscore (lest they be considered comments), and can't contain
any whitespace characters.

I make essentially no assumptions about what can be in a field value,
except that there can be no newline followed immediately by a
backslash.  (Any newline-backslash sequence in turned into
newline-space-backslash.)

You should be aware that Shoebox, or whatever other programs use SF
files, may have a I<much> more restricted view of what can be in a
field key or value.

=head1 SEE ALSO

L<Text::Shoebox::Lexicon>

L<Text::Shoebox::Entry>

=head1 COPYRIGHT

Copyright 2000-2004, Sean M. Burke C<sburke@cpan.org>, all rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke, C<sburke@cpan.org>

Please contact me if you find that this module is not behaving
correctly.  I've tested it only on Shoebox files I generate on my own.

I hasten to point out, incidentally, that I am not in any way
affiliated with the Summer Institute of Linguistics.

=cut

1;

__END__
