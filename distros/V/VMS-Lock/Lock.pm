package VMS::Lock;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT      = qw();
@EXPORT_OK   = qw(VLOCK_NLMODE VLOCK_CRMODE VLOCK_CWMODE VLOCK_PRMODE VLOCK_PWMODE VLOCK_EXMODE
                  VLOCK_KERNEL VLOCK_EXEC VLOCK_SUPER VLOCK_USER);
%EXPORT_TAGS = (lockmodes => [qw(VLOCK_NLMODE VLOCK_CRMODE VLOCK_CWMODE VLOCK_PRMODE VLOCK_PWMODE VLOCK_EXMODE)],
                accmodes  => [qw(VLOCK_KERNEL VLOCK_EXEC VLOCK_SUPER VLOCK_USER)]);

$VERSION = '1.03';

my $DEBUG = 0;
my $DISPLAY_MODE = 0;
my %comment = (
    RESOURCE_NAME => 'Name string to be locked.  Up to 31 bytes long.',
    SYSLOCK       => 'Denotes a system lock.  Requires SYSLCK priv.',
    ACCESS_MODE   => 'Denotes least priveleged access mode for this resource name.',
    NOQUEUE       => 'Sets LCK$M_NOQUEUE flag for convert.',
    LOCK_ID       => 'Lock id.',
    LOCK_MODE     => '0..5 => [NL,CR,CW,PR,PW,EX]',
    VALUE_BLOCK   => 'Lock Value Block passed about in Lock Status Block.',
    INV_VALBLOCK  => 'Set to 1 if SS$_VALNOTVALID returned in LSB.',
    DEADLOCK      => 'Set to 1 if SS$_DEADLOCK returned in LSB.',
    EXPEDITE      => 'Sets LCK$M_EXPEDITE flag for new lock.',
    DEBUG         => 'Level of debugging for this object.',
   );

my %quote = (
    RESOURCE_NAME => "'",
    SYSLOCK       => "",
    ACCESS_MODE   => "",
    NOQUEUE       => "",
    LOCK_ID       => "",
    LOCK_MODE     => "",
    VALUE_BLOCK   => "'",
    INV_VALBLOCK  => "",
    DEADLOCK      => "",
    EXPEDITE      => "",
    DEBUG         => "",
   );

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		die "Your vendor has not defined VMS::Lock macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap VMS::Lock $VERSION;

# Preloaded methods go here.

sub new {
  my $class = shift;
  my %param = @_;
  my $status;
  my $tdebug =0;

  my $self = {
    RESOURCE_NAME => '',
    SYSLOCK       => 0,
    ACCESS_MODE   => 0,
    NOQUEUE       => 0,
    LOCK_ID       => 0,
    LOCK_MODE     => 0,
    VALUE_BLOCK   => "\0" x 16,
    INV_VALBLOCK  => 0,
    DEADLOCK      => 0,
    EXPEDITE      => 0,
    DEBUG         => 0,
  };

  for my $tparam (qw(RESOURCE_NAME SYSLOCK ACCESS_MODE EXPEDITE DEBUG)) {
    if (exists $param{$tparam}) {
      $self->{$tparam} = $param{$tparam};
      delete $param{$tparam};
    }
  }

  $tdebug = $DEBUG | $self->{DEBUG};

  if ($tdebug & 1) {
    print "Entering new.\n";
    if (scalar %param) {
      display (\%param, "VMS::Lock::new called with extra params, these will be ignored");
      undef %param;
    }
    print "Calling _new.\n";
  }

  $status = _new ($self->{RESOURCE_NAME},
		  $self->{SYSLOCK},
		  $self->{ACCESS_MODE},
		  $self->{LOCK_ID},
		  $self->{VALUE_BLOCK},
		  $self->{INV_VALBLOCK},
		  $self->{EXPEDITE},
		  $tdebug);

  if ($tdebug & 1) { display ($self, "In new; result of _new; status = [$status]") }

  if (! $status) {
    if ($tdebug & 1) { print "Error [$!][$^E] from _new;  returning undef.\n" }
    return undef;
  }

  if ($tdebug & 1) { print "Leaving new.\n" }

  return bless $self, $class;
}

sub convert {
  my $self = shift;
  my %param = @_;
  my $status;
  my $tdebug;

  $param{DEBUG}       = 0  if ! exists $param{DEBUG};
  $param{VALUE_BLOCK} = '' if ! exists $param{VALUE_BLOCK};
  $param{NOQUEUE}     = 0  if ! exists $param{NOQUEUE};

  $tdebug = $DEBUG | $self->{DEBUG} | $param{DEBUG};

  if ($tdebug & 1) {
    print "Entering convert\n";
    display (\%param, "convert called with:");
  }

  if (! exists $param{LOCK_MODE}) {
    die "no LOCK_MODE passed into convert";
  }

  $status = _convert ($self->{LOCK_ID},
            $param{LOCK_MODE},
            $param{VALUE_BLOCK},
            $param{NOQUEUE},
	    $self->{INV_VALBLOCK},
	    $self->{DEADLOCK},
            $tdebug);

  if (! defined $status) {
    if ($tdebug & 1) { print "Error [$!][$^E] from _convert;  returning undef.\n" }
    return undef;
  }
  elsif ($status == 0) {
    if ($tdebug & 1) { print "Status of 0 from _convert;  noqueue = [",$param{NOQUEUE},"].\n" }
    $self->{NOQUEUE}     = $param{NOQUEUE};
  }
  else {  
    $self->{LOCK_MODE}   = $param{LOCK_MODE};    # potentially modified
    $self->{VALUE_BLOCK} = $param{VALUE_BLOCK};  #   by _convert
  }

  if ($tdebug & 1) { display ($self, "Result of _convert") }

  return $status;
}

sub value_block   { my $self = shift; return $self->{VALUE_BLOCK}; }
sub expedite      { my $self = shift; return $self->{EXPEDITE}; }
sub deadlock      { my $self = shift; return $self->{DEADLOCK}; }
sub noqueue       { my $self = shift; return $self->{NOQUEUE}; }
sub lock_id       { my $self = shift; return $self->{LOCK_ID}; }
sub lock_mode     { my $self = shift; return $self->{LOCK_MODE}; }
sub inv_valblock  { my $self = shift; return $self->{INV_VALBLOCK}; }
sub resource_name { my $self = shift; return $self->{RESOURCE_NAME}; }

sub delete {
  my $self = shift;
  my %param = @_;
  my $tdebug = $DEBUG | $self->{DEBUG} | $param{DEBUG};
  if ($tdebug & 1) { print "Entering delete.\n" }
  undef $self;
}

sub DESTROY {
  my $self = shift;
  my $tdebug = $DEBUG | $self->{DEBUG};

  if ($tdebug & 1) { print "Entering DESTROY\n" }

  _deq ($self->{LOCK_ID}, $tdebug) or die "error [$!][$^E] from _deq in DESTROY";

  if ($tdebug & 1) { print "Leaving DESTROY\n" }
}

sub debug {
  my $self = shift;
  if (@_) {
    my $level = shift;
    if (_debug($level)) { print "Turning on XS debugging.\n" }
    return ref $self ? $self->{DEBUG} = $level : $DEBUG = $level;
  }
  else {
    return ref $self ? $self->{DEBUG} : $DEBUG;
  }
}

sub display_mode {
  my $self = shift;
  if (@_) {
    my $mode = shift;
    return $DISPLAY_MODE = $mode;
  }
  else {
    return $DISPLAY_MODE;
  }
}

sub display {
  my ($hash, $header) = @_;
  $header  = $hash unless defined $header;

  my $tmode    = $DISPLAY_MODE & 1;
  my $tcomment = $DISPLAY_MODE & 2;
  my $tmaxsize;
  my $tvalue;

  foreach $tvalue (values %$hash) { $tmaxsize = length($tvalue) if length($tvalue) > length($tmaxsize) }

  if ($DEBUG) { print "mode = [$tmode], comment = [$tcomment]\n" }

  if ($tmode == 0) {
    print "$header ", '-' x (60 - length($header)), "\n";
    foreach my $key (sort keys %$hash) {
      $tvalue = defined $$hash{$key} ? $$hash{$key} : "undef";
      print "  key = [$key],", ' ' x (15 - length($key)), " value = [$tvalue]";
      if ($tcomment == 2) { print ' ' x ($tmaxsize + 2 - length($tvalue)), $comment{$key} }
      print "\n";
    }
    print '-' x 60, "\n";
  }
  elsif ($tmode == 1) {
    print "$header = {\n";
    foreach my $key (sort keys %$hash) {
      $tvalue = defined $$hash{$key} ? "$quote{$key}$$hash{$key}$quote{$key}" : "undef";
      print  "  $key" . ' ' x (15 - length($key)), " => $tvalue,";
      if ($tcomment == 2) { print ' ' x ($tmaxsize + 2 - length($tvalue)), "# $comment{$key}," }
      print "\n";
    }
    print "}\n";
  }
}

sub package_vars {
  print "DEBUG        = [$DEBUG]\n";
  print "DISPLAY_MODE = [$DISPLAY_MODE]\n";
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=cut

