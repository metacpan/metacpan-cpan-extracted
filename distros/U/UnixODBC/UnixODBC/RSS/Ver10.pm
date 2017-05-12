package UnixODBC::RSS::Ver10;

# $Id: Ver10.pm,v 1.13 2008-01-21 09:16:56 kiesling Exp $

my $VERSION=0.04;

my %rsstags = ('open' => "<rdf:RDF\n" .
	       "xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\n" .
	       'xmlns="http://purl.org/rss/1.0/">', 
	       'open_sy' => "<rdf:RDF\n" .
	       "xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\n" .
               "xmlns:sy=\"http://purl.org/rss/1.0/modules/syndication/\"\n" .
	       'xmlns="http://purl.org/rss/1.0/">', 
	       'close' => '</rdf:RDF>');

sub rssopen { return $rsstags{'open'}; }

sub rssopen_sy { return $rsstags{'open_sy'}; }

sub rssclose { return $rsstags{'close'}; }

my $channeltags = {open => '<channel rdf:about="">',
		   close => '</channel>',
		   titleopen => '<title>',
		   titleclose => '</title>',
		   descriptionopen => '<description>',
		   descriptionclose => '</description>',
		   linkopen => '<link>',
		   linkclose => '</link>'};

sub channeltagsref {return $channeltags;}

my $imagetags = {open => '<image rdf:about="">',
	       close => '</image>',
	       titleopen => '<title>',
	       titleclose => '</title>',
	       urlopen => '<url>',
	       urlclose => '</url>',
	       linkopen => '<link>',
	       linkclose => '</link>'};

sub imagetagsref { return $imagetags; }

my $itemtags = {open => '<item>',
		close => '</item>',
		titleopen => '<title>',
		titleclose => '</title>',
		nameopen => '<name>',
		nameclose => '</name>',
		descriptionopen => '<description>',
		descriptionclose => '</description>',
		linkopen => '<link>',
		linkclose => '</link>'};

sub itemtagsref { return $itemtags; }

my $syntags = {'updatePeriodopen' => '<sy:updatePeriod>',
		'updatePeriodclose' => '</sy:updatePeriod>',
		'updateFrequencyopen' => '<sy:updateFrequency>',
		'updateFrequencyclose' => '</sy:updateFrequency>',
		'updateBaseopen' => '<sy:updateBase>',
		'updateBaseclose' => '</sy:updateBase>'};

sub syntagsref { return $syntags; }

sub __rdf_about {
    my $tag = $_[0];
    my $res = $_[1];
    my $res2 = __required_entities ($res);
    my $s = $tag;
    $s =~ s"\"\""\"$res2\"";
    return $s;
}

sub __required_entities {
    my $s = $_[0];

    $s =~ s/\&/\&amp\;/g;
    $s =~ s/\</\&lt\;/g;
    $s =~ s/\>/\&gt\;/g;

    return $s;
}

sub channel_as_str { 
    my $self = shift;
    my $resultref = $_[0];

    my $b;
    my $s = '';
    my $c = $self -> channeltagsref;
    my $i = $self -> itemtagsref;
    my $y = $self -> syntagsref;

    if (! defined ($self -> {columnheadings})) {
	warn "column headings not defined.\n";
    }

    my $colheadref = $self -> {columnheadings};

    my $c1 = __rdf_about ($c -> {open}, $self -> {channel}{link});
    $s .= "  " . $c1 . "\n";

    foreach my $t (qw/title description link/) {
	$b = __required_entities ($self -> {channel}{$t});
	$s .= "    " . 
	    $c->{"${t}open"}.$b.$c -> {"${t}close"}."\n";
    }

    if (exists $self -> {syn}) {
	foreach my $t (qw/updatePeriod updateFrequency updateBase/) {
	    $b = __required_entities ($self -> {syn}{$t});
	    $s .= "    " . 
		$y->{"${t}open"}.$b.$y -> {"${t}close"}."\n";
	}
    }

    if (defined ($self -> {channelimage})) {
	my $url = $self -> {channelimage}{url};
	$s .=  qq{    <image rdf:resource="$url" />\n};
    }

    $s .= qq {    <items>\n      <rdf:Seq>\n};
    foreach my $rref (@{$resultref}) {
	for ($cidx = 0; $cidx <= $#{$rref}; $cidx++) {
	    foreach my $ic (keys %{$self -> {itemcolumns}} ) {
		if ( $self -> {itemcolumns}{$$colheadref[$cidx]} eq 'link') {
		    local $b1 = ${$rref}[$cidx];
		    $b = __required_entities ($b1);
                }	       
	    }
        } # for
	$s .=  "        <rdf:li resource=\"$b\" />\n";
    } # foreach
    $s .= qq {      </rdf:Seq>\n    </items>\n};

    if (defined ($self -> {textinput})) {
	my $texturl = $self -> {textinput}{link};
	$s .=  qq{    <textinput rdf:resource="$texturl" />\n};
    }

    $s .=  "  ". $c -> {close} . "\n";
    return $s;
}

sub image_as_str {
    my $self = shift;

    my $im = $self -> imagetagsref;
    my $s = '';

    my $c1 = __rdf_about ($im -> {open}, $self -> {channelimage}{url});
    $s = "  " . $c1 . "\n";

    foreach my $t (qw/title url/) {
	my $b = __required_entities ($self -> {channelimage}{$t});
	$s .= "    " . 
	    $im->{"${t}open"}.$b.$im -> {"${t}close"}."\n";
    }

    $s .=  "    <link>" . __required_entities ($self -> {channel}{link}) . 
	"</link>\n";
    $s .=  "  ".$im -> {close} . "\n";

    return $s;
}

sub items_as_str {
    my $self = shift;
    my $resultref = $_[0];

    my $s = '';

    my $i = $self -> itemtagsref;

    my $colheadref = $self -> {columnheadings};

    foreach my $rref (@{$resultref}) {
	$s .=  "      " . $i -> {open} . "\n";
	for ($cidx = 0; $cidx <= $#{$rref}; $cidx++) {
	    foreach my $ic (keys %{$self -> {itemcolumns}} ) {
		if ($$colheadref[$cidx] eq $ic) {
		    local $s1 = $self -> {itemcolumns}{$ic};
		    my $b = __required_entities (${$rref}[$cidx]);
		    $s .=  "        ". $i -> {"${s1}open"} . $b .
                      $i -> {"${s1}close"} . "\n";
		}
	    }
        }
	$s .=  "      " . $i -> {close} . "\n";
    } # foreach

return $s;
}

sub textinput_as_str {
    my $self = shift;

    my $s = '';

    $s .= '    <textinput rdf:about="' . $self -> {textinput}{link} . "\">\n" .
	'      <title>' . $self -> {textinput}{title} . "</title>\n" .
	'      <name>' . $self -> {textinput}{name} . "</name>\n" .
	'      <link>'. $self -> {textinput}{link}."</link>\n" .
	"    </textinput>\n";
    
    return $s;
}

1;
