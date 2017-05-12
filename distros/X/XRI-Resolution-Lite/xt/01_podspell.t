use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Toru Yamaguchi
zigorou@cpan.org
XRI::Resolution::Lite
HTTPS
MediaType
Refs
SAML
URI
cation
cid
https
param
refs
saml
sep
ua
uric
url
