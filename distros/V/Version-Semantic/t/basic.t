use Test2::V1
  -pragmas,
  -target => { CLASS => 'Version::Semantic' },
  qw( dies is isa_ok lives like ok plan subtest );

plan 15;

like dies { CLASS->new( major => 0, 'minor' ) }, qr/\AOdd number of elements in hash assignment at/,
  'Odd number of arguments';

## no critic ( ProhibitComplexRegexes )
like dies { CLASS->new( undef, 0 ) }, qr/\AUse of uninitialized value within \@_ in list assignment at/,
  'Attribute name cannot be undefined';

like dies { CLASS->new( trial => 'TRIAL1' ) }, qr/\AUnknown attribute name/, 'Unknown attribute name';

like dies { CLASS->new( major => '01' ) }, qr/\AAttribute .* has invalid value/, 'Invalid attribute value';

like dies { CLASS->new( major => 0 ) }, qr/Required attribute .* not set/, 'Missing required attribute';

like dies { CLASS->parse( undef, { fatal => 1 } ) }, qr/is not a semantic version/,
  'The undef value is an invalid semantic version';

like dies { CLASS->parse( '1.0.0-alpha_beta', { fatal => 1 } ) }, qr/is not a semantic version/,
  'Invalid semantic version';

like dies { CLASS->parse( '1.0.0_01', { fatal => 1 } ) }, qr/is not a semantic version/,
  'Perl underscore syntax does not refer to a semantic version';

is CLASS->parse( '0.500005' ), undef, 'Non "fatal" parsing of an invalid semantic version returns undef';

subtest 'Invalid semantic version' => sub {
  plan 39;

  my @versions = qw(
    1.2
    1.2.3-0123
    1.2.3-0123.0123
    1.1.2+.123
    +invalid
    -invalid
    -invalid+invalid
    -invalid.01
    alpha
    alpha.beta
    alpha.beta.1
    alpha.1
    alpha+beta
    alpha_beta
    alpha.
    alpha..
    beta
    1.0.0-alpha_beta
    -alpha.
    1.0.0-alpha..
    1.0.0-alpha..1
    1.0.0-alpha...1
    1.0.0-alpha....1
    1.0.0-alpha.....1
    1.0.0-alpha......1
    1.0.0-alpha.......1
    01.1.1
    1.01.1
    1.1.01
    1.2
    1.2.3.DEV
    1.2-SNAPSHOT
    1.2.31.2.3----RC-SNAPSHOT.12.09.1--..12+788
    1.2-RC-SNAPSHOT
    -1.0.3-gamma+b7718
    +justmeta
    9.8.7+meta+meta
    9.8.7-whatever+meta+meta
    99999999999999999999999.999999999999999999.99999999999999999----RC-SNAPSHOT.12.09.1--------------------------------..12
  );
  ok defined( dies { CLASS->parse( $_, { fatal => 1 } ) } ), "$_" for @versions
};

subtest 'Valid semantic versions' => sub {
  plan 32;

  my @versions = qw(
    0.0.4
    1.2.3
    10.20.30
    1.1.2-prerelease+meta
    1.1.2+meta
    1.1.2+meta-valid
    1.0.0-alpha
    1.0.0-beta
    1.0.0-alpha.beta
    1.0.0-alpha.beta.1
    1.0.0-alpha.1
    1.0.0-alpha0.valid
    1.0.0-alpha.0valid
    1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay
    1.0.0-rc.1+build.1
    2.0.0-rc.1+build.123
    1.2.3-beta
    10.2.3-DEV-SNAPSHOT
    1.2.3-SNAPSHOT-123
    1.0.0
    2.0.0
    1.1.7
    2.0.0+build.1848
    2.0.1-alpha.1227
    1.0.0-alpha+beta
    1.2.3----RC-SNAPSHOT.12.9.1--.12+788
    1.2.3----R-S.12.9.1--.12+meta
    1.2.3----RC-SNAPSHOT.12.9.1--.12
    1.0.0+0.build.1-rc.10000aaa-kk-0.1
    99999999999999999999999.999999999999999999.99999999999999999
    1.0.0-0A.is.legal
    1.0.8-20260216170758-TRIAL
  );
  ok lives { CLASS->parse( $_ ) }, "$_" for @versions
};

subtest 'Test named capture group accessors' => sub {
  plan 12;

  isa_ok my $self = CLASS->parse( '1.2.3-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay' ), CLASS;
  ok not( $self->has_prefix ), 'prefix is not defined';
  is $self->major,        1,       'major';
  is $self->minor,        2,       'minor';
  is $self->patch,        3,       'patch';
  is $self->version_core, '1.2.3', 'version_core';
  ok not( $self->is_core ), 'Is not core version';
  is $self->pre_release, 'alpha-a.b-c-somethinglong', 'pre_release';
  ok $self->has_pre_release, 'pre_release is defined';
  is $self->build, 'build.1-aef.1-its-okay', 'build';
  ok $self->has_build, 'build is defined';
  is "$self", '1.2.3-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay', 'Stringification'
};

subtest 'Test named capture group accessors: no pre-release but build information' => sub {
  plan 11;

  isa_ok my $self = CLASS->parse( '2.0.0+build.1848' ), CLASS;
  ok not( $self->has_prefix ), 'prefix is not defined';
  is $self->major,        2,       'major';
  is $self->minor,        0,       'minor';
  is $self->patch,        0,       'patch';
  is $self->version_core, '2.0.0', 'version_core';
  ok not( $self->is_core ),         'Is not core version';
  ok not( $self->has_pre_release ), 'pre_release is not defined';
  is $self->build, 'build.1848', 'build';
  ok $self->has_build, 'build is defined';
  is "$self", '2.0.0+build.1848', 'Stringification'
};

subtest 'Test named capture group accessors: "v" prefixed semantic version' => sub {
  plan 11;

  isa_ok my $self = CLASS->parse( 'v0.0.4' ), CLASS;
  ok $self->has_prefix, 'prefix is defined';
  is $self->prefix,       'v',      'prefix';
  is $self->major,        0,        'major';
  is $self->minor,        0,        'minor';
  is $self->patch,        4,        'patch';
  is $self->version_core, 'v0.0.4', 'version_core';
  ok $self->is_core,                'Is core version';
  ok not( $self->has_pre_release ), 'pre_release is not defined';
  ok not( $self->has_build ),       'build is not defined';
  is "$self", 'v0.0.4', 'Stringification'
};

subtest 'Test named capture group accessors: "-TRIAL[0-9]*" pre-releases' => sub {
  plan 25;

  my $expected_pre_release = 'TRIAL';
  isa_ok my $self = CLASS->parse( "1.0.5-$expected_pre_release" ), CLASS;
  ok not( $self->has_prefix ), 'prefix is not defined';
  is $self->major,        1,       'major';
  is $self->minor,        0,       'minor';
  is $self->patch,        5,       'patch';
  is $self->version_core, '1.0.5', 'version_core';
  ok not( $self->is_core ), 'Is not core version';
  is $self->pre_release, $expected_pre_release, "pre_release: $expected_pre_release";
  ok $self->has_pre_release,  'pre_release is defined';
  ok not( $self->has_build ), 'build is not defined';
  is "$self", "1.0.5-$expected_pre_release", 'Stringification';

  for ( 0 .. 13 ) {
    $expected_pre_release = "TRIAL$_";
    $self                 = CLASS->parse( "1.2.3-$expected_pre_release" );
    is $self->pre_release, $expected_pre_release, "pre_release: $expected_pre_release"
  }
}
