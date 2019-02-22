#!/usr/bin/perl -w

my $xmlbase='';
my $outbuf='';

my $sElt = 's';

my $isW = 0;

our $indentRoot = "\n";
our $indentS   = "\n  ";
our $indentW   = "\n    ";
our $indentW1  = "\n      ";
our $indentW2  = "\n        ";
our $indentW3  = "\n          ";
our $indentW4  = "\n            ";

sub xmlstr {
  my $s = shift;
  $s =~ s/\&/&amp;/g;
  $s =~ s/\</&lt;/g;
  $s =~ s/\>/&gt;/g;
  $s =~ s/\"/&quot;/g;
  $s =~ s/\'/&apos;/g;
  return $s;
}

while (<>) {
  chomp;
  if (/^\%\% xml\:base=(.*)$/) {
    $xmlbase=xmlstr($1);
    next;
  }
  elsif (/^\%\% Sentence (.*)$/) {
    $outbuf .= "${indentS}<$sElt id=\"".xmlstr($1)."\">" if (!$isS);
    $isS = 1;
    next;
  }
  elsif (/^\%\%/) {
    next;
  }
  elsif (/^$/) {
    $outbuf .= "${indentS}</$sElt>" if ($isS);
    $isS = 0;
    next;
  }
  elsif (!$isS) {
    ##-- maybe open new sentence
    $outbuf .= "${indentS}<$sElt>";
    $isS = 1;
  }

  ($wtext,$wfields) = split(/\t/,$_,2);
  ($wloc,$wid,$wchars) = ('','','');
  ($wxlit, $wmsafe, $wlts, $weqpho, $wmorph, $wmlatin, @wrw, @rwlts, @rwmorph, $wa) = qw();
  foreach (split(/\t/,$wfields)) {
    if (/^(\d+ \d+)/ || /^\[loc\] (\d+ \d+)/) {
      $wloc = $1;
    }
    elsif (/^\[xmlid\] (.*)/) {
      $wid = $1;
    }
    elsif (/^\[chars\] (.*)/) {
      $wchars = $1;
    }
    elsif (/^\[xlit\] l1=(\S*) lx=(\S*) l1s=([^\t]*)/) {
      $wxlit = "<xlit t=\"".xmlstr($3)."\" isLatin1=\"$1\" isLatinExt=\"$2\"/>";
    }
    elsif (/^\[lts\] (.*?)(?: \<([^\>]*)\>)?$/) {
      $wlts .= "${indentW2}<a hi=\"".xmlstr($1)."\" w=\"".(defined($2) ? xmlstr($2) : '')."\"/>";
    }
    elsif (/^\[morph\] (.*?)(?: \<([^\>]*)\>)?$/) {
      $wmorph .= "${indentW2}<a hi=\"".xmlstr($1)."\" w=\"".(defined($2) ? xmlstr($2) : '')."\"/>";
    }
    elsif (/^\[morph\/lat?\] (.*?)(?: \<([^\>]*)\>)?$/) {
      $wmlatin .= "${indentW2}<a hi=\"".xmlstr($1)."\" w=\"".(defined($2) ? xmlstr($2) : '')."\"/>";
    }
    elsif (/^\[eqpho\] (.*)/) {
      $weqpho .= "${indentW2}<a t=\"".xmlstr($1)."\"/>";
    }
    elsif (/^\[morph\/safe\] (.*)/) {
      $wmsafe .= "<msafe safe=\"$1\"/>";
    }
    elsif (/^\[rw\] (.*?)(?: \<([^\>]*)\>)?$/) {
      push(@wrw,"<a hi=\"".xmlstr($1)."\" w=\"".(defined($2) ? xmlstr($2) : '')."\">");
    }
    elsif (/^\[rw\/lts\] (.*?)(?: \<([^\>]*)\>)?$/) {
      $rwlts[$#wrw]   .= "${indentW4}<a hi=\"".xmlstr($1)."\" w=\"".(defined($2) ? xmlstr($2) : '')."\"/>";
    }
    elsif (/^\[rw\/morph\] (.*?)(?: \<([^\>]*)\>)?$/) {
      $rwmorph[$#wrw] .= "${indentW4}<a hi=\"".xmlstr($1)."\" w=\"".(defined($2) ? xmlstr($2) : '')."\"/>";
    }
    else {
      $wa .= "${indentW1}<a>".xmlstr($_)."</a>";
    }
  }

  ##-- append xml-ified token to buffer
  $outbuf .=
    (''
     .$indentW."<w id=\"".xmlstr($wid)."\" t=\"".xmlstr($wtext)."\" b=\"$wloc\" c=\"$wchars\">"
     .(defined($wxlit) ? ($indentW1.$wxlit) : '') #"$indentW1<xlit/>"
     .(defined($wlts)    ? ($indentW1."<lts>${wlts}${indentW1}</lts>") : '') #"$indentW1<lts/>"
     .(defined($weqpho)  ? ($indentW1."<eqpho>${weqpho}${indentW1}</eqpho>") : '') #"$indentW1<eqpho/>"
     .(defined($wmorph)  ? ($indentW1."<morph>${wmorph}${indentW1}</morph>") : '') #"$indentW1<morph/>"
     .(defined($wmlatin) ? ($indentW1."<mlatin>${wmlatin}${indentW1}</mlatin>") : '') #"$indentW1<mlatin/>"
     .(defined($wmsafe)  ? ($indentW1.$wmsafe) : '') #"<msafe/>"
     .(@wrw
       ? ($indentW1.'<rewrite>'
	  .join('',
		map {
		  ($indentW2.($wrw[$_]||'<a>')
		   .$indentW3.(defined($rwlts[$_])   ? ("<lts>$rwlts[$_]${indentW3}</lts>") : "<lts/>")
		   .$indentW3.(defined($rwmorph[$_]) ? ("<morph>$rwmorph[$_]${indentW3}</morph>") : "<morph/>")
		   .$indentW2."</a>")
		} (0..$#wrw))
	  .$indentW1.'</rewrite>'
	 )
       : '') #($indentW1."<rewrite/>")
     .(defined($wa) ? $wa : '')
     .$indentW."</w>"
    );
}

print
  ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
   $indentRoot, "<sentences xml:base=\"$xmlbase\">",
   $outbuf,
   $indentRoot, "</sentences>",
   "\n",
  );
