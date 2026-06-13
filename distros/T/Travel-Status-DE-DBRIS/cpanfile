requires 'Class::Accessor';
requires 'DateTime';
requires 'DateTime::Format::Strptime';
requires 'Getopt::Long';
requires 'HTTP::Request', '7.00';
requires 'IO::Uncompress::Brotli', '0.004_002';
requires 'JSON';
requires 'List::Util';
requires 'LWP::UserAgent';
requires 'LWP::Protocol::https';

recommends 'GIS::Distance';

suggests 'Cache::File';

on test => sub {
	requires 'File::Slurp';
	requires 'Test::Compile';
	requires 'Test::More';
	requires 'Test::Pod';
};
