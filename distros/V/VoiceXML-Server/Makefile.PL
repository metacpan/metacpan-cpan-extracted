#!/usr/local/bin/perl -w
use ExtUtils::MakeMaker;
use diagnostics;
use strict;

WriteMakefile(
	      NAME         => 'VoiceXML::Server',
	      VERSION_FROM => "Server.pm",
	      DISTNAME     => "VoiceXML-Server"
	      );

