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
#$Revision: 1.12 $

package VCS::Rcs::Parser;

require 5.8.0;
use strict;
use warnings;
use Carp;

use VCS::Rcs::YappRcsParser;

our $VERSION = '0.07';

sub new {
    my $this  = shift;
    my $rtext = shift;
    my %param = @_;

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
    $self->{__dt__} = $rcs->Run($rtext, $revs, $dates);  # VCS::Rcs::Deltatext

    for my $rev ($self->{__dt__}->revs) {
        my $rdate = $self->{__dt__}->date($rev);
	next unless (defined $rdate);
        $rdate = '19'.$rdate if (length($rdate) ==  17);
        $self->{__date_index__}{$rdate} = $rev;
        $self->{__rev_index__}{$rev} = $rdate;
    }

    $self
}


sub co {
    my $self = shift;
    my %param = @_;

    my $rev  = delete $param{rev};
    my $date = delete $param{date};

    croak "Unexpected Parameter(s):",(join ',', keys %param) if %param;
 
    return $self->{__dt__}->rev($rev) if (defined $rev);

    my @alldates  = sort keys %{$self->{__date_index__}};


    my($a,$date_proper);

    for $a (@alldates) {
	$date_proper=$a if ($a lt $date);
    }
    $date_proper=$alldates[-1] if ($alldates[-1] lt $date);

    no warnings;
    $self->{__dt__}->rev($self->{__date_index__}{$date_proper})
}


sub revs {
    my $self = shift;
    my %param = @_;

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

  my $rcs = VCS::Rcs::Parser->new(\$text); # Checkout all the revisions

  or
 
  my $rcs = VCS::Rcs::Parser->new(\$text, 
                                  dates=> ['2001.01.01', '2001.03'],
                                  revs => ['1.1', '1.5'] )
                or warn "Error Parsing $file\n";

  my $dates = $rcs->revs(index => 'date'); # ref. to a hash ( dates=>revs )
  my $revs  = $rcs->revs(index => 'rev' ); # ref. to a hash ( revs=>dates )

  print $rcs->co(rev => '1.1');
  print $rcs->co(date => '2001.01.01');


=head1 DESCRIPTION

Reads a ',v' RCS revisions file and checks out every revision into core.

=head1 METHODS

new: Takes one mandatory parameter, which is a referance to the Scalar 
containing the revision file. And two optionals, date=>[], and revs=>[] 
with the list of dates or revisions to be read into core.

revs: takes one parametre, index=>'' with a value 'date' or 'rev'. this
method lists the revisions put in the memory in to a hash referance, 
dates as the keys, or revisions respectivly.

co: Accepts one parametre rev, or date, with the value revision or date. 
Returns a scalar containing the revision.

=head1 BUGS

* 0.04 has a memory leak!!! upgrade

* 'CO' algoritm does not follow branches, or even 'next's.
  It only follows the order deltatext is written to the ,v
  revision file.

* Probably more!


=head1 AUTHOR

Ziya Suzen, ziya@ripe.net

=head1 SEE ALSO

perl(1).

=cut
