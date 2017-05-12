package VUser::ResultSet::Display::CSV;
use warnings;
use strict;

# Copyright 2006 Randy Smith <perlstalker@vuser.org>
# $Id: CSV.pm,v 1.1 2006-01-06 23:53:16 perlstalker Exp $

use base qw(VUser::ResultSet::Display);

use VUser::ExtLib qw(:config);

my $c_sec = 'Display::CSV';

our $VERSION = "0.3.1";
sub version { return $VERSION; }

sub init
{
    my $self = shift;
    my $cfg = shift;

    my $sep = strip_ws($cfg->{$c_sec}{'separator'});
    if (not defined $sep) {
	$sep = ',';
    } elsif ($sep eq '\t'
	     or $sep eq '[tab]'
	     or $sep eq 'tab'
	     ) {
	$sep = "\t";
    }

    $self->{sep} = $sep;
}

sub display_one
{
    my $self = shift;
    my $rs = shift;

    print join $self->{sep}, map { $_->name; } $rs->get_metadata;
    print "\n";

    foreach my $row ($rs->results()) {
	print join $self->{sep}, map { (defined $_)? $_ : 'undef'; } @$row;
	print "\n";
    }
}

1;

__END__

=head1 NAME

VUser::ResultSet::Display::CSV - Display VUser::ResultSets as CSV

=head1 CONFIGURATION

 [vuser]
 display format = CSV
 
 [Display::CSV]
 # Set to '[tab]' or 'tab' (without quotes) to use tabs as delimiters
 separator = ,

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

