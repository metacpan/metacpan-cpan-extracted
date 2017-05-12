# $File: //member/autrijus/only-latest/lib/only/latest.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 8676 $ $only: 2003/11/01 06:14:05 $

package only::latest;
use 5.006;

$only::latest::VERSION = '0.01';

=head1 NAME

only::latest - Always use the latest version of a module in @INC

=head1 VERSION

This document describes version 0.01 of only::latest, released
November 4, 2003.

=head1 SYNOPSIS

    use lib "/some/dir";
    use only::latest;
    use DBI; # use "/some/dir/DBI.pm" only if it's newer than system's

=head1 DESCRIPTION

This module is for people with separately-maintained INC directories
containing overlapping modules, who wishes to always use the latest version
of a module, regardless of the directory it is in.

If you C<use> or C<require> a module living in more than one directory,
the one with the highest C<$VERSION> is preferred, and its directory will
be tried first during the next time.  If there is a tie, the first-tried one
is used.

The implementation puts a hook in front of C<@INC>; this means it should
come after all C<use lib> statements.

If you wish to limit this module to some specific targets, list them as
the import arguments, like this:

    use only::latest qw(CGI CGI::Fast);
    use DBI; # not affected

=cut

sub import {
    my ($class, @pkgs) = @_;
    my %intercept = map { s{::}{/}g; "$_.pm" => 1 } @pkgs;
    my $cur_prefix;

    unshift @INC, sub {
	my ($self, $file) = @_;
	return undef if %intercept and !$intercept{$file};

	my ($cur_ver, $cur_file) = (-1, undef);
	foreach my $prefix ($cur_prefix, grep { $_ ne $cur_prefix } @INC) {
	    next if !defined($prefix) or ref($prefix);
	    my $pathname = "$prefix/$file";
	    next unless -e $pathname and !-d $pathname;
	    my $ver = $class->parse_version($pathname);
	    next unless $ver > $cur_ver;
	    $cur_prefix = $prefix if $cur_file; # if it wins, remember it
	    ($cur_ver, $cur_file) = ($ver, $pathname);
	}

	return undef unless $cur_file;
	open my($fh), $cur_file or return undef;
	return $fh;
    }
}

# Copied verbatim from ExtUtils::MM_Unix
sub parse_version {
    my($self,$parsefile) = @_;
    my $result;
    local *FH;
    local $/ = "\n";
    local $_;
    open(FH,$parsefile) or die "Could not open '$parsefile': $!";
    my $inpod = 0;
    while (<FH>) {
	$inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
	next if $inpod || /^\s*#/;
	chop;
	next unless /(?<!\\)([\$*])(([\w\:\']*)\bVERSION)\b.*\=/;
	my $eval = qq{
	    package ExtUtils::MakeMaker::_version;

	    local $1$2;
	    \$$2=undef; do {
		$_
	    }; \$$2
	};
        local $^W = 0;
	$result = eval($eval);
	warn "Could not eval '$eval' in $parsefile: $@" if $@;
	last;
    }
    close FH;

    $result = "undef" unless defined $result;
    return $result;
}

1;

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

Part of code derived from L<ExtUtils::MM_Unix>.

=head1 COPYRIGHT

Copyright 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
