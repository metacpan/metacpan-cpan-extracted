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
date	2001.09.12.16.31.28;	author ziya;	state Exp;
branches;
next	1.2;

1.2
date	2001.09.12.14.31.20;	author ziya;	state Exp;
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
package VCS::Rcs::Deltatext;

require 5.6.0;
use strict;
use warnings;

use Data::Dumper;

our ($VERSION) = (q$Revision: 1.1 $ =~ /([\d\.]+)/);

my $t;
my %a;
our $debug = 0;

our $AUTOLOAD;


# Constractor
sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $self = {};
    $t = undef;
    %a = ();

    bless $self, $class;
}


# Get revisions to checkout
sub revs2co {
    my $self = shift;
    $self->{__revs__} = shift;
}


# Convert plain text into linked list by lines
sub _text2list {
    my $self = shift;
    my $text = shift;

    return [undef,undef,undef] unless defined($$text);

    my $pp;
    my $p0 = [undef,undef,undef];
    my $p  = $p0;
    while ($$text =~ /\G([^\n]*\n)/gcs) {
        $pp = $p;
        $p = [$1, undef, $pp];
        $pp->[1] = $p;
    }
    $p0
}


# Convert a linked list into plain text
sub _list2text {
    my $self = shift;
    my $p = shift;
    my $text;
    $text .= $p->[0] while ($p = $p->[1]);
    return $text;
}


# Get the 'latest revision' first
sub lastrev {
    my $self = shift;
    my $text = shift;
    my $rev  = shift;

    $t = $self->_text2list($text);
    $self->{rev}->{$rev}->{__text__} = $$text;
}


# Apply deltatexts to the last state of revisions
sub deltarev {
    my $self  = shift;
    my $text  = shift;
    my $rev   = shift;

    if ($debug) {
        print STDERR "\nself:", Data::Dumper->Dump([$self]);
        print STDERR "\ntext:", $$text, "<<<";
        print STDERR "\nrev:", $rev;
    }

    return unless (defined($text));

    my $pr = $self->_text2list($text);

    # parse deltatext into a struct
    %a = ();
    while ($pr = $pr->[1]){
      
	$pr->[0] =~ /^(a|d)(\d+)\s+(\d+)/;

        $a{$2}{$1} = $3;

        next if ($1 eq 'd');

        for (my $i = 0; $i < $3; $i++){
	    $pr = $pr->[1]; # next
            push @@{ $a{$2}{a_line} } , $pr->[0];
	}
    }

    if ($debug) {
        print STDERR "\na:", Data::Dumper->Dump([\%a]);
    }

    # do 'co' one revision
    my $p = $t;
    my $i = 0;
    while ($p->[1]){

	($p, $i) = &do_rev($p, $i);

	$p = $p->[1];  # next
        $i++;
    }
    # anything left to do? do it then:
    ($p, $i) = &do_rev($p, $i);

    # co everything if nothing is specified or
    # co only the wanted revisions texts ( this may save memory sometimes ;)
    if ( !$self->{__revs__} or (grep {$rev eq $_} @@{$self->{__revs__}}) ) {

        $self->{rev}->{$rev}->{__text__} = $self->_list2text($t);
    }

}


# Get a specific revision.
sub rev {
    my $self = shift;
    my $rev  = shift;

    $self->{rev}->{$rev}->{__text__};
}


# Get a list of all or specified revisions.
sub revs {
    my $self = shift;

    $self->{__revs__} ?  @@{$self->{__revs__}} : keys(%{$self->{rev}})
}


# Get a list of all revisions explicitly.
sub allrevs {
    my $self = shift;

    keys(%{$self->{rev}});
}


# internal: wrapper aroud 'add's and 'delete's
sub do_rev {
    my $p = shift;
    my $i = shift;

    ($p, $i) = &d_rev($p, $a{$i}{d}, $i)      if (exists $a{$i}{d});
    $p =       &a_rev($p, $a{$i}{a_line},$i)  if (exists $a{$i}{a});

    ($p, $i)
}


# internal: apply delete command
sub d_rev {
    my $p = shift;
    my $j = shift;
    my $i = shift;

    for (my $k = 0; $k < $j; $k++) {
        $p->[2]->[1] = $p->[1];
        $p->[1]->[2] = $p->[2];
        $p = $p->[1];
    }

    $i = $i + $j - 1;

    ($p->[2], $i)
}


# internal: apply add command
sub a_rev {
    my $p = shift;
    my $a = shift;

    my $n;
    for (@@$a) {
        $n = [$_,$p->[1],$p];
        $p->[1]->[2] = $n;
        $p->[1] = $n;
        $p = $p->[1];
    }
    $p
}


# Assingne other specials to the revisions (like date and author)
sub AUTOLOAD {
    my $self = shift;
    my $rev  = shift;
    my $val  = shift;

    return unless (defined $rev);

    $self->{rev}->{$rev}->{$AUTOLOAD} = $val if defined($val);
    $self->{rev}->{$rev}->{$AUTOLOAD};
}


sub DESTROY {
    undef $t;
}


1;


__END__


=head1 NAME

VCS::Rcs::Deltatext - Perl extension for RCS like Deltatext parsing

=head1 SYNOPSIS

    use VCS::Rcs::Deltatext;
   
    my $dt = new VCS::Rcs::Deltatext();

    # Parse RCS file and find the last revision.
    # Put 'Last Revision' in
    $dt->lastrev($ref_text, $rev);

    # Parse RCS file and find the following revisions
    # Aply the deltatext
    $dt->deltarev($ref_deltatext, $rev);

    # add other details
    $dt->date($rev. $date);
    $dt->author($rev. $author);
    $dt->anything($rev. $anything);
    ...
    ...
    # more 'deltarev's and details


    @@all_revisions = $dt->revs();

    print "Revisions Text    : ", $dt->rev('1.1'),      "\n";
    print "Revisions Date    : ", $dt->date('1,1'),     "\n"; 
    print "Revisions Athor   : ", $dt->author('1,1'),   "\n";
    print "Revisions Anything: ", $dt->anything('1,1'), "\n";


=head1 DESCRIPTION

VCS::Rcs::Deltatext, simply applies 'diff -n' style patches. This format is
used in RCS files to keep the file history. Because there is no other 
use for today (as far as I know) this class is put under VCS::Rcs::. Unless
you have a verygood reason not to use patch(1) 


=head2 METHODS

=over 8

=item C<new>

 $o = new VCS::Rcs::Deltatext;

Create a new instance of VCS::Rcs::Deltatext.

=item C<lastrev>
 
 $o->lastrev($ref_text, $rev);

Put the latest revision into the object.

=item C<deltarev>

 $o->deltarev($ref_deltatext, $rev);

Patch the latest revision stored in the object. $ref_deltatext is a 
referanse to a scalar containing the text with the C<diff -n> style
format. It is constracted from two simple command. C<d> delete and C<a> add.
Here is a sample:

 d2 1
 a2 1
 Text to be added
 d5 4
 a8 2
 More text to add
 And more.

This kind of format is used in RCS files. And also if you use diff(1) command
with the option C<-n> you should get the same sort of format.

=item C<rev>
 
 $o->rev($rev);

Get a specific revision.

=item C<date>

 $o->date($rev, $date);
 $o->date($rev);

Assigne or get a date for a revision

=item C<author>

 $o->author($rev, $author_name);
 $o->author($rev);

Assigne or get a author name for a revision

=item C<anything>

 $o->anything($rev, $date);
 $o->anything($rev);

Assigne or get any kind of other information you want to keep for a revision.
This is an AUTOLOAD future.

=back

=head1 BUGS

It keeps all the revisions in the object, and uses split on ant text you supply
so it can be a memory monster if you are working with large number of
revisions or text.

There will be more documentation soon.

=head1 AUTHOR

Ziya Suzen, ziya@@ripe.net

=head1 SEE ALSO

rcsfile(5), diff(1), patch(1), Rcs(3), perl(1).

=cut


@


1.8
log
@namespace changed from Rcs:: to VCS::Rcs::
@
text
@d50 1
a50 1
our ($VERSION) = (q$Revision: 1.1 $ =~ /([\d\.]+)/);
d274 1
a274 1
Rcs::Deltatext - Perl extension for RCS like Deltatext parsing
d278 1
a278 1
    use Rcs::Deltatext;
d280 1
a280 1
    my $dt = new Rcs::Deltatext;
d290 1
a290 1
    # add athor details
d292 1
a292 1
    $dt->authoe($rev. $author);
d309 1
a309 1
Rcs::Deltatext, simply applies 'diff -n' style patches. This format is
d311 1
a311 1
use for today (as far as I know) this class is put under Rcs::. Unless
d321 1
a321 1
 $o = new Rcs::Deltatext;
d323 1
a323 1
Create a new instance of Rcs::Deltatext.
@


1.7
log
@Solved some 'undefined ...' warnings.
@
text
@d42 1
a42 1
package Rcs::Deltatext;
d50 1
a50 1
our ($VERSION) = (q$Revision: 1.1 $ =~ /([\d\.]+)/);
@


1.6
log
@date co future added.
@
text
@d50 1
a50 1
our ($VERSION) = (q$Revision: 1.1 $ =~ /([\d\.]+)/);
d186 1
a186 1
# Get a list of all revisions.
d189 9
d253 2
@


1.5
log
@Fixed a bug in the lexer, causing strings ending without a new line to breake the syntax in the grammar.
@
text
@d50 1
a50 1
our ($VERSION) = (q$Revision: 1.1 $ =~ /([\d\.]+)/);
d63 1
a63 1
    my $self  = {};
d71 7
d107 1
a107 1
# Get the 'initial revision'
d167 7
a173 1
    $self->{rev}->{$rev}->{__text__} = $self->_list2text($t);
@


1.4
log
@added copyright info.
@
text
@d48 3
a50 1
our ($VERSION) = (q$Revision: 1.1 $ =~ /([\d\.]+)/);
a56 2

require Data::Dumper if $debug;
@


1.3
log
@sorted the problem of calling new more then onece in one program.
@
text
@d1 41
d48 1
a48 1
our ($VERSION) = (q$Revision: 1.1 $ =~ /([\d\.]+)/);
d362 2
@


1.2
log
@version info added.
a smal fix to check emty text.
@
text
@d7 1
a7 1
our ($VERSION) = (q$Revision: 1.1 $ =~ /([\d\.]+)/);
d23 3
@


1.1
log
@Initial revision
@
text
@d7 1
a7 1
our $VERSION = '0.01';
d11 1
a11 1
my $debug = 0;
d31 2
@


1.1.1.1
log
@Initial release.
@
text
@@
