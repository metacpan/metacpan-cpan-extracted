package WebVTTBlock;
use strict;
use warnings;

our $VERSION = '0.03';

#
# A WEBVTTBLOCK IS A SINGLE ENTITY THAT LOOKS (WHEN DISPLAYED) SOMETHING LIKE THIS:
###########################################
# 1
# 00:00:01.000 --> 00:00:02.00
# YOU CAN SEE HERE THE DEATH START ORBITING
###########################################
# A TYPICALY WEBVTT FILE IS MADE UP OF HUNDREDS OR MORE OF THESE.  THIS MODULE
# ALLOWS YOU TO CREATE AND VALIDATE THESE BLOCKS MORE EASILY.
#

# OBJECT CONSTRUCTOR:
sub new {
 my $class = shift;
 my $self = {
  'label'	=> '',
  'start_time'	=> '',
  'end_time'	=> '',
  'data'	=> '',
  @_
 };
 bless $self, $class;
 if ($self->block_start_time() ne '') {
  unless ($self->validate_time($self->block_start_time()))
   { warn "Could not validate START time!\n"; }
 }
 if ($self->block_end_time() ne '') {
  unless ($self->validate_time($self->block_end_time()))
   { warn "Could not validate END time!\n"; }
 }
 return $self;
}

# GET/SET THE LABEL
sub block_label {
 my $self = shift;
 if (scalar(@_) == 1)
  { $self->{'label'} = shift; }
 return $self->{'label'};
}

# GET/SET THE START TIME
sub block_start_time {
 my $self = shift;
 if (scalar(@_) == 1)
  { $self->{'start_time'} = shift; }
 return $self->{'start_time'};
}

# GET/SET THE END TIME
sub block_end_time {
 my $self = shift;
 if (scalar(@_) == 1)
  { $self->{'end_time'} = shift; }
 return $self->{'end_time'};
}

# GET/SET THE DATA
sub block_data {
 my $self = shift;
 if (scalar(@_) == 1)
  { $self->{'data'} = shift; }
 return $self->{'data'};
}

# VALIDATE A TIME ATTRIBUTE (START OR END).
sub validate_time {
 my $self = shift;
 my $test_time = shift;
 my @h_m_s = split (':', $test_time);
 if ((scalar @h_m_s < 1) || (scalar @h_m_s > 3)) {
  # A VALID TIME MUST HAVE AT LEAST 1 AND AT MOST 3 PARTS (HOURS, MINUTES, SECONDS)
  return 0;
 }
 for (@h_m_s) {
  if (($_ < 0) || ($_ > 59)) {
   # A VALID HOUR, MINUTE, OR SECOND SHOULD BE BETWEEN 0 AND 59 INCLUSIVE.
   return 0;
  }

  # NEED TO ADD CODE HERE TO SPLICE OFF ALL BUT THE "SECONDS" AND VALIDATE IT'S AN INTIGER.
  # THE SECONDS CAN HAVE .000 THROUGH .999 MS APPENDED TO IT.
  for (my $index_counter =0; $index_counter < (scalar @h_m_s) -1; $index_counter++) {
   unless ($h_m_s[$index_counter] =~ /^\d{2}$/) {
    # AN HOUR OR MINUTE MUST BE NOTHING OTHER THAN TWO DIGITS
    # die "current H/M entry [$h_m_s[$index_counter]] did not match regex...\n";
    return 0;
   } # END: UNLESS BLOCK
  } # END: FOR BLOCK TO CYCLE THROUGH HOURS AND MINUTES, BUT NOT SECONDS

  my $second_entry = $h_m_s[scalar @h_m_s -1];
  unless ($second_entry =~ /^\d{2}([.]\d{1,3})*$/) {
   # THE SECOND ENTRY MUST BE TWO DIGITS, OPTIONALLY FOLLOWED BY UP TO THREE DIGITS REPRESENTING MILISECONDS
   # die "seconds entry [$second_entry] did not match regex...\n";
   return 0;
  } # END: UNLESS BLOCK TO VALIDATE THE SECONDS ENTRY
 } # END: validate_time() SUBROUTINE

 my @find_ms_array = split('.', $test_time);
 if (scalar @find_ms_array > 1) {
 }
 return 1;
}

# RETURN A BLOCK OF TEXT SUITABLE FOR PRINTING:
sub printable_block {
 my $self = shift;
 my $block_label = $self->block_label();
 my $block_start_time = $self->block_start_time();
 my $block_end_time = $self->block_end_time();
 my $block_data = $self->block_data();
 my $printable_block = '';
 if ($block_label ne '') {
  $printable_block .= "$block_label\n";
 }
 $printable_block .= "$block_start_time --> $block_end_time\n";
 $printable_block .= "$block_data\n";
 return $printable_block;
}

sub convert_time_to_srt {
 my $self = shift;
 my $incoming_time = shift;
 my ($hours, $minutes, $seconds, $milliseconds);
 # REMOVE ANY MILLISECOND VALUE:
 my @remove_milliseconds = split(/\./, $incoming_time);
 if (scalar @remove_milliseconds > 1) {
  $milliseconds = pop @remove_milliseconds;
 }
 else {
  $milliseconds = '000';
 }
 # WHATEVER IS LEFT AFTER REMOVING MILLISECONDS IS THE H:M:S.
 my @time_pieces = split(/:/,$remove_milliseconds[0]);

 if (scalar @time_pieces > 2)
  { $hours = shift @time_pieces; }
 else
  { $hours = '00'; }

 if (scalar @time_pieces > 1)
  { $minutes = shift @time_pieces; }
 else
  { $minutes = '00'; }

 if (scalar @time_pieces > 0)
  { $seconds = shift @time_pieces; }
 else
  { $seconds = '00'; }

 my $time_in_srt = $hours . ":" . $minutes . ":" . $seconds . "," . $milliseconds;
 return $time_in_srt; 
}

# CONVERTS THE BLOCK TO .srt FORMAT
# TAKES:	THE NUMBER TO USE AS THE "LABEL" FIELD.
# RETURNS:	A PRINTABLE TEXT BLOB WITH THE DATA FROM THE BLOCK.
sub printable_srt {
 my $self = shift;
 my $label_number = shift;
 my $block_start_time =	$self->convert_time_to_srt($self->block_start_time());
 my $block_end_time =	$self->convert_time_to_srt($self->block_end_time());
 my $block_data = $self->block_data();
 my $printable_block = '';
 $printable_block .= "$block_start_time --> $block_end_time\n";
 $printable_block .= "$block_data\n";
 return $printable_block;
}

1;
