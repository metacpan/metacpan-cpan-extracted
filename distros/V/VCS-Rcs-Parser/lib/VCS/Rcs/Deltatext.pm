#
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

require 5.8.0;
use strict;
use warnings;

use Data::Dumper;

use constant LINE => 0;
use constant NEXT => 1;
use constant PREV => 2;

our ($VERSION) = (q$Revision: 1.11 $ =~ /([\d\.]+)/);

our $debug = 0;

our $AUTOLOAD;


# Constractor
sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $self = {};

    bless $self, $class;
}


# Get revisions to checkout
sub revs2co {
    my $self = shift;
    $self->{__revs__} = shift;
}


# Convert plain text into linked list by lines
sub _text2list {
    my $text = shift;
    
    return [undef,undef,undef] unless defined($$text);
    
    my $pp;
    my $p0 = [undef,undef,undef];
    my $p  = $p0;
    while ($$text=~/\G([^\n]*\n)/gcs) {
        $pp = $p;
        $p = [$1, undef, $pp];
        $pp->[NEXT] = $p;
    }
    $p0;
}


# Convert a linked list into plain text
sub _list2text {
    my $p = shift;
    my $text;
    $text .= $p->[LINE] while ($p = $p->[NEXT]);
    return \$text;
}


# Keyword subs. (only Revision for now)
sub _kv {
    my $text = shift;
    my $rev = shift;

    pos($$text)=0;

    $rev = '$'."Revision: $rev ".'$';

    my $ltext;
    while ($$text=~/\G([^\n]*\n)/gcs) {
	my $tmp = $1;
	$tmp=~s{\x24Revision:[^\$]*\$}{$rev}g;
	$ltext .= $tmp;
    }
    return $ltext;
}

# Get the 'latest revision' first
sub lastrev {
    my $self = shift;
    my $text = shift;
    my $rev  = shift;

    $self->{__t__} = &_text2list($text);

    $self->{rev}->{$rev}->{__text__} = &_kv($text,$rev);
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

    # parse deltatext into a struct
    $self->{__a__} = {};
    pos($$text)=0;
    while ($$text=~/\G([^\n]*\n)/gcs) {

	my $tmp=$1;
	my($ad,$lineno,$numoflines) = ($tmp =~ /^(a|d)(\d+)\s+(\d+)/);

        $self->{__a__}{$lineno}{$ad} = $numoflines;

        next if ($ad eq 'd');

        for (my $i = 0; $i < $numoflines; $i++){
	    $$text=~/\G([^\n]*\n)/gcs;
            push @{ $self->{__a__}{$lineno}{a_line} } , $1;
	}
    }

    if ($debug) {
        print STDERR "\na:", Data::Dumper->Dump([$self->{__a__}]);
    }

    # do 'co' one revision
    my $p = $self->{__t__};
    my $i = 0;
    while ($p->[NEXT]){

	($p, $i) = $self->do_rev($p, $i);

	$p = $p->[NEXT];  # next
        $i++;
    }
    # anything left to do? do it then:
    ($p, $i) = $self->do_rev($p, $i);

    no warnings;
    # co everything if nothing is specified or
    # co only the wanted revisions texts ( this may save memory sometimes ;)
    if ( !$self->{__revs__} or (grep {$rev eq $_} @{$self->{__revs__}}) ) {
        $self->{rev}->{$rev}->{__text__} = 
	    &_kv(&_list2text($self->{__t__}),$rev);
    }

}


# Get a specific revision.
sub rev {
    my $self = shift;

    no warnings;
    my $rev  = shift;

    $self->{rev}->{$rev}->{__text__};
}


# Get a list of all or specified revisions.
sub revs {
    my $self = shift;

    $self->{__revs__} ?  @{$self->{__revs__}} : keys(%{$self->{rev}})
}


# Get a list of all revisions explicitly.
sub allrevs {
    my $self = shift;

    keys(%{$self->{rev}});
}


# internal: wrapper aroud 'add's and 'delete's
sub do_rev {
    my $self = shift;
    my $p = shift;
    my $i = shift;

    ($p, $i) = &d_rev($p, $self->{__a__}{$i}{d}, $i)      
	if (exists $self->{__a__}{$i}{d});

    $p       = &a_rev($p, $self->{__a__}{$i}{a_line},$i)  
	if (exists $self->{__a__}{$i}{a});

    ($p, $i)
}


# internal: apply delete command
sub d_rev {
    my $p = shift;
    my $j = shift;
    my $i = shift;

    for (my $k = 0; $k < $j; $k++) {
        $p->[PREV]->[NEXT] = $p->[NEXT];
        $p->[NEXT]->[PREV] = $p->[PREV];
        $p = $p->[NEXT];
    }

    $i = $i + $j - 1;

    ($p->[PREV], $i)
}


# internal: apply add command
sub a_rev {
    my $p = shift;
    my $a = shift;

    my $n;
    for (@$a) {
        $n = [$_,$p->[NEXT],$p];
        $p->[NEXT]->[PREV] = $n;
        $p->[NEXT] = $n;
        $p = $n;
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
    my $self = shift;
    my $p = $self->{__t__};

    my $tmp_p;
    my $i;
    #warn "\n\n";
    while ($p->[NEXT]){
        $tmp_p = $p->[NEXT];
        $p->[NEXT]=undef;
        $p->[PREV]=undef;
	$p = $tmp_p;  # next
	#print STDERR $i++;
    }
    $self->{__t__}=undef;
    #print STDERR Data::Dumper->Dump([$self->{__t__}]);

    for my $arevs (keys %{$self->{rev}}) {
	$self->{rev}->{$arevs}->{__text__}=undef;
    }
  
    $self={};
    #warn "\n\n";
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


    @all_revisions = $dt->revs();

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

Ziya Suzen, ziya@ripe.net

=head1 SEE ALSO

rcsfile(5), diff(1), patch(1), Rcs(3), perl(1).

=cut


