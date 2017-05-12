#!/usr/bin/perl
use strict;
use ExtUtils::MakeMaker;

my %opts = (
	NAME          => 'WWW::AuthTicket',
	VERSION_FROM  => 'AuthTicket.pm',
	PREREQ_PM     => {
		'CGI::Cookie'  => 1.26,
		'Digest::SHA1' => 2.11,
	}
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43)
{
	$opts{AUTHOR}   = 'John Winger <john@wingeronline.com>';
	$opts{ABSTRACT} = 'Handle authorization for web services or restricted areas of a website.';
}

WriteMakefile(%opts);
