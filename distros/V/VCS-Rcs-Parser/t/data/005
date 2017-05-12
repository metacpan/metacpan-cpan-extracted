head	1.9;
access;
symbols
	rel-0-1:1.1.1.1 ziya:1.1.1;
locks; strict;
comment	@# @;


1.9
date	2001.10.03.15.31.59;	author ziya;	state Exp;
branches;
next	1.8;

1.8
date	2001.10.03.15.07.35;	author ziya;	state Exp;
branches;
next	1.7;

1.7
date	2001.10.02.16.27.26;	author ziya;	state Exp;
branches;
next	1.6;

1.6
date	2001.10.01.16.23.02;	author ziya;	state Exp;
branches;
next	1.5;

1.5
date	2001.10.01.08.34.47;	author ziya;	state Exp;
branches;
next	1.4;

1.4
date	2001.09.27.18.26.58;	author ziya;	state Exp;
branches;
next	1.3;

1.3
date	2001.09.14.16.02.29;	author ziya;	state Exp;
branches;
next	1.2;

1.2
date	2001.09.11.15.52.24;	author ziya;	state Exp;
branches;
next	1.1;

1.1
date	2001.09.11.12.26.01;	author ziya;	state Exp;
branches
	1.1.1.1;
next	;

1.1.1.1
date	2001.09.11.12.26.01;	author ziya;	state Exp;
branches;
next	;


desc
@@


1.9
log
@last modifications for namespace change.
@
text
@#
# Copyright (c) 2001 by RIPE-NCC.  All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# You should have received a copy of the Perl license along with
# Perl; see the file README in Perl distribution.
#
# You should have received a copy of the GNU General Public License
# along with Perl; see the file Copying.  If not, write to
# the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
#
# You should have received a copy of the Artistic License
# along with Perl; see the file Artistic.
#
#                            NO WARRANTY
#
# BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
# FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
# OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
# PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
# OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
# TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
# PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
# REPAIR OR CORRECTION.
#
# IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
# WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
# REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
# INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
# OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
# TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
# YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
# PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGES.
#
#                     END OF TERMS AND CONDITIONS
#
#
package VCS::Rcs::Parser;

require 5.6.0;
use strict;
use warnings;
use Carp;

use VCS::Rcs::YappRcsParser;
use VCS::Rcs::Deltatext;

our $VERSION = '0.04';

my $dt;

sub new {
    my $this  = shift;
    my $rtext = shift;
    my %param = @@_;

    my $revs  = delete $param{revs};
    my $dates = delete $param{dates};

    croak "Unexpected Parameter(s):",(join ',', keys %param) if %param;

    (ref($rtext) eq 'SCALAR') or croak "Scalar Ref. to Text is missing!";

    if($revs){ (ref($revs) eq 'ARRAY') or croak "revs must be arrayref!"};

    if($dates){ (ref($dates) eq 'ARRAY') or croak "dates must be arrayref!"};


    my $class = ref($this) || $this;
    my $self = {};
    bless $self ,$class;


    my $rcs = new VCS::Rcs::YappRcsParser;
    $dt = $rcs->Run($rtext, $revs, $dates);  # VCS::Rcs::Deltatext

    for my $rev ($dt->revs) {
        my $rdate = $dt->date($rev);
	next unless (defined $rdate);
        $rdate = '19'.$rdate if (length($rdate) ==  17);
        $self->{__date_index__}{$rdate} = $rev;
        $self->{__rev_index__}{$rev} = $rdate;
    }

    $self
}


sub co {
    my $self = shift;
    my %param = @@_;

    my $rev  = delete $param{rev};
    my $date = delete $param{date};

    croak "Unexpected Parameter(s):",(join ',', keys %param) if %param;
 
    return $dt->rev($rev) if (defined $rev);

    my @@alldates  = sort keys %{$self->{__date_index__}};


    my($a,$date_proper);

    for $a (@@alldates) {
	$date_proper=$a if ($a lt $date);
    }

    $dt->rev($self->{__date_index__}{$date_proper})
}


sub revs {
    my $self = shift;
    my %param = @@_;

    my $index = delete $param{index};

    croak "Unexpected Parameter(s):",(join ',', keys %param) if %param;

    $index eq 'date' and return ($self->{__date_index__});

    $index eq 'rev' and return ($self->{__rev_index__});

    croak "Unexpected value(s):",(join ',', values %param);
}


1;


__END__


=head1 NAME

VCS::Rcs::Parser - Perl extension for RCSfile Parsing

=head1 SYNOPSIS

  use VCS::Rcs::Parser;

  # Read a *,v file into $text
  $text = do {local $/; <>};

  my $rcs = VCS::Rcs::Parser->new(\$text);

  print $rcs->co(rev => '1.1');


=head1 DESCRIPTION

Reads a ',v' RCS revisions file and checks out every revision into core.
There will be more documentation soon.

=head1 AUTHOR

Ziya Suzen, ziya@@ripe.net

=head1 SEE ALSO

perl(1).

=cut
@


1.8
log
@namespace changed from Rcs:: to VCS::Rcs::
@
text
@d78 2
a79 2
    my $rcs = new Rcs::YappRcsParser;
    $dt = $rcs->Run($rtext, $revs, $dates);  # Rcs::Deltatext
d141 1
a141 1
Rcs::Parser - Perl extension for RCSfile Parsing
d145 1
a145 1
  use Rcs::Parser;
d150 1
a150 1
  my $rcs = Rcs::Parser->new(\$text);
@


1.7
log
@Solved some 'undefined ...' warnings.
@
text
@d42 1
a42 1
package Rcs::Parser;
d49 2
a50 2
use Rcs::YappRcsParser;
use Rcs::Deltatext;
@


1.6
log
@date co future added.
@
text
@d52 1
a52 1
our $VERSION = '0.03';
d83 1
d125 3
a127 1
    $index eq 'date' and return ($self->{__rev_index__});
@


1.5
log
@Fixed a bug in the lexer, causing strings ending without a new line to breake the syntax in the grammar.
@
text
@d47 1
d52 1
a52 1
our $VERSION = '0.02';
d59 14
d77 1
d79 8
a86 1
    $dt = $rcs->Run($rtext); # Rcs::Deltatext
d96 17
a112 1
    $dt->rev($param{rev})
d120 7
a126 11
    $param{index} eq 'date' and do {
	my %date;
	my $rdate;
	my $rev;
        for $rev ($dt->revs) {
            $rdate = $dt->date($rev);
	    $rdate = '19'.$rdate if (length($rdate) ==  17);
            $date{$rev} = $rdate;
        }
	return (\%date);
    }
@


1.4
log
@added copyright info.
@
text
@d51 1
a51 1
our $VERSION = '0.01';
@


1.3
log
@a little nasty bug; do not use the time as the key in the hash; there may be some people doing a quick check in more then once less then a second!!!
@
text
@d1 41
d119 2
@


1.2
log
@Last fixes.
@
text
@d47 1
a47 1
            $date{$rdate} = $rev;
@


1.1
log
@Initial revision
@
text
@a40 1
	print "IN INDEX DATE\n";
@


1.1.1.1
log
@Initial release.
@
text
@@
