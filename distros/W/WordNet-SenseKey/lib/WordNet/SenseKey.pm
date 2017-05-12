# -*- perl -*-
#
# WordNet::SenseKey.pm version 1.03
#
# Given an WordNet file offset, return the corresponding sense key
# Meant to be used with WordNet::Similarity, which does not normally
# manipulate data using sense keys.
#
# Copyright (c) 2008 Linas Vepstas linasvepstas at gmail.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to
#
# The Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330,
# Boston, MA  02111-1307, USA.
#
# ------------------------------------------------------------------

package WordNet::SenseKey;

=head1 NAME

WordNet::SenseKey - convert WordNet sense keys to sense numbers, and v.v.

=head1 SYNOPSIS

   use WordNet::QueryData;
   use WordNet::SenseKey;

   my $wn = WordNet::QueryData->new("/usr/share/wordnet");
   my $sk = WordNet::SenseKey->new($wn);

   my $skey = $sk->get_sense_key("run#v#2");
   print "Found the sense key $skey for run#v#2\n";

   my $sense = $sk->get_sense_num($skey);
   print "Found sense $sense for key $skey\n";

   my @synset = $sk->get_synset($skey);
   print "Synset is @synset\n";

   my $can = $sk->get_canonical_sense("escape", "run%2:38:04::");
   print "Found sense $can\n";

=head1 DESCRIPTION

 The WordNet::Similarity package is designed to work with words in the
 form of lemma#pos#num  where "lemma" is the word lemma, "pos" is the 
 part of speech, and "num" is the sense number.  Unfortuantely, the 
 sense numbering is not stable from one WordNet release to another.
 Thus, for external programs, it can often be more useful to work with 
 sense keys. Unfortunately, the Wordnet::Similarity package is unaware 
 of sense keys. This class fills that gap.

 WordNet senses keys are described in greater detail in

   http://wordnet.princeton.edu/man/senseidx.5WN.html

 There are four routines implemented here:

    get_sense_key($sense);
    get_sense_num($sense_key);
    get_synset($sense_key);
    get_canonical_sense($lemma, $sense_key);

=head2 get_sense_key

 Given a word sense, in the form of lemma#pos#num, this method returns
 the corresponding sense key, as defined by WordNet. Here, "lemma" is the
 word lemma, "pos" is the part of speech, and "num" is the sense number.
 The format of WordNet sense keys is documented in senseidx(5WN), one of 
 the WordNet man pages. 

 Returns an undefined value if the sense key cannot be found.
 The 'get_sense_num' method performs the inverse operation.

=head2 get_sense_num

 Given a WordNet sense key, this method returns the corresponding
 word-sense string, in the lemma#pos#num format.  This function is the
 inverse of the get_sense_key method; calling one, and then the other,
 should always return exactly the original input.

 Returns an undefined value if the sense cannot be found.

=head2 get_synset

 Given a WordNet sense key, this method returns a list of other sense
 keys that belong to the same synset.

=head2 get_canonical_sense

 Senses in a synset all have different lemmas.  This function selects
 one particular element of a synset, given a lemma, and any other member
 of the synset. Thus, for example, run%2:38:04::  and escape%2:38:02:: 
 belong to the same synset. Then

   get_canonical_sense("escape", "run%2:38:04::");

 will return escape%2:38:02::, as this is the sense of "escape" that
 belongs to the same synset as run%2:38:04::.  Returns an undefined
 value if the sense cannot be found.

=head1 SEE ALSO

 senseidx(5WN), WordNet::Similarity(3), WordNet::QueryData(3)

 http://wordnet.princeton.edu/
 http://www.ai.mit.edu/~jrennie/WordNet
 http://groups.yahoo.com/group/wn-similarity

=head1 AUTHOR

 Linas Vepstas <linasvepstas@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008, 2009 Linas Vepstas

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to

    The Free Software Foundation, Inc.,
    59 Temple Place - Suite 330,
    Boston, MA  02111-1307, USA.

Note: a copy of the GNU General Public License is available on the web
at <http://www.gnu.org/licenses/gpl.txt> and is included in this
distribution as GPL.txt.

=cut

use strict;
use warnings;
require Exporter;

BEGIN {
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
	# List of classes from which we are inheriting methods
	@ISA = qw(Exporter);
	# Automatically loads these function names to be used without qualification
	@EXPORT = qw();
	# Allows these functions to be used without qualification
	@EXPORT_OK = qw();
	$VERSION = '1.03';
}

END { } # module clean-up code here (global destructor)

# ------------------------------------------------------
# Constructor
# Looks in a default path for the sense index file.
# Reads it, builds an associative array of file offsets to sense keys.
sub new
{
	my ($class, $wn) = @_;
	my $self = {
		senseidx_path => "/usr/share/wordnet",
		senseidx_file => "/usr/share/wordnet/index.sense",
		wn => $wn,
		reversed_index => undef,
		forward_index => undef
	};
	bless $self, $class;

	# Get a valid data path from WordNet::QueryData.
	my $path = $wn->dataPath();
	if (defined($path))
	{
		$self->{senseidx_path} = $path;
		$self->{senseidx_file} = $path . "/index.sense";
	}

	# Open the file for reading
	my $fh = new FileHandle($self->{senseidx_file});
	if (!defined($fh))
	{
		die "Unable to open $self->{senseidx_file}: $!";
	}
	
	# Build a reverse index of sense-keys to offsets.
	my %rev_idx = ();
	my %fwd_idx = ();
	while (<$fh>)
	{
		my ($skey, $offset, $snum, $tag_cnt) = split;
		my $keys = $rev_idx{$offset};
		# $keys is a reference to an array
		push @$keys, $skey;
		$rev_idx{$offset} = [@$keys];
		# print "index entry $skey and $offset so -- @$keys\n";
		$fwd_idx{$skey} = $snum;
	}
	undef $fh;

	# Remember that \% is an array reference.
	$self->{reversed_index} = \%rev_idx;
	$self->{forward_index} = \%fwd_idx;

	return $self;
}

# report WordNet data dir
sub dataPath { my $self = shift; return $self->{senseidx_path}; }

# ------------------------------------------------------

sub get_sense_key
{
	my ($self, $lempos) = @_;
	my $wn = $self->{wn};

	# If the args are undefined, return undefined value.
	my $offset = $wn->offset($lempos);
	if (!defined($offset))
	{
		return $offset;
	}
	if (!defined($lempos))
	{
		return $lempos;
	}

	# Change over to sense-key style notation
	if ($lempos) {
		$lempos =~ s/#.*//;

		# Tight matching -- failes to find %5 synsets, e.g. sane#a#2 which
		# maps to sane%5:00:00:rational:00
		# $lempos =~ s/#/%/;
		# $lempos =~ s/%n/%1/;
		# $lempos =~ s/%v/%2/;
		# $lempos =~ s/%a/%3/;
		# $lempos =~ s/%r/%4/;

		# make sure its lower-case too.
		$lempos =~ tr/[A-Z]/[a-z]/;
	}

	# pad the offet with zeroes, if its too short to be a valid offset.
	my $len = 8 - length($offset);
	for (my $i=0; $i< $len; $i++) {
   	$offset = "0" . $offset;
	}

	# get the array reference
	my $rev_idx = $self->{reversed_index};

	my $keys = $rev_idx->{$offset};
	# print "key candidates are @$keys\n";

	# Loop over all entries in the synset
	my $foundkey = "";
	foreach my $sensekey (@$keys)
	{
		if ($sensekey =~ $lempos) {
			$foundkey = $sensekey;
			last;
		}
	}

	return $foundkey;
}

# ------------------------------------------------------
sub get_sense_num
{
	my ($self, $sense_key) = @_;

	$sense_key =~ m/([\w\.]+)%(\d+):*/;
	my $lemma = $1;
	my $pos = $2;
	$pos =~ s/1/n/;
	$pos =~ s/2/v/;
	$pos =~ s/3/a/;
	$pos =~ s/4/r/;

	# XXX what about 5 ??

	my $fwd_idx = $self->{forward_index};
	my $sense_num = $fwd_idx->{$sense_key};

	if (!defined($sense_num)) { return $sense_num; }

	return $lemma . "#" . $pos . "#" . $sense_num;
}


# ------------------------------------------------------
# get_synset -- return a wordnet synset.
# Given a sense key as input, this will
# return a list of sense keys in the synset.
sub get_synset
{
	my ($self, $sense_key) = @_;
	my $sense_str = $self->get_sense_num($sense_key);

	if (!defined($sense_str)) { return (); }

	my $wn = $self->{wn};
	my @synset = $wn->querySense($sense_str, "syns");
	my @keyset = ();
	foreach (@synset)
	{
		my $lempos = $_;
		my $skey = $self->get_sense_key($lempos);
		push @keyset, $skey;
	}

	return @keyset;
}

# ------------------------------------------------------

# get_canonical_sense -- get matching lemma from a synset.
# Return an alternate sense key that belongs to the same
# synset ass the input sense key, but has the the lemmatized
# form $lemma at its root.
#
# Thus, for example:
#
#      get_canonical_sense("join#v", "connect%2:42:02::");
#
# will return "join%2:42:01", because "join%2:42:01" is in the same
# synset as "connect%2:42:02::", but has "join" as its root. 
#
sub get_canonical_sense
{
	my ($self, $lemma, $sense) = @_;
	my $wn = $self->{wn};

	# strip off the part-of-speech marker from the lemma.
	$lemma =~ m/([\w\.]+)#/;
	if (defined($1))
	{
		$lemma = $1;
	}

	# Loop over the synset, looking for a matching form.
	my @synset = $self->get_synset($sense);
	foreach (@synset)
	{
		my $altsense = $_;
		$altsense =~ m/([\w\.]+)%/;
		if ($1 eq $lemma)
		{
			return $altsense;
		}
	}

	my $notfound; # this is undefined!
	return $notfound;
}


# module must return true
1;
__END__
