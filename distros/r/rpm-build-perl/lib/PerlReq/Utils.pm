package PerlReq::Utils;

=head1	NAME

PerlReq::Utils - auxiliary routines for L<B::PerlReq>, L<perl.req> and L<perl.prov>

=head1	DESCRIPTION

This module provides the following convenience functions:

=over

=cut

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(argv explode inc path2mod mod2path path2dep mod2dep sv_version verf verf_perl);

use strict;

=item	B<path2mod>

Convert file path to module name, e.g. I<File/Find.pm> -> I<File::Find>.

=cut

sub path2mod ($) {
	local $_ = shift;
	s/\//::/g;
	s/\.pm$//;
	return $_;
}

=item	B<mod2path>

Convert module name to file path, e.g. I<File::Find> -> I<File/Find.pm>.

=cut

sub mod2path ($) {
	local $_ = shift;
	s/::/\//g;
	return $_ . ".pm";
}

=item	B<path2dep>

Convert file path to conventional dependency name,
e.g. I<File/Find.pm> -> I<perl(File/Find.pm)>.
Note that this differs from RedHat conventional form I<perl(File::Find)>.

=cut

sub path2dep ($) {
	my $path = shift;
	return "perl($path)";
}

=item	B<mod2dep>

Convert module name to conventional dependency name,
e.g. I<File::Find> -> I<perl(File/Find.pm)>.
Note that this differs from RedHat conventional form I<perl(File::Find)>.

=cut

sub mod2dep ($) {
	my $mod = shift;
	return path2dep(mod2path($mod));
}	

=item	B<verf>

Format module version number, e.g. I<2.12> -> I<2.120>.  Currently
truncated to 3 digits after decimal point, except for all zeroes, e.g.
I<2.000> -> I<2.0>.

Update.  The algorithm has been amended in almost compatible way
so that versions do not lose precision when truncated.  Now we allow
one more I<.ddd> series at the end, but I<.000> is still truncated
by default, e.g. I<2.123> -> I<2.123>, I<2.123456> -> I<2.123.456>.

=cut

sub verf ($) {
	my $v = shift;
	$v = sprintf "%.6f", $v;
	$v =~ s/[.]000000$/.0/ ||
		$v =~ s/000$// ||
		$v =~ s/(\d\d\d)$/.$1/ && $v =~ s/[.]000[.]/.0./;
	return $v;
}

=item	B<verf_perl>

Format Perl version number, e.g. I<5.005_03> -> I<1:5.5.30>.

=cut

sub verf_perl ($) {
	my $v = shift;
	my $major = int($v);
	my $minor = ($v * 1000) % ($major * 1000);
	my $micro = ($v * 1000 * 1000) % ($minor * 1000 + $major * 1000 * 1000);
	return "1:$major.$minor.$micro";
}

=item	B<sv_version>

Extract version number from B::SV object.  v-strings converted to floats
according to Perl rules, e.g. I<1.2.3> -> I<1.002003>.

=cut

sub sv_version ($) {
	my $sv = shift;
	if ($$sv == ${B::sv_yes()}) {
		# very special case: (0==0) -> 1
		return 1;
	}
	if ($sv->can("FLAGS")) {
		use B qw(SVf_IOK SVf_NOK);
		if ($sv->FLAGS & SVf_IOK) {
			return $sv->int_value;
		}
		if ($sv->FLAGS & SVf_NOK) {
			return $sv->NV;
		}
	}
	if ($sv->can("MAGIC")) {
		for (my $mg = $sv->MAGIC; $mg; $mg = $mg->MOREMAGIC) {
			next if $mg->TYPE ne "V";
			my @v = $mg->PTR =~ /(\d+)/g;
			return $v[0] + $v[1] / 1000 + $v[2] / 1000 / 1000;
		}
	}
	# handle version objects
	my $vobj = ${$sv->object_2svref};
	my $vnum;
	if (ref($vobj) eq "version") {
		$vnum = $vobj->numify;
		$vnum =~ s/_//g;
		return 0 + $vnum;
	}
	elsif ($sv->can("PV") and $sv->PV =~ /^[v.]?\d/) {
		# upgrade quoted-string version to version object
		require version;
		$vobj = eval { version->parse($sv->PV) };
		if ($@) {
			warn $@;
			return undef;
		}
		$vnum = $vobj->numify;
		$vnum =~ s/_//g;
		return 0 + $vnum;
	}
	return undef;
}

=item	B<argv>

Obtain a list of files passed on the command line.  When command line
is empty, obtain a list of files from standard input, one file per line.
Die when file list is empty.  Check that each file exists, or die
otherwise.  Canonicalize each filename with C<File::Spec::rel2abs()>
function (which makes no checks against the filesystem).

=cut

use File::Spec::Functions qw(rel2abs);
sub argv {
	my @f = @ARGV ? @ARGV : grep length, map { chomp; $_ } <>;
	die "$0: no files\n" unless @f;
	return map { -f $_ ? rel2abs($_) : die "$0: $_: $!\n" } @f;
}	

=item	B<inc>

Obtain a list of Perl library paths from C<@INC> variable, except for
current directory.  The RPM_PERL_LIB_PATH environment variable, if set,
is treated as a list of paths, seprarated by colons; put these paths
in front of the list.  Canonicalize each path in the list.

Finally, the RPM_BUILD_ROOT environment variable, if set, is treated as
installation root directory; each element of the list is then prefixed
with canonicalized RPM_BUILD_ROOT path and new values are put in front
of the list.

After all, only existent directories are returned.

=cut

my @inc;
sub inc {
	return @inc if @inc;
	my $root = $ENV{RPM_BUILD_ROOT}; $root &&= rel2abs($root);
	unshift @inc, map rel2abs($_), grep $_ ne ".", @INC;
	unshift @inc, map rel2abs($_), $ENV{RPM_PERL_LIB_PATH} =~ /([^:\s]+)/g;
	unshift @inc, map "$root$_", @inc if $root;
	return @inc = grep -d, @inc;
}

=item	B<explode>

Split given filename into its prefix (which is a valid Perl library
path, according to the inc() function above) and basename.  Return empty
list if filename does not match any prefix.

=cut

sub explode ($) {
	my $fname = shift;
	my ($prefix) =	sort { length($b) <=> length($a) }
			grep { index($fname, $_) == 0 } inc();
	return unless $prefix;
	my $delim = substr $fname, length($prefix), 1;
	return unless $delim eq "/";
	my $basename = substr $fname, length($prefix) + 1;
	return unless $basename;
	return ($prefix, $basename);
}

1;

__END__

=back

=head1	AUTHOR

Written by Alexey Tourbin <at@altlinux.org>.

=head1	COPYING

Copyright (c) 2004 Alexey Tourbin, ALT Linux Team.

This is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

=head1	SEE ALSO

L<B::PerlReq>, L<perl.req>, L<perl.prov>
