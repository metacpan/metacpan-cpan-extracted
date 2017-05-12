# -*- perl -*-

#
# $Id: XMLViewer.pm,v 1.42 2009/11/10 18:47:50 eserte Exp $
# Author: Slaven Rezic
#
# Copyright © 2000, 2003, 2004, 2007, 2009 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
# WWW:  http://www.sourceforge.net/projects/srezic
#

package Tk::XMLViewer;

use Tk 800.013; # -elide
require Tk::ROText;
require Tk::Pixmap;
use strict;
use vars qw($VERSION);

use base qw(Tk::Derived Tk::ROText);
use XML::Parser;

BEGIN {
    if ($] < 5.006) {
	$INC{"warnings.pm"} = 1;
	*warnings::import = sub { };
	*warnings::unimport = sub { };
    }
}

Construct Tk::Widget 'XMLViewer';

$VERSION = '0.21';

my($curr_w); # ugly, but probably faster than defining handlers for everything
my $curr_xpath;
my $indent_width = 32;
my $use_elide = $Tk::VERSION < 800 || $Tk::VERSION >= 804.025;
my @tagAdds;

sub SetIndent {
    my $w = shift;
    my $arg = shift;
    $indent_width = $arg;
}

sub Populate {
    my($w,$args) = @_;
    $w->SUPER::Populate($args);
    $w->configure(-wrap   => 'word',
		  -cursor => 'left_ptr');

    my $tagcolor     = delete $args->{-tagcolor}     || 'red';
    my $attrkeycolor = delete $args->{-attrkeycolor} || 'green4';
    my $attrvalcolor = delete $args->{-attrvalcolor} || 'DarkGreen';
    my $commentcolor = delete $args->{-commentcolor} || 'gold3';

    $w->tagConfigure('xml_tag',
		     -foreground => $tagcolor,
		     #-font => 'boldXXX',
		     );
    $w->tagConfigure('xml_attrkey',
		     -foreground => $attrkeycolor,
		     );
    $w->tagConfigure('xml_attrval',
		     -foreground => $attrvalcolor,
		     );
    $w->tagConfigure('xml_comment',
		     -foreground => $commentcolor,
		     );
    $w->{IndentTags}  = [];
    $w->{RegionCount} = 0;
    $w->{XmlInfo}     = {};

    # XXX warum parent?
    $w->{PlusImage}  = $w->parent->Pixmap(-id => 'plus');
    $w->{MinusImage} = $w->parent->Pixmap(-id => 'minus');
}

sub insertXML {
    my $w = shift;
    $w->Busy();
    my(%args) = @_;
    my $xmlparserargs = delete $args{-xmlparserargs};
    my $p1 = new XML::Parser(Style => "Stream",
			     Handlers => {
  				 Comment => \&hComment,
  				 XMLDecl => \&hDecl,
  				 Doctype => \&hDoctype,
  			     },
			     $xmlparserargs ? %$xmlparserargs : (),
			    );
    $w->{Indent} = 0;
    $w->{PendingEnd} = 0;
    $curr_w = $w;
    @tagAdds=();
    eval {
	if ($args{-file}) {
	    $w->{Source} = ['file', $args{-file}];
	    $p1->parsefile($args{-file});
	} elsif (exists $args{-text}) {
	    $w->{Source} = ['text', $args{-text}];
	    $p1->parse($args{-text});
	} else {
	    die "-text or -file argument missing";
	}
    };
    if ($@) {
	if ($@ =~ /byte\s+(\d+)/) {
	    my $byte = $1;
	    my $xmlstring; # the erraneauos (sp?) part
	    if ($args{-file}) {
		if (open(F, $args{-file})) {
		   binmode F;
		   seek(F, $byte, 0);
		   local($/) = undef;
		   $xmlstring = <F>;
		   close F;
		}
	    } else {
		$xmlstring = substr($args{-text}, $byte);
	    }
	    $w->tagConfigure("ERROR",
			     -background => '#800000',
			     -foreground => '#ffffff',
			    );
	    $w->see("end");
	    (my $err = $@) =~ s/(byte\s+\d+)\s*at\s*.*line\s*\d+/$1/;
	    $w->insert("end", "ERROR $err", "ERROR",
		       _convert_from_unicode($xmlstring));
	} else {
	    die "Error while parsing XML: $@";
	}
    } else {
	$w->_flush;
	for (reverse @tagAdds) {
	    $w->tagAdd(@$_);
	}
	@tagAdds = ();
    }
    $w->Unbusy();
}

sub hDoctype {
    my $exp = shift;
    foreach my $i (qw(Name Sysid Pubid Internal)) {
	$curr_w->{XmlInfo}{$i} = shift;
    }
}

sub hDecl {
    my $exp = shift;
    foreach my $i (qw(Version Encoding Standalone)) {
	$curr_w->{XmlInfo}{$i} = shift;
    }
}

sub _indenttag {
    my $w = shift;
    my $indent = shift || $w->{Indent};
    if (!defined $w->{IndentTags}[$indent]) {
	$w->tagConfigure("xml_indent$indent",
			 -lmargin1 => $indent*$indent_width,
			 -lmargin2 => $indent*$indent_width,
			);
	$w->{IndentTags}[$indent] = "xml_indent$indent";
    }
    $w->{IndentTags}[$indent];
}

sub _flush {
    my $w = shift;
    if ($w->{PendingEnd}) {
	$w->insert("end", ">", 'xml_tag', "\n");
	$w->{PendingEnd} = 0;
	my $indent = $w->{Indent}-1;
	$w->markSet('regionstart' . $indent, $w->index("end - 1 chars"));
	$w->markGravity('regionstart' . $indent, 'left');
    }
}

sub StartDocument {
    $curr_xpath = "";
}

sub StartTag {
    $curr_w->_flush;
    my $start = $curr_w->index("end - 1 chars");
    my $tagname = $_[1];
    $curr_xpath .= "/" . $tagname;
    $curr_w->insert("end", "<" . _convert_from_unicode($tagname), ['xml_tag', 'xpath_' . $curr_xpath]);
    if (%_) {
	$curr_w->insert("end", " ");
	my $need_space = 0;
	while(my($k,$v) = each %_) {
	    if ($need_space) {
		$curr_w->insert("end", " ");
	    } else {
		$need_space++;
	    }
	    $curr_w->insert("end",
			    _convert_from_unicode($k), ["xml_attrkey", 'xpath_' . $curr_xpath . '/@' . $k],
			    "=\"", "",
			    _convert_from_unicode($v), "xml_attrval",
			    "\"", "");
	}
    }
    $curr_w->tagAdd($curr_w->_indenttag, $start, "end");
    $curr_w->{PendingEnd} = 1;
    $curr_w->markSet('tagstart' . $curr_w->{Indent}, $start);
    $curr_w->{Indent}++;
}

sub Text {
    $curr_w->_flush;
    s/^\s+//;
    s/\s+$//;
    if ($_ ne "") {
	$curr_w->insert("end",
			_convert_from_unicode($_) . "\n",
			$curr_w->_indenttag);
    }
}
sub hComment {
    $curr_w->_flush;
    $_ = $_[1];
    s/^\s+//; s/\s+$//;
    if ($_ ne "") {
	my $tag_start = $curr_w->index("end - 1 chars");
	$curr_w->insert("end", "<!-- \n", "xml_comment");
	my $region_start = $curr_w->index("end - 1 chars");
	$curr_w->insert("end", 
			_convert_from_unicode($_) . " -->\n", "xml_comment");
	my $region_end   = $curr_w->index("end");
	my $region_count = $curr_w->{RegionCount};
	$curr_w->tagAdd("region" . $region_count,
			$region_start, $region_end);
	$curr_w->imageCreate("$tag_start",
 			     -image => $curr_w->{'MinusImage'});
	$curr_w->tagAdd("plus" . $region_count,
 			$tag_start);
	my $ww = $curr_w;
	$curr_w->tagBind("plus" . $region_count,
 			 '<1>' => [$ww, 'ShowHideRegion', $region_count]);
	$curr_w->tagBind("plus" . $region_count,
 			 '<Enter>' => sub { $ww->configure(-cursor => 'hand2') });
	$curr_w->tagBind("plus" . $region_count,
 			 '<Leave>' => sub { $ww->configure(-cursor => 'left_ptr') });
	$curr_w->{RegionCount}++;
    }
}

sub EndTag {
    $curr_w->{Indent} --;

    if ($curr_w->{PendingEnd}) {
	$curr_w->insert("end", " />", 'xml_tag', "\n");
	$curr_w->{PendingEnd} = 0;
    } else {
	my $region_start = $curr_w->index('regionstart' . $curr_w->{Indent});
	my $tag_start    = $curr_w->index('tagstart' . $curr_w->{Indent});
	my $region_end   = $curr_w->index("end");
	my $start = $curr_w->index("end - 1 chars");
	$curr_w->insert("end", "</" . _convert_from_unicode($_[1]) .">",
			'xml_tag');
# 	$curr_w->tagAdd($curr_w->_indenttag, $start, "end");
	my $end_index = $curr_w->index("end");
	push @tagAdds, [$curr_w->_indenttag, $start, $end_index];
 	my $region_count = $curr_w->{RegionCount};
# 	$curr_w->tagAdd("region" . $region_count,
# 			$region_start, $region_end);
	push @tagAdds, ["region" . $region_count,
 			$region_start, $region_end];

  	$curr_w->imageCreate("$tag_start",
  			     -image => $curr_w->{'MinusImage'});
# 	$curr_w->tagAdd("plus" . $region_count,	$tag_start);
	push @tagAdds, ["plus" . $region_count,	$tag_start];
# 	$curr_w->tagAdd($curr_w->_indenttag,	$tag_start);
	push @tagAdds, [$curr_w->_indenttag,	$tag_start];
	my $ww = $curr_w;
 	$curr_w->tagBind("plus" . $region_count,
 			 '<1>' => [$ww, 'ShowHideRegion', $region_count]);
 	$curr_w->tagBind("plus" . $region_count,
 			 '<Enter>' => sub { $ww->configure(-cursor => 'hand2') });
 	$curr_w->tagBind("plus" . $region_count,
 			 '<Leave>' => sub { $ww->configure(-cursor => 'left_ptr') });
	$curr_w->{RegionCount}++;
	$curr_w->insert("end", "\n");
    }

    $curr_xpath =~ s{/[^/]+$}{};
}

sub ShowHideRegion {
    my($w, $region, %args) = @_;
    $w->markSet("showhidemarkbegin", "plus" . $region . ".first");
    $w->markGravity("showhidemarkbegin", "left");
    $w->markSet("showhidemarkend", "plus" . $region . ".first + 1 chars");
    $w->markGravity("showhidemarkend", "right");
    # remember tags for restore
    my(@old_tags) = $w->tagNames("showhidemarkbegin");
    $w->delete("showhidemarkbegin", "showhidemarkend");
    if (!exists $args{-open}) {
	if ($use_elide) {
	    $args{-open} = $w->tagCget("region" . $region, '-elide');
	} else {
	    $args{-open} = $w->tagCget("region" . $region, '-state') eq 'hidden';
	}
    }
    if ($args{-open}) {
	$w->imageCreate("showhidemarkbegin",
			-image => $w->{'MinusImage'});
	$w->tagConfigure("region" . $region,
			 $use_elide ? (-elide => undef)
			            : (-state => ''));
    } else {
	$w->imageCreate("showhidemarkbegin",
			-image => $w->{'PlusImage'});
	$w->tagConfigure("region" . $region,
			 $use_elide ? (-elide => 1)
			            : (-state => 'hidden'));
    }
    # restore old tags for minus/plus image
    foreach my $tag (@old_tags) {
	$w->tagAdd($tag, "showhidemarkbegin");
    }
}

sub DumpXML {
    my($w) = @_;
    $w->Busy();
    my(@dump) = $w->dump("1.0", "end");
    my $out = "<?xml version='1.0' encoding='ISO-8859-1' ?>";
    $out .= "<perltktext>";
    for(my $i=0; $i<=$#dump; $i++) {
	my $x = $dump[$i];
	if ($x eq 'tagon') {
	    $out .= "<tag name='" . $dump[$i+1] . "'>\n";
	    $i+=2;
	} elsif ($x eq 'tagoff') {
	    $out .= "</tag>\n";
	    $i+=2;
	} elsif ($x eq 'image') {
	    local $^W = undef; # XXX often there is no image?!
	    $out .= "<image name='" . $dump[$i+1] . "' />\n";
	    $i+=2;
	} elsif ($x eq 'text') {
	    $dump[$i+1] =~ s/&/&amp;/g;
	    $dump[$i+1] =~ s/</&lt;/g;
	    $dump[$i+1] =~ s/>/&gt;/g;
	    $out .= $dump[$i+1];
	    $i+=2;
	} elsif ($x eq 'mark') {
	    $out .= "<mark name='" . $dump[$i+1] . "' />\n";
	    $i+=2;
	} else {
	    warn "Unknown type $x";
	    $i+=2;
	}
    }
    $out .= "</perltktext>";
    $w->Unbusy();
    $out;
}

sub OpenCloseDepth {
    my($w, $depth, $open) = @_;
    my($begin, $end) = ("1.0");
    while(1) {
	($begin, $end) = $w->tagNextrange('xml_indent' . $depth, $begin);
#warn "$begin $end<" if $depth == 2;
	last if !defined $begin || $begin eq '';
	my(@tags) = $w->tagNames($begin);
	my $region;
	foreach my $tag (@tags) {
	    if ($tag =~ /^region(\d+)/) {
		$region = $1;
		last;
	    }
	}
#warn "region=$region" if $depth==2;
	if (defined $region) {
	    $w->ShowHideRegion($region, -open => $open);
	}
	$begin = $end; #"$end + 1 chars";
    }
}

sub ShowToDepth {
    my($w, $depth) = @_;
    $w->Busy();
    if(!defined $depth) {
	$depth = 999; #this is just a temporary workaround
    }
#warn "Close Depth $depth";
    $depth--;
    $w->OpenCloseDepth($depth, 0);
    while ($depth > 0) {
	$depth--;
#warn "Open Depth $depth";
	$w->OpenCloseDepth($depth, 1);
    }
    $w->Unbusy();
}

# XXX not really working...
sub CloseSelectedRegion {
    my $w = shift;
    return unless $w->tagRanges("sel");

    my $begin_region;
    my $end_region;

    # find beginning
    my(@tags) = $w->tagNames("sel.first");
warn "@tags";
    foreach my $tag (@tags) {
warn $tag;
        if ($tag =~ /^region(\d+)/) {
            $begin_region = $1;
            last;
        }
    }

    # find end
    @tags = $w->tagNames("sel.last");
warn "@tags";
    foreach my $tag (@tags) {
warn $tag;
        if ($tag =~ /^region(\d+)/) {
            $end_region = $1;
            last;
        }
    }

    if (defined $begin_region and defined $end_region) {
        for my $region ($begin_region .. $end_region) {
            $w->ShowHideRegion($region, -open => 0);
        }
    }
}

sub XMLMenu {
    my $w = shift;
    if ($Tk::VERSION > 800.014 && $w->can("menu")) {
	my $textmenu = $w->menu;
	my $xmlmenu = $textmenu->cascade(-tearoff => 0,
					 -label => "XML");
	$xmlmenu->command(-label => 'Info',
			  -command => sub { $w->Showinfo; });
	my $depthmenu = $xmlmenu->cascade(-tearoff => 0,
					  -label => 'Show to depth');
	for my $depth (1 .. 6) {
	    my $_depth = $depth;
	    $depthmenu->command(-label => $depth,
				-command => sub { $w->ShowToDepth($_depth) });
	}
	$depthmenu->command(-label => "Open all",
			    -command => sub { $w->ShowToDepth(undef) });
	my $xpath_to_selection_menuitem = $xmlmenu->command(-label => "XPath to Selection",
							    -command => sub { $w->XPathToSelection });
	$w->{XPathToSelectionMenuItem} = $xpath_to_selection_menuitem;
# XXX not yet:
#	$xmlmenu->command(-label => "Close selected region",
#			  -command => sub { $w->CloseSelectedRegion });

	no warnings 'once';
	*menu = sub {
	    my $w = shift;
	    my $menu = $w->SUPER::menu(@_);
	    if ($menu->isa("Tk::Menu")) {
		# Hack: rebless
		bless $menu, 'Tk::XMLViewer::Menu';
	    }
	    $menu;
	};
    }
}

sub XPathToSelection {
    my($w) = @_;

    my $xpath;
    if ($w->{PostPosition}) {
	# called from context menu
	my($X,$Y) = @{$w->{PostPosition}};
	$xpath = $w->GetXPathFromXY($X,$Y);
	delete $w->{PostPosition};
    } else {
	# called from normal menu
	$xpath = $w->GetXPathFromIndex('insert');
    }

    # Define a dummy widget holding the selection, so we can still use
    # the Text selection after using XPathToSelection
    my $dummy = $w->Subwidget("DummyLabelForSelection");
    if (!$dummy) {
	$dummy = $w->Component("Label" => "DummyLabelForSelection");
    }

    $dummy->SelectionOwn;
    $dummy->SelectionHandle(''); # XXX why this seems to be necessary?
    $dummy->SelectionHandle
	(sub {
	     my($offset, $maxbytes) = @_;
	     substr($xpath, $offset, $maxbytes);
	 });
}

sub PostPopupMenu {
    my $w = shift;
    my $X = shift;
    my $Y = shift;
    $w->{PostPosition} = [$X,$Y];
    $w->SUPER::PostPopupMenu($X, $Y, @_);
}

sub BalloonInfo {
    my($w,$balloon,$X,$Y,@opt) = @_;
    $w->GetXPathFromXY($X, $Y);
}

sub GetXPathFromXY {
    my($w, $X, $Y) = @_;
    $w->GetXPathFromIndex('@'.($X-$w->rootx).','.($Y-$w->rooty));
}

sub GetXPathFromIndex {
    my($w, $index) = @_;
    for my $tag ($w->tagNames($index)) {
	if ($tag =~ m{^xpath_(.*)$}) {
	    my $xpath = $1;
	    return $xpath;
	}
    }
    return '';
}

if ($Tk::VERSION >= 803) { # native unicode support
    eval <<'EOF';
sub _convert_from_unicode { $_[0] }
EOF
} elsif ($] >= 5.006001) {
    # tr translator for unicode not available anymore
    eval <<'EOF';
sub _convert_from_unicode {
    pack("C*", unpack("U*", $_[0]));
}
EOF
} elsif ($] >= 5.006) {
    # unicode translator available
    eval <<'EOF';
sub _convert_from_unicode {
    $_[0] =~ tr/\0-\x{FF}//UC;
    $_[0];
}
EOF
} else {
    # try Unicode::String
    eval <<'EOF';
require Unicode::String;
EOF
    if (!$@) {
	eval <<'EOF';
sub _convert_from_unicode {
    my $umap = Unicode::String::utf8( $_[0]);
    $umap->latin1;
}
EOF
    } else { # do nothing
        warn "No unicode decoder found --- consider installing Unicode::String";
        eval <<'EOF';
sub _convert_from_unicode { $_[0] }
EOF
    }
}

sub SourceType    { $_[0]->{Source} && $_[0]->{Source}[0] }
sub SourceContent { $_[0]->{Source} && $_[0]->{Source}[1] }

sub Showinfo {
    my $w = shift;
    $w->Busy();
    my $file;
    if($w->{Source} && $w->{Source}[0] eq 'file') {
	$file = $w->{Source}[1];
    }
    require Tk::DialogBox;
    my $d = $w->DialogBox(-title => "XMLView: Info", -buttons => ["OK"]);
    my $textbox = $d->add("Scrolled", qw/ROText -wrap none -width 60
			  -height 5 -scrollbars osw -background white/);
    $textbox->pack(qw/-side left -expand yes -fill both/);
    if (keys %{ $w->{XmlInfo} }) {
	my $message = "XMLDecl: " ;
	foreach my $i (qw(Version Encoding Standalone)) {
	    if (defined $w->{XmlInfo}{$i}) {
		$message = $message . $i . ": " . $w->{XmlInfo}{$i} . " \n  ";
	    }
	}
	$textbox->insert("end", $message);
	$message = "\nDOCTYPE: ";
	foreach my $i (qw(Name Sysid Pubid Internal)) {
	    if (defined $w->{XmlInfo}{$i}) {
		$message = $message . $w->{XmlInfo}{$i} . " \n  ";
	    }
	}
	$textbox->insert("end", $message);
    }
    if (defined $file) {
	$textbox->insert("end", "\nFile: " . $file);
	$textbox->insert("end", " \n  " . scalar( -s $file ) . " Bytes\n");
    }
    my $button = $d->Show;
    $w->Unbusy();
}

sub GetInfo { $_[0]->{XmlInfo} }

package # XXX temporarily hide from PAUSE indexer
    Tk::XMLViewer::Menu;
use base qw(Tk::Menu);

# Hackish: this is needed to clear the PostPosition member.
# Unfortunately unpost is called *before* the actual XPathToSelection
# callback is called, so in this case the PostPosition member has to
# be kept and has to be deleted in the XPathToSelection callback.
sub unpost {
    my $menu = shift;
    $menu->SUPER::unpost;
    my $xmlviewer = $menu->parent;
    return if !$xmlviewer->{XPathToSelectionMenuItem};
    my $activelabel = $Tk::activeMenu->entrycget($Tk::activeItem, '-label');
    if (defined $activelabel && $activelabel eq $xmlviewer->{XPathToSelectionMenuItem}->cget('-label')) {
	# popup menu, keep PostPosition
    } else {
	delete $menu->parent->{PostPosition};
    }
}

1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Tk::XMLViewer - Tk widget to display XML

=head1 SYNOPSIS

  use Tk::XMLViewer;
  $xmlviewer = $top->XMLViewer->pack;
  $xmlviewer->insertXML(-file => "test.xml");
  $xmlviewer->insertXML(-text => '<?xml version="1.0" encoding="ISO-8859-1" ?><a><bla /><foo>bar</foo></a>');

=head1 DESCRIPTION

Tk::XMLViewer is an widget inherited from Tk::Text which displays XML
in a hierarchical tree. You can use the plus and minus buttons to
hide/show parts of the tree.

=head2 OPTIONS

C<Tk::XMLViewer> supports all option of C<Tk::Text> and additionally
the following:

=over

=item -tagcolor => $color

Foreground color of tags.

=item -attrkeycolor => $color

Foreground color of attribute keys.

=item -attrvalcolor => $color

Foreground color of attribute values.

=item -commentcolor => $color

Foreground color of comment sections.

=back

The text tags C<xml_tag>, C<xml_attrkey>, C<xml_attrval>, and
C<xml_comment> are defined for the corresponding XML elements. If you
want to customize further you can configure the tags directly, for
example:

    $xmlviewer->tagConfigure('xml_comment', -foreground => "white",
			     -background => "red", -font => "Helvetica 6");


=head2 METHODS

=over 4

=item insertXML

Insert XML into the XMLViewer widget. Use the B<-file> argument to
insert a file and B<-text> to insert an XML string. A hash to the
B<-xmlparserargs> option will be passed to the L<XML::Parser>
constructor.

=item DumpXML

Dump the contents of an C<Tk::Text> widget into an XML string. This is
meant as a alternative to the C<Tk::Text::dump> method (in fact,
C<DumpXML> is implemented with the help of C<dump>).

The output of C<DumpXML> can be used as input for the XMLViewer
widget, which is useful in debugging C<Tk::Text> tags.

Use the static variant of C<DumpXML> for C<Tk::Text> widgets and the
method variant for C<XMLViewer> widgets.

    $xml_string1 = Tk::XMLViewer::DumpXML($text_widget);
    $xmlviewer_widget->insertXML($xml_string1);

    $xml_string2 = $xmlviewer->DumpXML;

=item SetIndent

Set indent with for XML tags

    $xmlviewer->SetIndent(width);

=item XMLMenu

Insert XML Menu into Text widget menu.

    $xmlviewer->XMLMenu;

=item SourceType

Returns type of source used for last insertXML (-file or -text)

=item SourceContent

Returns filename (source type -file) or XML text (source type -text) used
for last insertXML.

=item GetInfo

Returns hash of standard XML decl and DOCTYPE elements:

    my %xmlheader = $xmlviewer->GetInfo;

Elements for XMLdecl: Version Encoding Standalone
Elements for DOCTYPE: Name Sysid Pubid Internal

=back

=head1 NOTES

=head2 Unicode

Perl/Tk 804 has Unicode support, so has C<Tk::XMLViewer>.

Perl/Tk 800 does not support Unicode. In this case C<Tk::XMLViewer>
tries to translate all characters returned by the XML parser to the
C<iso-8859-1> charset. This may be done with a builtin function like
C<pack>/C<unpack> or a CPAN module like L<Unicode::String>. If no
fallback could be found, then Unicode characters show as binary
values.

=head1 BUGS

DumpXML will not work with nested text tags.

There should be only one insertXML operation at one time (these is
probably only an issue with threaded operations, which do not work in
Perl/Tk anyway).

Viewing of large XML files is slow.

=head1 TODO

 - show to depth n: close everything from depth n+1
 - create menu item "close selected region"
 - DTD validation (is this possible with XML::Parser?)
 - use alternative XML parser i.e. XML::LibXML::Reader (maybe this
   would be faster?)

=head1 AUTHOR

Slaven Rezic, <slaven@rezic.de>

Some additions by Jerry Geiger <jgeiger@rios.de>.

=head1 SEE ALSO

L<XML::Parser>, L<Tk::Text>, L<tkxmlview>.

=cut
