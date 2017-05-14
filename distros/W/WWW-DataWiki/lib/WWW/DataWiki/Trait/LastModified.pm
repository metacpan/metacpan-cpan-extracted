use 5.010;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Trait::LastModified::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Trait::LastModified::VERSION   = '0.001';
}

role WWW::DataWiki::Trait::LastModified
	# for WWW::DataWiki::Resource
{
	use DateTime::Format::HTTP;
	
	requires 'last_modified';
	
	method last_modified_http
	{
		return DateTime::Format::HTTP->format_datetime($self->last_modified);
	}
}

