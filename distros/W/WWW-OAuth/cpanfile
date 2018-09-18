requires 'perl' => '5.008001';
requires 'Carp';
requires 'Class::Tiny::Chained';
requires 'Digest::SHA';
requires 'List::Util' => '1.33';
requires 'Module::Runtime';
requires 'Role::Tiny' => '2.000000';
requires 'Scalar::Util';
requires 'URI' => '1.28';
requires 'URI::Escape' => '3.26';
requires 'WWW::Form::UrlEncoded' => '0.23';
recommends 'WWW::Form::UrlEncoded::XS' => '0.23';
on test => sub {
	requires 'Data::Dumper';
	requires 'JSON::PP';
	requires 'Test::More' => '0.88';
	requires 'Test::Needs';
};
on develop => sub {
	requires 'HTTP::Request';
	requires 'HTTP::Tiny' => '0.014';
	requires 'LWP::UserAgent';
	recommends 'Mojolicious' => '7.54';
	requires 'Test::TCP';
};
