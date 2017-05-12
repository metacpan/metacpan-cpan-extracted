use Test::More tests => 1;
BEGIN { use_ok('first') };

# use first GOOD::A, BAD::A, UGLY::A;

# use first BAD::B, GOOD::B, UGLY::B

# use first UGLY::C, BAD::C, GOOD::C

# use first {}, FAKE, {}

# use first BAD, BAD, BAD;

# require() still works

# use still works