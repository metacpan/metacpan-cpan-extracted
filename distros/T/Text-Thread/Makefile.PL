#!/usr/bin/perl
# $File: //member/autrijus/GeekCode/Makefile.PL $ $Author: autrijus $
# $Revision: #4 $ $Change: 2162 $ $DateTime: 2001/10/20 01:13:05 $

use ExtUtils::MakeMaker;
require 5.005;

WriteMakefile (
    NAME         => 'Text::Thread',
    DISTNAME     => 'Text-Thread',
    ABSTRACT     => 'Convert tree structured items into ascii tree items',
    AUTHOR       => 'Chia-liang Kao (clkao@clkao.org)',
    VERSION_FROM => 'Thread.pm',
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' }
);
