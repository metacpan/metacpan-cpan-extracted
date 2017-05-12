#!/usr/bin/perl -w

#################################################################################
#                                                                              	#
#  Copyright (C) 2002,2003 Wim Vanderbauwhede. All rights reserved.             #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

use strict;
use Cwd;
use Tk;
my $xe=1;
if(@ARGV&&$ARGV[0] eq '-nox'){
 $xe=0;
shift @ARGV;
}
my $design=(@ARGV)?$ARGV[0]:'';
#first time use
system("GUI/create_design.pl $design");
if ((!$design)&&(-e ".vcgrc")) {
open(VCG,'<.vcgrc');
chomp($design=<VCG>);
close VCG;
}
if($design eq 'Verilog'){$design=''}

print STDERR "Starting UI ...";

my $normal='-adobe-helvetica-medium-r-normal-*-12-*-*-*-*-*-iso8859-1';
my $bold='-adobe-helvetica-bold-r-normal-*-12-*-*-*-*-*-iso8859-1';
my $boldsmall='-adobe-helvetica-bold-r-normal-*-10-*-*-*-*-*-iso8859-1';
my $console='-misc-fixed-bold-r-normal-*-*-140-*-*-c-*-iso8859-1';
my @matrix;
#-------------------------------------------------------------------
my $xemacs=0;
my $debug=0;
my $update=0;
my $overwrite=0;
my $showtb=0;
my $showdefault=0;
my $text;
my $nlines=20;
my $nowarn=0;
my $plot=0;
my $run=1;
my $inspectcode=0;
my $pid='WRONG';
my $selectedfile='NONE';


&create_ui();
&launch_xemacs($xe);

#=for_named_pipe
#use Fcntl;
#my $path='tmp';
#if(-e $path){unlink $path}
#require POSIX;
#POSIX::mkfifo($path,0666) or die $!;
#=cut

print STDERR "\nDone \n";
print STDERR "\nCreating socket ... \n";
use IO::Socket;
my $new_sock;
my $buff;
my $i=0;
my $ok=1;
my $sock = new IO::Socket::INET (LocalHost => 'localhost',
				 LocalPort => 2507,
				 Proto => 'tcp',
				 Listen => 5,
				 ReuseAddr => 1,
				 );
die "Could not connect: $!" unless $sock;
print STDERR "Done \n";

MainLoop();

exit(0);


#-------------------------------------------------------------------
sub create_ui {
    my $top = MainWindow->new('-background'=>'white','-title'=>'Perl/Verilog Coding Environment');

    # MENU STUFF

    # Menu bar
    my $menu_bar_frame = $top->Frame('-background'=>'darkgrey','-width'=>80)->pack('-side' => 'top','-anchor'=>'w', '-fill' => 'x');
my $menu_bar=$menu_bar_frame->Frame('-background'=>'grey','-relief'=>'flat','-borderwidth'=>1,'-width'=>80)->pack('-side' => 'left','-anchor'=>'w', '-fill' => 'x','padx'=>5,'pady'=>5);
#==============================================================================

# General 
    # File menu
    my $menu_file = $menu_bar->Menubutton('-text' => 'File','-tearoff'=>0,
                                          '-relief' => 'flat',
                                          '-borderwidth' => 1,'font'=>$normal,'foreground'=>'black','background'=>'grey'
                                          )->grid('-row'=>0,'-column'=>0,'-sticky'=>'w','-pady'=>5,'-padx'=>5);

    $menu_file->command('-label' => 'XEmacs', '-state'=>'active',
			'-command' => sub {$xemacs=1;system("xemacs blank &")},
			'foreground'=>'black','background'=>'grey','font'=>$normal,
);
    $menu_file->command('-label' => 'Schematics', '-state'=>'active',
			'-command' => sub {chdir "Schematics/$design";system("tkgate &"); chdir '..'},
			'foreground'=>'black','background'=>'grey','font'=>$normal,
);
    $menu_file->command('-label' => 'Diagrams', '-state'=>'active',
			'-command' => sub {chdir "Diagrams/$design";system("dia &"); chdir '..'},
			'foreground'=>'black','background'=>'grey','font'=>$normal,
);
    $menu_file->command('-label' => 'gCVS', '-state'=>'active',
			'-command' => sub {system("/usr/local/gcvs/bin/gcvs &")},
			'foreground'=>'black','background'=>'grey','font'=>$normal,
);
    $menu_file->command('-label' => 'Exit', '-command' => sub {close $sock;if($pid ne 'WRONG'){exec("kill -9 $pid")}else{exit(0)}},'foreground'=>'black','background'=>'grey','font'=>$normal,);

#==============================================================================

 $matrix[0][3] = $menu_bar->Label ('background' =>'grey')->grid('-row'=>0,'-column'=>3,'-sticky'=>'w',);

my $image=  $matrix[0][3]->Photo('-file'=>'GUI/rectangle_power_perl.gif');
 $matrix[0][3]->configure('-image'=>$image);


my $projectframe=$menu_bar->Frame('-background'=>'grey','-relief'=>'flat','-borderwidth'=>1,'-width'=>80)->grid('-row' => 0, '-column' => 1,'-columnspan'=>2,'-sticky'=>'w');
my $project = $projectframe->Label ('-text'=>'Design:', '-font' => $normal, '-background' =>'grey')->pack('-side' => 'left','-anchor'=>'w', '-fill' => 'x','padx'=>1,'pady'=>1);
$matrix[0][1] = $projectframe->Entry ('-width'   =>  15, '-font' => $normal,'foreground' => 'black','background' =>'white', )->pack('-side' => 'left','-anchor'=>'w', '-fill' => 'x','padx'=>1,'pady'=>1);
my $projectbutton = $projectframe->Button('-font' => $bold,'background' =>'grey','-text' => 'Set', '-command' => \&set_design)->pack('-side' => 'left','-anchor'=>'w', 'padx'=>1,'pady'=>1);

#==============================================================================
    # Device Object Code
 $matrix[1][0] = $menu_bar->Label ('-text'=>'Device Object Code', '-width'=>80, '-font' => $bold,'foreground' => 'black', '-background' =>'lightgrey',)->grid(
'-row' => 1, '-column' => 0,'-columnspan'=>4,'-sticky'=>'w');

 $matrix[2][3] = $menu_bar->Button('-width'=> 10, '-font' => $bold,'foreground' => 'black','background' =>'grey','-text' => 'Edit', '-command' => \&show_obj)->grid(
'-row' => 2,'-column'=> 3,'-sticky'=>'w');
 $matrix[2][2] = $menu_bar->Entry ('-width'   =>  20, '-font' => $normal,'foreground' => 'black','background' =>'white', )->grid(
'-row' => 2, '-column' => 2);

 $matrix[3][3] = $menu_bar->Button('-width'=> 10, '-font' => $bold,'foreground' => 'black','background' =>'grey','-text' => 'Parse', '-command' => \&debug)->grid(
'-row' => 3,'-column'=> 3,'-sticky'=>'w');

 $matrix[3][1] = $menu_bar->Label ('-text'=>'Show result', '-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w')->grid(
'-row' => 3, '-column' =>1,'-sticky'=>'w');
 $matrix[3][0] = $menu_bar->Checkbutton ('-variable'   => \$showdefault,
 '-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0)->grid(
'-row' => 3, '-column' =>0,'-sticky'=>'e');
#==============================================================================
    # Device Library Module
 $matrix[4][0] = $menu_bar->Label ('-text'=>'Device Library Module', '-width' => 80, '-font' => $bold,'foreground' => 'black','background' =>'lightgrey',)->grid(
'-row' => 4, '-column' => 0,'-columnspan'=>4,'-sticky'=>'w');

 $matrix[5][0] = $menu_bar->Button('-width'=> 10, '-font' => $bold,'foreground' => 'black','background' =>'grey','-text' => 'Update', '-command' => \&update)->grid(
'-row' => 5,'-column'=>3,'-sticky'=>'w');

 $matrix[5][1] = $menu_bar->Label ('-text'=>'Show module', '-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w')->grid(
'-row' => 5, '-column' =>1,'-sticky'=>'w');
 $matrix[5][3] = $menu_bar->Checkbutton ('-variable'   => \$update,
 '-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0)->grid(
'-row' => 5, '-column' =>0,'-sticky'=>'e');

#==============================================================================
    # Testbench Code
 $matrix[6][0] = $menu_bar->Label ('-text'=>'Testbench Code', '-width' => 80, '-font' => $bold,'foreground' => 'black','background' =>'lightgrey',)->grid(
'-row' => 6, '-column' => 0,'-columnspan'=>4);
#------------------------------------------------------------------------------
 $matrix[7][3] = $menu_bar->Button('-width'=> 10, '-font' => $bold,'foreground' => 'black','background' =>'grey','-text' => 'Edit', '-command' => \&edit_tb)->grid(
'-row' => 7 ,'-column'=>3,'-sticky'=>'w');
 $matrix[7][2] = $menu_bar->Entry ('-width'   =>  20, '-font' => $normal,'foreground' => 'black','background' =>'white',)->grid(
'-row' => 7, '-column' =>2);
 $matrix[7][1] = $menu_bar->Label ('-text'=>'Overwrite', '-font' => $bold,'foreground' => 'black','background' =>'grey', '-width'=> 20, '-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w',)->grid(
'-row' => 7, '-column' =>1,'-sticky'=>'w');
 $matrix[7][0] = $menu_bar->Checkbutton ('-variable'   => \$overwrite, '-font' => $normal,'foreground' => 'black','background' =>'grey','-width' => 0)->grid(
'-row' => 7, '-column' =>0,'-sticky'=>'e');
#------------------------------------------------------------------------------
 $matrix[8][3] = $menu_bar->Button('-width'=> 10, '-font' => $bold,'foreground' => 'black','background' =>'grey','-text' => 'Parse', '-command' => \&parse_tb )->grid(
'-row' => 8 ,'-column'=>3,'-sticky'=>'w');

 $matrix[8][1] = $menu_bar->Label ('-text'=>'Show result', '-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w',)->grid(
'-row' => 8, '-column' =>1,'-sticky'=>'w');
 $matrix[8][0] = $menu_bar->Checkbutton ('-variable'   => \$showtb, '-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0,)->grid(
'-row' => 8, '-column' =>0,'-sticky'=>'e');

 $matrix[9][1] = $menu_bar->Label ('-text'=>'Inspect Code', '-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w',)->grid(
'-row' => 9, '-column' =>1,'-sticky'=>'w');
 $matrix[9][0] = $menu_bar->Checkbutton ('-variable'   => \$inspectcode, '-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0,)->grid(
'-row' => 9, '-column' =>0,'-sticky'=>'e');

 $matrix[10][1] = $menu_bar->Label ('-text'=>'Plot', '-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w',)->grid(
'-row' => 11, '-column' =>1,'-sticky'=>'w');
 $matrix[10][0] = $menu_bar->Checkbutton ('-variable'   => \$plot, '-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0,)->grid(
'-row' => 11, '-column' =>0,'-sticky'=>'e');

 $matrix[11][1] = $menu_bar->Label ('-text'=>'Run','-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w',)->grid(
'-row' => 10, '-column' =>1,'-sticky'=>'w');
 $matrix[11][0] = $menu_bar->Checkbutton ('-variable'   => \$run,'-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0,)->grid(
'-row' => 10, '-column' =>0,'-sticky'=>'e');

#=no_warnings
# $matrix[10][1] = $menu_bar->Label ('-text'=>'No warnings', '-font' => $bold,'foreground' => 'black','background' =>'grey','-width'=>20,'-relief'=>'flat','-borderwidth'=>1,'-anchor'=>'w',)->grid(
#'-row' => 10, '-column' =>1,'-sticky'=>'w');
# $matrix[10][0] = $menu_bar->Checkbutton ('-variable'   => \$nowarn, '-font' => $normal,'foreground' => 'black','background' =>'grey','-width'=>0,)->grid(
#'-row' => 10, '-column' =>0,'-sticky'=>'e');
#=cut
#------------------------------------------------------------------------------
 $matrix[12][0] = $menu_bar->Label ('-text'=>'Output log', '-width' => 80, '-font' => $bold,'foreground' => 'black','background' =>'lightgrey',)->grid(
'-row' => 12, '-column' => 0,'-columnspan'=>4);
#==============================================================================
# Console 
my $text_frame = $top->Frame('-background'=>'black', '-width'=>80)->pack('-side' => 'top', '-fill' => 'x');
#
 $text=$text_frame->Text('-foreground' => 'grey','-background'=>'black','-height'=>25, '-width'=>80)->pack('-side' => 'left', '-fill' => 'y');
 $text->tagConfigure('console', '-font' => $console,'foreground' => 'grey','background' =>'black',); 
my $scroll=$text_frame->Scrollbar('-background'=>'grey','-width'=>10,'-command' => ['yview', $text])->pack('-side' => 'right', '-fill' => 'y');
# Inform listbox about the scrollbar
$text->configure('-yscrollcommand' => ['set', $scroll]);

  } #end of create_ui
#-------------------------------------------------------------------
sub set_design {
$design=$matrix[0][1]->get();
system("./GUI/create_design.pl $design 2>&1 | ./GUI/send_stdout.pl &");
&listen();
}
#-------------------------------------------------------------------
sub launch_xemacs {
my $xe=shift;
if($xe) {
# we could do fork & exec, but this is more intuitive
system("xemacs blank&");
my @pid=`ps -aux | grep 'xemacs blank' | grep -v grep`;
$pid=shift @pid;
chomp $pid;
$pid=~s/^\w+\s+(\d+)/$1/;
$pid=~s/\s+.*//;
}
}
#-------------------------------------------------------------------
sub show_obj {
my $pattern= $matrix[2][2]->get();
#system("./GUI/debug.pl -s $pattern 2>&1 | ./GUI/send_stdout.pl &");
system("./GUI/debug.pl -s $pattern $design 2>&1 | ./GUI/send_stdout.pl &");
&listen();
#system("./GUI/debug.pl -s $pattern > tmp &");
#&write_output();
}
#-------------------------------------------------------------------
sub debug {
  (!$showdefault)&&($showdefault=0);
my $pattern= $matrix[2][2]->get();
my $f='';
if ($showdefault==1) {$f='-sd'}
#system("./GUI/debug.pl $f $pattern 2>&1 | ./GUI/send_stdout.pl &");
system("./GUI/debug.pl $f $pattern $design 2>&1 | ./GUI/send_stdout.pl &");
&listen();
#system("./GUI/debug.pl $f $pattern >& tmp &");
#&write_output();
}
#-------------------------------------------------------------------
sub update {
  (!$update) &&($update=0);
my $f='';
if($update==1){$f='-s'}
$text->delete('1.0','end');
#system("./GUI/update.pl $f  2>&1 | ./GUI/send_stdout.pl &");
system("./GUI/update.pl $f $design 2>&1 | ./GUI/send_stdout.pl &");
&listen();
#system("./GUI/update.pl $f >& tmp &");
#&write_output();
}
#-------------------------------------------------------------------
sub edit_tb {
my $pattern= $matrix[7][2]->get();
my $f='';
if($overwrite==1){$f='-f'}
#system("./GUI/test.pl $f $pattern  2>&1 | ./GUI/send_stdout.pl &");
system("./GUI/test.pl $f $pattern $design 2>&1 | ./GUI/send_stdout.pl &");
&listen();
#system("./GUI/test.pl $f $pattern >& tmp &");
#&write_output();
}
#-------------------------------------------------------------------
sub parse_tb {

my $pattern= $matrix[7][2]->get();
my $p='-off';
my $r='-off';
if($plot){$p='-on'}
if($run){$r='-on'}
my $s='-no';
if($showtb==1){$s='-yes'}

system("./GUI/test.pl $s $p $r $pattern $design 2>&1 | ./GUI/send_stdout.pl &");
&listen();

if($inspectcode==1) {
system("./GUI/inspect_code.pl $pattern $design &");
}
}
#-------------------------------------------------------------------
#=for_fifo
#sub write_output {
#  if(!$nowarn){$nowarn=0}
#  $text->delete('1.0','end');

#sysopen(FIFO,$path,O_RDONLY)  or die $!;
# my $i=0;
#while(<FIFO>){

#($nowarn==1) && /\.v\:/ && next;

#    $i++;
#    $text->insert("$i.0",$_);
#    $text->tagAdd('console','1.0','end');
#}
#close FIFO;
#select(undef,undef,undef,0.2);

#}
#=cut
#-------------------------------------------------------------------
#=if_all_else_fails
#sub write_output_old {
#  if(!$nowarn){$nowarn=0}
#  $text->delete('1.0','end');

#  open(TMP,"<tmp");
#  my $i=0;
#  while(<TMP>){
#($nowarn==1) && /\.v\:/ && next;

#    $i++;
#    $text->insert("$i.0",$_);
#    $text->tagAdd('console','1.0','end');
#  }
#  close TMP;
#}
#=cut
#-------------------------------------------------------------------
sub listen {

  if(!$nowarn){$nowarn=0}
  $text->delete('1.0','end');


$new_sock = $sock->accept();

  while (defined ( $buff =<$new_sock>)) {

$_=$buff;
($nowarn==1) && /\.v\:/ && next;
if(!/testbench/ && /Parsing/ && /\.pl/){
$selectedfile=$_;
chomp $selectedfile;
$selectedfile=~s/^\s*Parsing\s+//;
$selectedfile=~s/\s+.*$//;
#$matrix[2][2]->selectionFrom(0);
#$matrix[2][2]->selectionTo(30);
$matrix[2][2]->delete(0,'end');
 $matrix[2][2]->insert(0,$selectedfile);
} elsif (/test_.*testbench/) {
$selectedfile=$_;
chomp $selectedfile;
$selectedfile=~s/^.*test_/test_/;
$selectedfile=~s/\s+.*$//;
$matrix[7][2]->delete(0,'end');
 $matrix[7][2]->insert(0,$selectedfile);
}
    $i++;
    $text->insert("$i.0",$_);
    $text->tagAdd('console','1.0','end');
}

}
################################################################################
=head1 NAME

B< Verilog code generator GUI>

=head1 SYNOPSIS

  $ ./gui.pl [design name]

The GUI and its utility scrips are in the C<scripts> folder of the distribution. 

The design name is optional. If no design name is provided, the GUI will check the .vcgrc file for one. If this file does not exists, the design library module defaults to DeviceLibs/Verilog.pm and the objects will reside directly under DeviceLibs/Objects. Otherwise, the design library module will be DeviceLibs/YourDesign.pm  and the objects will reside under DeviceLibs/YourDesign/Objects.

=head1 USAGE

The GUI is very simple to use. A short manual:

To create, test and run Verilog code using the Verilog::CodeGen GUI:


=head2 1. Create or edit  the Device Object.

This is the Perl script that will generate the Verilog code. 

=over

=item *

If this is a new file:

In the B<Device Object Code> area text entry field, type the full name of the script, I<including> the C<.pl> extension. Click B<Edit> (hitting return does not work). The GUI will create a skeleton from a template, and open it in XEmacs. 

=item *

If the file already exists: 

-If this was the last file to be modified previously, just click B<Edit>. The GUI will open the file in XEmacs.

-If not, type the beginning of the file in  the B<Device Object Code> text entry field, then click B<Edit>. The GUI will open the first file matching the pattern in XEmacs.

=back

=head2 2. Test the object code

In the B<Device Object Code> area, click B<Parse>. This executes the script and displays the output in the B<Output log> window. Ticking the B<Show result> tick box will cause the output to be displayed in an XEmacs window. To close this window, click B<Done>. This is a modal window, in other words it will freeze the main display as long as it stays open.

=head2 3. Add the Device Object to the Device Library

When the object code is bug finished, click B<Update> in the B<Device Library Module> area. This will add the device object to the device library (which is a Perl module). Ticking the B<Show module> tick box will cause the complete library module to be displayed in an XEmacs window. To close this window, click B<Done>. This is a modal window, in other words it will freeze the main display as long as it stays open.

=head2 4. Create or edit the test bench code

This is the Perl script that will generate the Verilog testbench code.

=over

=item *

If this is a new file:

In the B<Testbench Code> area text entry field, type the full name of the script, I<including> the C<.pl> extension, click B<Edit>. The GUI will create a skeleton from a template, and open it in XEmacs. 

=item *

If the file already exists: 

-If this was the last file to be modified previously, just click B<Edit>. The GUI will open the file in XEmacs.

-If not, type the beginning of the file in  the B<Device Object Code> text entry field.  The testbench I<must> have the name C<test_>I<[device obect file name]>. Then click B<Edit>. The GUI will open the first file matching the pattern in XEmacs.

-If the B<Overwrite> tick box is ticked, the existing script will be overwritten with the skeleton. This is usefull in case of major changes to the device object code.

=back

=head2 5. Test the testbench code

In the B<Testbench Code> area, click B<Parse>. This executes the script and displays the output in the B<Output log> window. 

-Ticking the B<Show result> tick box will cause the output to be displayed in an XEmacs window. To close this window, click B<Done>. This is a modal window, in other words it will freeze the main display as long as it stays open. 

-Ticking the B<Inspect code> tick box will open a browser window with pages generated by the B<v2html> Verilog to HTML convertor.

-Ticking the B<Run> tick box will execute the generated testbench.

-Ticking the B<Plot> tick box will plot the simulation results (if any exist).

=head1 REQUIREMENTS

=over

=item * 

B<Perl-Tk> (L<http://search.cpan.org/CPAN/authors/id/N/NI/NI-S/Tk-800.024.tar.gz>)

Otherwise, no GUI

=item *

B<XEmacs> (L<http://xemacs.org>)

With B<gnuserv> enabled, i.e. put the line (gnuserv-start) in your .emacs. Without XEmacs, the GUI is rather useless.

For a better user experience, customize gnuserv to open files in the active frame. By default, gnuserv will open a new frame for every new file, and you end up with lots of frames.

          o Choose Options->Customize->Group
          o type gnuserv
          o Open the "Gnuserv Frame" section (by clicking on the arrow)
          o Tick "Use selected frame"

I also use the B<auto-revert-mode> L<ftp://ftp.csd.uu.se/pub/users/andersl/emacs/autorevert.el> because parsing the test bench code modifies it, and I got annoyed by XEmacs prompting me for confirmation. See the file for details on how to install.

The B<Verilog-mode> (L<http://www.verilog.com/>)is (obviously) very usefull too.

=item * 

B<v2html> (L<http://www.burbleland.com/v2html/v2html.html>)

If you want to inspect the generated code, you need the v2html Verilog to HTML convertor and a controllable browser, I use galeon (L<http://galeon.sourceforge.net>).

=item *

B<A Verilog compiler/simulator>

To run the testbench, I use Icarus Verilog L<http://icarus.com/eda/verilog/index.html>, a great open source Verilog simulator.

=item * 

B<A VCD waveform viewer>

To plot the results, I use GTkWave (L<http://www.cs.man.ac.uk/apt/tools/gtkwave/index.html>, a great open source waveform viewer.

=back

=head2 To use a different Verilog compiler/simulator and/or VCD viewer:

In CodeGen.pm, change the following lines:

   #Modify this to use different compiler/simulator/viewer
   my $compiler="/usr/bin/iverilog";
   my $simulator="/usr/bin/vvp";
   my $vcdviewer="/usr/local/bin/gtkwave";


=head1 TODO

=over

=item *

Convert the utility scripts to functions to be called from Verilog::CodeGen.

=item *

Put the GUI scripts in a module Gui.pm.

=back

=head1 AUTHOR

W. Vanderbauwhede B<wim@motherearth.org>.

L<http://www.comms.eee.strath.ac.uk/~wim>

=head1 COPYRIGHT

Copyright (c) 2002,2003 Wim Vanderbauwhede. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

