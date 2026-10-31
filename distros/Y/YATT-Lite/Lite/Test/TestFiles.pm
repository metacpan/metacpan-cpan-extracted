package
  YATT::Lite::Test::TestFiles;
sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use base qw/File::Spec/;
use fields qw(basedir Dict List auto_clean quiet);

sub new {
  my MY $self = fields::new(shift);
  $self->{basedir} = shift;
  while (my ($name, $value) = splice @_, 0, 2) {
    $name =~ /^(?:auto_clean|quiet)\z/
      or die "No such option for @{[MY]}: $name\n";
    $self->{$name} = $value;
  }
  $self->mkdir();
  $self
}

sub mkdir {
  (my MY $self, my ($fn)) = @_;
  my $real = $_[2] = $self->catdir(grep {defined} $self->{basedir}, $fn);
  unless (-d $real) {
    CORE::mkdir($real) or die "Can't mkdir $real: $!";
    print "# o mkdir $real\n" unless $self->{quiet};
    push @{$self->{List}}, [rmdir => $real];
  } else {
    print "# o exists $real\n" unless $self->{quiet};
  }
  $fn;
}

sub add {
  (my MY $self, my ($fn, $content)) = @_;
  my $real = "$self->{basedir}/$fn";
  my $old_mtime;
  while (-e $real and ($old_mtime = (stat($real))[9]) == time) {
    # wait until mtime is changed.
    sleep 1;
  }
  open my $fh, '>', $real or die "Can't create $real: $!";
  print $fh $content;
  close $fh;
  if (defined $old_mtime and (stat($real))[9] <= $old_mtime) {
    sleep 1;
    utime(undef, undef, $real) || warn "Can't touch $real: $!";
  }
  unless ($self->{Dict}{$real}++) {
    push @{$self->{List}}, [unlink => $real];
  }
  print "# o written: $real\n" unless $self->{quiet};
  $self
}

sub rmdir {my ($self, $fn) = @_; CORE::rmdir($fn) or warn "# rmdir $fn: $!"};
sub unlink {my ($self, $fn) = @_; CORE::unlink($fn) or warn "# rm $fn: $!"};

sub DESTROY {
  my MY $self = shift;
  return unless $self->{auto_clean};
  foreach my $item (reverse @{$self->{List}}) {
    my ($method, $arg) = @$item;
    # print "# $method $arg\n";
    $self->$method($arg);
  }
}

1;
