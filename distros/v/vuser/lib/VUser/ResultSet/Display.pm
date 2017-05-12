package VUser::ResultSet::Display;
use warnings;
use strict;

# Copyright 2006 Randy Smith <perlstalker@vuser.org>
# $Id: Display.pm,v 1.5 2007-09-24 20:16:07 perlstalker Exp $

use VUser::ExtLib qw(:config);
our $VERSION = "0.3.1";

use base qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ();

my $c_sec = 'vuser'; # Configuration section

sub new
{
    my $class = shift;
    my $cfg = shift;

    my $self = {};

    my $display_format = strip_ws($cfg->{$c_sec}{'display format'});
    if (not defined $display_format
	or $display_format eq ''
	or $display_format eq 'normal'
	or $display_format eq 'standard'
	) {
	bless $self, $class;
    } else {
	# Load the display module
	eval "require VUser::ResultSet::Display::$display_format;";
	die "Unable to load display module $display_format: $@\n" if $@;
	bless $self, "VUser::ResultSet::Display::$display_format";
    }

    $self->init($cfg);
    return $self;
}

# Takes a ResultSet, array or array ref of ResultSets (or array refs of RSs)
# and displays them.
sub display
{
    my $self = shift;
    my @rsets = @_;
    
    foreach my $rs (@rsets) {
	if (defined $rs
	    and UNIVERSAL::isa($rs, 'VUser::ResultSet')
	    ) {
	    #print "Display RS with: ", ref $self, "\n";
	    eval { $self->display_one($rs); };
	    die "Can't display result set: $@\n" if $@;
	} elsif (ref $rs eq 'ARRAY') {
	    # $rs is a list ref. Dereference the list and send it to
	    # display() again to process any ResultSets within that list.
	    $self->display(@$rs);
	    print "\n";
	} else {
	    # It's not a VUser::ResultSet
	}
    }
}

# Overloaded by sub-classes
sub display_one
{
    my $self = shift;
    my $rs = shift; # VUser::ResultSet

    my @meta = $rs->get_metadata;

    foreach my $row ($rs->results()) {
	foreach (my $i = 0; $i < @meta; $i++) {
	    printf("%s: %s\n",
		   $meta[$i]->name,
		   defined $row->[$i]? $row->[$i] : 'undef');
	}
	#print "\n";
    }
}

sub init {}
sub version { return $VERSION; }

1;

__END__

=head1 NAME

VUser::ResultSet::Display - Display class for VUser::ResultSets

=head1 CONFIGURATION

 [vuser]
 display format = Standard

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
