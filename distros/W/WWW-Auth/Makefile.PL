#!/usr/bin/perl


use strict;
use ExtUtils::MakeMaker;


my %opts = (
  NAME          => 'WWW::Auth',
  VERSION_FROM  => 'lib/WWW/Auth.pm',
  PREREQ_PM     => {
    'CGI'		=> 2.91,
    'CGI::Cookie'	=> 1.22,
    'LWP::UserAgent'	=> 2.003,
    'HTTP::Request'	=> 1.30,
    'MD5'		=> 2.02
  }
);
if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
  $opts{AUTHOR}   = 'Jonathan Waxman <jowaxman@bbl.med.upenn.edu>';
  $opts{ABSTRACT} = 'A ticket based web authentication package.';
}
WriteMakefile (%opts);
