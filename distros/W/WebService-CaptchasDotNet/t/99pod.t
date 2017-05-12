use strict;
use warnings FATAL => qw(all);

use Test::More;

use File::Spec;
use File::Find qw(find);

eval {
  require Test::Pod;
  Test::Pod->import;
};

if ($@) {
  plan skip_all => "Test::Pod required for testing POD";
}
else {
  my @files;

  find(
    sub { push @files, $File::Find::name if m!\.p(m|od|l)$! }, 
    File::Spec->catfile(qw(blib lib))
  );

  plan tests => scalar @files;

  foreach my $file (@files) {
    pod_ok($file);
  }
}
