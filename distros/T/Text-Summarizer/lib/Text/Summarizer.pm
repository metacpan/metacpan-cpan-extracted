package Text::Summarizer;

use v5.14;
use strict;
use warnings;
use Moo;
use Types::Standard qw/ Bool Ref Str Int Num InstanceOf Bool /;
use List::AllUtils qw/ max min sum sum0 singleton pairkeys pairvalues pairs all /;
use Algorithm::CurveFit;
use Lingua::Stem qw/ stem /;
use Text::Typifier qw/ typify /;
use utf8;

binmode STDOUT, ':utf8';

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();
%EXPORT_TAGS = (all => [@EXPORT_OK]);
$VERSION = '2.01';


has permanent_path => (
  is  => 'rw',
  isa => Str,
  default => 'data/permanent.stop',
);

has stopwords_path => (
  is  => 'rw',
  isa => Str,
  default => 'data/stopwords.stop',
);

has articles_path => (
  is => 'rw',
  isa => Str,
  default => 'articles/*'
);

has store_scanner => (
  is => 'rw',
  isa => Bool,
  default => 0,
);

has print_scanner => (
  is => 'rw',
  isa => Bool,
  default => 0,
);

has print_summary => (
  is => 'rw',
  isa => Bool,
  default => 0,
);

has print_graphs => (
  is => 'rw',
  isa => Bool,
  default => 0,
);

has print_working => (
  is => 'rw',
  isa => Bool,
  default => 0,
);

has print_typifier => (
  is => 'rw',
  isa => Bool,
  default => 0,
);

has return_count => (
  is => 'rw',
  isa => Num,
  default => 20,
);

has phrase_thresh => (
  is => 'rw',
  isa => Int,
  default => 2,
);

has phrase_radius => (
  is => 'rw',
  isa => Int,
  default => 5,
);

has freq_constant => (
  is => 'rw',
  isa => Num,
  default => 0.004,
);

has watch_count => (
  is => 'rwp',
  isa => Int,
  default => 0,
);

has stopwords => (
  is => 'lazy',
  isa => Ref['HASH'],
);

has watchlist => (
  is => 'rwp',
  isa => Ref['HASH'],
  lazy => 1,
);

has article_length => (
  is => 'rwp',
  isa => Int,
  default => 0,
  lazy => 1,
);

has full_text => (
  is => 'rwp',
  isa => Str,
);

has types_list => (
  is => 'rwp',
  isa => Ref['ARRAY'],
);

has types_factor => (
  is => 'rwp',
  isa => Ref['HASH'],
  default => sub {{  '10_flat_clause' => 1,
                     '011_comma_clause' => 1,
                     '020_semicolon_list' => 1,
                     '031_sentence_list' => 1,
                     '032_bracket_clause' => 1,
                     '033_quote_clause' => 1,
                     '070_dialog' => 1,
                     '080_dateline' => 1,
                     '081_title' => 1,
                     '082_name' => 1,
                     '090_bold' => 1,
                     '091_italic' => 1,
                     '092_under' => 1,
                     '093_strong' => 1,
                     '094_title' => 1,
                     '095_table' => 1,
                     '096_ulist' => 1,
                     '097_olist' => 1,
                     '098_dlist' => 1,
                     '099_faq_div' => 1,
                     '100_h1' => 1,
                     '101_h2' => 1,
                     '102_h3' => 1,
                     '103_h4' => 1,
                     '104_h5' => 1,
                     '105_h6' => 1,
                     '200_sentence' => 1,
                     '210_paragraph' => 1,
                     '220_block_list' => 1,
                }},
);

has type_scores => (
  is => 'rwp',
  isa => Ref['HASH'],
);

has paragraphs => (
  is => 'rwp',
  isa => Ref['ARRAY'],
);

has sentences => (
  is => 'rwp',
  isa => Ref['ARRAY'],
);

has sen_words => (
  is => 'rwp',
  isa => Ref['ARRAY'],
);

has word_list => (
  is => 'rwp',
  isa => Ref['ARRAY'],
);

has freq_hash => (
  is => 'rwp',
  isa => Ref['HASH'],
);

has clst_hash => (
  is => 'rwp',
  isa => Ref['HASH'],
);

has phrs_hash => (
  is => 'rwp',
  isa => Ref['HASH'],
);

has sigma_hash => (
  is => 'rwp',
  isa => Ref['HASH'],
);

has inter_hash => (
  is => 'rwp',
  isa => Ref['HASH'],
);

has score_hash => (
  is => 'rwp',
  isa => Ref['HASH'],
);

has phrs_list => (
  is => 'rwp',
  isa => Ref['HASH'],
);

has frag_list => (
  is => 'rwp',
  isa => Ref['ARRAY'],
);

has summary => (
  is => 'rwp',
  isa => Ref['HASH'],
);

has file_name => (
  is => 'rwp',
  isa => Str,
);

has text_hint => (
  is => 'rwp',
  isa => Str,
);



sub _build_watchlist {
    my $self = shift;
    my %watchlist;
    open( my $stopwords_file, '<', $self->stopwords_path )
        or die "Can't open stopwords scanner file" . $self->stopwords_path . ": $!";
    chomp and $watchlist{ $_ } = 1 for (<$stopwords_file>);
    close $stopwords_file;

    return \%watchlist;
}

sub _build_stopwords {
    my $self = shift;
    my %stopwords;

    open( my $permanent_file, '<', $self->permanent_path )
        or die "Can't open stopwords permanent file " . $self->permanent_path . ": $!";
    chomp and $stopwords{ $_ } = 1 for (<$permanent_file>);
    close $permanent_file;
    
    open( my $stopwords_file, '<', $self->stopwords_path )
        or die "Can't open stopwords scanner file" . $self->stopwords_path . ": $!";
    chomp and $stopwords{ $_ } = 1 for (<$stopwords_file>);
    close $stopwords_file;

    return \%stopwords;
}

sub _store_stopwords {
    my $self = shift;
    open( my $stopwords_file, ">", $self->stopwords_path)
        or die "Can't open stopwords scanner file " . $self->stopwords_path . ": $!";
    grep { print $stopwords_file "$_\n" } sort keys %{$self->watchlist} if $self->store_scanner;
    close $stopwords_file;

    return $self;
}



sub scan_text {
    my ($self, $text, $path) = @_;

    $self->_set_file_name( '' );
    $self->_set_text_hint( '' );

    if ( ref $text ) {
        $self->_set_file_name( $path );
        $text = join "\n" => map { $_ } <$text>;
    }

    $self->_set_text_hint( '"' . substr($text,0,50) . '...' . substr($text,-30) . '"' );
    $self->tokenize( $text ); #breaks the provided file into sentences and individual words
    $self->_build_stopwords;

    $self->_build_freq_hash;
    $self->_build_clst_hash;
    $self->_build_phrs_hash;
    $self->_build_sigma_hash;
    $self->_build_frag_list;
 
    $self->develop_stopwords; #analyzes the frequency and clustering of words within the provided file
    $self->_store_stopwords;

    return $self->watchlist;
}

sub scan_file {
    my ($self, $file_path) = @_;
    open( my $file, '<:utf8', $file_path )
       or die "Can't open file $file_path for scanning: $!";

    return $self->scan_text( $file, $file_path );
}

sub scan_each {
    my ($self, $dir_path) = @_;

    return map { $self->scan_file( $_ ) } glob( $dir_path // $self->articles_path );
}



sub summarize_text {
    my ($self, $text, $path) = @_;

    $self->_set_file_name( '' );
    if ( ref $text ) {
        $self->_set_file_name( $path );
        $text = join "\n" => map { $_ } <$text>;
    }

    $self->_set_text_hint( '"' . substr($text,0,50) . '...' . substr($text,-30) . '"' );
    $self->tokenize($text); #breaks the provided file into sentences and individual words 
    $self->_build_stopwords;

    $self->_build_freq_hash;
    $self->_build_clst_hash;
    $self->_build_phrs_hash;
    $self->_build_sigma_hash;
    $self->_build_frag_list;

    $self->analyze_phrases; #analyzes the frequency and clustering of words within the provided file  return $self->summary;
}

sub summarize_file {
    my ($self, $file_path) = @_;
    open( my $file, '<:utf8', $file_path )
        or die "Can't open file $file_path for summarizing: $!";

    return $self->summarize_text( $file, $file_path );
}

sub summarize_each {
    my ($self, $dir_path) = @_;

    return map { $self->summarize_file( $_ ) } glob( $dir_path // $self->articles_path );
}

sub summ_text { return shift->summarize_text(@_); }
sub summ_file { return shift->summarize_file(@_); }
sub summ_each { return shift->summarize_each(@_); }



sub tokenize {
    my ( $self, $text ) = @_;

    my @types_list = typify($text);
    my @paragraphs = pairkeys @types_list;
    my %type_scores;
 
    foreach my $category ( pairvalues @types_list ) {
       foreach ( pairs @$category ) {
            my ( $type, $scraps ) = @$_;
            $type_scores{lc $_} += ($self->types_factor->{$type} // 1) for
                map { grep { !$self->stopwords->{lc $_} and /[A-Za-z]/ } /\b[\w-]+\b/gx } (ref $scraps eq 'ARRAY' ? @$scraps : $$scraps );
        }
    }

    $text = join "\n" => pairkeys @types_list;
    my $sentence_match = qr/(?|   (?<=(?<!\s[A-Z][a-z]) (?<!\s[A-Z][a-z]{2}) \. (?![A-Z0-9]\.|\s[a-z0-9]) | \! | \?) (?:(?=[A-Z])|\s+)
                              |   (?: \n+ | ^\s+ | \s+$ )
                            )/mx;

    my @sentences = split /$sentence_match/ => $text; # array of sentences
    my @word_list; # array literal of all the words in the entire text body
    my @sen_words; # array reference to all of the tokens in each sentence
    for (@sentences) {  #creates an array of each word in the current article
        my @words = grep { /[A-Za-z]/ } map { /\b (?: \w \. (?: ['’-] \w+ )?)+ | (?: \w+ ['’-]? )+ (?=\s|\b)/gx } lc $_;
            #tokenizes each sentence into complete words (single-quotes are considered part of the word they attach to)
        push @word_list =>  @words;
        push @sen_words => \@words;
    }

    $self->_set_article_length( scalar @word_list ); #counts the total number of words in the article
    $self->_set_full_text( $text  );
    $self->_set_sentences( \@sentences );
    $self->_set_word_list( \@word_list );
    $self->_set_sen_words( \@sen_words );
    $self->_set_paragraphs( \@paragraphs );
    $self->_set_types_list( \@types_list );
    $self->_set_type_scores( \%type_scores);

    return $self;
}



sub _build_freq_hash {
    my $self = shift;

    my $min_freq_thresh = int($self->article_length * $self->freq_constant) // 1; #estimates a minimum threshold of occurence for frequently occuring words
    my %freq_hash; #counts the number of times each word appears in the *%word_list* hash

    for my $word (@{$self->word_list}) {
        $freq_hash{$word}++ unless $self->stopwords->{$word} or $word !~ /[A-Za-z]/;
    }

    grep { delete $freq_hash{$_} if $freq_hash{$_} < $min_freq_thresh } keys %freq_hash; #remove words that appear less than the *$min_freq_thresh*
    
    $self->_set_freq_hash( \%freq_hash );

    return $self;
}



sub _build_clst_hash {
    my $self = shift;
    my (%cluster_hash, %cluster_count);

    my $abs_pos = 0;
    for my $sen_index (0..$#{$self->sentences}) { #gives the index of each sentence in the article
        my @sen_words = @{$self->sen_words->[$sen_index]}; # creates an array of each word in the given sentence

        for my $position (0..$#sen_words) { #iterates across each word in the sentence
            $abs_pos++;

            if ( exists $self->freq_hash->{$sen_words[$position]}) { # true if the given word at index *position* appears in the *freq_hash*
                my %word = ( abs => $abs_pos, sen => $sen_index, rel => $position, cnt => $cluster_count{$sen_words[$position]}++ );
                    # hash-vector of the following elements:
                    #  abs => absolute position of the currrent word within the entire token-stream
                    #  sen => the index of the current sentence
                    #  rel => position of the current word within the current sentence
                    #  cnt => number of times the given word has appeared in the entire text file 
                push @{$cluster_hash{$sen_words[$position]}} => \%word;
            }
        }
    }

    $self->_set_clst_hash( \%cluster_hash );

    return $self;
}



sub _build_phrs_hash {
    my $self = shift;

    #create long-form phrases around frequently used words by tracking forward and backward *phrase_radius* from any given *c_word*
    my %phrase_hash;
    for my $c_word (keys %{$self->clst_hash}) {
        for my $c_vector (@{$self->clst_hash->{$c_word}}) {
            my ($sen, $pos, $cnt) = @$c_vector{'sen', 'rel', 'cnt'};
                # *sen* indicates which sentence the current *c_word* appears in
                # *pos* indicates the position of the *c_word* within the sentence (see above)
                # *cnt* counts the total number of times the word has been detected thus far

            my @phrase = [ @{$self->sen_words->[$sen]}[ max($pos - $self->phrase_radius, 0) .. min($pos + $self->phrase_radius, scalar(@{$self->sen_words->[$sen]}) - 1) ] ];
               #array slice containing only tokens within *phrase_radius* of the *c_word* within the given sentence

            unshift @phrase => \$self->sentences->[$sen]; #begins the *phrase* array with a complete, unedited sentence (for reference only)
            push @{$phrase_hash{$c_word}} => \@phrase if scalar @{$phrase[-1]} > $self->phrase_thresh + 1;
               #the *phrase_hash* can only contain a given *phrase* array if it is longer than the defined *phrase_thresh* + 1  (defaults to 3)
        }
    }
    
    $self->_set_phrs_hash( \%phrase_hash );
    
    return $self;
}



sub _build_sigma_hash {
    my $self = shift;

    #determine population standard deviation for word clustering
    my %sigma_hash;
    for my $c_word (keys %{$self->clst_hash}) {
        for my $c_vector (@{$self->clst_hash->{$c_word}}) {

            #create a list of the distances between each instance of the current *c_word*
            my %dist_list;
            my ($L_pos, $R_pos);
            for (my $i = 0; $i < scalar @{$self->clst_hash->{$c_word}}; $i++) {
                $R_pos = $self->clst_hash->{$c_word}->[$i]->{abs};
                my $dist = $R_pos - ($L_pos // $R_pos);
                push @{$dist_list{$c_word}} => $dist if $dist >= 0;
                $L_pos = $R_pos;
            }

            #the following is used for scoring purposes, and is used only to determine the *sigma* score (population standard deviation) of the given *c_word*
            my $pop_size = scalar @{$dist_list{$c_word}} or 1;
            my $pop_ave  = sum0( @{$dist_list{$c_word}} ) / $pop_size;
            $sigma_hash{$c_word} = int sqrt( sum( map { ($_ - $pop_ave)**2 } @{$dist_list{$c_word}} ) / $pop_size ); #pop. std. deviation
        }
    }

    $self->_set_sigma_hash( \%sigma_hash );

    return $self;
}



sub _build_frag_list {
    my $self = shift;
    my @frag_list;

    F_WORD: for my $f_word (keys %{$self->phrs_hash}) {   #find common phrase-fragments
        my %full_phrase; #*inter_hash* contains phrase fragments;
        my (@hash_list, %sums_hash, %words_count);
        #  *hash_list* contains ordered, formatted lists of each word in the phrase fragment;
        #  *sums_hash* contains the total number of times each word appears in all phrases for the given *f_word*

        ORDER: for my $phrase (@{$self->phrs_hash->{$f_word}}) {
            my $sentence_ref  = $phrase->[0];
            my %ordered_words = map { $sums_hash{$phrase->[-1]->[$_]}++; ($_ => $phrase->[-1]->[$_]) } (0..$#{$phrase->[-1]});
               # *words* contains an ordered, formatted list of each word in the given phrase fragment, looks like:
               #  '01' => 'some'
               #  '02' => 'word'
               #  '03' => 'goes'
               #  '04' => 'here'

            $words_count{$_}++ for values %ordered_words;
            push @hash_list => { f_word => $f_word, sentence => $sentence_ref, counts => \%words_count, ordered => \%ordered_words };
        }

        #removes each word from the *word_hash* unless it occurs more than once amongst all phrases
        SCRAP: for my $word_hash (@hash_list) {
            for my $index ( keys %{$word_hash->{'ordered'}} ) {
                delete $word_hash->{'ordered'}->{$index} unless $sums_hash{$word_hash->{'ordered'}->{$index}} > 1
            }
        }

        #break phrases fragments into "scraps" (consecutive runs of words within the fragment)
        FRAG: for my $word_hash (@hash_list) {
            my (%L_scrap, %R_scrap); #a "scrap" is a sub-fragment
            my ($prev, $curr, $next) = (-1,0,0); #used to find consecutive sequences of words

            my $real = 0; #flag for stopwords identification

            my @word_keys = sort { $a <=> $b } keys %{$word_hash->{'ordered'}}; # *word_keys* contains a series of index-values
            for (my $i = 0; $i < scalar @word_keys; $i++ ) {
                $curr = $word_keys[$i];
                $next = $word_keys[$i+1] if $i < $#word_keys; # if-statement prevents out-of-bounds error

                if ( $next == $curr + 1 or $curr == $prev + 1 ) {
                    unless ($curr == $prev + 1) {  #resets *R_scrap* when the *curr* index skips over a number (i.e. a new scrap is encountered)
                        %L_scrap = %R_scrap if keys %L_scrap <= keys %R_scrap; #chooses the longest or most recent scrap
                        %R_scrap = (); #resets the *R_scrap*
                    }

                    $R_scrap{$curr} = $word_hash->{'ordered'}->{$curr};
                    $real = 1 unless $self->stopwords->{$R_scrap{$curr}}; #ensures that scraps consisting only of stopwords are ignored
                } else {
                    %L_scrap = %R_scrap if keys %L_scrap <= keys %R_scrap; #chooses the longest or most recent scrap
                    %R_scrap = (); #resets the *R_scrap*
                }

                $prev = $curr;
            }

            %L_scrap = %R_scrap if keys %L_scrap <= keys %R_scrap; #chooses the longest or most recent scrap
            %R_scrap = (); #resets the *R_scrap*

            push @frag_list => { %{$word_hash}, scrap => \%L_scrap } if $real and scalar keys %L_scrap >= $self->phrase_thresh;
        }
    }

    $self->_set_frag_list( \@frag_list );
    return $self;
}



sub develop_stopwords {
    my $self = shift;

    my %score_hash; #*score_hash* contains score values for words in those phrases
    $score_hash{$_}++ for keys %{$self->phrs_hash};
    JOIN: for my $fragment (@{$self->frag_list}) {

        #compile scraps for scoring
        my $scrap  = join ' ' => map { $score_hash{$fragment->{'scrap'}->{$_}}++;
        $fragment->{'scrap'}->{$_} } sort { $a <=> $b } keys %{$fragment->{'scrap'}};

        for my $word (split ' ' => $scrap) {
            $score_hash{$word} += $self->freq_hash->{$word} // 0;
            $score_hash{$word} += $self->sigma_hash->{$word} // 0;
            $score_hash{$word} -= $fragment->{'counts'}->{$word} // 0;
        }
    } 
    grep { delete $score_hash{$_} if $self->stopwords->{$_} } keys %score_hash;


    my @word_keys = sort { $score_hash{$b} <=> $score_hash{$a} or $a cmp $b } keys %score_hash;
    my $highest = $score_hash{$word_keys[0]};
    my $longest = max map { length } @word_keys;

    $score_hash{$_} = 40 * $score_hash{$_} / $highest for keys %score_hash;
    @word_keys = reverse grep { $score_hash{$_} >= 1 } @word_keys;

    my @scores = map { $score_hash{$_} } @word_keys;
    my @low    = @scores[ 0..(int scalar @scores / 2 - 1.5) ];
    my @high   = @scores[ (int scalar @scores / 2 + 1)..(int scalar @scores - 1) ];
    my @LM     = @low[  (int scalar @low / 2 - 0.5)..(int scalar @low / 2)   ];
    my @UM     = @high[ (int scalar @high / 2 - 0.5)..(int scalar @high / 2) ];
    my $Q1     = sum( @LM ) / scalar @LM;
    my $Q3     = sum( @UM ) / scalar @UM;
    my $IQR    = $Q3 - $Q1;
    my $lower  = $Q1;
    my $upper  = $Q3 + 1.5 * $IQR;

    my @graph_data = grep { $_ > $lower and $_ < $upper } map { $score_hash{$_} } @word_keys;
    my $n = scalar @graph_data;

    if ($n > 4) {
        my $average = sum( @graph_data ) / $n;
        my @xdata = 1..$n; # The data corresponsing to $variable
        my @ydata = @graph_data; # The data on the other axis
        my $max_iter = 100; # maximum iterations
        my @params_line = (
            # Name      Guess      Accuracy
            ['a',       0,         0.00001],
            ['b',       $average,  0.00001],
            ['c',       $highest,  0.00001],
        );

        Algorithm::CurveFit->curve_fit(
            formula             =>  'a + b * x + c * x^2',
            params              =>  \@params_line,
            xdata               =>  \@xdata,
            ydata               =>  \@ydata,
            maximum_iterations  =>  $max_iter,
        );

        my ($a, $b, $c) = ($params_line[0]->[1],$params_line[1]->[1],$params_line[2]->[1]);
        my %watchlist = %{$self->watchlist // {} };

        KEY: for my $index ( reverse 1..scalar @word_keys ) {
            my $score  = $a + $b * $index + $c * $index**2;
            $watchlist{$word_keys[$index - 1]}++ if $score >= $lower and $score < $score_hash{$word_keys[$index - 1]};
        }

        $self->_set_watchlist( \%watchlist );


        if ($self->print_scanner) {
            say "\nSCANNING:\n" . $self->full_text if $self->print_working;

            say "\n\n———————————————————————————————————————————\n\n";

            say "[file name] " . $self->file_name if $self->file_name;
            say "[text hint] " . $self->text_hint;

            say "\n---SCANNER GRAPHS---\n";

            say "KNOWN:";
            KEY: for my $index ( reverse 0..$#word_keys ) {
                my $format = "%" . $longest . "s|%s\n";
                my $score = $score_hash{$word_keys[$index]};
                my $score_string = sprintf " %5.2f |" => $score;
                for (0..max($score, $upper)) {
                    if ($score > $lower and $score < $upper) {
                        $score_string .= '+' if $_ <= $score;
                    } else {
                        $score_string .= ']' if $_ == int $upper;
                        $score_string .= '-' if $_ <= int $score;
                        $score_string .= ' ' if $_ >  int $score;
                        $score_string .= '[' if $_ == int $lower;
                    }
                }
                printf $format => ($word_keys[$index], $score_string);
            }

            printf "\n[whiskers] lower = %.2f; upper = %.2f\n\n" => ($lower, $upper);

            say "CALCULATED:";
            KEY: for my $index ( reverse 1..scalar @word_keys ) {
                my $format = "%" . $longest . "s|%s\n";
                my $score  = $a + $b * $index + $c * $index**2;
                my $score_string = sprintf " %5.2f |%s" => $score,
                    ($score >= $lower and $score < $score_hash{$word_keys[$index - 1]} ? '-' x $score : '+' x $score);
                printf $format => $word_keys[$index - 1], $score_string;
            }
            say "\n";
        }
    }

    return $self;
}



sub analyze_phrases {
    my $self = shift;

    #find common phrase-fragments
    my (%inter_hash, %score_hash, %bare_phrase, %full_phrase); #*inter_hash* contains phrase fragments; *score_hash* contains score values for words in those phrases
    F_WORD: for my $f_word (keys %{$self->phrs_hash}) {  #compile scraps for scoring
        JOIN: for my $fragment (@{$self->frag_list}) {
            my $scrap  = join ' ' => map { $score_hash{$_}++;

            $fragment->{'scrap'}->{$_} } sort { $a <=> $b } keys %{$fragment->{'scrap'}};

            my @bare   = map { $fragment->{'scrap'}->{$_} } grep { !$self->stopwords->{$fragment->{'scrap'}->{$_}} } sort { $a <=> $b } keys %{$fragment->{'scrap'}};

            $score_hash{$f_word}++; #scores each *f_word*
            $inter_hash{$scrap}++; #contains the final *L_scrap* 

            my $score = 1;
            for my $word (split ' ' => $scrap) {
                $score += $self->freq_hash->{$word}  // 0;
                $score += $self->sigma_hash->{$word} // 0;
                $score += $score_hash{$word} // 0;
            }

            $full_phrase{ ${$fragment->{'sentence'}} } += $score; #contains the full phrase from which the *L_scrap* was drawn
            $bare_phrase{ $scrap } = \@bare if scalar @bare; #contains the final *L_scrap* without any stopwords
        }
    }

    #each phrases' score is multiplied by the sum of the compound score of each word within the phrase
    for my $scrap (keys %inter_hash) {
        for my $word (split ' ' => $scrap) {
            my $score = 1;
            $score += $self->freq_hash->{$word}  // 0;
            $score += $self->sigma_hash->{$word} // 0;
            $score += $score_hash{$word} // 0;
            $inter_hash{$scrap} *= $score;
        }
    }

    #combine scraps — if scrap "a" contains scrap "b", add the value of "b" to "a" and delete "b"
    CLEAR: for my $scrap (sort { $inter_hash{$b} <=> $inter_hash{$a} or $a cmp $b } keys %inter_hash) {
        TEST: for my $compare (keys %inter_hash) {
            if ($compare ne $scrap) {
                my %test_hash = map { ($_ => 1) } split " " => $compare;
                if ( all { $test_hash{$_} } split " " => $scrap ) { #true iff  *scrap* ∈ *compare*
                    $inter_hash{$compare} += $inter_hash{$scrap};
                    delete $inter_hash{$scrap} and next CLEAR;

                } elsif ( not scalar singleton (@{$bare_phrase{$compare}}, @{$bare_phrase{$scrap}}) ) { #true iff *bare_phrase{compare}* == *bare_phrase{scrap}*
                    next TEST unless scalar @{$bare_phrase{$compare}} > 1;
                    my $joined = join '|' => @{$bare_phrase{$compare}};
                    $inter_hash{"($joined)"} = $inter_hash{$compare} + $inter_hash{$scrap};
                    $inter_hash{$compare} += $inter_hash{$scrap};
                    #delete $inter_hash{$scrap} and next CLEAR;
                }
            }
        }
    }

    $self->_set_score_hash(  \%score_hash );
    $self->_set_inter_hash(  \%inter_hash );
    $self->_set_phrs_list( \%full_phrase );

    #returns a summary array for the given text, in the form of a hash of array-refs:
    #   sentences => a list of full sentences from the given article, scored based on the scores of the words contained therein
    #   fragments => a list of phrase fragments from the given article, scored as above
    #   words => a list of all words in the article, scored by a three-factor system consisting of
    #       (frequency of appearance, population standard deviation, and use in important phrase fragments)


    my %sort_list;
    for (keys %{$self->freq_hash}) {
        $sort_list{$_} += $self->freq_hash->{$_}  // 0;
        $sort_list{$_} += $self->sigma_hash->{$_} // 0;
        $sort_list{$_} += $self->score_hash->{$_} // 0;
    }


    my %sentences = map { ($_ => $self->phrs_list->{$_}) } sort { $self->phrs_list->{$b} <=> $self->phrs_list->{$a} } keys %{$self->phrs_list};
    my %fragments = map { ($_ => $self->inter_hash->{$_})  } sort { $self->inter_hash->{$b} <=> $self->inter_hash->{$a} or $a cmp $b } keys %{$self->inter_hash};
    my %singleton = map { ($_ => $sort_list{$_})  } sort { $sort_list{$b} <=> $sort_list{$a} or $a cmp $b } keys %sort_list;


    my %type_sets = %{$self->type_scores};
    my @type_keys = sort { $type_sets{$b} <=> $type_sets{$a} or $a cmp $b } keys %type_sets;
    my $highest = $type_sets{$type_keys[0]};
    my %merge_set;
    for (@type_keys) {
        $merge_set{$_} = int(40*$type_sets{$_}/$highest);
    }

    my @word_keys = sort { $singleton{$b} <=> $singleton{$a} or $a cmp $b } keys %singleton;
    $highest = $singleton{$word_keys[0]};

    for (@word_keys) {
        $merge_set{$_} = ($merge_set{$_} // 0) + int(40*$singleton{$_}/$highest);
    }

    my @merge_keys   = keys %merge_set;
    my $stemmed_keys = stem @merge_keys;
    my %stem_list;

    for (my $i = 0; $i < @$stemmed_keys; $i++) {
        $stem_list{$stemmed_keys->[$i]} += $merge_set{$merge_keys[$i]};
    }
    
    my %summary = (
        sentences => \%sentences,
        fragments => \%fragments,
        words     => \%singleton,
        typed     => \%type_sets,
        merged    => \%merge_set,
        stemmed   => \%stem_list
    );
 
    $self->_set_summary( \%summary );
    $self->show_summary();

    return $self;
}



sub show_summary {
    my $self = shift;


    if ($self->print_working) {
        say "\nSUMMARIZING:\n" . $self->full_text;
    }


    if ($self->print_typifier) {
        say "\n\n———————————————————————————————————————————\n\n";

        say "[file name] " . $self->file_name if $self->file_name;
        say "[text hint] " . $self->text_hint;

        say "\n---TEXT TYPE LIST---\n";

        foreach ( pairs @{$self->types_list} ) {
            my ( $paragraph, $category ) = @$_;

            say "PARAGRAPH:\n$paragraph\n";

            say "BREAKDOWN:";
            foreach ( pairs @$category ) {
                my ( $type, $scraps ) = @$_;
                if (ref $scraps eq 'ARRAY') {
                    my $format = "%s\n" . ("\t• %s\n"x@$scraps) . "\n";
                    printf $format => ($type, @$scraps);
                }
            }
            say "\n";
        }
    } 


    if ($self->print_summary) {
        say "\n\n———————————————————————————————————————————\n\n";

        say "[file name] " . $self->file_name if $self->file_name;
        say "[text hint] " . $self->text_hint;

        say "\n---SUMMARY CHARTS---\n";

        my ($sentences, $fragments) = @{$self->summary}{'sentences','fragments'};

        SUMMARY: {
            say "SUMMARY:";
            my @sentence_keys = sort { $sentences->{$b} <=> $sentences->{$a} or $a cmp $b} keys %$sentences;
            my $highest = $sentences->{$sentence_keys[0]};
            for my $sen ( @sentence_keys[0..min($self->return_count,$#sentence_keys)] ) {
                my $score = 100*log($sentences->{$sen})/log($highest);
                printf "%d => %s\n" => $score, $sen;
            }
            say "\n";
        }

        PHRASES: {
            say "PHRASES:";
            my @phrase_keys = sort { $fragments->{$b} <=> $fragments->{$a} or $a cmp $b } keys %$fragments;
            my $highest = $fragments->{$phrase_keys[0]};
            for my $phrase ( @phrase_keys[0..min($self->return_count,$#phrase_keys)] ) {
                my $score = 100*log($fragments->{$phrase})/log($highest);
                printf "%d => %s\n" => $score, $phrase;
            }
            say "\n";
        }
    }

    if ($self->print_graphs) {
        say "\n\n———————————————————————————————————————————\n\n";

        say "[file name] " . $self->file_name if $self->file_name;
        say "[text hint] " . $self->text_hint;

        say "\n---SUMMARY GRAPHS---\n";

        my ($words, $typed, $merged, $stemmed) = @{$self->summary}{'words','typed','merged','stemmed'};

        WORDS: {
            say "  WORDS:";
            my @word_keys = sort { $words->{$b} <=> $words->{$a} or $a cmp $b } keys %$words;
            my $highest = $words->{$word_keys[0]};
            my $longest = max map {length} @word_keys;

            KEY: for my $word ( @word_keys[0..min($self->return_count,$#word_keys)] ) {
                my $format = "%" . $longest . "s| %2s |%s\n";
                my $score = int(40*$words->{$word}/$highest);
                printf $format => ( $word, $score, "-" x $score ) if $score > 2;
            }
            say "\n";
        }

        TYPES: {
            say "  TYPES:";
            my @type_keys = sort { $typed->{$b} <=> $typed->{$a} or $a cmp $b } keys %$typed;
            my $highest = $typed->{$type_keys[0]};
            my $longest = max map {length} @type_keys;

            KEY: for my $word ( @type_keys[0..min($self->return_count,$#type_keys)] ) {
                my $format = "%" . $longest . "s| %2s |%s\n";
                my $score = int(40*$typed->{$word}/$highest);
                printf $format => ( $word, $score, "-" x $score ) if $score > 2;
            }
            say "\n";
        }

        MERGED: {
            say "  MERGED:";
            my @merge_keys = sort { $merged->{$b} <=> $merged->{$a} or $a cmp $b } keys %$merged;
            my $highest = $merged->{$merge_keys[0]};
            my $longest = max map {length} @merge_keys;

            KEY: for my $word ( @merge_keys[0..min($self->return_count,$#merge_keys)] ) {
                my $format = "%" . $longest . "s| %2s |%s\n";
                my $score = int(40*$merged->{$word}/$highest);
                printf $format => ( $word, $score, "-" x $score ) if $score > 2;
            }
            say "\n";
        }

        STEMMED: {
            say "  STEMMED:";
            my @stem_keys = sort { $stemmed->{$b} <=> $stemmed->{$a} or $a cmp $b } keys %$stemmed;
            my $highest = $stemmed->{$stem_keys[0]};
            my $longest = max map {length} @stem_keys;

            KEY: for my $word ( @stem_keys[0..min($self->return_count,$#stem_keys)] ) {
                my $format = "%" . $longest . "s| %2s |%s\n";
                my $score = int(40*$stemmed->{$word}/$highest);
                printf $format => ( $word, $score, "-" x $score ) if $score > 2;
            }
            say "\n";
        }
    }
}



1;

__END__  


=pod
 
=encoding utf-8  

=head1 NAME

Text::Summarizer - Summarize Bodies of Text  

=head1 SYNOPSIS

  use Text::Summarizer;

    # all constructor arguments shown are OPTIONAL and reflect the DEFAULT VALUES of each attribute
  $summarizer = Text::Summarizer->new(
                    articles_path  => 'subdirectory/to/summarize/*',
                    permanent_path => 'data/permanent.stop',
                    stopwords_path => 'data/stopwrods.stop',
                    store_working  => 0,
                    print_scanner  => 0,
                    print_summary  => 0,
                    print_graphs   => 0,
                    print_typifier => 0,
                    return_count   => 20,
                    phrase_thresh  => 2,
                    phrase_radius  => 5,
                    freq_constant  => 0.004,
                );


  $summarizer = Text::Summarizer->new();

    # to summarize a string
  $stopwords = $summarizer->scan_text( 'this is a sample text' );
  $summary   = $summarizer->summ_text( 'this is a sample text' );

    # or to summarize an entire file
  $stopwords = $summarizer->scan_file("some/file.txt");
  $summary   = $summarizer->summ_file("some/file.txt");

    # or to summarize in bulk
    #   (if no argument provided, uses the 'articles_path' attribute)
  @stopwords = $summarizer->scan_each("/directory/glob/*");
  @summaries = $summarizer->summ_each("/directory/glob/*");

=head1 DESCRIPTION

This module allows you to summarize bodies of text into a scored hash of  I<sentences>,  I<phrase-fragments>, and  I<individual words> from the provided text.

These scores reflect the weight (or precedence) of the relative text-fragments, i.e. how well they summarize or reflect the overall nature of the text.

All of the sentences and phrase-fragments are drawn from within the existing text, and are NOT proceedurally generated.  

=head1 ATTRIBUTES

X< read-write accessible >

B< The following constructor attributes are available to the user, and can be accessed/modified at any time via C<< $summarizer->_set_[attribute] >> >:

=over 8

=item C<articles_path>   – [directory]

folder containing some text-files you wish to summarize

=item C<permanent_path>  – [filepath]

file containing a base set of universal stopwords (defaults to English stopwords)

=item C<stopwords_path>  – [filepath]

file containing a list of new stopwords identified by the C<scan> function

=item C<store_scanner>   – [boolean]

flag for storing new stopwords in the file indicated by C<stopwords_path>

=item C<print_scanner>   – [boolean]

flag that enables visual graphing of scanner activity (prints to C<STDOUT>)

=item C<print_summary>   – [boolean]

flag that enables visual charting of summary activity (prints to C<STDOUT>)

=item C<return_count>  – [int]

number of items to list when printing summary list

=item C<phrase_thresh>   – [int]

minimum number of word tokens allowed in a phrase

=item C<phrase_radius>   – [int]

distance iterated backward and forward from a given word when establishing a phrase (i.e. maximum length of phrase divided by 2)

=item C<freq_constant>   – [float]

mathematical constant for establishing minimum threshold of occurence for frequently occuring words (defaults to C<< 0.004 >>)

=back

X< read only >

B< These attributes are read-only, and can be accessed via C<< $summarizer->[attribute] >> >:

=over 8

=item C<full_text> – [string]

all the lines of the provided text, joined together

=item C<sentences> – [array-ref]

list of each sentence found in the provided text

=item C<sen_words> – [array-ref]

for each sentence, contains an array of each word in order

=item C<word_list> – [array-ref]

each individual word of the entire text, in order (token stream)

=item C<freq_hash> – [hash-ref]

all words that occur more than a specified threshold, paired with their frequency of occurence

=item C<clst_hash> – [hash-ref]

for each word in the text, specifies the position of each occurence of the word, both relative to the sentence it occurs in and absolute within the text

=item C<phrs_hash> – [hash-ref]

for each word in the text, contains a phrase of radius I<r> centered around the given word, and references the sentence from which the phrase was gathered

=item C<sigma_hash> – [hash-ref]

gives the population standard deviation of the clustering of each word in the text

=item C<inter_hash> – [hash-ref]

list of each chosen phrase-fragment-scrap, paired with its score

=item C<score_hash> – [hash-ref]

list of each word in the text, paired with its score

=item C<phrs_list>  – [hash-ref]

list of complete sentences that each scrap was drawn from, paired with its score

=item C<frag_list>  – [array-ref]

for each chosen scrap, contains a hash of: the pivot word of the scrap; the sentence containing the scrap; the number of occurences of each word in the sentence; an ordered list of the words in the phrase from which the scrap was derived

=item C<file_name> – [string]

the filename of the current text-source (if text was extracted from a file)

=item C<text_hint> – [string]

brief snippet of text containing the first 50 and the final 30 characters of the current text

=item C<summary> – [hash-ref]

scored lists of each summary sentence, each chosen scrap, and each frequently-occuring word

=item C<stopwords> - [hash-ref]

list of all stopwords, both permanent and proceedural

=item C<watchlist> - [hash-ref]

list of proceedurally generated stopwords, derived by the `scan` function

=back  

=head1 FUNCTIONS


=head2 C<scan>

Scan is a utility that allows the Text::Summarizer to parse through a body of text to find words that occur with unusually high frequency. These words are then stored as new stopwords via the provided C<< stopwords_path >>. Additionally, calling any of the three C<< scan_[...] >> subroutines will return a reference (or array of references) to an unordered list containing the new stopwords.  $stopwords = $summarizer->scan_text( 'this is a sample text' );
  $stopwords = $summarizer->scan_file( 'some/file/path.txt' );
  @stopwords = $summarizer->scan_each( 'some/directory/*' );
# if no argument provided, uses the 'articles_path' attribute


=head2 C<summarize>

Summarizing is, not surprisingly, the heart of the Text::Summarizer. Summarizing a body of text provides three distinct categories of information drawn from the existing text and ordered by relevance to the summary: I<full sentences>, I<phrase-fragments / context-free token streams>, and a list of I<frequently occuring words>.

There are three provided functions for summarizing text documents.  $summary   = $summarizer->summarize_text( 'this is a sample text' );
  $summary   = $summarizer->summarize_file( 'some/file/path.txt' );
  @summaries = $summarizer->summarize_each( 'some/directory/*' );
# if no argument provided, defaults to the 'articles_path' attribute   # or their short forms
  $summary   = $summarizer->summ_text('...');
  $summary   = $summarizer->summ_file('...');
  @sumamries = $summarizer->summ_each('...');
# if no argument provided, defaults to the 'articles_path' attribute

C<< summarize_text >> and C<< summarize_file >> each return a summary hash-ref containing three array-refs, while C<< summarize_each >> returns a list of these hash-refs. These summary hashes take the following form:

=over 8

=item *

C<sentences> => a list of full sentences from the given text, with composite scores of the words contained therein

=item *

C<fragments> => a list of phrase fragments from the given text, scored similarly to sentences

=item *

C<words>   => a list of all words in the text, scored by a three-factor system consisting of  I<frequency of appearance>,  I<population standard deviation>, and  I<use in important phrase fragments>.

=back  

=head3 (note about fragments)

Phrase fragments are in actuality short "scraps" of text (usually only two or three words) that are derived from the text via the following process:

=over 8

=item 1

the entirety of the text is tokenized and scored into a C<< frequency >> table, with a high-pass threshold of frequencies above C<< # of tokens * user-defined scaling factor >>

=item 2

each sentence is tokenized and stored in an array

=item 3

for each word within the C<< frequency >> table, a table of phrase-fragments is derived by finding each occurance of said word and tracking forward and backward by a user-defined "radius" of tokens (defaults to S<C<< radius = 5 >>>, does not include the central key-word) — each phrase-fragment is thus compiled of (by default) an 11-token string

=item 4

all fragments for a given key-word are then compared to each other, and each word is deleted if it appears only once amongst all of the fragments (leaving only C<< I<A> ∪ I<B> ∪ ... ∪ I<S> >> where I<A>, I<B>, ..., I<S> are the phrase-fragments)

=item 5

what remains of each fragment is a list of "scraps" — strings of consecutive tokens — from which the longest scrap is chosen as a representation of the given phrase-fragment

=item 6

when a shorter fragment-scrap (C<I<A>>) is included in the text of a longer scrap (C<I<B>>) such that C<< I<A> ⊂ I<B> >>, the shorter is deleted and its score is added to that of the longer

=item 7

when multiple fragments are equivalent (i.e. they consist of the same list of tokens when stopwords are excluded), they are condensed into a single scrap in the form of C<< "(some|word|tokens)" >> such that the fragment now represents the tokens of the scrap (excluding stopwords) regardless of order (refered to as a "context-free token stream")

=back  

=head1 SUPPORT

Bugs should always be submitted via the project hosting bug tracker

L<https://github.com/faelin/text-summarizer/issues>

For other issues, contact the maintainer.  

=head1 AUTHOR

Faelin Landy <faelin.landy@gmail.com> (current maintainer)  

=head1 CONTRIBUTORS

* Michael McClennen <michaelm@umich.edu>  

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 by the AUTHOR as listed above

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

=cut