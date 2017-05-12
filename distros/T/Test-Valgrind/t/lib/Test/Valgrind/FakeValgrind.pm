package Test::Valgrind::FakeValgrind;

use strict;
use warnings;

use Config ();
use File::Spec;
use File::Temp;

sub _dummy_valgrind_code {
 my ($version, $body) = @_;

 my $perl = $^X;
 unless (-e $perl and -x $perl) {
  $perl = $Config::Config{perlpath};
  unless (-e $perl and -x $perl) {
   return undef;
  }
 }

 if (defined $body) {
  $body = "\n$body";
 } else {
  $body = '';
 }

 return <<" FAKE_VG";
#!$perl
if (\@ARGV == 1 && \$ARGV[0] eq '--version') {
 print "valgrind-$version\n";
 exit 0;
}$body
 FAKE_VG
}

my $good_enough_file_temp;
BEGIN {
 $good_enough_file_temp = do {
  no warnings;
  local $@;
  eval { File::Temp->VERSION('0.19'); 1 }
 }
}

sub new {
 my ($class, %args) = @_;

 return 'Temporary executables do not work on Windows' if $^O eq 'MSWin32';

 my $exe_name = $args{exe_name};
 my $version  = $args{version} || '3.1.0';
 my $body     = $args{body};

 my $self = { };

 my $exe_ext = $Config::Config{exe_ext};
 $exe_ext    = '' unless defined $exe_ext;
 if (defined $exe_name) {
  return 'File::Temp 0.19 is required to make a proper temporary directory'
         unless $good_enough_file_temp;
  if (length $exe_ext and $exe_name !~ /\Q$exe_ext\E$/) {
   $exe_name .= $exe_ext;
  }
  $self->{tmp_dir_obj} = File::Temp->newdir(CLEANUP => 1);
  $self->{tmp_dir}     = $self->{tmp_dir_obj}->dirname;
  $self->{tmp_file}    = File::Spec->catfile($self->{tmp_dir}, $exe_name);
 } else {
  # Can't use the OO interface if we don't wan't the file to be opened by
  # default, but then we have to deal with cleanup ourselves.
  my %args = (
   TEMPLATE => 'fakevgXXXX',
   TMPDIR   => 1,
   CLEANUP  => 0,
   OPEN     => 0,
  );
  $args{SUFFIX} = $exe_ext if length $exe_ext;
  my $tmp_file = do {
   local $^W = 0;
   (File::Temp::tempfile(%args))[1]
  };
  $self->{tmp_file} = $tmp_file;
  my ($vol, $dir)   = File::Spec->splitpath($self->{tmp_file});
  $self->{tmp_dir}  = File::Spec->catpath($vol, $dir, '');
 }

 my $code = _dummy_valgrind_code($version, $body);
 return 'Could not generate the dummy valgrind executable' unless $code;

 return 'Temporary file already exists' if -s $self->{tmp_file};

 {
  open my $vg_fh, '>', $self->{tmp_file};
  print $vg_fh $code;
  close $vg_fh;
  chmod 0755, $self->{tmp_file};
 }

 bless $self, $class;
}

sub path    { $_[0]->{tmp_file} }

sub dir     { $_[0]->{tmp_dir} }

sub DESTROY { 1 while unlink $_[0]->{tmp_file} }

1;
