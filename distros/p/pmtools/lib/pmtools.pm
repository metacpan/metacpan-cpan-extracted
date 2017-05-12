package pmtools;

use strict;
use warnings;

our $VERSION = '2.0.0';

sub new_pod_iterator {
    my ($module) = @_;      # module name

    my $index     = 0;      # index of all possible POD files
    my $inc_index = 0;      # index into @INC
    my $pod_index = 0;      # index into @pods
    my @pods  = (           # list of possible POD files given an @INC directory
        "pod/$module.pod",
        "$module.pod",
        "$module.pm",
    );

    return sub {
        if ($index >= scalar @INC * scalar @pods) {
            return undef;
        }

        $inc_index = $index / scalar @pods;
        $pod_index = $index % scalar @pods;
        $index++;

	    return "$INC[$inc_index]/$pods[$pod_index]";
    };
}

1;


# ------ From Tom Christiansen's original README file for pmtools:
# This is pmtools -- a suite of small programs to help manage modules.
# The names are totally preliminary, and in fact, so is the code.  We follow
# the "keep it small" notion of many tiny tools each doing one thing well,
# eschewing giant megatools with millions of options.
#
# Tom Christiansen
# tchrist@perl.com

=head1 NAME

pmtools - Perl Module Tools

=head1 SYNOPSIS

pmdesc module ...
pmpath module ...
pmvers module ...
...
sitepods
...

=head1 DESCRIPTION

Perl Modules Tools (pmtools) is a suite of tools designed
originally by Tom Christiansen.

For each module name given as an argument, produces its full path on
the standard output, one per line.

=head1 EXAMPLES

    $ pmpath CGI
    /usr/local/devperl/lib/5.00554/CGI.pm

    $ filsperl -S pmpath IO::Socket CGI::Carp
    /usr/local/filsperl/lib/5.00554/i686-linux-thread/IO/Socket.pm
    /usr/local/filsperl/lib/5.00554/CGI/Carp.pm

    $ oldperl -S pmpath CGI CGI::Imagemap
    /usr/lib/perl5/CGI.pm
    /usr/lib/perl5/site_perl/CGI/Imagemap.pm

=head1 SEE ALSO

pmdesc(1),
pmvers(1),
pmcat(1).

=head1 AUTHORS and COPYRIGHTS

Copyright (C) 1999 Tom Christiansen.

Copyright (C) 2006-2014 Mark Leighton Fisher.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it
under the terms of either:
(a) the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or
(b) the Perl "Artistic License".
(This is the Perl 5 licensing scheme.)

Please note this is a change from the
original pmtools-1.00 (still available on CPAN),
as pmtools-1.00 were licensed only under the
Perl "Artistic License".
