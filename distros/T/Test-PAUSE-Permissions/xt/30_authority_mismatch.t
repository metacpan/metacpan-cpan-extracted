use strict;
use warnings;
use Test::More;

BEGIN {
  eval { use WorePAN 0.09; 1; }
    or plan skip_all => 'requires WorePAN 0.09';

  eval { use File::pushd; 1; }
    or plan skip_all => 'requires File::pushd';

  eval { use JSON::PP; 1; }
    or plan skip_all => 'requires JSON::PP';
}

my $worepan = WorePAN->new(
  files => ['ISHIGAKI/WorePAN-0.17.tar.gz'],
  no_network => 0,
  cleanup => 1,
  no_indices => 1,
  verbose => 0,
);

$worepan->walk(callback => sub {
  my $basedir = shift;

  # prepare perms test
  $basedir->file("xt/perms.t")->save(<<'TEST', {mkdir => 1});
use Test::PAUSE::Permissions;
local $ENV{RELEASE_TESTING} = 1;
all_permissions_ok('ISHIGAKI');
TEST

  {
    # should have no diagnosis message
    # (WorePAN doesn't have x_authority nor $AUTHORITY)

    my $dir = pushd($basedir);
    my $output = `prove -l xt/perms.t 2>&1`;
    like $output => qr/Result: PASS/;
    unlike $output => qr/doesn't match x_authority/;
  }

  {
    # tweak META (still no diagnosis)
    my $metafile = $basedir->file('META.json');
    my $meta = decode_json(scalar $metafile->slurp);
    $meta->{x_authority} = 'cpan:ISHIGAKI';
    $metafile->save(encode_json($meta));

    my $dir = pushd($basedir);
    my $output = `prove -l xt/perms.t 2>&1`;
    like $output => qr/Result: PASS/;
    unlike $output => qr/doesn't match x_authority/;
  }

  {
    # embed correct $AUTHORITY in .pm
    my $pmfile = $basedir->file('lib/WorePAN.pm');
    my $content = $pmfile->slurp;
    $content = 'our $AUTHORITY = "cpan:ISHIGAKI";' . "\n" . $content;
    $pmfile->save($content);
    my $dir = pushd($basedir);
    my $output = `prove -l xt/perms.t 2>&1`;
    like $output => qr/Result: PASS/;
    unlike $output => qr/doesn't match x_authority/;
  }

  {
    # embed correct $AUTHORITY in .pm
    my $pmfile = $basedir->file('lib/WorePAN.pm');
    my $content = $pmfile->slurp;
    $content =~ s/cpan:ISHIGAKI/cpan:LOCAL/;
    $pmfile->save($content);

    # should have a diagnosis message
    my $dir = pushd($basedir);
    my $output = `prove -l xt/perms.t 2>&1`;
    like $output => qr/Result: PASS/;
    like $output => qr/doesn't match x_authority/;
  }
});

done_testing;
