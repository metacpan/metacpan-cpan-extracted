# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 34;
BEGIN { use_ok('Text::Beautify',qw(beautify enable_feature disable_feature features enabled_features enable_all disable_all)) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$bad_string  = " some people do all  kind of stupid things ,,you know ?? :-) ";
$good_string = "Some people do all kind of stupid things, you know? :-)";

$string{heading_space} =
	"some people do all  kind of stupid things ,,you know ?? :-) ";
$string{trailing_space} =
	" some people do all  kind of stupid things ,,you know ?? :-)";
$string{space_in_front_of_punctuation} =
	" some people do all  kind of stupid things,,you know?? :-) ";
$string{double_spaces} =
	" some people do all kind of stupid things ,,you know ?? :-) ";
$string{repeated_punctuation} =
	" some people do all  kind of stupid things ,you know ? :-) ";
$string{space_after_punctuation} =
	" some people do all  kind of stupid things ,, you know ?? :-) ";
$string{uppercase_first} =
	" Some people do all  kind of stupid things ,,you know ?? :-) ";

is(enabled_features(),features());
ok(disable_feature(features()));
ok(enable_feature(features()));
is(enabled_features(),features());
ok(disable_feature(features()));
is(enabled_features(),0);
is(beautify($bad_string),$bad_string);

@allfeatures = features();

for (@allfeatures) {
  disable_feature(@allfeatures);
  enable_feature($_);
  is(enabled_features,1);
  is(beautify($bad_string),$string{$_});
  disable_feature($_);
}

ok(enable_feature(features()));
is(beautify($bad_string),$good_string);

disable_all();
is(beautify($bad_string),$bad_string);
enable_all();
is(beautify($bad_string),$good_string);

is(beautify('ok'),'Ok');
is(beautify('OK'),'OK');
is(beautify('oK'),'OK');
is(beautify('Ok'),'Ok');

is(beautify('Wait.. wait'),'Wait. Wait');
is(beautify('Wait... wait'),'Wait... Wait');
is(beautify('Wait.... wait'),'Wait... Wait');
is(beautify('I\'m ok'),'I\'m ok');

__END__

" some people do all  kind of stupid things ,,you know ?? "
"some people do all  kind of stupid things ,,you know ?? "
"some people do all  kind of stupid things ,,you know ??"
"some people do all kind of stupid things ,,you know ??"
"some people do all kind of stupid things ,you know ?"
"some people do all kind of stupid things,you know?"
"some people do all kind of stupid things, you know?"
"Some people do all kind of stupid things, you know?"
