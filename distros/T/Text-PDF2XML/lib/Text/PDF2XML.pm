#-*-perl-*-

=encoding utf-8

=head1 NAME

pdf2xml - extract text from PDF files and wraps it in XML

=head1 SYNOPSIS

 pdf2xml [OPTIONS] pdf-file > output.xml

For more information, see the man-pages of the command-line tool C<pdf2xml>.
Using pdf2xml as a library is possible via the pdf2xml function:

 use Text::PDF2XML

 my $xml = pdf2xml( $pdf_file, %options );

 pdf2xml( $pdf_file, output => \*STDOUT, %options );
 pdf2xml( $pdf_file, output => 'file.xml', %options );

 %options = (
    conversion_tool         => 'pdfXtk',        # use pdfXtk (default = 'tika')
    keep_vocabulary         => 1,               # don't reset the vocabulary
    vocabulary              => 'filename',      # plain text file
    vocabulary_from_pdf     => 0,               # skip pdftotext
    vocabulary_from_raw_pdf => 0,               # skip pdftotext -raw
    vocabulary_from_tika    => 1,               # read voc from Apache Tika
    java                    => '/path/to/java', # java binary
    java_heap               => '8g',            # default = 1g
    split_into_characters   => 1,               # split into characters
    detect_languages        => 1,               # enable language detection
    keep_languages          => 'en',            # only keep English sentences
    lowercase               => 0,               # switch off lower-casing
    dehyphenate             => 0,               # switch off de-hyphenation
    character_merging       => 0,               # skip char merging
    paragraph_merging       => 0,               # skip paragraph merging
    verbose                 => 1                # verbose output
    );

 pdf2xml( $pdf_file, output => 'file.xml', %options );

Note that the options stay for the next pdf2xml call! You need to overwrite them if you want to change the behaviour in subsquent calls while the libraray is loaded!


=head1 DESCRIPTION

Extract text from PDF using external tools and some post-processing heuristics.
Here is an example with and without post-processing:

  raw:    <p>PRESENTATION ET R A P P E L DES PRINCIPAUX RESULTATS 9</p>
  clean:  <p>PRESENTATION ET RAPPEL DES PRINCIPAUX RESULTATS 9</p>

  raw:    <p>2. Les c r i t è r e s de choix : la c o n s o m m a t i o n 
             de c o m b u s - t ib les et l e u r moda l i t é 
             d ' u t i l i s a t i on d 'une p a r t , 
             la concen t r a t ion d ' a u t r e p a r t 16</p>

  clean:  <p>2. Les critères de choix : la consommation 
             de combustibles et leur modalité 
             d'utilisation d'une part, 
             la concentration d'autre part 16</p>

=head1 TODO

Character merging heuristics are very simple. Using the longest string forming a valid word from the vocabulary may lead to many incorrect words in context for some languages. Also, the implementation of the merging procedure is probably not the most efficient one.

De-hyphenation heuristics could also be improved. The problem is to keep it as language-independent as possible.

=head1 SEE ALSO

Apache Tika: L<http://tika.apache.org>

The Poppler Developers - L<http://poppler.freedesktop.org>

pdfXtk L<http://sourceforge.net/projects/pdfxtk/>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

package Text::PDF2XML;

use strict;

use Encode::Locale;
use Encode qw/decode_utf8/;
use File::Temp qw /tempfile/;
use FindBin qw/$Bin/;
use IO::File;
use IPC::Open3;
use LWP::UserAgent;
use XML::Parser;
use XML::Writer;


use Exporter 'import';
our @EXPORT = qw(pdf2xml);
our %EXPORT_TAGS = ( all => \@EXPORT );

eval{ 
    require Lingua::Identify::Blacklists;
};

my $SHARED_HOME = undef;
eval{ 
    require File::ShareDir;
    $SHARED_HOME = File::ShareDir::dist_dir('Text-PDF2XML'); 
};

## work-arcound for testing if not yet installed ...
unless (-e $SHARED_HOME.'/lib/tika-app-1.18.jar'){
    $SHARED_HOME = $Bin.'/share';
    unless (-e $SHARED_HOME.'/lib/tika-app-1.18.jar'){
	$SHARED_HOME = $Bin.'/../share';
    }
}


# global parameters

our $TIKA_URL        = 'http://localhost:9998';
our $USE_TIKA_SERVER = 1;
our $CONVERTER       = 'tika';

our $JAVA            = 'java';
our $JAVA_HEAP_SIZE  = '1g';
our $TIKAJAR         = $SHARED_HOME.'/lib/tika-app-1.18.jar';
our $PDF2TEXT        = `which pdftotext`;chomp($PDF2TEXT);

our $LOWERCASE       = 1;
our $SPLIT_CHAR      = 0;
our $CHAR_MERGING    = 1;
our $PAR_MERGING     = 1;
our $DEHYPHENATE     = 1;
our $DETECT_LANG     = 0;
our $KEEP_LANG       = undef;

our $KEEP_VOCABULARY = 0;
our $VOCAB_FROM_PDF  = 0;
our $VOCAB_FROM_RAW  = 1;
our $VOCAB_FROM_TIKA = 0;

our $VERBOSE         = 0;



## check availability of the Apache Tika Server
my $_UserAgent;
if ($USE_TIKA_SERVER){
    $_UserAgent    = LWP::UserAgent->new();
    my $_request   = HTTP::Request->new('HEAD' => $TIKA_URL);
    my $_response  = $_UserAgent->request($_request);
    if ($_response->is_error) {
	# print "Apache Tika Server is not available!\n";
	$USE_TIKA_SERVER = 0;
    }
}


## a special variable for pdfXtk:
#
# SPLIT_CHAR_IF_NECESSARY = split strings into character sequences
#                           (if they do not contain any single whitespace)

our $SPLIT_CHAR_IF_NECESSARY = 0;


## voacabulary and unigram LM
# LONGEST_WORD = length of the longest word in the vocabulary

our %voc          = ();
our %lm           = ();
our $LONGEST_WORD = undef;


# we require recent versions of pdftotext developed by 
# The Poppler Developers - http://poppler.freedesktop.org
if (-e $PDF2TEXT){
    my $developer = `$PDF2TEXT --help 2>&1 | grep -i 'poppler'`;
    $PDF2TEXT    = undef unless ($developer=~/poppler/i);
}

my %LIGATURES = (
    "\x{0132}" => 'IJ',
    "\x{0133}" => 'ij',
    "\x{FB00}" => 'ff',
    "\x{FB01}" => 'fi',
    "\x{FB02}" => 'fl',
    "\x{FB03}" => 'ffi',
    "\x{FB04}" => 'ffl',
    "\x{FB06}" => 'st');

my $LIGATURES_MATCH = join('|',sort {length($b) <=> length($a)} 
			   keys %LIGATURES);

# XML writer handle
my $XMLWRITER = undef;

#-------------------------------------------------------
# use Apache Tika or pdfxtk to produce XHTML output
# and find character sequences that need to be merged
# to form known words (split character sequences, hyphenated words)
#-------------------------------------------------------

sub pdf2xml{
    my $pdf_file = shift;
    my %options = @_;

    die "no input file '$pdf_file' found" unless (-e $pdf_file);

    $CONVERTER       = $options{conversion_tool} if ($options{conversion_tool});
    $USE_TIKA_SERVER = $options{use_tika_server} if (defined $options{use_tika_server});
    $TIKA_URL        = $options{tika_url} if ($options{tika_url});

    $KEEP_VOCABULARY = $options{keep_vocabulary} if ($options{keep_vocabulary});
    $VOCAB_FROM_PDF  = $options{vocabulary_from_pdf} if (defined $options{vocabulary_from_pdf});
    $VOCAB_FROM_RAW  = $options{vocabulary_from_raw_pdf} if (defined $options{vocabulary_from_raw_pdf});
    $VOCAB_FROM_TIKA = $options{vocabulary_from_tika} if (defined $options{vocabulary_from_tika});

    $SPLIT_CHAR      = $options{split_into_characters} if (defined $options{split_into_characters});
    $DETECT_LANG     = $options{detect_language} if (defined $options{detect_language});
    $KEEP_LANG       = $options{keep_language} if ($options{keep_language});
    $LOWERCASE       = $options{lowercase} if (defined $options{lowercase});
    $DEHYPHENATE     = $options{dehyphenate} if (defined $options{dehyphenate});
    $CHAR_MERGING    = $options{character_merging} if (defined $options{character_merging});
    $PAR_MERGING     = $options{paragraph_merging} if (defined $options{paragraph_merging});

    $JAVA            = $options{java} if ($options{java});
    $JAVA_HEAP_SIZE  = $options{java_heap} if ($options{java_heap});

    $VERBOSE         = $options{verbose} if ($options{verbose});

    ## reset vocabulary
    unless ($KEEP_VOCABULARY){
	%voc = ();
	%lm = ();
	$LONGEST_WORD = undef;
    }

    if ($options{vocabulary}){
	&read_vocabulary($options{vocabulary});
    }
    if ($VOCAB_FROM_RAW && -e $PDF2TEXT){
	&read_vocabulary( $pdf_file, 'pdftotext_raw');
    }
    if ($VOCAB_FROM_PDF){
	if (-e $PDF2TEXT){
	    &read_vocabulary( $pdf_file, 'pdftotext');
	}
    }
    if ($VOCAB_FROM_TIKA || ($VOCAB_FROM_PDF && ! -e $PDF2TEXT)){
	&read_vocabulary( $pdf_file, 'tika');
    }
    &make_lm();

    my $output = undef;
    my $result = undef;
    if (defined $options{output}){
	$output = ref($options{output}) ? 
		      $options{output} : 
		      IO::File->new($options{output}, '>:utf8');
    }
    else{
	$output = \$result;
    }

    binmode(STDOUT,":encoding(locale)");
    binmode(STDERR,":encoding(locale)");

    # binmode(STDOUT,":encoding(UTF-8)");
    # binmode(STDERR,":encoding(UTF-8)");

    $XMLWRITER = XML::Writer->new( OUTPUT => $output,
				   DATA_MODE => 1,
				   DATA_INDENT => 1 );
    $XMLWRITER->xmlDecl("UTF-8");


    my $parser = new XML::Parser( Handlers => { 
	# Default => sub{ print $_[1] },
	Char    => sub{ $_[0]->{STRING} .= $_[1] },
	Start   => \&_xml_start,
	End     => \&_xml_end } );


    # use pdfxtk or Apache Tika (default)

    if ($CONVERTER=~/pdfxtk/i){
	my $out_file = &_run_pdfxtk($pdf_file);
	open OUT,"<$out_file" || die "cannot read from pdfxtkoutput ($out_file)\n";
	binmode(OUT,":encoding(UTF-8)");
	# binmode(OUT,":encoding(locale)");
	$SPLIT_CHAR_IF_NECESSARY = 1;
	my $handler = $parser->parse_start;
	while (<OUT>){
	    $handler->parse_more($_);
	}
	close OUT;
    }
    else{
	if ($USE_TIKA_SERVER){
	    my $RawContent = _read_raw_file($pdf_file);
	    my $ParsedContent = _request( 'put', $TIKA_URL, 'tika', 
					  { 'Accept' => 'text/xml' }, 
					  $RawContent );
	    $parser->parse($ParsedContent);
	}
	else {
	    local $ENV{LC_ALL} = 'en_US.UTF-8';
	    my $pid = open3(undef, \*OUT, \*ERR, $JAVA,'-Xmx'.$JAVA_HEAP_SIZE,
			    '-jar',$TIKAJAR,'-x',$pdf_file);
	    $parser->parse(*OUT);
	    # close(OUT);
	    # waitpid( $pid, 0 );
	}
    }
    return $result;
}


# Done!
##########################





sub read_vocabulary{
    my $file = shift;

    ## get the vocabulary from pdf files
    ## using a given pdf-converter
    if ($_[0] eq 'pdftotext_raw'){
	return &_vocab_from_pdftotext_raw($file);
    }
    elsif ($_[0] eq 'pdftotext'){
	return &_vocab_from_pdftotext($file);
    }
    elsif ($_[0] eq 'tika'){
	return &_vocab_from_tika($file);
    }

    if ($file=~/\.gz$/){
	open F,"gzip -cd < $file |" || die "cannot read from $file";
	binmode(F,":encoding(UTF-8)");
    }
    else{
	open F,"<:encoding(UTF-8)",$file || die "cannot read from $file";
    }
    while (<F>){
	chomp;
	my @words = split(/\s+/);
	foreach (@words){
	    $_ = lc($_) if ($LOWERCASE);
	    $voc{$_}++;
	}
    }
}


# make a simple unigram LM

sub make_lm{
    %lm = %voc;
    my $total=0.1;
    map ($total+=$lm{$_},keys %lm);
    map ($lm{$_} = log($lm{$_}) - log($total), keys %lm);
    $lm{__unknown__} = log(0.1) - log($total);
    $LONGEST_WORD = &_longest_word();
}



# convert pdf's using pdfxtk

sub _run_pdfxtk{
    my $pdf_file = shift;
    my $out_file = shift;

    unless ($out_file){
	(my $fh, $out_file) = tempfile();
	close $fh;
	
    }
    opendir(my $dh, $SHARED_HOME.'/lib/pdfxtk') 
	|| die "can't opendir $SHARED_HOME/lib/pdfxtk: $!";
    my @jars = grep { /\.jar/ } readdir($dh);
    closedir $dh;
    my $CLASSPATH = join( ':', map { $_=$SHARED_HOME.'/lib/pdfxtk/'.$_ } @jars );

    ## need Java 1.6 openjdk
    ## ugly way of finding java-1.6, assumes that java installed in /usr/lib/jvm
    my $JAVA16 = $JAVA;
    my $version = `$JAVA16 -version`;
    if ($version!~/java version "1\.6\./){
	my @java = glob '/usr/lib/jvm/jre-1.6.*openjdk*/bin/java';
	unless (@java){
	    @java = glob '/usr/lib/jvm/java-1.6.*openjdk*/bin/java';
	    unless (@java){
		@java = glob '/usr/lib/jvm/java-1.6.*/bin/java';
	    }
	}
	if (@java){
	    $JAVA16 = $java[0];
	}
	else{
	    print STDERR "pdfxtk does not work with recent versions of Java!\n";
	    print STDERR "It is tested with Java 1.6.0 openjdk.\n";
	    print STDERR "Use flag -J to specify the Java version in case the script fails!\n";
	}
    }
    ## ---------------------------

    # print STDERR "$JAVA16 -Xmx $JAVA_HEAP_SIZE -cp $CLASSPATH at.ac.tuwien.dbai.pdfwrap.ProcessFile $pdf_file $out_file\n";
    local $ENV{LC_ALL} = 'en_US.UTF-8';
    my $pid = open3(undef, undef, undef, 
		    $JAVA16,
		    '-Xmx'.$JAVA_HEAP_SIZE,
		    '-cp',$CLASSPATH,
		    'at.ac.tuwien.dbai.pdfwrap.ProcessFile',
		    $pdf_file,$out_file);
    waitpid( $pid, 0 );
    return $out_file;
}




sub _xml_start{ 
    my $p = shift;
    ## delay printing paragraph boundaries
    ## in order to merge if necessary
    if ($_[0] ne 'p'){
	if ($p->{OPEN_PARA}){
	    $XMLWRITER->endTag('p');
	    $p->{OPEN_PARA} = 0;
	}
	$XMLWRITER->startTag(shift, @_);
    }
}

sub _xml_end{
    if ($_[0]->{STRING}){

	my @words=();
	_normalize_string($_[0]->{STRING});
	my @lines = split(/\n+/,$_[0]->{STRING});

	while (@lines){
	    my $OriginalStr     = shift(@lines);
	    my $DehyphenatedStr = undef;

	    if ($DEHYPHENATE){
		while ($OriginalStr=~/\-\s*$/ && @lines){
		    $DehyphenatedStr = $OriginalStr unless ($DehyphenatedStr);
		    $DehyphenatedStr=~s/\-\s*$//;
		    my $nextLine = shift(@lines);
		    $OriginalStr     .= "\n".$nextLine;
		    $DehyphenatedStr .= "\n".$nextLine;
		}
	    }

	    my @tok = _find_words( $OriginalStr, 
				  $SPLIT_CHAR_IF_NECESSARY, 
				  $SPLIT_CHAR );
	    if ($DehyphenatedStr){
		my @tok2 = _find_words( $DehyphenatedStr, 
				       $SPLIT_CHAR_IF_NECESSARY, 
				       $SPLIT_CHAR );
		@tok = @tok2 if ($#tok2 < $#tok);
	    }
	    push(@words,@tok);
	}

	my $text = join(' ',@words);
	$text=~s/\s\s+/ /gs;
	my $lang = undef;
	if (@words && ($DETECT_LANG || $KEEP_LANG) ){
	    $lang = Lingua::Identify::Blacklists::identify( lc( $text ));
	    # print STDERR "language detected: ",$lang,"\n";
	    if ($KEEP_LANG && ($lang ne $KEEP_LANG)){
		$_[0]->{STRING} = '';
		@words = ();
	    }
	}

	if (@words){
	    ## if the new text is in a different language 
	    ## --> close previous paragraph if necessary
	    if ($_[0]->{OPEN_PARA}){
		if ($lang ne $_[0]->{OPEN_PARA_LANG}){
		    $XMLWRITER->endTag('p');
		    $_[0]->{OPEN_PARA}=0;
		}
	    }

	    ## check if there is an open paragraph
	    ## merge heuristics: if the first word starts
	    ##  with a lower-cased letter --> merge!
	    ## otherwise: close previous paragraph and start a new one
	    if ($_[0]->{OPEN_PARA}){
		unless ($words[0]=~/^\p{Ll}/){
		    $XMLWRITER->endTag('p');
		    if ($lang && $DETECT_LANG){
			$XMLWRITER->startTag('p',lang => $lang);
		    }
		    else{
			$XMLWRITER->startTag('p');
		    }
		}
		else{
		    $XMLWRITER->characters(' ');
		}
	    }
	    else{
		if ($lang && $DETECT_LANG){
		    $XMLWRITER->startTag('p',lang => $lang);
		}
		else{
		    $XMLWRITER->startTag('p');
		}
	    }
	    $XMLWRITER->characters( $text );
	    if ($PAR_MERGING){
		$_[0]->{OPEN_PARA_LANG} = $lang if ($lang);
		$_[0]->{OPEN_PARA} = 1;
		if ($words[-1]=~/[.?!]$/){
		    $_[0]->{OPEN_PARA} = 0;
		}
	    }
	    unless ($_[0]->{OPEN_PARA}){
		$XMLWRITER->endTag('p');
	    }
	    $_[0]->{STRING} = '';
	}
    }
    ## delay closing paragraphs
    ## (in case we want to merge with previous one)
    if ($_[1] ne 'p'){
	if ($_[0]->{OPEN_PARA}){
	    $XMLWRITER->endTag('p');
	    $_[0]->{OPEN_PARA} = 0;
	}
	$XMLWRITER->endTag($_[1]);
    }
}

sub _xml_end_simple{
    if ($_[0]->{STRING}){
	my @words = _find_words( $_[0]->{STRING} );
	if (@words){
	    $XMLWRITER->characters( join(' ',@words) );
	    $_[0]->{STRING} = '';
	}
    }
    $XMLWRITER->endTag($_[1]);
}




# read output of 'pdftotext -raw'

sub _vocab_from_pdftotext_raw{
    my $pdf_file = shift;

    local $ENV{LC_ALL} = 'en_US.UTF-8';
    my $pid = open3(undef, \*OUT, \*ERR, $PDF2TEXT,'-raw','-enc','UTF-8',$pdf_file,'-');

    binmode(OUT,":encoding(UTF-8)");
    my $hyphenated=undef;
    while(<OUT>){
	$hyphenated = _string2voc($_, $hyphenated);
    }
    close(OUT);
    waitpid( $pid, 0 );
}


# read output of standard 'pdftotext' (or Tika if no pdftotext is available)

sub _vocab_from_pdftotext{
    my $pdf_file = shift;

    return &_vocab_from_tika($pdf_file) unless ( -e $PDF2TEXT );
    local $ENV{LC_ALL} = 'en_US.UTF-8';
    my $pid = open3(undef, \*OUT, \*ERR, 'pdftotext','-enc','UTF-8',$pdf_file,'-');

    binmode(OUT,":encoding(UTF-8)");
    my $hyphenated=undef;
    while(<OUT>){
	$hyphenated = _string2voc($_, $hyphenated);
    }
    close(OUT);
    waitpid( $pid, 0 );
}


sub _vocab_from_tika{
    my $pdf_file = shift;

    if ($USE_TIKA_SERVER){
	my $RawContent = _read_raw_file($pdf_file);
        my $ParsedContent = _request( 'put', $TIKA_URL, 'tika', 
				      { 'Accept' => 'text/plain' }, 
				      $RawContent );
	my @lines = split(/\n/,$ParsedContent);
	my $hyphenated = undef;
	foreach (@lines){
	    $hyphenated = _string2voc($_,$hyphenated);
	}
	return 1;
    }

    local $ENV{LC_ALL} = 'en_US.UTF-8';
    my $pid = open3(undef, \*OUT, \*ERR, $JAVA,'-Xmx'.$JAVA_HEAP_SIZE,
		    '-jar',$TIKAJAR,'-t',$pdf_file);

    binmode(OUT,":encoding(UTF-8)");

    my $hyphenated=undef;
    while(<OUT>){
	$hyphenated = _string2voc($_, $hyphenated);
    }
    close(OUT);
    waitpid( $pid, 0 );
}



sub _string2voc{
    my ($str,$hyphenated) = @_;
    _normalize_string($str);
    chomp;
    my @words = _find_words($str);
    if ($hyphenated){
	my $str = $LOWERCASE ? lc($hyphenated.$words[0]) : $hyphenated.$words[0];
	$voc{$str}++;
	print STDERR "possibly hyphenated: $hyphenated -- $words[0]\n" if ($VERBOSE);
	$hyphenated=undef;
    }
    if (@words){
	if ($words[-1]=~/^(.*)-/){
	    $hyphenated=$1;
	}
    }
    foreach (@words){
	$_ = lc($_) if ($LOWERCASE);
	$voc{$_}++;
    }
    return $hyphenated;
}

sub _read_raw_file{
    my $file = shift;
    open my $fh, '<:raw', $file;
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}



sub _request {
    my ($method, $url, $path, $headers, $bodyBytes) = @_;
 
    # Perform request
    my $response = $_UserAgent->$method(
	$url . '/' . $path,
	%$headers,
	Content => $bodyBytes
        );
    return decode_utf8($response->decoded_content(charset => 'none'));
}




sub _normalize_string{
    chomp($_[0]);
    $_[0]=~s/($LIGATURES_MATCH)/$LIGATURES{$1}/ge;
}



##########################################################################
#### this is a greedy left-to-right search for the longest known words
#### ---> this easily leads to many mistakes
#### ---> better use the find_segment LM-based method 
####      and its dynamic programming procedure
##########################################################################


# find the longest known words in a string
#
#  $split_char_when_necessary = 1 ---> split into character sequences if string has no whitespaces
#  $split_char = 1 ---> always split into character sequences

sub _find_longest_words{
    my @tokens1 = @_;

    return @tokens1 unless ($CHAR_MERGING);          # skip merging ...
    my @words = ();
    
    my @tokens2   = ();
    my $remaining = \@tokens1;
    my $current   = \@tokens2;

    # max number of tokens to be considered
    my $LENGTH_THR = $LONGEST_WORD || @tokens1;

    while (@{$remaining}){
	($current,$remaining) = ($remaining,$current);
	@{$remaining} = ();

	# pessimistic selection of tokens: 
	# not more than the length of the longest known word
	# (assuming that each token is at least 1 character long)
	my @more = splice(@{$current},$LENGTH_THR);

	# join all current tokens and see if they form a known word
	my $str = join('',@{$current});
	$str = lc($str) if ($LOWERCASE);

	# remove the final token until we have a known word
	until (exists $voc{$str}){
	    last unless (@{$current});
	    unshift( @{$remaining}, pop(@{$current}) );
	    $str = join('',@{$current});
	    $str = lc($str) if ($LOWERCASE);
	}

	# more than one token? 
	# --> successfully (?) found a token sequence that should be merged
	if ($#{$current}>0){
	    $voc{$str}++;
	    print STDERR join(' ',@{$current})," --> $str\n" if ($VERBOSE);
	}

	# need to restore non-lowercased version if necessary
	$str = join('',@{$current}) if ($LOWERCASE);

	# add the detected word to the list (or the next one)
	if ($str){ push(@words,$str); }
	else{      push(@words,shift @{$remaining}); }

	# add additional tokens from the sentence
	push(@{$remaining},@more);
    }
    return @words;
}


#
# find segments that best match our simple unigram language model
#


sub _find_segments{
    my @tokens = @_;
    return @tokens unless ($CHAR_MERGING);          # skip ....

    # max number of tokens to be considered
    my $LENGTH_THR = $LONGEST_WORD || length(join('',@tokens));

    unshift(@tokens,'START');

    my @scores = ();
    my @trace = ();
    for my $i (0..$#tokens){
	for my $j ($i+1..$i+$LENGTH_THR){
	    last if ( $j > $#tokens );
	    my @current = @tokens[$i+1..$j];
	    my $str = join('',@current);
	    $str = lc($str) if ($LOWERCASE);
	    $str = &_try_dehyphenation($str);

	    # stop if the length is longer than the longest known word
	    last if ( $#current > 0 && length($str) > $LENGTH_THR );

	    # skip if str is not known (and not a single character)
	    next unless (exists($lm{$str}) || $#current == 0);

	    # unigram probability (or unknown word prob)
	    my $prob = exists($lm{$str}) ? $lm{$str} : $lm{__unknown__};
	    my $start_score = $i ? $scores[$i] : 0;
	    if (exists $scores[$j]){
		if ( $start_score + $prob > $scores[$j] ){
		    $scores[$j] = $start_score + $prob;
		    $trace[$j] = $i;
		}
	    }
	    else{
		$scores[$j] = $start_score + $prob;
		$trace[$j] = $i;
	    }
	}
    }

    my @words;
    my $i=$#tokens;
    # print STDERR "best LM score = $scores[$i]\n" if ($scores[$i] && $VERBOSE);

    while ($i > 0){
	my @current = @tokens[$trace[$i]+1..$i];
	my $str = join('',@current);
	if ($VERBOSE){
	    if ($i > $trace[$i]+1){
		print STDERR join(' ',@current)," --> $str\n";
	    }
	}
	$str = &_try_dehyphenation($str);
	unshift(@words,$str);
	$i = $trace[$i];
    }
    return @words;
}



sub _find_words{
    my ($string,$pdfxtk,$charsplit) = @_;
    if ($charsplit){
	return _find_words_charlevel($string);
    }
    if ($pdfxtk){
	return _find_words_pdfxtk($string);
    }
    return _find_words_standard($string);
}


sub _find_words_standard{
    $_[0]=~s/^\s*//;
    return _find_segments( split(/\s+/,$_[0]) );
    # return _find_longest_words( split(/\s+/,$_[0]) );
}

sub _find_words_charlevel{
    $_[0]=~s/^\s*//;
    return _find_segments( split(//,$_[0]) );
    # return _find_longest_words( split(//,$_[0]) );
}


# post-process conversion by pdfxtk

sub _find_words_pdfxtk{
    my $string = shift;
    $string=~s/^\s*//;
    
    my %ligatures = ();
    foreach (values %LIGATURES){
	$ligatures{$_} = $_;
    }
    # sometimes only the second letter remains after conversion
    # (using pdftotext for example)
    # TODO: 'ffi' can also become 'i' (example: Effizienz --> Eiizienz)
    $ligatures{'l'} = 'fl';
    $ligatures{'i'} = 'fi';
    $ligatures{'f'} = 'ff';

    my @words = ();
    my @tokens = ();
    if ($string=~/\s/){
	@tokens = split(/\s+/,$string);
    }
    else{
	# return _find_words_charlevel($string);
	@tokens = _find_words_charlevel($string);
    }

    foreach (@tokens){

	# suspiciously long words ....
	if ( length($_) > $LONGEST_WORD ){
	    push(@words, _find_words_charlevel($_) );
	}

	# upper-case letters following a lower-cased one ...
	elsif ( $_ =~/\p{Ll}\p{Lu}/ ){
	    push(@words, _find_words_charlevel($_) );
	}
	else{
	    push(@words, $_);
	}
    }

    foreach (0..$#words){
	$words[$_] = &_try_dehyphenation($words[$_]);
    }

    # more post-processing: merge words if necessary
    # TODO: check if this does more harm than good for some languages
    #       the heuristics are quite effective for German at least ....
    # TODO: add other ligature-strings that need to be checked for

    my @clean=();
    my $i=0;
WORD:    while ($i<$#words){
	my $this = $words[$i];
	my $next = $words[$i+1];
	$this = lc($this) if ($LOWERCASE);
	$next = lc($next) if ($LOWERCASE);

	# # dehyphenate if necessary
	# if ($this=~/^(.+)-/){
	#     if (exists $voc{$1.$next}){
	# 	$words[$i]=~s/\-$//;
	# 	push(@clean,$words[$i].$words[$i+1]);
	# 	print STDERR "merge $words[$i]+$words[$i+1]\n" if ($VERBOSE);
	# 	$i+=2;
	# 	next;
	#     }
	# }

	# if either this or the next word does not exist in the vocabulary:
	if (! exists $voc{$this} || ! exists $voc{$next} ){

	    # check if a concatenated version exists
	    if (exists $voc{$this.$next}){
		push(@clean,$words[$i].$words[$i+1]);
		print STDERR "merge $words[$i]+$words[$i+1]\n" if ($VERBOSE);
		$i+=2;
		next;
	    }
	    # check if pdfxtk swallowed ligatures such as 'ff' and 'fi'
	    else{
		foreach my $l (sort {length($b) <=> length($a)} 
			       keys %ligatures){
		    if (exists $voc{$this.$l.$next}){
			push(@clean,$words[$i].$ligatures{$l}.$words[$i+1]);
			print STDERR "add '$ligatures{$l}' and merge $words[$i] + $words[$i+1]\n" if ($VERBOSE);
			$i+=2;
			next WORD;
		    }
		}
	    }
	}

	# nothing special? --> just add the current word
	push(@clean,$words[$i]);
	$i++;
    }
    if (@words){
	push(@clean,$words[-1]);
    }

    foreach my $i (0..$#clean){

	# don't do it with single letters!
	next if (length($clean[$i]) < 2);

	my $this = $clean[$i];
	$this = lc($this) if ($LOWERCASE);

	# if the current word does not exist in the vocabulary
	# check if adding ligature strings helps
	if (! exists $voc{$this}){
	    foreach my $l (sort {length($b) <=> length($a)} values %ligatures){
		if (exists $voc{$l.$this}){
		    print STDERR "add '$ligatures{$l}' to $clean[$i]\n" if ($VERBOSE);
		    $clean[$i]=$ligatures{$l}.$clean[$i];
		    last;
		}
		elsif (exists $voc{$this.$l}){
		    print STDERR "add '$ligatures{$l}' after $clean[$i]\n" if ($VERBOSE);
		    $clean[$i]=$clean[$i].$ligatures{$l};
		    last;
		}
	    }
	}
    }

    return @clean;
}




















sub _longest_word{
    my $len=0;
    foreach (keys %voc){
	my $l = length($_);
	$len = $l if ($l > $len);
    }
    return $len;
}

sub _dehyphenate{
    my ($part1,$part2)=@_;
    $part1=~s/\-$//;
    return $part1.$part2;
}

sub _try_dehyphenation{
    my $word=shift;
    if ($word=~/.\-./){
	my $str = $word;
	$str=~s/\-//g;
	my $lc_str = $LOWERCASE ? lcfirst($str) : $str ;
	if (exists $voc{$lc_str}){
	    $word=$str;
	}
    }
    return $word;
}




1;

__END__
