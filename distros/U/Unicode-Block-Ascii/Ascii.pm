package Unicode::Block::Ascii;

# Pragmas.
use base qw(Unicode::Block);
use strict;
use warnings;

# Modules.
use Error::Pure qw(err);
use Readonly;
use Text::UnicodeBox;
use Text::UnicodeBox::Control qw(:all);

# Constants.
Readonly::Scalar our $SPACE => q{ };

# Version.
our $VERSION = 0.02;

# Get output.
sub get {
	my $self = shift;

	# Get width.
	$self->_get_chars;
	$self->{'_width'} = 16 + $self->{'_base_width'}
		+ (16 * $self->{'_char_width'});

	# Check width.
	if (defined $self->{'title'}
		&& (length $self->{'title'}) > $self->{'_width'}) {

		err 'Long title.';
	}

	# Box objext.
	my $box = Text::UnicodeBox->new;

	# Title.
	if (defined $self->{'title'}) {

		# Compute title.
		my $spaces = $self->{'_width'} - length $self->{'title'};
		my $left = int($spaces / 2);
		my $right = $self->{'_width'} - $left - length $self->{'title'};
		my $title = ($SPACE x $left).$self->{'title'}.($SPACE x $right);

		# Add title.
		$box->add_line(
			BOX_START('top' => 'light', 'bottom' => 'light'),
			$title,
			BOX_END(),
		);
	}

	# Header.
	my @headers = $SPACE x $self->{'_base_width'}, BOX_RULE;
	foreach my $header_char (0 .. 9, 'A' .. 'F') {
		if (@headers) {
			push @headers, BOX_RULE;
		}
		my $table_header_char = $header_char;
		if ($self->{'_char_width'} > 1) {
			$table_header_char
				= ($SPACE x ($self->{'_char_width'} - 1)).
				$header_char;
		}
		push @headers, $table_header_char;
	}
	my @title;
	if (! defined $self->{'title'}) {
		@title = ('top' => 'light');
	}
	$box->add_line(
		BOX_START(@title, 'bottom' => 'light'), @headers, BOX_END(),
	);

	# Columns.
	my @cols;
	foreach my $item (@{$self->{'_chars'}}) {
		if (@cols) {
			push @cols, BOX_RULE;
		} else {
			push @cols, $SPACE.$item->base.$SPACE, BOX_RULE;
			my $last_num = hex $item->last_hex;
			if ($last_num > 0) {
				push @cols, ($SPACE, BOX_RULE) x $last_num;
			}
		}
		my $char = $item->char;
		if ($item->width < $self->{'_char_width'}) {
			$char = ($SPACE x ($self->{'_char_width'}
				- $item->width)).$char;
		}
		push @cols, $char;
		if ($item->last_hex eq 'f') {
			$box->add_line(
				BOX_START('bottom' => 'light'),
				@cols,
				BOX_END(),
			);
			@cols = ();
		}
	}
	if (@cols) {
		my $spaces = @cols / 2;
		$box->add_line(
			BOX_START('bottom' => 'light'),
			@cols, BOX_RULE,
			($SPACE, BOX_RULE) x (16 - $spaces),
			$SPACE,
			BOX_END,
		);
	}
	return $box->render;
}

# Get chars and compute char width.
sub _get_chars {
	my $self = shift;
	$self->{'_chars'} = [];
	$self->{'_char_width'} = 1;
	$self->{'_base_width'} = 0;
	while (my $item = $self->next) {

		# Look for maximal character width in table.
		if ($item->width > $self->{'_char_width'}) {
			$self->{'_char_width'} = $item->width;
		}

		# Look for maximal base length in table.
		if ((length $item->base) + 2 > $self->{'_base_width'}) {
			$self->{'_base_width'} = (length $item->base) + 2;
		}

		# Add character.
		push @{$self->{'_chars'}}, $item;
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Unicode::Block::Ascii - Ascii output of unicode block.

=head1 SYNOPSIS

 use Unicode::Block::Ascii;
 my $obj = Unicode::Block::Ascii->new(%parameters);
 my $output = $obj->get;
 my $item = $obj->next;

=head1 METHODS

=over 8

=item C<new(%parameters)>

Constructor.

=over 8

=item * C<char_from>

 Character from.
 Default value is '0000'.

=item * C<char_to>

 Character to.
 Default value is '007f'.

=item * C<title>

 Title of block.
 Default value is undef.

=back

=item C<get()>

 Get output.
 Return string with ascii table of Unicode::Block object.

=item C<next()>

 Get next character.
 Returns Unicode::Block::Item object for character, if character exists.
 Returns undef, if character doesn't exist.

=back

=head1 ERRORS

 new():
         From Class::Utils::set_params_pub():
                 Unknown parameter '%s'.

 get():
         Long title.

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Encode qw(encode_utf8);
 use Unicode::Block::Ascii;
 use Unicode::Block::List;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 block_name\n";
         exit 1;
 }
 my $block_name = $ARGV[0];

 # List object.
 my $obj = Unicode::Block::List->new;

 # Get Unicode::Block for block name.
 my $block = $obj->block($block_name);

 # Get ASCII object.
 my $block_ascii = Unicode::Block::Ascii->new(%{$block});

 # Print to output.
 print encode_utf8($block_ascii->get)."\n";
 
 # Output:
 # Usage: /tmp/o1NG0vm_Wf block_name

 # Output with 'Block Elements' argument:
 # ┌────────────────────────────────────────┐
 # │             Block Elements             │
 # ├────────┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┤
 # │        │0│1│2│3│4│5│6│7│8│9│A│B│C│D│E│F│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+258x │▀│▁│▂│▃│▄│▅│▆│▇│█│▉│▊│▋│▌│▍│▎│▏│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+259x │▐│░│▒│▓│▔│▕│▖│▗│▘│▙│▚│▛│▜│▝│▞│▟│
 # └────────┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;
 
 # Modules.
 use Curses::UI;
 use Encode qw(encode_utf8);
 use Unicode::Block::Ascii;
 use Unicode::Block::List;
 
 # Get unicode block list.
 my $list = Unicode::Block::List->new;
 my @unicode_block_list = $list->list;
 
 # Window.
 my $cui = Curses::UI->new;
 my $win = $cui->add('window_id', 'Window');
 $win->set_binding(\&exit, "\cQ", "\cC");
 
 # Popup menu.
 my $popupbox = $win->add(
         'mypopupbox', 'Popupmenu',
         '-labels' => {
                 map { $_, $_ } @unicode_block_list,
         },
         '-onchange' => sub {
                 my $self = shift;
                 $cui->leave_curses;
                 my $block = $list->block($self->get);
                 my $block_ascii = Unicode::Block::Ascii->new(%{$block});
                 print encode_utf8($block_ascii->get)."\n";
                 exit 0;
         },
         '-values' => \@unicode_block_list,
 );
 $popupbox->focus;
 
 # Loop.
 $cui->mainloop;

 # Output after select 'Geometric Shapes' item:
 # ┌────────────────────────────────────────┐
 # │            Geometric Shapes            │
 # ├────────┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┤
 # │        │0│1│2│3│4│5│6│7│8│9│A│B│C│D│E│F│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+25ax │■│□│▢│▣│▤│▥│▦│▧│▨│▩│▪│▫│▬│▭│▮│▯│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+25bx │▰│▱│▲│△│▴│▵│▶│▷│▸│▹│►│▻│▼│▽│▾│▿│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+25cx │◀│◁│◂│◃│◄│◅│◆│◇│◈│◉│◊│○│◌│◍│◎│●│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+25dx │◐│◑│◒│◓│◔│◕│◖│◗│◘│◙│◚│◛│◜│◝│◞│◟│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+25ex │◠│◡│◢│◣│◤│◥│◦│◧│◨│◩│◪│◫│◬│◭│◮│◯│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+25fx │◰│◱│◲│◳│◴│◵│◶│◷│◸│◹│◺│◻│◼│◽│◾│◿│
 # └────────┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘

=head1 DEPENDENCIES

L<Error::Pure>,
L<Readonly>,
L<Text::UnicodeBox>,
L<Text::UnicodeBox::Control>,
L<Unicode::Block>.

=head1 REPOSITORY

L<https://github.com/tupinek/Unicode-Block-Ascii>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2013-2017 Michal Josef Špaček
 BSD 2-Clause License

=head1 VERSION

0.02

=cut
