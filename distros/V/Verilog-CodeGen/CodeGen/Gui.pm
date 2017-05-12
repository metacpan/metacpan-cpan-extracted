package Verilog::CodeGen::Gui;

use vars qw( $VERSION );
$VERSION='0.9.4';

#################################################################################
#                                                                              	#
#  Copyright (C) 2002,2003 Wim Vanderbauwhede. All rights reserved.             #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

print STDOUT "//Verilog::CodeGen GUI Documentation\n";

use strict;

################################################################################

 @Verilog::CodeGen::ISA = qw(Exporter);
 @Verilog::CodeGen::EXPORT =qw();

################################################################################

=head1 NAME

B<Verilog::Codegen::Gui> - Verilog code generator GUI

=head1 SYNOPSIS

  $ ./gui.pl [design name]

The GUI and its utility scrips are in the C<scripts> folder of the distribution. 

The design name is optional. If no design name is provided, the GUI will check the .vcgrc file for one. If this file does not exists, the design library module defaults to DeviceLibs/Verilog.pm and the objects will reside directly under DeviceLibs/Objects. Otherwise, the design library module will be DeviceLibs/YourDesign.pm  and the objects will reside under DeviceLibs/YourDesign/Objects. You can also set the design name via the GUI.

=head1 USAGE

The GUI is very simple to use. A short manual:

To create, test and run Verilog code using the Verilog::CodeGen GUI:

=head2 0. Choose your design.

In the B<Design> text entry field, type the full name of the design. Click B<Set>. 

If the design does not exist, it will be created, that is, an empty structure with skeleton files will be created. Otherwise, the design will be set to the entered value.

=head2 1. Create or edit the Device Object.

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

