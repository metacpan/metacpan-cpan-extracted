use Test::More no_plan;
use Date::Manip;
use strict;
use warnings;

BEGIN
{
    use_ok 'WWW::Page::Author';
}

my $pkg = 'WWW::Page::Author';

my @expected = (
    {
	url	=> 'http://brucehall.anu.edu.au/',
	author	=> 'webmaster@brucehall.anu.edu.au',
    },
    {
	url	=> 'http://www.global-online.com.au/',
	author	=> 'info@global-online.com.au',
    },
    {
	url	=> 'http://www.transport.tas.gov.au/forms/pts030_6f.html',
	author	=> 'webmaster@dot.tas.gov.au',
    },
    {
	url	=> 'http://www.justice.tas.gov.au/breg/as_form_2.htm',
	author	=> 'stephen.mitchell@justice.tas.gov.au',
    },
    {
	url	=> 'http://www.andys.com.au',
	author	=> 'webmaster@andys.com.au',
    },
    {
	url	=> 'http://www.dpiwe.tas.gov.au/inter.nsf/ThemeNodes/EGIL-52P7SP?open',
	author	=> '[error]',
    },
    {
	url	=> 'http://www.acst.com.au/',
	author	=> 'acst@acst.com.au',
    },
);

my $dm = $pkg->new();

isa_ok $dm => $pkg;

is $dm->get_author($_->{url}) => $_->{author}, $_->{url} foreach (@expected);

TODO: {
    local $TODO = "Recursive fetch not implemented yet.";

    my @expected = 
    (
	{
	    url	=> 'http://www.apmi.com.au/',
	    author	=> 'info@apmi.com.au',
	},
	{
	    url	=> 'http://www.tas.alp.org.au/',
	    author	=> 'info@tas.alp.org.au',
	},
    );

    is $dm->get_author($_->{url}) => $_->{author}, $_->{url} foreach (@expected);
}
