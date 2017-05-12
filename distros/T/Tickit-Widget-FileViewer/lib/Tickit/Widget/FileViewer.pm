package Tickit::Widget::FileViewer;
# ABSTRACT: Simple file-viewing widget for Tickit
use strict;
use warnings;
use parent qw(Tickit::Widget);

use Tickit::Utils qw(substrwidth);
use List::Util qw(min max);
use Text::Tabs ();

our $VERSION = '0.004';

=head1 NAME

Tickit::Widget::FileViewer - support for viewing files in L<Tickit>.

=head1 VERSION

Version 0.004

=head1 SYNOPSIS

 use Tickit::Async;
 use Tickit::Widget::FileViewer;
 my $tickit = Tickit::Async->new;
 my $viewer = Tickit::Widget::FileViewer->new(
   file => 'somefile.txt',
 );
 $tickit->set_root_widget($viewer);
 my $loop = IO::Async::Loop->new;
 $loop->add($tickit);
 $tickit->run;

=cut

use Tickit::Style;

BEGIN {
	style_definition base =>
		line_fg => 6;
}

=head1 METHODS

=cut


sub cols { 1 }
sub lines { 1 }

=head2 new

Instantiate a new fileviewer widget. Passes any given
named parameters to L</configure>.

=cut

sub new {
	my $self = shift->SUPER::new;
	my %args = @_;
	$self->{top_line} = 0;
	$self->{cursor_line} = 0;
	$self->configure(%args);
	$self
}

=head2 configure

Takes the following named parameters:

=over 4

=item * file - the file to load

=item * line - which line to jump to

=back

=cut

sub configure {
	my $self = shift;
	my %args = @_;
	if(my $file = delete $args{file}) {
		$self->load_file($file);
	}
	if(defined(my $line = delete $args{line})) {
		$self->cursor_line($line);
	}
	$self;
}

=head2 load_file

Loads the given file into memory.

=cut

sub load_file {
	my $self = shift;
	my $file = shift;
	$self->{filename} = $file;
	open my $fh, '<:encoding(utf-8)', $file or die "$file - $!";
	chomp(my @line_data = <$fh>);
	$self->{file_content} = \@line_data;
	$fh->close or die $!;
	$self;
}

=head2 line_attributes

Given a zero-based line number and line text, returns the attributes
to apply for this line.

This method is intended for line-level highlights such as current cursor
position or selected text - For syntax highlighting, overriding the
L</render_line_data> method may be more appropriate.

=cut

sub line_attributes {
	my $self = shift;
	my ($line, $txt) = @_;
	my %attr = (fg => 7);
	%attr = (fg => 6, bg => 4, b => 1) if $line == $self->cursor_line;
	return %attr;
}

=head2 render_to_rb

Render this widget. Will call L</render_line_data> and L</render_line_number>
to do the actual drawing.

=cut

sub render_to_rb {
	my ($self, $rb, $rect) = @_;
	my $win = $self->window or return;

	my $line = $rect->top + $self->top_line;
	my @line_data = @{$self->{file_content}}[$line .. min($line + $rect->lines, $#{$self->{file_content}})];

	# FIXME '7'? Is constant.pm on holiday?
	my $w = $win->cols - 7;
	for my $row ($rect->linerange) {
		if(@line_data) {
			# FIXME is this unicode-safe? probably not
			local $Text::Tabs::tabstop = 4;
			my $txt = substrwidth(Text::Tabs::expand(shift @line_data), 0, $w);
		# $rb->goto($row, $);
			$self->render_line_number($rb, $rect, $row, $line);
			$self->render_line_data($rb, $rect, $row, $line, $txt);
		} else {
			$rb->erase_at($row, $rect->left, $rect->cols, $self->get_style_pen);
		}
		++$line;
	}
}

=head2 render_line_number

Renders the given (zero-based) line number at the current
cursor position.

Subclasses should override this to provide styling as required.

=cut

sub render_line_number {
	my ($self, $rb, $rect, $row, $line) = @_;
	my $win = $self->window or return;
	$rb->text_at($row, 0, sprintf("%6d ", $line + 1), $self->get_style_pen('line'));
}

=head2 render_line_data

Renders the given line text at the current cursor position.

Subclasses should override this to provide styling as required.

=cut

sub render_line_data {
	my ($self, $rb, $rect, $row, $line, $txt) = @_;
	my $win = $self->window or return;
	my $pen = Tickit::Pen->new($self->line_attributes($line, $txt));
	$rb->text_at($row, 7, $txt, $pen);
}


=head2 on_key

Handle a keypress event. Passes the event on to L</handle_key> or
L</handle_text> as appropriate.

=cut

sub on_key {
	my ($self, $ev) = @_;
	return $self->handle_key($ev->str) if $ev->type eq 'key';
	return $self->handle_text($ev->str) if $ev->type eq 'text';
	die "wtf is @_ ?\n";
}

=head2 cursor_line

Accessor for the current cursor line. Will trigger a redraw if
we have a window and the cursor line has changed.

=cut

sub cursor_line {
	my $self = shift;
	if(@_) {
		my $line = shift;
		return $self if $self->{cursor_line} == $line;
		$self->{cursor_line} = $line;
		if(my $win = $self->window) {
			if($line < $self->top_line) {
				$self->top_line($line);
			} elsif($line >= $self->top_line + $win->lines) {
				$self->top_line($line - ($win->lines - 1));
			}
			$self->redraw;
		}
		return $self;
	}
	return $self->{cursor_line};
}

sub window_gained {
	my ($self, $win) = @_;
	$self->SUPER::window_gained($win);
	my $line = $self->cursor_line;
	if($line < $self->top_line) {
		$self->top_line($line);
	} elsif($line >= $self->top_line + $win->lines) {
		$self->top_line($line - ($win->lines - 1));
	}
	$self->redraw;
}

=head2 handle_key

Handle a keypress event. Currently hard-coded to accept
up, down, pageup and pagedown events.

=cut

sub handle_key {
	my $self = shift;
	my $key = shift;
	if($key eq 'Down') {
		if($self->cursor_line < $#{$self->{file_content}}) {
			$self->cursor_line($self->cursor_line + 1);
		} else {
			$self->cursor_line(0);
		}
	} elsif($key eq 'Up') {
		if($self->cursor_line > 0) {
			$self->cursor_line($self->cursor_line - 1);
		} else {
			$self->cursor_line($#{$self->{file_content}});
		}
	} elsif($key eq 'PageDown') {
		if($self->cursor_line < $#{$self->{file_content}}) {
			$self->cursor_line(min($self->cursor_line + 10, $#{$self->{file_content}}));
		}
	} elsif($key eq 'PageUp') {
		if($self->cursor_line > 0) {
			$self->cursor_line(max($self->cursor_line - 10, 0));
		}
	}
}

=head2 handle_text

Stub method for dealing with text events.

=cut

sub handle_text { }

=head2 top_line

First line shown in the window.

=cut

sub top_line {
	my $self = shift;
	if(@_) {
		my $line = shift;
		return $self if $line == $self->{top_line};
		my $prev = $self->{top_line};
		$self->{top_line} = $line;
		if(my $win = $self->window) {
			$self->redraw unless $win->scroll($line - $prev, 0);
		}
		return $self;
	}
	return $self->{top_line};
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Tickit::Widget::Scroller> - support for scrollable list of widgets, generally much cleaner and
flexible than this implementation, and could easily provide similar functionality if the line number and
code for each line are wrapped in another widget

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2014. Licensed under the same terms as Perl itself.
