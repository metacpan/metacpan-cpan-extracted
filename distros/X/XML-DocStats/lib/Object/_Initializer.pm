package Object::_Initializer;

#
# revision history
#
# 2001-09-05 AFD initial release 
# 2001-09-06 AFD add _get_attribute
# 2001-10-08 AFD rename to Object::_Initializer
# 2001-10-08 AFD add log_it and dump_log
# 2001-10-09 AFD add _timestamp, debug_log
# 2001-10-12 AFD return undef from _get_attribute instead of croak for missing...
# 2001-10-12 AFD add _timeformat
# 2001-10-13 AFD remove space from end of _timestamp
# 2002-01-16 AFD avoid redefining object methods in _init...
# 2002-03-02 AFD call _defaults in new if can...
#

use strict;
use vars qw($VERSION);

use Carp;

use Data::Dumper;

$VERSION = '0.08';

sub new {

  my ($class, %args) = @_;
  my $self = bless {}, ref($class)||$class;
  $self->_defaults if $self->can('_defaults');
  $self->_init(%args);
  return $self;
}

sub _init {

my ($self, %args) = @_;
my $class = ref($self);

for my $arg (keys %args) {
  $self->{$arg} = $args{$arg};
  next if $self->can($arg);
  my $name = "$class::$arg";
  no strict 'refs';
  *{$name} = sub {
       my $oldval = $_[0]->{$arg}; 
       $_[0]->{$arg} = $_[1] if defined $_[1];
       return $oldval;
       };
  }

}

sub _get_attribute {

  my ($self, $attribute, $newvalue) = @_;
  my $class = ref($self);
  return undef unless exists $self->{$attribute};
#  croak "no such attribute '$attribute' for class '$class'" unless exists $self->{$attribute};
  my $oldval = $self->{$attribute}; 
  $self->{$attribute} = $newvalue if defined $newvalue;
  return $oldval;
  
}

sub log_it {
  my ($self,$what) = @_;

  if ($self->trace) {
  my $logfilename = $self->LogFilename;
  $what = $self->_timestamp.$what;
  open(LOG, ">>$logfilename") or croak "$0 can't open LOG ($logfilename) $!";
  print LOG $what;
  close LOG;
 }
}

sub dump_log {
  my ($self) = @_;
  $self->log_it( ' '.Data::Dumper->Dump([ $_[0] ], [qw( *self)])."\n");
}

sub debug_log {
  my ($self) = @_;
  my ($savetrace,$savelogfile) = ($self->{'trace'},$self->{'LogFilename'});
  $self->_init(trace=>1,LogFilename=>'/data/'.ref($self).'.log');
  $self->dump_log;
  $self->trace($savetrace);
  $self->LogFilename($savelogfile);
}

sub _timestamp {
  my ($self) = @_;
  my ($SEC, $MIN, $HOUR, $DAY, $MONTH, $YEAR, $WEEKDAY) = (localtime)[0..6];
  return sprintf("%04d/%02d/%02d-%02d:%02d:%02d",$YEAR+1900,$MONTH+1,$DAY,$HOUR,$MIN,$SEC);
}

sub _timeformat {
  my ($self) = @_;
  my ($SEC, $MIN, $HOUR, $DAY, $MONTH, $YEAR, $WEEKDAY) = (gmtime)[0..6];
  my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my @days = qw(Sun Mon Tue Wed Thr Fri Sat);
  return sprintf("%s, %s %2d %04d at %02d:%02d:%02d UT",$days[$WEEKDAY],$months[$MONTH],$DAY,$YEAR+1900,$HOUR,$MIN,$SEC);
}

1;
__END__
