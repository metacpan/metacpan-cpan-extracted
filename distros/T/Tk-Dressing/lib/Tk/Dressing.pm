package Tk::Dressing;

use warnings;
use strict;
use Carp;

#==================================================================
# $Author    : Djibril Ousmanou                                   $
# $Copyright : 2011                                               $
# $Update    : 01/01/2011 00:00:00                                $
# $AIM       : Set a design for a Tk widget and its children      $
#==================================================================

use Tk;
use Config::Std { def_gap => 0 };
use File::Basename qw/ dirname /;
use File::Copy qw / copy /;
use File::Spec;

use vars qw($VERSION);
$VERSION = '1.04';

# get theme directory
my $themes_directory = File::Spec->catfile( dirname( $INC{'Tk/Dressing.pm'} ), 'DressingThemes' );

my %new_theme;
my %initial_theme;
my $current_theme;
my $POINT = q{.};

sub new {
  my ($self) = @_;

  $self = ref($self) || $self;
  my $this = {};
  bless $this, $self;

  return $this;
}

sub get_current_theme {
  my $this = shift;

  return $current_theme;
}

sub get_all_theme {
  my $this = shift;

  opendir my $fh_rep, $themes_directory or croak "Unable to read themes directory : $themes_directory\n";
  my @alltheme = grep {m/\.ini$/msx} readdir $fh_rep;
  foreach (@alltheme) { s/\.ini$//msx; }
  closedir $fh_rep or croak "Unable to close themes directory\n";

  # New themes loaded
  push @alltheme, keys %new_theme;

  my %unique;
  @unique{@alltheme} = ();

  return keys %unique;
}

sub get_default_theme_file {
  my ( $this, $theme, $directory ) = @_;

  if ( not defined $theme ) {
    carp("Theme not defined\n");
    return;
  }

  $directory = defined $directory ? $directory : $POINT;

  my $theme_file     = "$themes_directory/$theme.ini";
  my $new_theme_file = "$directory/$theme.ini";

  # default theme file
  if ( -e $theme_file ) {
    copy( $theme_file, $new_theme_file );
    return $new_theme_file;
  }
  carp("$theme not found\n");

  return;
}

sub load_theme_file {
  my ( $this, $theme, $theme_file ) = @_;

  if ( -e $theme_file ) {
    read_config $theme_file => my %config;
    $new_theme{$theme} = \%config;
    return;
  }

  carp("$theme_file not found\n");
  return;
}

sub clear {
  my ( $this, $widget ) = @_;

  if ( ( not defined $widget ) or ( !Exists $widget) ) {
    carp("Widget not defined\n");
    return;
  }

  if (%initial_theme) {
    $this->design_widget( -widget => $widget, -clear => 1 );
    $current_theme = undef;
  }

  return 1;
}

sub _default_config {
  my ( $this, $widget, $ref_config_theme ) = @_;

  my ( $class, $type ) = split m/::/msx, ref $widget;
  $type = defined $type ? $type : $class;
  if ( not defined $type ) { return; }

  # Store the initial configuration before set the first theme
  if ( !$initial_theme{$type} ) {
    foreach my $option ( sort keys %{ $ref_config_theme->{$type} } ) {
      my $initial_value = $widget->cget($option);
      next if ( not defined $initial_value );

      if ( $initial_value eq 'SystemButtonFace' and $type eq 'Entry' ) {
        if ( $option eq '-background' ) { $initial_value = 'white'; }
      }
      elsif ( $initial_value eq 'SystemWindow' and $type eq 'Frame' ) {
        $initial_value = 'SystemButtonFace';
      }
      $initial_theme{$type}{$option} = $initial_value;
    }
  }

  # children widgets design setting
  foreach my $child_level1 ( sort $widget->children ) {
    $this->_default_config( $child_level1, $ref_config_theme );
  }
  return;
}

#============================================
# set design in widget and its children
#============================================
sub design_widget {
  my ( $this, %information ) = @_;

  my $theme = $information{-theme} || 'djibel';
  if ( not defined $theme ) {
    carp("Theme not defined\n");
    return;
  }

  my $widget = $information{-widget};
  if ( ( not defined $widget ) or ( !Exists $widget ) ) {
    carp("Widget not defined\n");
    return;
  }

  my $clear = $information{-clear};

  # Get theme configuration
  my $ref_config_theme;

  # Clear
  if ( defined $clear and $clear == 1 ) {
    $ref_config_theme = \%initial_theme;
  }
  elsif ( exists $new_theme{$theme} ) {
    $ref_config_theme = $new_theme{$theme};
  }
  else {
    my $theme_file = "$themes_directory/$theme.ini";
    if ( !-e $theme_file ) {
      carp("$theme not found\n");
      return;
    }

    read_config $theme_file => my %config;
    $new_theme{$theme} = \%config;
    $ref_config_theme = $new_theme{$theme};
  }
  if ( not defined $ref_config_theme ) { return; }

  # Get Default configuration
  if ( ( !%initial_theme ) or ( not defined $clear or $clear != 1 ) ) {
    $this->_default_config( $widget, $ref_config_theme );
  }

  # Get Class an type of widget to design it
  my ( $class, $type ) = split m/::/msx, ref $widget;

  # For MainWindows widget, ref($widget) = MainWindow, then $type = $class
  # Else for Tk::Widget, ref($widget) = Tk::Toplevel or Tk::Frame, etc => $type ok
  $type = defined $type ? $type : $class;
  if ( not defined $type ) { return; }

  # Read configuration option
  if ( my $design_type = $ref_config_theme->{$type} ) {

    # Set configuration
    $widget->configure( %{$design_type} );
  }

  # children widgets design setting
  foreach my $child_level1 ( $widget->children ) {
    if ( defined $clear and $clear == 1 ) {
      $this->design_widget( -widget => $child_level1, -clear => 1 );
    }
    else {
      $this->design_widget( -widget => $child_level1, -theme => $theme );
    }
  }

  $current_theme = $theme;
  return;
}

1;
__END__

=head1 NAME

Tk::Dressing - Set a theme (dressing) in your widget and its children.

=head1 SYNOPSIS

  #!/usr/bin/perl
  use warnings;
  use strict;
  use Tk;
  use Tk::Dressing;
  
  use Tk::BrowseEntry;
  
  my $tk_dressing = Tk::Dressing->new();
  
  my $mw = MainWindow->new( -title => "Dressing widget", );
  $mw->minsize( 300, 100 );
  
  $mw->Button( -text => 'Close', )->pack(qw/ -side bottom -padx 10 -pady 10 /);
  
  my $browse_entry_theme = $mw->BrowseEntry(
    -label   => "Select a theme : ",
    -state   => 'readonly',
    -choices => [ 'clear dressing', sort $tk_dressing->get_all_theme ],
  )->pack;
  
  my $message = "Hello everybody\n\nWelcome to Perl/Tk and Tk::Dressing\n\n";
  $mw->Label( -text => $message,     -anchor => 'center' )->pack(qw/ -side top -padx 10 -pady 10 /);
  $mw->Label( -text => 'Example : ', -anchor => 'center' )->pack(qw/ -side left -padx 10 -pady 10 /);
  $mw->Entry( -text => 'test', )->pack(qw/ -side left -padx 10 -pady 10 /);
  
  $browse_entry_theme->configure(
    -browse2cmd => sub {
      my $theme = $browse_entry_theme->Subwidget('entry')->get;
      if ( $theme eq 'clear dressing' ) { $tk_dressing->clear($mw); return; }
      $tk_dressing->design_widget(
        -widget => $mw,
        -theme  => $theme,
      );
    },
  );
  
  MainLoop();


=head1 DESCRIPTION

Tk::Dressing allows you to set a theme (dressing) in your widget and its children by using one of different default 
themes or by loading a new theme. A theme contains all options that you want to use to configure the Tk widgets 
(color of buttons, of Entry, ...). 

Everybody can participate to increase the themes of this module by proposing a theme that 
will be store in the module because each theme is stored in an ini file.

=head1 CONSTRUCTOR/METHODS

=head2 new

This constructor allows you to create a new Tk::Dressing object.

B<$tk_dressing = Tk::Dressing-E<gt>new()>

The new() method is the main constructor for the Tk::Dressing module.

  # Create Tk::Dressing constructor
  my $tk_dressing = Tk::Dressing->new();


=head2 clear

This method allow you to replace your last theme set by the default look and feel of your widget.

B<$tk_dressing-E<gt>clear( $widget )>

  $tk_dressing->clear($mw);


=head2 design_widget

Set the theme (dressing) on your widget and its children.

B<$tk_dressing-E<gt>design_widget( -widget =E<gt> $widget, -theme =E<gt> $theme_name )>

=over 4

=item B<-widget> =E<gt> I<$widget>

Specifies the widget. The widget can be a Toplevel, Frame, Button, ...

  -widget => $mw,

=back

=over 4

=item B<-theme> =E<gt> I<string>

Specifies the theme name between defaults themes of module. If you have loaded a theme before, you can choose it.

    -theme => 'starwars',

Default : B<djibel>

=back

  $tk_dressing->design_widget(
   -widget => $mw,
   -theme  => 'djibel',
  );

=head2 get_all_theme

Get all the available themes and loaded in your widget.

  my @all_themes = $tk_dressing->get_all_theme;


=head2 get_current_theme

Get the theme in used in your widget.

  my $current_theme = $tk_dressing->get_current_theme;


=head2 get_default_theme_file

Get an .ini file of one of default themes of module.

B<$file> = B<$tk_dressing-E<gt>get_default_theme_file(I<$theme>, I<$directory>)>

  my $file = $tk_dressing->get_default_theme_file('djibel', '/home/user');
  # $file will be contain /home/user/djibel.ini and this file will be create.


=head2 load_theme_file

Loads your own theme file to design your widget.

  # Load your file
  $tk_dressing->load_theme_file($theme, $theme_file);
  # Set it to e frame widget
  $tk_dressing->design_widget(
   -widget => $frame,
   -theme  => $theme,
  );


Your file must be an .ini file and must contain sections. 
Each section correspond to a widget, that is an example.

  [BrowseEntry]
  -background: #697E6D
  -foreground: white
  -disabledbackground: #697E6D
  -disabledforeground: white
  
  [Button]
  -activebackground: #7F80C0
  -background: #7F80C0
  -foreground: white
  -disabledforeground: white
  -activeforeground: white
  
  [Canvas]
  -background: #697E6D
  
  [Checkbutton]
  -highlightbackground: #68676C
  -activebackground: #68676C
  -background: #68676C
  -foreground: white
  -disabledforeground: white
  -activeforeground: white
  -selectcolor: #697E6D
  
  [ColoredButton]
  -highlightbackground: #68676C
  -background: #68676C
  -autofit: 1
  
  [DirTree]
  -highlightbackground: #68676C
  -background: #697E6D
  -foreground: white
  -highlightcolor: #68676C
  -selectforeground: white
  -selectbackground: #68676C
  
  [Entry]
  -highlightbackground: #68676C
  -background: #697E6D
  -disabledbackground: #697E6D
  -foreground: white
  -readonlybackground: #697E6D
  -disabledforeground: white
  -insertbackground: white

=head1 How to participate to module to increase number of default themes ?

The first aim of Tk::Dressing is to allow user to choose between the proposed theme. But it is important 
for Tk::Dressing to propose a lot of default themes then, your help is welcome. 

Send me a .ini file and the name of your theme by email or through the web 
interface at : L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Dressing>. 
I will add it in the module in a new release. It will be notified in Change file.

=head1 EXAMPLE

See the demo directory in the distribution to execute an example program using Tk::Dressing.

=head1 SEE ALSO

See L<Tk::CmdLine/NAME> and L<Tk::Preferences/NAME>.

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tk-dressing at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Dressing>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::Dressing

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-Dressing>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-Dressing>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-Dressing>

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-Dressing/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Djibril Ousmanou.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

