use Module::Build;

Module::Build -> new
(
 module_name    => 'Text::CSV_PP::Iterator',
 license        => 'artistic',
 dist_abstract  => 'Provide fetchrow_hashref() for CSV files',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 Test::More => 0,
	 Test::Pod  => 0,
 },
 requires =>
 {
	 Exception::Class => 0,
	 Iterator         => 0,
	 Iterator::IO     => 0,
	 Text::CSV_PP     => 0,
 },
) -> create_build_script();
