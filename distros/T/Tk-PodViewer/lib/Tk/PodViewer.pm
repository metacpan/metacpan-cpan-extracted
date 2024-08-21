package Tk::PodViewer;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';
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

my %ignore = (
	'begin' => 1,
	'end' => 1,
	'for' => 1,
	'X' => 1,
	'Z' => 1,
);

=head1 NAME

Tk::PodViewer - Simple ROText based pod viewer.

=head1 SYNOPSIS

 my $podviewer = $app->PodViewer->pack;
 $podviewer->load('SomePerlFileWithPod.pm');

=head1 DESCRIPTION

Tk::PodViewer is a simple pod viewer.
It inherits L<Tk::Frame>, but delegates all options and methods to L<Tk::ROText>.

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

=item B<-fixedfontfamily>

Default value 'Hack'. Specifies the font family for tags that require a fixed font
family.

=item B<-linkcolor>

Default value '#0000FF' (blue). Specifies the foreground color for link tags.

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	my $text = $self->Scrolled('ROText',
		-width => 8,
		-height => 8,
		-insertwidth => 0,
		-scrollbars => 'osoe',		
		-wrap => 'word',
	)->pack(-expand => 1, -fill => 'both');
	$self->Advertise('txt', $text);
	
	$self->clear;
	$self->clearHistory;
	$self->{BASEFONTSIZE} = undef;
	$self->{CURRENT} = undef;
	$self->{TAGS} = [];
	$self->{ZOOM} = 0;

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-fixedfontfamily => ['PASSIVE', undef, undef, 'Hack'],
		-linkcolor => ['PASSIVE', undef, undef, '#0000DF'],
		DEFAULT => [ $text ],
	);
	$self->Delegates(
		DEFAULT => $text,
	);
	$self->after(10, ['configureTags', $self]);
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
}

=item B<clearHistory>

Resets the history stack.

=cut

sub clearHistory {
	my $self = shift;
	$self->{NEXT} = [];
	$self->{PREVIOUS} = [];
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
			push @tagopt, -wrap => 'none'
		}
		my $tfont = $self->fontCompose($font, @fontopt);
		my $newstyle = "$tag$style";
		$self->tagConfigure($newstyle, @tagopt, -font => $tfont);
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
	$self->{BASEFONTSIZE} = $size;
	my $zoomsize = $size + $self->zoom;
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
		push @result, $tag;
		push @result, $self->configureDerived($tag, $font);
	}

	#composing text font
	my $tfont = $self->fontCompose($font, -size => $zoomsize);

	#configuring item-text tags
	$self->tagConfigure('item-text', -font => $tfont);
	push @result, 'item-text';
	push @result, $self->configureDerived('item-text', $tfont);

	#configuring paragraph tags
	$self->tagConfigure('Para', -font => $tfont);
	push @result, 'Para';
	push @result, $self->configureDerived('Para', $tfont);

	#configuring verbatim tag
	my $vfont = $self->Font(
		-family => $self->cget('-fixedfontfamily'),
		-size => $zoomsize,
	);
	$self->tagConfigure('Verbatim', -font => $vfont, -wrap => 'none');
	push @result, 'Verbatim';

	$self->{TAGS} = \@result
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
	return exists $ignore{$tag}
}

sub indentDown {
	my $self = shift;
	my $stack = $self->indentStack;
	shift @$stack;
}

sub indentSize {
	my ($self, $indent) = @_;
	my $font = $self->cget('-font');
	my $size = $self->fontMeasure($font, '0123456789');
	$size = int($size / 10);
	return $size * $indent
}

sub indentStack { return $_[0]->{INDENTSTACK} }

sub indentStackTop { return $_[0]->indentStack->[0] }

sub indentUp {
	my ($self, $indent) = @_;
	$indent = 2 unless defined $indent;
	my $top = $self->indentStackTop;
#	print "top $top\n";
	$top =~ /(\d+)$/;
	my $topsize = $1;
	my $indentsize = $topsize + $indent;
	my $size = $self->indentSize($indentsize);
#	print "top $topsize, indent $indent, size $indentsize, $size px\n";
	my $tag = "indent$indentsize";
	$self->tagConfigure($tag,
		-lmargin1 => $size,
		-lmargin2 => $size,
	);
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

=item B<load>I<($source)>

Parses I<$source>. I<$source> can be a file name, a module name or a reference
tp a string.

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
		}
	}
	$self->current($source);

	#convert module name to file
	if ($source =~ s/\:\:/\//g) {
		for ('pod', 'pm') {
			my $test = Tk::findINC("$source.$_");
			if (defined $test) {
				$source = $test;
				last
			}
		}
	}

	#initializing pull parser
	my $p = new Pod::Simple::PullParser;
	$p->set_source($source);
	
	while(my $token = $p->get_token) {
		if($token->is_start) {
			my $name = $token->tagname;
			my $startline = $token->attr('start_line');

			if ($self->ignore($name)) { #do nothing

			} elsif (length($name) eq 1) {
				my $tname = $self->stackTop;
				if (defined $tname) {
					my $der = $self->tagDerived($tname, $name);
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

			} else {
				$self->stackPush($name) if $self->stackable($name)
			}

		} elsif($token->is_text) {
			my @tags = ();

			my $tname = $self->stackTop;
			push @tags, $tname if defined $tname;

			my $indent = $self->indentStackTop;
			push @tags, $indent if defined $indent;

			$self->insert('end', $token->text, [ @tags ]); 

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
			} else {
				$self->insert('end', "\n") unless length($name) eq 1;
				$self->insert('end', "\n") if $name =~ /^head/ ;
				$self->insert('end', "\n") if $name =~ /^Verbatim/ ;
				$self->stackPull if $self->stackable($name);
			}
		}
	}
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

sub tagList {
	my $self = shift;
	my $t = $self->{TAGS};
	return @$t;
}

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
	$zoom = 0 - $zoom;
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

Calling the B<configureTags> method takes ages.

If you find any bugs, please contact the author.

=head1 TODO

Change the S command into real non breakable spaces instead of just a wrap to none.

Configure tags as the need arises instead of all at once.

=head1 SEE ALSO

=over 4

=item L<Pod::Simple>

=item L<Tk::ROText>

=back

=cut

1;
__END__
