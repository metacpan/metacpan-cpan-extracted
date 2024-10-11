package Tk::PodViewer;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.04';
use base qw(Tk::Derived Tk::Frame);

Construct Tk::Widget 'PodViewer';

use Tk;
require Tk::ROText;
require Tk::Font;
use Pod::Simple::PullParser;

use Config;
my $mswin = 0;
$mswin = 1 if $Config{'osname'} eq 'MSWin32';

my @derivedtags = ('B', 'C', 'F', 'I', 'L', 'S');
my $derivedreg = qr/^([^BCFILS]*)([BCFILS]*)$/;

=head1 NAME

Tk::PodViewer - Simple ROText based pod viewer.

=head1 SYNOPSIS

 my $podviewer = $app->PodViewer->pack;
 $podviewer->load('SomePerlFileWithPod.pm');

=head1 DESCRIPTION

Tk::PodViewer is a simple pod viewer.
It inherits L<Tk::Frame>, but delegates all options and many
methods to L<Tk::ROText>.

It supports most of the pod tags. It ignores the following tags:

=over 4

 =begin
 =end
 =for
 X<>
 Z<>

=back

=head1 OPTIONS

=over 4

=item Switch: B<-fixedfontfamily>

Default value 'Hack'. Specifies the font family for tags that require a fixed font
family.

=item Switch: B<-loadcall>

Callback called at the end of each load. Receives the source determinator
as parameter.

=item Name: B<linkColor>

=item Class: B<LinkColor>

=item Switch: B<-linkcolor>

Default value '#3030DF' (light blue). Specifies the foreground color for link tags.

=item Switch: B<-scrollbars>

Only available at create time. Default value 'osoe'.

=item Switch: B<-zoom>

Default value 0. Set and get the zoom factor.

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;

	my $scrollbars = delete $args->{'-scrollbars'};
	$scrollbars = 'osoe' unless defined $scrollbars;

	$self->SUPER::Populate($args);
	
	my $text = $self->Scrolled('ROText',
		-width => 8,
		-height => 8,
		-insertwidth => 0,
		-scrollbars => $scrollbars,		
		-wrap => 'word',
	)->pack(-expand => 1, -fill => 'both');
	$text->bind('<Down>', [$text, 'yviewScroll', 1, 'units']);
	$text->bind('<Up>', [$text, 'yviewScroll', -1, 'units']);
	$self->Advertise('txt', $text);
	
	$self->{CURRENT} = undef;
	$self->{TAGS} = {};
	$self->{ZOOM} = 0;

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-fixedfontfamily => ['PASSIVE', undef, undef, 'Hack'],
		-loadcall => ['CALLBACK', undef, undef, sub {}],
		-linkcolor => ['PASSIVE', 'linkColor', 'LinkColor', '#3030DF'],
		-zoom => ['METHOD'],
		DEFAULT => [ $text ],
	);
	$self->Delegates(
		'compare' => $text,
		'delete' => $text,
		'get' => $text,
		'insert' => $text,
		'index' => $text,
		'tagBind' => $text,
		'tagCget' => $text,
		'tagConfigure' => $text,
		'tagRanges' => $text,
		DEFAULT => $self,
	);
	$self->after(10, ['postConfig', $self]);
}

=item B<clear>

Deletes all content and resets all stacks except the.

=cut

sub clear {
	my $self = shift;
	$self->Subwidget('txt')->delete('1.0', 'end');
	$self->{INDENTSTACK} = ['indent0'];
	$self->{INITEM} = 0;
	$self->{STACK} = [];
	$self->Callback('-loadcall', '');
}

=item B<clearHistory>

Resets the history stack.

=cut

sub clearHistory {
	my $self = shift;
	$self->clearNext;
	$self->{PREVIOUS} = [];
}

sub clearNext {
	my $self = shift;
	$self->{NEXT} = [];
}

sub clearTags {
	my $self = shift;
	$self->{TAGS} = {};
}

sub current {
	my $self = shift;
	$self->{CURRENT} = shift if @_;
	return $self->{CURRENT}
}

sub configureDerived {
	my $self = shift;
	my $tag = shift;
	my $font = shift;
	my @tags = @_;
	@tags = @derivedtags unless @tags;
#	my $font = $self->tagCget($tag, '-font');
	my @result = ();
	my $underline = $self->tagCget($tag, '-underline');
	$underline = 0 unless defined $underline;

	#create regular expression for testing
	my $reg = '';
	for (@tags) {
		$reg = $reg . "$_"
	}
	$reg = "([$reg]+)\$";
	$reg = qr/$reg/;

	for (@tags) {
		my $style = $_;
		next if $tag =~ /$style/;
		if ($tag =~ /$reg/) {
			next if $1 gt $style
		}
		my @fontopt = ();
		my @tagopt = (-underline => $underline);
		if ($style =~ /B/) {
			push @fontopt, -weight => 'bold'
		} elsif ($style =~ /I/) {
			push @fontopt, -slant => 'italic'
		} elsif ($style =~ /C/) {
			push @fontopt,	-family => $self->cget('-fixedfontfamily')
		} elsif ($style =~ /F/) {
			push @fontopt,	-family => $self->cget('-fixedfontfamily')
		} elsif ($style =~ /L/) {
			push @tagopt, -foreground => $self->cget('-linkcolor')
		} elsif ($style =~ /S/) {
#			push @tagopt, -wrap => 'none'
		}
		my $tfont = $self->fontCompose($font, @fontopt);
#		my $newstyle = "$tag$style";
		my $newstyle = $self->tagDerived($tag, $style);
		$self->tagConfigure($newstyle, @tagopt, -font => $tfont);
		$self->tagNew($newstyle);
		if ($style eq 'L') { #binding link
			$self->tagBind($newstyle, '<Enter>', sub {
				$self->{'cursor_save'} = $self->cget('-cursor'); 
				$self->configure(-cursor => 'hand1') 
			});
			$self->tagBind($newstyle, '<Leave>', sub { 
				$self->configure(-cursor => $self->{'cursor_save'});
				delete $self->{'cursor_save'};
			});
			$self->tagBind($newstyle, '<ButtonRelease-1>', sub {
				$self->linkClicked($newstyle);
			});
		}
		push @result, $newstyle;
		my @newtags = @tags;
		shift @newtags;
		push @result, $self->configureDerived($newstyle, $tfont, @newtags) if @newtags;
	}
	return @result;
}

=item B<configureTags>

Call after widget initialization and in all zoom methods.
Call this method after you make changes to any of the font options.

=cut

sub configureTags {
	my $self = shift;
	my $font = $self->Subwidget('txt')->cget('-font');
	my $family = $self->fontActual($font, '-family');
	my $size = $self->fontActual($font, '-size');
	my $zoomsize = $size - $self->zoom;
	my $hsize = $zoomsize + 1;
	my @result = ();

	#configuring head tags
	for (reverse 1 .. 6) {
		my $tag = "head$_";
		$hsize = $hsize - 2;
		my $font = $self->Font(
			-family => $family,
			-size => $hsize,
			
		);
		$self->tagConfigure($tag, -underline => 'true', -font => $font);
	}

	#composing text font
	my $tfont = $self->fontCompose($font, -size => $zoomsize);

	#configuring item-text tag
	$self->tagConfigure('item-text', -font => $tfont);

	#configuring paragraph tag
	$self->tagConfigure('Para', -font => $tfont);

	#configuring verbatim tag
	my $vfont = $self->Font(
		-family => $self->cget('-fixedfontfamily'),
		-size => $zoomsize,
	);
	$self->tagConfigure('Verbatim', -font => $vfont, -wrap => 'none');

	#reconfiguring existing tags
	my @list = $self->tagList;
	for (@list) {
		my $tag = $_;
		if ($tag =~ /^indent(\d+)$/) {
			my $size = $self->indentSize($1);
			$self->tagConfigure($tag,
				-lmargin1 => $size,
				-lmargin2 => $size,
			);
		} elsif ($tag =~ /$derivedreg/) {
			my $base = $1;
			my $dev = $2;
			my $font = $self->tagCget($base, '-font');
			my @der = split(//, $dev);
			$self->configureDerived($base, $font, @der);
		}
	}
	$self->tagConfigure('nbspace', -foreground => $self->cget('-background'))
}

sub fontCompose {
	my ($self, $font, %options) = @_;
	my $family = $self->fontActual($font, '-family');
	my $size = $self->fontActual($font, '-size');
	my $weight = $self->fontActual($font, '-weight');
	my $slant = $self->fontActual($font, '-slant');
	$family = $options{'-family'} if exists $options{'-family'};
	$size = $options{'-size'} if exists $options{'-size'};
	$slant = $options{'-slant'} if exists $options{'-slant'};
	$weight = $options{'-weight'} if exists $options{'-weight'};
	$slant = 'roman' if $slant eq '';
	$weight = 'normal' if $weight eq '';
	return $self->Font(
		-family => $family,
		-size => $size,
		-slant => $slant,
		-weight => $weight,
	);
}

sub ignore {
	my ($self, $tag) = @_;
	return $tag eq 'X'
}

sub indentDown {
	my $self = shift;
	my $stack = $self->indentStack;
	shift @$stack;
}

sub indentSize {
	my ($self, $indent) = @_;
	my $font = $self->cget('-font');
	my $size = $self->fontMeasure($font, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
	$size = int($size / 26);
	return $size * $indent
}

sub indentStack { return $_[0]->{INDENTSTACK} }

sub indentStackTop { return $_[0]->indentStack->[0] }

sub indentUp {
	my ($self, $indent) = @_;
	$indent = 2 unless defined $indent;
	my $top = $self->indentStackTop;
	$top =~ /(\d+)$/;
	my $topsize = $1;
	my $indentsize = $topsize + $indent;
	my $size = $self->indentSize($indentsize);
	my $tag = "indent$indentsize";
	unless ($self->tagExists($tag)) {
		$self->tagConfigure($tag,
			-lmargin1 => $size,
			-lmargin2 => $size,
		);
		$self->tagNew($tag);
	}
	my $stack = $self->indentStack;
	unshift @$stack, $tag
}

sub inItem {
	my $self = shift;
	$self->{INITEM} = shift if @_;
	return $self->{INITEM}
}

sub linkClicked {
	my ($self, $tag) = @_;
	my $pos = $self->index('insert');
	my $first;
	my $last;
	my @ranges = $self->tagRanges($tag);
	while (@ranges) {
		my $begin = shift @ranges;
		my $end = shift @ranges;
		if (($self->compare($begin, '<=', $pos)) and ($self->compare($end, '>=', $pos))) {
			$first = $begin;
			$last = $end;
			last;
		}
	}
	my $target = $self->get($first, $last);
	if ($target =~ /\:\:/) {
		$self->load($target)
	} elsif ($target =~ /\.pod$/) {
		$self->load($target)
	} elsif ($target =~ /\.pm$/) {
		$self->load($target)
	} else {
		$self->openURL($target)
	}
}

=item B<load>I<($source, ?$history?)>

Parses I<$source>. I<$source> can be a file name, a module name or a reference
tp a string.

You can set $history to false if you do not want $source added
to your history list. Usefull when reloading a source. By default it
is set to true.

=cut

sub load {
	my ($self, $source, $history) = @_;
	$history = 1 unless defined $history;
	$self->clear;

	#handling history
	if ($history) {
		my $cur = $self->current;
		if ((defined $cur) and ($cur ne $source)) {
			my $prev = $self->{PREVIOUS};
			push @$prev, $cur;
			$self->clearNext;
		}
	}
	$self->current($source);

	#convert module name to file
	my $original = $source;
	if ($source =~ s/\:\:/\//g) {
		for ('pod', 'pm') {
			my $test = Tk::findINC("$source.$_");
			if (defined $test) {
				$source = $test;
				last
			}
		}
	} else {
		for ('pod', 'pm') {
			my $test = Tk::findINC("$source.$_");
			if (defined $test) {
				$source = $test;
				last
			}
		}
	}

	unless ((-e $source) or (ref $source)) {
		warn "Source '$original' not found\n";
		return
	};

	#initializing pull parser
	my $p = new Pod::Simple::PullParser;
	$p->set_source($source);
	
	while (my $token = $p->get_token) {
		if($token->is_start) {
			my $name = $token->tagname;
			my $startline = $token->attr('start_line');

			if ($self->ignore($name)) { #do nothing

			} elsif (length($name) eq 1) {
				my $tname = $self->stackTop;
				if ($name eq 'S') {
					$self->{'nbspaces'} = 1;
				} elsif (defined $tname) {
					my $font = $self->tagCget($tname, '-font');
					my $der = $self->tagDerived($tname, $name);
					$self->configureDerived($tname, $font, $name) unless $self->tagExists($der);
					$self->stackPush($der);
				}

			} elsif ($name eq 'over-block') {
				my $indent = $token->attr('indent');
				$self->indentUp($indent);

			} elsif ($name eq 'over-text') {
				my $indent = $token->attr('indent');
				$self->indentUp($indent);

				$self->inItem(1);

			} elsif ($name =~ /^Para/) {
				$self->indentUp if $self->inItem;
				$self->stackPush($name);

			} elsif ($name =~ /^Verbatim/) {
				$self->indentUp if $self->inItem;
				$self->stackPush($name);

			} else {
				$self->stackPush($name) if $self->stackable($name)
			}

		} elsif($token->is_text) {
			my @tags = ();

			my $tname = $self->stackTop;
			push @tags, $tname if defined $tname;

			my $indent = $self->indentStackTop;
			push @tags, $indent if defined $indent;
			
			my @blob = ();
			my $text = $token->text;
			if (exists $self->{'nbspaces'}) {
				my @words = split(/\s/, $text);
				while (@words) {
					my $w = shift @words;
					if (@words) {
						push @blob, $w, [@tags], '-', ['nbspace'] 
					} else {
						push @blob, $w, [@tags] 
					}
				}
			} else {
				push @blob, $text, [ @tags ]
			}
			$self->insert('end', @blob); 

		} elsif($token->is_end) {
			my $name = $token->tagname;
			if ($self->ignore($name)) { #do nothing
			} elsif ($name eq 'over-block') {
				$self->indentDown;
			} elsif ($name eq 'over-text') {
				$self->inItem(0);
				$self->indentDown;
			} elsif ($name eq 'item-text') {
				$self->insert('end', "\n\n");
			} elsif ($name =~ /^Para/) {
				$self->indentDown if $self->inItem;
				$self->insert('end', "\n\n");
				$self->stackPull;
			} elsif ($name =~ /^Verbatim/) {
				$self->indentDown if $self->inItem;
				$self->insert('end', "\n\n");
				$self->stackPull;
			} else {
				delete $self->{'nbspaces'} if $name eq 'S';
				$self->insert('end', "\n") unless length($name) eq 1;
				$self->insert('end', "\n") if $name =~ /^head/ ;
				$self->insert('end', "\n") if $name =~ /^Verbatim/ ;
				$self->stackPull if $self->stackable($name);
			}
		}
	}
	$self->Callback('-loadcall', $self->current);
}

=item B<next>

Only works after B<previous> has been called.
Loads the next source in the history.

=cut

sub next {
	my $self = shift;
	my $nstack = $self->{NEXT};
	if (@$nstack) {
		my $pstack = $self->{PREVIOUS};
		unshift @$pstack, $self->current;
		my $new = shift @$nstack;
		$self->load($new, 0);
	}
}

sub openURL {
	my ($self, $url) = @_;
#	print "is web $url\n" if $url =~ /^[A-Za-z]+:\/\//;
	if ($mswin) {
		if ($url =~ /^[A-Za-z]+:\/\//) { #is a web document
			system("explorer \"$url\"");
		} else {
			system("\"$url\"");
		}
	} else {
		system("xdg-open \"$url\"");
	}
}

sub postConfig {
	my $self = shift;
	$self->clear;
	$self->clearHistory;
	$self->configureTags;
}

=item B<previous>

Only works after a link tag has been clicked.
Loads the previous source in the history.

=cut

sub previous {
	my $self = shift;
	my $pstack = $self->{PREVIOUS};
	if (@$pstack) {
		my $nstack = $self->{NEXT};
		unshift @$nstack, $self->current;
		my $new = shift @$pstack;
		$self->load($new, 0);
	}
}

sub stack { return $_[0]->{STACK} }

sub stackable {
	my ($self, $item) = @_;
	return '' if $item eq 'over-text';
	return '' if $item eq 'over-block';
	return '' if $item eq 'Document';
	return 1
}

sub stackPull {
	my $stack = $_[0]->stack;
	return unless @$stack;
	return shift @$stack;
}

sub stackPush {
	my ($self, $item) = @_;
	my $stack = $self->stack;
	unshift @$stack, $item
}

sub stackSize {
	my $stack = $_[0]->stack;
}

sub stackTop {
	return $_[0]->stack->[0];
}

sub tagDerived {
	my ($self, $tag, $der) = @_;
	if ($tag =~ /$derivedreg/) {
		my $base = $1;
		my $dev = $2;
		my $out = $base;
		if ($der eq '') {
			$out = "$base$dev"
		} else {
			my @keys = split(//, $der);
			my @pos = grep({ $dev gt $_ } @keys);
			my $pos = @pos;
			if ($pos eq 0) { #not found
				unshift @keys, $dev unless $dev eq $keys[0]
			} else {
				splice(@keys, $pos, 0, $dev) unless $dev eq $keys[$pos - 1];
			}
			for (@keys) { $out = "$out$_" }
		}
		return $out;
	}
}

sub tagExists {
	my ($self, $tag) = @_;
	return exists $self->tags->{$tag}
}

sub tagList {
	my $hash = $_[0]->tags;
	return sort keys %$hash
}

sub tagNew {
	my ($self, $tag) = @_;
	$self->tags->{$tag} = 1
}

sub tags { return $_[0]->{TAGS} }

sub zoom {
	my $self = shift;
	$self->{ZOOM} = shift if @_;
	return $self->{ZOOM}
}

=item B<zoomIn>

Increases font sizes by two pixels.

=cut

sub zoomIn {
	my $self = shift;
	$self->zoomNew($self->zoom + 2)
}

=item B<zoomNew>I<($zoom)>

Sets a new zoom size of original font sizes + $zoom pixels.

=cut

sub zoomNew {
	my ($self, $zoom) = @_;
	$self->zoom($zoom);
	$self->configureTags;
}

=item B<zoomOut>

Decreases font sizes by two pixels.

=cut

sub zoomOut {
	my $self = shift;
	$self->zoomNew($self->zoom - 2)
}

=item B<zoomReset>

Resets font sizes to zoom 0.

=cut

sub zoomReset {
	my $self = shift;
	$self->zoomNew(0)
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Pod::Simple>

=item L<Tk::ROText>

=back

=cut

1;
__END__
