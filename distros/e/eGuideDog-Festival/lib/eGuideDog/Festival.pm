# This package is developped on the base of the package of Speech::Festival, which is written by Richard Caley
# I add some wrapper to make it easier to use without knowing SCHEME language
# It is a part of eGuideDog project (http://e-guidedog.sourceforge.net)
# Author: Cameron Wong (hgn823-eguidedog002 at yahoo.com.cn)

package eGuideDog::Festival;

our $VERSION = '0.11';

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
use FileHandle;
use Socket;
use IPC::Open2;

sub new;
sub DESTROY;
sub execute_command;
sub speak;
sub block_speak;
sub play;
sub output;
sub pause;
sub resume; # continue speaking
sub stop;
sub close;
sub mode;
sub is_playing;
sub voice_list;
sub get_voice;
sub set_voice;
sub duration_stretch;
sub volume;
sub pitch;
sub range;
sub reset;
sub record_file;
sub recording;
###
sub new_client;
sub conn;
sub detach;
sub disconnect;
sub request;
sub wait_for_result;
sub result_waiting;
sub get_result;
sub handle_results;
sub waitforsomthing;
sub myread_n;
sub myread_upto;
sub parse_scheme;

@ISA = qw(Exporter);
@EXPORT = qw(
	     );

#*speech_error = *main::synth_error;
our $end_key='ft_StUfF_key';

our $OK='OK';
our $ERROR='ER';
our $SCHEME='LP';
our $WAVE='WV';

my $mode = 'article';
my @speech_spooler;
my @sentences_spooler;
my @words_spooler;
my $festival_pid = undef;

sub new {
  my ($self, $host, $port) = @_;

#  $child_pid = fork();

#  if (! defined $child_pid) {
#    die('Fail to fork!');
#  } elsif ($child_pid) { # parent
#    $speech_pipe->writer();
#   $speech_pipe->autoflush();

#    $self = {};
#  } else { # child
    if ($host && $port) {
      $self = new_client($host, $port);
    } else {
      $festival_pid = open2(*FESTIVAL_OUT, *FESTIVAL_IN, 'festival --server');
      CORE::close(FESTIVAL_IN);
      $self = new_client();
    }
    if (<FESTIVAL_OUT>) {
      # check whether server is successfully started
      return undef if (!conn($self));
    } else {
      return undef if (!conn($self));
    }

    # switch to async mode
    execute_command($self, "(audio_mode 'async)");

#    $speech_pipe->reader();
#    while (<$speech_pipe>) {
#      chomp;
#      execute_command($self, $_);
#      block_speak($self, $_);
#    }
#    &DESTROY($self);
#    exit(0);
#  }

  return $self;
}

sub DESTROY {
  my ($self) = @_;

#  if ($child_pid) {
#    kill INT => $child_pid;
#    close($speech_pipe) if ($speech_pipe);
#    waitpid($child_pid, 0);
#  } else {

    disconnect($self);
    CORE::close(FESTIVAL_OUT);# if (defined *FESTIVAL_OUT);
    kill(15, $festival_pid);
    waitpid($festival_pid, 0);
#  }
}

sub execute_command {
  my ($self, $command) = @_;

  # SayText
  if ($command =~ /^[(]SayText /) {
    request($self, $command);
    my ($type, $data) = get_result($self);
    if ($type ne $eGuideDog::Festival::SCHEME
	&& ($data !~ /^#<Utterance /)) {
      warn("Fail to $command");
    }
    ($type, $data) = get_result($self);
    if ($type ne $eGuideDog::Festival::OK) {
      warn("Fail to $command");
    }
  }

  # async mode
  elsif ($command eq "(audio_mode 'async)") {
    request($self, $command);
    my ($type, $data) = get_result($self);
    chomp($data);
    if ($type ne $eGuideDog::Festival::SCHEME
	|| $data ne 'async') {
      warn("Fail to async");
    }
    ($type, $data) = get_result($self);
    if ($type ne $eGuideDog::Festival::OK) {
      warn("Fail to async!");
    }
  }
}

sub speak {
  my ($self, $text) = @_;
  $text =~ s/\\/\\\\/g;
  $text =~ s/"/\\"/g;

  request($self, "(SayText \"$text\")");
  my ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::SCHEME
      && ($data !~ /^#<Utterance /)) {
    warn("Fail to speak!");
  }
  ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::OK) {
    warn("Fail to speak!");
  }
#  print $speech_pipe "(SayText \"$text\")\n";
}

sub block_speak {
  my ($self, $text) = @_;
  $text =~ s/\\/\\\\/g;
  $text =~ s/"/\\"/g;

  # wait and close audio stream first
  request($self, "(audio_mode 'close)");
  my ($type, $data) = get_result($self);
  chomp($data);
  if ($type ne $eGuideDog::Festival::SCHEME
      || $data ne 'close') {
    warn("Fail to close!");
  }
  ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::OK) {
    warn("Fail to close!");
  }

  # sync
  request($self, "(audio_mode 'sync)");
  ($type, $data) = get_result($self);
  chomp($data);
  if ($type ne $eGuideDog::Festival::SCHEME
      || $data ne 'sync') {
    warn("Fail to sync");
  }
  ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::OK) {
    warn("Fail to sync!");
  }

  # speak
  request($self, "(SayText \"$text\")");

  ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::SCHEME
      && ($data !~ /^#<Utterance /)) {
    warn("Fail to speak $text!");
  }
  ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::OK) {
    warn("Fail to speak $text!");
  }

  # async
  request($self, "(audio_mode 'async)");
  ($type, $data) = get_result($self);
  chomp($data);
  if ($type ne $eGuideDog::Festival::SCHEME
      || $data ne 'async') {
    warn("Fail to async");
  }
  ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::OK) {
    warn("Fail to async!");
  }
}

sub play {
  my ($self, $filename) = @_;
  $filename =~ s/\\/\\\\/g;
  $filename =~ s/"/\\"/g;

  request($self, "(utt.play (utt.synth (eval (list (quote Utterance) (quote Wave) \"$filename\"))))");
  my ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::SCHEME
      && ($data !~ /^#<Utterance /)) {
    warn("Fail to play!");
  }
  ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::OK) {
    warn("Fail to play!");
  }
}

sub output {
  my ($self, $text, $filename) = @_;
  $text =~ s/\\/\\\\/g;
  $text =~ s/"/\\"/g;
  $filename =~ s/\\/\\\\/g;
  $filename =~ s/"/\\"/g;

  request($self, "(utt.save.wave (utt.synth (eval (list (quote Utterance) (quote Text) \"$text\"))) \"$filename\")");
  my ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::SCHEME
      && ($data !~ /^#<Utterance /)) {
    warn("Fail to output $text to $filename:($type, $data)");
  }
  ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::OK) {
    warn("Fail to output $text to $filename:($type, $data)");
  }
}

sub pause {}

# continue speaking
sub resume {}

sub stop {
  my $self = shift;

  request($self, "(audio_mode 'shutup)");
  my ($type, $data) = get_result($self);
  chomp($data);
  if ($type ne $eGuideDog::Festival::SCHEME
      || $data ne 'shutup') {
    warn("Fail to shutup:($type, $data)");
  }
  ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::OK) {
    warn("Fail to shutup:($type, $data)");
  }
}

sub close {
  my $self = shift;

  request($self, "(audio_mode 'close)");
  my ($type, $data) = get_result($self);
  chomp($data);
  if ($type ne $eGuideDog::Festival::SCHEME
      || $data ne 'close') {
    warn("Fail to close!");
  }
  ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::OK) {
    warn("Fail to close!");
  }
}

# Mode can be changed from a new speech or after a pause.
# When it stops, call 'continue' method to go on reading.
# Modes are applied on 'async audio mode' but not 'sync audio mode'
#
# here are the modes:
#   article - no stop
#   paragraph - stop at new line.
#   sentence - stop at '.'
#   clause - stop at ',' and '.'
#   word - stop at every word
#   letter - stop at every letter
#   spell - spell a word (letter and word)
sub mode {
  my ($self, $mode) = @_;

  if ($mode ne 'article'
      && $mode ne 'paragraph'
      && $mode ne 'sentence'
      && $mode ne 'clause'
      && $mode ne 'word'
      && $mode ne 'letter'
      && $mode ne 'spell') {
    return 0;
  }

  $eGuideDog::Festival::mode = $mode;
  return 1;
}

sub is_playing {
  if (open(my $DSP, '>', '/dev/dsp')) {
    CORE::close($DSP);
    return 0;
  } else {
    return 1;
  }
}

sub language_list {}

sub get_language {}
sub set_language {}

sub voice_list {
  my $self = shift;

  request($self, '(voice.list)');
  my ($type, $data) = get_result($self);
  if ($type eq $eGuideDog::Festival::SCHEME) {
    my ($list) = parse_scheme($data);
    ($type, $data) = get_result($self);
    if ($type ne $eGuideDog::Festival::OK) {
      warn("Fail to get voice list!");
      return undef;
    }
    return @$list;
  } else {
    warn("Fail to get voice list!");
    ($type, $data) = get_result($self);
    return undef;
  }
}

sub get_voice {}

sub set_voice {
  my ($self, $name) = @_;

  # check whether voice exists
  my @voices = voice_list($self);
  my $exist = 0;
  foreach (@voices) {
    if ($name eq $_) {
      $exist = 1;
      last;
    }
  }
  return undef if (! $exist);

  request($self, "(voice.select '$name)");
  my ($type, $data) = get_result($self);
  if ($type eq $eGuideDog::Festival::SCHEME) {
    chomp($data);
    if ($data eq $name) {
      ($type, $data) = get_result($self);
      if ($type ne $eGuideDog::Festival::OK) {
	warn("Fail to set voice:($type, $data)");
	return undef;
      } else {
	return $name;
      }
    }
  } else {
#    warn("Fail to set voice:($type, $data)");
    return undef;
  }
}

sub styles {}
sub get_style {}
sub set_style {}

sub duration_stretch {
  my ($self, $stretch) = @_;

  if (defined $stretch) {
    return 0 if ($stretch <= 0 || $stretch > 10);
    request($self, "(Parameter.set 'Duration_Stretch $stretch)");
    my ($type, $data) = get_result($self);
    if ($type eq $eGuideDog::Festival::SCHEME) {
      chomp($data);
      my ($type2, $data2) = get_result($self);
      if ($type2 ne $eGuideDog::Festival::OK) {
	warn("Fail to set duration stretch!");
	return undef;
      } else {
	return $data;
      }
    } else {
      warn("Fail to set duration stretch!");
      return undef;
    }
  } else {
    request($self, "(Parameter.get 'Duration_Stretch)");
    my ($type, $data) = get_result($self);
    if ($type eq $eGuideDog::Festival::SCHEME) {
      chomp($data);
      my ($type2, $data2) = get_result($self);
      if ($type2 ne $eGuideDog::Festival::OK) {
	warn("Fail to get duration stretch!");
	return undef;
      } else {
	return $data;
      }
    } else {
      warn("Fail to get duration stretch!");
      return undef;
    }
  }
}

sub volume {
}

sub pitch {
  my ($self, $pitch) = @_;

  if (defined $pitch) {
    return 0 if ($pitch <=0 || $pitch > 1000);
    request($self, "
            (let ((model_mean (cadr (assoc 'model_f0_mean int_lr_params)))
                  (model_std  (cadr (assoc 'model_f0_std int_lr_params)))
                  (new_std (cadr (assoc 'target_f0_std int_lr_params))))
                 (set! int_lr_params
                  (list
                   (list 'target_f0_mean $pitch)
                   (list 'target_f0_std  new_std)
                   (list 'model_f0_mean  model_mean)
                   (list 'model_f0_std   model_std)
                  )
                 )
            )");
    my ($type, $data) = get_result($self);
    if ($type eq $eGuideDog::Festival::SCHEME) {
      chomp($data);
      my ($type2, $data2) = get_result($self);
      if ($type2 ne $eGuideDog::Festival::OK) {
	warn("Fail to get pitch:($type2, $data2)");
	return undef;
      }
      return $data;
    } else {
      warn("Fail to get pitch:($type, $data)");
      return undef;
    }
  } else {
    request($self, "(cadr (assoc 'target_f0_mean int_lr_params))");
    my ($type, $data) = get_result($self);
    if ($type eq $eGuideDog::Festival::SCHEME) {
      chomp($data);
      my ($type2, $data2) = get_result($self);
      if ($type2 ne $eGuideDog::Festival::OK) {
	warn("Fail to get pitch:($type2, $data2)");
	return undef;
      }
      return $data;
    } else {
      warn("Fail to get pitch:($type, $data)");
      return undef;
    }
  }
}

sub range {
  my ($self, $range) = @_;

  if (defined $range) {
    return 0 if ($range <=0 || $range > 1000);
    request($self, "
            (let ((model_mean (cadr (assoc 'model_f0_mean int_lr_params)))
                  (model_std  (cadr (assoc 'model_f0_std int_lr_params)))
                  (new_mean (cadr (assoc 'target_f0_mean int_lr_params))))
                 (set! int_lr_params
                  (list
                   (list 'target_f0_mean new_mean)
                   (list 'target_f0_std  $range)
                   (list 'model_f0_mean  model_mean)
                   (list 'model_f0_std   model_std)
                  )
                 )
            )");
    my ($type, $data) = get_result($self);
    if ($type eq $eGuideDog::Festival::SCHEME) {
      chomp($data);
      my ($type2, $data2) = get_result($self);
      if ($type2 ne $eGuideDog::Festival::OK) {
	warn("Fail to set range:($type2, $data2)");
	return undef;
      }
      return $data;
    } else {
      warn("Fail to set range:($type, $data)");
      return undef;
    }
  } else {
    request($self, "(cadr (assoc 'target_f0_std int_lr_params))");
    my ($type, $data) = get_result($self);
    if ($type eq $eGuideDog::Festival::SCHEME) {
      chomp($data);
      my ($type2, $data2) = get_result($self);
      if ($type2 ne $eGuideDog::Festival::OK) {
	warn("Fail to get range:($type2, $data2)");
	return undef;
      } else {
	return $data;
      }
    } else {
      warn("Fail to get range:($type, $data)");
      return undef;
    }
  }
}

sub reset {
  my $self = shift;

  request($self, "(voice_reset)");
  my ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::SCHEME) {
    warn("Fail to reset!");
    return undef;
  }
  ($type, $data) = get_result($self);
  if ($type ne $eGuideDog::Festival::OK) {
    warn("Fail to reset voice!");
  }
}

sub record_file {}
sub recording {}
sub history_size {}
sub speak_again {}


###### Below is orginal code in Speech::Festival #####
sub new_client
{
    my ($host, $port) = @_;

    $host ||= 'localhost';
    $port ||= 1314;
#    my ($self) = [ $host, $port, $eGuideDog::Festival::nextstream++, {} ];
    my ($self) = [ $host, $port, new FileHandle, {} ];

    return bless $self, __PACKAGE__;
}

sub conn
{
    my ($self) = @_;
    my ($host, $port, $s, $prop) = @$self;

    my($iaddr, $paddr, $proto);

    unless ($iaddr   = inet_aton($host))
	{
#	$speech_error = "no host: $host - $!";
	return 0;
	die;
	}

    $paddr   = sockaddr_in($port, $iaddr);

    $proto   = getprotobyname('tcp');

    unless(socket($s, PF_INET, SOCK_STREAM, $proto))
	{
#	$speech_error = "socket: $!";
	return 0;
	die;
	}

    unless(connect($s, $paddr))
	{
#	$speech_error = "connect: $!";
	return 0;
	die;
	}

    my ($old) = select($s);
    $|=1;
    select($old);

    $$prop{C}=1;

    return $s;
}

sub disconnect
{
    my ($self) = @_;

    my ($host, $port, $s, $prop) = @$self;

    if (defined($$prop{C}) && $$prop{C})
      {
	eval { local $SIG{PIPE} = 'IGNORE'; CORE::close($s); }
      }
    $$prop{C}=0;
}

sub detach
{
    my ($self) = @_;

    &DESTROY($self);

    bless $self, "destroyed Festival";
}

sub request
{
    my ($self, $scheme, $handler, @info) = @_;
    my ($host, $port, $s) = @$self;

#    print "request: $scheme\n";

    print $s "$scheme\n";

    if (defined($handler))
	{
	return handle_results($s, $handler, @info);
	}
}

sub wait_for_result

{
    my ($self, $time) = @_;
    my ($host, $port, $s) = @$self;

    return waitforsomething($s, $time);
}

sub result_waiting

{
    my ($self) = @_;
    my ($host, $port, $s) = @$self;

    return waitforsomething($s, 0);
}

sub get_result

{
    my ($self) = @_;
    my ($host, $port, $s);

    if (ref($self))
	{
	($host, $port, $s) = @$self;
	}
    else
	{
	$s = $self;
	}

    my ($type) = '';

    if (myread_n($s, $type, 3) != 3)
	{
#	$speech_error = "Error reading type - $!";
	return undef;
	}

    chomp $type;
    return ($type, 'void')
	if $type eq $OK || $type eq $ERROR;

    my ($data) = '';

    if (myread_upto($s, $data, $end_key) < 0)
	{
#	$speech_error = "Error reading data - $!";
	return undef;
	}

    return ($type, $data);
}

sub handle_results
{
    my ($s, $handler, @info) = @_;
    my ($nres)=0;
    my ($state);

    while (1)
	{
	my ($type, $data) = get_result $s;
	
	if (!defined($type))
	    {
	    return undef;
	    }
	
	$state = &$handler($type, $data, @info);

	if ($type eq $OK)
	    {
	    $state=$nres;
	    last;
	    }
	elsif ($type eq $ERROR)
	    {
	    $state=-1;
	    last;
	    }
	$nres++;
	}
    return $state;
}

# simple look-ahead IO

my $buffer='';
my $bend=0;

sub waitforsomething
{
    my ($s, $time) = @_;

    if (length($buffer) > 0)
	{
	return 1;
	}

    my ($rin, $rout) = '';
    vec($rin, fileno($s), 1) = 1;

    return select($rout = $rin, undef, undef, $time);
}

sub myread_n
{
    my ($s, $b, $n) = @_;

    while ($bend < $n)
	{
	my ($nr) = sysread($s, $buffer, 1000-$bend, $bend);
	$bend += $nr
	    if defined($nr);
	}

    $_[1] = substr($buffer, 0, $n);
    $buffer = substr($buffer, $n);
    $bend -= $n;
    return $n;
}

sub myread_upto
{
    my ($s, $b, $key) = @_;

    my ($checkfrom, $keyat) = 0;

    while (($keyat=index($buffer, $key, $checkfrom)) <0)
	{
	$checkfrom = $bend-length($key)
	    if $bend > length($key);

	my ($nr) = sysread($s, $buffer, 10000, $bend);
	$bend += $nr;
	}

    $_[1] = substr($buffer, 0, $keyat);
    $buffer = substr($buffer, $keyat+length($key));
    $bend -= $keyat+length($key);
    return length($_[1]);
}

# parse scheme

my $scheme_token = '^\\s*(("([^\\]"|[^"]|\s)*")|([-a-zA-Z0-9_+]+)|(\')|(\()|(\)))\\s*';

sub parse_scheme
  {
    my ($text) = @_;

    my ($scheme);

    if ($text eq '')
      {
	return (undef, "");
      }
    elsif ($text =~ /$scheme_token/om)
      {
	my ($tok, $str, $strcont, $atom, $sq, $open, $close, $tail) = 
	  ($1, $2, $3, $4, $5, $6, $7, $');

#	print "XXX", join("//", ($tok, $str, $strcont, $atom, $sq, $open, $close, $tail)), "\n";

	if (defined($str))
	  {
	    return ($str, $tail);
	  }
	elsif (defined($atom))
	  {
	    return ($atom, $tail);
	  }
	elsif (defined($sq))
	  {
	    my ($quoted, $ttail) = parse_scheme($tail);

	    return ([ 'quote', $quoted ], $ttail);
	  }
	elsif (defined($open))
	  {
	    my ($list) = [];

	    while (1)
	      {
		my ($item, $ttail) = parse_scheme($tail);

		$tail = $ttail;

		last
		  if !defined($item) || $item eq ')';

		push(@$list, $item);
	      }
	    
	    return ($list, $tail);
	  }
	elsif (defined($close))
	  {
	    return ($close, $tail);
	  }
      }

    return (undef, substr($text,1));
  }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

eGuideDog::Festival - Wrapper of common functions of Festival TTS.

=head1 VERSION

Version 0.1

=head1 SYNOPSIS

  use eGuideDog::Festival;

  $speaker = eGuideDog::Festival::new();
  $speaker->block_speak("hello world");

=head1 DESCRIPTION

This package provides simple way to use Festival speech synthesis system without knowing Scheme language.

=head1 METHODS

=head2 new($host, $port)

$host and $port are the Festival server host address and port number. A new server will be launched automaticly if these arguments are not specified. But you should make sure that Festival is installed on the system.

=head2 speak($text)

Speak text. This can be interrupted.

=head2 block_speak($text)

Speak text and wait until it finished.

=head2 play($filename)

Play wav file.

=head2 output($text, $filename)

Synthesize a wav file from text.

=head2 stop()

Stop speaking or playing. This will not affect block_speak method.

=head2 close()

Wait until all speech finished.

=head2 is_playing()

Return 1 for playing while 0 for not playing. I just check whether /dev/dsp is being used. So it doesn't work in all cases.

=head2 voice_list()

Return an array of voice list.

=head2 set_voice($voice)

Change the current voice. the value of $voice should exist in the returned array of voice list.

=head2 duration_stretch($value)

Return the current value of duration stretch if $value is omited.
$value between 0 to 1 makes speech slower.
$value larger than 1 makes speech faster.
Of course, 1 is the normal speed.

=head2 pitch($value)

Return the current value of voice pitch if $value is omited. Otherwise, set it.

=head2 range($value)

Return the current value of voice range if $value if omited. Otherwise, set it.

=head1 EXAMPLE


  use eGuideDog::Festival;

  $| = 1; # You cannot print message in time without this.

  $festival = eGuideDog::Festival::new();

  $festival->block_speak('You must wait until I finished this sentence.');
  $festival->speak('Thank you for your patience. You can intterupt me now.');
  sleep(1);
  $festival->stop() if ($festival->is_playing());

  # you can change some voice style, but I suggest saving there value first
  $festival->duration_stretch(1.5);
  $pitch = $festival->pitch();
  $festival->pitch(200);
  $range = $festival->range();
  $festival->range(200);
  $festival->speak('hello world');

  # this is the original voice style
  $festival->duration_stretch(1);
  $festival->pitch($pitch);
  $festival->range($range);
  $festival->speak('hello world');

  $festival->close(); # without this call, festival will die immediately without finishing the words.

=head1 SEE ALSO

L<Speech::Festival>, L<Festival::Client::Async>, L<Festival::Client>, L<Speech::Festival::Synthesiser>

=head1 AUTHOR

Cameron Wong, C<< <hgn823-eguidedog002 at yahoo.com.cn> >>, L<http://e-guidedog.sourceforge.net>

=head1 BUGS

This module may only work on Linux/Unix operating system.

In some documents, the symbol "'" is interpreted as Chinese symbol not the single quote. So copy and paste code may not always work. It seems a bug of some auto-generating tools. I am still wondering why.

Please report any bugs or feature requests to
C<bug-eguidedog-festival at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=eGuideDog-Festival>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc eGuideDog::Festival

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/eGuideDog-Festival>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/eGuideDog-Festival>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=eGuideDog-Festival>

=item * Search CPAN

L<http://search.cpan.org/dist/eGuideDog-Festival>

=back

=head1 ACKNOWLEDGEMENTS

This program is developped basing on Richard Caley's L<Speech::Festival>.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Cameron Wong, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of eGuideDog::Festival
