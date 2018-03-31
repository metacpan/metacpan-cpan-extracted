use Test::More;
eval "use Test::DocClaims";
plan skip_all => "Test::DocClaims not found" if $@;
all_doc_claims();
