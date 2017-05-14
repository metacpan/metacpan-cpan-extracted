package t::UnRTF;
use base qw(UnRTF::Test);
use Test::Most 'no_plan';

BEGIN {
  use UnRTF;
};

sub require_file_on_new : Tests {
  throws_ok { UnRTF->new } qr/Attribute.*file.*required/, 'file is required';
}

sub test_object : Tests {
  my $object = UnRTF->new(file => '');
  isa_ok($object, "UnRTF") or die "could not create UnRTF\n";
}

sub convert_rtf_file_to_text : Tests {
  my $object = UnRTF->new(file => 't/samples/sample.rtf');
  like($object->convert(format => 'text'), qr/# Translation from RTF performed by UnRTF/);
}

sub convert_to_blank_if_dont_tell_format : Tests {
  my $object = UnRTF->new(file => 't/samples/sample.rtf');
  is($object->convert(), '');
}
