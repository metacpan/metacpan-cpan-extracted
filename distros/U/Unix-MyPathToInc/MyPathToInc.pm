package Unix::MyPathToInc;

# Paper over the general silliness that I've run into in a few odd
# cases where you're insane enough to say "please add the place this
# executable can be found in to the language's library search path".
# As such, this is a special case module: you shouldn't be using it if
# you can't figure out how the words "race condition" could apply.

# $Id: MyPathToInc.pm,v 1.1 2005/09/14 00:46:06 hag Exp $

use strict;
use warnings;

our $VERSION = "0.1";

####

use File::Spec;
use File::Basename qw(dirname);

####

# XXX import time interface doesn't exactly leave a lot of room for
# minor twiddles in the general idea.  Reserve all :foo?
sub import {
    my $type = shift;

    if(@_ == 0) {
	add_include();
    } else {
	map { add_include($_); } @_;
    }
}

sub add_include {
    my $path = shift;

    my $out_path = sub {
	# Not the best way of doing this, but prolly good enough.
	if(defined($path)) {
	    return($_[0] . "/$path");
	} else {
	    return($_[0]);
	}
    };

    die "No hope of converting a -e script to a location for includes"
	if($0 eq "-e");

    if($0 =~ m,^/,) {
	# Beyond just being the obvious fully qualified path case,
	# this appears to cover a common perl DWIM, where perl seems
	# to search PATH for us.  POSIX makes no such promise about
	# argv[0].
	unshift(@INC, &{$out_path}(dirname($0)));
	return;
    }
    if($0 =~ m,/,) {
	unshift(@INC, &{$out_path}(File::Spec->rel2abs(dirname($0))));
	return;
    }

    # Blech.  Always searching . is nominally reasonable in this case.
    # I'd prefer to only do it when I knew I had no choice, but there
    # is no such knowledge.
    foreach my $p (split(":", $ENV{PATH}), ".") {
	if( -x "$p/$0" ) {
	    unshift(@INC, &{$out_path}(File::Spec->rel2abs($p)));
	    return;
	}
    }

    # The most obvious way to get here is to run a script via perl
    # foo.pl or some such, where foo.pl is not executable.

    die "Failed to perform any work; perhaps this script isn't executable?";
}

####

1;

####

__END__

=head1 NAME

Unix::MyPathToInc - Add the location of the current program to @INC.

=head1 SYNOPSIS

  use Unix::MyPathToInc;

  use Unix::MyPathToInc qw(/ lib);

=head1 DESCRIPTION

Add the location of the current program to @INC, or perhaps several
subdirectories related to the location of $0.  If used with no
imports, adds the current directory to @INC, or dies.  Imports can be
used to name directories relative to the program location (use an
import of "/" to name the directory containing $0 when using explicit
imports).

=head1 BUGS

Requires that the script be executable.

Using $0 to modify @INC is criminally insane from a security
standpoint.  Don't use this module unless you understand its
consequences.
