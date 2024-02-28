use Test2::V0 -no_srand => 1;
use Perl::Critic;
use Test2::Tools::PerlCritic::Util qw( perl_critic_config_id );
use Path::Tiny ();

subtest 'perl_critic_config_id' => sub {

  my $default_id = perl_critic_config_id;
  like $default_id, qr/^[a-f0-9]{32}\z/;
  note $default_id;

  is(perl_critic_config_id(Perl::Critic->new), $default_id);
  is(perl_critic_config_id(Perl::Critic->new->config), $default_id);

  my $profile = Path::Tiny->tempfile( TEMPLATE => "perlcriticrcXXXXXX" );

  $profile->spew_utf8(<<'EOF');
only = 1
[TestingAndDebugging::RequireUseStrict]
severity = 5
EOF

  note "CONFIG:\n", $profile->slurp_utf8;
  my $id = perl_critic_config_id(Perl::Critic->new( -profile => "$profile" ));

  like $id, qr/^[a-f0-9]{32}\z/;
  note $id;
  isnt $id, $default_id, 'produces a different id from the default';

  # add some content to the config file that should
  # not change the config
  $profile->append("; some comment here\n");
  $profile->append("\n\n\n\n");

  note "CONFIG:\n", $profile->slurp_utf8;
  is(perl_critic_config_id(Perl::Critic->new( -profile => "$profile" )), $id, 'id does not change for whitespace and comment changes');

  $profile->spew_utf8(<<'EOF');
only = 1
[TestingAndDebugging::RequireUseStrict]
severity = 4
EOF

  note "CONFIG:\n", $profile->slurp_utf8;
  isnt(perl_critic_config_id(Perl::Critic->new( -profile => "$profile" )), $id, 'changing the severity DOES change the config');

  $profile->spew_utf8(<<'EOF');
only = 1
[TestingAndDebugging::RequireUseStrict]
severity = 5
equivalent_modules = Test2::V0
EOF

  note "CONFIG:\n", $profile->slurp_utf8;
  isnt(perl_critic_config_id(Perl::Critic->new( -profile => "$profile" )), $id, 'changing a property DOES change the config');

  {
    local $Perl::Critic::VERSION = $Perl::Critic::VERSION . "00";

    note "CONFIG:\n", $profile->slurp_utf8;
    isnt(perl_critic_config_id(Perl::Critic->new( -profile => "$profile" )), $id, 'changing the version of Perl::Critic DOES change the id');
  }

  {
    local $Test2::Tools::PerlCritic::VERSION = '0.00';

    note "CONFIG:\n", $profile->slurp_utf8;
    isnt(perl_critic_config_id(Perl::Critic->new( -profile => "$profile" )), $id, 'changing the version of Test2::Tools::PerlCritic DOES change the id');
  }

};

done_testing;
