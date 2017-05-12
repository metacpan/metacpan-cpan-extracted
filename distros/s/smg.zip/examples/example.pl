use smg;
smg::initscr($Kb,$Pb) or die "Cannot initialize Screen";
smg::crewin(10,20,$win1,"L") or die "Cannot create window";
smg::putwin(2,2,$win1,$Pb) or die "Cannot show my window";
smg::crewin(10,20,$win2,"b") or die "Cannot create window";
smg::putwin(9,9,$win2,$Pb) or die "Cannot show my window";
smg::crewin(1,78,$win3,"l") or die "Cannot create window";
smg::putwin(22,2,$win3,$Pb) or die "Cannot show my window";
smg::crewin(2,80,$win4,"\n") or die "Cannot create window";
smg::putwin(19,1,$win4,$Pb) or die "Cannot show my window";
smg::puthichars($win4,2,1,
	      "SUPER DEMO (It is just a sample)"
	      ,"r7");
smg::putchars($win3,1,1,
	      "you can create windows with borders and put characters in those"
	      ,"b5");
for($i=1;$i<11;$i++){
   smg::putchars($win1,1,$i,"line border","br");
   smg::putchars($win2,1,$i,"block border","bf2");
}
sleep 1;
smg::erasewin($win3 ,1 ,1 ,1 ,78);
smg::putchars($win3,1,1,
	      "You can change window video attributes"
	      ,"b5");
smg::changewinattr($win1 ,1 ,1 ,3 ,5 ,"2" );
sleep 1;
smg::erasewin($win3 ,1 ,1 ,1 ,78);
smg::putchars($win3,1,1,
	      "you can change window size and label borders"
	      ,"b5");
smg::changewinsize($win2 ,8 ,30);
smg::labelwin($win1 ,"top" ,"t" ,3 ,"\n" );
sleep 1;
smg::labelwin($win1 ,"bottom" ,"b" ,3 ,"\n" );
sleep 1;
smg::labelwin($win1 ,"left" ,"l" ,3 ,"\n" );
sleep 1;
smg::labelwin($win1 ,"right" ,"r" ,3 ,"\n" );
sleep 1;
smg::labelwin($win2 ,"top" ,"t" ,3 ,"3r" );
sleep 1;
smg::labelwin($win2 ,"bottom" ,"b" ,3 ,"3r" );
sleep 1;
smg::labelwin($win2 ,"left" ,"l" ,3 ,"3r" );
sleep 1;
smg::labelwin($win2 ,"right" ,"r" ,3 ,"3r" );
sleep 1;
smg::erasewin($win3 ,1 ,1 ,1 ,78);
smg::putchars($win3,1,1,
	      "you can draw lines and boxes"
	      ,"b5");
smg::drawline($win2 ,5,16,5,19, "8");
smg::drawbox($win2 ,3,19,7,24, "8");
sleep 1;
smg::erasewin($win3 ,1 ,1 ,1 ,78);
smg::putchars($win3,1,1,
	      "you can enter a string"
	      ,"b5");
smg::setcurpos($win2,5,20);
smg::codetoname(smg::read_string($win2,$Kb,$Str,3),$keyname);
sleep 1;
smg::erasewin($win3 ,1 ,1 ,1 ,78);
smg::putchars($win3,1,1,
	      "You entered ".$Str." and terminated with ".$keyname
	      ,"b5");
sleep 2;
smg::erasewin($win3 ,1 ,1 ,1 ,78);
smg::putchars($win3,1,1,
	      "You can create a window and put a menu in it"
	      ,"b5");
smg::crewin(8,17,$menu,"L") or die "Cannot create window";
smg::putwin(8,40,$menu,$Pb) or die "Cannot show my window";
$choices="Caviar ortolanhomard patatesnouille";
smg::cremenu($menu ,$choices ,7 ,"vfd" ,2 ,"b");
$mess=sprintf "The cursor in Window 2 in at line %d and col %d",
      smg::curline($win2),
      smg::curcol($win2);
sleep 1;
smg::erasewin($win3 ,1 ,1 ,1 ,78);
smg::putchars($win3,1,1,
	      $mess
	      ,"b5");
$def=2;
$dir= qx'show default';
chomp $dir;
$hlb= $dir."example.hlb";
sleep 1;
smg::erasewin($win3 ,1 ,1 ,1 ,78);
smg::putchars($win3,1,1,
	      "select an option or press the help key"
	      ,"b5");
smg::selmenuopt($Kb ,$menu ,$sel_nb , $def ,"\0" ,$hlb);
smg::erasewin($win3 ,1 ,1 ,1 ,78);
smg::putchars($win3,1,1,
	      "you selected number $sel_nb indeed"
	      ,"b5");
sleep 1;
smg::cresubwin($win1 ,2 ,2 ,3 ,5);
smg::putwinagain($win1 ,Pb2 ,5 ,5);
smg::erasewin($win3 ,1 ,1 ,1 ,78);
smg::putchars($win3,1,1,
	      "We are watching window 1 thru a subwindow, type any key "
	      ,"b5");
sleep 1;
smg::readkey($Kb ,$code);
smg::codetoname($code,$keyname);
smg::erasewin($win3 ,1 ,1 ,1 ,78);
smg::putchars($win3,1,1,
	      "$keyname"
	      ,"b5");
smg::readkeypt($Kb ,$code ,"Go type! you can do it!",4 ,$win3);
sleep 1;
smg::putchars($win3,1,1,
	      "Let us cleanup"
	      ,"b5");
smg::delmenu($menu);
sleep 1;
smg::delwin($win1);
sleep 1;
smg::delwin($win2);
sleep 1;
smg::delwin($menu);
sleep 1;
smg::erasewin($win3 ,1 ,1 ,1 ,78);
smg::delwin($win3);
smg::clearscreen($Pb);
exit 0;
