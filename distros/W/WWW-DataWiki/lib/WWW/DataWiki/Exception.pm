use 5.010;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Exception::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Exception::VERSION   = '0.001';
}

class WWW::DataWiki::Exception
	with Throwable
	with StackTrace::Auto
	is mutable
{	
	has code        => (is=>'ro', isa=>'Num',            required=>1);
	has message     => (is=>'ro', isa=>'Maybe[Str]',     required=>1);
	has explanation => (is=>'ro', isa=>'Maybe[Str]',     required=>0);
	has params      => (is=>'ro', isa=>'Maybe[HashRef]', required=>0);
	has response_headers => (is => 'ro', isa=>'Maybe[HashRef]', required=>0, default => sub { {} });
	
	method new ($class: Num $code, Str $message?, Str $explanation?, $headers?)
	{
		$message //= 'Unexpected error';
		
		$class->SUPER::new(
			code        => $code,
			message     => $message,
			explanation => $explanation,
			response_headers => $headers,
			);
	}
}

package WWW::DataWiki::Exception;

use overload '""' => sub { sprintf("%s: %s", $_[0]->code, $_[0]->message); };

1;
