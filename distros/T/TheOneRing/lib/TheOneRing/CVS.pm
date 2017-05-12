# Copyright (C) 2009 Wes Hardaker
# License: GNU GPLv2.  See the COPYING file for details.
package TheOneRing::CVS;

use strict;
use TheOneRing;
use IO::File;

our @ISA = qw(TheOneRing);

our $VERSION = '0.3';

sub init {
    my ($self) = @_;
    $self->{'command'} = 'cvs';
    $self->{'mapping'} =
      {
# might be able to hack this through update
#        'status' =>
#        {
# 	'args' => { q => 'q' },
#        },

       'commit' =>
       {
	'args' => { m => '-m',
		    N => 'l'},
       },

       'update' =>
       {
	# need -D flag equiv
	'args' => { r => '-r',
		    N => 'l'},
       },

       'diff' =>
       {
	'args' => { r => '-r',
		    N => 'l'},
       },

       'annotate' =>
       {
	args => { r => '-r',
		  'N' => 'l'}
       },

       'export' =>
       {
	args => { N => 'l',
		  r => '-r'}
       },

       'log' =>
       {
	args => { N => 'l',
		  r => '-r'}
       },

       'add' =>
       {
	options => ['-m','adding files'],
	args => { }
       },

       'remove' =>
       {
	options => ['-f'],
	args => { N => 'l' }
       },

      };
}

sub info {
    my $fh = IO::File->new("<CVS/Repository");
    my $repo = <$fh>;
    $fh->close;

    $fh = IO::File->new("<CVS/Root");
    my $root = <$fh>;
    $fh->close;

    print "Root:       $root";
    print "Repository: $repo";
    chomp($root);
    print "Full Path:  $root/$repo";
}

sub revert {
    my ($self, @args) = @_;

    # lame quick processing
    my $quiet = 0;
    while ($args[0] eq '-q') {
	$quiet = 1;
	shift @args;
    }

    if ($#args == -1) {
	$self->ERROR("CVS requires you manually specify which files to revert");
    }

    foreach my $arg (@args) {
	unlink($arg);
	$self->System("cvs update $arg");
    }
}

sub ignore {
    my ($self, @args) = @_;
    $self->add_to_file(".cvsignore", @args);
}

sub move {
    my ($self, @args) = @_;
    $self->move_by_adddel(@args);
}

1;
