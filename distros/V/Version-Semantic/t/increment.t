use Test2::V1
  -pragmas,
  -target => { CLASS => 'Version::Semantic' },
  qw( dies is isa_ok like ok plan subtest );

plan 7;

like dies { CLASS->parse( 'v1.2.3' )->increment( 'pre_release' ) }, qr/not implemented/,
  'Unknown version incrementation strategy';

my $strategy;

subtest 'No strategy' => sub {
  plan 19;

  my $start = CLASS->parse( 'v1.2.3' );
  ok $start->is_core, 'Is core version';
  isa_ok my $self = $start->increment(), CLASS;
  is $self->prefix,       'v',      'prefix';
  is $self->major,        1,        'major';
  is $self->minor,        2,        'minor';
  is $self->patch,        4,        'patch';
  is $self->version_core, 'v1.2.4', 'version_core';
  ok $self->is_core, 'Is core version';
  ok $start < $self, 'Incremented';

  $start = CLASS->parse( '2.0.1' );
  ok $start->is_core, 'Is core version';
  isa_ok $self = $start->increment( undef, 'alpha.beta.1' ), CLASS;
  is $self->prefix,       undef,   'prefix';
  is $self->major,        2,       'major';
  is $self->minor,        0,       'minor';
  is $self->patch,        2,       'patch';
  is $self->version_core, '2.0.2', 'version_core';
  ok not( $self->is_core ), 'Is not core version';
  is "$self", '2.0.2-alpha.beta.1', 'Stringification';
  ok $start < $self, 'Incremented'
};

$strategy = 'patch';
subtest "\"$strategy\" strategy" => sub {
  plan 9;

  my $start = CLASS->parse( '1.2.3' );
  ok $start->is_core, 'Is core version';
  isa_ok my $self = $start->increment( $strategy ), CLASS;
  is $self->prefix,       undef,   'prefix';
  is $self->major,        1,       'major';
  is $self->minor,        2,       'minor';
  is $self->patch,        4,       'patch';
  is $self->version_core, '1.2.4', 'version_core';
  ok $self->is_core, 'Is core version';
  ok $start < $self, 'Incremented'
};

subtest "\"$strategy\" strategy with TRIAL pre-release" => sub {
  plan 10;

  my $start = CLASS->parse( '1.2.3' );
  ok $start->is_core, 'Is core version';
  isa_ok my $self = $start->increment( $strategy, 'TRIAL' ), CLASS;
  is $self->prefix,       undef,   'prefix';
  is $self->major,        1,       'major';
  is $self->minor,        2,       'minor';
  is $self->patch,        4,       'patch';
  is $self->version_core, '1.2.4', 'version_core';
  ok not( $self->is_core ), 'Is not core version';
  is "$self", '1.2.4-TRIAL', 'Stringification';
  ok $start < $self, 'Incremented'
};

$strategy = 'minor';
subtest "\"$strategy\" strategy" => sub {
  plan 13;

  my $start = CLASS->parse( 'v1.2.3-beta' );
  ok not( $start->is_core ), 'Is not core version';
  isa_ok my $self = $start->increment( $strategy ), CLASS;
  is $self->prefix,       'v',      'prefix';
  is $self->major,        1,        'major';
  is $self->minor,        3,        'minor';
  is $self->patch,        0,        'patch';
  is $self->version_core, 'v1.3.0', 'version_core';
  ok not( $self->is_core ), 'Is not core version';
  is $self->pre_release, 'beta', 'pre_release';
  ok $self->has_pre_release,  'pre_release is defined';
  ok not( $self->has_build ), 'build is not defined';
  is "$self", 'v1.3.0-beta', 'Stringification';
  ok $start < $self, 'Incremented'
};

$strategy = 'major';
subtest "\"$strategy\" strategy" => sub {
  plan 9;

  my $start = CLASS->parse( '1.2.3' );
  ok $start->is_core, 'Is core version';
  isa_ok my $self = $start->increment( $strategy ), CLASS;
  is $self->prefix,       undef,   'prefix';
  is $self->major,        2,       'major';
  is $self->minor,        0,       'minor';
  is $self->patch,        0,       'patch';
  is $self->version_core, '2.0.0', 'version_core';
  ok $self->is_core, 'Is core version';
  ok $start < $self, 'Incremented'
};

$strategy = 'trial';
subtest "\"$strategy\" strategy" => sub {
  plan 24;

  like dies { CLASS->parse( 'v1.2.3' )->increment( 'trial' ) }, qr/\ACannot apply '$strategy'/,
    'Version is not a pre-release version';
  like dies { CLASS->parse( 'v1.2.3-alpha.1' )->increment( 'trial' ) }, qr/does not match/,
    'Invalid pre-release extension';

  my $start = CLASS->parse( '1.2.3-TRIAL' );
  ok not( $start->is_core ), 'Is not core version';
  isa_ok my $self = $start->increment( $strategy ), CLASS;
  is $self->prefix,       undef,   'prefix';
  is $self->major,        1,       'major';
  is $self->minor,        2,       'minor';
  is $self->patch,        3,       'patch';
  is $self->version_core, '1.2.3', 'version_core';
  ok not( $self->is_core ), 'Is not core version';
  is $self->pre_release, 'TRIAL1', 'pre_release';
  ok $self->has_pre_release, 'pre_release is defined';
  ok $start < $self,         'Incremented';

  $start = CLASS->new(
    prefix      => 'v',
    major       => 4,
    minor       => 5,
    patch       => 8,
    pre_release => 'TRIAL004'
  );
  ok not( $start->is_core ), 'Is not core version';
  isa_ok $self = $start->increment( $strategy ), CLASS;
  is $self->prefix,       'v',      'prefix';
  is $self->major,        4,        'major';
  is $self->minor,        5,        'minor';
  is $self->patch,        8,        'patch';
  is $self->version_core, 'v4.5.8', 'version_core';
  ok not( $self->is_core ), 'Is not core version';
  is $self->pre_release, 'TRIAL5', 'pre_release (leading zeros removed!)';
  ok $self->has_pre_release, 'pre_release is defined';
  ok $start < $self,         'Incremented'
}
