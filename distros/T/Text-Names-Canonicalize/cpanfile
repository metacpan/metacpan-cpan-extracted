# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008';

requires 'Exporter';
requires 'JSON::MaybeXS';
requires 'Scalar::Util';
requires 'YAML::XS';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};
on 'test' => sub {
	requires 'Test::DescribeMe';
	requires 'Test::Most';
	requires 'Test::Needs';
};
on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
