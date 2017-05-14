package TieFile;

use Symbol;
use strict;
# The object constructed in TIEARRAY is a list, and these are the
# fields
my $F_OFFSETS    = 0;  # List of file seek offsets (for each line)
my $F_FILEHANDLE = 1;  # Open filehandle

sub TIEARRAY {
   my ($pkg, $filename) = @_;
   my $fh = gensym();
   open ($fh, $filename) || die "Could not open file: $!\n";
   bless [  [0],  # 0th line is at offset 0
            $fh
         ], $pkg;
}

sub FETCH {
   my ($obj, $index) = @_;
   # Have we already read this line?
   my $rl_offsets = $obj->[$F_OFFSETS];
   my $fh = $obj->[$F_FILEHANDLE];
   if ($index > @$rl_offsets) {
       $obj->read_until ($index);
   } else {
       # seek to the appropriate file offset
       seek ($fh, $rl_offsets->[$index], 0); 
   }
   scalar<$fh>;
}

sub STORE {
   die "Sorry. Cannot update file using package ListFile\n";
}

sub DESTROY {
   my ($obj) = @_;
   # close the filehandle
   close($obj->[$F_FILEHANDLE]);
}

sub read_until {
   my ($obj, $index) = @_;
   my $rl_offsets = $obj->[$F_OFFSETS];
   my $last_index = @$rl_offsets - 1;
   my $last_offset = $rl_offsets->[$last_index];
   my $fh = $obj->[$F_FILEHANDLE];
   seek ($fh, $last_offset, 0); 
   my $buf;
   while (defined($buf = <$fh>)) {
      $last_offset += length($buf);
      $last_index++;
      push (@$rl_offsets, $last_offset);
      last if $last_index > $index;
   }
}

1;

if (!caller) {
    # Testing code
    my @list;
    # Map this file itself over @list 
    tie @list, 'TieFile', 'TieFile.pm'; 
    my $i;

    for ($i = 10; $i >= 0; --$i) {
        print "Line $i ", $list[$i];
    }
}
