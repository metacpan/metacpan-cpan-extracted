use strict;
use warnings;
use Test::More;
use WorePAN;

plan skip_all => "set WOREPAN_NETWORK_TEST to test" unless $ENV{WOREPAN_NETWORK_TEST};

my $worepan = WorePAN->new(cleanup => 1, no_network => 0);

{
  $worepan->add_files(qw{
    ISHIGAKI/Acme-CPANAuthors-Japanese-0.071226.tar.gz
  });

  ok $worepan->file('I/IS/ISHIGAKI/Acme-CPANAuthors-Japanese-0.071226.tar.gz')->exists;

  ok !$worepan->mailrc->exists;
  ok !$worepan->packages_details->exists;
}

{
  $worepan->add_dists(
    'Path-Extended' => 0,
  );
}

{
  $worepan->update_indices;

  ok $worepan->look_for('Acme::CPANAuthors::Japanese'), "Acme::CPANAuthors::Japanese is listed in the index";
  ok $worepan->look_for('Path::Extended'), "Path::Extended is listed in the index";
}



done_testing;
