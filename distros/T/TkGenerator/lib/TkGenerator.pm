#!/usr/bin/perl
package TkGenerator; 
use Tk;

require Exporter; 


our @ISA = qw (Exporter); 
our @EXPORT = qw (generate $genwin);
our @EXPORT_OK = (@EXPORT); 
our $VERSION = "00.1a";

sub generate
	{ 
	my $optcnt1 = 0; $optcnt2 = 0; $optcnt3 = 0; $maincount=1; 
	$genwin = new MainWindow(-title=>'Tk Code Generator');
	$genwin -> maxsize (0, 390);
	$genwin -> minsize (0, 390);
	$t = $genwin -> Table (-rows=>40, -columns=>2) -> pack (-fill=>'x');
 	my $samplabel = $t -> Label (-text=>'Label');
	$t -> put (0,1, $samplabel);
	my $genlabel = $t -> Button (-text=>'Generate', -command=>sub { generate2 ("Label"); } ); 
	$t -> put (0, 2, $genlabel);
	my $sampbutton = $t -> Button (-text=>'Button', -state=>'disabled'); 
	my $genbutton=$t-> Button (-text=>'Generate', -command=>sub { generate2 ("Button"); } ); 
	my $samptlabel = $t -> Label (-text=>'Table');
	$t-> put (1, 1, $sampbutton); 
	$t-> put (1, 2, $genbutton); 
	$t->put (2, 1, $samptlabel);
	my $samptable = $t -> Table (-rows=>1, -columns=>2, -scrollbars=>0);
	$t -> put (3, 1, $samptable);
	my $samptlabel2 = $samptable -> Label (-text=>"Sample Cell 1"); 
	my $samptlabel3 = $samptable -> Label (-text=>"Sample Cell 2");
	$samptable -> put (0, 1, $samptlabel2);
	$samptable -> put (0, 2, $samptlabel3);
	my $gentable = $t -> Button (-text=>'Generate', -command=>sub { generate2 ("Table"); } );
	$t -> put (3, 2, $gentable);
	my $sampcanvaslabel = $t -> Label (-text=>'Canvas');
	my $sampcanvas = $t -> Canvas (-width=>4, -height=>2); 
	my $gencanvas = $t -> Button (-text=>'Generate', -command=>sub { generate2 ("Canvas"); } );
	$t -> put (4, 1, $sampcanvaslabel); 
	$t -> put (5, 1, $sampcanvas);
	$t -> put (5, 2, $gencanvas);
	my $sampanimation = $t -> Label (-text=>'Animation');
	my $genanimation = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Animation'); }); 
	$t -> put (6, 1, $sampanimation); 
	$t -> put (6, 2, $genanimation); 
	my $sampbrowseentryl = $t -> Label (-text=>"BrowseEntry"); 
	my $sampbrowseentry = $t -> BrowseEntry ();
	$sampbrowseentry-> insert ('end', "Sample Option"); 
	$sampbrowseentry-> insert ('end', "Sample Option 2"); 
	my $genbrowseentry = $genwin -> Button (-text=>'Generate', -command=>sub { generate2 ('BrowseEntry'); }); 
	$t -> put (7, 1, $sampbrowseentryl); 	
	$t -> put (8, 1, $sampbrowseentry);
	$t -> put (8, 2, $genbrowseentry);
	my $samptixgridl = $t -> Label (-text=>"TixGrid"); 
	my $samptixgrid = $t -> TixGrid (-width=>1, -height=>1); 
	my $gentixgrid = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('TixGrid'); }); 	
	$t -> put (9, 1, $samptixgridl); 
	$t -> put (10, 1, $samptixgrid);
	$t -> put (10, 2, $gentixgrid);
	my $sampdirtreel = $t -> Label (-text=>'DirTree'); 
	my $sampdirtree = $t -> DirTree (-width=>2, -height=>2); 
	my $gendirtree = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('DirTree'); }); 	
	$t -> put (11, 1, $sampdirtreel);
	$t -> put (12, 1, $sampdirtree);
	$t -> put (12, 2, $gendirtree); 
	my $sampdialogbox = $t -> Label (-text=>'DialogBox');
	my $gendialogbox = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('DialogBox'); }); 	
	$t -> put (13, 1, $sampdialogbox);
	$t -> put (13, 2, $gendialogbox);
	my $sampframe = $t -> Label (-text=>"Frame"); 
	my $genframe = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Frame'); });
	$t -> put (14, 1, $sampframe);
	$t -> put (14, 2, $genframe); 
	my $samplabframe = $t -> Label (-text=>"LabFrame"); 
	my $genlabframe = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Frame'); });
	$t -> put (15, 1, $samplabsframe);
	$t -> put (15, 2, $genlabframe);
	my $sampnotebookl = $t -> Label (-text=>"NoteBook"); 
	my $sampnotebook = $t -> NoteBook (-width=>2); 
	my $gennotebook = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('NoteBook'); });
	$sampnotebook -> add ('Sample Tab 1');
	$sampnotebook -> add ('Sample Tab 2');
	$t -> put (16, 1, $sampnotebookl);
	$t -> put (17, 1, $sampnotebook);
	$t -> put (17, 2, $gennotebook); 	
	my $samptlist = $t -> Label (-text=>"TList"); 
	my $gentlist  = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('TList'); });
	$t -> put (18, 1, $samptlist);
	$t -> put (18, 2, $gentlist);
	my $samptree = $t -> Label (-text=>'Tree' );
	my $gentree = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Tree'); }); 
	$t -> put (19,1, $samptree); 
	$t -> put (19, 2, $gentree); 
	my $sampinputo = $t -> Label (-text=>"InputO");
	my $geninputo = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('InputO'); });
	$t -> put (20, 1, $sampinputo);
	$t -> put (20, 2, $geninputo);
	my $sampcheckbutton = $t -> Checkbutton (-text=>"Checkbutton");
	my $gencheckbutton = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Checkbutton'); });
	$t -> put (21, 1, $sampcheckbutton);
	$t -> put (21, 2, $gencheckbutton);
	my $sampentryl = $t -> Label (-text=>"Entry"); 
	my $sampentry = $t -> Entry(); 
	my $genentry = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Entry'); });
	$t -> put (22, 1, $sampentryl); 
	$t -> put (23, 1, $sampentry);
	$t -> put (23, 2, $genentry);
	my $samphlist = $t -> Label (-text=>"HList");
	my $genhlist = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('HList'); });
	$t -> put (24, 1, $samphlist);
	$t -> put (24, 2, $genhlist);
	my $samplistboxl = $t -> Label (-text=>'Listbox'); 
	my $samplistbox = $t -> Listbox (-height=>2); 
	$samplistbox -> insert ('end', 'Sample List Item', 'Sample List Item');
	my $genlistbox = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Listbox'); });
	$t -> put (25, 1, $samplistboxl);
	$t -> put (26, 1, $samplistbox); 
	$t -> put (26, 2, $genlistbox);
	my $sampmenu = $t -> Label (-text=>"Menu");
	my $genmenu = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Menu'); });
	$t -> put (27, 1, $sampmenu);
	$t -> put (27, 2, $genmenu);
	my $sampmessage = $t -> Label (-text=>"Message"); 
	my $genmessage  = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Message'); });
	$t -> put (28, 1, $sampmessage);
	$t -> put (28, 2, $genmessage); 
	my $sampoptionmenu = $t -> Label (-text=>"Optionmenu");
	my $genoptionmenu  = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Optionmenu'); });
	$t -> put (29, 1, $sampoptionmenu);	
	$t -> put (29, 2, $genoptionmenu);
	my $sampradiobutton = $t -> Radiobutton (-text=>"Radiobutton");
	my $genradiobutton = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Radiobutton'); });
	$t -> put (30, 1, $sampradiobutton);
	$t -> put (30, 2, $genradiobutton); 
	my $sampscale = $t -> Label (-text=>'Scale'); 
	my $genscale = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Scale'); });
	$t -> put (31, 1, $sampscale); 
	$t -> put (31, 2, $genscale); 
	my $samptextl = $t -> Label (-text=>"Text");
	my $samptext = $t -> Text (-height=>4); 
	my $gentext = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Text'); });
	$t -> put (32, 1, $samptextl);
	$t -> put (33, 1, $samptext); 
	$t -> put (33, 2, $gentext);
	my $samptoplevel = $t -> Label (-text=>"Toplevel");
	my $gentoplevel = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Toplevel'); });
	$t -> put (34, 1, $samptoplevel); 
	$t -> put (34, 2, $gentoplevel);
	my $sampchoosecolor = $t -> Label (-text=>"chooseColor");
	my $genchoosecolor = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('chooseColor'); });\	
	$t -> put (35, 1, $sampchoosecolor);
	$t -> put (35, 2, $genchoosecolor); 
	my $sampcoloreditor = $t -> Label (-text=>'ColorEditor');
	my $gencoloreditor = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('ColorEditor'); });
	$t -> put (36, 1, $sampcoloreditor); 
	$t -> put (36, 2, $gencoloreditor);
	my $sampdialog = $t -> Label (-text=>"Dialog");
	my $gendialog  = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('Dialog'); });
	$t -> put (37, 1, $sampdialog);
	$t -> put (37, 2, $gendialog); 
	my $sampfileselect = $t -> Label (-text=>"FileSelect");
	my $genfileselect = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('FileSelect'); });
	$t -> put (38, 1, $sampfileselect);
 	$t -> put (38, 2, $genfileselect);
	my $sampgetopenfile = $t -> Label (-text=>"getOpenFile");
	my $gengetopenfile = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('getOpenFile'); });
	$t -> put (39,1, $sampgetopenfile);	
	$t -> put (39, 2, $gengetopenfile); 
	my $sampmessagebox = $t -> Label (-text=>'messageBox'); 
	my $genmessagebox = $t -> Button (-text=>'Generate', -command=>sub { generate2 ('messageBox'); });
	$t -> put (40, 1, $sampmessagebox);
	$t -> put (40, 2, $genmessagebox);
	MainLoop();
	} 


sub generate2
	{ 
	$type = shift; 
	my $packflag = 0; 
	if ( $genwin2 )
		{ 
		return; 
		} 
	$genwin2 = new MainWindow(-title=>"Tk Code Generator");
	my $topl = $genwin2 -> Label (-text=>"Enter The Scalar Variable for Your MainWindow.\nExample: \$win") -> pack (-fill=>'x');
	$winentry = $genwin2 -> Entry () -> pack (-fill=>'x'); 
	my $veryfirstdiv = $genwin2 -> Label () -> pack (-fill=>'x'); 
	my $firstl = $genwin2 -> Label (-text=>"Options for MainWindow") -> pack (-fill=>'x'); 
	my $firstdiv = $genwin2 -> Label () -> pack (-fill=>'x'); 
	my $scaloptl = $genwin2 -> Label (-text=>'Option')->pack(-fill=>'x'); 
	$scalaroption = $genwin2 -> Entry () -> pack (-fill=>'x') ;
	my $scalvall = $genwin2 -> Label (-text=>'Value')->pack(-fill=>'x'); 
	$scalarvalue = $genwin2 -> Entry () -> pack (-fill=>'x') ;
	my $div = $genwin2 -> Label () -> pack (-fill=>'x');
	my $checkpack = $genwin2 -> Checkbutton (-variable=>\$val, -text=>'Pack Widget?') -> pack(-fill=>'x');
	my $packoptslabel = $genwin2 -> Label (-text=> "Options for the Pack Command for Widget $type") ->pack (-fill=>'x') ;
	my $packtopl = $genwin2 -> Label (-text=>"Option")->pack (-fill=>'x'); 
	$winpackoption = $genwin2 -> Entry () -> pack (-fill=>'x'); 
	my $packtopl2 = $genwin2 -> Label (-text=>"Value") -> pack (-fill=>'x');
	$winpackvalue = $genwin2 -> Entry () -> pack (-fill=>'x'); 
	my $middiv = $genwin2 -> Label () -> pack (-fill=>'x');
	my $top2 = $genwin2 -> Label (-text=>"Add An Option for Widget $type") -> pack (-fill=>'x') ;	
	my $div2 = $genwin2 -> Label () -> pack (-fill=>'x');
	my $topl3 = $genwin2 -> Label (-text=>"Option")->pack (-fill=>'x'); 
	$option = $genwin2 -> Entry () -> pack (-fill=>'x'); 
	my $topl4 = $genwin2 -> Label (-text=>"Value") -> pack (-fill=>'x');
	$value = $genwin2 -> Entry () -> pack (-fill=>'x'); 
	my $div3 = $genwin2 -> Label () -> pack (-fill=>'x');
	my $addbutton = $genwin2 -> Button (-command=>\&add, -text=>'Add') -> pack (-fill=>'x'); 
	$codetext = $genwin2 -> Text (-height=>10) -> pack (-fill=>'both');
	$genwin2 -> OnDestroy (sub { $genwin2 = ''; }) ;
	
	MainLoop(); 


	} 

sub add
	{ 
	my $errordialog = $genwin2 -> Dialog (-title=>'Error', -text=>"Error:\nYou did not supply a scalar for the MainWindow"); 
	if ($winentry -> get() =~ /^\s*$|^$/)
		{ 
		$errordialog->Show(); 
		return; 
		} 
	if ($scalaroption -> get() !~ /^\s*$|^$/ and $scalarvalue -> get() !~ /^\s*$|^$/) 
		{ 
		$scalaropts .= "-" . $scalaroption->get() . "=>" . '"' . $scalarvalue->get() . '"' if $optcnt1 == 0; 
		$scalaropts .= "," . "-" . $scalaroption->get() . "=>" . '"' . $scalarvalue->get() . '"' if $optcnt1 > 0; 
		$optcnt1+=1;
		}
	if ($winpackoption -> get() !~ /^\s*$|^$/ and $winpackvalue -> get() !~ /^\s*$|^$/) 
		{ 
		$packopts .= "-" . $winpackoption->get() . "=>" . '"' . $winpackvalue->get() . '"' if $optcnt2 == 0 and $val; 

		$packopts .= "," . "-" . $winpackoption->get() . "=>" . '"' . $winpackvalue->get() . '"' if $optcnt2 > 0 and $val; 
		$optcnt2+=1 if $val;
		} 
	if ($option -> get() !~ /^\s*$|^$/ and $value -> get() !~ /^\s*$|^$/) 
		{ 
		my $scalval = $value -> get();
		if ($scalval !~ /sub\s*\{.*\}\s*|\\&.*/) 
			{ 
			$scalval = '"' . $scalval . '"';
			} 
		$mainopts .= "-" . $option->get() . "=>" . $scalval if $optcnt3 == 0 ; 
		$mainopts .= "," . "-" . $option->get() . "=>" . $scalval if $optcnt3 > 0; 
		$optcnt3+=1;
		}  
	$firststr = "#Begin TkGenerator Code#\n" . $winentry -> get . " = new MainWindow($scalaropts)\n"; 
	$mainstr = "\$$type$maincount = " . $winentry -> get() . " -> $type ($mainopts);\n" if ! $val; 
	$mainstr = "\$$type$maincount = " . $winentry -> get() . " -> $type ($mainopts) -> pack ($packopts);\n" if $val; 

	

	$laststr = "MainLoop();\n#End TkGenerator Code#"; 
	$finalstr = $firststr . $mainstr . $laststr;
	$maincount+=1; 
	$codetext -> Contents ($finalstr);
	$winpackvalue -> delete (0, 'end');
	$winpackoption -> delete (0, 'end');
	$scalaroption -> delete (0, 'end');
	$scalarvalue -> delete (0, 'end'); 
	$option -> delete (0, 'end');
	$value -> delete (0, 'end');
	} 
1; 

__END__ 
=head1 NAME

TkGenerator - A Tk Code Generator

=head1 SYNOPSIS

  use TkGenerator;
  generate; 

=head1 DESCRIPTION

This module is more a program than a module. It only has one function you can use, "generate". Call it to use a Tk code generator. 

The module also exports the variable for the main generator window, $genwin. 

=head1 SEE ALSO

See also Tk! It rocks. 

=head1 AUTHOR

Robin Bank, webmaster@infusedlight.net
check me out @ www.infusedlight.net

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Robin Bank

I really don't care what you do, but use at your own risk. 

=cut

