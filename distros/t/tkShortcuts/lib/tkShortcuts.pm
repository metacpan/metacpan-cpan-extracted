#!/usr/bin/perl


package tkShortcuts; 
use Tk;
#require Tk;
#require Tk; 

require Exporter; 


our @ISA = qw (Exporter); 
our @EXPORT = qw (superdirchoose superopenfile returntext saveit htmlcolret $VERSION $superdirwin $win_openfile $w $rett_win $as $html_win)  ;
our @EXPORT_OK = (@EXPORT); 

our $VERSION = "1.00a"; 

$as = 0; 
                  
sub superdirchoose
        { 
        $superdirwin = new MainWindow(-title=>'Choose a Directory');
        $superdirwin -> maxsize (300, 380);        
        my $d = $superdirwin -> DirTree () -> pack (-fill=>'x'); 
        my $l_makedir = $superdirwin -> Label (-text=>"CREATE NEW DIRECTORY\nType in a name for your directory.\nSelect a directory for it to be created under.") -> pack (-fill=>'x');
        my $ent_dir = $superdirwin -> Entry () -> pack (-fill=>'x'); 
        my $butt_newdir = $superdirwin -> Button (-text=>'New Directory', -command=>sub { superdirnewdir ($ent_dir-> get(), $d->info ('selection')  ); } ) -> pack (-fill=>'x') ;
        my $ret; 
        my $lplacer = $superdirwin -> Label () -> pack (-fill=>'x' );
        my $retb = $superdirwin -> Button (-text=>'Chooose Selected Directory', -command=>sub { $ret = superdirdone ($d); } ) -> pack (-fill=>'x' );  
        my $butt_cancel = $superdirwin -> Button (-text=>"Cancel", -command=>sub { $superdirwin-> destroy (); $superdirwin = ''; }) -> pack (-fill=>'x') ; 
        MainLoop();
        return $ret;
        } 

sub superopenfile
        { 
        $openw = new MainWindow(-title=>"Open a File");
        $open_dir = $openw -> DirTree (-width=>60) -> pack (-fill=>'x' );
        my $open_changedir = $openw -> Button (-text=>"Change Directory", -command=>\&superopencdir) -> pack (-fill=>'x');
        $open_botl = $openw -> Label (-text=>"Browse for a file");
        $open_list = $openw -> Listbox ();
        my @j;
        $open_sel = $openw -> Button (-text=>"Select File", -command=>sub { @j = superopenfinal (); $openw -> destroy(); } );        
        MainLoop();
        return @j ;
        } 


sub saveit
	{	
	@contents_file = @_;
	$file = $contents_file[0];
	@contents = @contents_file[1 .. @contents_file];
	

	if ($as)
		{ 
		$str = "Save '$file' as..."; 
		} 
	else
		{ 
		$str = "Save '$file'" ;
		} 

	$w = new MainWindow(-title=>"Save '$file'");
	$dirlist = $w -> DirTree (-width=>55) -> pack(-fill=>'x') ;
	$dirlabel = $w -> Label (-text=>"Select a directory for the new directory to be created under and enter name for the new directory:") -> pack (-fill=>'x' );
	$dirent = $w -> Entry () -> pack (-fill=>'x') ;
	$newdir = $w -> Button (-command=>sub { newdir(); } , -activebackground=>'blue', -text=>'NEW DIR')-> pack (-fill=>'x');
	$botlabel = $w -> Label (-text=>"Select a directory where you want to save the file and type the file name:") -> pack (-fill=>'x');
	$filename = $w -> Entry () -> pack (-fill=>'x');
	$filename -> insert (0, $file) if ! $as ; 
	$finalsavebutt = $w -> Button (-command=>\&savefinal, -text=>'SAVE THE FILE', -activebackground=>'blue')  -> pack (-fill=>'both');
	if ($file =~ /^$|^\s*$/) 
		{ 
		my $d = $w -> Dialog (-text=>"Your file name was blank. Try again" ,-title=>"Error"); 
		$d->Show(); 	
		$w -> destroy();
		} 	
	MainLoop(); 
	
	} 

sub returntext
	{ 
	my $wintit = shift;
 	my $butttext = shift; 
	$rett_win = new MainWindow(); 
	my $d = $rett_win -> Dialog (); 
	my $d2 = $rett_win -> Dialog(); 
	$d -> configure (-text=>'Error: You did not supply the argument for the window title', -title=>'Error'); 
	$d2 -> configure (-text=>'Error: You did not supply the argument for the button text', -title=>'Error'); 
	if (! $wintit)
		{ 
		$d -> Show() ;
		$rett_win -> destroy();
		return; 
		} 
	if (! $butttext) 
		{ 
		$d2 -> Show (); 
		$rett_win -> destroy();
		return;
		} 
	$rett_win -> configure (-title=>"$wintit"); 
	$ret_txt = $rett_win -> Text () -> pack (-fill=>'x');
	my @z; 
	my $ret_butt = $rett_win -> Button (-text=>"$butttext", -command=>sub {@z = rettxt_getcont(); $rett_win ->destroy();  $rett_win = ''; } )->pack();
	MainLoop();
	return (@z);
	} 

sub htmlcolret
	{ 
	my $ret; 
	$html_win = new MainWindow(-title=>"Html Color Chooser");
	my $t = $html_win -> Table (-rows=>4, -columns=>4, -scrollbars=>0) -> pack (-fill=>'x');
	my $one = $t -> Button (-background=>"black", -width=>4, -command=>sub { $ret = htmlreturnfinal ('#000000'); });
	my $two = $t -> Button (-background=>"gray75", -width=>4, -command=>sub { $ret = htmlreturnfinal ('#C0C0C0 '); });
	my $three = $t -> Button (-background=>"gray50", width=>4, -command=>sub { $ret = htmlreturnfinal ('#808080'); });
	my $four = $t -> Button (-background=>"white", -width=>4, -command=>sub { $ret = htmlreturnfinal ('#FFFFFF');  }); 
	my $five = $t -> Button (-background=>"darkred", -width=>4 , -command=>sub { $ret = htmlreturnfinal ('#800000');  }); 
	my $six = $t -> Button (-background=>"red", -width=>4, -command=>sub { $ret = htmlreturnfinal ('#FF0000'); });
	my $seven = $t -> Button (-background=>"DarkMagenta", -width=>4, -command=>sub { $ret = htmlreturnfinal ('#800080'); } );
	my $eight = $t -> Button (-background=>"green4", -width=>4, -command=>sub { $ret = htmlreturnfinal ('#008000');});
	my $nine = $t -> Button (-background=>"green", -width=>4, -command=>sub { $ret = htmlreturnfinal ('#00FF00');}); 
	my $ten = $t -> Button (-background=>"Gold4", -width=>4, -command=>sub { $ret = htmlreturnfinal ('#808000');}); 
	my $eleven = $t -> Button (-background=>"yellow", -width=>4, -command=>sub { $ret = htmlreturnfinal ('#FFFF00');}); 
	my $twelve = $t -> Button (-background=>"navy", -width=>4, -command=>sub { $ret = htmlreturnfinal ('#000080');}); 
	my $thirteen = $t -> Button (-background=>"turquoise4", -width=>4, -command=>sub { $ret = htmlreturnfinal ('#008080');}); 
	my $fourteen = $t -> Button (-background=>"cyan", -width=>4, -command=>sub { $ret = htmlreturnfinal ('#00FFFF');}); 
	$t->put (0, 1, $one) ;
	$t->put (0, 2, $two) ;
	$t->put (0, 3, $three) ;
	$t->put (0, 4, $four) ;
	$t->put (1, 1, $five) ;
	$t->put (1, 2, $six); 
	$t->put (1, 3, $seven) ;
	$t->put (1, 4, $eight) ;
	$t->put (2, 1, $nine) ;
	$t->put (2, 2, $ten) ;
	$t->put (2, 3, $eleven) ;
	$t->put (2, 4, $twelve) ;
	$t->put (3, 2, $thirteen) ;
	$t->put (3, 3, $fourteen) ;
	MainLoop();
	return $ret; 
	} 
	

#######################################################
#
#
### subs not exported

##############################


#######################################################

sub htmlreturnfinal
	{ 
	$html_win -> destroy();
	return shift; 
	} 

sub rettxt_getcont
	{ 
	my $t = join '', @tmp; 
	return ( $ret_txt -> Contents );
	} 

sub savefinal
	{ 
	$die1 = $w -> Dialog (-text=>'An error occured while saving. Remember to select only one directory and to include a file name.' ,-title=>"Error");
	$die2 = $w -> Dialog (-text=>'File already exists. Overwrite it?', -buttons=>['Yes', 'No'], -title=>"Overwrite file?");
	if (! $dirlist -> info ('selection') or $dirlist-> info ('selection') > 1 or $filename-> get() =~ /^$|^\s*$/)
		{
		$die1 -> Show() ; 
		return;
		} 
	if (-e join ('', $dirlist->info('selection')) . '/' . $filename-> get() )
		{
		$tmp=$die2->Show();
		if ($tmp eq 'No')
			{
			return; 
			}
		}
	$finfile = join ('', $dirlist->info('selection')) . '/' . $filename-> get();
	open (A,">$finfile");
	print A @contents; 
	close (A);
	$w -> $destroy; 
	$w = ''; 
	return;
	
	} 
sub newdir
	{ 
	$g = $w -> Dialog (-text=>"No directory selected or directory name empty or directory already exists.", -title=>'Error');
	$a = $w -> Dialog (-text=>"Directory created successfully.", -title=>'Success');
	if ( ! $dirlist -> info ('selection') or $dirlist -> info ('selection') > 1 or $dirent -> get() =~ /^$|^\s*$/)
		{ 
		
		$g->Show();
		return;  
		} 
	print (join ('', $dirlist -> info ('selection')) . $dirent -> get()); 
	$a -> Show and return 1 if mkdir (join ('', $dirlist -> info ('selection')) . '/' .$dirent -> get()); 
	$g->Show();	
	return 0;
	} 

sub superopenfinal
    { 
    my ($files);
    my $d = $openw -> Dialog (-title=>'Error', -text=>'Error: You selected an invalid file or did not select a file.' ); 
    
    $files = $open_list -> get ($open_list -> curselection);
    $_ = $files; 
    if (/^\.$/ or /^\.\.$/ or ! $files)
            {             
            $d-> Show();
            return; 
            } 
    my $d2 = join '', $open_dir-> info ('selection');
    chomp  ($d2, $files);
    open  (F, $d2 . '/' . $files);
    my @files2 = <F>;
    my $files2 = join '', @files2; 
    close (F);    
    return ($files, $files2 ); 
    } 
sub superopencdir
    { 
    $open_list -> delete (0 , 'end');     
    my $d = $openw -> Dialog (-title=>'Error', -text=>'Error: you selected more than one diretory.');
    my @a;
    @a = $open_dir -> info('selection' );
    if (@a) 
        {
        $open_botl  -> pack (-fill=>'x' );  
        $open_list -> pack (-fill=>'x' );  
        $open_sel -> pack (-fill=>'x');   
        }
    print scalar (@a);
    if (@a > 1)  
        {
        $d->Show();
        return;
        } 
    opendir (A, $a[0]); 
    my @dir = readdir ( A );
    closedir ( A ) ;
    $open_list -> insert ('end', @dir); 
        
    } 

sub superdirdone
        { 
        my $v = shift;
        my $v2 = $v-> info ('selection'); 

        if (! $v2) 
                { 
                my $errdialog = $superdirwin -> Dialog (-title=>'Error', -text=>'Error: you did not select a directory');
                $errdialog -> Show();
                return;
                } 
        $superdirwin -> destroy();        
        return $v2; 
        } 

sub superdirnewdir
        { 
        my $cont = shift; 
        my $dir = shift; 
        my $errordialog=$superdirwin-> Dialog (-text=>"An error occured.\n\nPossible cause 1: you didn't select a directory.\nPossible cause 2: you didn't type in a directory name or it was all in spaces.\nPossible cause 3: the directory you are trying to create already exists.\nPossible cause 4: the directory name was invalid.", -title=>"Error");
        my $sucessdialog = $superdirwin->Dialog (-text=>"Directory created sucessfully.", -title=>'success'); 
        if (-e "$dir/$cont" or $dir =~ /^$/ or $cont =~ /^$|^\s*$/) 
                { 
                $errordialog -> Show(); 
                return 0; 
                } 
        if (mkdir "$dir/$cont")
                { 
                $sucessdialog -> Show (); 
                return 1; 
                }         
        else
                {
                $errordialog -> Show(); 
                return 
                }
        }
1; 

__END__

=head1 NAME

tkShortcuts - Several shortcuts for Tk. 

=head1 SYNOPSIS

  use TkShortcuts1; 
  # then you call its methods. 

=head1 DESCRIPTION

This module contains some alternative Tk dialogs that you can use, that, in my opinion are more beneficial for the end user than some of the stuff that is packaged with Tk as well as two other Tk shortcuts that will make your life a lot easier. This module is very easy to use. 

--- 

METHODS: 

1. 

superdirchoose()

This method returns a chosen directory that the user will chose. 

Example:  

my $dir = superdichoose(); 

2. 

superopenfile() 

This method returns the contents of a file that the user selects to open. It returns it as an array. 

Example: 

my @filecontents = superopenfile(); 

3. 

saveit()

This is a method for creating a save file dialog. It takes two arguments. The first is a scalar which is the filename of the file to be saved. The second is an array of its contents. The method does not return anything. 

Example: 

saveit ($filname,  @contentsoffilename); 

4. 

returntext()

This method sets up a dialog where the user can type in text in a big text entry box and then that text is returned. The method takes two arguments, two scalars. The first is av string for the window title and the second is a string for the text on the button on the bottom of the window used to return the text. 

Example:

my @text = returntext ("Save Text", "Save Text"); 

5. 

htmlcolret

This method returns a hex number for various html colors color coded buttons. 

Example:

my $htmlcolor = htmlcolret(); 

---

All of the methods for this have the variable for their MainWindow() exported. 

For superdirchoose the variable is: $superdirwin 
For superopenfile: $win_openfile
For saveit: $w 
For returntext: $rett_win
For htmlcolret: $htmlwin

The variable as is also exported and set to 0. Giving it a true value will force saveit to be a "save as..." dialog box instead of a "save" one. 

=head1 SEE ALSO

See also Tk! It rocks. 

check me out @ www.infusedlight.net

=head1 AUTHOR

Robin Bank, webmaster@infusedlight.net

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Robin Bank

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
