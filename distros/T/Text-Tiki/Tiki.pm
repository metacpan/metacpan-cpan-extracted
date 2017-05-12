#
# Copyright 2003-4 Timothy Appnel.
# This code is released under the Artistic License.
#

package Text::Tiki;

use strict;

use vars qw( $VERSION );

$VERSION = 0.73;

# Explaination from HTML::FromText docs.
# This list of protocols is taken from RFC 1630: "Universal Resource
# Identifiers in WWW".  The protocol "file" is omitted because
# experience suggests that it results in many false positives; "https
# postdates RFC 1630.  The protocol "mailto" is handled separately, by
# the email address matching code.
my $protocol = join '|', qw(afs cid ftp gopher http https mid news nntp prospero telnet wais);

my %Map = ( '&' => '&amp;', '"' => '&quot;', '<' => '&lt;', '>' => '&gt;', "'" => '&#39;' );
my $RE = join '|', keys %Map;

my $punc = '[.?!,:;\]\)\}]';
my $inline_start_boundry='[\s\t\[\(\{]'; # this sets off the search for a handler
my $term= qr/(?=$punc*?(\s|$))/; # checks that the following space to be sure the character isn't something inline
my $not_in_markup='(?:[^<>]*|<[^<>]*>)*?';
my $macro= qr/%%.*?%%/;

# __LT__ & __GT__ is the unfortunate side effect of not confusing the parser during processing.
my %cell_alignments = ( '__LT__' => 'left', '^' => 'center', '__GT__' => 'right' );
my $cell_alignment = '\\'.join '|\\', keys %cell_alignments;

my %block_handlers = ( 
				'_p' => \&hdlr_paragraph,
				'>' => \&hdlr_blockquote,
				'_pre' => \&hdlr_pre,
				'%' => \&hdlr_code_block,
				'-' => \&hdlr_hr,
				'_h1' => \&hdlr_h1,
				'_h2' => \&hdlr_h2,
				'_h3' => \&hdlr_h3,
				'_h4' => \&hdlr_h4,
				'_h5' => \&hdlr_h5,
				'_h6' => \&hdlr_h6, 
				'*' => \&hdlr_ul,
				'#' => \&hdlr_ol,
				'_dl' => \&hdlr_dl,
				'|' => \&hdlr_table, 
				'_macro' => \&hdlr_macro_block # for default block handler
				);
			
my %inline_handlers = ( 
				'*' => \&hdlr_strong,
				'/' => \&hdlr_emp,
				'+' => \&hdlr_insert,
				'-' => \&hdlr_delete,
				'~' => \&hdlr_subscript,
				'^' => \&hdlr_superscript,
				'"' => \&hdlr_quote,
				'%' => \&hdlr_code_inline,
				'@' => \&hdlr_cite,
				'[' => \&hdlr_hyperlink,
				'{' => \&hdlr_image,
				);
				
#--- external methods

sub new { 
	my $class = shift;
	my $tiki = bless {}, $class;
	$tiki->init(@_);
	$tiki->clear_handlers(@_);
	return $tiki;
}

sub init { 
	my $tiki = shift;
	$tiki->{__heading_names}={};
	$tiki->{__block_format_depth}=0;
	$tiki->{__inline_format_depth}=0;
	$tiki->{__macro_processing}=0;
	$tiki->{__wiki_implicit_links}=0;
	$tiki->{__wiki_prefix}='';
	$tiki->{__interwiki_links}=0;
	$tiki->{__interwiki_table}={ };
	$tiki->{__typographic_processing}=1;
	# should we store the original?
	# should we store the finished product?
}

sub format {
	my $tiki = shift;
	my $content = shift;
	unless ( ref($content) eq "ARRAY") {  
		$content=~s/\r//g; 
		my @lines = split(/\n/, $content); 
		$content = \@lines; 
	}
	return $tiki->block_format($content);
}

sub format_line { 
	my $tiki = shift;
	my $line = shift;
	$tiki->inline_format(\$line);
	return $line
}

sub stash {
    my $tiki = shift;
    my $key = shift;
    $tiki->{__stash}->{$key} = shift if @_;
    return $tiki->{__stash}->{$key};
}

sub clear_handlers { 
	$_[0]->{__wiki_links_handler} = \&wiki_link_default_processor;
	$_[0]->{__interwiki_links_handler} = \&interwiki_link_default_processor;
	$_[0]->{__macro_handlers} = undef;
}

#--- internal "workhorse" methods

sub block_format {
	my $tiki = shift;
	my $content=shift;
	my $index=0;
	my $buffer;
	my $out;
	my @pre_tail=();
	return '' unless (  @{ $content } );
	$tiki->{__block_format_depth}++;
	foreach my $line (@{ $content }) {
		$line =~s/^[\s\t]*$//; # cleans out false negatives linebreaks.
		unless ( length($line) ) { 
			next unless( defined( $buffer->[$index]->{type} ) );
			if ( $buffer->[$index]->{type}!~/(_pre|%)/ ) {
				if ( @{ $buffer->[$index]->{buffer} } ) {
					$index++; $buffer->[$index]->{buffer} = ();
					next;
				} 
			} else { push(@pre_tail,''); next; }
		} else { 
			my $symbol=substr($line,0,1);
			if ($symbol=~/^[\s\t]/) { 
				$symbol='_pre'; 
				push(@{ $buffer->[$index]->{buffer} },@pre_tail);
				@pre_tail=();
			} else {
				if ( @pre_tail ) { $index++; $buffer->[$index]->{buffer} = (); @pre_tail=(); } 
				if ( $symbol eq '!' 
						&& substr($line,1,2)=~/^[1-6]?[\s\t]/ ) {
					$line=~s/^!([1-6]?)[\s\t]//;	
					$symbol = '_h'. ($1?$1:1);
				} elsif ($symbol eq '-') {
					if ($line=~/^----/) { $line=''; } 
					else { $symbol = '_p'; }
				} elsif ($symbol eq '|') {
					# avoids further processing for now
				} elsif ($symbol=~/[:;]/) {
					$symbol = '_dl'; 
					# we don't strip the symbol here so the dl handler knows what is a <dd> 
					# and what is a <dt>.
				} elsif ($tiki->{__macro_processing} && $symbol eq '%'  && $line=~/^$macro[\s\t]*$/) { # should use more precise regex that only accepts if alone on line.
					$symbol = '_macro'; 
				} elsif ( defined( $block_handlers{$symbol} ) 
						&&  ( ( $symbol=~/[#*]/ && substr($line,1,1)=~/[#*\s\t]/ ) || # Handles nested lists shortcut
						length($line) == 1 || # blank line in a block
						substr($line,1,1)=~/^[$symbol\s\t]/ ) ) { 
					$line=~s/^[$symbol][\s\t]?//;
				} else { $symbol = '_p'; } 
			}
			$buffer->[$index]->{type} = $symbol unless ( defined ( $buffer->[$index]->{type} ) );
		}
		# keeps encoder from getting confused during processing.
		$line=~s/</__LT__/g; $line=~s/>/__GT__/g; 
		push(@{ $buffer->[$index]->{buffer} },$line);
		if ($buffer->[$index]->{type} eq '_macro') { $index++; $buffer->[$index]->{buffer} = (); }
	}	
	pop( @{ $buffer } ) and $index-- unless ( $buffer->[-1]->{type} );
	foreach my $block ( @{ $buffer } ) {
		$out .= $block_handlers{ $block->{type} }->( $tiki, $block->{buffer} );
	}
	if ( ! ($tiki->{__block_format_depth}-1) && $tiki->{__macro_processing} ) {
		$out=~s/($macro)[\s\t]*/$tiki->hdlr_macro_block_postprocess($1)/meg; # should only work at start of the line
	}
	$tiki->{__block_format_depth}--;
	return $out?$out:'';
}

sub inline_format {
	my $tiki = shift;
	my $in = shift;
	my $out='';
	$tiki->{__inline_format_depth}++;
	while (defined($$in) && length($$in) > 2) {
		my $symbol = substr($$in,0,1);
		if ( $tiki->{__inline_format_depth}==1 && $symbol eq '%' && $tiki->{__macro_processing} ) {
			$$in=~s/^($macro)/$tiki->hdlr_macro_inline($1)/e;			
			#macro was passed through.
			if ($$in=~s/^($macro)// && $1) {
				$out .= $1; next;
			}
			$symbol = substr($$in,0,1);
		}
		if ( defined( $inline_handlers{$symbol} ) && 
			(! length($out) || substr($out, length($out)-1 )=~/$inline_start_boundry/ ) ) { 
			my ($start_tag,$enclosure,$end_tag) = $inline_handlers{ $symbol }->( $tiki, $in ); 
			if ( defined( $start_tag ) ) {
				$out .= $start_tag . $tiki->inline_format(\$enclosure) . $end_tag;
				next;
			}
		}
		$$in=~s/(.)//; $out.=$1;
	}
	$out .= defined($$in)?$$in:'';
	unless ( $tiki->{__inline_format_depth}-1 ) {
		$tiki->hdlr_autolink(\$out);
		$tiki->hdlr_wiki_link(\$out) if ( $tiki->{__wiki_implicit_links} );
		$tiki->hdlr_interwiki_link(\$out) if ( $tiki->{__interwiki_links} );
		$tiki->hdlr_acronym(\$out);
		encoding_processor(\$out, { typographic_processing => $tiki->{__typographic_processing} } );
		if ( $tiki->{__macro_processing} ) {
			$out=~s/($macro)/$tiki->hdlr_macro_inline_literal($1)/eg; 
		}
	}
	$tiki->{__inline_format_depth}--;
	return $out;
}

#-- wiki handling routines.

sub wiki_implicit_links { $_[0]->{__wiki_implicit_links}=$_[1]; }
sub wiki_prefix { $_[0]->{__wiki_prefix}=$_[1]; }
sub interwiki_links { $_[0]->{__interwiki_links}=$_[1]; }
sub interwiki_table { $_[0]->{__interwiki_table}=$_[1]; }

sub wiki_links_handler { $_[0]->{__wiki_links_handler}=$_[1]; }
sub interwiki_links_handler { $_[0]->{__interwiki_links_handler}=$_[1]; }

sub hdlr_wiki_link { # regex borrowed from Text::WikiFormat
	my $tiki = shift;
	my $in = shift;
	$tiki->{__wiki_links_handler} ||= \&wiki_link_default_processor;
	$$in =~ s|(?<!["/>=])\b([A-Za-z]+(?:[A-Z]\w+)+)|$tiki->{__wiki_links_handler}->($tiki,$1)|eg;
}

sub hdlr_interwiki_link { 
	my $tiki = shift;
	my $in = shift;
	$tiki->{__interwiki_links_handler} ||= \&interwiki_link_default_processor;
	$$in =~ s|\[\[([:\w]+?)(?:\s+([^\]{2}]+?))?\]\]|$tiki->{__interwiki_links_handler}->($tiki,$1,$2)|eg;
}

sub wiki_link_default_processor { 
	return qq|<a href="$_[0]->{__wiki_prefix}$_[1]">$_[1]</a>|;
}

sub interwiki_link_default_processor { 
	my $tiki = shift;
	my $link = shift;
	my $word = shift;
  	$link =~ m/^(\w+?):(.*)$/;
    my $interwiki = $tiki->{__interwiki_table}->{$1} || '';
    return qq{<a href="$tiki->{__interwiki_table}->{$1}$2" title="$1">}.($word||$2).qq{</a>};
}

#-- macro handling routines

sub macros { $_[0]->{__macro_processing}=$_[1]; }

{
	my %hdlr_types = ( 'block' =>1, 'block_post' =>1, 'inline'=>1, 'inline_literal'=>1 ); 
	sub macro_handler { 
		my ($tiki, $name, $code, $type) = @_;
		unless ( defined( $hdlr_types{ $type } ) ) {
			my @types = keys %hdlr_types;
			die "Unknown macro handler type: $type\n Valid types: @types";
		}
		$tiki->{__macro_handlers}->{ $name } = { code => $code, type => $type };
	}
}

sub hdlr_macro_block { return $_[0]->macro_processor($_[1],'block'); }
sub hdlr_macro_block_postprocess { return $_[0]->macro_processor($_[1],'block_post'); }
sub hdlr_macro_inline { return $_[0]->inline_format( \$_[0]->macro_processor($_[1],'inline') ); }
sub hdlr_macro_inline_literal { return $_[0]->macro_processor($_[1],'inline_literal'); }

sub macro_processor {
	my $tiki = shift;
	my $in = shift;
	my $type = shift;
	my $out;
	$in = join ('', @{ $in } ) if ( ref($in) eq "ARRAY");  
	$in=~/^%%(.*)%%/;
	my ($name, $attrib) = split(/\s/,$1,2); 
	if ( defined( $tiki->{__macro_handlers}->{ $name } ) && 
			$tiki->{__macro_handlers}->{ $name }->{type} eq $type ) {
		$out = $tiki->{__macro_handlers}->{ $name }->{code}->($tiki, $name, $attrib);
	}
	return ($out || $in).($type=~/^block/?"\n":'');
}

#--- block handlers
# They get an array and pass decide whether to pass them on to be encoded or autolinked.

sub hdlr_paragraph {
	foreach my $line ( @{ $_[1] } ) {
		$line = $_[0]->inline_format( \$line );
	}
	return '<p>'.join("<br \/>",@{ $_[1] } )."</p>\n";
}

sub hdlr_blockquote { return "<blockquote>\n" . $_[0]->block_format($_[1]) . "</blockquote>\n"; }

sub hdlr_pre {
	my $tiki = shift;
	foreach my $line ( @{ $_[0] } ) {
		$line = $tiki->inline_format( \$line );
	}
	return "<pre>\n". join("\n",@{ $_[0] }) ."\n</pre>\n"; 	
}

sub hdlr_code_block {
	my $line = join("\n",@{ $_[1] });
	xml_encode( \$line );
	return "<pre><code>\n".$line."\n</code></pre>\n"; 
}

sub hdlr_hr { return '<hr />'.join("<hr \/>",@{ $_[1] } ); }
sub hdlr_h1 { return $_[0]->heading_processor($_[1]); }
sub hdlr_h2 { return $_[0]->heading_processor($_[1],'h2'); }
sub hdlr_h3 { return $_[0]->heading_processor($_[1],'h3'); }
sub hdlr_h4 { return $_[0]->heading_processor($_[1],'h4'); }
sub hdlr_h5 { return $_[0]->heading_processor($_[1],'h5'); }
sub hdlr_h6 { return $_[0]->heading_processor($_[1],'h6'); }
sub hdlr_ul { return $_[0]->list_processor($_[1]); }
sub hdlr_ol { return $_[0]->list_processor($_[1],'ol'); }

sub hdlr_dl {
	my $tiki = shift;
	my $content = shift;
	my $out="<dl>\n";
	foreach my $line ( @{ $content } ) {
		$line=~s/([;:])[\s\t]//;
		# Unlike other block handlers we do the striping because we have 
		# two types of elements within this type.
		if ( $1 eq ':' ) {
			my @array = ( $line);
			$out .= "<dd>\n".$tiki->block_format( \@array )."</dd>\n"; 
		} else {
			$out .= '<dt>'.$tiki->inline_format( \$line )."</dt>\n";
		}
	}
	return $out."</dl>\n";
} # http://www.w3.org/TR/2003/WD-xhtml2-20030506/mod-list.html#s_listmodule

sub heading_processor {
	my $tiki = shift;
	my $heading = join("<br \/>", @{ $_[0] } );
	my $id = join('', @{ $_[0] } );
	my $level = $_[1] || 'h1';
	$id =~ s/[^\s\w\d]+//g; # remove non alpha/ws characters
	$id =~ s/\b([a-z])/\u\L$1/g; # proper case all lower case characters at start of words
	# Using WikiWord format instead of Camel Case
	# $id =~ s/^\s*([A-Z]+)/\L$1/; # but first word is all lowercase
	$id =~ s/\s+//g; # Remove whitespace
	if ($tiki->{__heading_names}->{$id}) {
		my $count=2; # one is assumed.
		while ($tiki->{__heading_names}->{$id.$count}) { $count++; }
		$id.=$count;
	}
	$tiki->{__heading_names}->{$id}++;
	return "<$level><a id=\"$id\"></a>".$tiki->inline_format(\$heading)."</$level>\n";
}

sub list_processor {
	my $tiki = shift;
	my $content = shift;
	my $list_type = shift || 'ul';
	my $buffer;
	my $index = 0;
	$buffer->[$index]->{type}='_li';
	foreach my $line ( @{ $content } ) {
		my $symbol;
		unless ( $line=~s/^([*#])([\s\t]|(?=[*#]))// ) {
			$symbol = '_li'; 
		} else { $symbol = $1; }	
		unless( $symbol eq $buffer->[$index]->{type} )  {
			$index++; $buffer->[$index]->{buffer}=(); $buffer->[$index]->{type}=$symbol;
		}
		push(@{ $buffer->[$index]->{buffer} },$line);
	}
	my $out = "<$list_type>\n<li>";
	my $started = 0;
	foreach my $buffer ( @{ $buffer } ) {
		if ($buffer->{type} eq '_li') {
			foreach my $line ( @{ $buffer->{buffer} } ) {
				$out .= $started ? "</li>\n<li>" : '';
				$started++;
				$out .= $tiki->inline_format( \$line );
			}
		} else { $out .= "\n".$tiki->list_processor( $buffer->{buffer}, ( $buffer->{type} eq '*'?'ul':'ol' ) ); }
	}
	$out .= "</li>\n";
	return $out."</$list_type>\n";
}

sub hdlr_table {
	my $tiki = shift;
	my $content = shift;
	my $out;
	foreach my $line (@{ $content }) {
		my $row='';
		my $colspan = 1;
		my $is_heading = 1 if $line=~s/^\|!/\|/; 
		$line=~s/\|/ \|/g; # quick hack that inserts a space and get "blanks cells" to register.
		my @cells = split(/\|/,$line);
		foreach my $cell (reverse @cells) { # work backward to calculate colspans.
			$cell=~s!^($cell_alignment)!!;
			my $alignment = $cell_alignments{$1} if $1;
			if ( $cell ) { $cell=~s/^\s*//; $cell=~s/\s*$//; }# clean out leading and tailing whitespace.
			unless( $cell ) { $colspan++; }
			else {
				my $encoded = ( defined($is_heading)?'<th':'<td' ) . 
					( defined($alignment)?" align=\"$alignment\"":'' ) .
					( $colspan>1?" colspan=\"$colspan\"":'' ) .
					'>';
				$encoded .= $tiki->inline_format( \$cell );
				$encoded .= (defined($is_heading)?'</th>':'</td>');
				$row = $encoded . "\n" . $row;
				$colspan = 1;
			}
		}
		$out .= "<tr>\n".$row."</tr>\n";
	}
	return "<table>\n".$out."</table>\n";
}


#--- inline handlers
# Handler functions gets scalar (reference?) and is assumed to parse the string from the start and strip 
# is entirely from the referenced string. If nothing is found return undef in the first position.)

sub hdlr_strong { return ${$_[1]}=~s/^\*(.+?)\*${term}//?('<strong>', $1,'</strong>'):undef; }
sub hdlr_emp { return ${$_[1]}=~s!^/(.+?)/${term}!!?('<em>', $1,'</em>'):undef; }
sub hdlr_insert { return ${$_[1]}=~s/^\+(.+?)\+${term}//?('<ins>', $1,'</ins>'):undef; }
sub hdlr_delete { return ${$_[1]}=~s/^\-(.+?)\b\-${term}//?('<del>', $1,'</del>'):undef; } # added \b to fix "greedy problem."
sub hdlr_subscript { return ${$_[1]}=~s/^\~(.+?)\~${term}//?('<sub>', $1,'</sub>'):undef; }
sub hdlr_superscript { return ${$_[1]}=~s/^\^(.+?)\^${term}//?('<sup>', $1,'</sup>'):undef; }
sub hdlr_quote { return ${$_[1]}=~s/^\"(.+?)\"${term}//?('<q>', $1,'</q>'):undef; }
sub hdlr_code_inline { return ${$_[1]}=~s/^\%(.+?)\%${term}//?('<code>', $1,'</code>'):undef; }
sub hdlr_cite { return ${$_[1]}=~s/^\@(.+?)\@${term}//?('<cite>', $1,'</cite>'):undef; }

sub hdlr_hyperlink { return ${$_[1]}=~s!^\[([^\]]*)\]:(.*?)${term}!!?("<a href=\"$2\">",$1,'</a>'):undef; }
sub hdlr_image { return ${$_[1]}=~s!^\{([^\}]*)\}:(.*?)${term}!!?("<img src=\"$2\" alt=\"$1\"/>",'',''):undef; }

sub hdlr_autolink { 
	${$_[1]}=~s#(?:^|(?<=\s))((?:$protocol):\S+[\w/])(?=${term})#<a href="$1">$1</a>#go;
	while ( ${$_[1]}=~m/(?:^|(?<=\s))((?:mailto:)?)([^\s",\@]*\@[^\s.,]+\.[^\s,]+)(?=${term})/ ) {
		my $matched = "$1$2";
		my ($prefix, $mailto) = ($1, $2 );
		$mailto=~s/\@/&#64;/; $mailto=~s/\./&#46;/g;
		my $email = $mailto;
		$email=~s/&/__AMP__/g; #uses amp markers to avoid encoding confusion in display.
		${$_[1]}=~s!$matched!<a href="mailto:$mailto">$prefix$email</a>!gi
	}
}

sub hdlr_acronym {
	${$_[1]}=~s!\b([A-Z][A-Z0-9]*)\(([^\)]+?)\)${term}!<acronym title="$2">$1</acronym>!go; # Needs to be more inclusive?
}

#--- encoding

sub encoding_processor {
	my $line = shift;
	my $attribs = shift;
	my $c;
	my $tp = defined( $attribs->{typographic_processing} )?$attribs->{typographic_processing}:1;
	while ( $$line=~m/($not_in_markup)/g ) { #|<[^>]*\/>
		my $t=$1;
		unless ($t=~/^</) {
			xml_encode(\$t);
			typographic_encode(\$t) if ($tp);
		}
		$c.=$t;
	}
	$$line=$c;
}

sub xml_encode { # Splitting this out is particularly helpful to CODE blocks.
	${$_[0]}=~s/__LT__/</g; ${$_[0]}=~s/__GT__/>/g; # reverse markers.	
	${$_[0]}=~s!($RE)!$Map{$1}!g;
	${$_[0]}=~s{([\xC0-\xDF].|[\xE0-\xEF]..|[\xF0-\xFF]...)}{xml_utf8_decode($1)}egs;
	${$_[0]}=~s/__AMP__/&/g; #reverse amp spam protect markers
	return ${$_[0]}; # hack for CODE blocks.
}

sub xml_utf8_decode {
	my ($str, $hex) = @_;
    my $len = length ($str);
    my $n;
    if ($len == 2) {
		my @n = unpack "C2", $str;
		$n = (($n[0] & 0x3f) << 6) + ($n[1] & 0x3f);
	} elsif ($len == 3) {
		my @n = unpack "C3", $str;
		$n = (($n[0] & 0x1f) << 12) + (($n[1] & 0x3f) << 6) + ($n[2] & 0x3f);
    } elsif ($len == 4) { 
		my @n = unpack "C4", $str;
		$n = (($n[0] & 0x0f) << 18) + (($n[1] & 0x3f) << 12)
		+ (($n[2] & 0x3f) << 6) + ($n[3] & 0x3f);
    } elsif ($len == 1) { $n = ord ($str); # just to be complete...
    } else { warn "bad value [$str] for xml_utf8_decode"; }
    return $hex ? sprintf ("&#x%x;", $n) : "&#$n;";
}

sub typographic_encode {
	${$_[0]}=~s!(^|(?<=\s))---(?=\s?)!&#8212;!go; 
	${$_[0]}=~s!(^|(?<=\s))--(?=\s?)!&#8211;!go;
	${$_[0]}=~s!(^|\B)\.\.\.\b!&#8230;!go;
	${$_[0]}=~s!\b\.\.\.(?=[\s\t]|$)!&#8230;!go;
	${$_[0]}=~s!\(R\)(?=\s?)!&#174;!go;
	${$_[0]}=~s!\(TM\)(?=${term})!&#8482;!go;
	${$_[0]}=~s!\(C\)(?=${term})!&#169;!go;
	${$_[0]}=~s!(^|(?<=\s))1/4(?=${term})!&#188;!go;
	${$_[0]}=~s!(^|(?<=\s))1/2(?=${term})!&#189;!go;
	${$_[0]}=~s!(^|(?<=\s))3/4(?=${term})!&#190;!go;
	${$_[0]}=~s!\b(\d+)\s?x\s?(\d+)\b!$1&#215;$2!go;
}

1;

__END__

=head1 NAME

Text::TikiText - TikiText

=head1 SYNOPSIS

	use Text::Tiki;
	my $tiki = new Text::Tiki;
	
	$tiki->wiki_implicit_links(1);
	$tiki->wiki_prefix('http://www.timaoutloud.org/foo?');
	$tiki->interwiki_links(1);
	$tiki->interwiki_table(
			{ 
				wikipedia=>'http://en2.wikipedia.org/wiki/',
				joi=>'http://joi.ito.com/joiwiki/',
				atom=>'http://www.intertwingly.net/wiki/pie/'
			}
		);

	$tiki->macro_handler('BR', \&html_break, 'inline');

	print $tiki->format(\@lines);
	print $tiki->formatline($line);

=head1 DESCRIPTION

Despite the notion of a universal canvas, rich authoring of content through Web browsers is still rather poor and laborious to do. There have been attempts to create WYSIWYG(What You See Is What You Get) editor widgets to rectify this, however none of these tools are reliable cross-platform and cross-browser not and often lack the flexiblity of its read-only counterparts. This is unfortunate and nothing one person will be able to fix any time soon leaving us to cope with brain dead C<E<lt>textareaE<gt>> and plain text.

TikiText is an attempt to work with what we have and minimize (not completely solve) these shortcomings.

I was faced with the task of architecting a way for non-developer non-markup saavy business user to publish information. Plain text (with no formatting) was not going to cut it. Nor was teaching them XHTML markup. I did an intensive study of different structured text formatting notations that have been developed in the past. These notations included a few different Wiki implements such as UseMod Wiki, MoinMoin Wiki, Text::WikiFormat, in addition to Zope's Structured Text, HTML::FromText and Textile. For one reason or another these notations fell short of my requirements. So in scratching my own itch I developed a notation I call I<TikiText> based on my observations and key learnings. 

The name Tiki came from the combination of Text formatting and wIKI and was chosen to reflect Hawaiian heritige. (For those not familiar with this mythical god of retro poleynesia it's said /I<tee-kee>/ and not /I<tick-E>/)

I defined the design goals for TikiText are as follows:

=over 4

=item * Leverage existing text formatting notions.

=item * Least amount of characters from plain text.

=item * Use more intuitive and common plain text email conventions.

=item * Abstract users from needing to know or understand markup whenever possible.

=item * Make valid and semantical XHTML markup easy. (And let CSS do its job!)

=item * Easy to learn the basics. Richer functionality for those who want to dive in.

=back

While Wikis are a part of TikiText's lineage, it was never my intention to create a new Wiki notation or tool. Based on the feedback I received from the initial releases, I've added more Wiki features to this module. (See L<Wiki Functions> for more.)

This code is quite usable and has been improved over the months, but it should still be used with the understanding that it is still somewhat experimental and is just being tested and properly documented. Feedback, bug fixes, and feature implementations are appreciated. Furthermore, I realized this format is less then perfect and falls short of its design goals. My hope is that it will be refined an tweaked over time to optimize its effectiveness.

=head1 TikiText NOTATION

The first thing you must understand about TikiText and, generally speaking, most other text formatting notions is that spaces and linebreaks particularly significant. To a certain extent, tabs and puncuation are also are important to the engine's interpretation. The module attempt to handle whitespace that may be introduced while while cutting and pasting text, but it may not be perfect and unexpected results may occur.

=head2 Block-Level Formatting

Block-Level formatting is set by one or more characters at the start of line followed by a space. Multiple consecutive lines with the same starting format are treated as part of the same block. A block is terminated by at least one blank line. HTML breaks (C<<br />>) are now supported inside of paragraphs and blockquotes.

 Paragraph:             (Line without block formatting)
 Blockquote:            > 
 Preformatted Text:     (space) or (tab)
 Code (Block):          % (A special type of PRE section where TikiText is ignored.)
 Table:                 | (See the section on Tables for more.)
 Headings:              !# (i.e !1, !2, ! alone implies level 1)
 Horizontal Line:       ---- (A line with 4+ dashes.)

=head2 List Formatting

Like block-level formatting a list is defined by one or more characters at the start of a line. List types cannot be intermixed and definition lists cannot be nested.

 Unordered List Item:       *
 Ordered List Item:         #
 Definition List Item:      ; Definition
                            : Text 

Multiple lines beginning with a : (colon) allows for multiple text definitions to be associated to a definition.

For example:

 ; foo
 : A sample name for absolutely anything, especially programs and files (especially scratch files).
 : Term of disgust.

For clarity the practice of place the semi-colon and colon on the same line is no longer supported.

=head2 Inline Formatting

Inline formatting differs from block-level formatting and lists in that they do not have to start a line. They also tend to mark a smaller piece of data. Inline elements are used within a block of list structure such as a paragraph or blockquote. Inline formatting cannot cross lines.

 Strong/Bold:           *hello world*
 Emphasis/Italics:      /hello world/
 Inserted:              +hello world+
 Delete/Strikethrough:  -hello world-
 Subscript:             ~hello world~
 Superscript:           ^hello world^
 Quote:                 "hello world"
 Code (short):          %hello world%
 Cite:                  @hello world@

=head2 Hyperlinking

Like inline formatting the notion for creating a hyperlink cannot cross lines. URLs (the text following the colon) can be an external, absolute, relative reference. (TikiText takes in everything after the colon until the first space and use that string for the href.)

 Hyperlink:	[Text to link]:URL 

=head2 Images

Simple image insertion is supported in TikiText. In this version only partial functionality has been added. Like the notion for creating a hyperlink, image markers cannot cross lines. URLs (the text following the colon) can be an external, absolute, relative reference. (TikiText takes in everything after the colon until the first space and use that string for the href.)

 Image:	{Some sample alternate text}:IMG-URL 

=head2 Acronyms

Authors can create acronym tagging in TikiText and are encouraged to do so. TikiText will scan for words in all capitals followed immediately (no space) by parenthesis with the full description contained.

 Acronym: ACRONYM(The description of ACRONYM)

=head2 Tables

TikiText supports basic tables. All table blocks begin with the | (pipe) character. Each line is a row. Columns are also seperated by the pipe character. All rows should end with a pipe character. Table headers, cell aligns and columns spans are supported. Nested tables are not support nor are row spans. 

 |                     Column seperator.
 |!                    All cells in this row are headings.
 |<                    Left justify this cell.
 |^                    Center this cell.
 |>                    Right justify this cell.
 |(span)||             A column span. (The last cell is spanned over blank 
                        cells that follow.)

Leading and trailing whitespaces in each cell are ignored. This way authors have the option to make tables more readable without being parsed. This assumes the author is using a fixed-width font.

For example this TikiText...

 |!heading 1|heading 2|heading 3|
 |< left    |^ center |> right  |
 |^ centered across 3 columns |||

...would produce the following table:

	<table>
	<tr>
	<th>heading 1</th>
	<th>heading 2</th>
	<th>heading 3</th>
	</tr>
	<tr>
	<td align="left">left</td>
	<td align="center">center</td>
	<td align="right">right</td>
	</tr>
	<tr>
	<td align="center" colspan="3">centered across 3 columns</td>
	</tr>
	</table> 

=head2 Automated Functions

TikiText also provides several automated features for convenience that are derived from the semantic structure of the input and standard best practices.

=over 4

=item * TikiText will UTF8 encode all output.

=item * TikiText will generate and inserts named links for each heading.

=item * TikiText will autolink URLs. The list of recognized protocols is taken from RFC 1630: "Universal Resource Identifiers in WWW" though it excludes the file protocol

=item * TikiText will autolink email addresses and apply some basic spambot protection.

=item * TikiText will convert symbols usually commonly represented using multiple character to their typographic equivalants. (See L<Typographic Conversions>.)

=back

=head2 Typographic Conversions

TikiText will convert symbols usually commonly represented using multiple character to their typographic equivalants similar to John Gruber's SmartPants plugin for MovableType. The following is a list of multi-character representations and their numeric entity equivelents TikiText will convert.

 --                                 &#8212; (em dash)
 - (spaces on either side)          &#8211; (en dash)
 ...                                &#8230; (horizontal ellipsis)
 (R)                                &#174;  (registered tademark)
 (TM)                               &#8482; (trademark symbol)
 (C)                                &#169;  (copyright symbol)
 1/4                                &#188;  (fraction one-fourth)
 1/2                                &#189;  (fraction one-half)
 3/4                                &#190;  (fraction three-fourths)
 (digets) x (digets)                &#215;  (multiply sign)

=head2 Not Supported

This is a list of formatting that IS NOT supported by TikiText. Some of this unsupported feature is out of scope. Others are unimplemented features. Please see the the TO DO list for more information.

=over 4

=item * div, span, form elements, or the use of class="" to name few.

=item * Mid-word inline formating.

=item * Ordered List Item with specific values.

=back

=head1 USAGE

=head2 $tiki->new()

Instaniates a new TikiText processor and automatically invokes the C<init> and C<clear_handlers>.

=head2 $tiki->format($text)

The "workhorse" method. Takes in a scalar or array reference assumed to be TikiText and returns XHTML as a scalar. Any handlers that have been registered will be called during the execution of this method.

=head2 $tiki->format_line($text)

Similar to C<format>, this methods takes in a scalar (not an array reference) containing a single line of TikiText content and returns XHTML, however block formatting is not performed.

=head1 INTEGRATION

=head2 $tiki->init()

Resets processor to its default values. It does not clear out any data in the C<stash>. 

This method is automatically invoked when a new processor is instaniated.

=head2 $tiki->stash($key, [$value])

A simple data store method that can be used to pass information between applications and handlers during initialization and formatting operations. C<$key> is required and a unique identify for retreiving data. C<$value> is optional, but, if present, sets the value associated with the C<$key>. Method always returns the value of C<$key>.

=head2 $tiki->clear_handlers()

Sets all wiki, interwiki and macro handler tables to undefined.

=head1 WIKI FUNCTIONS

While Wikis are a part of TikiText's lineage, it was never the intention for TikiText to be used with or replace existing Wiki notations, however initial interest has been expressed towards this realm. TikiText is just a notation. How a WikiWord link is created and resolved is an implementation-specific trait that will vary. The ability for a developer to register callback routines that will be invoked when a WikiWord or IntraWiki link is encountered has been added as of version 0.70.

=head2 $tiki->wiki_implicit_links($boolean)

Sets wiki linking of WikiWords pattern processing via a boolean value. Default is false (0).

=head2 $tiki->wiki_prefix($wiki_url_prefix)

TikiText has a simple default wiki linking method built-in. If I<wiki_implicit_links> is set to true (1) and a handler has not been set via I<wiki_links_handler>, TikiText will construct one using the value set (a scalar) set by this method.

=head2 $tiki->wiki_links_handler(\&code_ref)

I<wiki_links_handler> allows for a specialized wiki link generator routine to be hooked into the TikiText processor. When a WikiWord pattern is encountered, the processor calls the registered routine and passes in a reference to the TikiText processor instance that invoked it and a scalar containing the WikiWord text. Handlers are required to return a string scalar.

This is helpful for hooking TikiText into another system to provide tighter integration and/or robust or alternate functionality to the default routine. If registered, this routine will override the default wiki link routine and prefix.

If I<wiki_implicit_links> must be set to true (1) or the handler will not be envoked.

	$tiki->wiki_links_handler(\&wiki_link);
	
	sub wiki_link {
		my($tiki, $word) = @_;
		return "WikiLink -> $word";
	}

=head2 $tiki->interwiki_links($boolean)

Sets interwiki linking processing of patterns such as [InterWikiName:Page] via a boolean value. Default is false (0).

=head2 $tiki->interwiki_table(\%hash_ref)

Similar to I<wiki_prefix>, TikiText has a simple default wiki linking method built in. If I<interwiki_links> is set to true (1) and a handler has not been set via I<interwiki_links_handler>, TikiText will construct one using the key (interwikiwiki name) value (cooresponding URL prefix) pairs of the hash table reference passed in with this method. 

=head2 $tiki->interwiki_links_handler(\&code_ref)

I<interwiki_links_handler> allows for a specialized interwiki link generator routine to be hooked into the TikiText processor. When a interwiki link pattern is encountered, the processor calls the registered routine and passes in a reference to the TikiText processor instance that invoked it and two scalars containing the interwiki prefix and page names as text. Handlers are required to return a string scalar.

This is helpful for hooking TikiText into another system to provide tighter integration and/or robust or alternate functionality to the default routine. If registered, this routine will override the default interwiki linking routine and table data.

If I<interwiki_links> must be set to true (1) or the handler will not be envoked.

	$tiki->interwiki_links_handler(\&interwiki_link);
	
	sub interwiki_link {
		my($tiki, $wiki, $page) = @_;
		return "Wiki of prefix $word with page $page";
	}

=head1 MACROS

Macros are an B<experimental feature> that was added in version 0.70 of TikiText where developers can develop and register their own tags. Tags take the form of ##TagName some optional additional string## in TikiText content.

The code seems stable and reliable after my tests, however I reserve the right to change this part of the API at a later date. Your feedback is appreciated.

=head2 $tiki->macros()

This method returns an array of hash references containing all of the macros that are currently registered.

=head2 $tiki->macro_handler($name, \&code_ref, 'macro_type')

This method registers a callback routine when a macro tag of I<name> is found during processing. The macro type will determine how the result will be processed. They are as follows:

=over 4

=item I<block>

As its name implies, these macros are treated like block formatting and are expected to exist on a line by itself seperated by line breaks. Block macros are  processed for any TikiText notation before being appended to the output. This macro type is useful for inserting other TikiText files or setting/unsetting a switch during processing.

=item I<block_post>

This macro type is exactly like a block macro except its processing is deferred until all formatting has occurred and the formatting engine is about to return the output to its caller. This macro type is useful for inserting content you do not want processed for TikiText or summary content such as an index or table of contents.

=item I<inline>

An inline macro can appear anywhere within a block. Inline macros are  processed for any TikiText notation before being appended to the output. This macro type is useful for inserting a value that requires TikiText processing.

=item I<inline_literal>

An inline_lieral macro is identical to an inline macro except that it is not processed for TikiText notation before being inserted into the output. This macro type is useful for inserting values such as a timestamp or environmental variable. It can also be used for an inline switch during processing. 

=back

When a macro pattern is encountered, the processor calls the registered handler and passes in a reference to the TikiText processor instance that invoked it and two scalars containing the macro name and an attribute string (if any) as text. The attribute string is and text after the first space found. TikiText passes in the raw string and does not enforce a specific format for the attribute. Handlers are required to return a string scalar. In the event that a macro handler does not insert any text an empty string should be returned, not a undefined value.

Here is the relevant code for a simple handler for inserting an explicit HTML break tag (multiple times if specified):

	$tiki->macro_handler('BR', \&html_break, 'inline');
	
	sub html_break {
		my($tiki,$name,$attrib) = @_;
		my $val = int($attrib) || 1;
		return '<br />' x $val;
	}

With this handler registered, this TikiText...

	This is a test of ##BR 3## the emergency broadcasting system
	
would be formatted into...

	<p>This is a test of <br /><br /><br /> the emergency broadcasting system</p>

=head1 TO DO

This engine is not entirely complete and does not fully meet its design goals. These are some of the known issues I am aware of and plan on rectifying in future releases. This is not a complete. Feedback is welcome.

=over 4

B<Autosizing of images.> While basic image insertion has been added, the auto-insertion of height and width attributes needs to be implemented.

B<Implement C<E<lt>tableE<gt>> captions and perhaps titles.> 

B<Add C<cite=""> processing to inline quotes and blockquote formatting. Smarter use of E<lt>qE<gt>> 

B<Add support for an external acronym dictionary.> Implemented as an automatic function of the TikiText engine it would make a best effort to find and tag acronyms based on a pre-existing external source.

B<Add a switch and built-in function to enumerate headings (1, 1.1, 1.1.1, 1.1.2...).>

B<Better documentation -- particularly more code examples.>

B<Flesh out macros.>

B<Better charater encoding/decoding.>

=back

=head1 SEE ALSO

L<Text::WikiFormat>, L<HTML::FromText>, L<CGI::Kwiki>

L<http://udell.roninhouse.com/bytecols/2001-06-06.html>

L<http://www.usemod.com/cgi-bin/wiki.pl?TextFormattingRules>

L<http://twistedmatrix.com:80/wiki/moin/HelpOnEditing>

L<http://www.zope.org/Documentation/Articles/STX>

L<http://www.textism.com/tools/textile/>

L<http://daringfireball.net/projects/smartypants/>

L<http://en2.wikipedia.org/wiki/Tiki>

=head1 LICENSE

The software is released under the Artistic License. The terms of the Artistic License are described at http://www.perl.com/language/misc/Artistic.html.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, Text::Tiki is Copyright 2003, Timothy Appnel, tima@mplode.com. All rights reserved.

=cut

