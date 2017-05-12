#!/usr/bin/perl -w
use strict;
use warnings qw(FATAL all NONFATAL misc);

use fields qw(cf_tmpdir cf_datadir cf_limit);

use YATT::Lite qw/*CON/;

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

  open my $fh, '>'.($CON->get_encoding_layer), $fname
    or die "Can't open newfile '$fname': $!";

  wantarray ? ($fh, $fname, $fnum) : $fh;
}

sub mh_lastfnum {
  (my MY $yatt) = shift;
  my $lockfh = $yatt->mh_openlock(@_);
  my $num = <$lockfh>;
  if (defined $num and $num =~ /^\d+/) {
    $num = $&;
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

#========================================

Entity mh_files => sub {
  my ($this, $opts) = @_;
  my MY $yatt = MY->YATT; # To make sure strict check occurs.
  my $as_realpath = delete $opts->{realpath};
  my $start = delete($opts->{current}) // 0;
  my $limit = delete($opts->{limit}) // $yatt->{cf_limit};
  my $ext = delete($opts->{ext}) // '';
  # XXX: $opts should be empty now.
  my @result = do {
    my @all;
    opendir my $dh, $yatt->{cf_datadir}
      or die "Can't opendir '$yatt->{cf_datadir}': $!";
    while (my $fn = readdir $dh) {
      my ($num) = $fn =~ m{^\.ht_(\d+)$ext$}
	or next;
      push @all, $as_realpath ? [$num, "$yatt->{cf_datadir}/$fn"] : $num;
    }
    closedir $dh; # XXX: Is this required still?
    $as_realpath ? map($$_[-1], sort {$$a[0] <=> $$b[0]} @all)
      : sort {$a <=> $b} @all;
  };
  unless (wantarray) {
    \@result;
  } else {
    @result[$start .. min($start+$limit, $#result)];
  }
};

Entity mh_load => sub {
  my ($this, $fnum) = @_;
  my MY $yatt = $this->YATT; # To make sure strict field check occurs.
  my $fn = "$yatt->{cf_datadir}/.ht_$fnum";
  unless (-r $fn) {
    die "Can't read '$fn'\n";
  }
  $yatt->read_file_xhf($fn);
};

sub escape_nl {
  shift;
  $_[0] =~ s/\n/\n /g;
  $_[0];
}

sub min {$_[0] < $_[1] ? $_[0] : $_[1]}

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
  # $self->SUPER::after_new(); # Should call, but without this, should work.
  # XXX: rewrite with (future) abstract path api.
  $self->{cf_datadir} //= $self->app_path_var('data');
  $self->{cf_tmpdir}  //= $self->app_path_var_tmp;
  $self->{cf_limit} //= 100;
}

1;
