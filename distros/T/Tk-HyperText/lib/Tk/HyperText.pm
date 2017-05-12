package Tk::HyperText;

##########################################################
# Look to the end of this file for the POD documentation #
##########################################################

use strict;
use warnings;
use base qw(Tk::Derived Tk::ROText);
use Tk::PNG;
use Tk::JPEG;
use Tk::BrowseEntry;
use Tk::Listbox;
use Tk::Text;
use HTML::TokeParser;
use URI::Escape;

our $VERSION = '0.12';

Construct Tk::Widget 'HyperText';

sub Populate {
	my ($cw,$args) = @_;

	# Strip out the custom arguments for this widget.
	my $opts = {
		-attributes => {
			-anchor => {
				-normal  => '#0000FF',
				-hover   => '#FF0000',
				-active  => '#FF0000',
				-visited => '#990099',
			},
			-font => {
				-family => 'Times',
				-mono   => 'Courier',
				-size   => 'medium',
				-bold   => 0, # Bold
				-italic => 0, # Italic
				-under  => 0, # Underline
				-over   => 0, # Overstrike
			},
			-style => {
				-margins => 0,
				-color   => '#000000', # Text color
				-back    => '#FFFFFF', # Text back
			},
		},
		-continuous => 0,
		-allow      => [],
		-deny       => [],
	};

	# Copy attributes over.
	if (exists $args->{'-attributes'}) {
		my $attr = delete $args->{'-attributes'};
		foreach my $tag (keys %{$attr}) {
			foreach my $name (keys %{$attr->{$tag}}) {
				$opts->{'-attributes'}->{$tag}->{$name} =
					$attr->{$tag}->{$name};
			}
		}
	}

	# Copy other options over.
	$opts->{'-continuous'} = delete $args->{'-continuous'} || delete $args->{'-continue'};
	$opts->{'-allow'} = delete $args->{'-allow'} || [];
	$opts->{'-deny'} = delete $args->{'-deny'} || [];

	# Pass the remaining arguments to ROText.
	$args->{'-foreground'} = $opts->{'-attributes'}->{'-style'}->{'-color'};
	$args->{'-background'} = $opts->{'-attributes'}->{'-style'}->{'-back'};
	$cw->SUPER::Populate($args);

	# Reconfigure the ROText widget with our attributes.
	$cw->SUPER::configure (
		-highlightthickness => 0,
		-exportselection    => 1,
		-insertofftime      => 1000,
		-insertontime       => 0,
		-cursor             => undef,
		-font => [
			-family => $opts->{'-attributes'}->{'-font'}->{'-family'},
			-size   => $cw->_size ($opts->{'-attributes'}->{'-font'}->{'-size'}),
		],
	);

	$cw->{hypertext} = {
		html        => '', # Holds the HTML code
		continue    => $opts->{'-continuous'},
		attrib      => $opts->{'-attributes'},
		history     => {},
		events      => {},
		permissions => 'allow_all',
		allow       => {},
		deny        => {},
	};

	if (scalar @{$opts->{'-allow'}}) {
		$cw->allowedTags (@{$opts->{'-allow'}});
	}
	if (scalar @{$opts->{'-deny'}}) {
		$cw->deniedTags (@{$opts->{'-deny'}});
	}
}

sub setHandler {
	my ($cw,%handlers) = @_;

	foreach my $event (keys %handlers) {
		my $code = $handlers{$event};
		$cw->{hypertext}->{events}->{$event} = $code;
	}
}

sub _event {
	my ($cw,$event,@args) = @_;

	if (exists $cw->{hypertext}->{events}->{$event}) {
		return &{$cw->{hypertext}->{events}->{$event}} ($cw,@args);
	}

	return undef;
}

sub loadString {
	my $cw = shift;
	my $text = shift;

	# Clear the widget.
	$cw->loadBlank();

	# Set the HTML buffer = our string.
	$cw->{hypertext}->{html} = $text;
	$cw->{hypertext}->{plain} = $text;
	$cw->{hypertext}->{plain} =~ s/<(.|\n)+?>//sig;

	# Render the text.
	$cw->render ($text);
}

sub loadBlank {
	my $cw = shift;
	$cw->{hypertext}->{html} = '';
	$cw->{hypertext}->{plain} = '';
	$cw->delete ("0.0","end");
}

sub allowedTags {
	my ($cw,@tags) = @_;
	$cw->{hypertext}->{allow} = {};
	foreach (@tags) {
		$_ = lc($_);
		$cw->{hypertext}->{allow}->{$_} = 1;
	}
}

sub deniedTags {
	my ($cw,@tags) = @_;
	$cw->{hypertext}->{deny} = {};
	foreach (@tags) {
		$_ = lc($_);
		$cw->{hypertext}->{deny}->{$_} = 1;
	}
}

sub allowHypertext {
	my $cw = shift;

	# Allow AIM-style HTML tags.
	my @allow = qw(html head title body a p br hr
		img font center sup sub b i u s);
	$cw->{hypertext}->{allow} = {};
	$cw->{hypertext}->{deny} = {};

	foreach (@allow) {
		$cw->{hypertext}->{allow}->{$_} = 1;
	}
}

sub allowEverything {
	my $cw = shift;

	# Allow everything again.
	$cw->{hypertext}->{allow} = {};
	$cw->{hypertext}->{deny} = {};
}

sub getText {
	my $cw = shift;
	my $asHTML = shift || 0;

	if ($asHTML) {
		return $cw->{hypertext}->{html};
	}
	return $cw->{hypertext}->{plain};
}

sub clearHistory {
	my $cw = shift;
	$cw->{hypertext}->{history} = {};
}

sub render {
	my ($cw,$html) = @_;

	# Initialize the style stack.
	my $mAttr = $cw->{hypertext}->{attrib};
	my %style = (
		weight     => 'normal', # or 'bold'
		slant      => 'roman',  # or 'italic'
		underline  => 0,        # or 1
		overstrike => 0,        # or 1
		family     => $mAttr->{'-font'}->{'-family'},
		size       => $mAttr->{'-font'}->{'-size'},
		foreground => '',
		background => '',
		justify    => 'left',   # or 'center' or 'right'
		offset     => 0,        # for <sup> and <sub>
		lmargin1   => 0,        # for <blockquote>
		lmargin2   => 0,        # and <ol>
		rmargin    => 0,        # and <ul>
		pre        => 0,        # inside <pre> tags
		linking    => 0,        # inside <a>...</a> tags
		linktag    => '',       # Current linktag
		inul       => 0,        # Inside <ul>
		inol       => 0,        # Inside <ol>
		ullevel    => 0,
		ollevel    => 0,
		intable    => 0,
		intd       => 0,
	);
	my @escape = (
		'&lt;'   => '<',
		'&gt;'   => '>',
		'&quot;' => '"',
		'&apos;' => "'",
		'&nbsp;' => ' ',
		'&reg;'  => chr(0x00ae),
		'&copy;' => chr(0x00a9),
		'&hearts;' => chr(0x2665),
		'&diams;'  => chr(0x2666),
		'&spades;' => chr(0x2660),
		'&clubs;'  => chr(0x2663),
		'&amp;'  => '&',
	);
	my @stackList = ();
	my $ulLevel = 0;
	my $olLevel = 0;
	my @stackOLLevel = ();
	my @stackULLevel = ();
	my $ulStyles = {};
	my $olStyles = {};
	my %hyperlink = (); # Hyperlink tags
	my $tabledata = {}; # Table data
	my $tableid = 0;    # Table ID
	my $formdata = {};  # Form data
	my $formname = '';  # Current form name
	my $curSelect = {      # Selectbox data
		in   => 0,     # Not in a <select> tag
		opts => [],    # Options
		name => '',    # Name
		size => 1,     # Size
		multiple => 0, # Multiple
		state    => 'readonly',
	};
	my (@stack) = $cw->_addStack (\%style);

	# Initialize the Text widget that gets our attention.
	my $browser = $cw;

	# Initialize the parser.
	my $parser = HTML::TokeParser->new (\$html);
	$parser->xml_mode(1);
	$parser->strict_names(1);
	$parser->marked_sections(1);
	my $foundOneBody = 0;
	my $end = 0;
	my $lineWritten = 0; # 1 = a line of text was written
	while (my $token = $parser->get_token) {
		my @data = @{$token};

		if ($data[0] eq "T") { # Plain Text
			my $text = $data[1];
			$text =~ s/([A-Za-z0-9]+)(\n+)([A-Za-z0-9]+)/$1 $3/ig;

			# Process escape sequences.
			while ($text =~ /&#x([^;]+?)\;/i) {
				my $hex = $1;
				my $qm  = quotemeta("&#x$hex");
				my $chr = hex $hex;
				my $char = chr($chr);
				$text =~ s/$qm/$char/ig;
			}
			while ($text =~ /&#([^;]+?)\;/i) {
				my $decimal = $1;
				my $hex = sprintf("%x", $decimal);
				my $qm  = quotemeta("&#$decimal;");
				my $chr = hex $hex;
				my $char = chr($chr);
				$text =~ s/$qm/$char/ig;
			}
			for (my $i = 0; $i < scalar(@escape) - 1; $i += 2) {
				my $qm = quotemeta($escape[$i]);
				my $rep = $escape[$i + 1];
				$text =~ s/$qm/$rep/ig;
			}

			# Unless in <pre>, remove newlines.
			unless ($style{pre}) {
				$text =~ s/[\x0d\x0a]//g;

				# If there's no text, skip this.
				if ($text =~ /^[\s\t]+$/) {
					next;
				}
				$text =~ s/^[\s\t]+/ /g;
				$text =~ s/[\s\t]+$/ /g;
			}

			# Generate a tag.
			my $tag = '';
			$tag = $cw->_makeTag(\%style,$browser);

			# Is this a hyperlink?
			if ($style{linking}) {
				# Bind this tag to an event.
				my $href = $hyperlink{$style{linktag}}->{href};
				my $target = $hyperlink{$style{linktag}}->{target};

				# Style up the initial color and underline.
				if (exists $cw->{hypertext}->{history}->{$href}) {
					$style{foreground} = $mAttr->{'-anchor'}->{'-visited'};
				}
				else {
					$style{foreground} = $mAttr->{'-anchor'}->{'-normal'};
				}
				$style{underline} = 1;
				push (@stack, $cw->_addStack(\%style));
				$tag = $cw->_makeTag(\%style,$browser);

				my $codeClick = sub {
					my ($parent,$tag,$href,$target) = @_;

					# Add this link to the history.
					$parent->{hypertext}->{history}->{$href} = 1;

					# Recolor this link.
					$parent->SUPER::tagConfigure ($tag,
						-foreground => $mAttr->{'-anchor'}->{'-active'},
					);

					# Call the link command.
					$cw->_event ('Resource',
						tag    => 'a',
						src    => $href,
						href   => $href,
						target => $target,
					);
				};
				my $codeHover = sub {
					my ($parent,$tag) = @_;
					$parent->SUPER::configure (
						-cursor => 'hand2',
					);
					$parent->SUPER::tagConfigure ($tag,
						-foreground => $mAttr->{'-anchor'}->{'-active'},
					);
				};
				my $codeOut = sub {
					my ($parent,$tag,$href) = @_;
					$parent->SUPER::configure (
						-cursor => undef,
					);

					if (exists $parent->{hypertext}->{history}->{$href}) {
						$parent->SUPER::tagConfigure ($tag,
							-foreground => $mAttr->{'-anchor'}->{'-visited'},
						);
					}
					else {
						$parent->SUPER::tagConfigure ($tag,
							-foreground => $mAttr->{'-anchor'}->{'-normal'},
						);
					}
				};

				# Bind the clicking of the link.
				$browser->tagBind ($tag,"<Button-1>", [ $codeClick,
				$tag, $href, $target ]);

				# Set up the hand cursor.
				$browser->tagBind ($tag,"<Any-Enter>", [ $codeHover,
				$tag ]);
				$browser->tagBind ($tag,"<Any-Leave>", [ $codeOut,
				$tag, $href ]);
			}

			# Insert the plain text.
			if (length $text > 0) {
				$browser->insert ('end', $text, $tag);
				$lineWritten = 1;
			}

			if ($style{linking}) {
				# Rollback the link styles.
				%style = $cw->_rollbackStack(\@stack,
					qw(foreground underline));
			}
		}
		elsif ($data[0] eq "S") { # Start Tag
			# Skip blocked tags.
			next if $cw->_blockedTag ($data[1]);

			my $tag = lc($data[1]);
			my $format = $cw->_makeTag(\%style);
			if ($tag =~ /^(html|head)$/) { # HTML, HEAD
				# That was nice of them.
			}
			elsif ($tag eq "title") { # Title
				my $title = $parser->get_text("title", "/title");
				$cw->_event ('Title',$title);
			}
			elsif ($tag eq "body") { # Body
				my $at = $data[2];

				my ($bg,$fg,$link,$alink,$vlink);
				if (exists $at->{bgcolor}) {
					$bg = $at->{bgcolor} || "#FFFFFF";
				}
				if (exists $at->{text}) {
					$fg = $at->{text} || "#000000";
				}
				if (exists $at->{link}) {
					$link = $at->{link};
					$mAttr->{'-anchor'}->{'-normal'} = $link || "#0000FF";
				}
				if (exists $at->{vlink}) {
					$vlink = $at->{vlink};
					$mAttr->{'-anchor'}->{'-visited'} = $vlink || "#990099";
				}
				if (exists $at->{alink}) {
					$alink = $at->{alink};
					$mAttr->{'-anchor'}->{'-active'} = $alink || "#FF0000";
				}

				if ($foundOneBody == 0) {
					# This is the first <body> tag found;
					# apply its colors globally.
					$bg = $mAttr->{'-style'}->{'-back'}
						unless length $bg;
					$fg = $mAttr->{'-style'}->{'-color'}
						unless length $fg;
					$browser->configure (
						-background => $bg,
						-foreground => $fg,
					);

					$mAttr->{'-style'}->{'-back'} = $bg;
					$mAttr->{'-style'}->{'-color'} = $fg;
					$foundOneBody = 1;
				}
				else {
					# The bg/fg colors only apply from here
					# on out.
					$style{background} = $bg;
					$style{foreground} = $fg;
					push (@stack, $cw->_addStack(\%style));
				}
			}
			elsif ($tag eq "a") { # Hyperlink
				my $at = $data[2];
				my $href = $at->{href} || '';
				my $target = $at->{target} || '';

				# Create a unique link tag for Tk::Text.
				my $linktag = join("-",$href,$target);
				$linktag .= '_' while exists $hyperlink{$linktag};
				$hyperlink{$linktag} = {
					href => $href, target => $target,
				};

				$style{linking} = 1;
				$style{linktag} = $linktag;
			}
			elsif ($tag eq "br") { # Line break
				$browser->SUPER::insert ('end', "\n", $format);
				$lineWritten = 0;
			}
			elsif ($tag eq 'p') { # Paragraph
				$browser->insert ('end', "\n\n", $format);
				$lineWritten = 0;
			}
			elsif ($tag eq 'form') { # Form
				my $at = $data[2];
				my $name = defined $at->{name} ? $at->{name} : 'untitledform';
				my $action = defined $at->{action} ? $at->{action} : '';
				my $method = defined $at->{method} ? $at->{method} : '';
				my $enc    = defined $at->{enctype} ? $at->{enctype} : '';

				# Start collecting the form data.
				$formdata->{$name}->{form} = {
					name => $name, action => $action, method => $method, enctype => $enc,
				};
				$formname = $name;
			}
			elsif ($tag eq 'textarea') { # Textarea
				my $at = $data[2];
				my $name = defined $at->{name} ? $at->{name} : 'x_not_a_form_field';
				my $cols = defined $at->{cols} ? $at->{cols} : 20;
				my $rows = defined $at->{rows} ? $at->{rows} : 4;
				my $state = defined $at->{disabled} ? 'disabled' : 'normal';
				my $wrap = 'word';
				if (defined $at->{wrap}) {
					if ($at->{wrap} eq 'off') {
						$wrap = 'none';
					}
				}

				my $value = $parser->get_text("textarea", "/textarea");

				$formdata->{$formname}->{fields}->{$name} = $value;
				$formdata->{$formname}->{defaults}->{$name} = $value;

				my $widget = $browser->Text (
					#-scrollbars => 'ose',
					-wrap       => $wrap,
					-width      => $cols,
					-height     => $rows,
					-font       => [
						-family => 'Courier',
						-size   => 12,
					],
					-foreground => '#000000',
					-background => '#FFFFFF',
					-highlightthickness => 0,
					-border             => 1,
				);
				$widget->insert('end',$value);
				$browser->windowCreate('end',
					-window => $widget,
					-align  => 'baseline',
				);
			}
			elsif ($tag eq 'select') { # Selectbox
				my $at = $data[2];
				my $name = defined $at->{name} ? $at->{name} : 'x_not_a_form_field';
				my $size = defined $at->{size} ? $at->{size} : 1;
				my $mult = defined $at->{multiple} ? 1 : 0;
				my $state = defined $at->{disabled} ? 'disabled' : 'readonly';
				$curSelect->{in}   = 1;
				$curSelect->{opts} = [];
				$curSelect->{name} = $name;
				$curSelect->{size} = $size;
				$curSelect->{multiple} = $mult;
				$curSelect->{state} = $state;
			}
			elsif ($tag eq 'option') { # Option
				my $at = $data[2];
				my $name  = $curSelect->{name};
				my $value = defined $at->{value} ? $at->{value} : '';
				my $label = $parser->get_text("option","/option");

				# Selected?
				if (exists $at->{selected} || !exists $formdata->{$formname}->{fields}->{$name}) {
					$formdata->{$formname}->{fields}->{$name} = $label;
					$formdata->{$formname}->{defaults}->{$name} = $value;
				}

				if ($curSelect->{in}) {
					push (@{$curSelect->{opts}}, [ $value, $label ]);
				}
			}
			elsif ($tag eq 'input') { # Input
				my $at = $data[2];
				my $name = defined $at->{name} ? $at->{name} : 'x_not_a_form_field';

				my $type = defined $at->{type} ? $at->{type} : 'text';
				my $size = defined $at->{size} ? $at->{size} : 15;
				my $value = defined $at->{value} ? $at->{value} : '';
				my $max   = defined $at->{maxlength} ? $at->{maxlength} : 0;
				my $state = defined $at->{disabled} ? 'disabled' : 'normal';
				my $checked = defined $at->{checked} ? 'checked' : 'cleared';

				$type = lc($type);
				$type = 'text' unless $type =~ /^(text|password|button|checkbox|radio|submit|reset)$/i;

				# Initialize the form variable.
				$formdata->{$formname}->{fields}->{$name} = $value unless exists $formdata->{$formname}->{fields}->{$name};
				$formdata->{$formname}->{defaults}->{$name} = $value unless exists $formdata->{$formname}->{defaults}->{$name};

				# Insert the widgets.
				if ($type eq 'text') {
					my $widget = $browser->Entry (
						-textvariable => \$formdata->{$formname}->{fields}->{$name},
						-width        => $size,
						-state        => $state,
						-background   => '#FFFFFF',
						-foreground   => '#000000',
						-font         => [
							-family => 'Helvetica',
							-size   => 10,
						],
						-highlightthickness => 0,
						-border             => 1,
					);
					$browser->windowCreate ('end',
						-window => $widget,
						-align  => 'baseline',
					);
				}
				if ($type eq 'password') {
					my $widget = $browser->Entry (
						-textvariable => \$formdata->{$formname}->{fields}->{$name},
						-show         => '*',
						-state        => $state,
						-width        => $size,
						-background   => '#FFFFFF',
						-foreground   => '#000000',
						-font         => [
							-family => 'Helvetica',
							-size   => 10,
						],
						-highlightthickness => 0,
						-border             => 1,
					);
					$browser->windowCreate ('end',
						-window => $widget,
						-align  => 'baseline',
					);
				}
				elsif ($type eq 'checkbox') {
					if ($checked eq 'cleared') {
						$formdata->{$formname}->{fields}->{$name} = '';
					}

					my $widget = $browser->Checkbutton (
						-variable => \$formdata->{$formname}->{fields}->{$name},
						-state    => $state,
						-onvalue  => $formdata->{$formname}->{defaults}->{$name},
						-offvalue => '',
						-text     => '',
						-background         => $style{background} || $mAttr->{'-style'}->{'-back'},
						-activebackground   => $style{background} || $mAttr->{'-style'}->{'-back'},
						-highlightthickness => 0,
					);
					$browser->windowCreate ('end',
						-window => $widget,
						-align  => 'baseline',
					);
				}
				elsif ($type eq 'radio') {
					if ($checked eq 'checked') {
						$formdata->{$formname}->{fields}->{$name} = $value;
					}

					my $widget = $browser->Radiobutton (
						-variable => \$formdata->{$formname}->{fields}->{$name},
						-state    => $state,
						-value    => $value,
						-text     => '',
						-background         => $style{background} || $mAttr->{'-style'}->{'-back'},
						-activebackground   => $style{background} || $mAttr->{'-style'}->{'-back'},
						-highlightthickness => 0,
					);
					$browser->windowCreate ('end',
						-window => $widget,
						-align  => 'baseline',
					);
				}
				elsif ($type =~ /^(button|submit|reset)$/i) {
					my $widget = $browser->Button (
						-text               => $value,
						-state              => $state,
						-cursor             => '',
						-highlightthickness => 0,
						-border             => 1,
						-font               => [
							-family => 'Helvetica',
							-size   => 10,
						],
					);
					$browser->windowCreate ('end',
						-window => $widget,
						-align  => 'baseline',
					);

					# Submit buttons submit the form.
					if ($type eq 'submit') {
						$widget->configure (-command => sub {
							# Collect all the fields.
							my $fields = ();
							foreach my $f (keys %{$formdata->{$formname}->{fields}}) {
								next if $f eq 'x_not_a_form_field';
								$fields->{$f} = $formdata->{$formname}->{fields}->{$f};
							}

							# If there are any listboxes, get them too.
							if (exists $formdata->{$formname}->{listwidget}) {
								foreach my $w (keys %{$formdata->{$formname}->{listwidget}}) {
									my @in = $formdata->{$formname}->{listwidget}->{$w}->curselection();
									if (scalar(@in) > 1) {
										my $values = [];
										foreach my $i (@in) {
											my $v = $formdata->{$formname}->{listwidget}->{$w}->get ($i);
											push (@{$values}, $v);
										}
										$fields->{$w} = $values;
									}
									elsif (scalar(@in) == 1) {
										$fields->{$w} = $formdata->{$formname}->{listwidget}->{$w}->get ($in[0]);
									}
									else {
										$fields->{$w} = undef;
									}
								}
							}

							# Submit the form.
							$cw->_event ('Submit',
								form    => $formdata->{$formname}->{form}->{name},
								action  => $formdata->{$formname}->{form}->{action},
								method  => $formdata->{$formname}->{form}->{method},
								enctype => $formdata->{$formname}->{form}->{enctype},
								fields  => $fields,
							);
						});
					}

					# Reset buttons reset the form.
					if ($type eq 'reset') {
						$widget->configure (-command => sub {
							# Reset all the fields.
							foreach my $f (keys %{$formdata->{$formname}->{defaults}}) {
								$formdata->{$formname}->{fields}->{$f} = $formdata->{$formname}->{defaults}->{$f};
							}
						});
					}
				}
			}
			elsif ($tag eq 'table') { # Table
				$browser->insert ('end', "\n") if $lineWritten;
				my $at = $data[2];
				my $border = $at->{border} || 0;
				my $cellspacing = $at->{cellspacing} || 0;
				my $cellpadding = $at->{cellpadding} || 0;
				$tableid++;
				$tabledata->{$tableid}->{widget} =
					$cw->Frame (
						-takefocus          => 0,
						-highlightthickness => 0,
						-relief             => 'raised',
						-borderwidth        => $cw->_isNumber ($border,0),
						-background         => $style{background} || $mAttr->{'-style'}->{'-back'},
					);
				$tabledata->{$tableid}->{row} = -1;
				$tabledata->{$tableid}->{col} = -1;
				$tabledata->{$tableid}->{border} = $cw->_isNumber ($border,0);
				$tabledata->{$tableid}->{cellspacing} = $cw->_isNumber ($cellspacing,0);
				$tabledata->{$tableid}->{cellpadding} = $cw->_isNumber ($cellpadding,0);
				$browser->windowCreate ('end',
					-window => $tabledata->{$tableid}->{widget},
					-align  => 'baseline',
				);
				$style{intable} = 1;
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag eq "tr") { # Table Row
				if ($style{intable}) {
					$tabledata->{$tableid}->{col} = -1;
					$tabledata->{$tableid}->{row}++;
				}
			}
			elsif ($tag =~ /^(td|th|thead|tbody|tfoot)$/) { # Table Data
				if ($style{intable}) {
					my $at = $data[2];
					my $colspan = undef;
					my $rowspan = undef;
					if (defined $at->{colspan}) {
						$colspan = $at->{colspan};
					} if (defined $at->{rowspan}) {
						$rowspan = $at->{rowspan};
					}
					$style{intd} = 1;
					$tabledata->{$tableid}->{col}++;
					$browser = $tabledata->{$tableid}->{widget}->ROText (
						-exportselection => 1,
						-takefocus       => 0,
						-highlightthickness => 0,
						-relief          => 'sunken',
						-wrap            => 'word',
						-borderwidth     => $tabledata->{$tableid}->{border},
						-insertofftime   => 1000,
						-insertontime    => 0,
						-width           => 0,
						-height          => 2,
						-padx            => $tabledata->{$tableid}->{cellpadding},
						-pady            => $tabledata->{$tableid}->{cellpadding},
						-foreground      => $style{foreground} || $mAttr->{'-style'}->{'-color'},
						-background      => $style{background} || $mAttr->{'-style'}->{'-back'},
						-cursor          => undef,
						-font       => [
							-family => $style{family},
							-weight => $style{weight},
							-slant  => $style{slant},
							-size   => $cw->_size ($style{size}),
							-underline => $style{underline},
							-overstrike => $style{overstrike},
						],
					);
					my @spans = ();
					push (@spans, '-columnspan' => $colspan) if defined $colspan;
					push (@spans, '-rowspan' => $rowspan) if defined $rowspan;
					$browser->grid (
						-row => $tabledata->{$tableid}->{row},
						-column => $tabledata->{$tableid}->{col},
						-sticky => 'nsew',
						-padx => $tabledata->{$tableid}->{cellspacing},
						-pady => $tabledata->{$tableid}->{cellspacing},
						@spans,
					);
					$lineWritten = 0;
				}
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag eq 'hr') { # HR
				my $at = $data[2];
				my $height = 4;
				if (exists $at->{size}) {
					$height = $at->{size};
				}
				my $width = $cw->screenwidth;
				my $frame = $browser->Frame (
					-relief             => 'raised',
					-height             => $height,
					-width              => $width,
					-borderwidth        => 1,
					-highlightthickness => 0,
				);
				$browser->insert ('end', "\n", $format);
				$browser->windowCreate ('end',
					-window => $frame,
					-padx   => 0,
					-pady   => 5,
				);
				$browser->insert ('end', "\n", $format);
				$lineWritten = 0;
			}
			elsif ($tag eq 'img') { # IMG
				my $at = $data[2];

				my $format = '';
				my $align = lc($at->{align}) || '';
				$align = 'baseline' unless $align =~ /^(top|center|bottom|baseline)$/;
				if (length $at->{src}) {
					my ($ext) = $at->{src} =~ /\.([^\.]+)$/i;
					if ($ext =~ /^gif$/i) {
						$format = 'GIF';
					}
					elsif ($ext =~ /^png$/i) {
						$format = 'PNG';
					}
					elsif ($ext =~ /^(jpeg|jpe|jpg)$/i) {
						$format = 'JPEG';
					}
					elsif ($ext =~ /^bmp$/i) {
						$format = 'BMP';
					}
				}

				my $broken = 0;

				# Request this resource.
				my $data = $cw->_event ('Resource',
					tag    => 'img',
					src    => $at->{src} || '',
					width  => $at->{width} || '',
					height => $at->{height} || '',
					vspace => $at->{vspace} || '',
					hspace => $at->{hspace} || '',
					align  => $at->{align} || '',
					alt    => $at->{alt} || '',
				);
				$data = '' unless defined $data;

				# Invalid format?
				if (length $format == 0 || length $data == 0) {
					$broken = 1;
				}

				if (length $data > 0 && not $broken) {
					my $image = $cw->Photo (
						-data   => $data,
						-format => $format,
					);
					$browser->imageCreate ('end',
						-image => $image,
						-align => $align,
						-padx  => $cw->_isNumber($at->{hspace},2),
						-pady  => $cw->_isNumber($at->{vspace},2),
					);
				}
				else {
					my $image = $cw->Photo (
						-data   => $cw->_brokenImage(),
						-format => 'PNG',
					);
					$browser->imageCreate ('end',
						-image => $image,
						-align => $align,
						-padx  => $cw->_isNumber($at->{hspace},2),
						-pady  => $cw->_isNumber($at->{vspace},2),
					);
				}

				$lineWritten = 1;
			}
			elsif ($tag eq 'font' || $tag eq 'basefont') { # Font
				my $at = $data[2];

				if (exists $at->{face}) {
					$style{family} = $at->{face};
				}
				if (exists $at->{size}) {
					$style{size} = $at->{size};
				}
				if (exists $at->{color}) {
					$style{foreground} = $at->{color};
				}
				if (exists $at->{back}) {
					$style{background} = $at->{back};
				}

				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag =~ /^h(1|2|3|4|5|6)$/) { # Heading
				my $level = $1;
				my $size = $cw->_heading($level);
				$browser->insert ('end',"\n\n") if $lineWritten;
				$style{size} = $size;
				$style{weight} = 'bold';
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag eq "ol") { # Ordered List
				my $at = $data[2];
				if ($style{inol} == 0 && $style{inul} == 0 && $lineWritten) {
					$browser->insert ('end',"\n\n");
				}
				elsif ($style{inol} || $style{inul}) {
					$browser->insert ('end',"\n");
				}
				$style{lmargin1} += 15;
				$style{lmargin2} += 30;
				$style{inol}++;
				$olLevel++;

				my $type = 1;
				my $start = 1;
				if (defined $at->{type}) {
					$type = $at->{type};
				}
				if (defined $at->{start}) {
					$start = $at->{start};
				}

				$olStyles->{$olLevel} = {
					type     => $type,
					position => $start,
				};

				push (@stackList,join('#','ol',$olLevel));
				push (@stackOLLevel,$olLevel);

				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag eq "ul") { # Unordered List
				my $at = $data[2];
				if ($style{inol} == 0 && $style{inul} == 0 && $lineWritten) {
					$browser->insert ('end',"\n\n");
				}
				elsif ($style{inol} || $style{inul}) {
					$browser->insert ('end',"\n");
				}
				$style{lmargin1} += 15;
				$style{lmargin2} += 30;
				$style{inul}++;
				$ulLevel++;

				# Find out any style info.
				my $type = "disc";
				if (defined $at->{type}) {
					$type = $at->{type};
				}

				$ulStyles->{$ulLevel} = {
					type => $type,
				};

				push (@stackList,join('#','ul',$ulLevel));
				push (@stackULLevel,$ulLevel);

				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag eq 'li') { # List Item
				if (scalar(@stackList)) {
					my ($family,$level) = split(/#/, $stackList[-1], 2);
					my $kind = '';
					my $begin = 0;
					if ($family eq "ol") {
						$kind = $olStyles->{$level}->{type};
						$begin = $olStyles->{$level}->{position};
					}
					else {
						$kind = $ulStyles->{$level}->{type};
						$begin = 0;
					}

					if ($family eq "ol") {
						$olStyles->{$level}->{position}++;
						my $symbol = $cw->_getOLsym ($kind,$begin);
						$symbol .= ".";
						$symbol .= " " until length $symbol >= 8;
						$browser->insert ('end',"$symbol",$format);
					}
					else {
						my $symbol = $cw->_getULsym ($kind);
						$browser->insert ('end',"$symbol  ",$format);
					}
				}
			}
			elsif ($tag eq 'blockquote') { # Blockquote
				$browser->insert ('end',"\n",$format) if $lineWritten;
				$style{lmargin1} += 25;
				$style{lmargin2} += 25;
				$style{rmargin} += 25;
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag eq 'div') { # Div
				my $at = $data[2];
				$browser->insert ('end',"\n",$format) if $lineWritten;

				if (exists $at->{align}) {
					if ($at->{align} =~ /^(center|left|right)$/i) {
						$style{justify} = lc($1);
					}
				}

				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag eq 'span') { # Span
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag eq 'pre') { # Pre
				$browser->insert('end', "\n", $format) if $lineWritten;
				$style{family} = $mAttr->{'-font'}->{'-mono'};
				$style{pre} = 1;
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag =~ /^(code|tt|kbd|samp)$/) { # Code
				$style{family} = $mAttr->{'-font'}->{'-mono'};
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag =~ /^(center|right|left)$/) { # Alignment
				my $align = $1;
				$browser->insert ('end',"\n",$format);
				$style{justify} = lc($align);
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag eq 'sup') { # Superscript
				$style{size}--;
				$style{size} = 0 if $style{size} < 0;
				$style{offset} += 4;
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag eq 'sub') { # Subscript
				$style{size}--;
				$style{size} = 0 if $style{size} < 0;
				$style{offset} -= 2;
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag eq 'big') { # Big
				$style{size}++;
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag eq 'small') { # Small
				$style{size}--;
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag =~ /^(b|strong)$/) { # Bold
				$style{weight} = "bold";
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag =~ /^(i|em|address|var|cite|def)$/) { # Italic
				$style{slant} = "italic";
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag =~ /^(u|ins)$/) { # Underline
				$style{underline} = 1;
				push (@stack, $cw->_addStack(\%style));
			}
			elsif ($tag =~ /^(s|del)$/) { # Strike-out
				$style{overstrike} = 1;
				push (@stack, $cw->_addStack(\%style));
			}
		}
		elsif ($data[0] eq "E") { # End Tag
			# Skip blocked tags.
			next if $cw->_blockedTag ($data[1]);

			my $tag = lc($data[1]);
			my $format = $cw->_makeTag(\%style);
			if ($tag =~ /^(html|head)$/) { # /HTML, /HEAD
				# That was nice of them.
			}
			elsif ($tag eq 'title') { # /Title
				# Ignore; we already got the title.
			}
			elsif ($tag eq 'body') { # /Body
				$browser->insert('end',"\n",$format);
				%style = $cw->_rollbackStack(\@stack,
					qw(foreground background));
			}
			elsif ($tag eq 'a') { # /A
				# We're not linking anymore.
				$style{linking} = 0;
				$style{linktag} = '';
			}
			elsif ($tag eq 'p') { # /Paragraph
				$browser->insert('end',"\n\n",$format);
				$lineWritten = 0;
			}
			elsif ($tag eq 'table') { # /Table
				$browser->insert('end',"\n",$format);
				%style = $cw->_rollbackStack(\@stack,
					qw(intable));
			}
			elsif ($tag eq "tr") { # /Table Row
				# Do nothing.
			}
			elsif ($tag =~ /^(td|th|thead|tbody|tfoot)$/) { # /Table Data
				if ($style{intd}) {
					$style{intd} = 0;
					my $endline = $browser->index('end');
					$endline =~ s/\..*$//;
					my $i = 0;
					my $max = 0;
					while ($i++ < $endline) {
						my $l = length (
							$browser->get("$i.0","$i.0 lineend")
						);
						$max = $l if $l > $max;
					}
					$browser->configure (-width => $max,
						-height => $endline - 1);
					%style = $cw->_rollbackStack(\@stack,
						qw(intd));

					# Reset the browser.
					$browser = $cw;
				}
			}
			elsif ($tag eq 'select') { # /Select
				if ($curSelect->{in}) {
					# Collect the choices.
					my @choices = ();
					foreach my $choice (@{$curSelect->{opts}}) {
						push (@choices,$choice->[1] || $choice->[0]);
					}

					# Determine if we need a Listbox or a BrowseEntry.
					my $name = $curSelect->{name} || 'x_not_a_form_field';
					my $size = $curSelect->{size};
					my $mult = $curSelect->{multiple};
					$size = 1 unless $cw->_isNumber($size);
					if ($size <= 1) {
						# BrowseEntry.
						my $widget = $browser->BrowseEntry (
							-variable => \$formdata->{$formname}->{fields}->{$name},
							-choices  => [ @choices ],
							-state      => $curSelect->{state},
							-foreground => '#000000',
							-background => '#FFFFFF',
							-disabledforeground => '#000000',
							-disabledbackground => '#FFFFFF',
							-border     => 1,
							-highlightthickness => 0,
							-font       => [
								-family => 'Helvetica',
								-size   => 10,
							],
						);
						$browser->windowCreate ('end',
							-window => $widget,
							-align  => 'baseline',
						);
					}
					else {
						# Listbox.
						$formdata->{$formname}->{listboxes}->{$name} = 1;
						$formdata->{$formname}->{listwidget}->{$name} = $browser->Listbox (
							-height => $size,
							-foreground => '#000000',
							-background => '#FFFFFF',
							-font       => [
								-family => 'Helvetica',
								-size   => 10,
							],
							-selectmode => ($mult ? 'multiple' : 'single'),
							-exportselection => 0,
							-border          => 1,
							-highlightthickness => 0,
						);
						$formdata->{$formname}->{listwidget}->{$name}->insert('end',@choices);
						$browser->windowCreate ('end',
							-window => $formdata->{$formname}->{listwidget}->{$name},
							-align  => 'baseline',
						);
					}
				}
			}
			elsif ($tag eq 'font') { # /Font
				%style = $cw->_rollbackStack(\@stack,
					qw(family size color back));
			}
			elsif ($tag =~ /^h(1|2|3|4|5|6)$/) { # /Heading
				$browser->insert('end',"\n\n",$format);
				%style = $cw->_rollbackStack(\@stack,
					qw(size weight));
				$lineWritten = 0;
			}
			elsif ($tag eq 'ol') { # /Ordered List
				pop (@stackList);
				%style = $cw->_rollbackStack(\@stack,
					qw(lmargin1 lmargin2));

				my $lastLevel = pop(@stackOLLevel);
				$style{olLevel} = $stackOLLevel[-1] || 0;
				delete $olStyles->{$lastLevel};

				$style{inol}--;
				$olLevel--;
				$olLevel = 0 if $olLevel < 0;
				$style{inol} = 0 if $style{inol} < 0;

				if ($style{inol} || $style{inul}) {
					$browser->insert ('end',"\n",$format);
					$lineWritten = 0;
				}
				else {
					$browser->insert ('end',"\n\n",$format);
					$lineWritten = 0;
				}
			}
			elsif ($tag eq 'ul') { # /Unordered List
				pop (@stackList);
				%style = $cw->_rollbackStack(\@stack,
					qw(lmargin1 lmargin2));

				my $lastLevel = pop(@stackULLevel);
				$style{ulLevel} = $stackULLevel[-1] || 0;
				delete $ulStyles->{$lastLevel};

				$style{inul}--;
				$ulLevel--;
				$ulLevel = 0 if $ulLevel < 0;
				$style{inul} = 0 if $style{inul} < 0;

				if ($style{inol} || $style{inul}) {
					$browser->insert ('end',"\n",$format);
					$lineWritten = 0;
				}
				else {
					$browser->insert ('end',"\n\n",$format);
					$lineWritten = 0;
				}
			}
			elsif ($tag eq 'li') { # /LI
				$browser->insert('end',"\n",$format);
				$lineWritten = 0;
			}
			elsif ($tag eq 'blockquote') { # /Blockquote
				$browser->insert('end',"\n",$format);
				%style = $cw->_rollbackStack(\@stack,
					qw(lmargin1 lmargin2 rmargin));
				$lineWritten = 0;
			}
			elsif ($tag eq 'div') { # /Div
				$browser->insert('end',"\n",$format);
				%style = $cw->_rollbackStack(\@stack,'justify');
				$lineWritten = 0;
			}
			elsif ($tag eq 'span') { # /Span
				%style = $cw->_rollbackStack(\@stack);
			}
			elsif ($tag eq 'pre') { # /Pre
				$browser->insert ('end',"\n",$format);
				%style = $cw->_rollbackStack(\@stack,
					qw(family pre));
			}
			elsif ($tag =~ /^(code|tt|kbd|samp)$/) { # /Code
				%style = $cw->_rollbackStack(\@stack,'family');
			}
			elsif ($tag =~ /^(center|right|left)$/) { # /Align
				$browser->insert('end',"\n",$format);
				%style = $cw->_rollbackStack(\@stack,'justify');
				$lineWritten = 0;
			}
			elsif ($tag =~ /^(sup|sub)$/) { # /Superscript, /Subscript
				%style = $cw->_rollbackStack(\@stack,
					qw(size offset));
			}
			elsif ($tag =~ /^(big|small)$/) { # /Big, /Small
				%style = $cw->_rollbackStack(\@stack,'size');
			}
			elsif ($tag =~ /^(b|strong)$/) { # /Bold
				%style = $cw->_rollbackStack(\@stack,'weight');
			}
			elsif ($tag =~ /^(i|em|address|var|cite|def)$/) { # /Italic
				%style = $cw->_rollbackStack(\@stack,'slant');
			}
			elsif ($tag =~ /^(u|ins)$/) { # /Underline
				%style = $cw->_rollbackStack(\@stack,'underline');
			}
			elsif ($tag =~ /^(s|del)$/) { # /Overstrike
				%style = $cw->_rollbackStack(\@stack,'overstrike');
			}
		}
	}
}

sub _addStack {
	my ($cw,$style) = @_;

	my @keys = sort { $a cmp $b } keys %{$style};
	my @parts = ();
	foreach my $k (@keys) {
		my $val = $style->{$k};
		$val = uri_escape($val);
		push (@parts,join("=",$k,$val));
	}

	return join ("&",@parts);
}

sub _rollbackStack {
	my ($cw,$stack,@keys) = @_;

	my $newStyle = {};
	if (scalar @{$stack} > 1) {
		my $curStack = $stack->[-1];
		my $lastStack = $stack->[-2];
		my $curStyle = {};
		my $lastStyle = {};

		# Collect the style data.
		foreach my $p (split(/\&/, $curStack)) {
			my ($k,$val) = split(/=/, $p, 2);
			$val = uri_unescape($val);
			$curStyle->{$k} = $val;
		}
		foreach my $p (split(/\&/, $lastStack)) {
			my ($k,$val) = split(/=/, $p, 2);
			$val = uri_unescape($val);
			$lastStyle->{$k} = $val;
		}

		$newStyle = $lastStyle;

		# For @keys, set these values to what they were before.
		foreach my $k (@keys) {
			$newStyle->{$k} = (defined $lastStyle->{$k} &&
				length $lastStyle->{$k}) ? $lastStyle->{$k} : '';
		}

		pop(@{$stack});
		return %{$newStyle};
	}
	else {
		my $curStyle = {};

		foreach my $p (split(/\&/, $stack->[-1])) {
			my ($k,$val) = split(/=/, $p, 2);
			$val = uri_unescape($val);
			$curStyle->{$k} = $val;
		}

		return %{$curStyle};
	}
}

sub _makeTag {
	my ($cw,$style,$widget) = @_;

	my @parts = ();
	foreach my $k (sort { $a cmp $b } keys %{$style}) {
		my $val = uri_escape($style->{$k}) || '';
		push (@parts,$val);
	}

	my $tag = join("-",@parts);

	if (defined $widget) {
		$widget->tagConfigure ($tag,
			-foreground => $style->{foreground},
			-background => $style->{background},
			-font       => [
				-family => $style->{family},
				-weight => $style->{weight},
				-slant  => $style->{slant},
				-size   => $cw->_size ($style->{size}),
				-underline => $style->{underline},
				-overstrike => $style->{overstrike},
			],
			-offset => $style->{offset},
			-justify => $style->{justify},
			-lmargin1 => $style->{lmargin1},
			-lmargin2 => $style->{lmargin2},
			-rmargin  => $style->{rmargin},
		);
	}
	else {
		$cw->SUPER::tagConfigure ($tag,
			-foreground => $style->{foreground},
			-background => $style->{background},
			-font       => [
				-family => $style->{family},
				-weight => $style->{weight},
				-slant  => $style->{slant},
				-size   => $cw->_size ($style->{size}),
				-underline => $style->{underline},
				-overstrike => $style->{overstrike},
			],
			-offset => $style->{offset},
			-justify => $style->{justify},
			-lmargin1 => $style->{lmargin1},
			-lmargin2 => $style->{lmargin2},
			-rmargin  => $style->{rmargin},
		);
	}

	return $tag;
}

# Calculates the point size from an HTML size.
sub _size {
	my ($cw,$size) = @_;

	# Translate words to numbers?
	if ($size =~ /[^0-9]/) {
		$size = $cw->_sizeStringToNumber ($size);
	}

	my %map = (
		# HTML => Point
		0 => 8,
		1 => 9,
		2 => 10,
		3 => 12,
		4 => 14,
		5 => 16,
		6 => 18,
	);

	return exists $map{$size} ? $map{$size} : 10;
}

# Calculates the HTML size for a heading.
sub _heading {
	my ($cw,$level) = @_;

	my %map = (
		# Level => HTML Size
		1 => 6,
		2 => 5,
		3 => 4,
		4 => 3,
		5 => 2,
		6 => 1,
	);

	return exists $map{$level} ? $map{$level} : 6;
}

sub _sizeStringToNumber {
	my ($cw,$string) = @_;

	my %map = (
		'xx-large' => 6,
		'x-large'  => 5,
		'large'    => 4,
		'medium'   => 3,
		'small'    => 2,
		'x-small'  => 1,
		'xx-small' => 0,
	);

	return exists $map{$string} ? $map{$string} : 3;
}

sub _isNumber {
	my ($cw,$number,$default) = @_;

	if (defined $number && length $number && $number !~ /[^0-9]/) {
		return $number;
	}
	else {
		return $default;
	}
}

sub _getOLsym {
	my ($cw,$type,$pos) = @_;

	my %letterhash = (
		0 => '',
		1 => 'A',
		2 => 'B',
		3 => 'C',
		4 => 'D',
		5 => 'E',
		6 => 'F',
		7 => 'G',
		8 => 'H',
		9 => 'I',
		10 => 'J',
		11 => 'K',
		12 => 'L',
		13 => 'M',
		14 => 'N',
		15 => 'O',
		16 => 'P',
		17 => 'Q',
		18 => 'R',
		19 => 'S',
		20 => 'T',
		21 => 'U',
		22 => 'V',
		23 => 'W',
		24 => 'X',
		25 => 'Y',
		26 => 'Z',
	);

	if ($type =~ /^[0-9]+$/) {
		# Numeric types are easy.
		return $pos;
	}
	elsif ($type eq 'I') {
		# Roman numerals.
		return uc ($cw->_roman($pos));
	}
	elsif ($type eq 'i') {
		# Roman numerals.
		return lc ($cw->_roman($pos));
	}
	elsif ($type =~ /^[A-Za-z]+$/) {
		# Alphabetic.
		my $string = '';
		while ($pos > 26) {
			my $first = $pos % 26;
			my $second = ($pos - $first) / 26;
			$string = $letterhash{$first} . $string;
			$pos = $second;
		}

		$string = $letterhash{$pos} . $string;

		if ($type =~ /^[A-Z]+$/) {
			return uc($string);
		}
		else {
			return lc($string);
		}
	}

	return $pos;
}

sub _getULsym {
	my ($cw,$type) = @_;

	my $circle = chr(0x25cb);
	my $disc   = chr(0x25cf);
	my $square = chr(0x25aa);

	if ($type =~ /^circle$/i) {
		return $circle;
	}
	elsif ($type =~ /^square$/i) {
		return $square;
	}
	else {
		return $disc;
	}
}

sub _roman {
	my ($cw,$dec) = @_;

	0 < $dec and $dec < 4000 or return undef;

	my %roman2arabic = qw(I 1 V 5 X 10 L 50 C 100 D 500 M 1000);
	my %roman_digit = qw(1 IV 10 XL 100 CD 1000 MMMMMM);
	my @figure = reverse sort keys %roman_digit;
	$roman_digit{$_} = [ split(//, $roman_digit{$_}, 2) ] foreach @figure;

	my ($x,$roman);
	foreach (@figure) {
		my ($digit, $i, $v) = (int($dec / $_), @{$roman_digit{$_}});
		if (1 <= $digit and $digit <= 3) {
			$roman .= $i x $digit;
		}
		elsif ($digit == 4) {
			$roman .= join("", $i, $v);
		}
		elsif ($digit == 5) {
			$roman .= $v;
		}
		elsif (6 <= $digit and $digit <= 8) {
			$roman .= $v . ($i x ($digit - 5));
		}
		elsif ($digit == 9) {
			$roman .= join("", $i, $x);
		}
		$dec -= $digit * $_;
		$x = $i;
	}

	return $roman;
}

sub _blockedTag {
	my ($self,$tag) = @_;

	my $deny = 0;

	# If we have defined any "allowed tags", check it.
	if (scalar keys %{$self->{hypertext}->{allow}} > 0) {
		$deny = 1;

		# See if this tag is allowed.
		if (exists $self->{hypertext}->{allow}->{$tag}) {
			$deny = 0;
		}
	}

	# If we have any "denied tags", check them.
	if (scalar keys %{$self->{hypertext}->{deny}} > 0) {
		if (exists $self->{hypertext}->{deny}->{$tag}) {
			$deny = 1;
		}
	}

	return $deny;
}

sub _brokenImage {
	return q~iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABGdBTUEAAK/INwWK6QAAABl0RVh0
U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAKTSURBVHjaYmxpafnPMEAgPT2dASCAWECM
6upqxoFwwJs3b/4DBBATwwADgAAacAcABNCAOwAggAbcAQABNOAOAAigAXcAQAANuAMAAmjAHQAQ
QAPuAIAAItoBjIyM04D4PxKeBhVPBuIzyOJAzEesuQABxESk5S4uoqKZ/6urGf63tjL89/ZmUGJh
yQSKBwGlM8/U1hr/Ly5m+C8oyJAK5DNAMFEAIIAYQJUREDAQwkAwrYON7f9/Tc3//5WV/+8WEAAJ
7i53c/v/v7T0/xsGhv8xQAwUOwPEfMSY+fr16/8AAUSKA+SB+O4hoCXAcP7/X1b2f7mu7v//RUX/
/7Ow/I8GigtCHJBMjHkwBwAEENFpAKjhIZCaXosQYOjg5GRgWLWKYfKfPwwngELvgfJAdXNJSYQA
AURSLgAa3nOQgWH1ahkZBgY2NgaGW7cYnj95wvAaFDRg+xk6Sc0FAAFEkgOAiQ4UDcbGJiYMDOzs
DD8+fGBgBgrYAbE4AwMwBhhcSHUAQACRWg6Ud7i4KClxcTE8uX6dYRdQ4C0Q6wPxVIh8JilZEAQA
AoiUciBZSUgos9zIiIFh+XKGFqBYPhCD4p4ViJ2BOA0YOkCqgxQHAAQQseUAyFeZq8zNGRjmzmUo
+vePYQ9Q4AEw0YF8fhaILwOxJxDzQkIhiFgHAAQQC5HqMssZGY0/b9/OEAvk3IEkunugRAe0nBno
iDRQWvgAxI5AvAlSEK0jxmCAACKqHAAVLKCCiAGSz/9D7GcogcoZAPFMJLndQBxEbDkAEEAsRGa/
T0AqC4rR5S6AWthQTDIACKABrw0BAmjAHQAQQAPuAIAAGnAHAATQgDsAIIAG3AEAATTgDgAIIEZw
q2QAAUCAAQBj+lYRrQ+vagAAAABJRU5ErkJggg==~;
}

1;

__END__

=head1 NAME

Tk::HyperText - An ROText widget which renders HTML code.

=head1 SYNOPSIS

  use Tk::HyperText;

  my $html = $mw->Scrolled ('HyperText',
    -scrollbars => 'ose',
    -wrap       => 'word',
  )->pack (-fill => 'both', -expand => 1);

  $html->setHandler (Title    => \&onNewTitle);
  $html->setHandler (Resource => \&onResource);
  $html->setHandler (Submit   => \&onFormSubmit);

  $html->loadString (qq~<html>
    <head>
    <title>Hello world!</title>
    </head>
    <body bgcolor="#0099FF">
    <font size="6" family="Impact" color="#FFFFFF">
    <strong>Hello, world!</strong>
    </font>
    </body>
    </html>
  ~);

=head1 DESCRIPTION

C<Tk::HyperText> is a widget derived from C<Tk::ROText> that renders HTML
code.

=head2 PURPOSE

First of all, B<Tk::HyperText is NOT expected to become a full-fledged web
browser widget>. This module's original idea was just to be a simple
HTML-rendering widget, specifically to match the capabilities of the
I<AOL Instant Messenger>'s HTML widgets. That is, to render basic text
formatting, images, and hyperlinks. Anything this module does that's extra
is only there because I was up to the challenge.

=head2 VERSION 0.06+

This module is B<NOT> backwards compatible with versions 0.05 and below.
Specifically, the module was rewritten to use C<HTML::TokeParser> as its
HTML parsing engine instead of parsing it as plain text. Also, the methods
have all been changed. The old module's overloading of the standard
C<Tk::Text> methods was causing all kinds of problems, and since this isn't
really a "drop-in" replacement for the other Text widgets, its methods don't
need to follow the same format.

Also, support for Cascading StyleSheets doesn't work at this time. It may be
re-implemented at a later date, but, as this widget is not meant to become
a full-fledged web browser (see L<"PURPOSE">), the CSS support might not
return.

=head2 EXAMPLE

Run the `demo.pl` script included in the distribution.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item -continuous, -continue

Setting this option to 1 tells the widget B<not> to re-render the entire
contents of the widget each time the contents are updated. The default value
is 0, so the entire page contents are rendered on any updates. This causes
the code to be "continuous", so that i.e. if you fail to close a bold tag and
then insert more code, the new code should carry on the unclosed tag and
appear in bold. Setting this option to 1 would render the new code
independently from the existing page and is therefore unnatural in HTML.

C<-continue> is an alias for C<-continuous> if you're terrible at spelling.

=item -allow, -deny

Define tags that are allowed or denied. See L<"WIDGET METHODS"> for more
details.

=item -attributes

Since Tk::HyperText doesn't yet support Cascading Style Sheets, the only
alternative is to send in C<-attributes>. This data structure defines some
default styles for use within the rendered pages.

  my $html = $mw->Scrolled('HyperText',
    -attributes => {
      -anchor => {              # Hyperlink colors
        -normal  => '#0000FF',  # or 'blue'
        -hover   => '#FF0000',  # or 'red'
        -active  => '#FF0000',  # or 'red'
        -visited => '#990099',  # or 'purple'
      },
      -font => {
        -family => 'Times',
        -mono   => 'Courier',
        -size   => 'medium',    # or any HTML size
                                # (1..6, xx-small..xx-large)

        # Text styles, set them to 1 to apply the effect.
        # I don't see why anyone would want to use these,
        # but they're here anyway.
        -bold   => 0, # Bold
        -italic => 0, # Italic
        -under  => 0, # Underline
        -over   => 0, # Overstrike
      },
      -style => {
        -margins => 0,         # Text margins
        -color   => '#000000', # Text color
        -back    => '#FFFFFF', # Text BG color
      },
    },
  );

=back

=head1 WIDGET METHODS

=over 4

=item I<$text>-E<gt>B<setHandler> I<(name =E<gt> event)>

Define a handler for certain events that happen within the widget. See
L<"EVENTS"> for more information.

  $html->setHandler (Title => sub {
    my ($self,$newTitle) = @_;

    $mw->configure (-title => $newTitle);
  });

=item I<$text>-E<gt>B<allowedTags> I<(tags)>

Specify a set of tags that are allowed to be rendered. Pass in the tag names
as an array. If the "allow list" has any entries, B<only> these tags will be
rendered.

=item I<$text>-E<gt>B<deniedTags> I<(tags)>

Specify a set of tags that are B<not> allowed to be rendered. If the "allow
list" is empty and the "denied list" has any entries, then all tags are
allowed B<except> for those in the denied list. If any entries in the denied
list conflict with entries in the allowed list, those tags are B<not>
allowed.

=item I<$text>-E<gt>B<allowHypertext> I<()>

This is a preset allow/deny scheme. It allows all hypertext tags (basic
text formatting, images, and horizontal rules) but doesn't allow tables,
forms, lists, or other complicated tags. This will make it match the
capabilities of I<AOL Instant Messenger>'s HTML rendering widgets.

It will allow the following tags:

  <html>, <head>, <title>, <body>, <a>, <p>, <br>, <hr>,
  <img>, <font>, <center>, <sup>, <sub>, <b>, <i>,
  <u>, <s>

All other tags are denied.

=item I<$text>-E<gt>B<allowEverything> I<()>

Allows all supported tags to be rendered. It resets the "allow" and
"deny" lists to be blank.

=item I<$text>-E<gt>B<loadString> I<(html_code)>

Render a string of HTML code into the text widget. This will replace all of
the current contents of the widget with the new HTML code.

=item I<$text>-E<gt>B<loadBlank> I<()>

Blanks out the contents of the widget (similar to the "C<about:blank>" URI
in most modern web browsers).

=item I<$text>-E<gt>B<clearHistory> I<()>

Resets the browsing history (so "visited links" will become "normal links"
again).

=item I<$text>-E<gt>B<getText> I<([as_html])>

Returns the contents of the widget as a string. Send a true value as an
argument to get the contents back including HTML code. Otherwise, only the
plain text content is returned.

=back

=head1 EVENTS

All events receive a reference to its parent widget as C<$_[0]>.
The following are the event handlers currently supported by
C<Tk::HyperText>:

=over 4

=item Title ($self, $newTitle)

This event is called every time a C<< <title>...</title> >> sequence is found
in the HTML code. C<$newTitle> is the text of the new page title.

=item Resource ($self, %info)

This event is called whenever an external resource is requested (such as an
image or a hyperlink trying to link to another page). C<%info> contains all
the information about the requested resource.

  # For hyperlinks (<a> tags)
  %info = (
    tag    => 'a',                 # The HTML tag.
    href   => 'http://google.com', # The <a href> attribute.
    src    => 'http://google.com', # src is an alias for href
    target => '_blank',            # The <a target> attribute
  );

  # For images (<img> tags)
  %info = (
    tag    => 'img',        # The HTML tag.
    src    => 'avatar.jpg', # The <img src> attribute.
    width  => 48,           # The <img width> attribute.
    height => 48,           # The <img height> attribute.
    vspace => '',           # <img vspace>
    hspace => '',           # <img hspace>
    align  => '',           # <img align>
    alt    => 'alt text',   # <img alt>
  );

B<Note about Images:> The C<Resource> event, when called for an image, wants
you to return the image's data, Base64-encoded. Otherwise, the image on the
page will show up as a "broken image" icon. Here is an example of how to
handle image resources:

  use LWP::Simple;
  use MIME::Base64 qw(encode_base64);

  $html->setHandler (Resource => sub {
    my ($self,%info) = @_;

    if ($info{tag} eq 'img') {

      # If an http:// link, get the image from the web.
      if ($info{src} =~ /^http/i) {
        my $bin = get $info{src};
        my $enc = encode_base64($bin);
        return $enc;
      }

      # Otherwise, read it from a local file.
      else {
        if (-f $src) {
          open (READ, $src);
          binmode READ;
          my @bin = <READ>;
          close (READ);
          chomp @bin;

          my $enc = encode_base64(join("\n",@bin));
          return enc;
        }
      }
    }

    return undef;
  });

On hyperlink resources, the module doesn't need or expect any return value.
It should be up to the handler to do what it needs (i.e. fetch the source
of the page, blank out the HTML widget and then C<loadString> the new code
into it).

=item Submit ($self,%info)

This event is called when an HTML form has been submitted. C<%info> is a
hash containing the information about the event.

  %info = (
    form    => 'login',      # The <form name> attribute.
    action  => '/login.cgi', # The <form action> attribute.
    method  => 'POST',       # The <form method> attribute.
    enctype => 'text/plain', # The <form enctype> attribute.
    fields  => {             # Hashref of form names and values.
      username => 'soandso',
      password => 'bigsecret',
      remember => 1,
    },
  );

The event doesn't want or expect a return value, similarly to the C<Resource>
event for normal anchor tags. Your code should know what to do with this
event (i.e. get C<LWP::UserAgent> to post the form to a remote web address,
stream the results of the request in through C<loadString>, etc.)

=back

=head1 HTML SUPPORT

The following tags and attributes are supported by this module:

  <html>
  <head>
  <title>
  <body>     (bgcolor, text, link, alink, vlink)
  <a>        (href, target)
  <br>
  <p>
  <form>     (name, action, method, enctype)
  <textarea> (name, cols, rows, disabled)
  <select>   (name, size, multiple)
  <option>   (value, selected)
  <input>    (name, type, size, value, maxlength, disabled, checked)
              types: text, password, checkbox, radio, button, submit, reset
  <table>    (border, cellspacing, cellpadding)
  <tr>
  <td>       (colspan, rowspan)
    <th>
    <thead>
    <tbody>
    <tfoot>
  <hr>       (height, size)
  <img>      (src, width, height, vspace, hspace, align, alt)*
  <font>     (face, size, color, back)
    <basefont>
  <h1>..<h6>
  <ol>       (type, start)
  <ul>       (type)
  <li>
  <blockquote>
  <div>      (align)
  <span>
  <pre>
  <code>
    <tt>
    <kbd>
    <samp>
  <center>
    <right>
    <left>
  <sup>
  <sub>
  <big>
  <small>
  <b>
    <strong>
  <i>
    <em>
    <address>
    <var>
    <cite>
    <def>
  <u>
    <ins>
  <s>
    <del>

=head1 SEE ALSO

L<Tk::ROText> and L<Tk::Text>.

=head1 CHANGES

  0.12 Feb 25, 2016
  - Add more dependencies to get CPANTS to pass.

  0.11 Feb 23, 2016
  - Add dependency on HTML::TokeParser.

  0.10 Sep 18, 2015
  - Add dependency on Tk::Derived.

  0.09 Nov 11, 2013
  - Reformatted as per CPAN::Changes::Spec -neilbowers

  0.08 Nov  1, 2013
  - Use hex() instead of eval() to convert hex strings into numbers.
  - Set default values for body colors.
  - Stop demo.pl from being installed; rename it to eg/example.

  0.06 July 14, 2008
  - The module uses HTML::TokeParser now and does "real" HTML parsing.
  - Badly broke backwards compatibility.

  0.05 July 11, 2007
  - Added support for "tag permissions", so that you can allow/deny specific tags from
    being rendered (i.e. say you're making a chat client which uses HTML and you don't
    want people inserting images into their messages, or style sheets, etc)
  - Added the tags <address>, <var>, <cite>, and <def>.
  - Added the <hr> tag.
  - Added two "default images" that are displayed when an <img> tag tries to show
    an image that couldn't be found, or was found but is a file type that isn't
    supported (e.g. <img src="index.html"> would show an "invalid image" icon).
  - Bug fix: every opened tag that modifies your style will now copy all the other
    stacks. As a result, opening <font back="yellow">, then <font color="red">, and
    then closing the red font, will still apply the yellow background to the following
    text. The same is true for every tag.
  - Added some support for Cascading StyleSheets.
  - Added some actual use for the "active link color": it's used as the hover color
    on links (using it as a true active color is mostly useless, since most of the
    time the page won't remain very long when clicking on a link to even see it)

  0.04 June 23, 2007
  - Added support for the <basefont> tag.
  - Added support for <ul>, <ol>, and <li>. I've even extended the HTML specs a
    little and added "diamonds" as a shape for <ul>, and allowed <ul> to specify
    a decimal escape code (<ul type="#0164">)
  - Added a "page history", so that the "visited link color" on pages can actually
    be applied to the links.
  - Fixed the <blockquote> so that the margin applies to the right side as well.

  0.02 June 20, 2007
  - Bugfix: on consecutive insert() commands (without clearing it in between),
    the entire content of the HTML already in the widget would be inserted again,
    in addition to the new content. This has been fixed.

  0.01 June 20, 2007
  - Initial release.

=head1 AUTHOR

Noah Petherbridge, http://www.kirsle.net/

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
