#
# Copyright (C) 2011 by Opera Software Australia Pty Ltd
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR	    => 'Greg Banks <gnb@fastmail.fm>',
    NAME	    => 'Tree::Interval',
    VERSION_FROM    => 'lib/Tree/Interval.pm',
    BUILD_REQUIRES  => {
	'Test::Unit'	    => '0.25',
    },
);
