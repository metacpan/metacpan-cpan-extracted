use strict;
use fields qw(cf_datadir cf_tmpdir cf_config);
use YATT::Lite::Entities qw(*CON);
Entity YATT => sub {shift->YATT};
use Carp;

#========================================
Entity config => sub {
  my ($this) = shift;
  my MY $yatt = $this->YATT;
  if (@_) {
    $yatt->{cf_config}->{$_[0]};
  } else {
    $yatt->{cf_config};
  }
};

#========================================

Entity session_start => sub {
  my ($this) = shift;
  $CON->start_session(@_ ? @_ : qr/^\w+$/);
  '';
};

# Normally, calling &yatt:sess(); is enough.
Entity session_resume => sub {
  my ($this) = shift;
  $CON->get_session;
  '';
};


#========================================
use Fcntl qw(:DEFAULT :flock SEEK_SET);

sub mh_alloc_newfh {
  (my MY $yatt) = @_;
  my ($fnum, $lockfh) = $yatt->mh_lastfnum(1);

  my ($fname);
  do {
    $fname = "$yatt->{cf_datadir}/.ht_" . ++$fnum;
  } while (-e $fname);

  seek $lockfh, 0, SEEK_SET
    or die "Can't seek: $!";
  print $lockfh $fnum, "\n";
  truncate $lockfh, tell($lockfh);

  open my $fh, '>', $fname
    or die "Can't open newfile '$fname': $!";

  wantarray ? ($fh, $fname, $fnum) : $fh;
}

sub mh_lastfnum {
  (my MY $yatt) = shift;
  my $lockfh = $yatt->mh_openlock(@_);
  my $num = <$lockfh>;
  if (defined $num) {
    # chomp $num;
    $num = ($num =~ m{^(\d+)} ? $1 : 0);
  } else {
    $num = 0;
  }
  wantarray ? ($num, $lockfh) : $num;
}

sub mh_openlock {
  (my MY $yatt, my $lock) = @_;
  my $lockfn = "$yatt->{cf_datadir}/.ht_lock";
  sysopen my $lockfh, $lockfn, O_RDWR | O_CREAT
    or die "Can't open '$lockfn': $!";

  if ($lock) {
    flock $lockfh, LOCK_EX
      or die "Can't lock '$lockfn': $!";
  }
  $lockfh;
}

#########################################
Entity tsvfile => sub {
  my ($this, $name) = @_;
  my MY $yatt = $this->YATT;
  $name =~ s;(^|/)\.+/;$1;g;
  my $fn = "$yatt->{cf_dir}/../$name.tsv";
  unless (-r $fn) {
    die "No such file: $fn\n";
  }
  open my $fh, '<', $fn or die "Can't open $fn: $!";
  local $_;
  my @lines;
  while (<$fh>) {
    chomp; s/\r$//;
    next if /^\#/;
    # XXX: Untaint?
    push @lines, [split /\t/];
  }
  wantarray ? @lines : \@lines;
};

#########################################

sub cmd_setup {
  my MY $self = shift;
  require File::Path;
  foreach my $dir ($self->{cf_datadir}, $self->{cf_tmpdir}) {
    next if -d $dir;
    File::Path::make_path($dir, {mode => 02775, verbose => 1});
  }
}

sub after_new {
  my MY $self = shift;
  $self->{cf_tmpdir}  //= $self->app_path_var_tmp;
  $self->{cf_datadir} //= $self->app_path_var('data');
}

Entity sess_obj => sub {
  my ($this) = shift;

  # This will call MY->session_resume.
  $CON->get_session
};

Entity att_value_of => sub {
  my ($this, $type, $name, $formal_value, $opts) = @_;

  my $in       = delete $opts->{in} // $CON;
  my $as_value = delete $opts->{as_value};

  if (%$opts) {
    croak "Unknown option for att_value_of(): ".join(", ", sort keys %$opts);
  }

  \ YATT::Lite::Util::att_value_in($in, $type, $name, $formal_value, $as_value);
};
