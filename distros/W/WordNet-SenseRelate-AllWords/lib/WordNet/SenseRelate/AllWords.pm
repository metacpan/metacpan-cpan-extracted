package WordNet::SenseRelate::AllWords;

# $Id: AllWords.pm,v 1.40 2009/05/27 20:58:27 kvarada Exp $

=head1 NAME

WordNet::SenseRelate::AllWords - Disambiguate All Words in a Text based on semantic similarity and relatedness in WordNet 

=head1 SYNOPSIS

  use WordNet::SenseRelate::AllWords;
  use WordNet::QueryData;
  use WordNet::Tools;
  my $qd = WordNet::QueryData->new;
  defined $qd or die "Construction of WordNet::QueryData failed";
  my $wntools = WordNet::Tools->new($qd);
  defined $wntools or die "\nCouldn't construct WordNet::Tools object"; 

  my $wsd = WordNet::SenseRelate::AllWords->new (wordnet => $qd,
						 wntools => $wntools,
                                                 measure => 'WordNet::Similarity::lesk');

  my @context = qw/the bridge is held up by red tape/;
  my @results = $wsd->disambiguate (window => 3,
				    context => [@context]);
  print "@results\n";

=head1 DESCRIPTION

WordNet::SenseRelate::AllWords implements an algorithm for Word Sense
Disambiguation that uses measures of semantic relatedness.  The algorithm
is an extension of an algorithm described by Pedersen, Banerjee, and
Patwardhan[1].  This implementation is similar to the original SenseRelate
package but disambiguates every word in the given context rather than just
single word.

=head2 Methods

Note: the methods below will die() on serious errors.  Wrap calls to the
methods in an eval BLOCK to catch the exceptions.  See
'perldoc -f eval' for more information.

Example:

  my @res;
  eval {@res = $wsd->disambiguate (args...)}

  if ($@){
      print STDERR "An exception occurred ($@)\n";
  }

=over

=cut

use 5.006;
use strict;
use warnings;
use Carp;

our @ISA = ();

our $VERSION = '0.19';

my %wordnet;
my %wntools;
my %simMeasure; # the similarity/relatedness measure
my %stoplist;
my %pairScore;
my %contextScore;
my %trace;
my %outfile;
my %forcepos;
my %nocompoundify;
my %usemono;
my %backoff;
my %wnformat;
my %fixed;

# closed class words
use constant {CLOSED => 'c',
	      NOINFO => 'f'};

# constants used to specify trace levels
use constant TR_CONTEXT    =>  1;  # show the context window
use constant TR_BESTSCORE  =>  2;  # show the best score
use constant TR_ALLSCORES  =>  4;  # show all non-zero scores
use constant TR_PAIRWISE   =>  8;  # show all the non-zero similarity scores
use constant TR_ZERO       => 16;  
use constant TR_MEASURE    => 32;  # show similarity measure traces

# Penn tagset
my %wnTag = (
    JJ => 'a',
    JJR => 'a',
    JJS => 'a',
    CD => 'a',
    RB => 'r',
    RBR => 'r',
    RBS => 'r',
    RP => 'r',
    WRB => CLOSED,
    CC => CLOSED,
    IN => 'r',
    DT => CLOSED,
    PDT => CLOSED,
    CC => CLOSED,
    'PRP$' => CLOSED,
    PRP => CLOSED,
    WDT => CLOSED,
    'WP$' => CLOSED,
    NN => 'n',
    NNS => 'n',
    NNP => 'n',
    NNPS => 'n',
    PRP => CLOSED,
    WP => CLOSED,
    EX => CLOSED,
    VBP => 'v',
    VB => 'v',
    VBD => 'v',
    VBG => 'v',
    VBN => 'v',
    VBZ => 'v',
    VBP => 'v',
    MD => 'v',
    TO => CLOSED,
    POS => undef,
    UH => CLOSED,
    '.' => undef,
    ':' => undef,
    ',' => undef,
    _ => undef,
    '$' => undef,
    '(' => undef,
    ')' => undef,
    '"' => undef,
    FW => NOINFO,
    SYM => undef,
    LS => undef,
    );

=item B<new>Z<>

Z<>The constructor for this class.  It will create a new instance and
return a reference to the constructed object.

Parameters:

  wordnet      => REFERENCE : WordNet::QueryData object
  wntools	   => REFERENCE : WordNet::Tools object
  measure      => STRING    : name of a WordNet::Similarity measure
  config       => FILENAME  : config file for above measure
  outfile      => FILENAME  : name of a file for output (optional)
  stoplist     => FILENAME  : file containing list of stop words
  pairScore    => INTEGER   : minimum pairwise score (default: 0)
  contextScore => INTEGER   : minimum overall score (default: 0)
  trace        => INTEGER   : generate traces (default: 0)
  forcepos     => INTEGER   : do part-of-speech coercion (default: 0)
  nocompoundify => INTEGER  : disable compoundify (default: 0)
  usemono => INTEGER  : enable assigning the available sense to usemono (default: 0)
  backoff => INTEGER  : enable assigning most frequent sense if the measure can't assign sense (default: 0)

Returns:

  A reference to the constructed object.

Example:

  WordNet::SenseRelate::AllWords->new (wordnet => $query_data_obj,
				       wntools => $wordnet_tools_obj,
                                       measure => 'WordNet::Similarity::lesk',
                                       trace   => 1);

The trace levels are:

  1 Show the context window for each pass through the algorithm.

  2 Display winning score for each pass (i.e., for each target word).

  4 Display the non-zero scores for each sense of each target
    word (overrides 2).

  8 Display the non-zero values from the semantic relatedness measures.

 16 Show the zero values as well when combined with either 4 or 8.
    When not used with 4 or 8, this has no effect.

 32 Display traces from the semantic relatedness module.

These trace levels can be added together.  For example, by specifying
a trace level of 3, the context window will be displayed along with
the winning score for each pass.

=cut

sub new
{
    my $class = shift;
    my %args = @_;
    $class = ref $class || $class;

    my $qd;
    my $wnt;
    my $measure;
    my $measure_config;
    my $stoplist;
    my $pairScore = 0;
    my $contextScore = 0;
    my $trace;
    my $outfile;
    my $forcepos;
    my $nocompoundify=0;
    my $usemono=0;
    my $backoff=0;
    my $fixed = 0;
    my $wnformat = 0;

    while (my ($key, $val) = each %args) {
	if ($key eq 'wordnet') {
	    $qd = $val; 
	}
	elsif ($key eq 'wntools')
		{
		$wnt = $val;
		}
	elsif ($key eq 'measure') {
	    $measure = $val;
	}
	elsif ($key eq 'config') {
	    $measure_config = $val;
	}
	elsif ($key eq 'stoplist') {
	    $stoplist = $val;
	}
	elsif ($key eq 'pairScore') {
	    $pairScore = $val;
	}
	elsif ($key eq 'contextScore') {
	    $contextScore = $val;
	}
	elsif($key eq 'nocompoundify'){
	    $nocompoundify=$val;	
	}
	elsif($key eq 'usemono'){
	    $usemono=$val;	
	}
	elsif($key eq 'backoff'){
	    $backoff=$val;	
	}
	elsif ($key eq 'trace') {
	    $trace = $val;
	    $trace = defined $trace ? $trace : 0;
	}
	elsif ($key eq 'outfile') {
	    $outfile = $val;
	}
	elsif ($key eq 'forcepos') {
	    $forcepos = $val;
	}
	elsif ($key eq 'fixed') {
	    $fixed = $val;
	}
	elsif ($key eq 'wnformat') {
	    $wnformat = $val;
	}
	else {
	    croak "Unknown parameter type '$key'";
	}
    }

    unless (ref $qd) {
	croak "No WordNet::QueryData object supplied";
    }

	unless (ref $wnt) {
	croak "No WordNet::Tools object supplied";
    }

    unless ($measure) {
	croak "No relatedness measure supplied";
    }

    my $self = bless [], $class;

    # initialize tracing;
    if (defined $trace) {
	$trace{$self} = {level => $trace, string => ''};
    }
    else {
	$trace{$self} = {level => 0, string => ''};
    }

    # require the relatedness modules
    my $file = $measure;
    $file =~ s/::/\//g;
    require "${file}.pm";

    # construct the relatedness object
    if (defined $measure_config) {
	$simMeasure{$self} = $measure->new ($qd, $measure_config);
    }
    else {
	$simMeasure{$self} = $measure->new ($qd);
    }

    # check for errors
    my ($errCode, $errStr) = $simMeasure{$self}->getError;
    if ($errCode) {
	carp $errStr;
    }

    # turn on traces in the relatedness measure if required
    if ($trace{$self}->{level} & TR_MEASURE) {
	$simMeasure{$self}->{trace} = 1;
    }
    else {
	$simMeasure{$self}->{trace} = 0;
    }


    # save ref to WordNet::QueryData obj
    $wordnet{$self} = $qd;

    # save ref to WordNet::Tools obj
    $wntools{$self} = $wnt;

    $self->_loadStoplist ($stoplist) if defined $stoplist;

    # store threshold values
    $pairScore{$self} = $pairScore;
    $contextScore{$self} = $contextScore;

    # save output file name
    $outfile{$self} = $outfile;
    if ($outfile and -e $outfile) {
	unlink $outfile;
    }

    if (defined $forcepos) {
	$forcepos{$self} = $forcepos;
    }
    else {
	$forcepos{$self} = 0;
    }

    if (defined $nocompoundify) {
	$nocompoundify{$self} = $nocompoundify;
    }
    else {
	$nocompoundify{$self} = 0;
    }

    if (defined $usemono) {
	$usemono{$self} = $usemono;
    }
    else {
	$usemono{$self} = 0;
    }

    if (defined $backoff) {
	$backoff{$self} = $backoff;
    }
    else {
	$backoff{$self} = 0;
    }




    $fixed{$self} = $fixed;

    $wnformat{$self} = $wnformat;

    return $self;
}

# the destructor for this class.  You shouldn't need to call this
# explicitly (but if you really want to, you can see what happens)
sub DESTROY
{
    my $self = shift;
    delete $wordnet{$self};
    delete $wntools{$self};
    delete $simMeasure{$self};
    delete $stoplist{$self};
    delete $pairScore{$self};
    delete $contextScore{$self};
    delete $trace{$self};
    delete $outfile{$self};
    delete $forcepos{$self};
    delete $nocompoundify{$self};
    delete $usemono{$self};
    delete $backoff{$self};
    delete $wnformat{$self};
    delete $fixed{$self};

    1;
}

sub wordnet : lvalue
{
    my $self = shift;
    $wordnet{$self};
}

=item B<disambiguate>

Disambiguates all the words in the specified context and returns them
as a list.  If a word cannot be disambiguated, then it is returned "as is".
A word cannot be disambiguated if it is not in WordNet or if no value
exceeds the specified threshold.

The context parameter specifies the
words to be disambiguated.  It treats the value as one sentence.  To
disambiguate a document with multiple sentences, make one call to
disambiguate() for each sentence.

Parameters:

  window => INTEGER    : the window size to use.  A window size of N means
                         that the window will include N words, including
                         the target word.  If N is an even number, there
                         will be one more word on the left side of the
                         target word than on the right.
  tagged => BOOLEAN    : true if the text is tagged, false otherwise
  scheme => normal|sense1|random|fixed : the disambiguation scheme to use
  context => ARRAY_REF : reference to an array of words to disambiguate

Returns:  An array of disambiguated words.

Example:

  my @results =
    $wsd->disambiguate (window => 3, tagged => 0, context => [@words]);

Rules for attaching suffixes:

Suffixes are attached to the words in the context in order to ignore those while disambiguation. 
Note that after converting the tags to WordNet tags, tagged text is treated same as wntagged text.

Below is the ordered enumeration of the words which are ignored for disambiguation and the suffixes attached to those words. 

Note that we check for such words in the order below:

 1 stopwords => #o 

 2 Only for tagged text :

    i)   Closed Class words => #CL

    ii)  Invalid Tag => #IT

    iii) Missing Word => #MW

 3 For tagged and wntagged text:

    i)	 No Tag => #NT

    ii)  Missing Word => #MW

    iii) Invalid Tag => #IT

 4 Not in WordNet => #ND

 5 No Relatedness found with the surrounding words => #NR

=cut 

#The scheme can have three different values:
#
#=over
#
#=item normal
#
#This is the normal mode of operation, where disambiguation is done by
#measuring the semantic relatedness of the senses of each word with the
#surrounding words.
#
#=item sense1
#
#In this mode, the first sense number (i.e., sense number 1) is assigned
#to each word.  In WordNet, the first sense of a word is I<usually> the
#most frequent sense.
#
#=item random
#
#In this mode, sense numbers are randomly assigned to each word from the
#set of valid sense numbers for each word.  For example, the noun 'hart'
#has three senses in WordNet 2.0, so the word would randomly be assigned
#1, 2, or 3.  This may be useful for comparison purposes when evaluating
#experimental results.
#
# 
#
#
#=cut

sub disambiguate
{
    my $self = shift;
    my %options = @_;
    my $contextScore;
    my $pairScore;
    my $window = 3;   # default the window to 3 to avoid failure if omitted
    my $tagged;
    my @context;
    my $scheme = 'normal';

    while (my ($key, $value) = each %options){
	if ($key eq 'window') {
	    $window = $value;
	}
	elsif ($key eq 'tagged') {
	    $tagged = $value;
	}
	elsif ($key eq 'context') {
	    @context = @$value;
	}
	elsif ($key eq 'scheme') {
	    $scheme = $value;
	}
	else {
	    croak "Unknown option '$key'";
	}
    }

	# _initializeContext method 
	# 1) compoundifies the text
	# 2) checks if the word is a stopword. If it is a stopword, attaches \#o 
	# 3) converts position tags if we have tagged text
    my @newcontext = $self->_initializeContext ($tagged, @context);
		
	if($tagged || $wnformat{$self}){
		foreach my $word (@newcontext) {
			if ($word !~ /\#/) {
				$word = $word . "#NT";
			}
			elsif( $word =~ /^#/)
			{
				$word = $word . "#MW";
			}
			elsif ( $word !~ /\#[nvar]$/ && $word !~ /\#o\b/ && $word !~ /\#CL\b/ && $word !~ /\#IT\b/) {
				$word = $word . "#IT";
			}
		}
	}

    my @results;
    if ($scheme eq 'sense1') {
	@results = $self->doSense1 (@newcontext);
    }
    elsif ($scheme eq 'random') {
	@results = $self->doRandom (@newcontext);
    }
    elsif (($scheme eq 'normal') or ($scheme eq 'fixed')) {
	$fixed{$self} = 1 if $scheme eq 'fixed';
	@results = $self->doNormal ($pairScore, $contextScore, $window,
				    @newcontext);
    }
    else {
	croak ("Bad scheme '$scheme'.\n", 
	       "Scheme must be 'normal', 'sense1', 'random', or 'fixed'");
    }

   # my @rval = map {s/\#o//; $_} @results;
    my @rval = @results;

    if ($outfile{$self}) {
	open OFH, '>>', $outfile{$self} or croak "Cannot open outfile: $!";
	print OFH "\n\n";
	print OFH "Results after disambiguation...\n";
	for my $i (0..$#newcontext) {
	    my $orig_word = $newcontext[$i];
	    my $new_word = $rval[$i];
	    my ($w, $p, $s) = $new_word =~ /([^\#]+)(?:\#([^\#]+)(?:\#([^\#]+))?)?/;
	    printf OFH "%25s", $orig_word;
	    printf OFH " %24s", $w;
	    printf OFH "%3s", $p if defined $p;
	    printf OFH "%3s", $s if defined $s;
	    print OFH "\n";
	}

	close OFH;
    }

    return @rval;
}

sub _initializeContext
{
    my $self = shift;
    my $tagged = shift;
    my $wn = $wordnet{$self};
    my $wnt = $wntools{$self};
    my $nocompoundify = $nocompoundify{$self};

    my @context = @_;

    # compoundify the words (if the text is raw)
    if (defined $wnt and $nocompoundify == 0 and defined !$tagged and !$wnformat{$self} ) {
		@context = split(/ +/,$wnt->compoundify("@context"));
    }

    my @newcontext;
    # do stoplisting
    if ($stoplist{$self}) {
	foreach my $word (@context) {
	    if ($self->isStop ($word)) {
		push @newcontext, $word."#o";
	    }
	    else {
		push @newcontext, $word;
	    }
	}
    }
    else {
	@newcontext = @context;
    }
	
    # convert POS tags, if we have tagged text
    if ($tagged) {
	foreach my $wpos (@newcontext) {
	    $wpos = $self->convertTag ($wpos);
		if (!defined $wpos) {
			$wpos="#MW";
		}
	}
    }

    return @newcontext;
}

sub doNormal {
    my $self = shift;
    my $pairScore = shift;
    my $contextScore = shift;
    my $window = shift;
    my @context = @_;

    my $lwindow = $window >> 1;   # simply divide by 2 & throw away remainder
    my $rwindow = $window - $lwindow - 1;

    # get all the senses for each word
    my @senses = $self->_getSenses (\@context);


    # disambiguate
    my @results;

    local $| = 1;

    my $sense1firstword = 0;

    # for each word in the context, disambiguate the (target) word
    for my $targetIdx (0..$#context) {
	my @target_scores;
	
	unless (ref $senses[$targetIdx]) {
	    $results[$targetIdx] = $context[$targetIdx];
	    next;
	}


	# figure out which words are in the window
	my $lower = $targetIdx - $lwindow;
	$lower = 0 if $lower < 0;
	my $upper = $targetIdx + $rwindow;
	$upper = $#context if $upper > $#context;

	# expand context window to the left, if necessary
	my $i = $targetIdx - 1;
	while ($i >= $lower) {
	    last if $lower == 0;
	    unless (defined $senses[$i] and (scalar @{$senses[$i]} > 0)) {
		$lower--;
	    }
	    $i--;
	}

	# expand context window to the right, if necessary
	my $j = $targetIdx + 1;
	while ($j <= $upper) {
	    last if $upper >= scalar $#context;
	    unless (defined $senses[$j] and (scalar @{$senses[$j]} > 0)) {
		$upper++;
	    }
	    $j++;
	}

    # If it is the first word in a sentence and the window size is 2, we'll 
    # consider a word at the right of the target word. Otherwise it will not be 
    # assigned any sense. In the previous version we were simply doing sense1 
    # which gave a boost to window=2 results. 

	if ($targetIdx==0 && $window == 2){
		$upper=1;
	}

	# do some tracing
	if ($trace{$self} and ($trace{$self}->{level} & TR_CONTEXT)) {
	    $trace{$self}->{string} .= "Context: ";
	    if ($lower < $targetIdx) {
		$trace{$self}->{string} .=
		    join (' ', @context[$lower..$targetIdx-1]) . ' ';
		
	    }

	    $trace{$self}->{string} .=
		"<target>$context[$targetIdx]</target>";
	    
	    if ($targetIdx < $upper) {
		$trace{$self}->{string} .= ' ' .
		    join (' ', @context[($targetIdx+1)..$upper]);
	    }

	    $trace{$self}->{string} .= "\n";
	}

	my $result;
	if ($sense1firstword) {
	    ##########################
	    my $word = $context[$targetIdx];

	    my $t = $self->getSense1 (\$context[$targetIdx]);
	    if (defined $t) {
		$sense1firstword = 0;
		$result = $t;
	    }
	    else {
		$result = $context[$targetIdx];
	    }
	}
	else {
	    if ($forcepos{$self}) {
		$result = $self->_forcedPosDisambig ($lower, $targetIdx,
						     $upper, \@senses,
						     \@context);
	    }
	    else {
		$result = $self->_normalDisambig ($lower, $targetIdx, $upper,
						  \@senses, \@context);
	    }
	}

	if ($fixed{$self}) {
	    if ($result =~ /\#[nvars]\#\d/) {
		$senses[$targetIdx] = [$result];
	    }
	}

	push @results, $result;
    }

    return @results;
}

=item B<getTrace>

Gets the current trace string and resets it to "".

Parameters:

  None

Returns:

  The current trace string (before resetting it).  If the returned string
  is not empty, it will end with a newline.

Example:

  my $str = $wsd->getTrace ();
  print $str;

=cut

sub getTrace
{
    my $self = shift;
    my $str = $trace{$self}->{string};
    $trace{$self}->{string} = '';
    return $str;
}

# does sense 1 disambiguation
sub doSense1
{
    my $self = shift;
    my @words = @_;
    my $wn = $wordnet{$self};

    my @disambiguated;

    foreach my $word (@words) {
	my $tmp = $self->getSense1 (\$word);
	if (defined $tmp) {
	    push @disambiguated, $tmp;
	}
	else {
	    push @disambiguated, $word;
	}
    }

    return @disambiguated;
}

# gets sense number 1 for the specified word.  If the word has multiple forms,
# then the most frequent sense is returned.  If there is more than one
# most frequent sense with sense number 1, a sense is chosen at random.
#
# this is not quite the same as choosing the most frequent sense of a word.
# The sense number 1 in wordnet is often the most frequent but not always.
sub getSense1
{
    my $self = shift;
    my $word_ref = shift;
    my $wn = $wordnet{$self};
    my %senses;
    
    # check if word has error suffix in it, if it does, we can't do anything with it
	if (${$word_ref} =~ /\#o|\#IT|\#CL|\#NT|\#MW/) {
		return undef;
    }

    my @forms;
    unless ($wnformat{$self}) {
	@forms = $wn->validForms (${$word_ref});
    }
    else {
	@forms = ${$word_ref};
    }
	if (scalar @forms == 0) {
	${$word_ref}= "${$word_ref}"."#ND";
	}
	else{
		foreach my $form (@forms) {
		my @t = $wn->querySense ($form);
		if (scalar @t > 0) {
			$senses{$form} = $t[0];
		}
		}
	}
    my @best_senses;

    foreach my $key (keys %senses) {
	my $sense = $senses{$key};

	my $freq = $wn->frequency ($sense);

	if ($#best_senses < 0) {
	    push @best_senses, [$sense, $freq];
	}
	elsif ($best_senses[$#best_senses]->[1] < $freq) {
	    @best_senses = ([$sense, $freq]);
	}
	elsif ($best_senses[$#best_senses]->[1] == $freq) {
	    push @best_senses, [$sense, $freq];
	}
	else {
	    # do nothing
	}
    }

    if (scalar @best_senses) {
	my $i = int (rand (scalar @best_senses));

	return $best_senses[$i]->[0];
    }

    return undef;
}

# does random guessing.  This could be considered a baseline approach
# of sorts.  Also try running normal disambiguation using the
# WordNet::Similarity::random measure
sub doRandom
{
    my $self = shift;
    my @words = @_;
    my $wn = $wordnet{$self};

    my $datapath = $wn->dataPath;

    my @disambiguated;

    foreach my $word (@words) {
	if ( $word =~ /\#o|\#IT|\#CL|\#NT|\#MW/) {
	    # push the string into the array
	    push @disambiguated, $word;
	    next;
	}

	my @forms;
	unless ($wnformat{$self}) {
	    @forms = $wn->validForms ($word);
	}
	else {
	    @forms = $word;
	}
	my @senses;
    if (scalar @forms == 0) {
		$word= "$word"."#ND";
	}
	else {	
		foreach my $form (@forms) {
			my @t = $wn->querySense ($form);
			if (scalar @t > 0) {
			push @senses, @t;
			}
		}
	}
	if (scalar @senses) {
	    my $i = int (rand (scalar @senses));
	    push @disambiguated, $senses[$i];
	}
	else {
	    push @disambiguated, $word;
	}


    }
    return @disambiguated;
}

sub _forcedPosDisambig
{
    my $self = shift;
    my $lower = shift;
    my $targetIdx = shift;
    my $upper = shift;
    my $senses_ref = shift;
    my $context_ref = shift;
    my $measure = $simMeasure{$self};
    my $result;
    my @traces;
    my @target_scores;


    # for each sense of the target word ...
    for my $i (0..$#{$senses_ref->[$targetIdx]}) {
	unless (ref $senses_ref->[$targetIdx]
		and  defined $senses_ref->[$targetIdx][$i]) {
	    $target_scores[$i] = -1;
	    next;
	}

	$target_scores[$i] = 0;

	my $target_pos = getPos ($senses_ref->[$targetIdx][$i]);

	# for each (context) word in the window around the target word
	for my $contextIdx ($lower..$upper) {
	    next if $contextIdx == $targetIdx;
	    next unless ref $senses_ref->[$contextIdx];

	    my @tempScores;

	    my @goodsenses;
	    # * check if senses for context word work with target word *
	    if (needCoercePos ($target_pos, $senses_ref->[$contextIdx])) {
		@goodsenses = $self->coercePos ($context_ref->[$contextIdx],
						$target_pos);
	    }
	    else {
		@goodsenses = @{$senses_ref->[$contextIdx]};
	    }

	    # for each sense of the context word in the window
	    for my $k (0..$#{$senses_ref->[$contextIdx]}) {
		unless (defined $senses_ref->[$contextIdx][$k]) {
		    $tempScores[$k] = -1;
		    next;
		}
		    
		$tempScores[$k] =
		    $measure->getRelatedness ($senses_ref->[$targetIdx][$i],
					      $senses_ref->[$contextIdx][$k]);
		    
		if ($trace{$self}->{level} & TR_PAIRWISE) {
		    # only trace zero values if TR_ZERO is specified
		    if ((defined $tempScores[$k] and $tempScores[$k] > 0)
			or ($trace{$self}->{level} & TR_ZERO)) {
			my $s = "      "
			    . $senses_ref->[$targetIdx][$i] . ' ' 
			    . $senses_ref->[$contextIdx][$k] . ' '
			    . (defined $tempScores[$k]
			       ? $tempScores[$k]
			       : 'undef');
			push @{$traces[$i]}, $s;
		    }
		}

		if ($trace{$self}->{level} & TR_MEASURE
		    and ((defined $tempScores[$k] and $tempScores[$k] > 0)
			 or ($trace{$self}->{level} & TR_ZERO))) {
		    push @{$traces[$i]}, $measure->getTraceString ();
		}
		# clear errors in Similarity object
		$measure->getError () unless defined $tempScores[$k];
	    }
	    my $best = -2;
	    foreach my $temp (@tempScores) {
		next unless defined $temp;
		$best = $temp if $temp > $best;
	    }

	    if ($best > $pairScore{$self}) {
		$target_scores[$i] += $best;
	    }
	}
    }

    # find the best score for this sense of the target word

    # first, do a bit of tracing
    if (ref $trace{$self} and ($trace{$self}->{level} & TR_ALLSCORES)) {
	$trace{$self}->{string} .= "  Scores for $context_ref->[$targetIdx]\n";
    }

    # now find the best sense
    my $best_tscore = -1;
    foreach my $i (0..$#target_scores) {
	my $tscore = $target_scores[$i];
	next unless defined $tscore;
	
	if ($trace{$self}->{level} & TR_ALLSCORES
	    and (($tscore > 0) or ($trace{$self}->{level} & TR_ZERO))) {
	    $trace{$self}->{string} .= "    $senses_ref->[$targetIdx][$i]: $tscore\n";
	}
	
	if (($trace{$self}->{level} & TR_MEASURE
	     or $trace{$self}->{level} & TR_PAIRWISE)
	    and defined $traces[$i]) {
	    foreach my $str (@{$traces[$i]}) {
		$trace{$self}->{string} .= $str . "\n";
	    }
	}

	# ignore scores less than the threshold
	next unless $tscore > $contextScore{$self};
	
	if ($tscore > $best_tscore) {
	    $result = $senses_ref->[$targetIdx][$i];
	    $best_tscore = $tscore;
	}
    }

    if ($best_tscore < 0) {
	$result = $context_ref->[$targetIdx];
    }
    
    if (ref $trace{$self} and $trace{$self}->{level} & TR_BESTSCORE) {
	$trace{$self}->{string} .= "  Winning score: $best_tscore\n";
    }

    return $result;
}

sub _normalDisambig
{
    my $self = shift;
    my $lower = shift;
    my $targetIdx = shift;
    my $upper = shift;
    my $senses_ref = shift;
    my $context_ref = shift;
    my $measure = $simMeasure{$self};
    my $usemono = $usemono{$self};
    my $backoff = $backoff{$self};
	
    my $result;

    my @traces;
    my @target_scores;

    # for each sense of the target word ...
    for my $i (0..$#{$senses_ref->[$targetIdx]}) {
	unless (ref $senses_ref->[$targetIdx]
		and  defined $senses_ref->[$targetIdx][$i]) {
	    $target_scores[$i] = -1;
	    next;
	}
	$target_scores[$i] = 0;
	# If --usemono flag is on and the word has only one sense then assign it.
	# This flag will be off by default.
	if($usemono == 1 && $#{$senses_ref->[$targetIdx]} == 0){
		$result = $senses_ref->[$targetIdx][0];
		return $result;
	}
	#my @tempScores;
	    

	# for each (context) word in the window around the target word
	for my $contextIdx ($lower..$upper) {
	    my @tempScores = ();
	    next if $contextIdx == $targetIdx;
	    next unless ref $senses_ref->[$contextIdx];

	    # for each sense of the context word in the window
	    for my $k (0..$#{$senses_ref->[$contextIdx]}) {
		unless (defined $senses_ref->[$contextIdx][$k]) {
		    $tempScores[$k] = -1;
		    next;
		}
		    
		$tempScores[$k] =
		    $measure->getRelatedness ($senses_ref->[$targetIdx][$i],
					      $senses_ref->[$contextIdx][$k]);
		    
		if ($trace{$self}->{level} & TR_PAIRWISE) {
		    # only trace zero values if TR_ZERO is specified
		    if ((defined $tempScores[$k] and $tempScores[$k] > 0)
			or ($trace{$self}->{level} & TR_ZERO)) {
			my $s =  "      "
			    .$senses_ref->[$targetIdx][$i] . ' ' 
			    .$senses_ref->[$contextIdx][$k] . ' '
			    . (defined $tempScores[$k]
			       ? $tempScores[$k]
			       : 'undef');

			push @{$traces[$i]}, $s;
		    }
		}

		if ($trace{$self}->{level} & TR_MEASURE
		    and ((defined $tempScores[$k] and $tempScores[$k] > 0) 
			 or ($trace{$self}->{level} & TR_ZERO))) {
		    push @{$traces[$i]}, $measure->getTraceString ();
		}

		# clear errors in Similarity object
		$measure->getError () unless defined $tempScores[$k];
	    }
	    my $best = -2;
	    foreach my $temp (@tempScores) {
		next unless defined $temp;
		
		$best = $temp if $temp > $best;
	    }

	    if ($best > $pairScore{$self}) {
		$target_scores[$i] += $best;
	    }
	}
    }

    # find the best score for this sense of the target word

    # first, do a bit of tracing
    if (ref $trace{$self} and ($trace{$self}->{level} & TR_ALLSCORES)) {
	$trace{$self}->{string} .= "  Scores for $context_ref->[$targetIdx]\n";
    }

    # now find the best sense
    my $best_tscore = -1;

    foreach my $i (0..$#target_scores) {
	my $tscore = $target_scores[$i];
	next unless defined $tscore;

	if ($trace{$self}->{level} & TR_ALLSCORES
	    && (($tscore > 0) or ($trace{$self}->{level} & TR_ZERO))) {
	    $trace{$self}->{string} .= "    $senses_ref->[$targetIdx][$i]: $tscore\n";
	}

	if (($trace{$self}->{level} & TR_MEASURE
	     or $trace{$self}->{level} & TR_PAIRWISE)
	    and defined $traces[$i]) {
	    foreach my $str (@{$traces[$i]}) {
		$trace{$self}->{string} .= $str . "\n";
	    }
	}

	# ignore scores less than the threshold
	next unless $tscore > $contextScore{$self};
	
	if ($tscore > $best_tscore) {
	    $result = $senses_ref->[$targetIdx][$i];
	    $best_tscore = $tscore;
	}
    }

    if ($best_tscore < 0) {
	#$result = $context_ref->[$targetIdx];
	$result = "$context_ref->[$targetIdx]"."#NR";
	if($backoff == 1){
		$result = $self->getSense1(\$context_ref->[$targetIdx]);
	}
    }
    
    if (ref $trace{$self} and $trace{$self}->{level} & TR_BESTSCORE) {
	$trace{$self}->{string} .= "  Winning score: $best_tscore\n";
    }

#    if ($trace{$self}->{level} & 8) { # | $trace{$self}->{level} & TR_PAIRWISE) {
#	foreach my $str (@traces) {
#	    $trace{$self}->{string} .= "$str\n";
#	}
#	@traces = ();
#    }
    return $result;
}

sub isStop
{
    my $self = shift;
    my $word = shift;
    foreach my $re (@{$stoplist{$self}}) {
	if ($word =~ /^$re$/) {
	    return 1;
	}
    }
    return 0;
}

# checks to see if the POS of at least one word#pos#sense string in $aref 
# is $pos
sub needCoercePos
{
    my $pos = shift;

    # Only coerce if target POS is noun or verb.
    # The measures that take advantage of POS coercion only work with
    # nouns and verbs.
    unless ($pos eq 'n' or $pos eq 'v') {
	return 0;
    }

    my $aref = shift;
    foreach my $wps (@$aref) {
	if ($pos eq getPos ($wps)) {
	    return 0;
	}
    }
    return 1;
}

sub convertTag
{
    my $self = shift;
    my $wordpos = shift;
    my $index = index $wordpos, "/";

    if ($index <  0) {
	return $wordpos;
    }
    elsif ($index == 0) {
	return undef;
    }
    elsif (index ($wordpos, "'") == 0) {
        # we have a contraction
        my $word = substr $wordpos, 0, $index;
        my $tag = substr $wordpos, $index + 1;
        return $self->convertContraction ($word, $tag);
    }
    else {
	my $word = substr $wordpos, 0, $index;
	my $old_pos_tag = substr $wordpos, $index + 1;
	my $new_pos_tag = $wnTag{$old_pos_tag};

	if ((defined $new_pos_tag) and ($new_pos_tag =~ /[nvar]/)) {
	    return $word . '#' . $new_pos_tag;
	}
	elsif((defined $new_pos_tag) and ($new_pos_tag =~ /[cf]/)){
		return $word . '#CL';
	}
	elsif(!(defined $new_pos_tag)){
		return $word . '#IT';
	}
	else {
		return $word;
	}
    }
}


sub convertContraction
{
    my ($self, $word, $tag) = @_;
    if ($word eq "'s") {
	if ($tag =~ /^V/) {
	    return "is#v";
	}
	else {
	    return "";
	}
    }
    elsif ($word eq "'re") {
	return "are#v";
    }
    elsif ($word eq "'d") {
	return "had#v"; # actually this could be would as well
    }
    elsif ($word eq "'ll") {
	return "will#v";
    }
    elsif ($word eq "'em") {
	return "";
    }
    elsif ($word eq "'ve") {
	return "have#v";
    }
    elsif ($word eq "'m") {
	return "am#v";
    }
    elsif ($word eq "'t") { # HELP should be n't
	return "not";
    }
    else {
	return "$word#$tag";
    }

}

# noun to non-noun ptr symbols, with frequencies
# -u 329 (dmnu)  - cf. domn (all domains)
# -r 80  (dmnr)
# = 648  (attr)
# -c 2372 (dmnc)
# + 21390 (deri) lexical

# verb to non-verb ptr symbols, with frequencies
# ;u 16   (dmtu) - cf. domt (all domains)
# ;c 1213 (dmtc)
# ;r 2    (dmtr)
# + 21095 (deri) lexical

# adj to non-adj
# \ 4672   (pert) pertains to noun ; lexical
# ;u 233  
# ;c 1125
# = 648    (attr)
# < 124    (part) particple of verb ; lexical
# ;r 76

# adv to non-adv
# \ 3208    (derived from adj)
# ;u 74
# ;c 37
# ;r 2

sub coercePos
{
    my $self = shift;
    my $word = shift;
    my $pos = shift;
    my $wn = $wordnet{$self};

    # remove pos tag, if present
    $word =~ s/\#.*//;

    my @forms = $wn->validForms ($word);

    if (0 >= scalar @forms) {
	return undef;
    }

    # pre-compile the pattern
    my $cpattern = qr/\#$pos/;

    foreach my $form (@forms) {
	if ($form =~ /$cpattern/) {
	    return $form;
	}
    }

    # didn't find a surface match, look along cross-pos relations

    my @goodforms;
    foreach my $form (@forms) {
	my @cands = $wn->queryWord ($form, "deri");
	foreach my $candidate (@cands) {
	    if ($candidate =~ /$cpattern/) {
		push @goodforms, $candidate;
	    }
	}
    }

    return @goodforms;
}

# get all senses for each context word
sub _getSenses
{
    my $self = shift;
    my $context_ref = shift;
    my @senses;
	for my $i (0..$#{$context_ref}){
	# first get all forms for each POS
	if ( (${$context_ref}[$i] =~ /\#o|\#IT|\#CL|\#NT|\#MW/) ) {
	    $senses[$i] = undef;
	}
	else {
	    my @forms;
	    unless ($wnformat{$self}) {
		@forms = $self->wordnet->validForms (${$context_ref}[$i]);
	    }
	    else {
		@forms = ${$context_ref}[$i];
	    }
	    if (scalar @forms == 0) {
		${$context_ref}[$i]= "${$context_ref}[$i]"."#ND";
	    }
	    else {
		# now get all the senses for each form
		foreach my $form (@forms) {
		    my @temps = $self->wordnet->querySense ($form);
		    push @{$senses[$i]}, @temps;
		}
	    }
	}
    }
    return @senses;
}

sub _loadStoplist
{
    my $self = shift;
    my $file = shift;
    open SFH, '<', $file or die "Cannot open stoplist $file: $!";
    $stoplist{$self} = [];
    while (my $line = <SFH>) {
        chomp $line;
	if ($line =~ m|/(.*)/|) {
	    push @{$stoplist{$self}}, qr/$1/;
	}
	else {
	    warn "Line $. of the stoplist '$file' is malformed\n";
	}
    }
    close SFH;
}

sub getPos
{
    my $string = shift;
    my $p = index $string, "#";
    return undef if $p < 0;
    my $pos = substr $string, $p+1, 1;
    return $pos;
}

1;

__END__

=pod

=back

=head1 SEE ALSO

 L<WordNet::Similarity::AllWords>

The main web page for SenseRelate is :

 L<http://senserelate.sourceforge.net/>

There are several mailing lists for SenseRelate:

 L<http://lists.sourceforge.net/lists/listinfo/senserelate-users/>

 L<http://lists.sourceforge.net/lists/listinfo/senserelate-news/>

 L<http://lists.sourceforge.net/lists/listinfo/senserelate-developers/>

=head1 REFERENCES

=over

=item [1] Ted Pedersen, Satanjeev Banerjee, and Siddharth Patwardhan 
(2005) Maximizing Semantic Relatedness to Perform Word Sense 
Disambiguation, University of Minnesota Supercomputing Institute 
Research Report UMSI 2005/25, March.
L<http://www.msi.umn.edu/general/Reports/rptfiles/2005-25.pdf>

=back

=head1 AUTHORS

Jason Michelizzi, E<lt>jmichelizzi at users.sourceforge.netE<gt>

Varada Kolhatkar, E<lt>kolha002 at d.umn.eduE<gt>

Ted Pedersen, E<lt>tpederse at d.umn.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008 by Jason Michelizzi and Ted Pedersen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
