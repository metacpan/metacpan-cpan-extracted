#!/usr/bin/perl

BEGIN{ require 5.006; }
use ExtUtils::MakeMaker;

# I’m keeping these separate, in case these modules should ever be dis-
# tributed individually:
%js_prq = (
	CSS::DOM::Interface           => 0,
	Encode                        => 0,
	Hash::Util::FieldHash::Compat => 0,
	HTML'DOM'EventTarget          => 0.032, # new event handler model
	HTML::DOM::Interface          => 0,
	Scalar::Util                  => 0,
	strict                        => 0,
	URI::Escape                   => 0,
	warnings                      => 0,
	WWW'Scripter                  => 0.022, # screen
# for testing:
	lib          => 0,
	Test::More   => 0,
	URI::file    => 0,
);
#if($] < 5.0080071 && !eval 'use LWP::UserAgent 5.815; 1') {
# $js_prq{'Bundle::LWP5_837'} = 0;
#}
#else {
 $js_prq{'LWP::UserAgent'} = 5.815; # handlers
#}

%je_prq = (
	Carp                          => 0,
	Hash::Util::FieldHash::Compat => 0,
	HTML::DOM::Interface          => 0.032, # UTF16 export
	JE                            =>  .038, # call_with
	JE::Destroyer                 => 0,
	Scalar::Util                  => 1.09, # refaddr
	strict                        => 0,
	warnings                      => 0,
# for testing:
	HTML'DOM     => 0.027, # document.write and node lists
	lib          => 0,
	Test::More   => 0,
	URI::file    => 0,
	WWW'Scripter =>  .016, # event2sub and $@
#	WWW'Scripter'Plugin'JavaScript => 0,
);
eval{require HTML::DOM and VERSION HTML::DOM == 0.034}
 and $je_prq{HTML::DOM} = 0.035; # getElementById bug

for(\(%js_prq, %je_prq)) {
	for $k(keys %$_) {
		$prq{$k} = $$_{$k}
			unless exists $prq{$k} and $$_{$k} < $prq{$k};
	}
}

# Incompatibility between old HTML::DOM and new HTML::Tree
eval{require HTML::DOM::Node and HTML::DOM::Node->VERSION < 0.051}
 and !eval{require HTML::Element} || VERSION HTML::Element >= 5
 and $prq{"HTML::DOM::Node"} = 0.051;

WriteMakefile(
    NAME                => 'WWW::Scripter::Plugin::JavaScript',
    AUTHOR              => 'Father Chrysostomos <sprout & cpan . org>',
    VERSION_FROM        => 'lib/WWW/Scripter/Plugin/JavaScript.pm',
#    VERSION             => "0.008a",
    ABSTRACT_FROM       => 'lib/WWW/Scripter/Plugin/JavaScript.pm',
    PL_FILES            => {},
    PREREQ_PM           => \%prq,
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'WWW-Scripter-Plugin-JavaScript-*' },
);
