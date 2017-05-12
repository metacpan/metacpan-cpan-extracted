#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------

package ePortal::PageSection;
    our $VERSION = '4.5';
    use base qw/ePortal::ThePersistent::ExtendedACL/;

	use ePortal::Global;
	use ePortal::Utils;

    use Params::Validate qw/:types/;
    use Storable qw//;

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{title} ||= {};
    $p{Attributes}{params} ||= {
        label => {rus => 'Параметры секции', eng => 'Section parameters'},
        size => 60,
        # description => 'There may be a few sections with one template',
        };
    $p{Attributes}{setupinfo} ||= {
                dtype => 'Varchar',
                maxlength => 16000000,
        };
    $p{Attributes}{width} ||= {
        label => {rus => 'Ширина секции', eng => 'Section width'},
        fieldtype => 'popup_menu',
        values => [ qw/N W/ ],
        labels => {
            N => {rus => 'узкая', eng => 'narrow'},
            W => {rus => 'широкая', eng => 'wide'},
        },
        };
    $p{Attributes}{url} ||= {
        label => {rus => 'URL для заголовка', eng => 'URL for section title'},
        size => 60,
        #description => 'URL for section caption',
        };
    $p{Attributes}{component} ||= {
        label => {rus => 'Файл компоненты', eng => 'Component file name'},
        fieldtype => 'popup_menu',
        values => \&ComponentNames,
        #description => 'filename of mason component',
        };
    $p{Attributes}{memo} ||= {};

    $self->SUPER::initialize(%p);
}##initialize




############################################################################
sub ComponentNames	{	#10/09/01 11:25
############################################################################
	my $self = shift;
    my @files = $ePortal->m->interp->resolver->glob_path('/pv/sections/*.mc');
    foreach (@files) {
        $_ =~ s|^.*/||g;    # remove dir path
    }

	return [ sort @files ];
}##ComponentNames



############################################################################
sub delete	{	#10/15/01 11:32
############################################################################
	my $self = shift;

    my $result = $self->SUPER::delete(); # may throw !
    if ($result) {
        my $dbh = $self->dbh();
        $result += $dbh->do("DELETE FROM UserSection WHERE ps_id=?", undef, $self->id);
    }
    return $result;
}##delete

############################################################################
sub setupinfo_hash  {   #12/25/2003 5:43
############################################################################
    my ($self, $newhash) = Params::Validate::validate_with( params => \@_,
        spec => [
        { type => OBJECT },
        { type => HASHREF, optional => 1 },
        ],
    );

    my $hash = $newhash;
  
    # Save data
    if ( $newhash ) {
        $self->value('setupinfo', Storable::nfreeze($newhash));
    }    

    # Get current information
    if (! $hash ) {
        # Try to reconstruct setupinfo HASH
        eval {
        $hash = Storable::thaw( $self->value('setupinfo') );
        };

        # On error or old version of setup info construct default HASH
        if ( $@ or (ref($hash) ne 'HASH')) {
            $hash = {};
            $hash->{old_setupinfo} = $self->value('setupinfo') if $self->value('setupinfo') ne '';
        }
    }

    return $hash;
}##setupinfo_hash


sub xacl_check_insert {  $ePortal->isAdmin; }
sub xacl_check_update {  $ePortal->isAdmin; }

1;
