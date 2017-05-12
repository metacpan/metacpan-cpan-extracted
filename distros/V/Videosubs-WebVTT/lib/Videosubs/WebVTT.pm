package Videosubs::WebVTT;
use Videosubs::WebVTTBlock;
use warnings;
use strict;

our $VERSION = '0.05';

# INSTANTIATE NEW WEBVTT OBJECT
# TAKES:	OPTIONAL VALUES: HEADER, FILENAME
# DOES:
#	CREATE NEW OBJECT
#	PARSES INCOMING FILE, IF APPLICABLE
# RETURNS:	NEWLY CREATED OBJECT
sub new {
 my $class = shift;
 my $self = {
  'header'	=> '',
  'filename'	=> '',
  @_
 };
 bless $self, $class;

 if ($self->webvtt_filename() ne '') {
  $self->parse_incoming_file();
 }
 return $self;
}

# GET/SET THE HEADER
sub webvtt_header {
 my $self = shift;
 if (scalar(@_) == 1)
  { $self->{'header'} = shift; }
 return $self->{'header'};
}

# GET/SET THE FILENAME
sub webvtt_filename {
 my $self = shift;
 if (scalar(@_) == 1)
  { $self->{'filename'} = shift; }
 return $self->{'filename'};
}

# PARSE AN INCOMING FILE.
# TAKES:	A WEBVTT OBJECT CALLER.
# DOES:		ADD WEBVTT BLOCK OBJECT(S) TO CALLER.
# RETURNS:
#	0 IF FILE DOES NOT EXIST.
#	0 IF FILE NOT READABLE.
#	1 IF FILE SUCCESSFULLY PARSED INTO ZERO OR MORE BLOCKS
sub parse_incoming_file {
 my $self = shift;
 my $incoming_file = $self->webvtt_filename();
 my $temp_webvtt_header = '';
 my @temp_webvtt_blocks_array = ();
 unless (-e $incoming_file) {
  warn "Could not find $incoming_file - $!\n";
  return 0;
 }

 my $block_count = 0;
 my $current_block = '';
 my $incoming_fh;
 unless (open ($incoming_fh, '<', $incoming_file)) {
  warn "Failed to open $incoming_file - $!\n";
  return 0;
 }

 my $found_header = 0;
 while (my $single_line = <$incoming_fh>) {
  chomp $single_line;
  $single_line =~ s/^\s+(\S)*\s+$/$1/i;
  # IF WE GET TO A BLANK LINE, PROCESS STUFF IF NEEDED
  if ($single_line eq '') {
   # IF NEEDED, PROCESS A HEADER:
   if ($found_header == 0) {
    if ($current_block ne '') {
     # ONCE WE FIND A HEADER, STORE IT AND RESET THE VARIOUS COUNTERS.
     $temp_webvtt_header = $current_block;
     $found_header = 1;
     $current_block = '';
     next;
    }
    else {
     # IF WE DON'T HAVE A VALID $current_block THEN IT'S JUST AN OPENING BLANK LINE; SKIP.
     next;
    } # END: elsif, meaning we have a blank line and no data yet
   } # END: IF WE HAVE NO HEADER
   my $new_block_object = parse_block($current_block);
   push @temp_webvtt_blocks_array, $new_block_object;
   $current_block = '';
   $block_count++;
  } # END: IF $single_line IS BLANK, MEANING WE HAVE A BLOCK TO PROCESS.
  else {
   # WE DON'T HAVE A BLANK LINE YET, SO KEEP ADDING THIS TO THE TEMP BLOCK.
   $current_block .= "$single_line\n";
  } # END else, MEANING WE DON'T HAVE A BLANK LINE.
  } # END WHILE LOOP, WHERE WE CYCLE THROUGH THE FILE
 my $new_block_object = parse_block($current_block);
 push @temp_webvtt_blocks_array, $new_block_object;
 $block_count++;
 $self->{'header'} = $temp_webvtt_header;
 $self->{'blocks'} = \@temp_webvtt_blocks_array;
 return 1;
}

# WE MUST HAVE A VALID HEADER, SO WE'RE JUST PARSING A BIT OF TEXT NOW:
sub parse_block {
 my $current_block = shift;
 my @all_lines = split("\n", $current_block);
 if (scalar @all_lines < 2) {
  warn "Not sure what to do with [$current_block] - it's less than two lines!\n";
  return 0;
 }

 my $temp_label = '';
 my $temp_date_line = '';

 # THE FIRST LINE CAN BE A LABEL OR A TIMESTAMP:
 my $first_line = shift(@all_lines);
 if ($first_line =~ /\d{2}(:\d{2})*([.]\d+)*(\s+[->]+\s+)\d{2}(:\d{2})([.]\d+)*/) {
  # THE FIRST LINE IS THE TIMESTAMP, SO THERE'S NO LABEL...
  $temp_label = '';
  $temp_date_line = $first_line;
 }
 else {
  $temp_label = $first_line;
  $temp_date_line = shift(@all_lines);
 }

 $temp_date_line =~ /([^- ]+)\s+\-\-\>\s+([^- ]+)/;
 my $temp_start_time = $1;
 my $temp_end_time = $2;
 my $temp_data = join("\n", @all_lines);
 my $new_block = Videosubs::WebVTTBlock->new(
  'label' => '',
  'start_time' => $temp_start_time,
  'end_time' => $temp_end_time,
  'data' => $temp_data
  );

#print "Attempting to create block with label, s, e, d: [$temp_label], [$temp_start_time], [$temp_end_time], [$temp_data]\n--\n";

 return $new_block;
}

# COUNT HOW MANY BLOCKS THIS OBJECT HAS.
sub count_blocks {
 my $self = shift;
 my @blocks = @{$self->{'blocks'}};
 my $num_blocks = scalar @blocks;
 return $num_blocks;
}

# PRINTS ENTIRE WEBVTT OBJECT.
sub printall {
 my $self = shift;
 my @all_blocks = @{$self->{'blocks'}};
 print $self->webvtt_header;
 foreach my $one_block (@all_blocks) {
  print "\n";
  print $one_block->printable_block();
 }
}

sub printall_srt {
 my $self = shift;
 my $counter =0;
 my @all_blocks = @{$self->{'blocks'}};
 foreach my $one_block (@all_blocks) {
  print "\n";
  print ++$counter . "\n";
  print $one_block->printable_srt();;
 }

}

1;
