use Test::More;

eval 'require Test::Distribution';
plan(skip_all => 'Test Distribution not installed') if($@);
Test::Distribution->import();
