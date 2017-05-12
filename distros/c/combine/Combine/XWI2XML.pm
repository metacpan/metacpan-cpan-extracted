package Combine::XWI2XML;

use strict;
use Combine::XWI;
use Encode;
use Combine::Config;
use Compress::Zlib;
use MIME::Base64;

my $level=0; #Used to calculate indentation for pretty printing

our %dcMap;
   %dcMap = (
            'rights' => 'dc:rights',
            'coverage' => 'dc:coverage',
            'creator' => 'dc:creator',
            'content' => 'dc:description',
            'geo.country' => 'dc:coverage',
            'email' => 'dc:publisher',
            'language' => 'dc:language',
            'identifier-url' => 'dc:identifier',
            'timemodified' => 'dc:date',
            'copyright' => 'dc:rights',
            'classification' => 'dc:subject',
            'url' => 'dc:identifier',
            'timecreated' => 'dc:date',
            'category' => 'dc:subject',
            'description' => 'dc:description',
            'location' => 'dc:coverage',
            'originator' => 'dc:creator',
            'subject' => 'dc:subject',
            'author' => 'dc:creator',
            'publisher' => 'dc:publisher',
            'pd' => 'dc:date',
            'publisher-email' => 'dc:publisher',
            'abstract' => 'dc:description',
            'documenttype' => 'dc:type',
            'doc-rights' => 'dc:rights',
            'page-topic' => 'dc:subject',
            'topicname' => 'dc:subject',
            'keyword' => 'dc:subject',
            'document-rights' => 'dc:rights',
            'keywords' => 'dc:subject',
            'resource-type' => 'dc:type',
            'summary' => 'dc:description',
            'creation-date' => 'dc:date',
            'type' => 'dc:type',
            'document-classification' => 'dc:subject',
            'country' => 'dc:coverage',
            'progid' => 'dc:format',
            'content-language' => 'dc:language',
            'content-type' => 'dc:format',
            'title' => 'dc:title',
            'created' => 'dc:date',
            'timemodified' => 'dc:date',
            'doc-type' => 'dc:type',
            'mimetype' => 'dc:type'
            );

##########################SUBS########################

sub XWI2XML {
    my ($xwi, $inclHTML, $inclCanonDoc, $collapseinLinks, $nooutLinks) = @_;
    my $recordid=$xwi->recordid;
    my $Rsummary = '';
    my $md5 = $xwi->md5;
    my $res = StartTag("documentRecord md5id=\"$md5\" id=\"$recordid\"");

    $res .= ToXML('modifiedDate', time2iso($xwi->modifiedDate));
    $res .= ToXML('expiryDate', time2iso($xwi->expiryDate));
    $res .= ToXML('checkedDate', time2iso($xwi->checkedDate));
    $res .= ToXML('mimeType', $xwi->type);
    $res .= ToXML('httpServer', $xwi->server);
#urls
    #?    $xwi->url_rewind;
    $res .= StartTag('urls');
    my $sv = Combine::Config::Get('MySQLhandle');
    my $sth = $sv->prepare(qq{SELECT urlstr from urls,recordurl WHERE recordurl.recordid=? AND recordurl.urlid=urls.urlid;});
    my $rv = $sth->execute($recordid);
    my $urlstr;
    my %servers=();
    while (($urlstr)=$sth->fetchrow_array) {
	$res .= ToXML('url',$urlstr);
	$urlstr =~ s|http://([^/:]+).*|$1|;
	$servers{$urlstr}=1; 
    }
    $res .= EndTag('urls');

	$res .= StartTag('servers');
        foreach my $s (keys(%servers)) { $res .= ToXML('server',$s); }
	$res .= EndTag('servers');

#originalDoc
    if ($inclHTML) {
        my $base64=MIME::Base64::encode(Compress::Zlib::memGzip(${$xwi->content}));
        $res .= '<originalDocument mimeType="text/html" compression="gzip" encoding="base64" charSet="UTF-8">' . "\n" . $base64 . '</originalDocument>' . "\n";
    }
#documentText
    my $ok = 1;
    if ($inclCanonDoc) {
        my $html = ${$xwi->content};
        if (length($html) > 10) {
            $html =~ s/<!DOCTYPE[^>]+>//;
            $html =~ s/&nbsp;/ /g;
            my ($canonicalDoc,$errs);
            require Combine::CleanXML2CanDoc;
            my $converter = Combine::CleanXML2CanDoc->new('indentation'=>2);
            ($ok,$canonicalDoc,$errs) = $converter->convert($html);
            if ($ok == 0) { $res .= $canonicalDoc . "\n"; } #if conversion OK save resul
        }
    } 
    if ( (!$inclCanonDoc) || ($ok != 0) ) { #fallback if conversion fails
      $res .= StartTag('canonicalDocument');
      $res .= ToXML('section', ${$xwi->text}); 
      $res .= EndTag('canonicalDocument');
    }

#meta
    $xwi->meta_rewind;
    $res .= StartTag('metaData');
    my $tit= $xwi->title;
    $res .= ToXMLAttr('meta',"name=\"title\"", $tit);
    if ( !defined($tit) || $tit =~ /^\s*$/ ) {
      #Empty title => generate title from text and 1st heading
      my @ip = split(/\s+/,substr(${$xwi->text},0,100),5);
      my ($head,$t) = split(/;/, $xwi->heading_get, 2);
      my $ip = join(' ', $ip[0], $ip[1], $ip[2], $ip[3]);
#      if ( $ip =~ /$head/ ) { $res .= ToXMLAttr('meta',"name=\"title\"", $ip); }
#      else  { $res .= ToXMLAttr('meta',"name=\"title\"", $head . ' ' . $ip); }
       $res .= ToXMLAttr('meta',"name=\"title\"", $head . ' ' . $ip);
    }
    my ($name,$content);
    while (1) {
	($name,$content) = $xwi->meta_get;
	last unless $name;
	if ( $name eq 'Rsummary' ) {
	    $Rsummary = $content;
	    next;
	}
        $name =~ s/"/ /g;
        $name = encodeXML($name);

          if (($name =~ /^dc\./)) {
            $name =~ s/^dc\.\s*/dc:/;
            my $t;
            ($name,$t) = split('\.', $name, 2);
            if ($name =~ /subject/) { $res .= DCsubj($name,$content); }
            else { $res .= ToXMLAttr('meta', "name=\"$name\"", $content); }
          } elsif ( defined($dcMap{$name}) ) {
            if ($dcMap{$name} =~ /subject/) { $res .= DCsubj($dcMap{$name},$content); }
            else { $res .= ToXMLAttr('meta', "name=\"$dcMap{$name}\"", $content); }
          }
#          else { $res .= ToXMLAttr('meta', "name=\"$name\"", $content); } #????????
    } 
    $res .= EndTag('metaData');

# links
    $res .= StartTag('links');
    $res .= StartTag('outlinks');
    $xwi->link_rewind;
    my $antImgLinks=0;
    my ($netlocid, $urlid, $anchor, $ltype, $lmd5);
    $sth = $sv->prepare(qq{SELECT urlstr FROM urls WHERE urls.urlid=?;});
    my $sth1 = $sv->prepare(qq{SELECT md5 FROM recordurl WHERE urlid=?;});
    my %seen = ();
#    while (1) {
    while (!$nooutLinks) {
	($urlstr, $netlocid, $urlid, $anchor, $ltype) = $xwi->link_get;
	last unless ($urlstr || $netlocid);
	if ( $urlstr eq '' ) {
	    $rv = $sth->execute($urlid);
	    ($urlstr)=$sth->fetchrow_array;
	}

           next if (defined($seen{$urlstr,$anchor}));
           $seen{$urlstr,$anchor}=1;

	$res .= StartTag('link' . " type=\"$ltype\"");
	$rv = $sth1->execute($urlid);
	($lmd5)=$sth1->fetchrow_array;
        #    $res .= ToXML('linkurl', $urlstr . '; ' . $urlid); #Keep? Attribute?
	$res .= ToXML('anchorText', $anchor);
	if (defined($lmd5)) {
	    $res .= ToXMLAttr('location', "documentId=\"$lmd5\"", $urlstr);
	} else {
	    $res .= ToXML('location', $urlstr);
	}
	if ($ltype eq 'img') { $antImgLinks++; }
	$res .= EndTag('link');
    }
    $res .= EndTag('outlinks');
    #anchors from other pages linking to this page
    my $from;
    $sth = $sv->prepare(qq{SELECT urlstr,anchor,md5,linktype from links,urls,recordurl WHERE links.urlid=? AND links.recordid=recordurl.recordid AND recordurl.urlid=urls.urlid;});
    $rv = $sth->execute($xwi->urlid);
    if ( $rv >= 1 ) {
        %seen = ();
        my @internalLinks =();
        my %inlinkHosts;
	$res .= StartTag('inlinks');
	my $atmp;
	while (($from,$atmp,$lmd5,$ltype)=$sth->fetchrow_array) {
            $anchor = Encode::decode('utf8',$atmp);
	    next if ( defined($seen{$from,$anchor}) || ($anchor eq '') || defined($seen{$anchor}) );
	    $seen{$from,$anchor}=1;
	    if ($collapseinLinks) {
		$seen{$anchor}=1;
	    }
	    my $s = $from;
	    $s =~ s|http://([^/:]+).*|$1|;
	    if (defined($servers{$s})) {#from same server as page, just save and put last in list
		my $tres = StartTag('link' . " type=\"$ltype\"");
		$tres .= ToXML('anchorText',$anchor);
		$tres .= ToXMLAttr('location', "documentId=\"$lmd5\"", $from);
		$tres .= EndTag('link');
		push(@internalLinks,$tres);
		next;
	    }
            $inlinkHosts{$s}=1;
            $res .= StartTag('link' . " type=\"$ltype\"");
	    $res .= ToXML('anchorText',$anchor);
	    $res .= ToXMLAttr('location', "documentId=\"$lmd5\"", $from);
	    $res .= EndTag('link');
	}
        $res .= join('',@internalLinks);
	$res .= EndTag('inlinks');
        my $no =  scalar(keys %inlinkHosts);
	if (defined($no) && $no>0) {$res .= ToXML('inlinkHosts', $no);}
    }
    $res .= EndTag('links');

# analysis
      $xwi->heading_rewind;
      $res .= ToXML('headings', $xwi->heading_get); # Only one cumulative heading stored in database
      $res .= ToXML('Rsummary',$Rsummary);

#analys - robot
    $xwi->robot_rewind;
    while (1) {
	($name,$content) = $xwi->robot_get;
	last unless $name;
        next if ( ($name eq 'hostinlinks') || ($name eq 'inlinks') ||
                  ($name eq 'outlinks') || ($name eq 'charsetlist') );
	if ( $name eq 'domain' ) { $name = 'topLevelDomain'; }
        $name =~ s/"/ /g;
	$res .= ToXMLAttr('property', "name=\"$name\"", $content);
    } 

    #topic
    $xwi->topic_rewind;
    my ($cls,$absscore, $relscore, $terms);
    while (1) {
	($cls,$absscore, $relscore,$terms) = $xwi->topic_get;
	last unless $cls;
	$res .= StartTag('topic' . " absoluteScore=\"$absscore\" relativeScore=\"$relscore\"");
	$res .= ToXML('class', $cls);
#	$res .= ToXML('terms', $terms);
        my %seen;
        foreach my $t (split(',\s*',$terms)) {
          $t =~ s/\\.//g;
          $t =~ tr/\?\*\^\[\]//d;
          # remove trailing 's' (OK?) and replace '@and' with ','
          $t = join(', ', map {s/s$//;$_} split(' @and ', $t) );
          next if (defined($seen{$t}));
	  $res .= ToXML('terms', $t);
          $seen{$t}=1;
        }
	$res .= EndTag('topic');
    } 

    $res .= EndTag('documentRecord');

    return $res;
}

sub DCsubj {
    my ($name,$val) = @_;
    my $frag = '';
    foreach my $t (split(',\s*',$val)) {
          $frag .= ToXMLAttr('meta', "name=\"$name\"", $t);
    }
    return $frag;
}

sub ToXML {
    my ($name,$val) = @_;
    return '' if ( !defined($val) || $val =~ /^\s*$/ );
    #XMLify tag-name
    $name =~ tr/0-9a-zA-Z:_\-./_/c;
    if ($name =~ /^\d/) { $name='_' . $name; }
    #XMLify val!!
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ tr/[\x00-\x08\x0B\x0C\x0E-\x1F]/ /s;
    return &prefix()."<$name>$val</$name>\n";
}

sub ToXMLAttr {
    my ($name,$attr,$val) = @_;
    return '' if ( !defined($val) || $val =~ /^\s*$/ );
    #XMLify tag-name
    $name =~ tr/0-9a-zA-Z:_\-./_/c;
    if ($name =~ /^\d/) { $name='M' . $name; }
    #XMLify val!!
    $val =~ s/&/&amp;/sg;
    $val =~ s/</&lt;/sg;
    $val =~ s/>/&gt;/sg;
#    $val =~ tr/ -	-\^/ /;
    $val =~ tr/[\x00-\x08\x0B\x0C\x0E-\x1F]/ /s;
    return &prefix()."<$name $attr>$val</$name>\n";
}

sub encodeXML {
    my ($val)=@_;
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ tr/[\x00-\x08\x0B\x0C\x0E-\x1F]/ /s;
    return $val;
}

sub normalizeName {
#Names and Tokens
#    [4]   NameStartChar   ::=   ":" | [A-Z] | "_" | [a-z] | [#xC0-#xD6] | [#xD8-#xF6] | [#xF8-#x2FF] | [#x370-#x37D] | [#x37F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] | [#x10000-#xEFFFF]
#    [4a]   NameChar   ::=   NameStartChar | "-" | "." | [0-9] | #xB7 | [#x0300-#x036F] | [#x203F-#x2040]
}

sub prefix {
    my $prefix='';
    foreach my $i (1..$level) { $prefix.='  '; }
    return $prefix;
}
sub StartTag {
    my ($name) = @_;
    my $str = &prefix() . "<$name>\n";
    $level++;
    return $str;
}
sub EndTag {
    my ($name) = @_;
    $level--;
    my $str = &prefix() . "</$name>\n";
    return $str;
}
sub XMLtext {
    my ($name) = @_;
    if ( $name eq '' ) { return ''; }
    else { return &prefix() . "$name\n"; }
}

sub time2iso {
    my ($t) = @_;
    if ($t) {
	my @t = gmtime($t);
	$t[5] = 1900 + $t[5]; #year
	$t[4] = $t[4] + 1;    #month
	foreach my $i (4,3,1,0) { if ($t[$i]<10) { $t[$i] = "0$t[$i]"; } }
	return join('-',($t[5],$t[4],$t[3])) . ' ' . join(':',($t[2],$t[1],$t[0]));
    } else { return ''; }
}

########################################
1;
