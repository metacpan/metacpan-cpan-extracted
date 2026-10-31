package YATT::Lite::XHF::StoreDir; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);

use base qw(YATT::Lite::Object);
use fields qw(datadir
	      fileprefix
	      fileext
	      lockname
	    );

use YATT::Lite::XHF::Dumper;

use Fcntl qw(:DEFAULT :flock SEEK_SET);

sub after_new {
  my MY $self = shift;
  $self->{fileprefix} //= '.ht_';
  $self->{fileext}    //= '.xhf';
  $self->{lockname}   //= 'lock';
}

sub create {
  my MY $self = shift;
  my $dump = $self->dump_xhf(@_) if @_;
  my ($fnum, $lockfh) = $self->lastfnum(1);
  my ($fname);
  do {
    $fname = "$self->{datadir}/$self->{fileprefix}" . ++$fnum;
  } while (-e $fname);

  seek $lockfh, 0, SEEK_SET
    or die "Can't seek: $!";
  print $lockfh $fnum, "\n";
  truncate $lockfh, tell($lockfh);

  open my $fh, '>', $fname
    or die "Can't open newfile '$fname': $!";

  if (defined $dump) {
    print $fh $dump;
    return $fnum;
  } else {
    wantarray ? ($fh, $fnum, $fname) : $fh;
  }
}

sub fnum2path {
  (my MY $self, my $fnum) = @_;
  "$self->{datadir}/$self->{fileprefix}$fnum";
}

sub lastfnum {
  (my MY $self) = shift;
  my $lockfh = $self->openlock(@_);
  my $num = <$lockfh>;
  if (defined $num and $num =~ /^\d+/) {
    $num = $&;
  } else {
    $num = 0;
  }
  wantarray ? ($num, $lockfh) : $num;
}

sub openlock {
  (my MY $self, my $flock) = @_;
  my $lockfn = "$self->{datadir}/$self->{fileprefix}$self->{lockname}";
  sysopen my $lockfh, $lockfn, O_RDWR | O_CREAT
    or die "Can't open '$lockfn': $!";

  if ($flock) {
    flock $lockfh, LOCK_EX
      or die "Can't lock '$lockfn': $!";
  }
  $lockfh;
}

1;
