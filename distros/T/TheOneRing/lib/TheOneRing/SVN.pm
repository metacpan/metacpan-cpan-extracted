# Copyright (C) 2009 Wes Hardaker
# License: GNU GPLv2.  See the COPYING file for details.
package TheOneRing::SVN;

use strict;
use TheOneRing;

our @ISA = qw(TheOneRing);

our $VERSION = '0.3';

sub init {
    my ($self) = @_;
    $self->{'command'} = 'svn';
    $self->{'mapping'} =
      {
       'status' =>
       {
	'args' => { q => 'q' },
       },

       'commit' =>
       {
	'args' => { m => '-m',
		    q => 'q',
		    N => 'N'},
       },

       'update' =>
       {
	'args' => { r => '-r',
		    q => 'q',
		    N => 'N'},
       },

       'diff' =>
       {
	'args' => { r => '-r',
		    N => 'N'},
       },

       'annotate' =>
       {
	args => { r => '-r' }
       },

       'info' =>
       {
	args => { r => '-r' }
       },

       'add' =>
       {
	args => { N => 'N',
		  q => 'q'}
       },

       'remove' =>
       {
	args => { N => 'N',
		  q => 'q'}
       },

       'list' =>
       {
	args => { N => 'N',
		  q => 'q',
		  r => '-r'}
       },

       'export' =>
       {
	args => { N => 'N',
		  q => 'q',
		  r => '-r'}
       },

       'log' =>
       {
	args => { q => 'q',
		  r => '-r'}
       },

       'revert' =>
       {
	args => { q => 'q',
		  # N => XXX: same as -depth=immediates I think
		},
       },

       'move' =>
       {
       },
      };
}

1;
