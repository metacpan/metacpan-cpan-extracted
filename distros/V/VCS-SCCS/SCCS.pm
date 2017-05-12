#!/pro/bin/perl

# Copyright (c) 2007-2016 H.Merijn Brand.  All rights reserved.

package VCS::SCCS;

use strict;
use warnings;

use POSIX  qw(mktime);
use Carp;

use vars qw( $VERSION );
$VERSION = "0.24";

### ###########################################################################

# We can safely use \d instead of [0-9] for this ancient format

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto	or return;

    # We can safely rule out "0" as a valid filename, ans 99.9999% of
    # SCCS source files start with s.
    my $fn = shift		or croak ("SCCS needs a valid file name");
    -e $fn			or croak ("$fn does not exist");
    -f $fn			or croak ("$fn is not a file");
    -s $fn			or croak ("$fn is empty");
    (my $filename = $fn) =~ s{\b(?:SCCS|sccs)/s\.(?=[^/]+$)}{};

    open my $fh, "<", $fn	or croak ("Cannot open '$fn': $!");

    # Checksum
    # ^Ah checksum
    <$fh> =~ m/^\cAh(\d+)$/	or croak ("SCCS file $fn is supposed to start with a checksum");

    my %sccs = (
	file		=> $filename,

	checksum	=> $1,
	delta		=> {},
	users		=> [],
	flags		=> {},
	comment		=> "",
	body		=> undef,

	current		=> undef,
	vsn		=> {},	# version to revision map

	tran		=> undef,
	);

    # Delta's At least one! ^A[ixg] ignored
    # ^As inserted/deleted/unchanged
    # ^Ad D version date time user v_new v_old
    # ^Am MR
    # ^Ac comment
    # ^Ae
    $_ = <$fh>;
    while (m{^\cAs (\d+)/(\d+)/(\d+)$}) {

	my @delta;

	my ($l_ins, $l_del, $l_unc) = map { $_ + 0 } $1, $2, $3;

	{   local $/ = "\cAe\n";
	    @delta = split m/\n/, scalar <$fh>;
	    }

	my ($type, $vsn, $v_r, $v_l, $v_b, $v_s,
		   $date, $y, $m, $d, $time, $H, $M, $S,
		   $user, $rev, $prv) =
	    (shift (@delta) =~ m{
		\cAd				# Delta
		\s+ ([DR])			# Type	Delta/Remove?
		\s+ ((\d+)\.(\d+)
		     (?:\.(\d+)(?:\.(\d+))?)?)	# Vsn	%R%.%L%[.%B%[.%S%]]
		\s+ ((\d\d)/(\d\d)/(\d\d))	# Date	%E%
		\s+ ((\d\d):(\d\d):(\d\d))	# Time	%U%
		\s+ (\S+)			# User
		\s+ (\d+)			# current rev
		\s+ (\d+)			# new     rev
		\s*$
		}x);
	$y += $y < 70 ? 2000 : 1900; # SCCS is not Y2k safe!

	# Type R rev's are removed/overridden deltas:
	# D 4.21 22 21
	# D 4.20 21 19
	# R 4.20 20 19
	# D 4.19 19 18

	my @mr   = grep { s/^\cAm\s*// } @delta; # MR number(s)
	my @cmnt = grep { s/^\cAc\s*// } @delta; # Comment

	$sccs{current} ||= [ $rev, $vsn, $v_r, $v_l, $v_b, $v_s ];
	$sccs{delta}{$rev} = {
	    lines_ins	=> $l_ins,
	    lines_del	=> $l_del,
	    lines_unc	=> $l_unc,

	    type	=> $type,

	    version	=> $vsn,	# %I%
	    release	=> $v_r,	# %R%
	    level	=> $v_l,	# %L%
	    branch	=> $v_b,	# %B%
	    sequence	=> $v_s,	# %S%

	    date	=> $date,	# %E%
	    time	=> $time,	# %U%
	    stamp	=> mktime ($S, $M, $H, $d, $m - 1, $y - 1900, -1, -1, -1),

	    committer	=> $user,

	    mr		=> join (", ", @mr),
	    comment	=> join ("\n", @cmnt),

	    prev_rev	=> $prv,
	    };
	exists $sccs{vsn}{$vsn} or $sccs{vsn}{$vsn} = $rev;
	$_ = <$fh>;
	}

    # Users
    # ^Au
    # user1
    # user2
    # ...
    # ^AU
    if (m{^\cAu}) {
	{   local $/ = "\cAU\n";
	   $sccs{users} = [ (<$fh> =~ m{^([A-Za-z].*)$}gm) ];
	   }
	$_ = <$fh>;
	}

    # Flags
    # ^Af q Project name
    # ^Af v ...
    # ^Af e 1
    while (m/^\cAf \s+ (\S) \s* (.+)?$/x) {
	$sccs{flags}{$1} = $2;
	$_ = <$fh>;
	}

    # Comment
    # ^At comment
    while (s/^\cA[tT]\s*//) {
	m/\S/ and $sccs{comment} .= $_;
	$_ = <$fh>;
	}

    # Body
    local $/ = undef;
    $sccs{body} = [ split m/\n/, $_ . <$fh> ];
    close $fh;

    return bless \%sccs, $class;
    } # new

sub file
{
    my $self = shift;
    return $self->{file};
    } # file

sub checksum
{
    my $self = shift;
    return $self->{checksum};
    } # checksum

sub users
{
    my $self = shift;
    return @{$self->{users}};
    } # users

sub flags
{
    my $self = shift;
    return { %{$self->{flags}} };
    } # flags

sub comment
{
    my $self = shift;
    return $self->{comment};
    } # comment

sub current
{
    my $self = shift;
    $self->{current} or return;
    wantarray ? @{$self->{current}} : $self->{current}[0];
    } # current

sub delta
{
    my ($self, $rev) = @_;
    $self->{current} or return;
    if (!defined $rev) {
	$rev = $self->{current}[0];
	}
    elsif (exists $self->{delta}{$rev}) {
	#$rev = $rev;
	}
    elsif (exists $self->{vsn}{$rev}) {
	$rev = $self->{vsn}{$rev};
	}
    else {
	return;
	}
    return { %{ $self->{delta}{$rev} } };
    } # delta

sub version
{
    my ($self, $rev) = @_;
    ref $self eq __PACKAGE__ or return $VERSION;
    $self->{current}         or return;

    # $self->version () returns most recent version
    $rev or return $self->{current}[1];

    # $self->revision (12) returns version for that revision
    exists $self->{delta}{$rev} and
	return $self->{delta}{$rev}{version};

    return;
    } # version

sub revision
{
    my ($self, $vsn) = @_;
    $self->{current} or return;

    # $self->revision () returns most recent revision
    $vsn or return $self->{current}[0];

    # $self->revision (12) returns version for that revision
    exists $self->{vsn}{$vsn} and
	return $self->{vsn}{$vsn};

    return;
    } # revision

sub revision_map
{
    my $self = shift;
    $self->{current} or return;

    return [ map { [ $_ => $self->{delta}{$_}{version} ] }
	sort { $a <=> $b }
	    keys %{$self->{delta}} ];
    } # revision

my %tran = (
    SCCS	=> {	# Documentation only
	},
    RCS		=> {
#	"%W%[ \t]*%G%"			=> '$""Id""$',
#	"%W%[ \t]*%E%"			=> '$""Id""$',
#	"%W%"				=> '$""Id""$',
#	"%Z%%M%[ \t]*%I%[ \t]*%G%"	=> '$""SunId""$',
#	"%Z%%M%[ \t]*%I%[ \t]*%E%"	=> '$""SunId""$',
#	"%M%[ \t]*%I%[ \t]*%G%"		=> '$""Id""$',
#	"%M%[ \t]*%I%[ \t]*%E%"		=> '$""Id""$',
#	"%M%"				=> '$""RCSfile""$',
#	"%I%"				=> '$""Revision""$',
#	"%G%"				=> '$""Date""$',
#	"%E%"				=> '$""Date""$',
#	"%U%"				=> '',
	},
    );

sub set_translate
{
    my ($self, $type) = @_;

    if (ref $type eq "HASH") {
	$self->{tran} = "CUSTOM";
	$tran{CUSTOM} = $type;
	}
    elsif (exists $tran{uc $type}) {
	$self->{tran} = uc $type;
	}
    else {
	$self->{tran} = undef;
	}
    } # set_translate

sub _tran
{
    my ($self, $line) = @_;
    my $tt = $self->{tran} or return $line;
    my $tr = $tran{$tt}    or return $line;
    my $re = $tr->{re};
    $line =~ s{($re)}{$tr->{$1}}g;
    return $line;
    } # _tran

sub translate
{
    my ($self, $rev, $line) = @_;

    my $type = $self->{tran}    or return $line;
    exists $self->{delta}{$rev} or return $line;

    (my $def_M = $self->file ()) =~ s{.*/}{};

    # TODO (or don't): %D%, %H%, %T%, %G%, %F%, %P%, %C%
    my %delta = %{$self->delta ($rev)};
    my $I = $delta{version};
    my $Z = "@(#)";
    my $M = exists $self->{flags}{"m"} ? $self->{flags}{"m"} : $def_M;
    my $Q = exists $self->{flags}{"q"} ? $self->{flags}{"q"} : "";
    my $Y = exists $self->{flags}{"t"} ? $self->{flags}{"t"} : "";
    $tran{SCCS}{"%U%"} = $delta{"time"};
    $tran{SCCS}{"%E%"} = $delta{"date"};
    $tran{SCCS}{"%R%"} = $delta{"release"};
    $tran{SCCS}{"%L%"} = $delta{"level"};
    $tran{SCCS}{"%B%"} = $delta{"branch"};
    $tran{SCCS}{"%S%"} = $delta{"sequence"};
    $tran{SCCS}{"%I%"} = $I;
    $tran{SCCS}{"%Z%"} = $Z;
    $tran{SCCS}{"%M%"} = $M;
    $tran{SCCS}{"%W%"} = "$Z$M\t$I";
    $tran{SCCS}{"%A%"} = "$Z$Y $M $I$Z";
    $tran{SCCS}{"%Q%"} = $Q;
    $tran{SCCS}{"%Y%"} = $Y;

    unless (exists $tran{$type}{re}) {
	my $kw = join "|", reverse sort keys %{$tran{$type}};
	$tran{$type}{re} = $kw ? qr{$kw} : undef;
	}

    return $self->_tran ($line);
    } # translate

sub body
{
    my $self = shift;

    $self->{body} && $self->{current} or return;
    my $r = shift || $self->{current}[0];

    exists $self->{vsn}{$r} and $r = $self->{vsn}{$r};

    my @lvl = ([ 1, "I", 0 ]);
    my @body;

#   my $v = sub {
#	join " ", map { sprintf "%s:%02d", $_->[1], $_->[2] } @lvl[1..$#lvl];
#	}; # v

    $self->translate ($r, "");	# Initialize translate hash

    my $want = 1;
    for (@{$self->{body}}) {
	if (m/^\cAE\s+(\d+)$/) {
	    my $e = $1;
#	    print STDERR $v->(), " END $e (@{$lvl[-1]})\n";
	    # SCCS has a seriously ill design so that chunks can overlap
	    # Below example is from actual code
	    # D 9
	    # E 9
	    # I 9
	    #  D 10
	    #  E 10
	    #  I 10
	    #   D 53
	    #   E 53
	    #   I 53
	    #   E 53
	    #   I 23
	    #    D 31
	    #    E 31
	    #    I 31
	    #     D 45
	    #     E 45
	    #     I 45
	    #     E 45
	    #     D 53 ---+
	    #    E 31     |
	    #   E 23      |
	    #  E 10       |
	    # E 9         |
	    # D 7         |
	    # E 7         |
	    # I 7         |
	    #     E 53 <--+
	    #  I 53
	    #  E 53
	    #  D 53
	    #  E 53
	    #  I 53
	    #  E 53
	    # E 7
	    foreach my $x (reverse 0 .. $#lvl) {
		$lvl[$x][2] == $e or next;
		splice @lvl, $x, 1;
		last;
		}
	    $want = (grep { $_->[0] == 0 } @lvl) ? 0 : 1;
	    next;
	    }
	if (m/^\cAI\s+(\d+)$/) {
	    push @lvl, [ $r >= $1 ? 1 : 0, "I", $1 ];
	    $want = (grep { $_->[0] == 0 } @lvl) ? 0 : 1;
	    next;
	    }
	if (m/^\cAD\s+(\d+)$/) {
	    push @lvl, [ $r >= $1 ? 0 : 1, "D", $1 ];
	    $want = (grep { $_->[0] == 0 } @lvl) ? 0 : 1;
	    next;
	    }
	if (m/^\cA(.*)/) {
	    carp "Unsupported SCCS control: ^A$1, line skipped";
	    next;
	    }
	$want and push @body, $self->_tran ($_);
#	printf STDERR "%2d.%04d/%s: %-29.29s |%s\n", $r, scalar @body, $want, $v->(), $_;
	}

    if ($self->{flags}{e} && @body && $body[0] =~ m/^[\x20-\x60]{1,61}$/) {
	my $body = unpack "u" => join "\n" => @body;
	$body and @body = split m/\n/ => $body;
	}

    return wantarray ? @body : join "\n", @body, "";
    } # body

1;

__END__

=head1 NAME

VCS::SCCS - OO Interface to SCCS files

=head1 SYNOPSIS

 use VCS::SCCS;

 my $sccs = VCS::SCCS->new ("SCCS/s.file.pl");   # Read and parse

 # Meta info
 my $fn = $sccs->file ();            # file.pl
 my $cs = $sccs->checksum ();        # 52534
 my @us = $sccs->users ();           # qw( merijn user )
 my $fl = $sccs->flags ();           # { q => "Test applic", v => undef }
 my $cm = $sccs->comment ();         # ""
 my $cr = $sccs->current ();         # 70
 my @cr = $sccs->current ();         # ( 70, "5.39", 5, 39 )

 # Delta related
 my $vs = $sccs->version ();         # "5.39"
 my $vs = $sccs->version (69);       # "5.38"
 my $rv = $sccs->revision ();        # 70
 my $rv = $sccs->revision ("5.37");  # 68
 my $rm = $sccs->revision_map ();    # [ [ 1, "4.1" ], ... [ 70, "5.39" ]]
 my $dd = $sccs->delta (17);         # none, revision or version as arg

 # Content related
 my $body_70 = $sccs->body ();       # file.pl @70 incl NL's
 my @body_70 = $sccs->body ();       # file.pl @70 list of chomped lines
 my @body_69 = $sccs->body (69);     # same for file.pl @96
 my @body_69 = $sccs->body ("5.38"); # same

 $sccs->set_translate ("SCCS");
 print $sccs->translate ($rev, $line);

 -- NYI --
 my $diff = $sccs->diff (67);        # unified diff between rev 67 and 70
 my $diff = $sccs->diff (63, "5.37");# unified diff between rev 63 and 68

=head1 DESCRIPTION

SCCS was the dominant version control system until the release of the
Revision Control System. Today, SCCS is generally considered obsolete.
However, its file format is still used internally by a few other revision
control programs, including BitKeeper and TeamWare. Sablime[1] also allows
the use of SCCS files. The SCCS file format uses a storage technique called
interleaved deltas (or the weave). This storage technique is now considered
by many revision control system developers as key to some advanced merging
techniques, such as the "Precise Codeville" ("pcdv") merge.

This interface aims at the possibility to read those files, without the
need of the sccs utility set, and open up to the possibility of scripts
that use it to convert to more modern VCSs like git, Mercurial, CVS, or
subversion.

=head1 FUNCTIONS

=head2 Meta function

=over 4

=item new (<file>)

The constructor only accepts a single argument: the SCCS file. this will
typically be something like C<SCCS/s.file.c>.

If anything in that file makes C<new ()> believe that it is not a SCCS
file, it will return undef. In this stage, there is no way yet to tell
why C<new ()> failed.

=item file

Returns the name of the parsed file. Useful if you have more than a
single $sccs object.

=item checksum

Returns the checksum that was stored in the file. This module does not
check if it is valid, nor does it have functionality to calculate a new
checksum.

=item users

Returns the list of users that was recorded in this file as authorized
to make deltas/changes.

=item flags

Returns a hash of the flags set for this file (if set at all). VCS::SCCS
does not do anything with these flags. They are here for the end-user only.

Note that not all flags are supported by all versions of C<admin>, like
C<x> is supported on HP-UX, but not in CSSC.

=over 4

=item t <type of program>

File has a user defined value for the %Y% keyword.

=item v [<program name>]

File was flagged to prompt for MR (using <program name> for validation).

=item i <keyword string>

File was flagged to require id keywords.

=item b

File was allowed to pass -b to get to create branch deltas.

=item m <module name>

File has a user defined value for the %M% keyword.

=item f <floor>

File was given a floor: the lowest release, a number from 1 to 9998, which
may be get for editing.

=item c <ceiling>

File was given a ceiling: a number less than or equal to 9999, which can
be retrieved by a get command.

=item d <default sid>

File was given a default delta number SID.

=item n

File created null deltas for skipped major versions.

=item j

File was flagged to allow concurrent edits on the same SID.

=item l <lock releases>

File was given a list of releases to which deltas can no longer be made.

=item q <user defined text>

File has a user defined value for the %Q% keyword.

=item s <line count>

Defines the number of lines scanned for keyword expansion. Past that
line, no keyword expansion takes place. Not implemented in all version.

This flag is a SUN extension that does not exist in historic SCCS
implementations and is completely ignored by C<VCS::SCCS>.

=item x (HP-UX, SCO)

File was flagged to set execution bit on get. This is the implementation
that VCS::SCCS knows about.

=item x SCHILY|0 (other)

Enable SCCS extensions that are not implemented in classical SCCS
variants. If the C<x> flag is enabled, the keywords %D%, %E%, %G%
and %H% are expanded even though not explicitly enabled by the C<y>
flag.

This flag is a SCHILY extension that does not exist in historic SCCS
implementations.

=item y <val> ...

The list of SCCS keywords to be expanded. If the C<y> flag is missing,
all keywords are expanded. If the flag is present but the list is empty,
no keyword is expanded and no "No id keywords" message is generated. The
value C<*> controls the expansion of the %sccs.include.filename% keyword.

This flag is a SUN/SCHILY extension that does not exist in historic SCCS
implementations.

This flag is currently ignored in C<VCS::SCCS>.

=item z <reserved for use in interfaces>

Used in Sun's NSE system.

=back

=item comment

The comment that was added when the file was created.

=item current

In scalar context returns the current revision number. That is the
number of the file that would be restored by get with no arguments.

In list context, it returns the current revision, version and parts
of the version, something like C<(70, "5.39", 5, 39, undef, undef)>.
The last 4 numbers are the equivalent of the keywords %R%, %L%, %B%,
and %S% for that release.

=item set_translate (<type>)

By default VCS::SCCS will not translate the SCCS keywords (like C<%W%>,
see C<translate ()> for the full list). With C<set_translate ()>, you
can select a translation type: C<SCCS> is currently the only supported
type, C<CVS> and C<RCS> are planned. Passing a false argument will reset
translation to none.

You can also pass a hashref that will do custom translation:

  my %trans = (
    "%W%" => "This is my what id",
    "%E%" => "Yesterday",
    "%U%" => "Noon",
    #...
    };
  $sccs->set_translate (\%tran);

any missing keywords will not be translated.

=back

=head2 Delta functions

=over 4

=item delta

=item delta (<revision>)

=item delta (<version>)

If called without argument, it returns the delta of the last revision
as a hashref.

If called with a revision argument, it returns you the delta of that
revision. If there is no such revision, returns undef.

If called with a version argument, it returns you the delta of that
version. If there is no such version, returns undef.

The elements of the hash returned are:

=over 4

=item lines_ins

The number of lines inserted in this delta

=item lines_del

The number of lines deleted in this delta

=item lines_unc

The number of lines unchanged in this delta

=item type

The type of this delta. Usually this will be a C<D>, but it could
also be a C<R>, which has not (yet) been tested.

=item version

The version (SID) of this delta

=item release

The release number of this delta

=item level

The level number of this delta

=item branch

The branch number of this delta. Can be undef

=item sequence

The sequence number of this delta. Can be undef

=item date

The date this delta was submitted in YY/MM/DD format

=item time

The time this delta was submitted in HH:MM:SS format

=item stamp

The C<date> and C<time> elements converted to a unix time stamp

=item committer

The logname of the user that committed this delta

=item mr

The MR numbers of this delta, separated by ", "

=item comment

The comment as entered with this delta

=back

=item version

=item version (<revision>)

If called without argument, it returns the last version, just as
the second return value of C<current ()> in list context.

If called with a revision argument, it returns you the version that
matches that revision. It returns undef if no matching version is
found.

=item revision

=item revision (<version>)

If called without argument, it returns the last revision, just as
C<current ()> returns in scalar context.

If called with a version argument, it returns you the revision that
matches that version. It returns undef if no matching revision is
found.

=item revision_map

Returns an anonymous list of C<revision> - C<version> pairs (in
anonymous lists).

=back

=head2 Content function

=over 4

=item body

=item body (<revision>)

=item body (<version>)

In scalar context returns the full body for the given revision.
If no revision is passed, the current (most recent) revision is
used. If a version is passed, the matching revision will be used.
If the is no matching version or revision, C<body ()> returns
C<undef>.

In list context, C<body ()> returns the list of chomped lines for
the given revision.

C<body ()> will use the translation set by C<set_translate ()>.

=item diff

NYI

=item translate (<revision>, <text>)

Translate the SCCS keywords in the text passed using the plan set
with C<set_translate ()>.

The SCCS keywords are

=over 4

=item %M%

Module name: either the value of the m flag in the file (see C<flags>),
or if absent, the name of the SCCS file with the leading s. removed.

=item %I%

SCCS identification (SID) (%R%.%L%.%B%.%S%) of the retrieved text.

=item %R%

Release.

=item %L%

Level.

=item %B%

Branch.

=item %S%

Sequence.

=item %D%

Current date (YY/MM/DD).

=item %H%

Current date (MM/DD/YY).

=item %T%

Current time (HH:MM:SS).

=item %E%

Date newest applied delta was created (YY/MM/DD).

=item %G%

Date newest applied delta was created (MM/DD/YY).

=item %U%

Time newest applied delta was created (HH:MM:SS).

=item %Y%

Module type: value of the t flag in the SCCS file (see C<flags>).

=item %F%

SCCS file name.

=item %P%

Fully qualified SCCS file name.

=item %Q%

The value of the q flag in the file (see C<flags>).

=item %C%

Current line number.  This keyword is intended for identifying messages
output by the program such as --this should not have happened-- type
errors.  It is not intended to be used on every line to provide sequence
numbers.

=item %Z%

The 4-character string @(#) @(#) recognizable by what (see what(1)).

=item %W%

A shorthand notation for constructing what(1) strings for HP-UX system
program files.  %W%=%Z%%M%horizontal-tab%I%

=item %A%

Another shorthand notation for constructing what(1) strings for
non-HP-UX system program files.  %A% = %Z%%Y% %M% %I%%Z%

=back

For now, %D%, %H%, %T%, %G%, %F%, %P%, and %C% are not translated.
I see no use for %D%, %H%, or %T%. People that use %G% have enough
problems already, so they should be able to cope, %F% and %P% lose
their meaning after conversion and %C% might be done later.

If you convert from SCCS to git, it might be advisable to not do
any translation at all, and leave the keywords in, just the way
they are, and create a checkout hook.

=back

=head1 SPECIFICATION

SCCS file format is reasonable well documented. I have included a
manual page for sccsfile for HP-UX in doc/

=head1 EXAMPLES

See the files in examples/ for my attempts to start converters to
other VCSs

=head1 BUGS AND LIMITATIONS

As this module is created as a base for conversion to more useful
and robust VCSs, it is a read-only interface to the SCCS files.

Translation is incomplete and might be questionable, but at least
there is a workaround.

=head1 TODO

 * improve documentation
 * implement diff ()
 * more tests
 * autodetect the available VCS candidates for sccs2***
 * sccs2git documentation and installation
 * sccs2rcs
 * sccs2cvs
 * sccs2hg
 * sccs2svn
 * errors and warnings
 * provide hooks to VCS::

=head1 DIAGNOSTICS

First errors, than diagnostics ...

=head1 SEE ALSO

=over 2

=item SCCS

source code at http://sccs.sourceforge.net/

manual pages at http://sccs.sourceforge.net/man/index.html

http://en.wikipedia.org/wiki/Source_Code_Control_System

=item CSSC

https://sourceforge.net/projects/cssc
A GNU project that aims to be a drop-in replacement for SCCS. It is
written in c++ and therefor disqualifies to be used at any older OS
that does support SCCS but has no C++ compiler. And even if you have
one, there is a good chance it won't build or does not bass the basic
tests. I did not get it to work.

=item VCS

http://search.cpan.org/dist/VCS

=item GIT

http://www.kernel.org/pub/software/scm/git/docs/

=back

=head1 AUTHOR

H.Merijn Brand <h.m.brand@xs4all.nl>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2016 H.Merijn Brand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
