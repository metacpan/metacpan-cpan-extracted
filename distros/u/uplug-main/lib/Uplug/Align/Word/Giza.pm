#-*-perl-*-

package Uplug::Align::Word::Giza;


use strict;

use Cwd;
use Exporter;
use File::Copy;

use Uplug::Data;
use Uplug::Data::Align;
use Uplug::IO::Any;
use Uplug::Config;

use vars qw(@ISA @EXPORT $DEBUG $GIZAHOME);

# @ISA = qw( Uplug::Align::Word Exporter );
@ISA = qw( Exporter);
$DEBUG = 0;

@EXPORT = qw( &Bitext2Text &RunGiza &Combined2Uplug &Giza2Clue &Giza2Uplug );

#BEGIN{
    our $GIZAHOME="$ENV{UPLUGHOME}/ext/GIZA++";
    if (not -d $GIZAHOME){$GIZAHOME="$ENV{HOME}/cvs/GIZA++-v2";}
    if (not -d $GIZAHOME){$GIZAHOME="$ENV{HOME}/cvs/GIZA++";}
    if (not -d $GIZAHOME){$GIZAHOME="/local/ling/GIZA++-v2";}
    if (not -d $GIZAHOME){$GIZAHOME="/local/ling/GIZA++";}
#}

# if (not -d $GIZAHOME){warn "cannot find GIZA++!";exit;}


#----------------------------------------------------------------------------
# Giza2Clue (new version): no external calls
#  - looks for $dir/GIZA++.actual.ti.final (lexical prob's from GIZA)
#  - creates data/runtime/giza.dbm
#  - creates data/runtime/giza2.dbm (inverse alignments)

sub Giza2Clue{
    my $file=shift;
    my $param=shift;
    my $inverse=shift;
    my $ClueDB=shift;
    my $threshold=shift;

    if (-d $file){                             # if file is a directory
	$file="$file/GIZA++.actual.ti.final";  # look for the standard file in
    }                                          # this directory!

    my %dic;
    if (ref($ClueDB) eq 'HASH'){
	%dic=%{$ClueDB};
    }
    else{
	%dic=('format' => 'dbm',
	      'write_mode' => 'overwrite',
	      'key' => ['source','target']);
	my $cluedir='data/runtime';
	if ($inverse){$dic{file}="$cluedir/giza2.dbm";}
	else{$dic{file}="$cluedir/giza.dbm";}
    }

    my %inStream=('file' => $file,
		  'format' => 'tab',
		  'field delimiter' => ' ');
    if ($inverse){
	$inStream{'columns'}=['source','target','value',],
    }
    else{
	$inStream{'columns'}=['target','source','value',],
    }


    my %lex=();
    my $data=Uplug::Data->new;

    my $in=Uplug::IO::Any->new(\%inStream);
    $in->open('read',\%inStream);
    my $count=0;
    while ($in->read($data)){
	$count++;
	if (not ($count % 1000)){print STDERR '.';}
	if (not ($count % 10000)){print STDERR "$count\n";}
	my $src=$data->attribute('source');
	my $trg=$data->attribute('target');
	if ((not $src) or (not $trg)){next;}
	my $value=$data->attribute('value');
	if (not $value){$value=1;}
	if ((defined $threshold) and ($value<$threshold)){next;}
	$lex{$src}{$trg}=$value;
	if (($src=~s/\_/ /gs) or ($trg=~s/\_/ /gs)){ # (for giza-clue:)
	    $lex{$src}{$trg}=$value;                 #   '_' means ' '
	}
    }
    my $header=$in->header;

    my $out=Uplug::IO::Any->new(\%dic);
    $out->open('write',\%dic);
    $out->addheader($header);
    $out->addheader($param);
    $out->writeheader();

    foreach my $s (keys %lex){
	my $total;
	foreach my $t (keys %{$lex{$s}}){
	    my $score=$lex{$s}{$t};
	    my $data=Uplug::Data->new;
	    $data->setAttribute('source',$s);
	    $data->setAttribute('target',$t);
	    $data->setAttribute('score',$score);
	    $out->write($data);
	}
    }

    $out->close;
    $in->close;
}

#----------------------------------------------------------------------------
# Giza2Uplug: convert GIZA's Viterbi alignment to Uplug format (XML)
# (slow and risky: GIZA's output must be complete and use a certain format)

sub Giza2Uplug{
    my $viterbi=shift;
    my $bitext=shift;
    my $param=shift;
    my $links=shift;
    my $inverse=shift;

    if (ref($links) ne 'HASH'){return 0;}
    my $input=Uplug::IO::Any->new($bitext);
    if (not ref($input)){return 0;}
    if (not $input->open('read',$bitext)){return 0;}
    my $BitextHeader=$input->header();
    my $output=Uplug::IO::Any->new($links);
    if (not ref($output)){return 0;}
    $output->addheader($BitextHeader);
    if (not $output->open('write',$links)){return 0;}
    $output->setOption('SkipDataHeader',0); # don't skip headers and
    $output->setOption('SkipDataTail',0);   # footers (e.g. <linkGrp>)


    #------------------------------------------------------------------------
    if ($viterbi=~/\.gz$/){
	open F,"gzip -cd <$viterbi |" || 
	    die "cannot open Viterbi alignment file $viterbi!";
    }
    else{
	open F,"<$viterbi" || 
	    die "cannot open Viterbi alignment file $viterbi!";
    }
    #------------------------------------------------------------------------

    my $TokenLabel='w';
    my $data=Uplug::Data::Align->new();
    print STDERR "convert GIZA's Viterbi alignment to XML!\n";
    my $count=0;

    while ($input->read($data)){

	$count++;
	if (not ($count % 100)){
	    $|=1;print STDERR '.';$|=0;
	}
	if (not ($count % 1000)){
	    $|=1;print STDERR "$count\n";$|=0;
	}

	#----------------------------------
	# do the same as for Bitext2Text!!
	# (to check for empty strings ...)
	#
	my @SrcNodes=();
	my @TrgNodes=();
	my ($srctxt,$trgtxt)=
	    &BitextStrings($data,$param,\@SrcNodes,\@TrgNodes);
	if (($srctxt!~/\S/) or ($trgtxt!~/\S/)){next;}
	#----------------------------------

#	my $SrcData=$data->sourceData();
#	my $TrgData=$data->targetData();
#
#	my @SrcNodes=$SrcData->findNodes($TokenLabel);
	my @SrcIds=$data->attribute(\@SrcNodes,'id');
	my @SrcSpans=$data->attribute(\@SrcNodes,'span');
#	my @SrcTokens=$data->content(\@SrcNodes);
	my @SrcTokens=$data->getSrcTokenFeatures($param,\@SrcNodes);

#	my @TrgNodes=$TrgData->findNodes($TokenLabel);
	my @TrgIds=$data->attribute(\@TrgNodes,'id');
	my @TrgSpans=$data->attribute(\@TrgNodes,'span');
#	my @TrgTokens=$data->content(\@TrgNodes);
	my @TrgTokens=$data->getTrgTokenFeatures($param,\@TrgNodes);

	if ((not @SrcNodes) or (not @TrgNodes)){next;}

	$_=<F>;
	$_=<F>;
	chomp;
	my @src=split(/ /);
	$_=<F>;
	chomp;

	my %align=();
	my $count=1;
	while (/\s(\S.*?)\s\(\{\s(.*?)\}\)/g){     # strunta i NULL!!
	    if ($2){push (@{$align{$2}},$count);}
	    $count++;
	}
	foreach (sort keys %align){
	    my @s;my @t;
	    if ($inverse){
		@t=@{$align{$_}};
		@s=split(/\s/);
	    }
	    else{
		@s=@{$align{$_}};
		@t=split(/\s/);
	    }

	    my @src=();my @trg=();
	    foreach (@s){push (@src,$SrcTokens[$_-1]);}
	    foreach (@t){push (@trg,$TrgTokens[$_-1]);}
	    my @srcId=();my @trgId=();
	    foreach (@s){push (@srcId,$SrcIds[$_-1]);}
	    foreach (@t){push (@trgId,$TrgIds[$_-1]);}
	    my @srcSpan=();my @trgSpan=();
	    foreach (@s){push (@srcSpan,$SrcSpans[$_-1]);}
	    foreach (@t){push (@trgSpan,$TrgSpans[$_-1]);}

	    my %link=();
	    $link{link}=join ' ',@src;
	    $link{link}.=';';
	    $link{link}.=join ' ',@trg;
	    $link{source}=join '+',@srcId;
	    $link{target}=join '+',@trgId;
	    $link{src}=join '&',@srcSpan;
	    $link{trg}=join '&',@trgSpan;

	    $data->addWordLink(\%link);
	}

	$output->write($data);
    }
    $input->close;
    $output->close;
}


#----------------------------------------------------------------------------
# Combined2Uplug: combine GIZA's Viterbi alignment and convert them to Uplug format (XML)
# (slow and risky: GIZA's output must be complete and must use a certain format)
#
# possible combinatins: union, intersection, refined
#

sub Combined2Uplug{
    my $giza0=shift;
    my $giza1=shift;
    my $combine=shift;
    my $bitext=shift;
    my $param=shift;
    my $links=shift;

    if (ref($links) ne 'HASH'){return 0;}
    my $input=Uplug::IO::Any->new($bitext);
    if (not ref($input)){return 0;}
    if (not $input->open('read',$bitext)){return 0;}
    my $output;   # open output later (after reading the first record of
                  # the input stream --> this gives the complete input header)

    #------------------------------------------------------------------------
    if ($giza0=~/\.gz$/){open F0,"gzip -cd <$giza0 |";}
    else{open F0,"<$giza0";}
#    ($]>=5.008){binmode(F0, ":encoding(utf-8)");}

    if ($giza1=~/\.gz$/){open F1,"gzip -cd <$giza1 |";}
    else{open F1,"<$giza1";}
#    ($]>=5.008){binmode(F1, ":encoding(utf-8)");}
    #------------------------------------------------------------------------

    my $TokenLabel='w';
    my $data=Uplug::Data::Align->new();
    print STDERR "combine GIZA's Viterbi alignments and convert to XML!\n";
    my $count=0;

    while ($input->read($data)){

	if (not $output){                           # output is not opened yet:
	    my $BitextHeader=$input->header();      # - get the input header
	    $output=Uplug::IO::Any->new($links);    # - create an output stream
	    if (not ref($output)){return 0;}        #   (or die)
	    $output->addheader($BitextHeader);      # - add input header
	    if (not $output->open('write',$links)){ # - open the output stream
		return 0;                           #   (or die)
	    }
	    $output->setOption('SkipDataHeader',0); # don't skip headers and
	    $output->setOption('SkipDataTail',0);   # footers (e.g. <linkGrp>)
	}

	$count++;
	if (not ($count % 100)){
	    $|=1;print STDERR '.';$|=0;
	}
	if (not ($count % 1000)){
	    $|=1;print STDERR "$count\n";$|=0;
	}

	#----------------------------------
	# do the same as for Bitext2Text!!
	# (to check for empty strings ...)
	#
	my @SrcNodes=();
	my @TrgNodes=();
	my ($srctxt,$trgtxt)=
	    &BitextStrings($data,$param,\@SrcNodes,\@TrgNodes);
	if (($srctxt!~/\S/) or ($trgtxt!~/\S/)){next;}
	#----------------------------------

#	my @SrcNodes=$SrcData->findNodes($TokenLabel);
	my @SrcIds=$data->attribute(\@SrcNodes,'id');
	my @SrcSpans=$data->attribute(\@SrcNodes,'span');
#	my @SrcTokens=$data->content(\@SrcNodes);
	my @SrcTokens=$data->getSrcTokenFeatures($param,\@SrcNodes);

#	my @TrgNodes=$TrgData->findNodes($TokenLabel);
	my @TrgIds=$data->attribute(\@TrgNodes,'id');
	my @TrgSpans=$data->attribute(\@TrgNodes,'span');
#	my @TrgTokens=$data->content(\@TrgNodes);
	my @TrgTokens=$data->getTrgTokenFeatures($param,\@TrgNodes);

	if ((not @SrcNodes) or (not @TrgNodes)){next;}

	$_=<F1>;$_=<F1>;chomp;    # read source->target viterbi alignment
	my @src=split(/ /);
	$_=<F1>;chomp;
	my %srclinks=();
	my $count=1;
	while (/\s(\S.*?)\s\(\{\s(.*?)\}\)/g){     # strunta i NULL!!
	    my @s=split(/\s/,$2);
	    foreach (@s){$srclinks{$_}{$count}=1;}
	    $count++;
	}


	$_=<F0>;$_=<F0>;chomp;    # read source->target viterbi alignment
	my @trg=split(/ /);
	$_=<F0>;chomp;
	my %trglinks=();
	my $count=1;
	while (/\s(\S.*?)\s\(\{\s(.*?)\}\)/g){     # strunta i NULL!!
	    my @t=split(/\s/,$2);
	    foreach (@t){$trglinks{$_}{$count}=1;}
	    $count++;
	}

	my (%CombinedSrc,%CombinedTrg);
	&CombineLinks(\%srclinks,\%trglinks,$combine,\%CombinedSrc,\%CombinedTrg);
	my @cluster=&LinkClusters(\%CombinedSrc,\%CombinedTrg);

	foreach my $c (@cluster){
#	    my @s=sort {$a <=> $b} keys %{$cluster[$_]{src}};
#	    my @t=sort {$a <=> $b} keys %{$cluster[$_]{trg}};

	    my @s=@{$$c{src}};
	    my @t=@{$$c{trg}};

	    my @src=();my @trg=();
	    foreach (@s){push (@src,$SrcTokens[$_-1]);}
	    foreach (@t){push (@trg,$TrgTokens[$_-1]);}
	    my @srcId=();my @trgId=();
	    foreach (@s){push (@srcId,$SrcIds[$_-1]);}
	    foreach (@t){push (@trgId,$TrgIds[$_-1]);}
	    my @srcSpan=();my @trgSpan=();
	    foreach (@s){push (@srcSpan,$SrcSpans[$_-1]);}
	    foreach (@t){push (@trgSpan,$TrgSpans[$_-1]);}

	    my %link=();
	    $link{link}=join ' ',@src;
	    $link{link}.=';';
	    $link{link}.=join ' ',@trg;
	    $link{source}=join '+',@srcId;
	    $link{target}=join '+',@trgId;
	    $link{src}=join '&',@srcSpan;
	    $link{trg}=join '&',@trgSpan;

	    $data->addWordLink(\%link);
	}

	$output->write($data);
    }
    $input->close;
    $output->close;
}


sub LinkClusters{
    my ($src,$trg)=@_;
    my @cluster=();
    while (keys %{$src}){
	my ($s,$links)=each %{$src};            # get the next source token
	if ((ref($$src{$s}) ne 'HASH') or
	    (not keys %{$$src{$s}})){           # if no links exist:
	    delete $$src{$s};                   # delete and next!
	    next;
	}
	push (@cluster,{src=>[],trg=>[]});      # create a new link cluster
	push (@{$cluster[-1]{src}},$s);         #  and save it in the cluster
	&AddLinks($cluster[-1],$src,$trg,$s,    # add all tokens aligned to the
		  'src','trg');                 #  source token to the cluster
    }                                           #  (and recursively the ones

    foreach my $c (@cluster){
	@{$$c{src}}=sort {$a <=> $b} @{$$c{src}};
	@{$$c{trg}}=sort {$a <=> $b} @{$$c{trg}};
    }
    return @cluster;
}                                               #   linked to them, see AddLinks)

sub AddLinks{
    my ($cluster,$src,$trg,$s,$key1,$key2)=@_;
    foreach my $t (keys %{$$src{$s}}){          # add all linked tokens to the
	delete $$src{$s}{$t};                   # cluster and delete the links
	delete $$trg{$t}{$s};                   # in the link-hashs
	push (@{$$cluster{$key2}},$t);
	&AddLinks($cluster,$trg,$src,$t,$key2,$key1); # add tokens aligned to the
    }                                                 # linked token to the cluster
    delete $$src{$s};                           # delete the source token link hash
}



sub CombineLinks{
    my ($src,$trg,$method,$srclinks,$trglinks)=@_;
#    my %srclinks;
#    my %trglinks;
    if ($method eq 'union'){
	foreach my $s (keys %{$src}){
	    foreach my $t (keys %{$$src{$s}}){
		$$srclinks{$s}{$t}=1;
		$$trglinks{$t}{$s}=1;
	    }
	}
	foreach my $t (keys %{$trg}){
	    foreach my $s (keys %{$$trg{$t}}){
		$$srclinks{$s}{$t}=1;
		$$trglinks{$t}{$s}=1;
	    }
	}
    }
    elsif ($method eq 'intersection'){
	foreach my $s (keys %{$src}){
	    foreach my $t (keys %{$$src{$s}}){
		if (exists $$trg{$t}{$s}){
		    $$srclinks{$s}{$t}=1;
		    $$trglinks{$t}{$s}=1;
		}
	    }
	}
    }
    if ($method eq 'refined'){                   # refined combination:
	my %links=();
	foreach my $s (keys %{$src}){               # 1) start with intersection
	    foreach my $t (keys %{$$src{$s}}){
		if (exists $$trg{$t}{$s}){
		    $$srclinks{$s}{$t}=1;
		    $$trglinks{$t}{$s}=1;
		}
		else{
		    $links{"$s:$t"}=1;              # keep union of links
		}
	    }
	}
	foreach my $t (keys %{$trg}){
	    foreach my $s (keys %{$$trg{$t}}){
		if (not exists $$src{$s}{$t}){
		    $links{"$s:$t"}=1;
		}
	    }
	}
	add_unaligned(\%links,$srclinks,$trglinks); # 2) add unaligned pairs
	add_adjacent(\%links,$srclinks,$trglinks);  # 3) add adjacent links
    }
#    $src=\%srclinks;
#    $trg=\%trglinks;
}


sub is_diagonal{
    my ($s,$t,$srclinks,$trglinks)=@_;
    if (defined $$srclinks{$s-1}){
	return 1 if (defined $$trglinks{$t-1});
	return 1 if (defined $$trglinks{$t+1});
    }
    if (defined $$srclinks{$s+1}){
	return 1 if (defined $$trglinks{$t-1});
	return 1 if (defined $$trglinks{$t+1});
    }
    return 0;
}



sub is_adjacent{
    my ($s,$t,$srclinks,$trglinks)=@_;
    if (exists $$srclinks{$s}){
	return 1 if (exists $$srclinks{$s}{$t-1});
	return 1 if (exists $$srclinks{$s}{$t+1});
    }
    elsif (exists $$trglinks{$t}){
	return 1 if (exists $$trglinks{$t}{$s-1});
	return 1 if (exists $$trglinks{$t}{$s+1});
    }
    return 0;
}


sub add_adjacent{
    my $links=shift;
    my $srclinks=shift;
    my $trglinks=shift;

    my $add=1;
    while (%{$links} && $add){
	$add=0;
	foreach my $l (keys %{$links}){
	    my ($l) = each %{$links};
	    my ($s,$t) = split(/:/,$l);
	    next if (exists $$srclinks{$s} && exists $$trglinks{$t});
	    if (is_adjacent($s,$t,$srclinks,$trglinks)){
		$$srclinks{$s}{$t}=1;
		$$trglinks{$t}{$s}=1;
		delete $$links{$l};
		$add++;
	    }
	}
    }
}



sub is_unaligned{
    my ($s,$t,$srclinks,$trglinks)=@_;
    if (not exists $$srclinks{$s}){
	return 1 if (not exists $$trglinks{$t});
    }
    return 0;
}

sub add_unaligned{
    my $links=shift;
    my $srclinks=shift;
    my $trglinks=shift;
    foreach my $l (keys %{$links}){
	my ($s,$t) = split(/:/,$l);
	if (is_unaligned($s,$t,$srclinks,$trglinks)){
	    $$srclinks{$s}{$t}=1;
	    $$trglinks{$t}{$s}=1;
	    delete $$links{$l};
	}
    }
}




sub add_adjacent_old{
    my $links=shift;
    my $srclinks=shift;
    my $trglinks=shift;
    foreach my $s (0..$#{$links}){
	foreach my $t (0..$#{$$links[$s]}){
	    next if (not $$links[$s][$t]);
	    if ((not defined $$srclinks{$s}) and
		(not defined $$trglinks{$t})){       #   - if both are not aligned yet:
		$$srclinks{$s}{$t}=1;                #     add the link
		$$trglinks{$t}{$s}=1;
	    }
	    elsif ((defined $$srclinks{$s-1}) or
		   (defined $$srclinks{$s+1})){
		if (($$srclinks{$s-1}{$t}) or         # if the link is adjacent to
		    ($$srclinks{$s+1}{$t})){       # another one horizontally:
		    if ($$srclinks{$s}{$t+1}){next;}  # do not accept if it is also
		    if ($$srclinks{$s}{$t-1}){next;}  # adjacent to other links vertically
		    if ($$srclinks{$s-1}{$t}){              # do not accept if the adjacent
			if ($$srclinks{$s-1}{$t-1}){next;}  # link is also adjacent to other
			if ($$srclinks{$s-1}{$t+1}){next;}  # links vertically
		    }
		    if ($$srclinks{$s+1}{$t}){              # the same for the other
			if ($$srclinks{$s+1}{$t-1}){next;}  # adjacency direction
			if ($$srclinks{$s+1}{$t+1}){next;}
		    }
		    $$srclinks{$s}{$t}=1;        # everything ok: add the link
		    $$trglinks{$t}{$s}=1;
		}
	    }
	    elsif ((defined $$trglinks{$t-1}) or
		   (defined $$trglinks{$t+1})){
		if (($$srclinks{$s}{$t-1}) or         # if the link is adjacent to
		    ($$srclinks{$s}{$t+1})){          # another one vertically:
		    if ($$srclinks{$s+1}{$t}){next;}  # do not accept if it is also
		    if ($$srclinks{$s-1}{$t}){next;}  # adjacent to other links horizontally
		    if ($$srclinks{$s}{$t-1}){              # do not accept if the adjacent
			if ($$srclinks{$s-1}{$t-1}){next;}  # link is also adjacent to other
			if ($$srclinks{$s+1}{$t-1}){next;}  # links horizontally
		    }
		    if ($$srclinks{$s}{$t+1}){              # the same for the other
			if ($$srclinks{$s-1}{$t+1}){next;}  # adjacency direction
			if ($$srclinks{$s+1}{$t+1}){next;}
		    }
		    $$srclinks{$s}{$t}=1;        # everything ok: add the link
		    $$trglinks{$t}{$s}=1;
		}
	    }
	}
    }
}


#----------------------------------------------------------------------------
# RunGiza: run GIZA++ using external scripts
# (GIZA must be installed in the given directory)

sub RunGiza{
    my $src=shift;
    my $trg=shift;
    my $viterbi=shift;

    if (not -d $GIZAHOME){
        $GIZAHOME="$ENV{UPLUGHOME}/ext/GIZA++";
    	if (not -d $GIZAHOME){$GIZAHOME="$ENV{HOME}/cvs/GIZA++-v2";}
    	if (not -d $GIZAHOME){$GIZAHOME="$ENV{HOME}/cvs/GIZA++";}
    	if (not -d $GIZAHOME){$GIZAHOME="/local/ling/GIZA++-v2";}
    	if (not -d $GIZAHOME){$GIZAHOME="/local/ling/GIZA++";}
        if (not -d $GIZAHOME){
	   warn "cannot find GIZA++ in $GIZAHOME! Set ENV{UPLUGHOME} or Uplug::Align::Word::Giza::GIZAHOME!";
	   return 0;
        }
    }
    if (my $sig=system "$GIZAHOME/plain2snt.out $src $trg"){
	die "got signal $? from plain2snt!\n";
    }
    my $command="PATH=\$\{PATH\}:$GIZAHOME;";
    my $snt="$src$trg\.snt";
    if (not -e $snt){$snt="$src\_$trg\.snt";}
    if (not -e $snt){die "cannot find alignment-file: $snt!\n";}
    $command.="$GIZAHOME/trainGIZA++.sh $src\.vcb $trg\.vcb $snt";
    if (my $sig=system $command){
	die "got signal $? from trainGIZA++.sh!\n";
    }
    if ($viterbi){copy ('GIZA++.A3.final',$viterbi);}
    else{copy ('GIZA++.A3.final','viterbi');}
}

#----------------------------------------------------------------------------
# Bitext2Text: convert bitexts from Uplug format (XML) to GIZA's format
# (this is much too slow ....)

sub Bitext2Text{
    my $bitext=shift;
    my $srcfile=shift;
    my $trgfile=shift;
    my $param=shift;

    my %SrcStream=('format'=>'text','file'=>$srcfile);
    my %TrgStream=('format'=>'text','file'=>$trgfile);

    my $input=Uplug::IO::Any->new($bitext);
    my $source=Uplug::IO::Any->new(\%SrcStream);
    my $target=Uplug::IO::Any->new(\%TrgStream);
    $input->open('read',$bitext)
	|| warn "cannot open the bitext" && return 0;
    $source->open('write',\%SrcStream) 
	|| warn "cannot write to $srcfile" && return 0;
    $target->open('write',\%TrgStream) 
	|| warn "cannot write to $trgfile" && return 0;

    #-------------------------------------------------------------------------

    my $data=Uplug::Data::Align->new();

    print STDERR "convert bitext to plain text!\n";
    my $count=0;
    while ($input->read($data)){
	$count++;
	if (not ($count % 100)){
	    $|=1;print STDERR '.';$|=0;
	}
	if (not ($count % 1000)){
	    $|=1;print STDERR "$count\n";$|=0;
	}

	my ($srctxt,$trgtxt)=&BitextStrings($data,$param);

	if (($srctxt=~/\S/) and ($trgtxt=~/\S/)){
	    $source->write($srctxt);
	    $target->write($trgtxt);
	}
    }
#     $BitextHeader=$input->header;
    $input->close;
    $source->close;
    $target->close;
    return $input->header;
}

#----------------------------------------------------------------------------
# get the actual strings from the bitext (using feature-parameters)
# (feature specifications as in coocfreq.pl)

sub BitextStrings{
    my $data=shift;
    my $param=shift;
    my ($srcnodes,$trgnodes)=@_;

    my @srctok=$data->getSrcTokenFeatures($param,$srcnodes);
    my @trgtok=$data->getTrgTokenFeatures($param,$trgnodes);

    map($_=~s/^\s+//sg,@srctok);         # delete initial white-space
    map($_=~s/^\s+//sg,@trgtok);
    map($_=~s/(\S)\s+$/$1/sg,@srctok);   # delete final white-space
    map($_=~s/(\S)\s+$/$1/sg,@trgtok);

    map($_=~s/\n/ /sg,@srctok);          # otherwise: convert to space
    map($_=~s/\n/ /sg,@trgtok);
    map($_=~s/\s/\_/sg,@srctok);         # and replace space with underline
    map($_=~s/\s/\_/sg,@trgtok);         # (to avoid extra tokens)
	
    my $srctxt=join(' ',@srctok);
    my $trgtxt=join(' ',@trgtok);

    $srctxt=~tr/\n/ /;
    $trgtxt=~tr/\n/ /;
    return ($srctxt,$trgtxt);
}

#----------------------------------------------------------------------------



=pod

=head1 Synopsis

 use lib '/path/to/uplug';
 use Uplug::Align::Word::Giza;

 $ENV{UPLUGHOME}='/path/to/uplug';


 my %bitext = ('file' => 'svenprf.xces',
               'format' => 'xces align');


 &Bitext2Text(\%bitext,'src','trg',{});     # convert to plain text
 &RunGiza('src','trg','viterbi.src-trg');   # run GIZA++ (src-->trg)
 &RunGiza('trg','src','viterbi.trg-src');   # run GIZA++ (trg-->src)

 my %dbm = (file=>'clues.dbm',
	    format=>'dbm',
	    key => ['source','target']);

 &Giza2Clue('.',         # directory where GIZA was running (=current)
	    {},          # parameter (= clue dbm header)
	    1,           # =1 --> inverse (trg-src)
	    \%dbm);      # clue DBM (giza.dbm if not specified)

 my $combine = 'intersection'       # combine heuristics (union|refined)
 my %out = ('file' => $combined,    # save the result in this file
            'format' => 'xces align');

  &Combined2Uplug('viterbi.src-trg',  # name of first viterbi alignment
                  'viterbi.trg-src',  # name of second viterbi alignment
                  $combine,           # type of combination heuristics
		  \%bitext,           # bitext
		  {},                 # token parameters
                  \%out);             # output stream


=head1 GIZA++ directories

You have to tell the program where it can find the GIZA++ executables.
You can either set the UPLUGHOME environment variable or the GIZAHOME variable.

 $ENV{UPLUGHOME}='/path/to/uplug';
 $Uplug::Align::Word::Giza::GIZAHOME="/path/to/uplug/ext/GIZA++";

=cut



1;
