#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2001-2009,2017,2018 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
# WWW:  https://github.com/eserte/tk-pathentry
#

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk";
my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough) {
    no warnings 'once';
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

WriteMakefile
  (
   'NAME'	   => 'Tk::PathEntry',
    AUTHOR         => 'Slaven Rezic <srezic@cpan.org>',
   'VERSION_FROM'  => 'PathEntry.pm',
   'ABSTRACT'      => 'Entry widget for selecting paths with completion',
   'PREREQ_PM'     => { Tk => 800.020 },

    ($eumm_recent_enough
     ? (META_MERGE => { resources  => { repository => 'git://github.com/eserte/tk-pathentry.git' },
			author     => ['Klaus Wittrock <wittrock@cpan.org>'],
		      },
       )
     : ()
    ),
  );

sub MY::postamble {
    my $postamble = "";

    if ($is_devel_host) {
	$postamble .= <<'EOF';

PERL_TEST_DISTRIBUTION_CHANGES=yes

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}

__END__
