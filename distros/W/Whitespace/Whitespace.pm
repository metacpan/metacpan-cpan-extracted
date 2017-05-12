package Whitespace;
use strict;

#
# $Id: Whitespace.pm,v 1.4 2001/05/23 21:36:50 rv Exp $
#

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION = 1.02;
    @ISA = qw(Exporter);
    @EXPORT = qw(&new &detect &cleanup &error &status);
    @EXPORT_OK = qw(&leadclean &trailclean &indentclean &spacetabclean
		    &eolclean &DESTROY);
    %EXPORT_TAGS = ();
}

=head1 NAME

Whitespace - Cleanup various types of bogus whitespace in source files.

=head1 SYNOPSIS

    use Whitespace;

    # Instantiate a whitespace object with
    # both input and output files specified
    $ws = new Whitespace($infile, $outfile);

    # Instantiate a whitespace object with
    # only the input files specified (in-place cleanup)
    $ws2 = new Whitespace($infile);

    # Detect the whitespaces
    $ret = $ws->detect();

C<detect> returns B<undef> if it is unable to operate on the given
file.

The error that caused the undef can be retrieved using C<error>

    print $ws->error() . "\n" unless defined $ret;

C<detect> returns the types of whitespaces detected as a hash which
can be retrieved using the method C<status>. The populated hash might
look like this, if the file only had leading, trailing and end-of-line
spaces (say on 3 lines).

    %stat = %{$env->status()};
    print map "$_ => $stat{$_}\n", sort keys %stat;

    eol => 3
    indent => 0
    leading => 1
    spacetab => 0
    trailing => 1

Cleanup can be achieved for all the whitespaces or for just a given
type of whitespace, using the following methods.

If a B<outfile> is given, the cleaned contents are written to this
file. If not, the contents are replaced in-place.  B<undef> is
returned if there was an error writing the file.

    # To cleanup the all the whitespaces
    $ret = $env->cleanup();

    # To cleanup leading whitespaces only
    $leadstat = $env->leadclean();

    # To cleanup trailing whitespaces only
    $trailstat = $env->trailclean();

    # To cleanup indentation whitespaces only
    $indentstat = $env->indentclean();

    # To cleanup space-followed-by-tabs only
    $sftstat = $env->spacetabclean();

    # To cleanup end-of-line whitespaces only
    $eolstat = $env->eolclean();

=cut

#
# Exported Functions
#
sub new {
    my $package = shift;
    my $env = {
	'infile' => shift,
	'outfile' => shift,
	'cleaned' => 0,
    };
    bless $env, $package;
}

sub detect {
    my $env = shift;
    my $ret = 0;
    my $infile = $env->{cleaned} ? $env->{'outfile'} : $env->{'infile'};

    unless (defined $infile) {
	$env->{'error'} = "No input file!";
	return undef;
    }
    if (-d $infile) {
	$env->{'error'} = "$infile: Is a directory!";
	return undef;
    }
    if (ref $infile) {
	$env->{'error'} = "$infile: Is not a regular file (a reference)!";
	return undef;
    }
    unless (open FILE, $infile) {
	$env->{'error'} = "$infile: $!";
	return undef;
    }
    if (! -T _) {
	close FILE;
	$env->{'error'} = "$infile: Not a text file!";
	return undef;
    }
    $env->{'_IFILE'} = *FILE;

    my $first = 1;
    my $leading = 0;
    my $trailing = 0;
    my $indent = 0;
    my $spacetab = 0;
    my $ateol = 0;
    while (<FILE>) {
	if (! /^.*\n$/) {
#	    warn "$infile: Line too long\n";
	    $env->{'error'} = "$infile: Line too long";
	    last;
	}

=head1 DESCRIPTION

=item Leading space

Empty lines at the top of a file.

=cut
	$leading = 1 if $first && /^[ \t]*$/;

=item Trailing space

Empty lines at the end of a file.

=cut
	$trailing = /^[ \t]*$/ ? 1 : 0;

=item Indentation space

8 or more spaces at the beginning of a line, that should be replaced with
TABS.

    Since this is the most controversial one, here is the rationale:
    Most terminal drivers and printer drivers have TAB configured or
    even hardcoded to be 8 spaces. (Some of them allow configuration,
    but almost always they default to 8.)

    Changing tab-width to other than 8 and editing will cause your
    code to look different from within emacs, and say, if you cat it
    or more it, or even print it.

    Almost all the popular programming modes let you define an offset
    (like c-basic-offset or perl-indent-level) to configure the
    offset, so you should never have to set your tab-width to be other
    than 8 in all these modes. In fact, with an indent level of say,
    4, 2 TABS will cause emacs to replace your 8 spaces with one \t
    (try it). If vi users in your office complain, tell them to use
    vim, which distinguishes between tabstop and shiftwidth (vi
    equivalent of our offsets), and also ask them to set smarttab.

=cut
	$indent = 1 if /^\s* {8,}/;

=item Spaces followed by a TAB.

Almost always, we never want that.

=cut
	$spacetab = 1 if / \t/;


=item EOL Whitespace

Spaces or TABS at the end of a line.

=cut

	$ateol = 1 if /[ \t]$/;
	$first = 0;
    }
    close FILE;
    $env->{'_IFILE'} = undef;
    return undef if defined $env->{'error'};
    ++$ret if $leading;
    ++$ret if $indent;
    ++$ret if $spacetab;
    ++$ret if $ateol;
    ++$ret if $trailing;

    ++$env->{'status'}->{'leading'} if $leading;
    ++$env->{'status'}->{'trailing'} if $trailing;
    ++$env->{'status'}->{'indent'} if $indent;
    ++$env->{'status'}->{'spacetab'} if $spacetab;
    ++$env->{'status'}->{'eol'} if $ateol;

    return $ret;
}

sub cleanup {
    my $env = shift;
    my $infile = $env->{'infile'};
    my $outfile = $env->{'outfile'};
    my $cleanup => $env->{'cleanup'};

    unless (defined $infile) {
	$env->{'error'} = "No input file!";
	return undef;
    }
    if (-d $infile) {
	$env->{'error'} = "$infile: Is a directory!";
	return undef;
    }
    if (ref $infile) {
	$env->{'error'} = "$infile: Is not a regular file (a reference)!";
	return undef;
    }
    unless (open FILE, $infile) {
	$env->{'error'} = "$infile: $!";
	return undef;
    }
    $env->{'_IFILE'} = *FILE;
    if (defined $outfile) {
	unless (open OUTFILE, ">$outfile") {
	    $env->{'error'} = "$outfile: $!";
	    close FILE;
	    return $env->{'_IFILE'} = undef;
	}
	close OUTFILE;
    } else {
	unless (-w $infile) {
	    $env->{'error'} = "$infile: Not writable!";
	    return undef;
	}
	$outfile = $infile;
	$env->{'outfile'} = $env->{'infile'};
    }

    my @arr = <FILE>;
    close FILE;
    $env->{'_IFILE'} = undef;
    #
    # Leading/Trailing space cleanup
    #
    @arr = _leadtrailclean(@arr)
	if (!defined $cleanup || $cleanup->{'leading'});
    @arr = reverse _leadtrailclean(reverse @arr)
	if (!defined $cleanup || $cleanup->{'trailing'});

    #
    # Indentation cleanup
    #
    @arr = _indentclean(@arr)
	if (!defined $cleanup || $cleanup->{'indent'});

    #
    # EOL Space cleanup
    #
    @arr = _eolclean(@arr)
	if (!defined $cleanup || $cleanup->{'eol'});

    #
    # Space-followed-by-TAB cleanup
    #
    @arr = _spctabclean(@arr)
	if (!defined $cleanup || $cleanup->{'spacetab'});

    use File::Spec 0.8;
    my ($junk, $tmp);
    ($junk, $junk, $tmp) = File::Spec->splitpath($infile);
    my $tmpdir = File::Spec->tmpdir;

    $tmp = File::Spec->catfile($tmpdir, "$tmp.$$");
    unless (open FILE, ">$tmp") {
	$env->{'error'} = "$tmp: $!. $infile not cleaned";
	return undef;
    }
    $env->{'_TFILE'} = *FILE;
    print FILE @arr;
    close FILE;
    $env->{'_TFILE'} = undef;

    use File::Copy qw(move);
    move($tmp, $outfile);

    #
    # Test the file once again.
    #
    $env->{'cleaned'} = 1;
    return $env->detect;
}

sub leadclean {
    my $env = shift;
    $env->{'cleanup'}->{'leading'} = 1;
    return $env->cleanup;
}

sub trailclean {
    my $env = shift;
    $env->{'cleanup'}->{'trailing'} = 1;
    return $env->cleanup;
}

sub indentclean {
    my $env = shift;
    $env->{'cleanup'}->{'indent'} = 1;
    return $env->cleanup;
}

sub spacetabclean {
    my $env = shift;
    $env->{'cleanup'}->{'spacetab'} = 1;
    return $env->cleanup;
}

sub eolclean {
    my $env = shift;
    $env->{'cleanup'}->{'eol'} = 1;
    return $env->cleanup;
}

sub error {
    my $env = shift;
    $env->{'error'};
}

sub status {
    my $env = shift;
    $env->{'status'};
}

sub DESTROY {
    my $env = shift;
    my $ifh = $env->{'_IFILE'};
    my $tfh = $env->{'_TFILE'};
#    warn "destroying whitespace object for $env->{'infile'}\n";
    close $ifh if defined $ifh;
    close $tfh if defined $tfh;
}

#
# Internal functions
#
sub _leadtrailclean {
    my $first = 1;
    my @ret = ();
    foreach (@_) {
	if ($first) {
	    if (! /^[ \t]*$/) {
		$first = 0;
		push @ret, $_;
	    }
	} else {
	    $first = 0;
	    push @ret, $_;
	}
    }
    return @ret;
}

sub _indentclean {
    my @ret = ();
    foreach (@_) {
	while (/^\s* {8,}/) {
	    $_ =~ s/^(\t*) {8}/$1\t/g;
	}
	push @ret, $_;
    }
    return @ret;
}

sub _eolclean {
    my @ret = ();
    foreach (@_) {
	$_ =~ s/[ \t]*$//g;
	push @ret, $_;
    }
    return @ret;
}

sub _spctabclean {
    my @ret = ();
    foreach (@_) {
	while (/ \t/) {
	    s/ \t/_brinkoftabstop($`) ? "\t\t" : "\t"/eg;
	}
	push @ret, $_;
    }
    return @ret;
}

#
# This sub ensures that while cleaning space-followed-by-TAB issues,
# we don't blindly cleanup at tab boundaries.
#
# For instance, "1234567 \t" should change to "1234567\t\t" and not to
# "1234567\t", which would not look the same as the original.
#
sub _brinkoftabstop {
    my $s = shift;
    $s =~ s/.*\t//;
    return length($s) % 8 == 7;
}

1;

=head1 ACKNOWLEDGMENTS

This module is based on the original B<whitespace> program written by
Bradley W. White, distributed under the same license as the module
itself.

=head1 AUTHORS

Rajesh Vaidheeswarran E<lt>rv@gnu.orgE<gt>

Bradley W. White

=head1 LICENSE

Copyright (C) 2000-2001 Rajesh Vaidheeswarran

All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
