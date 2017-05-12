#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: Collection.pm,v 1.4 2001/09/04 19:46:41 srl Exp $
#
# (C) COPYRIGHT 2001, Shane Landrum <srl@cpan.org>
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

$VERSION = "0.02";

package Verity::Collection;

use Carp;

my $MKVDK = 'mkvdk';

=head1 NAME

Verity::Collection - interface to a local Verity collection.

=head1 SYNOPSIS

  use Verity::Collection;

  my $v = Verity::Collection->new(collection => '/foo/bar/baz',
                                  binaries => '/verity/bin');
  
=head1 DESCRIPTION

This module assumes that you have a local Verity collection;
it's intended to interface to Verity through the local Unix
system using mkvdk and rcvdk. At some point in the future
it may use XS under the hood to speak to the Verity developers'
toolkit, but not for now.  

=head1 METHODS

=head2 new(collection => $dir, binaries => $dir, verbose => [0|1], warn_on_error => [0|1])

This method makes a new Verity::Collection object in the collection
dir using the binaries dir to find Verity tools. 

If "verbose" is turned on you'll see the command lines used to talk 
to Verity. If "warn_on_error" is on you'll get warnings when you do 
something that won't work.

=begin testing

BEGIN { use_ok( 'Verity::Collection' ); }
# all other tests are in their own files.  --srl

=end testing

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {};
    bless $self, $class;

    unless (defined($args{binaries})) {
        $args{binaries} = '';
        $self->_whine("Verity binaries directory not defined");
    }
    unless (defined($args{collection})) {
        $args{collection} = '';
        $self->_whine ("Verity collection directory not defined");
    }
    $self->_whine("No verity binary dir given") unless $args{binaries};
    $self->_whine("No verity collection dir given") unless $args{collection};
    return undef unless ($args{collection} and $args{binaries});
   
    $self->{mkvdk} = $args{binaries} . "/$MKVDK";
    $self->{collection} = $args{collection};
    $self->{verbose} = $args{verbose} || 0;
    $self->{warn_on_error} = $args{warn_on_error} || 0;
    
    unless (-e ($self->{mkvdk})) {
        $self->_whine("Couldn't find $MKVDK at " . $self->{mkvdk});
        return undef;
    }
    unless (-d ($self->{collection}) ) {
        mkdir $self->{collection} || 
            croak "couldn't make collection dir " . $self->{collection};
    }

    
    return $self;
}

=head2 create

This method makes a new collection on the filesystem. 

=cut

sub create {
    my ($self, $args) = @_;

    my $commandline = $self->{mkvdk} . 
        " -collection " . $self->{collection} . 
        " -create ";
    
    return $self->_system($commandline);
}

=head2 insert (%args)

This method adds new data to the collection. Options are:

=over 4

=item * mode - defaults to '', specify 'bulk' if this is a bulk file

=item * file - full path of the file to insert into the collection

=back

=cut

sub insert {
    my ($self, %args) = @_;
    
    my $bulkmode = '';
    if (defined($args{mode})) {
        $bulkmode = "-bulk" if ($args{mode} eq 'bulk');
    }
    
    unless (defined($args{file})) {
        $args{file} = '';
        carp "Filename to insert not defined";
    }
    carp "No filename to insert given" unless $args{file};
    carp "File " . $args{file} . " doesn't exist" unless (-e $args{file});

    my $commandline = $self->{mkvdk} . 
        " -collection " . $self->{collection} .
        " $bulkmode" .
        " -insert " . $args{file};
    
    return $self->_system($commandline);
}

=head2 purge

This method purges all data from the collection. It does *not*
delete the collection. See delete() for that.

=cut

sub purge {
    my ($self, %args) = @_;

    my $commandline = $self->{mkvdk} . 
        " -collection " . $self->{collection} . 
        " -delete ";
    
    return $self->_system($commandline);
}

=head2 delete

This method deletes the collection itself on disk.

=cut

sub delete {
    my ($self, %args) = @_;

    my $commandline = "rm -rf " . $self->{collection};
    
    return $self->_system($commandline);
}

=head2 reindex

This method updates the indexes in the collection.

=cut

sub reindex {
    my ($self) = @_;

    return undef;
}


=head1 TODO

Write some code. Write some tests.

=cut

sub _whine {
    my ($self, $msg) = @_;
    warn "$msg\n" if $self->{warn_on_error};
}

sub _system {
    my ($self, $command) = @_;

    my $result = system($command);
    warn "System command: '$command'\n" if $self->{verbose};
    return 1 if ($result == 0);
    return undef if ($result != 0);
}

1;

