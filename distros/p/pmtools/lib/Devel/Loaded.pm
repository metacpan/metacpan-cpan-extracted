# Loaded.pm -- show what files were loaded 
package Devel::Loaded;

# ABSTRACT: pmtools - Perl Module Tools

# ------ pragmas
use strict;
use warnings;
use File::Spec;

our $VERSION = '2.0.0';

# ----- define variable
my $path  = undef;	# current module path
our %Seen = ();		# track whether we've seen this module before

BEGIN { %Seen = %INC } 

END { 
    # get last part of Devel::Loaded path; handle File::Spec->canonpath() removing '.' from '.pm'
    my $devel_loaded = File::Spec->catfile('Devel', 'Loaded.pm');
    if ($devel_loaded =~ m/Loadedpm$/) {
        $devel_loaded =~ s/Loadedpm$/Loaded.pm/;
    }

    # delete the matching absolute path from %INC
    # NOTE: this will fail if you also have directories like ".../MyOwnDevel/Loaded.pm"
    my $inc_devel_loaded = "";
    foreach $path (keys(%INC)) {
       if ($path =~ m/$devel_loaded$/) {
            $inc_devel_loaded = $path;
            last;
        } 
    }
    if ($inc_devel_loaded ne "") {
        #delete $INC{$inc_devel_loaded};
    }

    for my $path (values %INC) {
       print "$path\n" unless $Seen{$path};
    }

}

1;

__END__

=head1 NAME

Devel::Loaded - Post-execution dump of loaded modules

=head1 SYNOPSIS

    perl -MDevel::Loaded programname 2>/dev/null

=head1 DESCRIPTION

The Devel::Loaded module installs an at-exit handler to generate a dump of
all the module files used by a Perl program.  If used in conjunction with
a I<perl -c>, you find those files loaded in at compile time with C<use>.
If you are willing to wait until after the program runs, you can get
them all.

=head1 EXAMPLES

This is compile-time only:

    $ perl -MDevel::Loaded perldoc 2>/dev/null
    /usr/local/devperl/lib/5.00554/Exporter.pm
    /usr/local/devperl/lib/5.00554/strict.pm
    /usr/local/devperl/lib/5.00554/vars.pm
    /usr/local/devperl/lib/5.00554/i686-linux/Config.pm
    /usr/local/devperl/lib/5.00554/Getopt/Std.pm

This will also catch run-time loads:

    #!/usr/bin/perl
    use Devel::Loaded;
    ...

=head1 SEE ALSO

The I<plxload> and the I<pmload> programs, which use
this technique.

Neil Bowers has written a L<review|http://neilb.org/reviews/dependencies.html> of
Perl modules for getting dependency information (26 of them at the time of writing). 

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
