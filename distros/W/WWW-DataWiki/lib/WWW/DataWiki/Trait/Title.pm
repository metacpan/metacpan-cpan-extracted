use 5.010;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Trait::Title::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Trait::Title::VERSION   = '0.001';
}

role WWW::DataWiki::Trait::Title
	# for WWW::DataWiki::Resource
{
	requires 'title_string';
}

