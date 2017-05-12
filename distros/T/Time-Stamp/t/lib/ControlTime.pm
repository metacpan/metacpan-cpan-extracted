package # no_index
  ControlTime;

our ($time, $frac);

BEGIN {
  # override it now, decide at each call what to return
  *CORE::GLOBAL::time = \&fake_or_real_time;
}

# serve fake time if set, otherwise real time
sub fake_or_real_time {
  $time || CORE::time();
}

# OO mostly for the sake of simple, intuitive scoping
sub new {
  my $class = shift;
  my $self = bless [@_], $class;
  $self->set( @$self ) if @$self;
  $self;
}

sub set {
  my $self = shift;
  $time = shift;
  $self->fraction(shift) if @_;
}

sub fraction {
  my ($self, $f) = @_;
  $self->mock_time_hires;
  $frac = $f;
}

my $mocked_hires;
sub mock_time_hires {
  return if $mocked_hires++;

  $INC{"Time/HiRes.pm"} = 1;

  *Time::HiRes::gettimeofday = sub {
    my @t = (fake_or_real_time(), $frac);
    return wantarray ? @t : sprintf("%d.%06d", @t);
  };

  {
    no warnings 'once';
    *Time::HiRes::time = sub {
      scalar Time::HiRes::gettimeofday();
    };
  }
}

sub fake_have_hires {
  my ($self, $bool) = @_;
  $self->mock_time_hires;

  require Time::Stamp;
  no warnings 'redefine';
  *Time::Stamp::_have_hires = sub { $bool };
}

sub reset {
  $time = $frac = undef;
}

sub DESTROY { shift->reset }

1;
