package Tk::Browser;  

my $RCSRevKey = '$Revision: 1.1.1.1 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION='0.82';

@ISA = qw( Tk::Widget );

use base qw(Tk::Widget);
use vars qw( @ISA $VERSION );
require Carp;
use Tk qw(Ev);
use Tk::widgets qw (DialogBox Dialog FileSelect CmdLine);
use POSIX qw( tmpnam );
use Pod::Text;
use Browser::LibModule;
Construct Tk::Widget 'Tk::Browser';

#
# Defaults
#
my $menufont="*-helvetica-medium-r-*-*-12-*";
my $errordialogfont="*-helvetica-medium-r-*-*-14-*";
my $defaulttextfont="*-courier-medium-r-*-*-12-*";
my $bgcolor = 'white';

Tk::CmdLine::SetResources ('*font: ' . $menufont);
Tk::CmdLine::SetResources ('*Text*font: ' . $defaulttextfont); 
Tk::CmdLine::SetResources ('*Listbox*background: ' . $bgcolor); 
Tk::CmdLine::SetResources ('*Text*background: ' . $bgcolor); 

#
#  User defaults in ~/.Xresources, ~/.Xdefaults, or ~/Browser
#
Tk::CmdLine::SetArguments(-class => Browser);
Tk::CmdLine::LoadResources(-file => "$ENV{HOME}/.Xdefaults");
Tk::CmdLine::LoadResources(-file => "$ENV{HOME}/.Xresources");
Tk::CmdLine::LoadResources ();

sub new {
    my $proto = shift;
    my $class = ref( $proto ) || $proto;
    no warnings;
    my $self = {
	window => undef,
	filelist => undef, 
	symbollist => undef,
	listframe => undef,
	moduleframe => undef,
	symbolframe => undef,
	editor => undef,
	directories => [],
	# menubar menus
	menubar => undef,
	filemenu => undef,
	editmenu => undef,
	modulemenu => undef,	
	viewmenu => undef,
	symbolmenu => undef,
	helpmenu => undef,
	# Popup menus one for each panel.
	modulepopupmenu => undef,
	# this is derived from the text popup menu
	textpopupmenu => undef,
	symbolpopupmenu => undef,
	# parameters for current list search
	searchtext => undef,
	# index into filelist
	modulematched => undef,
	# index into symbollist
	symbolmatched => undef,
	# index of previous match in text.  necessary because
	# Tk::Text::FindNet wraps to the beginning of the 
	#file, instead of halting at the end.
	textmatched => undef,
	list_matched => undef,
	# radiobuttons 
	searchv => undef,
	symbolrefs => undef,
	# search options... 
	searchopts => (),
	#UNIVERSAL superclass
	defaultclass => undef,
	# Package selected in file list.  
	# App shouldn't have multiple selections unless they
        # can be constrained to separate listboxes...
	selectedpackage => undef,
	modview => undef,
	symbolview => undef,
    };
    use warnings;
    $self -> {defaultclass} = new Browser::LibModule;
    bless( $self, $class );
    return $self;
}

sub open {
    my $b = shift;
    my $w = $b -> window(new MainWindow);
    $b -> listframe($w -> Frame(-container => '0'));
    $b -> moduleframe(($b -> listframe) -> Frame(-container => '0'));
    $b -> symbolframe(($b -> listframe) -> Frame(-container => '0'));
    $b -> {filelist} = ($b -> moduleframe) -> Scrolled( 'Listbox', 
			-width => 35, -selectmode => 'single',
                        -scrollbars => 'se' );
    $b -> {symbollist} = ($b -> symbolframe) -> Scrolled( 'Listbox', 
                          -width => 35,	-selectmode => 'single',
                          -scrollbars => 'se' );
    $b -> {editor} = $w -> Scrolled( 'Text', -width => 80,
		     -exportselection => '1', -scrollbars => 'se' );
    my $f = $b -> {filelist};
    my $s = $b -> {symbollist};
    my $e = $b -> {editor};
    foreach ( $f, $s, $e ) {
      $_ -> Subwidget('yscrollbar') -> configure(-width=>10);
      $_ -> Subwidget('xscrollbar') -> configure(-width=>10);
    }
    menus ($b, $w);
    $b -> listframe -> pack( -expand => '1', -fill => 'both');
    $b -> moduleframe -> pack(-side => 'left', -expand => 1, -fill => 'both');
    $b -> symbolframe -> pack(-side => 'left',-expand => '1', -fill => 'both');
    $f -> pack( -anchor => 'w', -expand => 1, -fill => 'both');
    $s -> pack( -anchor => 'w', -expand => '1', -fill => 'both');
    $e -> pack (-expand => 1, -fill => 'both');
    $f -> bind( '<1>', sub{view_event( $f, $b )} );
    $w -> update;
    $b -> watchcursor;

    # parse valid args.
    my (%args) = @_;
    my $def = $b -> defaultclass;
    if ( exists $args{package} ) { 
      my $pkg = $args{package};
      # match on either the file's basename or the "package"
      # name, so we're not dependent on the Perl lib hierarchy
      # here...
      &Tk::Event::DoOneEvent(255);
      $def -> libdirs;
      $def -> module_paths;
      my @allpaths = $def -> modulepathnames;
      my @matched_paths;
      # Unix-specific for the moment
      my $path = $pkg;
      $path =~ s/\:\:/\//;
      @matched_paths = grep /$path/, @allpaths;
      $def -> modinfo($matched_paths[0]);
      $f -> insert( 'end', $b -> defaultclass -> PackageName);
      $b -> selectModule( 0 );
      view_event( $f, $b );
    } elsif ( exists $args{pathname} ) {
      $def -> modinfo($args{pathname});
      $f -> insert( 'end', $b -> defaultclass -> PackageName);
      $b -> selectModule( 0 );
      view_event( $f, $b );
    } else { #invalid or non-existent arguments
      $f -> insert( 'end', 'Reading Library Modules...' );
      $def -> libdirs;
      $def -> module_paths;
      $def -> scanlibs;
      $f -> delete( 0 );
      $f -> insert( 'end', $def -> PackageName);
      foreach ( @{$def -> Children}) {
	$b -> filelist -> insert( 'end', $_ -> PackageName );
      }
      $b -> modulematched( 0 );
      $b -> symbolmatched( 0 );
      $b -> textmatched( '1.0' );
    } 
    $b -> defaultcursor;
}

sub view_event {
  my( $self, $b) = @_;
  my $m = $b -> modview;
  $b -> selectedpackage( $self -> get ( $self -> curselection ) );
  $b -> window -> 
    configure( -title => 
	       "Browser [".$b -> selectedpackage."]" );
  $b -> window -> update;
  $b -> watchcursor;
  if ( $m =~ /source/ ) {
    viewtext( $b );
  }
  if ( $m =~ /doc/ ) {
    viewpod( $b );
  }
  if ( $m =~ /info/ ) {
    viewinfo( $b );
  }
  $b -> defaultcursor;
}

sub viewmain {
  my ($b) = @_;
  exported_key_list( $b, "main\:\:", 1 );
}

sub packagestashes {
  my ($b) = @_;
  my @oldlist;
  my @newlist;
  my $max = $b -> symbollist -> size;
  my $i;
  for( $i = 0; $i < $max; $i++ ) {
    push @oldlist, ($b -> symbollist -> get( $i ) );
  }
  @newlist = grep /\:\: => \{/, @oldlist;
  $b -> symbollist -> delete( 0, $max );
  foreach( @newlist ) { $b -> symbollist -> insert( 'end', $_ ) }
}

sub view_symbols {
  my $b = shift;
  my ($package) = @_;

  $b -> viewmain if ($b -> symbolrefs =~ /mainstash/);

  my $pkg = "main\:\:".$package."\:\:";
  if ( $b -> symbolrefs =~ /packagestash/ ) {
    exported_key_list( $b, $pkg, 1 );
  } elsif ( $b -> symbolrefs =~ /lexical/ ) {
    exported_key_list( $b, $pkg, 0 );
    &lexical_key_list( $b );
  } elsif ( $b -> symbolrefs =~ /xrefs/ ) {
    exported_key_list( $b, $pkg, 0 );
    lexical_key_list( $b );
  }
}

sub viewtext {
  my ($b) = @_;
  my $e = $b -> editor;
  my $lb = $b -> filelist;
  $e -> delete( '1.0', 'end' );
  my @text;
  my $m = new Browser::LibModule;
  if ( ! $b -> selectedpackage ) {
    return;
  }
  $m =  $b -> defaultclass -> retrieve_module( $b -> selectedpackage );
  $b -> view_symbols( $m -> PackageName );
  @text = $m -> readfile ( $m -> PathName );
  foreach ( @text ) { $e -> insert( 'end', $_ ) }
}

sub viewpod {
  my ($b) = @_;
  my $e = $b -> editor;
  my $lb = $b -> filelist;
  $e -> delete( '1.0', 'end' );
  my $m = new Browser::LibModule;
  if ( ! $b -> selectedpackage ) {
    return;
  }
  $m = $b -> defaultclass -> retrieve_module( $b -> selectedpackage );
  $b -> view_symbols( $m -> PackageName );
  my @text = podtext( $m );
  foreach( @text ) { $e -> insert( 'end', $_ ) }
}

sub viewinfo {
  my ($b) = @_;
  my $e = $b -> editor;
  my $lb = $b -> filelist;
  if ( ! $b -> selectedpackage ) {
    return;
  }
  my $m = new Browser::LibModule;
  $m = $b -> defaultclass -> retrieve_module( $b -> selectedpackage );
  $b -> view_symbols( $m -> PackageName );
  $e -> delete( '1.0', 'end' );
  foreach (qw/BaseName PackageName Version PathName SuperClasses/) {
      $e -> insert ('end', "$_\t\t" . $m -> $_ . "\n") if $m -> $_;
  }
}

sub listimports {
  my ($b) = @_;
  my $d = 
    $b -> window -> DialogBox( -title => "Imported Modules from main::",
#			       -buttons => ["View", "Dismiss" ] );
			       -buttons => [qw/Dismiss/] );
  my $imlist = $d -> Scrolled( 'Listbox', -width => 80, -height => 15, 
			       -scrollbars => 'se' ) -> pack;

  while ( my ( $key, $val ) = each %{*{"main\:\:"}} ) {
    if ( $key =~ /\_\</ ) {
      $key =~ s/\_\<//;
      $imlist -> insert( 'end', $key );
    }
  }
  my $resp = $d -> Show;
#  if ( $resp =~ /View/ ) {
#    $b -> view_import( $imlist );
#  }
}

sub view_import {
    my $parent = shift;
    my ($imlist) = @_; 
    if( ! $imlist ) { return; }
    my $bnew = new Tk::Browser;
    $bnew -> defaultclass 
	-> modinfo ($imlist -> get ($imlist -> curselection));
    $bnew -> open( package => $bnew -> defaultclass -> PackageName);
}

sub podtext {
  my ($m) = @_;
  my $modulepathname = $m -> PathName;
  my $help_text;
  my $helpwindow;
  my $textwidget;
  my $tmpfilename = "/tmp/$$.tmp";
  $help_text = 
    "Unable to process help text for $modulepathname."; 
  `pod2text $modulepathname $tmpfilename`;
  @help_text = $m -> readfile( $tmpfilename );
  unlink( $tmpfilename );
  return @help_text;
}

sub lexical_key_list {
  my ($b) = @_;
  my $kl = $b -> symbollist;
  my $fl = $b -> filelist;
  my $n = $fl -> get( $fl -> curselection );
  $kl -> delete( 0, $kl -> index( 'end' ) );
  if( $n eq '' ) { return; }
  my $m = new Browser::LibModule;
  my $contents;
  my @crossrefs;
  my $nrefs;
  $m = $b -> defaultclass -> retrieve_module( $n );
  foreach ( @{$m -> Symbols} ) {
    $contents = $_->{name};
    $contents =~ s/^.*:://;
    next if( $contents eq '' );
    &Tk::Event::DoOneEvent(255);
    if( $b -> symbolrefs =~ /xrefs/ ) {
      @crossrefs = $m -> ModuleInfo -> xrefs( $contents );
      if( ( $nrefs = @crossrefs ) > 0) {
	  $contents .= " <-- ";
	  foreach( @crossrefs ) {
	    $contents .= "$_, ";
	  }
       }
      $contents =~ s/, //;
    }
    $kl -> insert( 'end', $contents );
  }
}

# Call with browser object, name of stash, flag to display 
# results in list window. 
sub exported_key_list {
  my ($b, $stash, $list ) = @_;
  my $kl = $b -> symbollist;
  my $fl = $b -> filelist;
  return unless  $fl -> curselection;
  my $n = $fl -> get( ($fl -> curselection)[0] );
  if( $list ) {
    $kl -> delete( 0, $kl -> index( 'end') )
  }
  my $m = new Browser::LibModule;
  if ( $n ) { 
    $m = $b -> defaultclass -> retrieve_module( $n );
    modImport( $m -> PackageName );
  }
  $m -> exportedkeys( $stash );
  my $contents;
  $m -> ModuleInfo -> xrefcache(()) if $b -> symbolrefs =~ /xrefs/;
  foreach my $s ( @{$m -> {symbols}} ) {
    if( $list ) {
      # Makes the scrollbar update weirdly.
      &Tk::Event::DoOneEvent(255);
    }
    $contents = '';
    # Lvalue globbing dereferencing is from
    # Devel::Symdump.pm and dumpvar.pl
    local (*v) = $s -> {name};
    ### "Use of uninitialized value in pattern match..." warning.
no warnings;
    if ( defined *v{ARRAY} ) { 
use warnings;
      $contents = '( ';
      foreach ( @{*v{ARRAY}} ) {
	$contents .= "$_ ";
      }
      $contents .= ' )';
      if( $list ) {
	$kl -> insert( 'end', $s -> {name}." => $contents" );
      }
    } elsif ( defined *v{CODE} ) { 
      if( $list ) {
	$kl -> insert( 'end', $s -> {name}." => sub" );
      }
    } elsif ( defined *v{HASH} && $key !~ /::/) { 
      $contents = '{ ';
      while ( my ($key_h, $val_h ) = each %{*v{HASH}} ) {
	$contents .= "$key_h => $val_h ";
      }
      $contents .= ' }';
      if( $list ) {
	$kl -> insert( 'end', $s -> {name}." => $contents" );
      }
    } elsif ( defined *v{IO} ) {
      $contents = '<'.$key.'>' if $key;
      if( $list ) {
	$kl -> insert( 'end', $s -> {name}." => $contents" );
      }
    } elsif ( defined ${*v{SCALAR}} ) {
      # If it's uninitialized don't list it.
      $contents = "\'${*v{SCALAR}}\'";
      if( $list ) {
	$kl -> insert( 'end', $s -> {name}." => $contents" );
      }
    }
  }
  return @{$m -> Symbols};
}

sub modImport {
  my ($pkg) = @_;
  eval "package $pkg";
  eval "use $pkg";
  eval "require $pkg";
}

sub menus {
  my ($b, $w) = @_;
  my $items;

  $b -> {menubar} = $w -> Menu ( -type => 'menubar' );

  $b -> {filemenu}   = $b -> {menubar} -> Menu;
  $b -> {editmenu}   = $b -> {menubar} -> Menu;
  $b -> {modulemenu} = $b -> {menubar} -> Menu;
  $b -> {viewmenu}   = $b -> {menubar} -> Menu;
  $b -> {symbolmenu} = $b -> {menubar} -> Menu;
  $b -> {helpmenu}   = $b -> {menubar} -> Menu;

  $b -> menubar -> add ('cascade', -label => 'File', 
			-menu => $b -> {filemenu} );
  $b -> menubar ->add ('cascade', -label => 'Edit',
		       -menu => $b -> {editmenu} );
  $b -> menubar -> add ('cascade', -label => 'View',
			-menu => $b -> {viewmenu} );
  $b -> menubar ->add ('cascade', -label => 'Library',
		       -menu => $b -> {modulemenu} );
  $b -> menubar -> add ('cascade', -label => 'Package',
			-menu => $b -> {symbolmenu} );
  $b -> menubar -> add ('separator');
  $b -> menubar -> add ('cascade', -label => 'Help',
			-menu => $b -> {helpmenu} );
  $b -> menubar -> pack( -anchor => 'w', -fill => 'x' );
  $b -> filemenu -> add( 'command', -label => 'Open Selected Module',
			 -command => sub{ openSelectedModule( $b ) } );
  $b -> filemenu -> add( 'command', -label => 'Save Info...',
			 -command => sub{ saveInfo( $b ) } );
  $b -> filemenu -> add ('separator');
  $b -> filemenu -> add( 'command', -label => 'Exit',
			 -command => sub{ $b->window->WmDeleteWindow});
  $b -> editmenu -> add( 'command', -label => 'Copy',
			 -command => sub{$b->editor->clipboardCopy});
  $b -> editmenu -> add( 'command', -label => 'Cut',
			 -command => sub{$b->editor->clipboardCut});
  $b -> editmenu -> add( 'command', -label => 'Paste',
			 -command => sub{$b->editor->clipboardPaste});
  $b -> modulemenu -> add ( 'command', -label => 'Read Again',
			    -state => 'normal',
			    -command => sub{mod_reload($b)});
  $b -> modulemenu -> add ( 'command', -label => 'List Imported',
			    -state => 'normal',
			    -command => sub{listimports($b)});
  $b -> viewmenu -> add( 'radiobutton', -label => 'Source',
			 -variable => \$b -> {modview},
			 -value => 'source');
  $b -> viewmenu -> add( 'radiobutton', -label => 'POD Documentation',
			 -variable => \$b -> {modview},
			 -value => 'doc');
  $b -> viewmenu -> add( 'radiobutton', -label => 'Module Info',
			 -variable => \$b -> {modview},
			 -value => 'info');
  $b -> viewmenu -> invoke( 1 );
  $b -> viewmenu -> add ('separator');
#  $b -> viewmenu -> add( 'command', -label => '*main:: Stash',
#			 -state => 'normal',
#			 -command => sub{viewmain($b)} );
  $b -> viewmenu -> add( 'command', -label => 'Package Stashes',
			 -state => 'normal',
			 -command => sub{packagestashes($b)} );
  $b -> symbolmenu -> add( 'radiobutton', -label => '*main:: Stash',
			 -variable => \$b -> {symbolrefs},
			 -value => 'mainstash');
  $b -> symbolmenu -> add( 'radiobutton', -label => 'Symbol Table Imports',
			 -variable => \$b -> {symbolrefs},
			 -value => 'packagestash');
  $b -> symbolmenu -> add( 'radiobutton', -label => 'Lexical',
			 -variable => \$b -> {symbolrefs},
			 -value => 'lexical');
  $b -> symbolmenu -> add( 'radiobutton', -label => 'Cross References',
			 -variable => \$b -> {symbolrefs},
			 -value => 'xrefs');
  $b -> symbolmenu -> invoke( 1 );
  $b -> helpmenu -> add ( 'command', -label => 'About...',
			  -state => 'normal',
			  -command => sub{about($b)});
  $b -> helpmenu -> add ( 'command', -label => 'Help...',
			  -state => 'normal',
			  -accelerator => "F1",
			  -command => sub{$b -> self_help(__FILE__)});

  $b -> window -> SUPER::bind('<F1>', 
			      sub{$b -> self_help( __FILE__)});

  $b->modulepopupmenu($b->filelist->Menu(-type=>'normal',-tearoff => ''));
  $b->textpopupmenu($b->editor->Menu(-type=>'normal',-tearoff => ''));
  $b->symbolpopupmenu($b->symbollist->Menu(-type=>'normal',-tearoff => '' ));

  $b -> filelist -> bind( '<ButtonPress-3>',[\&postpopupmenu, 
			     $b -> modulepopupmenu,Ev('X'), Ev('Y') ] );
  $b -> symbollist -> bind( '<ButtonPress-3>',[\&postpopupmenu, 
			       $b -> symbolpopupmenu,Ev('X'), Ev('Y') ] );
  $b -> window -> bind('Tk::Text', '<3>','' );
  $b -> editor -> bind( '<ButtonPress-3>',[\&postpopupmenu, 
			   $b -> textpopupmenu,Ev('X'), Ev('Y') ] );
  $b -> modulepopupmenu -> add( 'command', -label => 'Find...',
				-command => [\&findModule, $b ]);
  $b -> modulepopupmenu -> add( 'command', -label => 'Selected Module',
				-command => [\&openSelectedModule, $b ]);
  $b -> symbolpopupmenu -> add( 'command', -label => 'Find...',
				-command => [\&findSymbol, $b]);
  $b -> textpopupmenu -> add( 'command', -label => 'Find...',
			      -command => [\&findText, $b]);
}

sub postpopupmenu {
  my $c = shift;
  my $m = shift;
  my $x = shift;
  my $y = shift;
  $m -> Post( $x, $y );
}

sub findModule {
  my ($b) = @_;
  return unless $b -> searchdialog;
  my $max = $b -> filelist -> size;
  my $n = findfileliststring( $b, $b -> filelist );
  if ( $n ) {
    $b -> selectModule( $n );
    view_event( $b -> filelist, $b );
  } else {
    searchNotFound( $b );
    $b -> modulematched( 0 );
  }
}

sub openSelectedModule {
  my ($b) = @_;
  my $fl = $b -> {filelist};
  my $n = $fl -> get( $fl -> curselection );
  if( ! $n ) { return; }
  my $module = $b -> defaultclass -> retrieve_module( $n );
  if( !$module) { moduleNotFound($b); return; }
  my $bnew = new Tk::Browser;
  $bnew -> defaultclass ( $module );
  $bnew -> open( pathname => $module -> PathName );
}

sub saveInfo {
  my ($b) = @_;
  my $f = $b -> filelist;
  my $s = $b -> symbollist;
  my $e = $b -> editor;
  my $fn;
  my $i;
  my $max;
  my $d = ($b -> window) -> FileSelect( -directory => '.');
  $d -> configure( -title => 'Save Information to File:' );
  $fn = $d -> Show;
  my $FileErr = 0;
  my ($n, $m);
  CORE::open FILE, ">>$fn" or 
    $FileErr = fileError( $b, "Couldn't open $fn: $!\n" );
  if( ! $FileErr ) {
    $max = $f -> size;
    print FILE "\nModules:\n------------------------\n";
    for( $i = 0; $i < $max; $i++ ) {
      print FILE $f -> get( $i )."\n";
    }
    print FILE "\n\nSelected Module:\n------------------------\n";
    $n = $f -> get( $f -> curselection );
    if( $n ) { 
      $m = $b -> defaultclass -> retrieve_module( $n );
      if( $m ) {
	  foreach (qw/BaseName PackageName Version PathName SuperClasses/) {
	      print FILE "$_\t\t" . $m -> $_ . "\n" if $m -> $_;
	  }
      }
    }
    print FILE "\n\nSymbols:\n------------------------\n";
    $max = $s -> size;
    for( $i = 0; $i < $max; $i++ ) {
      print FILE $s -> get( $i )."\n";
    }
    print FILE "\n\nText:\n------------------------\n\n";
    print FILE $e -> get( '1.0', 'end' );
    close FILE;
  }
}

sub fileError {
  my ($b, $text) = @_;
  my $d = $b -> window -> Dialog( -title => 'File Error',
				  -text => $text,
				  -bitmap => 'info',
				  -buttons => [qw/Ok/] );
  $d -> Show;
  return 1;
}

sub findSymbol {
  my ($b) = @_;
  my $s = $b -> symbollist;
  return unless $b -> searchdialog;
  my $max = $b -> symbollist -> size;
  my $n = findsymbolliststring( $b, $b -> symbollist );
  if ( $n ) {
    $s -> selectionClear( 0, $max );
    $s -> see( $n );
    $s -> selectionSet( $n );
  } else {
    searchNotFound( $b );
  }
  
}

sub findsymbolliststring {
  my ($b, $l) = @_;
  my $m; my $n; my $e;
  my $w = $b -> window;
  my $st = $b -> searchtext;

  $n = $l -> size;
  for ( $m = ( $b -> symbolmatched + 1); $m < $n;  $m++ ) {
    $e = $l -> get( $m) ;
    if ( $e =~ /$st/ ) {
      $b -> symbolmatched( $m );
      return $m;
    }
  }
  $b -> symbolmatched( 0 );
  return 0;
}

sub findText {
  my ($b) = @_;
  my $e = $b -> editor;
  return unless $b -> searchdialog;
  my $findex;
  my $l = length $b -> searchtext;
  if ( ($findex = &find_next( $b) ) != '' ) {
    $e -> tagRemove( 'sel', '1.0', 'end' );
    $b -> textmatched( $findex );
    $e -> markSet( 'insert', $findex );
    $e -> see( $findex );
    $e -> tagAdd( 'sel', 'insert', 
		  ( $e -> index('insert') + "0\.$l" ) ); 
  } else {
    searchNotFound( $b );
    $b -> textmatched( '1.0' );
  }
}

sub find_next {
  my ($b ) = @_;
  $b -> textmatched( ($b -> textmatched) + '0.1' );
  return $b -> editor -> search( '-forward','-exact','-nocase',
				 $b -> searchtext, 
				 $b -> textmatched,
				 'end' );
}

sub searchdialog {
  my $b = shift;
  my $w = $b -> window;
  my $l = $b -> filelist;
  my $d = $w -> DialogBox( -title => 'Find Library Text',
			-buttons => ["Search" , "Cancel" ] );
  my $labl = $d -> add( 'Label', -justify => 'left',
		     -text => 'Enter the text to search for.',
		     ) -> pack( -anchor => 'w', -padx => 5, -pady => 5 );

  my $e = $d -> add( 'Entry' ) -> 
      pack( -expand => '1', -fill => 'both', -padx => 5, -pady => 5);
  $e -> insert (0, $b -> searchtext);
  my $resp = $d -> Show;
  $b -> searchtext( $e -> get );
  if ( ( $b -> searchtext ) && ( $resp =~ /Search/ ) ) {
    return $b -> searchtext;
  } else {
    return undef;
  }
}

sub selectModule {
  my $b = shift;
  my $n = shift;
  my $l = $b -> filelist;
  my $w = $b -> window;
  $l -> selectionClear( 0, $l -> size );
  $l -> see( $n );
  $l -> selectionSet( $n );
  viewtext( $b );
  $b -> selectedpackage( $l -> get ( $l -> curselection ) );
  $w -> configure( -title => "Browser [".$b -> selectedpackage."]" );
}

sub searchNotFound {
  my ($b) = @_;
  my $w = $b -> window;
  $d = $w -> Dialog( -title => 'Not Found', 
		     -text => 'The search text was not found.',
		     -bitmap => 'info' );
  $d -> Show;
}

sub moduleNotFound {
  my ($b) = @_;
  my $w = $b -> window;
  $d = $w -> Dialog( -title => 'Not Found', 
		     -text => 'The module was not found.',
		     -bitmap => 'info' );
  $d -> Show;
}

sub findfileliststring {
  my ($b, $l) = @_;
  my $m; my $n; my $e;
  my $w = $b -> window;
  my $st = $b -> searchtext;

  $n = $l -> size;
  for ( $m = ( $b -> modulematched + 1); $m < $n;  $m++ ) {
    $e = $l -> get( $m) ;
    if ( $e =~ /$st/ ) {
      $b -> modulematched( $m );
      return $m;
    }
  }
  $b -> modulematched( 0 );
  return 0;
}

sub mod_reload {
  my ($b) = @_;
  my $i;
  $b -> {filelist} -> delete( 0, $b -> {filelist} -> index( 'end') );
  $b -> {filelist} -> insert( 'end', 'Reading Library Modules...' );

 Lib:Module -> DESTROY( $b -> {defaultclass} );
  ($b -> {defaultclass}) = Browser::LibModule -> new;
  $b -> watchcursor;
  $b -> {defaultclass} -> scanlibs;
  $b -> {filelist} -> delete( 0 );
  ($b -> {filelist}) -> insert( 'end', $b -> {defaultclass} -> {basename} );
  foreach ( @{$b -> {defaultclass} -> Children}) {
    $b -> {filelist} -> insert( 'end', $_ -> {basename} );
  }
  $b -> defaultcursor;
}

sub about {
  my $self = shift;
  my $aboutdialog;
  my $title_text;
  my $version_text;
  my $line_space;		# blank label as separator.

  $aboutdialog = 
    ($self -> {window}) -> 
      DialogBox( -buttons => ["Ok"],
		 -title => 'About' );
  $title_text = $aboutdialog -> add ('Label');
  $version_text = $aboutdialog -> add ('Label');
  $line_space = $aboutdialog -> add ('Label');

  $title_text -> configure ( -text => 
   "Tk\:\:Browser.pm\n\n" . 
   "Copyright \xa9 2001-2004\nRobert Kiesling, " .
   "rkies\@cpan.org.\n" .
   "Version $VERSION\n" .
   "Licensed using the same terms as Perl.\nRefer to the file, " .
   "\"Artistic,\" for information.");

  $title_text -> pack (-pady => 10);
  $aboutdialog -> Show;
}

# Instance variable methods.  Refer to the perltoot
# man page.

sub window {
  my $self = shift;
  if (@_) { $self -> {window} = shift; }
  return $self -> {window}
}

sub filelist {
  my $self = shift;
  if (@_) { $self -> {filelist} = shift; }
  return $self -> {filelist}
}

sub symbollist {
  my $self = shift;
  if (@_) { $self -> {symbollist} = shift; }
  return $self -> {symbollist}
}

sub symbolrefs {
  my $self = shift;
  if (@_) { $self -> {symbolrefs} = shift; }
  return $self -> {symbolrefs}
}

sub listframe {
  my $self = shift;
  if (@_) { $self -> {listframe} = shift; }
  return $self -> {listframe}
}

sub moduleframe {
  my $self = shift;
  if (@_) { $self -> {moduleframe} = shift; }
  return $self -> {moduleframe}
}

sub symbolframe {
  my $self = shift;
  if (@_) { $self -> {symbolframe} = shift; }
  return $self -> {symbolframe}
}

sub modulepopupmenu {
  my $self = shift;
  if (@_) { $self -> {modulepopupmenu} = shift; }
  return $self -> {modulepopupmenu}
}

sub textpopupmenu {
  my $self = shift;
  if (@_) { $self -> {textpopupmenu} = shift; }
  return $self -> {textpopupmenu}
}

sub symbolpopupmenu {
  my $self = shift;
  if (@_) { $self -> {symbolpopupmenu} = shift; }
  return $self -> {symbolpopupmenu}
}

sub editor {
  my $self = shift;
  if (@_) { $self -> {editor} = shift; }
  return $self -> {editor}
}

sub directories {
  my $self = shift;
  if (@_) { $self -> {directories} = shift; }
  return $self -> {directories}
}

sub menubar {
  my $self = shift;
  if (@_) { $self -> {menubar} = shift; }
  return $self -> {menubar}
}

sub filemenu {
  my $self = shift;
  if (@_) { $self -> {filemenu} = shift; }
  return $self -> {filemenu}
}

sub editmenu {
  my $self = shift;
  if (@_) { $self -> {editmenu} = shift; }
  return $self -> {editmenu}
}

sub modulemenu {
  my $self = shift;
  if (@_) { $self -> {modulemenu} = shift; }
  return $self -> {modulemenu}
}

sub searchmenu {
  my $self = shift;
  if (@_) { $self -> {searchmenu} = shift; }
  return $self -> {searchmenu}
}

sub viewmenu {
  my $self = shift;
  if (@_) { $self -> {viewmenu} = shift; }
  return $self -> {viewmenu}
}

sub symbolmenu {
  my $self = shift;
  if (@_) { $self -> {symbolmenu} = shift; }
  return $self -> {symbolmenu}
}

sub helpmenu {
  my $self = shift;
  if (@_) { $self -> {helpmenu} = shift; }
  return $self -> {helpmenu}
}

sub textmenu {
  my $self = shift;
  if (@_) { $self -> {textmenu} = shift; }
  return $self -> {textmenu}
}

sub textfilemenu {
  my $self = shift;
  if (@_) { $self -> {textfilemenu} = shift; }
  return $self -> {textfilemenu}
}

sub searchtext {
  my $self = shift;
  if (@_) { $self -> {searchtext} = shift; }
  return $self -> {searchtext}
}

sub modulematched {
  my $self = shift;
  if (@_) { $self -> {modulematched} = shift; }
  return $self -> {modulematched}
}

sub symbolmatched {
  my $self = shift;
  if (@_) { $self -> {symbolmatched} = shift; }
  return $self -> {symbolmatched}
}

sub textmatched {
  my $self = shift;
  if (@_) { $self -> {textmatched} = shift; }
  return $self -> {textmatched}
}

sub list_matched {
  my $self = shift;
  if (@_) { $self -> {list_matched} = shift; }
  return $self -> {list_matched}
}

sub searchv {
  my $self = shift;
  if (@_) { $self -> {searchv} = shift; }
  return $self -> {searchv}
}

sub defaultclass {
  my $self = shift;
  if (@_) { $self -> {defaultclass} = shift; }
  return $self -> {defaultclass}
}

sub modview {
  my $self = shift;
  if (@_) { $self -> {modview} = shift; }
  return $self -> {modview}
}

sub symbolview {
  my $self = shift;
  if (@_) { $self -> {symbolview} = shift; }
  return $self -> {symbolview}
}

sub selectedpackage {
  my $self = shift;
  if (@_) { $self -> {selectedpackage} = shift; }
  return $self -> {selectedpackage}
}

# for each subwidget
sub watchcursor {
  my $app = shift;
  $app -> window -> Busy( -recurse => '1' );
}

sub defaultcursor {
  my $app = shift;
  $app -> window -> Unbusy( -recurse => '1' );
}

sub self_help {
    my $self = shift;
    my ($appfilename) = @_;
    my $help_text;
    my $helpwindow;
    my $textwidget;

    eval {
	CORE::open HELP, "pod2text < $appfilename |" or $help_text = 
	    "Unable to process help text for $appfilename."; 
	  while (<HELP>) { $help_text .= $_; }
	  close( HELP );
      };

    $helpwindow = $self -> window -> DialogBox (-title => 'Browser.pm(3)',
	-buttons => [qw/Dismiss/]);

    $textwidget = $helpwindow 
      -> Scrolled( 'Text', -scrollbars => 'e', -height => 25, 
		   -width => 80) 
      -> pack( -fill => 'both', -expand => 1 );

    $textwidget -> insert( 'end', $help_text );

    $helpwindow -> Show;

}

1;

__END__

=head1 NAME

Tk::Browser.pm -- Perl library browser.

=head1 SYNOPSIS

# Open from a shell prompt:

  # mkbrowser <module_pathname>  # Open a library file by name
  # mkbrowser <package_name>     # Open package(s) matching 
                                 # <package_name> (Unix specific);
  # mkbrowser                    # Browse the entire library.

# Open from a Perl script:

  use Tk::Browser;
  use Lib::Module;

  # Construct Browser object:
  $b = new Browser;   

  # Browse entire library:
  $b -> open();       

  # Browse a package by name:
  $b -> open(package => IO::File);   

  # Browse a package by module path name:
  $b -> open(pathname =>"/usr/local/lib/perl5/5.6.0/open.pm");

=head1 DESCRIPTION

Tk::Browser.pm creates a Perl library module browser.  The browser
window contains a module listing at the upper left, a symbol listing
at the upper right, and a text display.

If the argument to open() is a package or path name, the
browser displays that package.  The default is to list the first
instance of each .pm and .pl file in the Perl library's @INC array of
directories.

Clicking the left mouse button on a package name in the upper
left-hand pane displays the package's information as described in 
the sections, L<Package List>, L<Reference List>, and L<Text Display>.

The right mouse button pops up a menu that provides options to search
for text in the frame, and, in the package list, an option to open
a new browser window on a selected package.

=head2 Package List

The package list in the upper left hand frame displays the name of a
package if its package name or file pathname is given as an argument.
Without arguments, the package list displays all of the packages in
the Perl interpreter's @INC path array.

=head2 Reference List

The reference list in the upper right hand frame displays the contents
of the main:: stash, the module's symbol table hash, the symbols
produced by a lexical scan, or a cross reference listing, depending on
the setting of options in the, "Package," menu.

=head2 Text Display

The text frame displays the module's source code, POD documentation,
or class and version information depending on the settings of the,
"View," menu.


If the default Perl configuration includes '.' in the @INC path array,
the browser also displays modules in the current directory and its
subdirectories.

The section L<MENU FUNCTIONS> describes the menu bar functions.

If the entire library is scanned, the listing starts with the default
class, UNIVERSAL.  Selecting the main:: Symbol Table display from the
View menu displays all of the symbols in the default stash, including
those of the the Browser itself.  In this stash also are the path
names of library modules that are imported at run time.

The Modules ==> List Imports menu option opens a window that lists all
symbol table imports.

The open() method's B<package> option browses the first package which
has a matching name, after locating it in the Perl library's @INC
directories.  The B<pathname> argument specifies the path name of a
single Perl module to browse.  For example:

  . . .

  my $b = new Tk::Browser;

  if( -e $ARGV[0] ) { # Package file name.
    $b -> open(pathname => $ARGV[0]);
  } elsif( $ARGV[0] ) { # Module name
    $b -> open(package => $ARGV[0]);
  } else {  # No argument: scan everything.
    $b -> open;
  }

  . . .

  MainLoop;

=head1 MENU FUNCTIONS

=head2 File Menu

=head3 Open Selected Module

Open a new browser for the module selected in the module list window.

=head3 Save Info... 

Open a FileBrowser and prompt for a file name.  Save the information
in each of the browser windows to the text file.

=head3 Exit 

Exit the browser and close the window.

=head2 Edit Menu

=head3 Cut

Move selected text from the editor pane to the X clipboard.

=head3 Copy 

Copy selected text from the editor pane to the X clipboard.

=head3 Paste 

Insert text from the X clipboard at the text editor pane's insertion
point.

=head2 View Menu

=head3 Source 

View module source code of selected module.

=head3 POD Documentation 

Format and view the selected module's POD documentation, if any.

=head3 Module Info 

List the selected module's package name, module filename, version, and
superclasses.

=head3 Package Stashes 

Filter current symbol list to show only secondary stashes and their
symbols.

=head2 Library Menu

=head3 Read Again 

Re-scan the Perl library directories and files.

=head3 View Imported 

List files in the main:: stash that were imported by Perl.

=head2 Packages Menu

=head3 main:: Stash 

View the symbols in the main:: symbol table hash.

=head3 Symbol Table Imports 

View symbols that are in the module's symbol table hash.

=head3 Lexical 

View symbols parsed from the module's source code.

=head3 Cross References 

For non-local stash symbols, check for cross references in other
modules that have been loaded by the interpreter.  Warning: Cross
referencing can take a considerable amount of time.

=head2 Help Menu

=head3 About 

Display the version number and authorship of the Browser library.

=head3 Help 

View the Browser's POD documentation.

=head2 Popup Menus

=head3 Find 

Search for text in that pane where the menu is popped up by pressing
the right mouse button.

=head3 Open Module 

In the module list window, query for the module name on which to open
a new browser.

=head1 X RESOURCES

X resources in ~/Browser, ~/.Xdefaults, or ~/Xresources override some
of the user interface defaults.  The file, "Browser.ad," contains
sample resource definitions.

  Browser*font: *-courier-medium-r-*-*-14-*
  Browser*geometry: 650x650
  Browser*Dialog*font: *-helvetica-medium-r-*-*-12-*
  Browser*TextUndo*font: *-courier-medium-r-*-*-12-*
  Browser*Text*background: white
  Browser*Listbox*font: *-courier-medium-r-*-*-12-*
  Browser*Menu*font: *-helvetica-medium-r-*-*-12-*
  Browser*Menu*background: lightblue
  Browser*Button*font: *-helvetica-medium-r-*-*-12-*

Refer to the Tk::CmdLine(3) manual page.  

=head1 COPYRIGHT

Copyright © 2001-2004 Robert Kiesling, rkies@cpan.org.

Licensed using the same terms as Perl.  Refer to the file,
"Artistic," for information.

=head1 VERSION

$Id: Browser.pm,v 1.1.1.1 2015/04/18 18:43:42 rkiesling Exp $

=head1 SEE ALSO

mkbrowser(1), Lib::Module(3), Tk(3), perl(1), perlmod(1),
perlmodlib(1), perlreftut(1), and perlref(1)

=cut

__DATA__

