###############################################################################
#
# Win32::GUI::XMLBuilder
#
# 14 Dec 2003 by Blair Sutton <bsdz@cpan.org>
#
# Version: 0.39 (25th January 2007)
#
# Copyright (c) 2003-2007 Blair Sutton. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
###############################################################################

package Win32::GUI::XMLBuilder;

use strict;
require Exporter;
our $VERSION = 0.39;
our @ISA     = qw(Exporter);

our $AUTHOR = "Blair Sutton - 2007 - Win32::GUI::XMLBuilder - $VERSION";

use XML::Twig;
use Win32::GUI qw(WS_CAPTION WS_SIZEBOX WS_EX_CONTROLPARENT WS_CHILD DS_CONTROL WS_VISIBLE WS_VSCROLL WS_TABSTOP);

use Win32::GUI::BitmapInline ();
our $ICON = newIcon Win32::GUI::BitmapInline( q(
AAABAAEAICAAAAEAGACoDAAAFgAAACgAAAAgAAAAQAAAAAEAGAAAAAAAAAAAAEgAAABIAAAAAAAA
AAAAAAD/////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////cyfzJrfvcyfzcyfzJrfv////////////cyfzJ
rfvcyfz////////////JrfvJrfvcyfz/////////////////////////////////////////////
//////////+UW/ZeCfJeCfJeCfJwJfNeCfL////t5P6CQPVeCfJeCfJeCfJwJfPt5P7///9eCfJe
CfKUW/b////////////////////////////////////////////////////t5P5eCfJeCfKCQPVw
JfNeCfJeCfL///+md/heCfJeCfKUW/ZeCfJeCfKmd/j///9eCfJeCfKUW/b/////////////////
///////////////////////////////////JrfteCfJeCfLJrfuUW/ZeCfJeCfL///+UW/ZeCfJe
CfL///9eCfJeCfKUW/b///9eCfJeCfKUW/b/////////////////////////////////////////
///////////JrfteCfJeCfLJrfuCQPVeCfJeCfL///+UW/ZeCfJeCfL///9eCfJeCfKUW/b///9e
CfJeCfKUW/b////////////////////////////////////////////////////JrfteCfJeCfLJ
rfteCfJeCfJeCfL///+UW/ZeCfJeCfL///9eCfJeCfKUW/b///9eCfJeCfKUW/b/////////////
///////////////////////////////////////JrfteCfJeCfLJrfvJrfvJrfvJrfv///+UW/Ze
CfJeCfL///9eCfJeCfKUW/b///9eCfJeCfKUW/b/////////////////////////////////////
///////////////JrfteCfJeCfLJrfu4kvmUW/aUW/b///+UW/ZeCfJeCfL///9eCfJeCfKUW/b/
//9eCfJeCfKUW/b////////////////////////////////////////////////////JrfteCfJe
CfLJrfuUW/ZeCfJeCfL///+UW/ZeCfJeCfL///9eCfJeCfKUW/b///9eCfJeCfKUW/b/////////
///////////////////////////////////////////JrfteCfJeCfKmd/iCQPVeCfJwJfP///+U
W/ZeCfJeCfL///9eCfJeCfKUW/b///9eCfJeCfKUW/b/////////////////////////////////
//////////////////////9wJfNeCfJeCfJeCfJeCfLJrfv///+UW/ZeCfJeCfL///9eCfJeCfKU
W/b///9eCfJeCfKUW/b/////////////////////////////////////////////////////////
//+4kvmUW/aUW/bcyfz///////+4kvmUW/aUW/b///+UW/aUW/a4kvn///+UW/aUW/a4kvn/////
///////////HyceOko7///////////+Oko7Hycf///////+Oko7///+Oko7///////+Oko7////H
ycdVW1Vyd3Lj5OPHycdVW1VVW1VVW1WOko7///////////////////////////9yd3I5QDn/////
//////85QDlyd3L///////9VW1X///9VW1X///////9VW1XHycdVW1X////j5ONVW1X///9yd3Lj
5OP///////////////////////////////////85QDmOko6qrar///+qraqOko5VW1X///////9V
W1X///9VW1X///////9VW1X///////////////9VW1X///////9yd3Lj5OP/////////////////
///////////j5ONVW1Xj5ONVW1X///9yd3Lj5ONVW1Xj5OP///9VW1X///9VW1X///////9VW1X/
///////HyceOko5VW1X///////////9yd3Lj5OP///////////////////////+qraqqrar///9V
W1X///9VW1X///+qraqqrar///9VW1X///8ACQCOko6Oko5yd3L////////Hycdyd3Kqrar/////
///////j5ONyd3L///////////////////////9VW1X///////+Oko6Oko6Oko7///////9VW1X/
///Hycf////HycfHyceqrar////Hyceqrar///////9VW1XHycfHycf////j5ONVW1X/////////
//////////////9VW1X////////j5OMdJR3j5OP///////9VW1X///+Oko7/////////////////
//////9VW1VVW1U5QDnj5OP///9VW1VVW1U5QDnj5OP////////////////////6WmT+5Ob/////
///////////////7dn/8rLL////6WmT9ycz////////6WmT7kZj////////6WmT9ycz////9ycz6
WmT6WmT6WmT6WmT6WmT6WmT////////////////6WmT4IzH+5Ob////////////7kZj3Bxf+5Ob/
///5Pkv6WmT////////3Bxf3Bxf+5Ob////6WmT6WmT////+5Ob3Bxf5Pkv6WmT6WmT6WmT6WmT9
ycz////////////////6WmT4IzH+5Ob////+5Ob4IzH7kZj////////7dn/5Pkv////////3Bxf3
Bxf7dn/////7dn/5Pkv////////3Bxf7kZj////////////////////////////////////////6
WmT4IzH+5Ob7dn/4IzH////////////8rLL3Bxf////8rLL3Bxf8rLL3Bxf+5Ob8rLL3Bxf/////
///6WmT6WmT////////////////////////////////////////////6WmT4IzH3Bxf8rLL/////
///////+5Ob3Bxf9ycz8rLL3Bxf////4IzH7dn/+5Ob3Bxf9ycz////7dn/4IzH/////////////
///////////////////////////////////4IzH3Bxf+5Ob////////////////4IzH7kZj8rLL3
Bxf////7kZj3Bxf+5Ob4IzH7kZj////8rLL3Bxf/////////////////////////////////////
///////8rLL3Bxf6WmT4IzH+5Ob////////////6WmT6WmT7dn/5Pkv////////4IzH7dn/6WmT6
WmT////+5Ob3Bxf8rLL////////////////////////////////////////4IzH7dn/////6WmT4
IzH+5Ob////////7kZj4IzH6WmT6WmT////////7kZj3Bxf7dn/4IzH////////3Bxf7kZj/////
///////////////////////////////7kZj4IzH+5Ob////////6WmT4IzH+5Ob////8rLL3Bxf5
Pkv6WmT////////////4IzH5Pkv3Bxf////////6WmT6WmT/////////////////////////////
///+5Ob3Bxf7kZj////////////////6WmT4IzH+5Ob////3Bxf3Bxf7kZj////////////7kZj3
Bxf3Bxf8rLL////7dn/4IzH////////////////////////////////+5Ob8rLL/////////////
///////////8rLL9ycz////8rLL8rLL+5Ob////////////////8rLL8rLL+5Ob////+5Ob8rLL/
////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////8A
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAA==
) );

=head1 NAME

XMLBuilder - Build Win32::GUIs using XML.

=head1 SYNOPSIS

	use Win32::GUI::XMLBuilder;
	
	my $gui = Win32::GUI::XMLBuilder->new({file=>"file.xml"});
	my $gui = Win32::GUI::XMLBuilder->new(*DATA);
	
	Win32::GUI::Dialog;
	
	sub test {
	 $gui->{Status}->Text("testing 1 2 3..");
	}
	
	...
	
	__END__
	<GUI>
	
	..
	</GUI>

=head1 DEPENDENCIES

	XML::Twig
	Win32::GUI

=head1 DESCRIPTION

This module allows Win32::GUIs to be built using XML.
For examples on usage please look in samples/ directory.

=head1 XML SYNTAX

XMLBuilder will parse an XML file or string that contains elements
that describe a Win32::GUI object.

All XML documents must be enclosed in <GUI>..</GUI> elements and each
separate GUI window must be enclosed in <Window>..</Window> elements.
To create a N-tier window system one might use a construction similar to: -

	<GUI>
	 <Window name="W_1">
	  ...
	 </Window>
	 <Window name="W_2">
	  ...
	 </Window>
	 <Window name="W_N">
	  ...
	 </Window>
	</GUI>

=head1 ATTRIBUTES

Elements can additionally be supplemented with attributes that describe its
corresponding Win32::GUI object's properties such as top, left, height and
width. These properties usually include those provided as standard in each
Win32::GUI class. I.e.

	<Window height="200" width="200" title="My Window"/>

Elements that require referencing in your code should be given a name attribute.
An element with attribute: -

	<Button name="MyButton"/>

can be called as $gui->{'MyButton'} and event subroutines called using MyButton_Click.
From within an XML string the element must be called by $self->{'MyButton'}.

Attributes can contain Perl code or variables and generally any attribute that
contains the variable '$self' or starts with 'exec:' will be evaluated. This is useful
when one wants to create dynamically sizing windows: -

	<Window name='W'
	 left='0' top='0'
	 width='400' height='200'
	>
	 <StatusBar name='S'
	  left='0' top='$self->{W}->ScaleHeight-$self->{S}->Height'
	  width='$self->{W}->ScaleWidth' height='$self->{S}->Height'
	 />
	</Window>

=head1 SPECIAL SUBSTITUTION VARIABLES

If an attribute contains the string %P% then it is subsituted with $self->{<parent>}. Where
<parent> is the name of the current elements parent. It is useful when specifying child
dimensions where the parent is nameless.

=head1 SPECIFYING DIMENSIONS

'pos' and 'size' attributes are supported but converted to top, left, height and width
attributes on parsing. I suggest using the attribute dim='left,top,width,height' instead
(not an array but an list with brackets).

=cut

sub expandDimensions {
	my ($self, $e) = @_;

	if (exists $e->{'att'}->{'pos'}) {
		if ($e->{'att'}->{'pos'} =~ m/^\[\s*(.+)\s*,\s*(.+)\s*\]$/) {
			($e->{'att'}->{'top'}, $e->{'att'}->{'left'}) = ($1, $2);
			delete $e->{'att'}->{'pos'};
		} else {
			$self->debug("Failed to parse pos '$e->{att}->{pos}', should have format '[top, left]'");
		}
	}

	if (exists $e->{'att'}->{'size'}) {
		if ($e->{'att'}->{'size'} =~ m/^\[\s*(.+)\s*,\s*(.+)\s*\]$/) {
			($e->{'att'}->{'width'}, $e->{'att'}->{'height'}) = ($1, $2);
			delete $e->{'att'}->{'size'};
		} else {
			$self->debug("Failed to parse size '$e->{att}->{size}', should have format '[width, height]'");
		}
	}

	if (exists $e->{'att'}->{'dim'}) {
		if ($e->{'att'}->{'dim'} =~ m/^\s*(.+)\s*,\s*(.+)\s*,\s*(.+)\s*,\s*(.+)\s*$/) {
			($e->{'att'}->{'left'}, $e->{'att'}->{'top'}, $e->{'att'}->{'width'}, $e->{'att'}->{'height'}) = ($1, $2, $3, $4);
			delete $e->{'att'}->{'dim'};
		} else {
			$self->debug("Failed to parse dim '$e->{att}->{dim}', should have format 'left, top, width, height'");
		}
	}

	return $e;
}

=head1 AUTO-RESIZING

Win32::GUI::XMLBuilder will autogenerate an onResize NEM method by reading in values for top, left, height and width.
This will work sufficiently well provided you use values that are dynamic such as $self->{PARENT_WIDGET}->Width,
$self->{PARENT_WIDGET}->Height for width, height attributes respectively when creating new widget elements.

=cut

sub genresize {
	my ($self, $name) = @_;

	my $coderef = eval "{
		package main; no strict;
		sub {
			foreach (\@{\$self->{_worder_}{$name}}) {
				my \$width = eval \$self->{_width_}{$name}{\$_};
				\$self->debug(\"\$_: Width to \$self->{_width_}{$name}{\$_} = \$width\");
				\$self->{\$_}->Width(\$width) if \$_ ne '$name';
			}
			foreach (\@{\$self->{_horder_}{$name}}) {
				my \$height = eval \$self->{_height_}{$name}{\$_};
				\$self->debug(\"\$_: Height to \$self->{_height_}{$name}{\$_} = \$height\");
				\$self->{\$_}->Height(\$height) if \$_ ne '$name';
			}

			foreach (\@{\$self->{_lorder_}{$name}}) {
				my \$left = eval \$self->{_left_}{$name}{\$_};
				\$self->debug(\"\$_: Left to \$self->{_left_}{$name}{\$_} = \$left\");
				\$self->{\$_}->Left(\$left) if \$_ ne '$name';
			}
			foreach (\@{\$self->{_torder_}{$name}}) {
				my \$top = eval \$self->{_top_}{$name}{\$_};
				\$self->debug(\"\$_: Top to \$self->{_top_}{$name}{\$_} = \$top\");
				\$self->{\$_}->Top(\$top) if \$_ ne '$name';
			}
		}
	}";	print STDERR $@ if $@;
	
	return $coderef;
}

=head1 NEM EVENTS

NEM events are supported. When specifying a NEM event such as onClick one must use $self syntax to specify current
Win32::GUI::XMLBuilder object in anonymous subroutines. An attribute of notify='1' is added automatically when an
NEM event is called. One can alo specify other named subroutines by name, but do not prefix with an ampersand! i.e.

	onClick='my_sub' [CORRECT]
	onClick='&my_sub' [INCORRECT]

=head1 SIMPLE POSITION AND SIZE

If no dimensions are given for an element whose direct parent is of a Top level widget type such as Window or DialogBox,
it will assume a top and left of zero and and a width and height of its parent. I.e.

	dim='0, 0, $self->{PARENT}->ScaleWidth, $self->{PARENT}->ScaleHeight'

=cut

my $qrTop = qr/(Window|DialogBox|MDIFrame|MDIClient|MDIChild)$/;
my $qrFile = qr/(Icon|Bitmap|Cursor)$/;
my $qrNoParent = qr/(Font|Class|Pen|Brush)$/;
my $qrNoDim = qr/(NotifyIcon)$/;
my $qrLRWidgets = qr/(Grid|DIBitmap|AxWindow|Scintilla|ScintillaPerl)$/;

sub evalhash {
	my ($self, $e) = @_;

	$e = $self->expandDimensions($e);
	my %in = %{$e->{'att'}};
	my %out;
	
	my $parent = $self->getParent($e);
	
	foreach my $k (sort keys %in) {
		$in{$k} =~ s/%P%/\$self->{$parent}/g; # sub %P% for parent
		if ($k =~ /^on[A-Z]/) {
			$out{-notify} = 1;
			if ($in{$k} =~ /^\s*sub\s*\{.*\}\s*/s) {
				$out{-$k} = eval "{ package main; no strict; use Win32::GUI(); ".$in{$k}."}"; print STDERR $@ if $@;
			} else {
				$out{-$k} = $in{$k};
			}
		} elsif ($in{$k} =~ /\$self|(^\s*exec:)/) {
			(my $eval = $in{$k}) =~ s/(^\s*exec:)//;
			$out{-$k} = eval "{ package main; no strict; use Win32::GUI(); ".$eval."}"; print STDERR $@ if $@;
		} else {
			$out{-$k} = $in{$k};
		}

		$self->debug("\t-$k : $in{$k} -> $out{-$k}");
	}

	if (defined $parent) {

		if (!$in{_nowidth_}) {
			if (exists $in{width} && $in{width} ne '') {
				$self->{_width_}{$parent}{$out{-name}} = $in{width};
				push @{$self->{_worder_}{$parent}}, $out{-name};
			} elsif ($e->gi !~ /^$qrNoDim/ && ref($self->{$e->parent->{'att'}->{'name'}}) =~ /^Win32::GUI::$qrTop/) {
				$self->{_width_}{$parent}{$out{-name}} = "\$self->{$parent}->ScaleWidth"; # since we know $parent must be direct ancestor
				push @{$self->{_worder_}{$parent}}, $out{-name};
				$out{-width} = eval "{ package main; no strict; use Win32::GUI(); \$self->{$parent}->ScaleWidth }"; print STDERR $@ if $@;
			}
		}
		
		if (!$in{_noheight_}) {
			if (exists $in{height} && $in{height} ne '') {
				$self->{_height_}{$parent}{$out{-name}} = $in{height};
				push @{$self->{_horder_}{$parent}}, $out{-name};
			} elsif ($e->gi !~ /^$qrNoDim/ && ref($self->{$e->parent->{'att'}->{'name'}}) =~ /^Win32::GUI::$qrTop/) {
				$self->{_height_}{$parent}{$out{-name}} = "\$self->{$parent}->ScaleHeight";
				push @{$self->{_horder_}{$parent}}, $out{-name};
				$out{-height} = eval "{ package main; no strict; use Win32::GUI(); \$self->{$parent}->ScaleHeight }"; print STDERR $@ if $@;
			}
		}
		
		if (!$in{_noleft_}) {
			if (exists $in{left} && $in{left} ne '') {
				$self->{_left_}{$parent}{$out{-name}} = $in{left};
				push @{$self->{_lorder_}{$parent}}, $out{-name};
			} elsif ($e->gi !~ /^$qrNoDim/ && ref($self->{$e->parent->{'att'}->{'name'}}) =~ /^Win32::GUI::$qrTop/) {
				$self->{_left_}{$parent}{$out{-name}} = "0";
				push @{$self->{_lorder_}{$parent}}, $out{-name};
				$out{-left} = 0;
			}
		}
		
		if (!$in{_notop_}) {
			if (exists $in{top} && $in{top} ne '') {
				$self->{_top_}{$parent}{$out{-name}} = $in{top};
				push @{$self->{_torder_}{$parent}}, $out{-name};
			} elsif ($e->gi !~ /^$qrNoDim/ && ref($self->{$e->parent->{'att'}->{'name'}}) =~ /^Win32::GUI::$qrTop/) {
				$self->{_top_}{$parent}{$out{-name}} = "0";
				push @{$self->{_torder_}{$parent}}, $out{-name};
				$out{-top} = 0;
			}
		}
	}

	return %out;
}

sub getParent {
	my ($self, $e) = @_;

	if (ref $e ne 'XML::Twig::Elt' || $e->level == 1) {
		return undef;
	}

	my $xmlparent = $e->parent(sub {
		return ref($self->{$_[0]->{'att'}->{'name'}}) =~ /^Win32::GUI::$qrTop/ 
	});

	# should return undef if no parent found!
	return $xmlparent->{'att'}->{'name'};
}

=head1 AUTO WIDGET NAMING

Win32::GUI::XMLBuilder will autogenerate a name for a wiget if a 'name' attribute is not
provided. The current naming convention is Widget_Class_N where N is a number. For example
Button_1, Window_23, etc...

=cut

sub genname {
	my ($self, $e) = @_;
	if (!exists $e->{'att'}->{'name'} || $e->{'att'}->{'name'} eq '') {
		my $i = 0;
		while () {
			if (!exists $self->{$e->gi.'_'.$i}) {
				$e->set_att(name=>$e->gi.'_'.$i);
				last;
			}
			$i++;
		}
	}
	return $e->{'att'}->{'name'};
}

=head1 ENVIRONMENT VARIABLES

=over 4

=item WIN32GUIXMLBUILDER_DEBUG

Setting this to 1 will produce logging.

=cut

sub debug {
	my $self = shift;
	print "$_[0]\n" if $ENV{WIN32GUIXMLBUILDER_DEBUG};
}

sub error {
	my $self = shift;
	my $sub  = (caller(1))[3];
	my $line  = (caller(1))[2];
	$self->debug("$sub error on line $line: $^E $!");
	print STDERR "$sub error on line $line: $^E $!\n";
}

=head1 METHODS

=over 4

=item new({file=>$file}) or new($xmlstring)

=cut

sub new {
	my $this = shift;
	my $self = {};
	$self->{_show_}    = undef; # ...{parent} = COMMAND
	$self->{_width_}   = undef; # ...{parent}{child}
	$self->{_worder_}  = undef; # ...{parent} = (child1, child2, ...)
	$self->{_height_}  = undef; # ...{parent}{child}
	$self->{_horder_}  = undef; # ...{parent} = (child1, child2, ...)
	$self->{_left_}    = undef; # ...{parent}{child}
	$self->{_lorder_}  = undef; # ...{parent} = (child1, child2, ...)
	$self->{_top_}     = undef; # ...{parent}{child}
	$self->{_torder_}  = undef; # ...{parent} = (child1, child2, ...)
	$self->{_menuid_}  = 1; # menu id counter (see Win32/GUI.pm/MakeMenu)

	bless($self, (ref($this) || $this));

	my $s = new XML::Twig(
		TwigHandlers => {
			Script     => sub { $self->WGXPre(@_) },
			PreExec    => sub { $self->WGXPre(@_) },
			WGXPre    => sub { $self->WGXPre(@_) },
		}
	);

	if (ref($_[0]) eq 'HASH') {
		$self->debug("processing file ${$_[0]}{file}");
		$s->parsefile(${$_[0]}{file})
	}
	else {
		$s->parse($_[0])
	}

	my $t = new XML::Twig;
	$t->parse($s->sprint);
	my $root = $t->root; 
	foreach ($root->children()) {
		#$self->debug($_->{'att'}->{'name'});
		#$self->debug($_->gi);
		next if $_->gi eq 'WGXPost' or $_->gi eq 'PostExec';

		if (exists &{$_->gi}) {
			&{\&{$_->gi}}($self, $t, $_);
		}	
		elsif ($_->gi =~ /^$qrTop/) {
			$self->_GenericTop($t, $_);
		} 
		elsif ($_->gi =~ /^$qrFile/) {
			$self->_GenericFile($t, $_);
		} 
		elsif ($_->gi =~ /^$qrNoParent/) {
			$self->_GenericNoParent($t, $_);
		}
	}

	foreach (sort keys %{$self->{_show_}}) {
		$self->debug("show widget $_ with command ${$self->{_show_}}{$_}");
		
		if (${$self->{_show_}}{$_} =~ /\$self|(^\s*exec:)/) {
			(my $eval = ${$self->{_show_}}{$_}) =~ s/(^\s*exec:)//;
			${$self->{_show_}}{$_} = eval "{ package main; no strict; use Win32::GUI(); ".$eval."}"; print STDERR $@ if $@;
		}
		
		$self->{$_}->Show(${$self->{_show_}}{$_});
	}

	my $u = new XML::Twig(
		TwigHandlers => {
			PostExec    => sub { $self->WGXPost(@_) },
			WGXPost    => sub { $self->WGXPost(@_) },
		}
	);

	$u->parse($t->sprint);

	return $self;
}


=head1 SUPPORTED WIDGETS - ELEMENTS

Most Win32::GUI widgets are supported and general type widgets can added without any modification
being added to this module.

=over 4

=item <WGXPre>

The <WGXPre> element is parsed before GUI construction and is useful for defining subroutines
and global variables. Code is wrapped in a { package main; no strict; .. } so that if subroutines
are created they can contain variables in your program including Win32::GUI::XMLBuilder instances.
The current Win32::GUI::XMLBuilder instance can also be accessed outside subroutines as $self.
If any data is returned it must be valid XML that will be parsed once by the WGXPost phase, see below.

Since you may need to use a illegal XML characters within this element such as

	<  less than      (&lt;)
	>  greater than   (&gt;)
	&  ampersand      (&amp;)
	'  apostrophe     (&apos;)
	"  quotation mark (&quot;)

you can use the alternative predefined entity reference or enclose this data in a "<![CDATA[" "]]>" section.
Please look at the samples and read http://www.w3schools.com/xml/xml_cdata.asp.

The <WGXPre> element was previously called <PreExec>. The <PreExec> tag is deprecated but remains
only for backward compatibility and will be removed in a later release.

=cut

sub WGXPre {
	my ($self, $t, $e) = @_;

	$self->debug($e->text);
	my $ret = eval "{ package main; no strict; ".$e->text."}";
	print STDERR "$@" if $@;
	$self->debug($ret);
	$e->set_text('');
	my $pcdata= XML::Twig::Elt->new(XML::Twig::ENT, $ret);
	$pcdata->paste($e);
	$e->erase();
}

=item <WGXExec>

The <WGXExec> element is parsed during GUI construction and allows code to be inserted at arbitrary points in the code.
It otherwise behaves exactly the same as <WGXPre> and can be used to place _Resize subroutines. If any data is returned
it must be valid XML that will be parsed once by the WGXPost phase, see below.

=cut

sub WGXExec { 	WGXPre(@_) }

=item <WGXPost>

The <WGXPost> element is parsed after GUI construction and allows code to be included at the end of an XML file.
It otherwise behaves exactly the same as <WGXPre> and can be used to place _Resize subroutines.

The <WGXPost> element was previously called <PostExec>. The <PostExec>
tag is deprecated but remains only for backward compatibility and will be removed in a later release.

=cut

sub WGXPost {
	my ($self, $t, $e) = @_;

	$self->debug($e->text);
	my $ret = eval "{ package main; no strict; ".$e->text."}";
	print STDERR "$@" if $@;
	$self->debug($ret);
}

=item <Icon>, <Bitmap> and <Cursor> elements.

The <Icon> element allows you to specify an Icon for your program.

	<Icon file="myicon.ico" name='MyIcon' />

The <Bitmap> element allows you to specify an Bitmap for your program.

	<Bitmap file="bitmap.bmp" name='Image' />

The <Cursor> element allows you to specify an Cursor for your program.

	<Cursor file="mycursor.cur" name='Cursor' />

=cut

sub _GenericFile {
	my ($self, $t, $e) = @_;
	my $widget = $e->gi;
	my $name = $self->genname($e);
	my $file = $e->{'att'}->{'file'} !~ /\$/ ? $e->{'att'}->{'file'} : eval $e->{'att'}->{'file'};;

	$self->debug("\n$widget (_GenericFile): $name");
	$self->debug("file -> $file");
	$self->{$name} = eval "new Win32::GUI::$widget('$file')"  || $self->error;
}

=item <ImageList>

	<ImageList name='IL' width='16' height='16' maxsize='10'>
	 <Item bitmap='one.bmp'/>
	 <Item bitmap='two.bmp'/>
	 <Item bitmap='$self->{Bitmap}'/>
	</ImageList>

=cut

sub ImageList {
	my ($self, $t, $e) = @_;
	my $name    = $self->genname($e);
	my %opt     = $self->evalhash($e);
	my $width   = $opt{-width}  || 16;
	my $height  = $opt{-height} || 16;
	my $initial = $e->children_count();
	my $growth  = $opt{-growth} || (2 * $initial);

	$self->debug("\nImageList: $name");
	$self->{$name} = new Win32::GUI::ImageList($width, $height, 0, $initial, $growth) || $self->error;

	foreach ($e->children()) {
		my %chopt = $self->evalhash($_);
		if (exists $chopt{-bitmap}) {
			$self->{$name}->Add($chopt{-bitmap}, $chopt{-mask});
			$self->debug($chopt{-bitmap});
		} elsif (exists $chopt{-icon}) {
			$self->{$name}->AddIcon($chopt{-icon});
			$self->debug($chopt{-icon});
		}
	}
}

=item <Font>

Allows you to create a font for use in your program.

	<Font name='Bold'
	 size='8'
	 face='Arial'
	 bold='1'
	 italic='0'
	/>

You might call this in a label element using something like this: -

	<label
	 text='some text'
	 font='$self->{Bold}'
	 ...
	/>.

=item <Class>

You can create a <Class> element,

	<Class name='MyClass' icon='$self->{MyIcon}'/>

that can be applied to a <Window .. class='$self->{MyClass}'>. The name of a class must be unique
over all instances of Win32::GUI::XMLBuilder instances!

Typically one might add an icon to your application using a Class element, i.e.

	<GUI>
	 <Icon file="myicon.ico" name='MyIcon'/>
	 <Class name='MyClass' icon='$self->{MyIcon}'/>
	 <Window class='$self->{MyClass}'/>
	</GUI>

=cut

sub _GenericNoParent {
	my ($self, $t, $e) = @_;
	my $widget = $e->gi;
	my $name = $self->genname($e);

	$self->debug("\n$widget (_GenericNoParent): $name");
	$self->{$name} = eval "new Win32::GUI::$widget(\$self->evalhash(\$e))" || $self->error;
}

=item <WGXMenu>

Creates a menu system. Submenus can be nested many times more deeply than using MakeMenu. Although
one can use Item elements throughout the structure it is more readable to use the Button attribute
when a new nest begins. I.e.

	<WGXMenu>
	 <Button>
	  <Item/>
	 </Button>
	</WGXMenu>

and

	<WGXMenu>
	 <Item>
	  <Item/>
	 </Item>
	</WGXMenu>

are equivalent but the former is more true to what is happening under the hood. One can generally pass
a Button to TrackPopupMenu and a Button handle to MDIClient's windowmenu attribute.

A separator line can be specified by setting the separator attribute to 1.

One can also use NEM events directly as attributes such as onClick (or OEM events by using
PopupMenu_Click), etc..

	<WGXMenu name='Menu'>
	 <Button name='PopupMenu' text='ContextMenu'>
	  <Item name='OnEditCut' text='Cut' onClick='OnEditCut'/>
	  <Item name='OnEditCopy' text='Copy' onClick='sub { ... do something ...}'/>
	  <Item name='OnEditPaste' text='Paste'/>
	  <Item separator='1'/>
	  <Item name='SelectAll' text='>Select All'/>
	 </Button>
	</WGXMenu>

See the menus.xml for an extensive example in the samples/ directory.

=cut

sub WGXMenu {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);

	$self->debug("\nWGXMenu: $name");
	$self->{$name} = new Win32::GUI::Menu() || $self->error;
	
	foreach my $button ($e->children()) {
		next if $button->gi !~ /^(Item|Button)$/; 
		$self->WGXMenu_Button($button, $name);
	}
}

sub WGXMenu_Button {
	my ($self, $e, $parent) = @_;
	my $name = $self->genname($e);
	$e->{'att'}->{'id'} = $self->{_menuid_}++;
	
	$self->debug("\nWGXMenu_Button: $name");
	$self->{$name} = $self->{$parent}->AddMenuButton($self->evalhash($e));
	
	foreach my $item ($e->children()) {
		$item->{'att'}->{'id'} = $self->{_menuid_}++;
		my $iname = $self->genname($item);
		if ($item->gi eq 'Button' || $item->children_count()) {
			$self->{'submenu'.$self->{_menuid_}} = new Win32::GUI::Menu();
			my $bname = $self->WGXMenu_Button($item, 'submenu'.$self->{_menuid_});
			$item->{'att'}->{'submenu'} = $self->{$bname};
			$self->{$name}->AddMenuItem($self->evalhash($item));
		} elsif ($item->gi eq 'Item') {
			$self->{$iname} = $self->{$name}->AddMenuItem($self->evalhash($item));
		}
	}
	return $name;
}

=item <MakeMenu>

Creates a menu system. The amount of '>'s prefixing a text label specifies the menu items
depth. A value of text '-' (includes '>-', '>>-', etc) creates a separator line. To access
named menu items one must use the menu widgets name, i.e. $gui->{PopupMenu}->{SelectAll},
although one can access an event by its name, i.e. SelectAll_Click. One can also use NEM
events directly as attributes such as onClick, etc..

	<MakeMenu name='PopupMenu'>
	 <Item text='ContextMenu'/>
	 <Item name='OnEditCut' text='>Cut'/>
	 <Item name='OnEditCopy' text='>Copy'/>
	 <Item name='OnEditPaste' text='>Paste'/>
	 <item text='>-' />
	 <Item name='SelectAll' text='>Select All'/>
	 <item text='>-' />
	 <Item name='Mode' text='>Mode' checked='1'/>
	</MakeMenu>

See the makemenu.xml example in the samples/ directory. The MakeMenu element suffers from
the limitation of being only able to nest menus to 2 layers. This is inherent from the
underlying Win32::GUI module. I would suggest using the more configurable WGXMenu above.

The <MakeMenu> element was previously called <Menu>. The <Menu> tag is deprecated but remains
only for backward compatibility and will be removed in a later release. Please try to update
your code to use MakeMenu instead.

=cut

sub Menu { MakeMenu(@_) }

sub MakeMenu {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);

	$self->debug("\nMenu: $name");
	my @m;
	foreach ($e->children()) {
		next if $_->gi ne 'Item';
		$_->{'att'}->{'name'} = '0' if ! exists $_->{'att'}->{'name'};
		my $label = $_->{'att'}->{'text'};
		$self->debug("Text: $label");
		delete $_->{'att'}->{'text'}; # prevents preformated text becoming label
		push @m, $label, { $self->evalhash($_) };
	}
	$self->{$name} = Win32::GUI::MakeMenu(@m) || $self->error;
}

=item <AcceleratorTable>

Creates a key accelerator table.

	<AcceleratorTable name='Accel'>
	 <Item key='Ctrl-X' sub='Close'/>
	 <Item key='Shift-N' sub='New'/>
	 <Item key='Ctrl-Alt-Del' sub='Reboot'/>
	 <Item key='Shift-A' sub='sub { print "Hello\n"; }'/>
	</AcceleratorTable>

=cut

sub AcceleratorTable {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);

	$self->debug("\nAcceleratorTable: $name");
	my @a;
	foreach ($e->children()) {
		my $key = $_->{'att'}->{'key'};
		my $sub = $_->{'att'}->{'sub'};
		if ($sub =~ /^\s*sub\s*\{.*\}\s*/) {
			$sub = eval "{ package main; no strict; use Win32::GUI(); ".$sub."}"; print STDERR $@ if $@;
		} else {
			$sub = \&{'::'.$sub};
		}
		$self->debug("$key -> $sub");
		push @a, $key, $sub;
	}
	$self->{$name} = new Win32::GUI::AcceleratorTable(@a) || $self->error;
}


=item <Window>

The <Window> element creates a top level widget. In addition to standard
Win32::GUI::Window attributes it also has a 'show=n' attribute. This instructs XMLBuilder
to give the window a Show(n) command on invocation.

	<Window show='0' ... />

NOTE: Since the onResize event is defined automatically for the this element one must set
the attribute 'eventmodel' to 'both' to allow <Window_Name>_Event events to be caught!

=item <DialogBox>

<DialogBox> is very similar to <Window>, except that by default it cannot be resized and it
doesn't have the minimize and maximize buttons.

=item <MDIFrame>

The <MDIFrame> element creates a Multiple Document Interface. It has a similar behaviour
to the <Window> attribute. PLease see the MDI.xml sample.

=cut

sub _GenericTop {
	my ($self, $t, $e) = @_;
	my $widget = $e->gi;
	my $name = $self->genname($e); # should this be allowed?
	my $show = $e->{'att'}->{'show'};

	$self->debug("\n$widget (_GenericTop): $name");
	$self->{$name} = eval "new Win32::GUI::$widget(\$self->evalhash(\$e))" || $self->error;
	$self->{$name}->SetEvent('Resize', $self->genresize($name));
	
	${$self->{_show_}}{$name} = $show eq '' ? 1 : $show;

	foreach ($e->children()) {
		if (exists &{$_->gi}) {
			&{\&{$_->gi}}($self, $t, $_);
		}	else {
			$self->_Generic($t, $_);
		}
	}
}

=item <WGXPanel>

A WGXPanel is a shorthand for a Window element with popstyles WS_CAPTION, WS_SIZEBOX and WS_EX_CONTROLPARENT
and pushstyles WS_CHILD, DS_CONTROL and WS_VISIBLE. It is useful for grouping controls together.

	<WGXPanel ...>
	 ...
	</WGXPanel>

=cut

sub WGXPanel {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $parent = $self->getParent($e);
	my $show = $e->{'att'}->{'show'};

	$self->debug("\nWGXPanel: $name; Parent: $parent");

	$e->{'att'}->{'parent'} = $self->{$parent};
	$e->{'att'}->{'popstyle'} = WS_CAPTION()|WS_SIZEBOX()|WS_EX_CONTROLPARENT();
	$e->{'att'}->{'pushstyle'} = WS_CHILD()|DS_CONTROL()|WS_VISIBLE();

	$self->debug("\nWGXPanel: $name");
	$self->{$name} = eval "new Win32::GUI::Window(\$self->evalhash(\$e))" || $self->error;
	$self->{$name}->SetEvent('Resize', $self->genresize($name));
	
	${$self->{_show_}}{$name} = $show eq '' ? 1 : $show;

	foreach ($e->children()) {
		if (exists &{$_->gi}) {
			&{\&{$_->gi}}($self, $t, $_);
		}	else {
			$self->_Generic($t, $_);
		}
	}

}


=item <TreeView>

Creates a TreeView. These can be nested deeply using the sub element <Item>. Please look at the
treeview.pl example in the samples/ directory.

	<TreeView ..>
	 <Item .. />
	  <Item ..>
	   <Item .. />
	   <Item .. />
	    etc...
	  </item>
	 ...
	</TreeView>

=cut

sub TreeView {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $parent = $self->getParent($e);

	$self->debug("\nTreeView: $name; Parent: $parent");
	$self->{$name} = $self->{$parent}->AddTreeView($self->evalhash($e))  || $self->error;

	if($e->children_count()) {
		$self->TreeView_Item($e, $name);
	}
}

sub TreeView_Item {
	my ($self, $e, $parent) = @_;
	my $name = $e->{'att'}->{'name'};
	foreach my $item ($e->children()) {
		next if $item->gi ne 'Item';
		my $iname = $item->{'att'}->{'name'};
		$self->debug("Item: $iname; Parent: $name");
		$item->{'att'}->{'parent'} = "\$self->{$name}" if $name ne $parent;
		$self->{$iname} = $self->{$parent}->InsertItem($self->evalhash($item));
		if($item->children_count()) {
			$self->TreeView_Item($item, $parent);
		}
	}
}

=item <Combobox>

Generate a combobox with drop down items specified with the <Items> elements. In addition
to standard attributes for Win32::GUI::Combobox there is also a 'dropdown' attribute that
automatically sets the 'pushstyle' to 'WS_VISIBLE()|0x3|WS_VSCROLL()|WS_TABSTOP()'. In 'dropdown'
mode an <Item> element has the additional attribute 'default'.

=cut

sub Combobox {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $parent = $self->getParent($e);

	$self->debug("\nCombobox: $name; Parent: $parent");

	$e->{'att'}->{'pushstyle'} = WS_VISIBLE()|0x3|WS_VSCROLL()|WS_TABSTOP() if $e->{'att'}->{'dropdown'};

	$self->{$name} = $self->{$parent}->AddCombobox($self->evalhash($e)) || $self->error;

	my $default;
	if($e->children_count()) {
		foreach my $item ($e->children()) {
			next if $item->gi ne 'Item';
			my $text = $item->{'att'}->{'text'};
			$default = $text if $item->{'att'}->{'default'};
			$self->debug("Item: $text");
			$self->{$name}->InsertItem($text);
		}
	}

	$self->{$name}->Select($self->{$name}->FindStringExact($default)) if $default;
}

=item <Listbox>

Generate a listbox with drop down items specified with the <Items> elements. In addition
to standard attributes for Win32::GUI::Listbox there is also a 'dropdown' attribute that
automatically sets the 'pushstyle' to 'WS_CHILD()|WS_VISIBLE()|1'. In 'dropdown' mode an <Item> element has
the additional attribute 'default'.

=cut

sub Listbox {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $parent = $self->getParent($e);

	$self->debug("\nListbox: $name; Parent: $parent");
	$e->{'att'}->{'pushstyle'} = $e->{'att'}->{'dropdown'} ? WS_VSCROLL()|WS_CHILD()|WS_VISIBLE()|1 : WS_VSCROLL()|WS_VISIBLE()|WS_CHILD();
	$self->{$name} = $self->{$parent}->AddListbox($self->evalhash($e))  || $self->error;

 # $self->{$name}->SendMessage(0x0195, 201, 0);

	my $default;
	if($e->children_count()) {
		foreach my $item ($e->children()) {
			next if $item->gi ne 'Item';
			my $text = $item->{'att'}->{'text'};
			$default = $text if $item->{'att'}->{'default'};
			$self->debug("Item: $text");
			$self->{$name}->AddString($text);
		}
	}

	$self->{$name}->Select($self->{$name}->FindStringExact($default)) if $default;
}

=item <Rebar>

See rebar.xml example in samples/ directory.

=cut

sub Rebar {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $parent = $self->getParent($e);

	$self->debug("\nRebar: $name; Parent: $parent");
	$self->{$name} = $self->{$parent}->AddRebar($self->evalhash($e)) || $self->error;
	foreach my $item ($e->children()) {
		my $bname = $self->genname($item);
		$self->debug("Band: $bname");

		my $f;
		$f->{'att'}->{'parent'} = $self->{$parent};
		$f->{'att'}->{'popstyle'} = WS_CAPTION()|WS_SIZEBOX();
		$f->{'att'}->{'pushstyle'} = WS_CHILD();
		# push non-Band attributes into Window class
		foreach (keys %{$item->{'att'}}) {
			if ($_ !~ /^(image|index|bitmap|child|foreground|background|width|minwidth|minheight|text|style)$/) {
				$f->{'att'}->{$_} = $item->{'att'}->{$_};
			}
		}
		$self->debug("Window: $bname");
		$self->{$bname} = new Win32::GUI::Window($self->evalhash($f)) || $self->error;
		$item->{'att'}->{'child'} = $self->{$bname};
		
		$self->{$bname}->SetEvent('Resize', $self->genresize($bname));

		foreach ($item->children()) {
			$self->debug($_->{'att'}->{'name'});
			$self->debug($_->gi);

			if (exists &{$_->gi}) {
				&{\&{$_->gi}}($self, $t, $_);
			}	else {
				$self->_Generic($t, $_);
			}
		}

		$self->{$name}->InsertBand($self->evalhash($item));
	}
}

=item <TabStrip>

A TabStrip can be created using the following structure: -

	<TabStrip ...>
	 <Item name='P0' text='Zero'>
	  <Label text='Tab 1' .... />
	 </Item>
	 <Item name='P1' text='One'>
	  <Label text='Tab 2' .... />
	   ..other elements, etc...
	 </Item>
	</TabStrip>

See wizard_tabstrip.xml example in samples/ directory.

=item <TabFrame>

A TabFrame should behave identically to a TabStrip. TabFrame is no longer supported
and will be removed from a future release. Please try to update your code to use
TabStrip instead.

=cut

sub TabFrame { TabStrip(@_); }

sub TabStrip {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $parent = $self->getParent($e);

	$e->{'att'}->{'onChange'} = "sub {
		my \$i;
		for (\$i = 0; \$i < \$_[0]->Count; \$i++) {
			\$self->{\$self->{$name}->{\$i}}->Show(\$_[0]->SelectedItem == \$i ? 1 : 0);
		}
	}";

	$self->debug("\nTabStrip: $name; Parent: $parent");
	$self->{$name} = $self->{$parent}->AddTabStrip($self->evalhash($e)) || $self->error;
	my $tabcount = 0;
	foreach my $item ($e->children()) {
		my $bname = $self->genname($item);
		$self->debug("Tab: $bname");

		my $f;
		$f->{'att'}->{'parent'} = $self->{$parent};
		$f->{'att'}->{'popstyle'} = WS_CAPTION()|WS_SIZEBOX()|WS_EX_CONTROLPARENT();
		$f->{'att'}->{'pushstyle'} = WS_CHILD()|DS_CONTROL();
		$f->{'att'}->{'pushstyle'} |= WS_VISIBLE() if $tabcount == 0;

		$self->{$name}->InsertItem($self->evalhash($item));

		# push non-Item attributes into Window class
		foreach (keys %{$item->{'att'}}) {
			if ($_ !~ /^(image|index|text)$/) {
				$f->{'att'}->{$_} = $item->{'att'}->{$_};
			}
		}

		($f->{'att'}->{'left'}, $f->{'att'}->{'top'}, $f->{'att'}->{'width'}, $f->{'att'}->{'height'}) = (
			$self->{$name}->Left + ($self->{$name}->DisplayArea)[0],
			$self->{$name}->Top + ($self->{$name}->DisplayArea)[1],
			($self->{$name}->DisplayArea)[2],
			($self->{$name}->DisplayArea)[3],
		);

		$self->debug("Window: $bname");
		$self->{$bname} = new Win32::GUI::Window($self->evalhash($f)) || $self->error;
		$self->{$bname}->SetEvent('Resize', $self->genresize($bname));
		
		$self->{_left_}{$parent}{$bname}   = "\$self->{$name}->Left + (\$self->{$name}->DisplayArea)[0]";
		$self->{_top_}{$parent}{$bname}    = "\$self->{$name}->Top + (\$self->{$name}->DisplayArea)[1]";
		$self->{_width_}{$parent}{$bname}  = "(\$self->{$name}->DisplayArea)[2]";
		$self->{_height_}{$parent}{$bname} = "(\$self->{$name}->DisplayArea)[3]";
		
		push @{$self->{_worder_}{$parent}}, $bname;
		push @{$self->{_horder_}{$parent}}, $bname;
		push @{$self->{_lorder_}{$parent}}, $bname;
		push @{$self->{_torder_}{$parent}}, $bname;


		$self->{$name}->{$tabcount} = $bname; # stash index to name mapping!

		foreach ($item->children()) {
			$self->debug($_->{'att'}->{'name'});
			$self->debug($_->gi);

			if (exists &{$_->gi}) {
				&{\&{$_->gi}}($self, $t, $_);
			}	else {
				$self->_Generic($t, $_);
			}
		}

		$tabcount++;
	}
}


=item <WGXSplitter>

A WGXSplitter can be created using the following structure: -

	<WGXSplitter ...>
	 <Item>
	  <Label text='Tab 1' .... />
	 </Item>
	 <Item>
	  <Label text='Tab 2' .... />
	   ..other elements, etc...
	 </Item>
	</WGXSplitter>

The reason this is called a WGXSplitter is because it does not exist as a super-class
to a Splitter object. It's width dimension for example holds the complete width of both
panes and its splitterwidth ...

See splitter.xml example in samples/ directory.

=cut

sub WGXSplitter {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $parent = $self->getParent($e);

	$e = $self->expandDimensions($e);

	if (exists $e->{'att'}->{'range'}) {
		if ($e->{'att'}->{'range'} =~ m/^\s*(.+)\s*,\s*(.+)\s*$/) {
			($e->{'att'}->{'min'}, $e->{'att'}->{'max'}) = ($1, $2);
			delete $e->{'att'}->{'range'};
		} else {
			$self->debug("Failed to parse range '$e->{'att'}->{'range'}', should have format '[min, max]'");
		}
	}

	my ($LEFT, $TOP, $WIDTH, $HEIGHT);
	if($e->{'att'}->{'horizontal'}) {
		$e->{'att'}->{'_notop_'} = 1;
		$e->{'att'}->{'_noheight_'} = 1;
		$TOP = $e->{'att'}->{'top'};
		$e->{'att'}->{'top'} = "exec:".join('+', map { s/^exec://; $_ } $TOP, $e->{'att'}->{'start'});
		$HEIGHT = $e->{'att'}->{'height'};
		$e->{'att'}->{'height'} = $e->{'att'}->{'splittersize'};
		$e->{'att'}->{'min'} = "exec:".join('+', map { s/^exec://; $_ } $TOP, $e->{'att'}->{'min'}) if exists $e->{'att'}->{'min'};
		$e->{'att'}->{'max'} = "exec:".join('+', map { s/^exec://; $_ } $TOP, $e->{'att'}->{'max'}) if exists $e->{'att'}->{'max'};
		$e->{'att'}->{'onRelease'} = "sub {
			\$self->{\$self->{$name}->{0}}->Move(\$_[0]->Left, $TOP);
			\$self->{\$self->{$name}->{0}}->Resize(\$_[0]->Width, \$_[1] - $TOP);
			\$self->{\$self->{$name}->{1}}->Move(\$_[0]->Left, \$_[1] + \$_[0]->Height);
			\$self->{\$self->{$name}->{1}}->Resize(\$_[0]->Width, $HEIGHT - \$_[0]->Height - \$_[1] + $TOP);
		}";
	} else {
		$e->{'att'}->{'_noleft_'} = 1;
		$e->{'att'}->{'_nowidth_'} = 1;
		$LEFT = $e->{'att'}->{'left'};
		$e->{'att'}->{'left'} = "exec:".join('+', map { s/^exec://; $_ } $LEFT, $e->{'att'}->{'start'});
		$WIDTH = $e->{'att'}->{'width'};
		$e->{'att'}->{'width'} = $e->{'att'}->{'splittersize'};
		$e->{'att'}->{'min'} = "exec:".join('+', map { s/^exec://; $_ } $LEFT, $e->{'att'}->{'min'}) if exists $e->{'att'}->{'min'};
		$e->{'att'}->{'max'} = "exec:".join('+', map { s/^exec://; $_ } $LEFT, $e->{'att'}->{'max'}) if exists $e->{'att'}->{'max'};
		$e->{'att'}->{'onRelease'} = "sub {
			\$self->{\$self->{$name}->{0}}->Move($LEFT, \$_[0]->Top);
			\$self->{\$self->{$name}->{0}}->Resize(\$_[1] - $LEFT, \$_[0]->Height);
			\$self->{\$self->{$name}->{1}}->Move(\$_[1] + \$_[0]->Width, \$_[0]->Top);
			\$self->{\$self->{$name}->{1}}->Resize($WIDTH - \$_[0]->Width - \$_[1] + $LEFT, \$_[0]->Height);
		}";
	}

	$self->debug("\nWGXSplitter: $name; Parent: $parent");
	$self->{$name} = $self->{$parent}->AddSplitter($self->evalhash($e)) || $self->error;
	my $tabcount = 0;
	foreach my $item ($e->children()) {
		my $bname = $self->genname($item);
		$self->debug("Pane: $bname");

		my $f;
		$f->{'att'}->{'parent'} = $self->{$parent};
		$f->{'att'}->{'popstyle'} = WS_CAPTION()|WS_SIZEBOX()|WS_EX_CONTROLPARENT();
		$f->{'att'}->{'pushstyle'} = WS_CHILD()|DS_CONTROL()|WS_VISIBLE();

		
		# push attributes into Window class
		foreach (keys %{$item->{'att'}}) {
			$f->{'att'}->{$_} = $item->{'att'}->{$_};
		}

		$self->debug("Window: $bname");
		$self->{$bname} = new Win32::GUI::Window($self->evalhash($f)) || $self->error;
		$self->{$bname}->SetEvent('Resize', $self->genresize($bname));

		if($e->{'att'}->{'horizontal'}) {
			$self->{_left_}{$parent}{$bname}   = $tabcount == 0 ? "\$self->{$name}->Left" : "\$self->{$name}->Left";
			$self->{_top_}{$parent}{$bname}    = $tabcount == 0 ? "$TOP" : "\$self->{$name}->Top + \$self->{$name}->Height";
			$self->{_width_}{$parent}{$bname}  = $tabcount == 0 ? "\$self->{$name}->Width" : "\$self->{$name}->Width";
			$self->{_height_}{$parent}{$bname} = $tabcount == 0 ? "\$self->{$name}->Top - $TOP" : "$HEIGHT - \$self->{$name}->Top - \$self->{$name}->Height + $TOP";
		} else {
			$self->{_left_}{$parent}{$bname}   = $tabcount == 0 ? "$LEFT" : "\$self->{$name}->Left + \$self->{$name}->Width";
			$self->{_top_}{$parent}{$bname}    = $tabcount == 0 ? "\$self->{$name}->Top" : "\$self->{$name}->Top";
			$self->{_width_}{$parent}{$bname}  = $tabcount == 0 ? "\$self->{$name}->Left - $LEFT" : "$WIDTH - \$self->{$name}->Width - \$self->{$name}->Left + $LEFT";
			$self->{_height_}{$parent}{$bname} = $tabcount == 0 ? "\$self->{$name}->Height" : "\$self->{$name}->Height";
		}

		push @{$self->{_worder_}{$parent}}, $bname;
		push @{$self->{_horder_}{$parent}}, $bname;
		push @{$self->{_lorder_}{$parent}}, $bname;
		push @{$self->{_torder_}{$parent}}, $bname;

		$self->{$name}->{$tabcount} = $bname; # stash index to name mapping!

		foreach ($item->children()) {
			$self->debug($_->{'att'}->{'name'});
			$self->debug($_->gi);

			if (exists &{$_->gi}) {
				&{\&{$_->gi}}($self, $t, $_);
			}	else {
				$self->_Generic($t, $_);
			}
		}

		$tabcount++;
	}
}

=item <Timer>

Allows you to create a timer for use in your program.

	<Timer name='start_thread' elapse='8'/>

=cut

sub Timer {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $parent = $self->getParent($e);
	my $elapse = $e->{'att'}->{'elapse'};

	$self->debug("\nTimer: $name, $elapse, ($parent)");
	$self->{$name} = new Win32::GUI::Timer($self->{$parent}, $name, $elapse) || $self->error;
}

=item Generic Elements

Any widget not explicitly mentioned above can be generated by using its name
as an element id. For example a Button widget can be created using: -

	<Button name='B'
	 text='Push Me'
	 left='20' top='0'
	 width='80' height='20'
	/>

=cut

sub _Generic {
	my ($self, $t, $e) = @_;
	my $widget = $e->gi;
	my $name = $self->genname($e);
	my $parent = $self->getParent($e);

	$self->debug("\n$widget (_Generic): $name; Parent: $parent");
	if ($widget =~ /^$qrLRWidgets/) {
		$e->{'att'}->{'parent'} = "\$self->{$parent}";
		$self->{$name} = eval "new Win32::GUI::$widget(\$self->evalhash(\$e))" || $self->error;
	}
	elsif ($widget =~ /^$qrTop/) {
		$e->{'att'}->{'parent'} = "\$self->{$parent}";
		$self->{$name} = eval "new Win32::GUI::$widget(\$self->evalhash(\$e))" || $self->error;
		$self->{$name}->SetEvent('Resize', $self->genresize($name));
	}
	else {
		$self->{$name} = eval "new Win32::GUI::$widget(\$self->{$parent}, \$self->evalhash(\$e))" || $self->error;
	}
	
	foreach ($e->children()) {
		if (exists &{$_->gi}) {
			&{\&{$_->gi}}($self, $t, $_);
		}	else {
			$self->_Generic($t, $_);
		}
	}
}

1;
