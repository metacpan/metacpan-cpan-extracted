#
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


package Uplug::Web::CWB;

use strict;
use CGI qw/:standard escapeHTML escape/;
use HTML::Entities;
use Encode;
use lib ('/home/staff/joerg/user_local/lib/perl5/site_perl/5.8.0/');
use WebCqp::Query;

binmode(STDOUT, ":utf8");            # set UTF8 for STDOUT

my $MAXWAIT=60;
my $SHOWMAX=20;
my $NRCORPORA=0;

#------------------------------------------------------
# some links and text

my ($CQPSYNTAX,$CWBLINK,$CQPEXAMPLES)=
    (
     "http://www.ims.uni-stuttgart.de/projekte/CorpusWorkbench/CQPSyntax.html",
     "http://www.ims.uni-stuttgart.de/projekte/CorpusWorkbench/index.html",
     "http://www.ims.uni-stuttgart.de/projekte/CorpusWorkbench/CQPExamples.html"
    );
my $CQPtext=
    'A CQP query consists of a regular'.&br().
    'expression over '.&i('attribute expressions').'.'.&br().
    &a({-href=>$CQPSYNTAX},'Introduction of the query syntax').&br.
    &a({-href=>$CQPEXAMPLES},'Example queries');
my $PATTRtext='positional annotation';
my $SATTRtext='structural annotation';
my %corpora;



############################################################################
############################################################################
############################################################################
############################################################################
############################################################################
############################################################################
############################################################################
############################################################################
############################################################################
############################################################################

sub Query{

    my $url      = shift;
    my $owner    = shift;
    my $corpus   = shift;

    my $lang = url_param('s');
    if (param('showmax')){$SHOWMAX=param('showmax');}

    my $advanced = url_param('adv');
    my @alg = param('alg');
    my $cqp = decode('utf-8',param('query'));
    if ($cqp){param('query',$cqp);}

    binmode (STDOUT,':encoding(utf-8)');

    if (not -d $ENV{UPLUGCWB}){mkdir $ENV{UPLUGCWB},0755;}
    if (not -d "$ENV{UPLUGCWB}/reg"){mkdir "$ENV{UPLUGCWB}/reg",0755;}
    if (not -d "$ENV{UPLUGCWB}/dat"){mkdir "$ENV{UPLUGCWB}/dat",0755;}
    if (not -d "$ENV{UPLUGCWB}/reg/$owner"){mkdir "$ENV{UPLUGCWB}/reg/$owner",0755;}
    if (not -d "$ENV{UPLUGCWB}/dat/$owner"){mkdir "$ENV{UPLUGCWB}/dat/$owner",0755;}

    my $CWBregistry="$ENV{UPLUGCWB}/reg/$owner";
    chdir $CWBregistry;

#------------------------------------------------------
# main
#------------------------------------------------------

    my $html;     # =&h2("Corpus query (CWB)");
    &ReadRegistry('.',\%corpora);

    my $reg=undef;

##----------------------------------------------
## if there is only one corpus: set parameters
## otherwise: create corpus-links for each corpus in the registry
##
    if ($NRCORPORA==1){
	($corpus,$lang)=keys %corpora;
	($lang)=keys %{$corpora{$corpus}};
    }
    else{
	$reg=&RegisteryLinks(\%corpora,$url);
    }
##----------------------------------------------

    my $form=&CorpusQueryForm($corpus,$lang,$advanced);
    $html.=&table({},caption(''),&Tr([&td({-valign=>'top'},[$reg,$form])]));


    if (param('query')){
	$html.=&p(),&hr();
	my $style = param('style');
	$html.=&CorpusQuery($corpus,$lang,$cqp,\@alg,$style);
    }
    return $html;
}

#------------------------------------------------------
# end
#------------------------------------------------------




#------------------------------------------------------
# FixString: convert from CWB-format 
# to UTF-8 if necessary!


sub FixString{
    my ($lang,$string)=@_;
    if ($lang=~/^(ar|az|be|bg|bs|he|id|jp|ja|ko|ku|mi|mk|ru|ta|th|uk|vi|xh|zh_tw|zu)$/){
	decode_entities($string);
	$string=decode('utf-8',$string);
    }
    if ($lang eq 'el'){decode_entities($string);}
    if ($lang=~/^(cs|hr|hu|pl|ro|sk|sl|sr)$/){
	decode_entities($string);
	$string=decode('iso-8859-2',$string);
    }
    if ($lang=~/^el$/){
	decode_entities($string);
	$string=decode('iso-8859-7',$string);
    }
    if ($lang=~/^tr$/){
	decode_entities($string);
	$string=decode('iso-8859-9',$string);
    }
    return $string;
}



#------------------------------------------------------
# CorpusQueryForm: show the query form
#

sub CorpusQueryForm{
    my ($corpus,$lang,$advanced)=@_;

    if (not $corpus){return;}
    if (not $lang){return;}

    my %index=%corpora;
    my $form= &startform();


    #---------------------------------------------------
    # cqp-query-field

    my $query.=&textfield(-size=>'30',-name => 'query',
		       -default=>'[word="a.*"]');

    #---------------------------------------------------
    # checkboxes for word attributes

    my $pattr=undef;
    if (ref($corpora{$corpus}{$lang}{attr}) eq 'ARRAY'){
	my @attr=sort grep ($_ ne 'word',@{$corpora{$corpus}{$lang}{attr}});
	$pattr.=&checkbox_group(-name=>'attr',
				-values=>('word'),
				-default=>('word'));
	$pattr.=&checkbox_group(-name=>'attr',
				-values=>\@attr);
    }

    #---------------------------------------------------
    # checkboxes for structural attributes

    my $sattr=undef;
    if (ref($corpora{$corpus}{$lang}{struc}) eq 'HASH'){
	my @struc=sort keys %{$corpora{$corpus}{$lang}{struc}};
	foreach (sort @struc){
	    $sattr.=&checkbox_group(-name=>'attr',-values=>($_));
	    my @strucattr=sort @{$corpora{$corpus}{$lang}{struc}{$_}};
	    $sattr.=&checkbox_group(-name=>'attr',-values=>\@strucattr);
	    $sattr.=&br();
	}
    }

    #---------------------------------------------------
    # context window

    my $context=undef;
    my @struc=('s');
    if (ref($corpora{$corpus}{$lang}{struc}) eq 'HASH'){
	@struc=sort keys %{$corpora{$corpus}{$lang}{struc}};
    }

    $context.=&popup_menu(-name=> 'bcs',
			  -default => '1',
			  -values => [1,2,3,4,5]);
    $context.=&popup_menu(-name=> 'bc',
			-default => 's',
			-values => \@struc);
    $context.=&popup_menu(-name=> 'acs',
			-default => '1',
			-values => [1,2,3,4,5]);
    $context.=&popup_menu(-name=> 'ac',
			-default => 's',
			-values => \@struc);


    #---------------------------------------------------
    # checkboxes (and input fields) for sentence aligned corpora

    my $align=undef;
    if (ref($index{$corpus}{$lang}{align}) eq 'ARRAY'){
	my @lang=sort @{$index{$corpus}{$lang}{align}};
	my $nr_col=sqrt(@lang);
	my @rows=();
	my $i=1;
	my $nr_rows=0;
	foreach my $l (sort @{$index{$corpus}{$lang}{align}}){
	    $rows[$nr_rows].=
		&td({-nowrap=>'1'},
		    [&checkbox_group(-name=>'alg',-values=>($l))]);
#	    if ($advanced){
		$rows[$nr_rows].=
		    &td([&textfield(-size=>'10',-name => 'query_'.$l)]);
#	    }
	    $i++;
	    if ($i>$nr_col){$nr_rows++;$i=1;}
	}
	$align.=&table({-cellspacing=>"0"},caption(''),&Tr(\@rows));
    }

    #---------------------------------------------------
    # display styles

    my @styles=('vertical','KWIC');
    if (defined ($align)){push(@styles,'horizontal');}
    my $style=&radio_group(-name=>'style',
			   -values=>\@styles);

    #---------------------------------------------------
    # max number of hits

    my $show='show max '.&textfield(-size=>'4',
				    -default=>"$SHOWMAX",
				    -name => 'showmax').' hits';
    if (defined $align){
	$show.=' and ';
	$show.=&checkbox(-name=>'skipnoalign',
			  -checked=>'checked',
			  -value=>'skip',
			  -label=>'skip non-aligned segments');
    }

    #---------------------------------------------------
    # submit-query-button and other stuff

    my $submit=&p().&submit(-name => 'action',-value => 'select');
    $submit.= ' '.$show.$style;
    my $link=url();
    $link=&AddUrlParam($link,'c',$corpus);
    $link=&AddUrlParam($link,'s',$lang);
#    if ($advanced){
#	$link=&AddUrlParam($link,'adv','0');
#	$submit.=&br().'('.&a({-href=>$link},'simple').' search)';
#    }
#    else{
#	$link=&AddUrlParam($link,'adv','1');
#	$submit.=&br().'('.&a({-href=>$link},'advanced').' search)';
#    }


    #---------------------------------------------------
    # put everything together

    my @rows=();

    if ($advanced){
	my $header=&a({-href=>$CQPSYNTAX},'CQP query').' ';
	$header.=&a({-href=>$CWBLINK},'(CWB)');
	push (@rows,&th([$header,'show attributes']));
	push (@rows,&td([&p().'query: '.$query.
			 &p().'context: '.$context,
			 $PATTRtext.&br().$pattr.&p().
			 $SATTRtext.&br().$sattr]));
	push (@rows,&th({-colspan=>'2'},'alignments'));
	push (@rows,&td({-colspan=>'2'},$align));
	push (@rows,&td({-colspan=>'2'},$submit));
	$form.=&table({-cellspacing=>"0"},caption(''),&Tr(\@rows));
    }
    else{
	my $header=&a({-href=>$CQPSYNTAX},'CQP query').' ';
	$header.=&a({-href=>$CWBLINK},'(CWB)');
	push (@rows,&th([$header,'show attributes']));
	if ($align){$rows[-1].=&th(['alignments'])};
	push (@rows,&td([$CQPtext.&p().$query,
			 $PATTRtext.&p().$pattr.&p().
			 $SATTRtext.&br().$sattr,
			 $align.&br()]));
	push (@rows,&td({-colspan=>'3'},$submit));
	$form.=&table({-cellspacing=>"0"},caption(''),&Tr(\@rows));
    }

    $form.= &endform();
    return &div({-class=>'query'},$form);
}



#-----------------------------------------------------------
# CorpusQuery: run the corpus query using WebCqp


sub CorpusQuery{

    my ($corpus,$lang,$cqp,$aligned,$style)=@_;

    $WebCqp::Query::Registry = $corpus;
    my $query;
    eval { $query = new WebCqp::Query("$lang"); };
    if ($@){print "--$@--$!--$?--";}

    #---------------------------------------------------------

    $query->on_error(sub{grep {print "$_".&br()} @_});
    my @corpora=($lang);

    my ($bc,$bcs,$ac,$acs)=('s',1,'s',1);
    if (param('bc')){$bc=param('bc');}         # before context
    if (param('bcs')){$bcs=param('bcs');}      # before context size
    if (param('ac')){$ac=param('ac');}         # after context
    if (param('acs')){$acs=param('acs');}      # after context size

    if ($style ne 'KWIC'){
	$query->context("$bcs $bc", "$acs $ac");
    }
    if ($cqp!~/^[\"\[]/){$cqp='"'.$cqp.'"';}

    #---------------------------------------------------------
    # check queries for each alignment

    if (ref($aligned) eq 'ARRAY'){
	$query->alignments(sort @{$aligned});
	push (@corpora,@{$aligned});
	foreach (@{$aligned}){
	    if (param("query_$_")){
		my $l=uc($_);
		$cqp.=" :$l ".param("query_$_");
	    }
	}
    }

    #---------------------------------------------------------
    # show certain attributes

    if (defined param('attr')){
	my @attr=param('attr');
	$query->attributes(@attr);
    }

    #---------------------------------------------------------
    # run the query
    $query->reduce($SHOWMAX);
    my @result=();
    local $SIG{ALRM}=\&timeout;
    eval {
	alarm ($MAXWAIT);
	@result = $query->query($cqp);
	alarm 0;
    };
    my $nr_result = @result;
    #---------------------------------------------------------

    my $html="Query string: \"$cqp\"".&br();
    $html.="<b>$nr_result</b> hits found";

    my @rows=();
    if ($style eq 'vertical'){
	push (@rows,&th(['',@corpora]));
    }

    my $skipnoalign=param('skipnoalign');
    my $nr;my $i;
    for ($i = 0; $i < $nr_result; $i++) {
	$nr = $i + 1;
	my $m = $result[$i];
	my $pos = $m->{'cpos'};
	my $ord = &FixString($lang,$m->{'kwic'}->{'match'});
	my $res_r = &FixString($lang,$m->{'kwic'}->{'right'});
	my $res_l = &FixString($lang,$m->{'kwic'}->{'left'});
	my $noalign=0;
	my @newrows=();
	if ($style eq 'KWIC'){                       # KWIC style
	    push (@newrows,
		  &td({},[$pos]).
		  &td({-align=>'right'},[$res_l]).
		  &td({-align=>'center'},["<b>$ord</b>"]).
		  &td({},[$res_r]));
	}
	else{
	    push (@newrows,&td({},[$pos,"$res_l <b>$ord</b> $res_r"]));
	}

	#----------------------------
	# aligned regions

	if (ref($aligned) eq 'ARRAY'){
	    my $even=0;
	    foreach (@{$aligned}){
		my $color='#FFEEDD';                 # align-color 1
		if ($even){$color='#FFFFE0';}        # align-color 2
#		my $color='#FFFF99';                 # align-color 1
#		if ($even){$color='#FFCC99';}        # align-color 2
		$even=not $even;
		if ($m->{$_}=~/\(no alignment found\)/){$noalign++;}
		my $string=&FixString($_,$m->{$_});
		if ($style eq 'vertical'){           # vertical alignment
		    $newrows[-1].=&td({-valign=>'top'},$string);
		}
		elsif ($style eq 'KWIC'){            # KWIC style
		    push (@newrows,
			  &th({},[$_]).
			  &td({-bgcolor=>$color,
			       -colspan=>"3",
			       -align=>'center'},[$string]));
		}
		else{                                # horizontal alignment
		    push (@newrows,
			  &th({},[$_]).
			  &td({-bgcolor=>$color},[$string]));
		}
	    }
	}
	if ((not $skipnoalign) or (not $noalign)){
	    push (@rows,@newrows);
	}
	if ($nr>=$SHOWMAX){last;}
    }
    $html.=&table({-cellspacing=>'0'},caption(''),&Tr(\@rows));
    return &div({-class=>'result'},$html);
}


#--------------------------------------------------
# create a table of registry links
# (create links for each corpus)


sub RegisteryLinks{
    my $corpora=shift;
    my $url=shift;

    my @rows=(&th({},['corpus&nbsp;','&nbsp;languages&nbsp;']));
    my %trans=();
    foreach my $c (sort keys %{$corpora}){
	my $link=&AddUrlParam($url,'c',$c);
	my $html='';
	foreach my $l (sort keys %{$$corpora{$c}}){
	    my $link=&AddUrlParam($link,'s',$l);
	    $html.=&a({-href=>$link},$l).' ';
	    $trans{$l}{$c}=$link;
	}
	push (@rows,&td({},[$c,$html]));
    }
    return &div({-class=>'registry'},
		&table({-cellpadding=>"0"},caption(''),&Tr(\@rows)));
}


#-----------------------------------------
# add a URL-style parameter to the CGI-URL

sub AddUrlParam{
    my ($url,$name,$val)=@_;
    $val=escape($val);
    if ($url!~/[\?\;]$name\=/){
	if ($url!~/\?/){$url.="\?$name=$val";}
	else{$url.="\;$name=$val";}
    }
    else{$url=~s/$name\=[^\;]*(\;|\Z)/$name=$val$1/;}
    return $url;
}


#-----------------------------------------
# read all registry files
#    directory=corpus
#    language=registry-file

sub ReadRegistry{
    my $dir=shift;
    my $reg=shift;
    opendir(DIR, $dir) or die "Can't open it: $!\n";
    my @files= readdir(DIR);
    foreach my $f (@files){
	if ($f=~/^\./){next;}
	if (-d $dir.'/'.$f){
	    my $subdir=$dir.'/'.$f;
	    $subdir=~s/^\.\///;                # delete './'
	    &ReadRegistry($subdir,$reg);
	}
	if (-f $dir.'/'.$f && ! -l $dir.'/'.$f){
	    $NRCORPORA++;
	    $$reg{$dir}{$f}={};
	    open F,"<$dir/$f";
	    my @text=<F>;
	    close F;
	    foreach (@text){
		if (/ATTRIBUTE\s(.*)$/){
		    push (@{$$reg{$dir}{$f}{attr}},$1);
		}
		if (/STRUCTURE\s(.*)$/){
		    my $struc=$1;
		    if ($struc=~/^(\S+)\_(\S+)(\s|\Z)/){
			push (@{$$reg{$dir}{$f}{struc}{$1}},"$1_$2");
		    }
		    else{
			@{$$reg{$dir}{$f}{struc}{$struc}}=();
		    }
		}
		if (/ALIGNED\s(.*)$/){
		    push (@{$$reg{$dir}{$f}{align}},$1);
		}
	    }
	}
    }
}

#-----------------------------------------
# print timeout-message and die!

sub timeout{
    print &h2("Your query took more than $MAXWAIT seconds!");
    print "The process has been timed out!",&br();
    print "Possible reasons:<ul>";
    print "<li>The server is busy</li>";
    print "<li>Your query is very complicated</li>";
    print "</ul>";
    print "try<ul>";
    print "<li>another (simple) query</li>";
    print "<li>to reduce the number of results (show max)</li>";
    print "<li>to run queries without aligned regions</li>";
    print "</ul>";
    print "Sorry for any inconvenience!",&hr();
    print &end_html;
    exit;
}

############################################################################
############################################################################
############################################################################
############################################################################
############################################################################
############################################################################
############################################################################
############################################################################


1;
