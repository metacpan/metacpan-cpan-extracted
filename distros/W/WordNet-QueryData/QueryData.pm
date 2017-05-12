# -*- perl -*-
#
# Package to interface with WordNet (wn) database

# Run 'perldoc' on this file to produce documentation

# Copyright 1999-2006 Jason Rennie

# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

####### manual page & loadIndex ##########

# STANDARDS
# =========
# - upper case to distinguish words in function & variable names
# - use 'warn' to report warning & progress messages
# - begin 'warn' messages with "(fn)" where "fn" is function name
# - all non-trivial function calls should receive $self
# - syntactic markers are ignored

package WordNet::QueryData;

use strict;
use Carp;
use FileHandle;
use Search::Dict;
use File::Spec;
use Exporter;

##############################
# Environment/Initialization #
##############################

BEGIN {
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
    # List of classes from which we are inheriting methods
    @ISA = qw(Exporter);
    # Automatically loads these function names to be used without qualification
    @EXPORT = qw();
    # Allows these functions to be used without qualification
    @EXPORT_OK = qw();
    $VERSION = "1.49";
}

#############################
# Private Package Variables #
#############################

# Error variables
my $errorString = "";
my $errorVal = 0;

# Mapping of possible part of speech to single letter used by wordnet
my %pos_map = ('noun'      => 'n',
	       'n'         => 'n',
	       '1'         => 'n',
	       ''          => 'n',
	       'verb'      => 'v',
	       'v'         => 'v',
	       '2'         => 'v',
	       'adjective' => 'a',
	       'adj'       => 'a',
	       'a'         => 'a',
	       # Adj satellite is essentially just an adjective
	       's'         => 'a',
	       '3'         => 'a',
	       '5'         => 'a', # adj satellite
	       'adverb'    => 'r',
	       'adv'       => 'r',
	       'r'         => 'r',
	       '4'         => 'r');
# Mapping of possible part of speech to corresponding number
my %pos_num = ('noun'      => '1',
	       'n'         => '1',
	       '1'         => '1',
	       ''          => '1',
	       'verb'      => '2',
	       'v'         => '2',
	       '2'         => '2',
	       'adjective' => '3',
	       'adj'       => '3',
	       'a'         => '3',
	       # Adj satellite is essentially just an adjective
	       's'         => '3',
	       '3'         => '3',
	       'adverb'    => '4',
	       'adv'       => '4',
	       'r'         => '4',
	       '4'         => '4');
# Mapping from WordNet symbols to short relation names
my %relNameSym = ('ants' => {'!'=>1},
		  'hype' => {'@'=>1},
		  'inst' => {'@i'=>1},
		  'hypes' => {'@'=>1,'@i'=>1},
		  'hypo' => {'~'=>1},
		  'hasi' => {'~i'=>1},
		  'hypos' => {'~'=>1,'~i'=>1},
		  'mmem' => {'%m'=>1},
		  'msub' => {'%s'=>1},
		  'mprt' => {'%p'=>1},
		  'mero' => {'%m'=>1, '%s'=>1, '%p'=>1},
		  'hmem' => {'#m'=>1},
		  'hsub' => {'#s'=>1},
		  'hprt' => {'#p'=>1},
		  'holo' => {'#m'=>1, '#s'=>1, '#p'=>1},
		  'attr' => {'='=>1},
		  'enta' => {'*'=>1},
		  'caus' => {'>'=>1},
		  'also' => {'^'=>1},
		  'vgrp' => {'$'=>1},
		  'sim' => {'&'=>1},
		  'part' => {'<'=>1},
		  'pert' => {'\\'=>1},
		  'deri' => {'+'=>1},
		  'domn' => {';c'=>1, ';r'=>1, ';u'=>1},
		  'dmnc' => {';c'=>1},
		  'dmnr' => {';r'=>1},
		  'dmnu' => {';u'=>1},
		  'domt' => {'-c'=>1, '-r'=>1, '-u'=>1},
		  'dmtc' => {'-c'=>1},
		  'dmtr' => {'-r'=>1},
		  'dmtu' => {'-u'=>1});

# Mapping from WordNet symbols to short relation names
my %relSymName = ('!'  => 'ants',
		  '@'  => 'hype',
		  '@i' => 'inst',
		  '~'  => 'hypo',
		  '~i' => 'hasi',
		  '%m' => 'mmem',
		  '%s' => 'msub',
		  '%p' => 'mprt',
		  '#m' => 'hmem',
		  '#s' => 'hsub',
		  '#p' => 'hprt',
		  '='  => 'attr',
		  '*'  => 'enta',
		  '>'  => 'caus',
		  '^'  => 'also',
		  '$' => 'vgrp', # '$' Hack to make font-lock work in emacs
		  '&'  => 'sim',
		  '<'  => 'part',
		  '\\' => 'pert',
		  '-u' => 'dmtu',
		  '-r' => 'dmtr',
		  '-c' => 'dmtc',
		  ';u' => 'dmnu',
		  ';r' => 'dmnr',
		  ';c' => 'dmnc');

my %lexnames = ('00' => 'adj.all',
		'01' => 'adj.pert',
		'02' => 'adv.all',
		'03' => 'noun.Tops',
		'04' => 'noun.act',
		'05' => 'noun.animal',
		'06' => 'noun.artifact',
		'07' => 'noun.attribute',
		'08' => 'noun.body',
		'09' => 'noun.cognition',
		'10' => 'noun.communication',
		'11' => 'noun.event',
		'12' => 'noun.feeling',
		'13' => 'noun.food',
		'14' => 'noun.group',
		'15' => 'noun.location',
		'16' => 'noun.motive',
		'17' => 'noun.object',
		'18' => 'noun.person',
		'19' => 'noun.phenomenon',
		'20' => 'noun.plant',
		'21' => 'noun.possession',
		'22' => 'noun.process',
		'23' => 'noun.quantity',
		'24' => 'noun.relation',
		'25' => 'noun.shape',
		'26' => 'noun.state',
		'27' => 'noun.substance',
		'28' => 'noun.time',
		'29' => 'verb.body',
		'30' => 'verb.change',
		'31' => 'verb.cognition',
		'32' => 'verb.communication',
		'33' => 'verb.competition',
		'34' => 'verb.consumption',
		'35' => 'verb.contact',
		'36' => 'verb.creation',
		'37' => 'verb.emotion',
		'38' => 'verb.motion',
		'39' => 'verb.perception',
		'40' => 'verb.possession',
		'41' => 'verb.social',
		'42' => 'verb.stative',
		'43' => 'verb.weather',
		'44' => 'adj.ppl');

# WordNet data file names
my $lexnamesFile = "lexnames";
my @excFile = ("", "noun.exc", "verb.exc", "adj.exc", "adv.exc");
my @indexFile = ("", "index.noun", "index.verb", "index.adj", "index.adv");
my @dataFile = ("", "data.noun", "data.verb", "data.adj", "data.adv");

my $wnHomeUnix = defined($ENV{"WNHOME"}) ? $ENV{"WNHOME"} : "/usr/local/WordNet-3.0";
my $wnHomePC = defined($ENV{"WNHOME"}) ? $ENV{"WNHOME"} : "C:\\Program Files\\WordNet\\3.0";
my $wnPrefixUnix = defined($ENV{"WNSEARCHDIR"}) ? $ENV{"WNSEARCHDIR"} : "$wnHomeUnix/dict";
my $wnPrefixPC = defined($ENV{"WNSEARCHDIR"}) ? $ENV{"WNSEARCHDIR"} : "$wnHomePC\\dict";

END { } # module clean-up code here (global destructor)

###############
# Subroutines #
###############

# report WordNet version
# Invalid way of identifying version as of WordNet 3.0
#sub version { my $self = shift; return $self->{version}; }


sub getResetError#
{
    my $self = shift;
    my $tmpString = $self->{errorString};
    my $tmpVal = $self->{errorVal};
    $self->{errorString} = "";
    $self->{errorVal} = 0;
    return ($tmpString, $tmpVal);
}

# convert to lower case, translate ' ' to '_' and eliminate any
# syntactic marker
sub lower#
{ 
    my $word = shift;
    $word =~ tr/A-Z /a-z_/;
    $word =~ s/\(.*\)$//;
    return $word;
}

# translate ' ' to '_'
sub underscore#
{ 
    $_[0] =~ tr/ /_/;
    return $_[0];
}

# Eliminate any syntactic marker
sub delMarker#
{ 
    $_[0] =~ s/\(.*\)$//;
    return $_[0];
}

# Perform all initialization for new WordNet class instance
sub _initialize#
{
    my $self = shift;
    warn "Loading WordNet data...\n" if ($self->{verbose});
    # Ensure that input record separator is "\n"
    my $old_separator = $/;
    $/ = "\n";
    
    # Load morphology exclusion mapping, indexes, open data file handles
    unless ($self->{noload}) {
        $self->loadExclusions ();
    }
    $self->loadIndex ();
    $self->openData ();

    $self->{errorString} = "";
    $self->{errorVal} = "";
    warn "Done.\n" if ($self->{verbose});
    
    # Return setting of input record separator
    $/ = $old_separator;
}

sub new#
{
    # First argument is class
    my $class = shift;
    
    my $self = {};
    bless $self, $class;

    # try to preserve old calling syntax, at least for dir
    if (scalar @_ == 1) {
        $self->{dir} = shift;
    }
    # but allow an extensible params syntax
    else
    {
        my %params = @_;
        $self->{dir}     = $params{dir} if $params{dir};
        $self->{verbose} = $params{verbose} if $params{verbose};
        $self->{noload}  = $params{noload} if $params{noload};
    }
        
    warn "Dir = ", $self->{dir}, "\n" if ($self->{verbose});
    warn "Verbose = ", $self->{verbose}, "\n" if ($self->{verbose});
    warn "Noload = ", $self->{noload}, "\n" if ($self->{verbose});
    
    ## set $self->{dir} here and avoid the confusion later on, and the {wnpath} stuff.
    ## also fix up path endings to have trailing slashes if they didn't come that way.
    if (-e $wnPrefixUnix) {
        $self->{dir} ||= $wnPrefixUnix;
        $self->{dir} .= "/" if $self->{dir} !~ m|/$|;
    } elsif (-e $wnPrefixPC) {
        $self->{dir} ||= $wnPrefixPC;
        $self->{dir} .= "\\" if $self->{dir} !~ m|\\$|;
    }
    
    $self->_initialize ();
    return $self;
}

# Object destructor
sub DESTROY#
{
    my $self = shift;

    for (my $i=1; $i <= 4; $i++) {
        undef $self->{data_fh}->[$i];
    }
}

# Load mapping to non-standard canonical form of words (morphological
# exceptions)
sub loadExclusions#
{
    my $self = shift;
    warn "(loadExclusions)" if ($self->{verbose});

    for (my $i=1; $i <= 4; $i++)
    {
        my $file = $self->{dir} . "$excFile[$i]";
        my $fh = new FileHandle($file);
        die "Not able to open $file: $!" if (!defined($fh));
        
        while (my $line = <$fh>)
        {
            my ($exc, @word) = split(/\s+/, $line);
            next if (!@word);
            $self->{morph_exc}->[$i]->{$exc} ||= [];
            push @{$self->{morph_exc}->[$i]->{$exc}}, @word;
        }
    }
}

sub loadIndex#
{
    my $self = shift;
    warn "(loadIndex)" if ($self->{verbose});

    for (my $i=1; $i <= 4; $i++)
    {
        my $file = $self->{dir} . "$indexFile[$i]";
        ${$self->{indexFilePaths}}[$i] = $file;
        
        if (!$self->{noload})
        {
            my $fh = $self->_getIndexFH($pos_num{$i});            
            my $line;
            while ($line = <$fh>) {
                $self->{version} = $1 if ($line =~ m/WordNet (\S+)/);
                last if ($line =~ m/^\S/);
            }
            while (1) {
                my ($lemma, $pos, $offsets, $sense_cnt, $p_cnt) = $self->_parseIndexLine($line);
                $self->{"index"}->[$pos_num{$pos}]->{$lemma} = $offsets;
                $self->{"tagsense_cnt"}->[$pos_num{$pos}]->{$lemma} = $sense_cnt;
                $line = <$fh>;
                last if (!$line);
            }
            warn "\n*** Version 1.6 of the WordNet database is no longer being supported as\n*** of QueryData 1.27.  It may still work, but consider yourself warned.\n" if ($self->{version} eq "1.6");
            warn "\n*** Version 1.7 of the WordNet database is no longer being supported as\n*** of QueryData 1.27.  It may still work, but consider yourself warned.\n" if ($self->{version} eq "1.7");
        }
    }
}

# Open data files and return file handles
sub openData#
{
    my $self = shift;
    warn "(openData)" if ($self->{verbose});

    for (my $i=1; $i <= 4; $i++)
    {
        my $file = $self->{dir} . "$dataFile[$i]";
        ${$self->{dataFilePaths}}[$i] = $file;
        $self->_getDataFH($i);
    }
}

# Remove duplicate values from an array, which must be passed as a
# reference to an array.
sub removeDuplicates
{
    my ($self, $aref) = @_;
    warn "(removeDupliates) array=", join(" ", @{$aref}), "\n"
	if ($self->{verbose});
    
    my $i = 0;
    while ( $i < $#$aref ) {
        if ( grep {$_ eq ${$aref}[$i]} @{$aref}[$i+1 .. $#$aref] ) {
	    # element at $i is duplicate--remove it
	    splice @$aref, $i, 1;
	} else {
            $i++;
        }
    }
}

# - transforms ending according to rules of detachment
#   (http://www.cogsci.princeton.edu/~wn/doc/man1.7.1/morphy.htm).
# - assumes a single token (no collocations).
# - "#pos#sense" qualification NOT appended to returned words
# - always returns original word
sub tokenDetach#
{
    my ($self, $string) = @_;
    # The query string (word, pos and sense #)
    my ($word, $pos, $sense) = $string =~ /^([^\#]+)(?:\#([^\#]+)(?:\#(\d+))?)?$/; 
    warn "(forms) Sense number ignored\n" if (defined($sense));
    die "(tokenDetach) bad part-of-speech: pos=$pos word=$word sense=$sense" if (!defined($pos) or !defined($pos_num{$pos}));
    my @detach = ($word); # list of possible forms
    if ($pos_num{$pos} == 1)
    {
	push @detach, $1 if ($word =~ m/^(.+)s$/);
	push @detach, $1 if ($word =~ m/^(.+s)es$/);
	push @detach, $1 if ($word =~ m/^(.+x)es$/);
	push @detach, $1 if ($word =~ m/^(.+z)es$/);
	push @detach, $1 if ($word =~ m/^(.+ch)es$/);
	push @detach, $1 if ($word =~ m/^(.+sh)es$/);
	push @detach, $1."man" if ($word =~ m/^(.+)men$/);
	push @detach, $1."y" if ($word =~ m/^(.+)ies$/);
    }
    elsif ($pos_num{$pos} == 2)
    {
	push @detach, $1 if ($word =~ m/^(.+)s$/);
	push @detach, $1."y" if ($word =~ m/^(.+)ies$/);
	push @detach, $1 if ($word =~ m/^(.+e)s$/);
	push @detach, $1 if ($word =~ m/^(.+)es$/);
	push @detach, $1 if ($word =~ m/^(.+e)d$/);
	push @detach, $1 if ($word =~ m/^(.+)ed$/);
	push @detach, $1."e" if ($word =~ m/^(.+)ing$/);
	push @detach, $1 if ($word =~ m/^(.+)ing$/);
    }
    elsif ($pos_num{$pos} == 3)
    {
	push @detach, $1 if ($word =~ m/^(.+)er$/);
	push @detach, $1 if ($word =~ m/^(.+)est$/);
	push @detach, $1 if ($word =~ m/^(.+e)r$/);
	push @detach, $1 if ($word =~ m/^(.+e)st$/);
    }
    $self->removeDuplicates(\@detach);
    return @detach;
}

# sub-function of forms; do not use unless you know what you're doing
sub _forms#
{
    # Assume that word is canonicalized, pos is number
    my ($self, $word, $pos) = @_;

    my $lword = lower($word);
    warn "(_forms) WORD=$word POS=$pos\n" if ($self->{verbose});
    # if word is in morph exclusion table, return that entry
    if ($self->{noload}) {
        # for noload, only load exclusions when needed; we do cache these
        # though because the list is short (40k) and used on repeated recursive
        # calls.
        if (! exists $self->{morph_exc}) {
            $self->loadExclusions();
        }
    }
    if (defined ($self->{morph_exc}->[$pos]->{$lword})) {
        return ($word, @{$self->{morph_exc}->[$pos]->{$lword}});
    }

    my @token = split (/[ _]/, $word);
    # If there is only one token, process via rules of detachment
    return tokenDetach ($self, $token[0]."#".$pos) if (@token == 1);
    # Otherwise, process each token individually, then string together colloc's
    my @forms;
    for (my $i=0; $i < @token; $i++) {
	   push @{$forms[$i]}, _forms ($self, $token[$i], $pos);
    }
    
    # Generate all possible token sequences (collocations)
    my @rtn;
    my @index;
    for (my $i=0; $i < @token; $i++) { $index[$i] = 0; }
    while (1) {
	# String together one sequence of possibilities
	my $colloc = $forms[0]->[$index[0]];
	for (my $i=1; $i < @token; $i++) {
	    $colloc .= "_".$forms[$i]->[$index[$i]];
	}
	push @rtn, $colloc;
	# think "adder" (computer architechture)
	my $i;
	for ($i=0; $i < @token; $i++) {
	    last if (++$index[$i] < @{$forms[$i]});
	    $index[$i] = 0;
	}
	# If we had to reset every index, we're done
	last if ($i >= @token);
    }
    return @rtn;
}

# Generate list of all possible forms of how word may be found in WordNet
sub forms#
{
    my ($self, $string) = @_;
    # The query string (word, pos and sense #)
    my ($word, $pos, $sense) = $string =~ /^([^\#]+)(?:\#([^\#]+)(?:\#(\d+))?)?$/; 
    warn "(forms) Sense number ignored\n" if (defined($sense));
    warn "(forms) WORD=$word POS=$pos\n" if ($self->{verbose});
    die "(forms) Bad part-of-speech: pos=$pos" if (!defined($pos) or !defined($pos_num{$pos}));
    my @rtn = _forms ($self, $word, $pos_num{$pos});
    for (my $i=0; $i < @rtn; ++$i) {
	   $rtn[$i] .= "\#$pos";
    }
    return @rtn;
}


# $line is line from data file; $ptr is a reference to a hash of
# symbols; returns list of word#pos#sense strings
sub getSensePointers#
{
    my ($self, $line, $ptr) = @_;
    warn "(getSensePointers) ptr=", keys(%{$ptr}), " line=\"$line\"\n"
	if ($self->{verbose});
    
    my (@rtn, $w_cnt);
    # $w_cnt is hexadecimal
    (undef, undef, undef, $w_cnt, $line) = split (/\s+/, $line, 5);
    $w_cnt = hex ($w_cnt);
    for (my $i=0; $i < $w_cnt; ++$i) {
	   (undef, undef, $line) = split(/\s+/, $line, 3);
    }
    my $p_cnt;
    ($p_cnt, $line) = split(/\s+/, $line, 2);
    for (my $i=0; $i < $p_cnt; ++$i) {
	my ($sym, $offset, $pos, $st);
	# $st "source/target" is 2-part hexadecimal
	($sym, $offset, $pos, $st, $line) = split(/\s+/, $line, 5);
	push @rtn, $self->getSense($offset, $pos)
	    if (hex($st)==0 and defined($ptr->{$sym}));
    }
    return @rtn;
}

# $line is line from data file; $ptr is a reference to a hash of
# symbols; $word is query word/lemma; returns list of word#pos#sense strings
sub getWordPointers#
{
    my ($self, $line, $ptr, $word) = @_;
    warn "(getWordPointers) ptr=", keys(%{$ptr}), " word=$word line=\"$line\"\n"
	if ($self->{verbose});
    
    my $lword = lower($word);
    my (@rtn, $w_cnt);
    (undef, undef, undef, $w_cnt, $line) = split (/\s+/, $line, 5);
    $w_cnt = hex ($w_cnt);
    my @word;
    for (my $i=0; $i < $w_cnt; ++$i) {
	   ($word[$i], undef, $line) = split(/\s+/, $line, 3);
    }
    my $p_cnt;
    ($p_cnt, $line) = split(/\s+/, $line, 2);
    for (my $i=0; $i < $p_cnt; ++$i) {
        my ($sym, $offset, $pos, $st);
        # $st "source/target" is 2-part hexadecimal
        ($sym, $offset, $pos, $st, $line) = split(/\s+/, $line, 5);
        next if (!$st);
        my ($src, $tgt) = ($st =~ m/([0-9a-f]{2})([0-9a-f]{2})/);
        push @rtn, $self->getWord($offset, $pos, hex($tgt))
            if (defined($ptr->{$sym}) and ($word[hex($src)-1] =~ m/$lword/i));
    }
    return @rtn;
}

# return list of word#pos#sense for $offset and $pos (synset)
sub getAllSenses#
{
    my ($self, $offset, $pos) = @_;
    warn "(getAllSenses) offset=$offset pos=$pos\n" if ($self->{verbose});

    my @rtn;
    my $line = $self->_dataLookup($pos, $offset);
    my $w_cnt;
    (undef, undef, undef, $w_cnt, $line) = split(/\s+/, $line, 5);
    $w_cnt = hex ($w_cnt);
    my @words;
    for (my $i=0; $i < $w_cnt; ++$i) {
	   ($words[$i], undef, $line) = split(/\s+/, $line, 3);
    }
    foreach my $word (@words) {
        $word = delMarker($word);
        my $lword = lower ($word);
        my @offArr = $self->_indexOffsetLookup($lword, $pos);
        for (my $i=0; $i < @offArr; $i++) {
            if ($offArr[$i] == $offset) {
                push @rtn, "$word\#$pos\#".($i+1);
                last;
            }
        }
    }
    return @rtn;
}

# returns word#pos#sense for given offset and pos
sub getSense#
{
    my ($self, $offset, $pos) = @_;
    warn "(getSense) offset=$offset pos=$pos\n" if ($self->{verbose});
    
    my $line = $self->_dataLookup($pos, $offset);
    
    my ($lexfn,$word);
    (undef, $lexfn, undef, undef, $word, $line) = split (/\s+/, $line, 6);
    $word = delMarker($word);
    my $lword = lower($word);
    
    my @offArr = $self->_indexOffsetLookup($word, $pos);
    for (my $i=0; $i < @offArr; $i++) {
	   return "$word\#$pos\#".($i+1) if ($offArr[$i] == $offset);
    }
    die "(getSense) Internal error: offset=$offset pos=$pos";
}

sub _getIndexFH {
    my $self = shift;
    my $pos = shift;
    my $fh = $self->{index_fh}->[$pos_num{$pos}] ||= 
                   FileHandle->new ( ${$self->{indexFilePaths}}[$pos_num{$pos}] );
    unless ($fh) {
        die "Couldn't open index file: " . ${$self->{indexFilePaths}}[$pos_num{$pos}];
    }
    return $fh;
}

sub _getDataFH {
    my $self = shift;
    my $pos = shift;
    my $fh = $self->{data_fh}->[$pos_num{$pos}] ||= 
                   FileHandle->new ( ${$self->{dataFilePaths}}[$pos_num{$pos}] );
    unless ($fh) {
        die "Couldn't open data file: " . ${$self->{indexFilePaths}}[$pos_num{$pos}];
    }
    return $fh;
}

## returns the offset(s) given word, pos, and sense
sub _indexOffsetLookup {
    my $self = shift;
    my ($word, $pos, $sense) = @_;
    my $lword = lower ($word);
    # print STDERR "(_indexOffsetLookup) $word $pos $sense\n";
    if ($sense) {
        my $offset;
        if ($self->{noload}) {
            my $line = $self->_indexLookup($pos, $lword);
            my ($lemma, $pos, $offsets, $sense_cnt, $p_cnt) = $self->_parseIndexLine($line);
            $offset = $$offsets[$sense - 1] if ($lemma eq $lword); ## remember that look always succeeds
        }
        else
        {
            $offset = (unpack "i*", $self->{"index"}->[$pos_num{$pos}]->{$lword})[$sense-1]
                if (exists $self->{"index"}->[$pos_num{$pos}]->{$lword});
        }
        return $offset;
    }
    else
    {
        my @offsets = ();
        if ($self->{noload}) {
            my $line = $self->_indexLookup($pos, $lword);
            my ($lemma, $pos, $offsets, $sense_cnt, $p_cnt) = $self->_parseIndexLine($line);
            @offsets = @$offsets if ($lemma eq $lword);
        }
        else
        {
            if (defined($self->{"index"}->[$pos_num{$pos}]->{$lword})) {
                @offsets = (unpack "i*", $self->{"index"}->[$pos_num{$pos}]->{$lword});
            }
        }
        return @offsets;
    }
}

## returns line from index file
sub _indexLookup {
    my $self = shift;
    my ($pos, $word) = @_;
    my $fh = $self->_getIndexFH($pos);
    look($fh, $word, 0);
    my $line  = <$fh>;
    return $line;
}

## returns line from data file
sub _dataLookup {
    my $self = shift;
    my ($pos, $offset) = @_;
    my $fh = $self->_getDataFH($pos);
    seek($fh, $offset, 0);
    my $line  = <$fh>;
    return $line;
}

# returns word#pos#sense for given offset, pos and number
sub getWord#
{
    my ($self, $offset, $pos, $num) = @_;
    warn "(getWord) offset=$offset pos=$pos num=$num" if ($self->{verbose});
    
    my $fh = $self->_getDataFH($pos);
    seek $fh, $offset, 0;
    my $line = <$fh>;
    my $w_cnt;
    (undef, undef, undef, $w_cnt, $line) = split (/\s+/, $line, 5);
    $w_cnt = hex ($w_cnt);
    my $word;
    for (my $i=0; $i < $w_cnt; ++$i) {
	   ($word, undef, $line) = split(/\s+/, $line, 3);
	   $word = delMarker($word);
	   # (mich0212) return "$word\#$pos" if ($i+1 == $num);
	   last if ($i+1 == $num);
    }
    my $lword = lower($word);
    my @offArr = $self->_indexOffsetLookup($lword, $pos);;
    for (my $i=0; $i < @offArr; $i++) {
	   return "$word\#$pos\#".($i+1) if ($offArr[$i] == $offset);
    }
    die "(getWord) Bad number: offset=$offset pos=$pos num=$num";
}


#sub offset#
#{
#    my ($self, $string) = @_;
#
#    my ($word, $pos, $sense)
#	= $string =~ /^([^\#]+)(?:\#([^\#]+)(?:\#(\d+))?)?$/; 
#    warn "(offset) WORD=$word POS=$pos SENSE=$sense\n"
#	if ($self->{verbose});
#    die "(offset) Bad query string: $string"
#	if (!defined($sense)
#	    or !defined($pos)
#	    or !defined($word)
#	    or !defined($pos_num{$pos}));
#    my $lword = lower ($word);
#    return (unpack "i*", $self->{"index"}->[$pos_num{$pos}]->{$lword})[$sense-1];
#}

# Return the WordNet data file offset for a fully qualified word sense
sub offset#
{
   my ($self, $string) = @_;

   my ($word, $pos, $sense)
       = $string =~ /^([^\#]+)(?:\#([^\#]+)(?:\#(\d+))?)?$/;
   warn "(offset) WORD=$word POS=$pos SENSE=$sense\n"
       if ($self->{verbose});
   
   if (!defined($sense)
       or !defined($pos)
       or !defined($word)
       or !defined($pos_num{$pos})) {
       $self->{errorVal} = 1;
       $self->{errorString} = "One or more bogus arguments: offset($word,$pos,$sense)";
       return;#die "(offset) Bad query string: $string";
   }

   my $lword = lower($word);
   my $res = $self->_indexOffsetLookup($lword, $pos, $sense);

   return $res if $res;

   $self->{errorVal} = 2;
   $self->{errorString} = "Index not initialized properly or `$word' not found in index";
   return;
}

# Return the lexname for the type (3) query string
sub lexname#
{
    my ($self, $string) = @_;

    my $offset = $self->offset($string);
    my ($word, $pos, $sense) = $string =~ /^([^\#]+)(?:\#([^\#]+)(?:\#(\d+))?)?$/; 
    warn "(lexname) word=$word pos=$pos sense=$sense offset=$offset\n" if ($self->{verbose});
    my $line = $self->_dataLookup($pos, $offset);
    my (undef, $lexfn, undef) = split (/\s+/, $line, 3);
    return $lexnames{$lexfn};
}

# Return the frequency count for the type (3) query string
# Added by mich0212 (12/1/04)
sub frequency
{
    my ($self, $string) = @_;
    my ($word, $pos, $sense) = $string =~ /^([^\#]+)\#([^\#]+)\#([^\#]+)$/;

    unless (defined $word and defined $pos and defined $sense) {
	   croak "(frequency) Query string is not a valid type (3) string";
    }

    warn "(frequency) word=$word pos=$pos sense=$sense\n" if $self->{verbose};

    my $cntfile = File::Spec->catfile ( $self->{dir} . 'cntlist.rev');
    open CFH, "<$cntfile" or die "Cannot open $cntfile: $!";
    
    # look() seek()s to the right position in the file
    my $position = Search::Dict::look (*CFH, "$word\%", 0, 0);
    while (<CFH>) {
        if (/^$word\%(\d+):[^ ]+ (\d+) (\d+)/) {
            next unless $pos_map{$1} eq $pos;
            next unless $2 eq $sense;
            close CFH;
            return $3;
        }
        else {
            last;
        }
    }
    close CFH;
    return 0;
}

sub querySense#
{
    my $self = shift;
    my $string = shift;
    
    warn "(querySense) STRING=$string" if $self->{verbose};
    
    # Ensure that input record separator is "\n"
    my $old_separator = $/;
    $/ = "\n";
    my @rtn;
        
    # get word, pos, and sense from second argument:
    my ($word, $pos, $sense) = $string =~ /^([^\#]+)(?:\#([^\#]+)(?:\#(\d+))?)?$/; 
    die "(querySense) Bad query string: $string" if (!defined($word));
    my $lword = lower ($word);
    die "(querySense) Bad part-of-speech: $string" if (defined($pos) && !$pos_num{$pos});
    
    if (defined($sense)) {
        my $rel = shift;
        warn "(querySense) WORD=$word POS=$pos SENSE=$sense RELATION=$rel\n" if ($self->{verbose});
        die "(querySense) Relation required: $string" if (!defined($rel));
        die "(querySense) Bad relation: $rel" 
            if (!defined($relNameSym{$rel}) and !defined($relSymName{$rel})
             and ($rel ne "glos") and ($rel ne "syns"));
        $rel = $relSymName{$rel} if (defined($relSymName{$rel}));
        
        my $offset = $self->_indexOffsetLookup($lword, $pos, $sense);
        my $line = $self->_dataLookup($pos, $offset);
        
        if (!$line) {
            die "Line not found for offset $offset!";
        }
        
        if ($rel eq "glos") {
            $line =~ m/.*\|\s*(.*)$/;
            $rtn[0] = $1;
        } elsif ($rel eq "syns") {
            @rtn = $self->getAllSenses ($offset, $pos);
        } else {
            @rtn = $self->getSensePointers($line, $relNameSym{$rel});
        }
    }
    elsif (defined($pos)) {
        warn "(querySense) WORD=$word POS=$pos\n" if ($self->{verbose});
        my @offsets = $self->_indexOffsetLookup($lword, $pos);
        $word = underscore(delMarker($word));
        for (my $i=0; $i < @offsets; $i++) {
            push @rtn, "$word\#$pos\#".($i+1);
        }
    }
    elsif (defined($word)) {
        warn "(querySense) WORD=$word\n" if ($self->{verbose});
        $word = underscore(delMarker($word));
        for (my $i=1; $i <= 4; $i++) {
            my ($offset) = $self->_indexOffsetLookup($lword, $i);
            push @rtn, "$word\#".$pos_map{$i} if $offset;
        }
    }
    else
    {
        warn "(querySense) no results being returned" if $self->{verbose};
    }
    # Return setting of input record separator
    $/ = $old_separator;
    return @rtn;
}

sub queryWord#
{
    my $self = shift;
    my $string = shift;

    # (mich0212) warn "queryWord: WARNING: certain aspects of this function are broken.  It needs\n a rewrite.  Use at your own risk.\n";
    
    # Ensure that input record separator is "\n"
    my $old_separator = $/;
    $/ = "\n";
    my @rtn;
    
    # get word, pos, and sense from second argument:
    my ($word, $pos, $sense) = $string =~ /^([^\#]+)(?:\#([^\#]+)(?:\#(\d+))?)?$/; 
    die "(queryWord) Bad query string: $string" if (!defined($word));
    my $lword = lower ($word);
    die "(queryWord) Bad part-of-speech: $string" if (defined($pos) && !$pos_num{$pos});
    
    if (defined($sense)) {
        my $rel = shift;
        warn "(queryWord) WORD=$word POS=$pos SENSE=$sense RELATION=$rel\n" 
            if ($self->{verbose});
        die "(queryWord) Relation required: $string" if (!defined($rel));
        die "(queryWord) Bad relation: $rel"
            if ((!defined($relNameSym{$rel}) and !defined($relSymName{$rel})));
        $rel = $relSymName{$rel} if (defined($relSymName{$rel}));
        
        my $offset = $self->_indexOffsetLookup($lword, $pos, $sense);
        my $line = $self->_dataLookup($pos, $offset);
	    push @rtn, $self->getWordPointers($line, $relNameSym{$rel}, $word);
    }
    elsif (defined($pos))
    {
        warn "(queryWord) WORD=$word POS=$pos\n" if ($self->{verbose});
        my @offsets = $self->_indexOffsetLookup($lword, $pos);
        $word = underscore(delMarker($word));
        for (my $i=0; $i < @offsets; $i++) {
            push @rtn, "$word\#$pos\#".($i+1);
        }
    }
    else
    {
        print STDERR "(queryWord) WORD=$word\n" if ($self->{verbose});
        
        $word = underscore(delMarker($word));
        for (my $i=1; $i <= 4; $i++) {
            my $offset = $self->_indexOffsetLookup($lword, $i);
            push @rtn, "$word\#".$pos_map{$i} if $offset;
        }
    }
    # Return setting of input record separator
    $/ = $old_separator;
    return @rtn;
}

# return list of entries in wordnet database (in word#pos form)
sub validForms#
{
    my ($self, $string) = @_;
    my (@possible_forms, @valid_forms);
    
    # get word, pos, and sense from second argument:
    my ($word, $pos, $sense) = $string =~ /^([^\#]+)(?:\#([^\#]+)(?:\#(\d+))?)?$/; 
    warn "(valid_forms) Sense number ignored: $string\n" if (defined $sense);
    if (!defined($pos)) {
        my @rtn;
        push @rtn, $self->validForms($string."#n");
        push @rtn, $self->validForms($string."#v");
        push @rtn, $self->validForms($string."#a");
        push @rtn, $self->validForms($string."#r");
        return @rtn;
    }
    
    die "(valid_forms) Invalid part-of-speech: $pos" if (!defined($pos_map{$pos}));
    @possible_forms = $self->forms ("$word#$pos");
    @valid_forms = grep $self->querySense ($_), @possible_forms;
    
    return @valid_forms;
}

sub _parseIndexLine {
    my $self = shift;
    my $line = shift;
    my ($lemma, $pos, $sense_cnt, $p_cnt, $rline) = split(/\s+/, $line, 5);
    for (my $i=0; $i < $p_cnt; ++$i) {
        (undef, $rline) = split(/\s+/, $rline, 2);
    }
    my (undef, $tagsense_cnt, @offsets) = split(/\s+/, $rline);
    ## return offset list packed if caching, otherwise just use an array ref
    if ($self->{noload}) {
        return ($lemma, $pos, \@offsets, $tagsense_cnt);
    }
    else
    {
        return ($lemma, $pos, (pack "i*", @offsets), $tagsense_cnt);
    }
}

# List all words in WordNet database of a particular part of speech
sub listAllWords#
{
    my ($self, $pos) = @_;
    if ($self->{noload}) {
        my @words;
        my $fh = $self->_getIndexFH($pos);
        seek($fh, 0, 0);
        for my $line (<$fh>) {
            next if ($line =~ m/^\s/);
            my ($lemma, @rest) = $self->_parseIndexLine($line);
            push @words, $lemma;
        }
        return @words;
    }
    else
    {
        return keys(%{$self->{"index"}->[$pos_num{$pos}]});
    }
}

# Return length of (some) path to root, plus one (root is considered
# to be level 1); $word must be word#pos#sense form
sub level#
{
    my ($self, $word) = @_;
    my $level;
    
    for ($level=0; $word; ++$level)
    {
	   ($word) = $self->querySense ($word, "hype");
    }
    return $level;
}

sub tagSenseCnt
{
    my ($self, $string) = @_;
    # get word, pos, and sense from second argument:
    my ($word, $pos, $sense) = $string =~ /^([^\#]+)(?:\#([^\#]+)(?:\#(\d+))?)?$/; 
    warn "(tagSenseCnt) Ignorning sense: $string" if (defined($sense));
    die "Word and part-of-speech required word=$word pos=$pos" if (!defined($word) or !defined($pos) or !defined($pos_num{$pos}));
    my $lword = lower($word);
    return $self->_getTagSenseCnt($lword, $pos);
}

sub dataPath {
    my $self = shift;
    return $self->{dir};
}

sub _getTagSenseCnt {
    my $self = shift;
    my ($lword, $pos) = @_;
    if ($self->{noload}) {
        my $line = $self->_indexLookup($pos, $lword);
        my ($lemma, $pos, $offsets, $tagsense_cnt) = $self->_parseIndexLine($line);
        return $tagsense_cnt if ($lemma eq $lword);
    }
    else
    {
        return $self->{"tagsense_cnt"}->[$pos_num{$pos}]->{$lword};
    }
}

# module must return true
1;
__END__

#################
# Documentation #
#################

=head1 NAME

WordNet::QueryData - direct perl interface to WordNet database

=head1 SYNOPSIS

  use WordNet::QueryData;

  my $wn = WordNet::QueryData->new( noload => 1);

  print "Synset: ", join(", ", $wn->querySense("cat#n#7", "syns")), "\n";
  print "Hyponyms: ", join(", ", $wn->querySense("cat#n#1", "hypo")), "\n";
  print "Parts of Speech: ", join(", ", $wn->querySense("run")), "\n";
  print "Senses: ", join(", ", $wn->querySense("run#v")), "\n";
  print "Forms: ", join(", ", $wn->validForms("lay down#v")), "\n";
  print "Noun count: ", scalar($wn->listAllWords("noun")), "\n";
  print "Antonyms: ", join(", ", $wn->queryWord("dark#n#1", "ants")), "\n";

=head1 DESCRIPTION

WordNet::QueryData provides a direct interface to the WordNet database
files.  It requires the WordNet package
(http://www.cogsci.princeton.edu/~wn/).  It allows the user direct
access to the full WordNet semantic lexicon.  All parts of speech are
supported and access is generally very efficient because the index and
morphical exclusion tables are loaded at initialization. The module can 
optionally be used to load the indexes into memory for extra-fast lookups.

=head1 USAGE

=head2 LOCATING THE WORDNET DATABASE

To use QueryData, you must tell it where your WordNet database is.
There are two ways you can do this: 1) by setting the appropriate
environment variables, or 2) by passing the location to QueryData when
you invoke the "new" function.

QueryData knows about two environment variables, WNHOME and
WNSEARCHDIR.  If WNSEARCHDIR is set, QueryData looks for WordNet data
files there.  Otherwise, QueryData looks for WordNet data files in
WNHOME/dict (WNHOME\dict on a PC).  If WNHOME is not set, it defaults
to "/usr/local/WordNet-3.0" on Unix and "C:\Program Files\WordNet\3.0"
on a PC.  Normally, all you have to do is to set the WNHOME variable
to the location where you unpacked your WordNet distribution.  The
database files are normally unpacked to the "dict" subdirectory.

You can also pass the location of the database files directly to
QueryData.  To do this, pass the location to "new":

  my $wn = WordNet::QueryData->new("/usr/local/wordnet/dict");

You can instead call the constructor with a hash of params, as in:

  my $wn = WordNet::QueryData->new(
      dir => "/usr/local/wordnet/dict",
      verbose => 0,
      noload => 1
  );
  
When calling "new" in this fashion, two additional arguments are 
supported; "verbose" will output debugging information, and "noload"
will cause the object to *not* load the indexes at startup.

=head2 CACHING VERSUS NOLOAD

The "noload" option results in data being retrieved using a 
dictionary lookup rather than caching the indexes in RAM.
This method yields an immediate startup time but *slightly* (though
less than you might think) longer lookup time. For the curious, here
are some profile data for each method on a duo core intel mac, averaged
seconds over 10000 iterations:

=head3 Caching versus noload times in seconds

                                          noload => 1  noload => 0
------------------------------------------------------------------
new()                                     0.00001      2.55
queryWord("descending")                   0.0009       0.0001
querySense("sunset#n#1", "hype")          0.0007       0.0001
validForms ("lay down#2")                 0.0004       0.0001

Obviously the new() comparison is not very useful, because nothing is 
happening with the constructor in the case of noload => 1. Similarly,
lookups with caching are basically just hash lookups, and therefore very
fast. The lookup times for noload => 1 illustrate the tradeoff between 
caching at new() time and using dictionary lookups.

Because of the lookup speed increase when noload => 0, many users will
find it useful to set noload to 1 during development cycles, and to 0
when RAM is less of a concern than speed. The bottom line is that 
noload => 1 saves you over 2 seconds of startup time, and costs you about 
0.0005 seconds per lookup.

=head2 QUERYING THE DATABASE

There are two primary query functions, 'querySense' and 'queryWord'.
querySense accesses semantic (sense to sense) relations; queryWord
accesses lexical (word to word) relations.  The majority of relations
are semantic.  Some relations, including "also see", antonym,
pertainym, "participle of verb", and derived forms are lexical.
See the following WordNet documentation for additional information:

  http://wordnet.princeton.edu/man/wninput.5WN#sect3

Both functions take as their first argument a query string that takes
one of three types:

  (1) word (e.g. "dog")
  (2) word#pos (e.g. "house#n")
  (3) word#pos#sense (e.g. "ghostly#a#1")

Types (1) or (2) passed to querySense or queryWord will return a list
of possible query strings at the next level of specificity.  When type
(3) is passed to querySense or queryWord, it requires a second
argument, a relation.  Relations generally only work with one function
or the other, though some relations can be either semantic or lexical;
hence they may work for both functions.  Below is a list of known
relations, grouped according to the function they're most likely to
work with:

  queryWord
  ---------
  also - also see
  ants - antonyms
  deri - derived forms (nouns and verbs only)
  part - participle of verb (adjectives only)
  pert - pertainym (pertains to noun) (adjectives only)
  vgrp - verb group (verbs only)

  querySense
  ----------
  also - also see
  glos - word definition
  syns - synset words
  hype - hypernyms
  inst - instance of
  hypes - hypernyms and "instance of"
  hypo - hyponyms
  hasi - has instance
  hypos - hyponums and "has instance"
  mmem - member meronyms
  msub - substance meronyms
  mprt - part meronyms
  mero - all meronyms
  hmem - member holonyms
  hsub - substance holonyms
  hprt - part holonyms
  holo - all holonyms
  attr - attributes (?)
  sim  - similar to (adjectives only)
  enta - entailment (verbs only)
  caus - cause (verbs only)
  domn - domain - all
  dmnc - domain - category
  dmnu - domain - usage
  dmnr - domain - region
  domt - member of domain - all (nouns only)
  dmtc - member of domain - category (nouns only)
  dmtu - member of domain - usage (nouns only)
  dmtr - member of domain - region (nouns only)

When called in this manner, querySense and queryWord will return a
list of related words/senses.  Note that as of WordNet 2.1, many
hypernyms have become "instance of" and many hyponyms have become "has
instance."

Note that querySense and queryWord use type (3) query strings in
different ways.  A type (3) string passed to querySense specifies a
synset.  A type (3) string passed to queryWord specifies a specific
sense of a specific word.

=head2 OTHER FUNCTIONS

"validForms" accepts a type (1) or (2) query string.  It returns a
list of all alternate forms (alternate spellings, conjugations,
plural/singular forms, etc.).  The type (1) query returns alternates
for all parts of speech (noun, verb, adjective, adverb).  WARNING:
Only the first argument returned by validForms is certain to be valid
(i.e. recognized by WordNet).  Remaining arguments may not be valid.

"listAllWords" accepts a part of speech and returns the full list of
words in the WordNet database for that part of speech.

"level" accepts a type (3) query string and returns a distance (not
necessarily the shortest or longest) to the root in the hypernym
directed acyclic graph.

"offset" accepts a type (3) query string and returns the binary offset of
that sense's location in the corresponding data file.

"tagSenseCnt" accepts a type (2) query string and returns the tagsense_cnt
value for that lemma: "number of senses of lemma that are ranked
according to their frequency of occurrence in semantic concordance
texts."

"lexname" accepts a type (3) query string and returns the lexname of
the sense; see WordNet lexnames man page for more information.

"frequency" accepts a type (3) query string and returns the frequency
count of the sense from tagged text; see WordNet cntlist man page
for more information.

See test.pl for additional example usage.

=head1 NOTES

Requires access to WordNet database files (data.noun/noun.dat,
index.noun/noun.idx, etc.)

=head1 COPYRIGHT

Copyright 2000-2005 Jason Rennie.  All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1)

http://wordnet.princeton.edu/

http://people.csail.mit.edu/~jrennie/WordNet/

=cut
