package Win32::MIDI;

use 5.006;
use strict;
use warnings;

use Time::HiRes qw/sleep/;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our $VERSION = '0.2';

bootstrap Win32::MIDI $VERSION;

# Preloaded methods go here.

sub new {
 
 my $class = shift;
 my $self = {};
 bless($self,$class);
 
 if($self->_init(@_)) {
    return($self);
    } else {
        return(undef);
        }
}



sub _init {

 my $self = shift;
 my $opt_HR = shift;
 
 $self->{'erRx1'} = undef;
 $self->{'device'} = undef;
 $self->{'note'} = ();
 $self->{'channel'} = ();
 $self->{'use_dyn_octave'} = undef;
 $self->{'null'} = "\x00";
 
 $self->{'special_names'} = ();
 my $sRef = \%{ $self->{'special_names'} };

 $sRef->{1} = "System Exclusive";
 $sRef->{2} = "MTC Quarter Frame";
 $sRef->{3} = "Song Position Pointer";
 $sRef->{4} = "Song Select";
 $sRef->{5} = "Undefined";
 $sRef->{6} = "Undefined";
 $sRef->{7} = "Tune Request";
 $sRef->{8} = "EOX";
 $sRef->{9} = "Timing Clock";
 $sRef->{10} = "Undefined";
 $sRef->{11} = "Start";
 $sRef->{12} = "Continue";
 $sRef->{13} = "Stop";
 $sRef->{14} = "Undefined";
 $sRef->{15} = "Active Sensing";
 $sRef->{16} = "System Reset";
 
 $self->_create_values();
 $self->_create_note_map();
 
 return(1);
}



sub _create_values {

 my $self = shift;
 
 $self->{'channel'}{'on'} = ();
 $self->{'channel'}{'off'} = ();

 my $i = undef;
 
 foreach $i (0..127) {
	 $self->{'note'}{"$i"} = chr($i);
	 $self->{'velocity'}{"$i"} = chr($i);
	 }
 
 foreach $i (1..16) {
	my $rval = $i - 1;
	$self->{'channel'}{'on'}{"$i"} = chr(0x90 + $rval);
	$self->{'channel'}{'off'}{"$i"} = chr(0x80 + $rval);
	$self->{'polyphonic'}{"$i"} = chr(0xA0 + $rval);
	$self->{'cc'}{"$i"} = chr(0xB0 + $rval);
	$self->{'channel_aftertouch'}{"$i"} = chr(0xD0 + $rval);
	$self->{'pitch_wheel'}{"$i"} = chr(0xE0 + $rval);
	$self->{'special'}{"$i"} = chr(0xF0 + $rval);
	}
 
 return(1);
}



sub _create_note_map {

 my $self = shift;

 $self->{'note_name_map'} = ();
 my $sR = \%{ $self->{'note_name_map'} };

 my %map = ();
 $map{1} = 'C';
 $map{2} = 'C#';
 $map{3} = 'D';
 $map{4} = 'D#';
 $map{5} = 'E';
 $map{6} = 'F';
 $map{7} = 'F#';
 $map{8} = 'G';
 $map{9} = 'G#';
 $map{10} = 'A';
 $map{11} = 'A#';
 $map{12} = 'B';
 
 my $base = 0;
 my $start = -1;

 foreach (1..11) {
	 $sR->{$start} = ();
	 foreach my $i (1..12) {
		 last if($base > 127);
		 my $note_nm = lc($map{$i});
		 $sR->{$start}{"$note_nm"} = $base;
		 $base++;
		 }
	 $start++;
	 }
 	 
 return(1);
}




sub error {

 my $self = shift;

 $self->{'erRx1'} = $_[0] if(defined($_[0]));
 return($self->{'erRx1'});
}


sub reset_error {

 my $self = shift;
 $self->{'erRx1'} = undef;
 return(1);
}



sub note_map {

 my $self = shift; 
 return(\%{ $self->{'note_name_map'} });
}



sub system_common_map {

 my $self = shift;
 return(\%{ $self->{'special_names'} });
}



sub value_of {
	
 my $self = shift;

 my $type = lc(shift);
 my $arg1 = shift;
 my $arg2 = shift;


 if(defined($arg2)) {
	 return(undef) if(!exists($self->{"$type"}{lc($arg1)}{lc($arg2)}));
	 return($self->{"$type"}{lc($arg1)}{lc($arg2)});
	 } elsif(defined($arg1)) {
		 return(undef) if(!exists($self->{"$type"}{lc($arg1)}));
		 return($self->{"$type"}{lc($arg1)});
		 } else {
			 return(undef) if(!exists($self->{"$type"}));
			 return($self->{"$type"}) if(length($type > 0));
			 }

 return(undef); 
}



sub cur_octave {

 my $self = shift;

 my $dyn_oct = shift;

 if(defined($dyn_oct) && ($dyn_oct < 10 && $dyn_oct > -2)) {	 
	 $self->{'use_dyn_octave'} = $dyn_oct;
	 }
 
 return($self->{'use_dyn_octave'});
}



sub cur_channel {

 my $self = shift;

 my $channel = shift;

 if(defined($channel) && ($channel > 0 &&  $channel < 17)) {
	 $self->{'cur_channel'} = $channel;
	 }

 return($self->{'cur_channel'});
}



sub play_note {

 my $self = shift;
 
 my $note = shift;
 my $dur = shift;
 my $aRef = \@_;
  
 if(!defined($note) || !defined($dur)) {
	 $self->error("[play_note] ERROR: NOTE and DURATION Arguments Required!");
	 return(undef);
	 }

 if($dur !~ /^[\d\.]+$/) {
	 $self->error("[play_note] ERROR: DURATION Argument Must Be Numeric!");
	 return(undef);
	 }
 
 if(!exists($self->{'handle'}) || !defined($self->{'handle'})) {
	 $self->error("[play_note] ERROR: No Device Has Been Opened!  Please Utilize openDevice() First!");
	 return(undef);
	 }

 my $note_num = undef;
 
 if($note =~ /[a-z]/i) {
	 my $octave;
	 $octave = $aRef->[3];
	 if(!defined($octave)) {
		 $octave = $self->cur_octave();
		 if(!defined($octave)) {
			 $self->error("[play_note] ERROR: I cannot determine the Octave for Note $note");
			 return(undef);
			 }
		 }
	 $note_num = $self->value_of('note_name_map',$octave,$note);
	 if(!defined($note_num)) {
		 $self->error("[play_note] ERROR: I cannot determine a value for Note named $note under Octave $octave");
		 return(undef);
		 }
	 } else {
		 $note_num = $note;
		 }

 if($note_num < 0 || $note_num > 127) {
	 $self->error("[play_note] NOTE Value Must be in Range 0-127");
	 return(undef);
	 }
 
 my $velocity = (defined($aRef->[0])  && ($aRef->[0] >= 0 && $aRef->[0] <= 127)) ? $aRef->[0] : 127;
 my $channel = (defined($aRef->[1]) && ($aRef->[1] >= 1 && $aRef->[1] <= 16)) ? $aRef->[1] : $self->cur_channel();
 my $do_off = defined($aRef->[2]) ? $aRef->[2] : 1;
 
 $channel = defined($channel) ? $channel : 1;
 
 my $ch_dat_on = $self->value_of('channel','on',$channel);
 my $ch_dat_off = $self->value_of('channel','off',$channel);
 
 my $vel_dat = $self->value_of('velocity',$velocity);
 my $note_dat = $self->value_of('note',$note_num);

 my $data_on = "\x00" . $vel_dat . $note_dat . $ch_dat_on;
 my $data_off = "\x00" . $vel_dat . $note_dat . $ch_dat_off;

 
 $self->writeMIDI(unpack("N",$data_on));

 if($do_off == 0) {
	 return(1);
	 } else {
		 sleep($dur);
		 $self->writeMIDI(unpack("N",$data_off));
		 return(1);
		 }

 return(1); 
}



sub send_cc {

 my $self = shift;
 
 my $value = shift;
 my $data = shift;
 
 my $channel = shift;
  
 if(!defined($value) || !defined($data)) {
	 $self->error("[send_cc] ERROR: Arguments CCVALUE and CCDATA are Required");
	 return(undef);
	 }

 if(($value < 0 || $value > 127) || ($data < 0 || $data > 127)) {
	 $self->error("[send_cc] ERROR: Arguments CCVALUE and CCDATA Must be Within Range 0-127");
	 return(undef);
	 }
 
 if(!exists($self->{'handle'}) || !defined($self->{'handle'})) {
	 $self->error("[send_cc] ERROR: No Device Has Been Opened!  Please Utilize openDevice() First!");
	 return(undef);
	 }

 if(!defined($channel)) {
	 $channel = $self->cur_channel();
	 $channel = (defined($channel)) ? $channel : 1;
	 }

 my $chan_data = $self->value_of('cc',$channel);
 my $value_data = $self->value_of('note',$value);
 my $dat_data = $self->value_of('note',$data);

 my $send_data = "\x00" . $dat_data . $value_data . $chan_data;
 
 $self->writeMIDI(unpack("N",$send_data));

 return(1);
}


sub pitch_wheel {

 my $self = shift;
 my $val1 = shift;
 my $val2 = shift;
 my $channel = shift;

 if(!defined($val1) || !defined($val2)) {
	 $self->error("[pitch_wheel] ERROR: Arguments VALUE1 and VALUE2 are Required");
	 return(undef);
	 }

 if(($val1 < 0 || $val1 > 127) || ($val2 < 0 || $val2 > 127)) {
	 $self->error("[pitch_wheel] ERROR: Arguments VALUE1 and VALUE2 Must be in the Range 0-127");
	 return(undef);
	 }
 
 if(!exists($self->{'handle'}) || !defined($self->{'handle'})) {
	 $self->error("[pitch_wheel] ERROR: No Device Has Been Opened!  Please Utilize openDevice() First!");
	 return(undef);
	 }

 if(!defined($channel)) {
	 $channel = $self->cur_channel();
	 $channel = (defined($channel)) ? $channel : 1;
	 }

 my $pw_data = $self->value_of('pitch_wheel',$channel);
 my $val1_data = $self->value_of('note',$val1);
 my $val2_data = $self->value_of('note',$val2);

 my $send_data = "\x00" . $val2_data . $val1_data . $pw_data;
 $self->writeMIDI(unpack("N",$send_data));

 return(1); 
}
 
1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Win32::MIDI - Perl extension for writing to MIDI devices under Win32

=head1 SYNOPSIS

  use Win32::MIDI;

	# create new instance of the class, you need to create
	# a new object for every midi device you want to write to
	# at any given time.  You can only open a device once, so no
	# two objects can write to the same device at the same time.
	
  my $midi_obj = Win32::MIDI->new();

	# print number of available (writing) devices
	
  print $midi_obj->numDevices() . "\n";

	# open a device

  $midi_obj->openDevice(0);

	# set default channel

  $midi_obj->cur_channel(1);

	# play a note by absolute value (numeric)
	# middle C - 60
	# note,dur,velocity
	
  $midi_obj->play_note(60,2.5,127) || print $midi_obj->error() . "\n" and $midi_obj->reset_error();

	# set default octave (middle)
	
  $midi_obj->cur_octave(4);
  
	# play a note by relative name (note name)
	# middle C - 60
	# note,dur,velocity

  $midi_obj->play_note(C,2.5,127) || print $midi_obj->error() . "\n" and $midi_obj->reset_error();

	# close the device
	
  $midi_obj->closeDevice();

  
	## Low-Level Method -- Writing Directly To The Device,
	## Creating Your Own MIDI Messages


	# note_on event, channel 1 (0x90), velocity (127), note (127), null (0x00);
  my $data_on = "\x00\127\127\x90";	
	# note_off event, channel 1 (0x80), velocity (127), note (127), null (0x00);
   my $data_off  = "\x00\127\127\x80";

  $midi_obj->writeMIDI(unpack("N",$data_on));

  sleep(3);

  $midi_obj->writeMIDI(unpack("N",$data_off));
  

	# NOTE: Mixed-case methods warn() on error
	# Others use $obj->error();
	
=head1 DESCRIPTION

Win32::MIDI Version 0.2

Win32::MIDI serves as a driver for PERL to gain write access to a MIDI device.  This module is, in no way,
complete or expansive.  It does not currently provide access to reading data from a MIDI device.
It is intended to compliment such packages as Win32::Sound and MIDI-Perl (indeed, it would be quite nice
if it were more compatible with MIDI-Perl).  Win32::MIDI provides the ability to send Channel Control messages,
Pitch Wheel Changes, (some) SYSEX messages, Aftertouch, Notes, and a whole lot more to any available MIDI
output device on your system.  This module uses the Time::HiRes module to provide timing intervals of less than
a second.  This package is by no means complete, and can be expanded upon a great deal.  

You will need Win32::Sound if you wish to know anything about a device other than its number. (See the info on
 openDevice() below)

This module can be retrieved from http://www.digitalKOMA.com/church/projects/


=head1 METHODS

 new()

	Creates a new instance of the class.  Returns a blessed object upon success.

	Usage:

		my $object = Win32::MIDI::new();



 error()

	Returns the last set error message.  Returns undef() if no errors have occured.

	Usage:

		my $error = $object->error();



 reset_error()

	Resets the error message mechanism.  error() will now return undef.

	Always returns true (1).

	Usage:

		$object->reset_error();



 numDevices()

	Returns the number of available MIDIOUT devices on the system.
	For more information about these devices, you should use the Devices() method of Win32::Sound.

	This method, as all methods with mixed-case names do, utilizes croak() on errors.
	
	Usage:

		my $num_devices = $object->numDevices();



 openDevice NUM

	Opens a MIDI device, specified by NUM.
	NUM corresponds to the (x) portion of MIDIOUTx as returned by Win32::Sound::Devices().  This number
	should never be more than the number of devices returned by numDevices() minus 1.  You must open a
	device BEFORE you attempt to write any data to a MIDI device or close a device.  If you wish to open
	more than one device at a time, you must create another instance of this class to do so.

	This method, as all methods with mixed-case names do, utilizes croak() on errors.
	
	Usage:

		$object->openDevice(1);



 closeDevice()

	Closes the currently open device.

	This method, as all methods with mixed-case names do, utilizes croak() on errors.

	Usage:

		$object->closeDevice();



 play_note NOTE DURATION VELOCITY CHANNEL ON/OFF OCTAVE

	Sends a note_on event to an opened MIDIOUT device.  The following arguments may be supplied:

	NOTE		The note to play, can be an absolute note value (e.g.: 100) or relative name (e.g.: 'C')
	DURATION	A decimal representing how many seconds to play the note for.  May be less than 1.
	VELOCITY	(optional) The velocity value of the note being played, defaults to 127.
	CHANNEL	(optional) The channel to play the note on (1..16) checks cur_channel() if not supplied.
			Defaults to 1.
	ON/OFF	(optional) Specifies whether a note_off event should be sent at the end of DURATION.
			Boolean: 1 = send note_off event, 0 = do not send
	OCTAVE	(optional) Used in conjunction with a relative note name (e.g.: 'C'), specifies the octave the
			note falls in.  If not supplied, and a relative note name is used, will check cur_octave().  If
			no 'current octave' is set, then the method will fail.


	All arguments are positional.  That is to say, if you wish to supply OCTAVE, you must supply all
	other arguments.
	
	Returns true (1) on success, sets the value of error() and returns undef() on failure.

	Usage:

			# play note by absolute vlaue, and minimum arguments.
			
		if($object->play_note(60,.35)) {
			print("Note played.\n");
			} else {
				print $object->error() . "\n" and $object->reset_error();
				}

			# play note by relative name, specifying octave
			# middle C (c4), half a second duration full velocity, channel 1
			# with note_off event
			
		if($object->play_note('C',.5,127,1,1,4)) {
			print("Note played.\n");
			} else {
				print $object->error() . "\n" and $object->reset_error();
				}

			# use cur_octave and relative names for minimum arguments

			# cycle through octaves, playing C from each.

		my $nmRef = $object->note_map();
		
		foreach my $octave (sort { $a <=> $b } keys(%{ $nmRef })) {
			$object->cur_octave($octave);
			print("Octave is $octave\n");
			if($object->play_note('C',.5)) {
				print("\tPlayed C\n");
				} else {
					print $object->error() . "\n" and $object->reset_error();
					}
			}



 cur_octave OCTAVE

	Returns the current 'default' octave.  Sets the current 'default' octave if OCTAVE
	is supplied.	 Valid range for OCTAVE is -1..9. (unless you have redefined the Note
	Name Map, see note_map() below.)

	The 'default' octave is utilized when no OCTAVE argument is provided to the play_note()
	method and a relative note name (e.g.: 'C#') is utilized.

	This function always returns the currently set 'default' octave, and undef() if no
	'default' octave has been set.

	Usage:

		$object->cur_octave('3');
		my $octave = $object->cur_octave();



 cur_channel CHANNEL

	Returns the current 'default' channel.  Sets the current 'default' channel if CHANNEL
	is supplied.  Valid range for CHANNEL is 1..16.

	The 'default' channel is utilized when no CHANNEL argument is provided to the play_note()
	method.

	This function always returns the currently set 'default' channel, and undef() if no
	'default' channel has been set.

	Usage:

		$object->cur_channel('1');
		my $channel = $object->cur_channel();

		
 note_map()

	Returns a reference to the hash which represents the current mapping of note names to
	absolute note values, grouped by octave.  By changing the data within the reference, you can
	create new octaves, new note names, and more.  Note names can be anything you desire, octaves
	must be numeric.  You may define any number of octaves as well.

	The Note Map is accessed on every call to play_note() that utilizes a relative note name.

	For a read-only version of the note map, see value_of() method below.
	
	The structure of the note map is as follows:

	Top
		Octave
			Note
				Value
			Note
				Value
		Octave
			Note
				Value

	That is,

	%map = ();
	$map{4} = ();
	$map{4}{'c'} = 60;
	$map{4}{'c#'} = 61;
	$map{4}{'d'} = 62;

	It is useful to note, that all note names must be lower-cased, even though you can use any
	word to name a note, if you use any upper-cased characters, the note will not be retrievable.
	(This is to allow the use of any case when calling play_note(), see it's entry below)

	By default, the range of octaves is -1..9, where C4 is 60.
	 

	Usage:

	my $hRef = $object->note_map();

		# Print the	contents of the map

	foreach my $key (sort { $a <=> $b } keys(%{ $hRef })) {
		print("Octave $key:\n");
		foreach my $note (sort { $a cmp $b } keys(%{ $hRef->{"$key"} })) {
			my $abs_value = $hRef->{"$key"}{"$note"};
			print("\tNote: $note, Absolute Value: $abs_value\n");
			next;
			}
		next;
		}

		# create a new map

	%{ $hRef } = ();

		# group by 4 notes, using a, b, c, and d.  There are 0-127 	(128 total) possible
		# values.
	 
	 my $total_octaves = 128 / 4;
	 my $base_note_val = 0;
	 
	 for my $oct (1..$total_octaves) {
		 $hRef->{"$oct"} = ();
		 for my $note (a..d) {
			 last if($base_note_val > 127);
			 $hRef->{"$oct"}{"$note"} = $base_note_val;
			 $base_note_val++;
			}
		}


		# all calls to play_note() utilizing named notes will now use this note map.



 value_of NAME OPT1 OPT2

	Returns the stored value of a given data element in use by the module.  NAME is the name of the
	element you wish to receive, and OPT1 and OPT2 can be utilized to become more specific.  Not
	all names require, or can have OPT arguments.  NAME can be one of the following:

		note
		velocity
		cc
		channel
		channel_aftertouch
		polyphonic
		pitch_wheel
		special
		note_name_map
		null

	The data returned is read-only, and is of the type specified, all elements consist of a single byte
	except for generally described elements (lacking a specific target, i.e. OPT which specifies which
	value of the list of elements of that type to return, in which case a hash is returned).


	The following data elements can accept OPT2 arguments, and the possible values:

	
	channel		OPT1 = on|off	OPT2 = channel number [1..16]

		Returns the byte to use as a channel note on/off MIDI status.  Can
		also return the entire hash of a particular state (on/off) or both.
		
		e.g.:
			my $channel_1_on_byte = $object->value_of('channel','on',1);
			my $channel_4_off_byte = $object->value_of('channel','off',4);

	note_name_map	OPT1 = octave	OPT2 = note name

		Returns the mapping of relative note names to octaves and absolute note
		values.  Can return a single note's value, an entire octave, or the entire range
		of octaves.
		
		e.g.:
			my $c4_note_value = $object->value_of('note_name_map',4,'c');
			my $d_sharp_neg1 = $object->value_of('note_name_map',-1,'d#');

				See the note_map() method above for a writeable version of the
				note name map.


	Either of the above elements will return hashes if not given OPT2 or OPT1.
	OPT2 can only be supplied if OPT1 is.  Example:

		my %note_hash = ($object->value_of('note_name_map'));
		print $note_hash{4}{'d#'} . "\n";


		my $channel_off_hash = ($object->value_of('channel','off'));
		print $channel_off_hash{};


	The other elements are described here:

	note OPT1 = number [0..127]

		Returns the MIDI byte which represents a note event (to be combined with a channel
		on/off MIDI status byte and velocity value byte).  Returns a hash with 128 keys (0..127)
		if OPT1 is omitted.

	velocity OPT1 = value [0..127]

		Return the MIDI byte which represents a velocity level.  See note, above.  Returns a hash
		with 128 keys (0..127) if OPT1 is omitted.

	cc OPT1 = channel [1..16]

		Returns the MIDI byte which represents a MIDI Channel Control event.  To be used in
		creating MIDI CC commands.  Returns a hash with 16 keys (1..16) if OPT1 is omitted.

	channel_aftertouch OPT1 = channel (1..16)			

		Returns the MIDI byte which represents a MIDI Channel Aftertouch command.  Returns
		a hash with 16 keys (1..16) if OPT1 is omitted.

	polyphonic OPT1 = channel (1..16)

		Returns the MIDI byte which represents a MIDI Polyphonic Aftertouch command.  Returns
		a hash with 16 keys (1..16) if OPT1 is omitted.

	pitch_wheel OPT1 = channel (1..16)

		Returns the MIDI byte which represents a MIDI Pitch Wheel change.  Returns	a hash with 16
		keys (1..16) if OPT1 is omitted.

	special OPT1 = number	(1..16)

		Returns the MIDI byte which represents a MIDI special command, such as SYSEX or PLAY.
		Returns a hash with 16 keys (1..16) if OPT1 is omitted.

	null

		Returns the current value of a NULL byte.  This is used to construct and pad MIDI messages.
		If OPT1 is supplied, undef() will be returned.
		
		
	This method is used both internally and externally to access the raw data used to construct a
	MESSAGE for the low-level writeMIDI() method below.  You can utilize this method to avoid having
	to create your own data maps when sending out messages.

	

 send_cc CCVALUE CCDATA CHANNEL

	Sends a MIDI Channel Control message.  The following arguments are accepted:

	CCVALUE	Which Channel Control message to send.  Values range 0..127.  Each value
			typically maps to a function as defined by the MMA.  For example, Modulation
			Wheel position is value 33.  This determines what the contents of CCDATA may be.

	CCDATA	The data to send related to the Control Message specified by CCVALUE.  CCDATA
			is always numeric, and the maximum value is always 127.  CCVALUE determines what
			an appropriate value for CCDATA is.  For example, to move the Mod Wheel to position
			slightly below 'default', you'd use a CCVALUE of 33 and CCDATA of 62 (64 is roughly
			center, or 'default').

	CHANNEL	(optional) The channel to send a Control Message to.  If no CHANNEL is supplied, then
			cur_channel() is consulted.  Will default to 1 if no 'current channel' is set.

	Returns true (1) on success, sets the value of error() and return undef() on failure.

	Usage:

			# send an expression controller change, move it up, and then back down

		if($object->send_cc(11,68,1)) {
			print("Expression Controller Go Up\n");
			if($object->send_cc(11,50,1)) {
				print("Expression Controller Go Down\n");
				} else {
					print $object->error() . "\n" and $object->reset_error();
					}
			} else {
				print $object->error() . "\n" and $object->reset_error();
				}
				



 pitch_wheel VALUE1 VALUE2 CHANNEL

	Sends a pitch wheel change to specified CHANNEL.  Two values are used for changes
	of fine granularity.  The following arguments are accepted:

	VALUE1	The major value.  0-127.
	VALUE2	The minor value. 0-127.
	CHANNEL	(optional) The channel to send the Pitch Wheel change to.  If not supplied,
			cur_channel() is consulted.  Defaults to 1 if no 'current channel' has been set.

	The two (major + minor) VALUEs are used to allow for very fluid, human-like changes.  You
	can consider the MAJOR value (VALUE1) to be the 'large step' position, and the MINOR value
	(VALUE2) to be the 'small step' position.  That is, if we first chopped the total length the pitch
	wheel can move into 128 sections, we get the MAJOR value, if we then split each of those sections
	in 128 small sections, we'd have the minor value.  VALUE1, then, determines our 'big' steps, and
	VALUE2 determines our 'precise' movement within that 'step'.

	Returns true (1) on success, sets the value of error() and returns undef() on failure.

	Usage:

			# move pitchwheel up slightly (64/64 can be considered 'center', or unchanged)

		if($object->pitch_wheel(64,70,1)) {
			print("I moved it up slightly\n");
			} else {
				print $object->error() . "\n" and $object->reset_error();
				}

			# move pitchwheel down VERY far and then reset it.

		if($object->pitch_wheel(0,1,1)) {
			print("Dropped it down\n");
			if($object->pitch_wheel(64,64,1)) {
				print("Back to normal\n");
				} else {
					print $object->error() . "\n" and $object->reset_error();
					}
			} else {
				print $object->error() . "\n" and $object->reset_error();
				}



 writeMIDI MESSAGE

	Writes MESSAGE to the currently open MIDI device.
	Structure of MESSAGE comes from the midiOutShortMsg() function of Winmm.dll:

	A doubleword (long) message with the first byte of the message in the low-order byte.
	The message is packed as follows:

		Word		Byte			Usage
		High		High-order		Not used.
				Low-order		The second byte of MIDI data (when needed)
		Low		High-order		The first byte of MIDI data (when needed)
				Low-order		The MIDI Status

	This means that the format of MESSAGE must be an unsigned long in "network" order.

	To achieve this, you can create a string with the necessary values like this:

		my $string = "\x00\127\127\x90";

	Which mean:

		Not used data 		: NULL (\x00)
		Second MIDI Byte	: Velocity 127 (\127)
		First MIDI Byte		: Note 127 (\127)
		Status			: note_on channel 1 (\x90)

	Then, you must convert the string into an unsigned long, in network order:

		my $message = unpack("N",$string);

	For more information on the byte data for MIDI messages, see http://www.harmony-central.com/MIDI/Doc/

	This method, as all methods with mixed-case names do, utilizes croak() on errors.

	Usage:

		$object->writeMIDI($message);	


		
=head2 EXPORT

None.

=head1 AUTHOR

C. Church, E<lt>dolljunkie@digitalKOMA.comE<gt>

=head1 SEE ALSO

L<perl>, L<MIDI-Perl>, L<Win32::Sound>, L<MIDI>, L<http://www.harmony-central.com/MIDI/Doc/>

=cut
