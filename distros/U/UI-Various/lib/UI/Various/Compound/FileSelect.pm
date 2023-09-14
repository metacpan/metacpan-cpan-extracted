package UI::Various::Compound::FileSelect;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Compound::FileSelect - general file selection widget of L<UI::Various>

=head1 SYNOPSIS

    use UI::Various;
    my $main = UI::Various::Main->new(height => 20, width => 60);
    my $fs =
        UI::Various::Compound::FileSelect->new(
            mode => 2,
            directory => $ENV{HOME},
            filter => [['all files' => '.'], ['Perl scripts' => '\.pl$']],
            height => 12,
            width => 20);
    my $dialog = $main->dialog({title => 'select input files'}, $fs);
    ...
    $main->mainloop();
    print join("\n", $fs->selection(), '');

=head1 ABSTRACT

This module defines a specialised compound L<UI::Various> widget for
selecting one or more files for input or one file for output.

=head1 DESCRIPTION

The C<Compound::FileSelect> widget creates and returns a compound
L<Box|UI::Various::Box> widget containing everything needed to select a
file.  This widget can be simply put into a dialog as in the example in the
L<SYNOPSIS|/SYNOPSIS> or put into another L<Box|UI::Various::Box> to combine
it with something else.  All directory operations are handled internally.

Note that the given width and height are the values for the internal
L<Listbox|UI::Various::Listbox> widget.  The C<FileSelect> widget is notably
higher than that.  Besides those common attributes inherited from
C<UI::Various::widget> the C<Compound::FileSelect> widget knows the
following additional attributes:

=head2 Attributes

=over

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use Cwd 'abs_path';

our $VERSION = '0.42';

use UI::Various::core;
use UI::Various::Box;
use UI::Various::Button;
use UI::Various::Input;
use UI::Various::Optionmenu;
use UI::Various::Listbox;
use UI::Various::Text;

require Exporter;
our @ISA = qw(UI::Various::Box);
our @EXPORT_OK = qw();

#########################################################################

=item directory [rw, fixed, optional]

the initial working directory of the file selector as string or variable
reference defaulting to the current directory of the application (during
creation of the widget)

Note that though this attribute may not be changed from outside after
initialisation, it is always changed internally to the directory currently
displayed in the file selection widget.

=cut

sub directory($;$)
{
    return access('directory', undef, @_);
}

=item filter [rw, fixed, optional]

a list of filters that can be applied to the files listed (as
L<Optionmenu|UI::Various::Optionmenu>)

The list of filters must be an ARRAY of pairs (reference to an ARRAY with
two elements each).  The first entry of a pair is the entry shown in the
selection and the second one must be a regular expression used to filter the
files to be displayed.  (We don't use a glob as a regular expression allows
much more flexibility.)

Note that directories are always displayed to allow traversing the file
system.

=cut

sub filter($;$)
{
    return access('filter', undef, @_);
}

=item mode [rw, fixed]

the mandatory file selection mode of the file selector:

=over

=item C<0>

the file selector is used to select or enter a file name for an output file
(which may not yet exist)

=item C<1>

the file selector is used to select one input file

=item C<2>

the file selector is used to select one or more input files (using a
L<Optionmenu|UI::Various::Listbox> with multiple selection)

=back

=cut

sub mode($;$)
{
    return access('mode',
		  sub{
		      unless (m/^[012]$/)
		      {
			  error('parameter__1_must_be_in__2__3',
				'mode', 0, 2);
			  $_ = 1;
		      }
		  },
		  @_);
}

=item symlinks [rw, fixed]

an optional flag if symbolic links can be selected or not:

=over

=item C<0>

Symbolic links are automatically followed (replaced with their target).
This is the default.

=item C<1>

Symbolic links are kept as they are.  This allows selecting them instead of
their target.

=back

=cut

sub symlinks($;$)
{
    return access('symlinks',
		  sub{
		      unless (m/^[01]$/)
		      {
			  error('parameter__1_must_be_in__2__3',
				'symlinks', 0, 1);
			  $_ = 1;
		      }
		  },
		  @_);
}

#########################################################################
#
# internal constants and data:

use constant ALLOWED_PARAMETERS =>
    (UI::Various::Box::ALLOWED_PARAMETERS, qw(directory filter mode symlinks));
use constant DEFAULT_ATTRIBUTES =>
    (directory => abs_path('.'), height => 8, width => 24, symlinks => 0);

#########################################################################
#########################################################################

=back

=head1 METHODS

Besides the accessors (attributes) described above and the attributes and
methods of L<UI::Various::widget>, L<UI::Various::container> and
L<UI::Various::Box>, the following additional methods are provided by the
C<FileSelect> class itself:

=cut

#########################################################################

=head2 B<new> - constructor

see L<UI::Various::core::construct|UI::Various::core/construct - common
constructor for UI elements>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub new($;\[@$])
{
    debug(2, __PACKAGE__, '::new(', join(',', @_), ')');
    my $self = construct({ DEFAULT_ATTRIBUTES },
			 '^(?:' . join('|', ALLOWED_PARAMETERS) . ')$',
			 @_,
			 # override everything passed:
			 border => 0, columns => 1, rows => 3);
    unless (defined $self->{mode})
    {
	error('mandatory_parameter__1_is_missing', 'mode');
	return undef;
    }
    @ISA = (UI::Various::core::ui() . '::Box');

    my ($mode, $height, $width) = ($self->mode, $self->height, $self->width);

    my $row1 = UI::Various::Box->new(columns => 2);
    $row1->add(UI::Various::Button->new(text => '..',
					width => 2,
					code => sub{
					    my @files = $self->_cd('..');
					    $self->{_widget}{files}
						->replace(@files);
					}),
	       UI::Various::Text->new(text => \$self->{directory}));
    my @widgets = ($row1);
    my %w = (row1 => $row1);
    $self->{_widget} = \%w;

    if (defined $self->{filter})
    {
	my $filter =
	    UI::Various::Optionmenu->new(init => $self->{filter}[0][1],
					 options => $self->{filter},
					 on_select => sub {
					    my @files = $self->_cd();
					    $self->{_widget}{files}
						->replace(@files);
					 });
	push @widgets, $filter;
	$w{filter} = $filter;
    }

    my @files = $self->_cd();
    my $files =
	UI::Various::Listbox->new(height => $height,
				  width => $width,
				  selection => $mode == 2 ? 2 : 1,
				  texts => \@files,
				  on_select => sub{
				      my $lb = $self->{_widget}{files};
				      my @selection = $lb->selected();
				      0 < @selection  or  return;
				      local $_;
				      @selection =
					  map { $lb->{texts}[$_] } @selection;
				      if (-d $self->{directory} . '/' .
					  $selection[0])
				      {
					  my @files = $self->_cd($selection[0]);
					  $lb->replace(@files);
					  return;
				      }
				      if (defined $self->{_inputvar})
				      {
					  $self->{_inputvar} = $selection[0];
					  $w{input}->can('_update')  and
					      $w{input}->_update;
				      }
				  });
    push @widgets, $files;
    $w{files} = $files;

    if ($mode == 0)
    {
	$self->{_inputvar} = '';
	my $input = UI::Various::Input->new(textvar => \$self->{_inputvar},
					    width => $width);
	push @widgets, $input;
	$w{input} = $input;
    }

    $self->{_msg} = ' ' x $width;
    my $msg = UI::Various::Text->new(text => \$self->{_msg}, width => $width);
    push @widgets, $msg;
    $w{msg} = $msg;

    $self->rows(scalar(@widgets));
    $self->add(@widgets);
    return $self;
}

#########################################################################

=head2 B<_cd> - get list of files for directory

This internal method returns the list of sub-directories and files according
to the current configuration.  An optional parameter changes the current
directory prior to that.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _cd($;$)
{
    my ($self, $cd) = @_;
    shift @_;
    debug(3, __PACKAGE__, '::_cd(', @_, ')');
    local $_ = $self->{directory};

    $self->{_msg} = ' ' x $self->{width};
    $cd  and  $_ .= '/' . $cd;
    if (m|^/|  and  $self->symlinks)
    {
	s|(?<=.)/[^/]+/\.\.$||;
	s|^/[^/]+/\.\.$|/|;
	s|^/{2,}|/|;
    }
    else
    {
	$_ = abs_path($_);
	unless ($_)
	{
	    $self->{_msg} = message('reset_directory_invalid_symbolic_link');
	    $_ = '/';
	}
    }
    my @files = ();
    my $dir;
    if (opendir $dir, $_)
    {
	$self->{directory} = $_;
	my $re_filter = '.';
	defined  $self->{_widget}{filter}  and
	    $re_filter = $self->{_widget}{filter}->selected;
	my $path = $_;
	while (readdir $dir)
	{
	    next if m/^\.{1,2}$/;
	    if (-d $path . '/' . $_  or  m/$re_filter/)
	    {   push @files, $_;   }
	}
	closedir $dir;
    }
    elsif ($cd)
    {
	@files = $self->_cd();
	$self->{_msg} = message('can_t_open__1__2', $_, $!);
    }
    return sort @files;
}

#########################################################################

=head2 B<selection> - get current selection of file selection widget

    $selection = $listbox->selection();  # C<mode =E<gt> 0 or 1>
    @selection = $listbox->selection();  # C<mode =E<gt> 2>

=head3 description:

This method returns the full path(s) to the file(s) selected or entered (in
case of C<mode =E<gt> 0>) in the file selection widget.  If there is nothing
selected at all, the method returns the current directory with a trailing
C</>.  (A directory selected after a regular file in C<mode =E<gt> 2> has no
trailing C</>.)

=head3 returns:

selected/entered element(s)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub selection($)
{
    my ($self) = @_;
    local $_;
    my $lb = $self->{_widget}{files};
    my $directory = $self->{directory};
    $directory =~ s|(?<=[^/])$|/|;
    if ($self->mode == 0)
    {	return $directory . $self->{_inputvar};   }
    if ($self->mode == 1)
    {
	$_ = $lb->selected();
	return defined $_ ? $directory . $lb->{texts}[$_] : $directory;
    }
    my @selection = $lb->selected();
    @selection =
	map { $directory . $lb->{texts}[$_] }
	@selection;
    @selection  or  @selection = ($directory);
    return @selection;
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
