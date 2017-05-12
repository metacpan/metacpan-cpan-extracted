package Uniden::BC75XLT;

$VERSION = "0.0.4";
sub Version { $VERSION; }

use strict;
use Device::SerialPort;

my %priMode = (0 => 'OFF', 1 => 'ON', 2 => 'PLUS ON', 3 => 'DND');
my %keyState = (0 => 'OFF', 1 => 'ON');
my %bandPlan = (0 => 'USA', 1 => 'CANADA');
my %scanGroup = (1 => 'OFF', 0 => 'ON');
my %chDLY = (0 => 'OFF', 1 => 'ON');
my %chPRI = (0 => 'OFF', 1 => 'ON');
my %chLOUT = (0 => 'UNLOCKED', 1 => 'LOCKOUT');
my %srchDirection = (0 => 'UP', 1 => 'DOWN');
my %ccAlarm = (0 => 'OFF', 1 => 'ON');
my %ccMode = (0 => 'OFF', 1 => 'PRIORITY', 2 => 'DND');
my %ccBand = (0 => 'VHF_LOW', 1 => 'AIR', 2 => 'VHF_HIGH', 4 => 'UHF');
my %ssBand = (
   1 => 'WX', 2 => 'POLICE', 3 => 'FIRE', 4 => 'MARINE',
   5 => 'RACE', 6 => 'AIR', 7 => 'HAM', 8 => 'RAIL', 9 => 'CB', 10 => 'OTHER'
);

sub new
{
   my $class = shift;
   my $device = shift;
   my %opts = @_;

   my $baudrate = $opts{baudrate} || 57600;

   my $port = Device::SerialPort->new($device) || return undef;
   $port->databits($opts{databits} || 8);
   $port->baudrate($opts{baudrate} || 57600);
   $port->parity($opts{parity} || "none");
   $port->stopbits($opts{stopbits} || 1);
   $port->handshake($opts{handshake} || "none");
   $port->read_const_time($opts{read_cost_time} || 1);

   my %o = (
      _port => $port,
      fatal => ($opts{fatal} || 0),
      echo =>  ($opts{echo} || 0),
      timeout =>  ($opts{timeout} || 999),
   );

   bless \%o, $class;
}

### public ###

sub getModelName
{
   my $self = shift;
   return $self->_simpleGetCommand('MDL');
}

sub getFirmwareVersion
{
   my $self = shift;
   return $self->_simpleGetCommand('VER');
} 

sub getVolume
{
   my $self = shift;
   return $self->_simpleGetCommand('VOL');
} 

sub setVolume
{
   my $self = shift;
   my $value = shift;

   return $self->_simpleSetCommand('VOL', $value);
}

sub getSql
{
   my $self = shift;
   return $self->_simpleGetCommand('SQL');
}

sub setSql
{
   my $self = shift;
   my $value = shift;

   return $self->_simpleSetCommand('SQL', $value);
}

sub setProgramMode
{
   my $self = shift;

   return if $self->{_pgm};
   my $res = $self->_simpleGetCommand('PRG');
   if($res eq 'OK')
   {
      $self->{_pgm} = 1;
      return 1;
   }
   else
   {
      print STDERR "NO $res\n";
   }
   return 0;
}

sub quitProgramMode
{
   my $self = shift;

   return unless $self->{_pgm};
   my $res = $self->_simpleGetCommand('EPG');
   if($res eq 'OK')
   {
      $self->{_pgm} = 0;
      return 1;
   }
   return 0;
}

sub getBandPlan
{
   my $self = shift;

   return $self->_simpleGetCommand('BPL', pgm => 1);
}

sub getBandPlanName
{
   my $self = shift;

   my $code = $self->getBandPlan();
   return $self->_getName($code, \%bandPlan);
}

sub setBandPlan
{
   my $self = shift;
   my $value = $self->_fromName(shift, \%bandPlan);

   return $self->_simpleSetCommand('BPL', $value, 1);
}

sub getKeyLockState
{
   my $self = shift;
   return $self->_simpleGetCommand('KBP', pgm => 1, index => 1);
}

sub getKeyLockStateName
{
   my $self = shift;

   my $code = $self->getKeyLockState();
   return $self->_getName($code, \%keyState);
}

sub setKeyLockState
{
   my $self = shift;
   my $state = $self->_fromName(shift, \%keyState);

   return $self->_simpleSetCommand('KBP', [ '', $state ], 1);
}

sub getPriorityMode
{
   my $self = shift;

   return $self->_simpleGetCommand('PRI', pgm => 1);
}

sub getPriorityModeName
{
   my $self = shift;

   my $code = $self->getPriorityMode();
   return $self->_getName($code, \%priMode);
}

sub setPriorityMode
{
   my $self = shift;
   my $value = $self->_fromName(shift, \%priMode);

   return $self->_simpleSetCommand('PRI', $value, 1);
}

sub getScanChannelGroup
{
   my $self = shift;
   
   my $value = $self->_simpleGetCommand('SCG', pgm => 1);

   if($value)
   {
      my @group;
      foreach my $one (split('', $value))
      {
          push @group, $self->_getName($one, \%scanGroup);
      }
      return \@group;
   }
   return;
}

sub setScanChannelGroup
{
   my $self = shift;
   my $gdata = shift;

   my $str = '';
   if(ref($gdata) eq 'ARRAY')
   {
      foreach my $i (0..9)
      {
         my $code = $self->_fromName($gdata->[$i], \%scanGroup);
	 $code = 1 unless defined($code);
	 $str .= $code;
      }
   }
   elsif(ref($gdata) eq 'HASH')
   {
      foreach my $i (1..10)
      {
         my $code;
	 if(exists($gdata->{$i}))
	 {
            $code = $self->_fromName($gdata->{$i}, \%scanGroup);
	 }
	 $code = 1 unless defined($code);
	 $str .= $code;
      }
   }
   else
   {
      $str = $gdata;
   }
   return $self->_simpleSetCommand('SCG', $str, 1);
}

sub setValidScanChannels
{
   my $self = shift;
   my $channels = shift;

   my %on = map { $_ => 1 } @$channels;

   my @group = map { $on{$_} ? 0: 1 } (1..10);
   $self->setScanChannelGroup(\@group);
}

sub getChannelInfo
{
   my $self = shift;
   my $index = shift;

   if($index < 1 || $index > 300)
   {
      return $self->error("Invalid channel index: $index");
   }

   my $value = $self->_simpleGetCommand('CIN', args => [ $index ], pgm => 1, array => 1);
   return undef unless $value;
   my $freq = $value->[2];
   if($freq eq '00000000')
   {
      return { state => 'UNSET' , index => $value->[0] };
   }

   my %info = (
      state => 'SET',
      index => $value->[0],
      freq_code => $value->[2],
      freq => $self->_freq_human($value->[2]),
      delay => $self->_getName($value->[5], \%chDLY), 
      delay_code => $value->[5], 
      lockout => $self->_getName($value->[6], \%chLOUT),
      lockout_code => $value->[6],
      priority => $self->_getName($value->[7], \%chPRI),
      priority_code => $value->[7],
   );

   return \%info;
}

sub getChannelsInfo
{
   my $self = shift;
   my %opts = @_;

   my $start = $opts{start} || 1;
   my $stop  = $opts{stop} || 300;
   my $state = $opts{state};

   $start = 1 if($start < 1 || $start > 300);
   $stop = 300 if($stop < 1 || $stop > 300);
   if($start > $stop)
   {
       $start = $stop;
   }
   
   my @result;
   $self->setProgramMode();
   foreach my $n ($start..$stop)
   {
      my $info = $self->getChannelInfo($n);
      if($state)
      {
         if($state eq $info->{state})
	 {
	    push @result, $info;
	 }
      }
      else
      {
	 push @result, $info;
      }
   }
   $self->quitProgramMode();

   return \@result;
}

sub getBankChannelsInfo
{
   my $self = shift;
   my $bank = shift;
   my $state = shift;

   if($bank < 1 || $bank > 10)
   {
      return $self->error("wrong bank number: $bank, valid - 1..10");
   }
   my $start = (($bank-1) * 30)+ 1;
   my $stop = $start+29;

   my %opts = (start => $start, stop => $stop);
   if($state)
   {
      $opts{state} = uc($state);
   }

   return $self->getChannelsInfo(%opts);
}

sub setChannelInfo
{
   my $self = shift;
   my $index = shift;
   my $data = shift;

   if($index < 1 || $index > 300)
   {
      return $self->error("Invalid channel index: $index");
   }

   my $freq = $self->_from_human_freq($data->{freq});
   my $dly = $data->{delay_code} || $self->_fromName($data->{delay}, \%chDLY);
   $dly = 1 unless defined $dly;
   my $pri = $data->{priority_code} || $self->_fromName($data->{priority}, \%chPRI) || 0;
   my $lout = $data->{lockout_code} || $self->_fromName($data->{lockout}, \%chLOUT) || 0;

   return $self->_simpleSetCommand('CIN', [ $index, '', $freq, '','', $dly, $lout, $pri ], 1);
}

sub eraseChannel
{
   my $self = shift;
   my $index = shift;

   if($index < 1 || $index > 300)
   {
      return $self->error("Invalid channel index: $index");
   }

   $self->setChannelInfo($index, { freq => '0.0' });
}

sub getSearchCloseCallSettings
{
   my $self = shift;

   my $value = $self->_simpleGetCommand('SCO', pgm => 1, array => 1);

   if($value)
   {
      my $dly = $value->[0];
      my $dir = $value->[2];

      return {
	 direction_code => $dir,
	 direction => $self->_getName($dir, \%srchDirection),
         delay_code => $dly,
	 delay => $self->_getName($dly, \%chDLY),
      };
   }
   return undef;
}

sub setSearchCloseCallSettings
{
   my $self = shift;
   my %data = @_;

   my $dir = $self->_fromName($data{direction}, \%srchDirection);
   my $dly = $self->_fromName($data{delay}, \%chDLY);
   $dir = 1 unless defined $dir;;
   $dly = 1 unless defined $dir;;

   $self->_simpleSetCommand('SCO', [ $dly, '', $dir ], 1);
}

sub getGlobalLockoutFreqs
{
   my $self = shift;

   my @freqs = ();

   my $i = 300;
   $self->setProgramMode();
   while($i-- > 0)
   {
       my $value = $self->_simpleGetCommand('GLF', pgm => 1);
       return unless defined($value);

       if($value == -1 || $value eq 'OK')
       {
          last;
       }
       else
       {
           push @freqs, $self->_freq_human($value);
       }
   }
   $self->quitProgramMode();

   return \@freqs;
}

sub lockGlobalFrequency
{
   my $self = shift;
   my $freq = shift;

   $self->_simpleSetCommand('LOF', $self->_from_human_freq($freq), 1);
}

sub unlockGlobalFrequency
{
   my $self = shift;
   my $freq = shift;

   $self->_simpleSetCommand('ULF', $self->_from_human_freq($freq), 1);
}

sub getCloseCallSettings
{
   my $self = shift;

   my $val = $self->_simpleGetCommand('CLC', pgm => 1, array => 1);
   return unless $val;

   my $mode = $val->[0];
   my $al_beep = $val->[1];
   my $al_light = $val->[2];
   my $band_str = $val->[3];

   my %info = (
      mode_code => $mode,
      mode => $self->_getName($mode, \%ccMode),
      alert_beep_code => $al_beep,
      alert_beep => $self->_getName($al_beep, \%ccAlarm),
      alert_light_code => $al_beep,
      alert_light => $self->_getName($al_light, \%ccAlarm),
   );

   my %bands = ();
   for(my $i = 0 ; $i < 5; $i++)
   {
      next unless $ccBand{$i};
      $bands{$ccBand{$i}} = substr($band_str, $i, 1) eq '1' ? 'ON': 'OFF';
   }
   $info{bands} = \%bands;

   return \%info;
}

sub setCloseCallSettings
{
   my $self = shift;
   my %data = @_;

   my $mode = $self->_fromName($data{mode}, \%ccMode);
   my $al_beep = $self->_fromName($data{alert_beep},\%ccAlarm);
   my $al_light = $self->_fromName($data{alert_light},\%ccAlarm);
   $mode = 2 unless defined $mode;
   $al_beep = 0 unless defined $al_beep;
   $al_light = 0 unless defined $al_light;

   my $bands = '11101';
   if($data{bands} && ref($data{bands}) eq 'ARRAY' && scalar(@{$data{bands}}))
   {
       my @B = ( 0, 0, 0, 0, 0 );
       foreach my $name (@{$data{bands}})
       {
           my $code = $self->_fromName($name, \%ccBand);
	   if(defined($code))
	   {
	      $B[$code] = 1;
	   }
       }
       $bands = join('', @B);
       print STDERR "BANDS: $bands\n";
   }

   $self->_simpleSetCommand('CLC', [ $mode, $al_beep, $al_light, $bands, '' ], 1);
}

sub getServiceSearchSettings
{
   my $self = shift;
   my $band = shift;
   
   return $self->error("There is no band") unless $band;
   my $index = $self->_fromName($band, \%ssBand);
   if($index < 1 || $index > 10)
   {
       return $self->error("Band is out of range: $index. (1..10)");
   }

   my $value = $self->_simpleGetCommand('SSP', args => [ $index ], pgm => 1, array => 1);
   return unless $value;

   my %data = (
      index => $index,
      band => $self->_getName($index, \%ssBand),
      delay => $self->_getName($value->[1], \%chDLY),
      delay_code => $value->[1],
      direction => $self->_getName($value->[2], \%srchDirection),
      direction_code => $value->[2],
   );

   return \%data;
}

sub setServiceSearchSettings
{
   my $self = shift;
   my $band = shift;
   my $delay = shift;
   my $dir = shift;

   return $self->error("There is no band") unless $band;
   my $index = $self->_fromName($band, \%ssBand);
   if($index < 1 || $index > 10)
   {
       return $self->error("Band is out of range: $index. (1..10)");
   }

   $delay = 1 unless defined $delay;
   $dir = 1 unless defined $dir;

   my @args = (
      $index,
      $self->_fromName($delay,  \%chDLY), 
      $self->_fromName($dir,  \%srchDirection), 
   );

   $self->_simpleSetCommand('SSP', \@args, 1);
}

sub getCustomSearchGroup
{
   my $self = shift;
   
   my $value = $self->_simpleGetCommand('CSG', pgm => 1, array => 1);

   return unless $value;

   my @group;
   foreach my $one (split('', $value->[0]))
   {
       push @group, $self->_getName($one, \%scanGroup);
   }

   my %data = ( 
      group => \@group, 
      delay => $self->_getName($value->[1], \%chDLY),
      delay_code => $value->[1],
      direction => $self->_getName($value->[2], \%srchDirection),
      direction_code => $value->[2],
   );

   return \%data;
}

sub setCustomSearchGroup
{
   my $self = shift;
   my $gdata = shift;
   my $delay =shift;
   my $dir = shift;

   $delay = 1 unless defined $delay;
   $dir = 0 unless defined $dir;

   my $str = '';
   if(ref($gdata) eq 'ARRAY')
   {
      foreach my $i (0..9)
      {
         my $code = $self->_fromName($gdata->[$i], \%scanGroup);
	 $code = 1 unless defined($code);
	 $str .= $code;
      }
   }
   elsif(ref($gdata) eq 'HASH')
   {
      foreach my $i (1..10)
      {
         my $code;
	 if(exists($gdata->{$i}))
	 {
            $code = $self->_fromName($gdata->{$i}, \%scanGroup);
	 }
	 $code = 1 unless defined($code);
	 $str .= $code;
      }
   }
   else
   {
      $str = $gdata;
   }
   my @args = (
      $str,
      $self->_fromName($delay,  \%chDLY), 
      $self->_fromName($dir,  \%srchDirection), 
   );
   return $self->_simpleSetCommand('CSG', \@args, 1);
}

sub getCustomSearchRange
{
   my $self = shift;
   my $idx = shift;

   return $self->error("No search index") unless $idx;
   if($idx < 1 || $idx > 10)
   {
       $self->error("Search index is out of range: $idx (1..10)");
   }
   my $value = $self->_simpleGetCommand('CSP', args => [ $idx], pgm => 1, array => 1);
   return unless $value;

   return [ $self->_freq_human($value->[1]), $self->_freq_human($value->[2]) ];
}

sub getAllCustomSearchRanges
{
   my $self = shift;

   $self->setProgramMode();
   my @data;
   foreach my $n (1..10)
   {
      push @data, $self->getCustomSearchRange($n);
   }
   $self->quitProgramMode();

   return \@data;
}

sub setCustomSearchRange
{
   my $self = shift;
   my $idx = shift;
   my $left = shift;
   my $right = shift;

   return $self->error("No search index") unless $idx;
   if($idx < 1 || $idx > 10)
   {
       $self->error("Search index is out of range: $idx (1..10)");
   }
   return $self->error("No left bound frequency") unless $left;
   return $self->error("No right bound frequency") unless $right;

   my @args = ( $idx, $self->_from_human_freq($left), $self->_from_human_freq($right) );

   return $self->_simpleSetCommand('CSP', \@args, 1);
}

sub clearMemory
{
   my $self = shift;

   my $val = $self->_simpleGetCommand('CLR', prm => 1);

   return $val eq 'OK' ? 1: 0;
}

### main method ###

sub command
{
   my $self = shift;
   my $cmdName = uc(shift);
   my $args = shift;

   my $str = $cmdName;
   if($args && ref($args) eq 'ARRAY' && scalar(@$args) > 0)
   {
       $str .= ",".join(',', map { defined($_) ? $_: '' } @$args);
   }
   if($self->_write($str))
   {
      my $resp = $self->_readstr();
      unless($resp)
      {
          return { status => 'ERROR', desc => 'Zero read from port' };
      }
      my @out = split(',', $resp);
      my $first = shift @out;
      if($first eq $cmdName)
      {
          if(scalar(@out) && $out[0] eq 'ERR')
	  {
	      shift @out;
	      my $desc = 'Radio returned error';
	      if(scalar(@out))
	      {
	         $desc .= ' ('.join(',', @out).')';
	      }
	      return { status => 'ERROR', desc => $desc };
	  }
          return { status => 'OK', data => \@out }; 
      }
      elsif($first eq 'ERR')
      {
          return { status => 'ERROR', desc => join(',', @out) }; 
      }
      else
      {
          return { status => 'ERROR', desc => "Wrong response: $resp" }; 
      }
   }
   return { status => 'ERROR', desc => 'Write failed' };
}

### internals ###

sub port
{
   shift->{_port};
}

sub error
{
   my $self = shift;

   if($self->{fatal}) 
   {
       die "ERROR: ", @_;
   }
   else
   {
       print STDERR "ERROR: ", @_;
   }
}

sub _echo
{
   my $self = shift;
   my $str = shift;

   return unless $self->{echo};
   print $str."\n";
}

sub _write
{
   my $self = shift;
   my $str = shift;

   $self->_echo("-> $str");
   my $n = $self->port->write("$str\015\012");
   if($n)
   {
      return $n;
   }
   else
   {
      $self->error("Write failed\n");
   }
   return;
}

sub _readstr
{
   my $self = shift;

   my $port = $self->port;

   my $timeout = $self->{timeout};
   my $buffer = "";
   while ($timeout>0)
   {
       my ($count,$saw)=$port->read(255);
       if ($count > 0)
       {
          $buffer .= $saw;
	  if($buffer =~ /\015$/)
	  {
	     last;
	  }
       }
       else
       {
          $timeout--;
       }
   }

   if($timeout == 0)
   {
       print STDERR "*** Timeout ***\n";
   }
   else
   {
      $self->_echo("<- $buffer");
   }
   $buffer =~ s/\015$//;
   return $buffer;
}

sub _simpleGetCommand
{
   my $self = shift;
   my $cmd = shift;
   my %opts = @_;

   my $pgm = $opts{pgm};
   my $qp = 0;
   if($pgm && !($self->{_pgm}))
   {
      $self->setProgramMode();
      $qp = 1;
   }
   my @ARGS = ($cmd);
   if($opts{args})
   {
       push @ARGS, $opts{args};
   }
   my $res = $self->command(@ARGS);

   my $out;
   if($res->{status} eq 'OK')
   {
       if($opts{array})
       {
           $out = $res->{data};
       }
       else
       {
           my $idx = $opts{index} || 0;
           $out = $res->{data}->[$idx];
       }
   }
   else
   {
       print STDERR "ERROR: $res->{desc}\n";
   }
   $self->quitProgramMode() if($qp);
   return $out;
}

sub _simpleSetCommand
{
   my $self = shift;
   my $cmd = shift;
   my $value = shift;
   my $pgm = shift;

   my $qp = 0;
   if($pgm && !($self->{_pgm}))
   {
      $self->setProgramMode();
      $qp = 1;
   }
   my $out = 0;
   my $res = $self->command($cmd, (ref($value) eq 'ARRAY' ? $value : [ $value ]));
   if($res->{status} eq 'OK')
   {
       if($res->{data} && $res->{data}->[0] eq 'NG')
       {
           $out = -1;
       }
       else
       {
           $out = 1;
       }
   }
   else
   {
       print STDERR "ERROR: $res->{desc}\n";
   }
   $self->quitProgramMode() if($qp);
   return $out;
}


sub _getName
{
   my $self = shift;
   my $code = shift;
   my $src = shift;

   return unless defined($code);
   return $src->{$code} if $src->{$code};
   return 'UNKNOWN';
}

sub _fromName
{
   my $self = shift;
   my $name = shift;
   my $src = shift;

   return $name if($name =~ /^\d+$/);

   my %reverse = map { $src->{$_} => $_ } keys %$src;
   my $NAME = uc($name);

   return $reverse{$NAME} if exists $reverse{$NAME};
   return $name;
}

sub _freq_human
{
   my $self = shift;
   my $f = shift;

   return undef if length($f) != 8;

   my $A = substr($f, 0, 4) + 0;
   my $B = substr($f, 4);

   return "$A.$B";
}

sub _from_human_freq
{
   my $self = shift;
   my $value = shift;

   if($value =~ /^(\d+)\.(\d+)$/)
   {
      my $out = sprintf("%04d%-04s", $1, $2);
      $out =~ s/ /0/g;
      return $out;

   }
   elsif($value =~ /^\d+$/)
   {
      return sprintf("%04d0000", $value);
   }
   return $value;
}


1;
