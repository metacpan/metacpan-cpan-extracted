use Test2::V0 -no_srand => 1;
use Test2::Plugin::FauxHomeDir;

my $faux = defined $ENV{HOME}
  ? $ENV{HOME}
  : defined $ENV{USERPROFILE}
    ? $ENV{USERPROFILE}
    : undef;

bail_out 'no HOME or USERPROFILE' unless $faux;

is($faux, D(), 'faux home is defined');
ok(-d $faux,   'faux home is a directory');
note "faux home = $faux";

{
  my $filename = File::Spec->catfile($faux, 'test.txt');
  open my $fh, '>', $filename;
  print $fh "xx\n";
  close $fh;
}

subtest 'File::Glob' => sub {

  skip_all 'test requires File::Glob'
    unless eval q{ require File::Glob };
  
  my $filename = File::Glob::bsd_glob('~/test.txt');
  ok -f $filename;
  note "filename = $filename";
  open my $fh, '<', $filename;
  my $data = do { local $/; <$fh> };
  close $fh;
  is $data, "xx\n";

};

subtest 'Path::Tiny' => sub {

  skip_all 'test requires Path::Tiny'
    unless eval q{ require Path::Tiny };
  
  my $path = Path::Tiny->new('~/test.txt');
  
  ok -f $path;
  is $path->slurp, "xx\n";

};

subtest 'File::HomeDir' => sub {

  skip_all 'test requires File::HomeDir'
    unless eval q{ require File::HomeDir };

  my $filename = File::Spec->catfile(File::HomeDir->my_home, 'test.txt');

  ok -f $filename;
  
  open my $fh, '<', $filename;
  my $data = do { local $/; <$fh> };
  close $fh;
  
  is $data, "xx\n";  
};

done_testing
