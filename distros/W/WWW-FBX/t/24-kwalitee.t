use Test::More;
BEGIN {
   plan skip_all => 'these tests are for release candidate testing' 
      unless $ENV{RELEASE_TESTING};
   plan skip_all => 'install Test::Kwalitee to run this test' 
      unless eval "use Test::Kwalitee 'kwalitee_ok'; 1";
}

kwalitee_ok( qw/ -has_manifest -has_meta_yml / );
done_testing;
