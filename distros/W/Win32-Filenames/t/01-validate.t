use Test::More tests => 14;

use Win32::Filenames qw( validate );

# First test good names.

ok( validate('good'), '[good] should be valid name.' );
ok( validate('real_good.txt'), '[real_good.txt] should be valid name.');
ok( validate('no_problemo_guys.doc'), '[no_problemo_guys.doc] should be valid name.' );

# Test odd names that are valid

ok( validate('@IMok'), '[@IMok] is still valid.' );
ok( validate('there is no !\'problems[]'), '[there is no !\'problems[] is still valid.' );
ok( validate('I~am(valid).doc'), '[I~am(valid).doc] is still valid.' );

# Test bad names

ok( !validate('dd|'), '[dd|] should not be valid.' );
ok( !validate('d<.txt', '[d<.txt] should not be valid.') );
ok( !validate('>.doc'), '[>.doc] should not be valid.' );
ok( !validate('?ucks'), '[?ucks] should not be valid.' );
ok( !validate('looks\\good'), '[looks\\good] should not be valid.' );
ok( !validate('hahahahah.a:a'), '[hahahahah.a:a] should not be valid.' );
ok( !validate('jojo/'), '[jojo/] should not be valid.' );
ok( !validate('bye"bye'), '[bye"bye] should not be valid.' );

