use Test2::V1
  -pragmas,
  -target => { CLASS => 'Version::Semantic' },
  qw( is ok plan subtest );

plan 2;

my $trial_release_date_re = qr/(?: Not\ Released | Development\ Release | Development | Developer\ Release )/x; ## no critic ( ProhibitComplexRegexes )
my $w3cdtf_utc_re = qr/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z/;
# CPAN::Changes::Parser uses [:;.-]?\s+ as $spaces_re which matches "- " but not " - "
my $spaces_re = qr/ +/;

subtest 'Known TRIAL release date' => sub {
  plan tests => 12;

  my $input        = 'v1.2.3 2026-02-25T14:54:45Z TRIAL release';
  my $input_length = length $input;
  ok not( defined( pos( $input ) ) ),               'No match has yet been run on input';
  ok $input =~ m/\G ${ \( CLASS->semver_re ) }/gcx, 'Match version';
  is \%+, { prefix => 'v', major => 1, minor => 2, patch => 3 }, 'Named capture buffers';
  is pos( $input ), 6, 'Offset';
  ok $input =~ m/\G ${spaces_re}/gcx, 'Match spaces';
  is pos( $input ), 7, 'Offset';
  ok $input =~ m/\G $w3cdtf_utc_re /gcx, 'Match UTC normalized W3CDTF';
  is pos( $input ), 27, 'Offset';
  ok $input =~ m/\G ${spaces_re}/gcx, 'Match spaces';
  is pos( $input ), 28, 'Offset';
  ok $input =~ m/\G TRIAL\ release /gcx, 'Match note to identify a TRIAL release';
  is pos( $input ), $input_length, 'Offset'
};

subtest 'Special TRIAL release date string ("Not Released")' => sub {
  plan tests => 13;

  my $input        = 'v1.2.3 Not Released some optional text';
  my $input_length = length $input;
  ok not( defined( pos( $input ) ) ),               'No match has yet been run on input';
  ok $input =~ m/\G ${ \( CLASS->semver_re ) }/gcx, 'Match version';
  my $self = CLASS->new( %+ );
  ok not( $self->has_pre_release ), 'Is not a pre-release version';
  ok not( $self->has_build ),       'Version has no build extension';
  is pos( $input ), 6, 'Offset';
  ok $input =~ m/\G ${spaces_re}/gcx, 'Match spaces';
  is pos( $input ), 7, 'Offset';
  ok $input =~ m/\G $trial_release_date_re /gcx, 'Match date string to identify a TRIAL release';
  is pos( $input ), 19, 'Offset';
  # No need to continue the tokenization
  ok $input =~ m/\G ${spaces_re}/gcx, 'Match spaces';
  is pos( $input ), 20, 'Offset';
  ok $input =~ m/\G some\ optional\ text /gcx, 'Match note';
  is pos( $input ), $input_length, 'Offset'
}

