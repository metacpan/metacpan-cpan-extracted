#!/usr/bin/perl
#
#
# tei2xces.pl tei-files
#

use File::Basename;
use strict;

my $UPLUGHOME="$ENV{HOME}/cvs/sourceforge/uplug";
my $UPLUG="$UPLUGHOME/uplug";
my $CATALOG = '/corpora/MATS/XCES/dtd/catalog';
my $SGML2XML = "/usr/bin/sgml2xml -E0 -xno-nl-in-tag -xlower -c${CATALOG} 2>/dev/null";
my $RECODE = "$ENV{HOME}/user_local/bin/recode";
my $TIDY='/usr/bin/tidy -i -xml -utf8';

my %WrongNames=(ty => 'de',
		ho => 'nl',
		po => 'pl',
		a => 'sv',
		b => 'en',
		c => 'de',
		d => 'es',
		e => 'fr',
		f => 'nl',
		g => 'it',
		h => 'fi',
		p => 'es',
		'-e' => 'en',
		'_s' => 'sv',
		v => 'sv',
		is => 'sv');

foreach my $f (@ARGV){
    my ($oldsrc,$oldtrg,
	$newsrc,$newtrg,
	$srclang,$trglang)=&ConvertAlign($f);
    if ((-e $oldsrc) and (not -e $newsrc) and (not -e "$newsrc.gz")){
	&TEI2XML($oldsrc,$newsrc);
	&PreProcess($newsrc,$srclang);
    }
    if ((-e $oldtrg) and (not -e $newtrg) and (not -e "$newtrg.gz")){
	&TEI2XML($oldtrg,$newtrg);
	&PreProcess($newtrg,$trglang);
    }
}


sub MakeXmlFileName{
    my $file=shift;
    $file=~s/^.*?Aligned\///;
    $file=~s/^.*?Aligned[0-9]*\///;
    $file=~s/tei/xml/;
    return $file;
}


sub TEI2XML{
    my $tei=shift;
    my $xml=shift;

    my $command='';

    #-------------------
    # convert sgml to xml and save the result in a temp-file

    if ($tei=~/\.gz$/){$command="gzip -cd $tei | $SGML2XML";}
    else{$command="$SGML2XML < $tei";}
    $command.=" | $TIDY > $xml.tmp";
    system $command;

    #-------------------
    # remove the <back>-part (link-section)

    open IN,"<$xml.tmp";
    binmode(IN);
    if ($xml=~/\.gz$/){open OUT,"| gzip -c >$xml";}
    else{open OUT,">$xml";}
    binmode(OUT);

    my $print=1;
    while (<IN>){
	if (/\<back/){$print=0;}
	s/(\<\?xml version="1.0")(\?\>)/$1 encoding="utf-8"$2/;
	if ($print){print OUT $_;}
	if (/\<\/back/){$print=1;}
    }
    close IN;
    close OUT;
    unlink "$xml.tmp";
}


sub GetLanguagePair{
    my $src=shift;
    my $trg=shift;
    my @s=split(//,$src);
    my @t=split(//,$trg);
    my @diffs;
    my @difft;
    foreach (0..$#s){
	if ($s[$_] ne $t[$_]){
	    push @diffs,$s[$_];
	    push @difft,$t[$_];
	    if (@diffs>1){last;}      # not more than 2 characters!
	}
    }
    my $s=join '',@diffs;
    my $t=join '',@difft;
    if (defined $WrongNames{$s}){$s=$WrongNames{$s};}
    if (defined $WrongNames{$t}){$t=$WrongNames{$t};}
    my $name=$s.$t;
    return ($s,$t);
}


#-----------------------------------------------------------------------------

sub ConvertAlign{
    my $oldsrc=shift;
    my $oldtrg;
    my @xptr;
    my @links;

    my $olddir=dirname($oldsrc);
    my $src=&MakeXmlFileName($oldsrc);
    my $dir=dirname($src);
    my $trg;
    my ($s,$t);   # source and target language ID

    &ReadLinks($oldsrc,\@xptr,\@links);              # read sentence links

    if ($xptr[0]=~/doc\=\'(.*?)\'/){
	$oldtrg=$1;
	if ((not -e $oldtrg) and                     # check if the target
	    (not -e "$oldtrg.gz")){                  # file exists
	    $oldtrg="$olddir/$oldtrg";
	    if ((not -e $oldtrg) and 
		(not -e "$oldtrg.gz")){              # return empty array
		return ();                           # otherwise!
	    }
	}
	if ((not -e $oldtrg) and (-e "$oldtrg.gz")){ # check if target is
	    $oldtrg="$oldtrg.gz";                    # gzipped
	}

	#-------------------------------------------------------------------
	($s,$t)=&GetLanguagePair($oldsrc,$oldtrg);   # get the language pair
	system "mkdir -p $s/$dir";                   # create sub-dirs for each
	system "mkdir -p $t/$dir";                   # language
	my $out=$s.$t.'.ces';                        # name of sent-align-file
	$src=&MakeXmlFileName(basename($oldsrc));    # get XML-file names
	$trg=&MakeXmlFileName(basename($oldtrg));
	$src="$s/$dir/$src";
	$trg="$t/$dir/$trg";                         # add path to file names
	#-------------------------------------------------------------------

	if (-e $out){open OUT,">>$out";}         # open/append to sentence-
	else{                                    # align-file
	    open OUT,">$out";
	    print OUT '<?xml version="1.0"?>
<!DOCTYPE cesDoc PUBLIC "-//CES//DTD XML cesAlign//EN"
                        "dtd/xcesAlign.dtd" [
]>
<cesAlign>
  <linkList>';
	}
	print OUT '<linkGrp targType="s"
             fromDoc="';                         # fromDoc=source-XML-file
	print OUT $src;
	print OUT '"
             toDoc="';                           # toDoc=target-XML-file
	print OUT $trg.'">'."\n";

	my $count=0;
	my $IDpref=$src;
	$IDpref=~s/^.*\/([^\/]+)\.xml.*$/$1/;
	foreach (@links){
	    $count++;
	    s/(targets=\'.*?)x/x$1; /;
	    s/xid/id/g;
	    tr/'/"/;
	    s/(\<link)\s/$1 id="$IDpref.$count" /;
	    print OUT $_;
	}
	print OUT '</linkGrp>';
	close OUT;
    }
    return ($oldsrc,$oldtrg,$src,$trg,$s,$t);
}

#-----------------------------------------------------------------------------

sub ReadLinks{
    my $file=shift;
    my ($xptr,$links)=@_;
    if ($file=~/\.gz$/){open F,"gzip -cd  <$file |";}
    else{open F,"<$file";}

    my @lines=<F>;
    @{$xptr}=grep (/\<xptr\s/,@lines);
    @{$links}=grep (/\<link\s/,@lines);
}


#-----------------------------------------------------------------------------

sub PreProcess{
    my $file=shift;
    my $lang=shift;

    my $out=$file.'tmp';
    if ($file=~/\.gz$/){$out.='.gz';}

    if (-e "$UPLUGHOME/systems/pre/$lang/toktag"){
	system "$UPLUG systems/pre/$lang/toktag -in $file -out $out";
	system "mv $out $file";
    }
    else{
	system "$UPLUG systems/pre/tok -in $file -out $out";
	system "mv $out $file";
    }
    if ((-e "$UPLUGHOME/systems/pre/$lang/tag") and             # if default
	(not `grep 'tree' $UPLUGHOME/systems/pre/$lang/tag`)){  # is not TreeT
	system "$UPLUG systems/pre/$lang/tag -in $file -out $out";
	system "mv $out $file";
    }
    if (-e "$UPLUGHOME/systems/pre/$lang/chunk"){
	system "$UPLUG systems/pre/$lang/chunk -in $file -out $out";
	system "mv $out $file";
    }
    if (-e "$UPLUGHOME/systems/pre/$lang/parse"){
	system "$UPLUG systems/pre/$lang/parse -in $file -out $out";
	system "mv $out $file";
    }
    if ($file=~/\.gz$/){
	system "gzip -cd $file | $TIDY | gzip -c > $out";
    }
    else{
	system "$TIDY < $file > $out";
    }
    system "mv $out $file";
}
