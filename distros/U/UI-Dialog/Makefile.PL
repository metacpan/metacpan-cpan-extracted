use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  ( 'NAME' => 'UI::Dialog',
    'VERSION_FROM' => 'lib/UI/Dialog.pm',          # finds $VERSION
    'PREREQ_PM' =>
    { Text::Wrap => 0,
      File::Basename => 0,
      Time::HiRes => 0,
      perl => 5.006,
      String::ShellQuote => 0,
      File::Slurp => 0
    },             # e.g., Module::Name => 1.1
    ($] >= 5.005 ? ## Add these new keywords supported since 5.005
     ( AUTHOR          => 'Kevin C. Krinke <kevin@krinke.ca>') : () ),
    'PM_FILTER' => 'perl -pe "s!\\Q/usr/bin/perl\\E!$(FULLPERL)!g"',
    'PM' =>
    { 'lib/UI/Dialog.pm'                   => '$(INST_LIBDIR)/Dialog.pm',
      'lib/UI/Dialog/Console.pm'           => '$(INST_LIBDIR)/Dialog/Console.pm',
      'lib/UI/Dialog/Gauged.pm'            => '$(INST_LIBDIR)/Dialog/Gauged.pm',
      'lib/UI/Dialog/GNOME.pm'             => '$(INST_LIBDIR)/Dialog/GNOME.pm',
      'lib/UI/Dialog/KDE.pm'               => '$(INST_LIBDIR)/Dialog/KDE.pm',
      'lib/UI/Dialog/Backend.pm'           => '$(INST_LIBDIR)/Dialog/Backend.pm',
      'lib/UI/Dialog/Backend/ASCII.pm'     => '$(INST_LIBDIR)/Dialog/Backend/ASCII.pm',
      'lib/UI/Dialog/Backend/CDialog.pm'   => '$(INST_LIBDIR)/Dialog/Backend/CDialog.pm',
      'lib/UI/Dialog/Backend/GDialog.pm'   => '$(INST_LIBDIR)/Dialog/Backend/GDialog.pm',
      'lib/UI/Dialog/Backend/KDialog.pm'   => '$(INST_LIBDIR)/Dialog/Backend/KDialog.pm',
      'lib/UI/Dialog/Backend/Nautilus.pm'  => '$(INST_LIBDIR)/Dialog/Backend/Nautilus.pm',
      'lib/UI/Dialog/Backend/Whiptail.pm'  => '$(INST_LIBDIR)/Dialog/Backend/Whiptail.pm',
      'lib/UI/Dialog/Backend/XDialog.pm'   => '$(INST_LIBDIR)/Dialog/Backend/XDialog.pm',
      'lib/UI/Dialog/Backend/XOSD.pm'      => '$(INST_LIBDIR)/Dialog/Backend/XOSD.pm',
      'lib/UI/Dialog/Backend/Zenity.pm'    => '$(INST_LIBDIR)/Dialog/Backend/Zenity.pm',
      'lib/UI/Dialog/Screen/Druid.pm'      => '$(INST_LIBDIR)/Dialog/Screen/Druid.pm',
      'lib/UI/Dialog/Screen/Menu.pm'       => '$(INST_LIBDIR)/Dialog/Screen/Menu.pm',
      'lib/UI/Dialog.pod'                  => '$(INST_LIBDIR)/Dialog.pod',
      'lib/UI/Dialog/Console.pod'          => '$(INST_LIBDIR)/Dialog/Console.pod',
      'lib/UI/Dialog/Gauged.pod'           => '$(INST_LIBDIR)/Dialog/Gauged.pod',
      'lib/UI/Dialog/GNOME.pod'            => '$(INST_LIBDIR)/Dialog/GNOME.pod',
      'lib/UI/Dialog/KDE.pod'              => '$(INST_LIBDIR)/Dialog/KDE.pod',
      'lib/UI/Dialog/Backend.pod'          => '$(INST_LIBDIR)/Dialog/Backend.pod',
      'lib/UI/Dialog/Backend/ASCII.pod'    => '$(INST_LIBDIR)/Dialog/Backend/ASCII.pod',
      'lib/UI/Dialog/Backend/CDialog.pod'  => '$(INST_LIBDIR)/Dialog/Backend/CDialog.pod',
      'lib/UI/Dialog/Backend/GDialog.pod'  => '$(INST_LIBDIR)/Dialog/Backend/GDialog.pod',
      'lib/UI/Dialog/Backend/KDialog.pod'  => '$(INST_LIBDIR)/Dialog/Backend/KDialog.pod',
      'lib/UI/Dialog/Backend/Nautilus.pod' => '$(INST_LIBDIR)/Dialog/Backend/Nautilus.pod',
      'lib/UI/Dialog/Backend/Whiptail.pod' => '$(INST_LIBDIR)/Dialog/Backend/Whiptail.pod',
      'lib/UI/Dialog/Backend/XDialog.pod'  => '$(INST_LIBDIR)/Dialog/Backend/XDialog.pod',
      'lib/UI/Dialog/Backend/XOSD.pod'     => '$(INST_LIBDIR)/Dialog/Backend/XOSD.pod',
      'lib/UI/Dialog/Backend/Zenity.pod'   => '$(INST_LIBDIR)/Dialog/Backend/Zenity.pod',
      'lib/UI/Dialog/Screen/Druid.pod'     => '$(INST_LIBDIR)/Dialog/Screen/Druid.pod',
      'lib/UI/Dialog/Screen/Menu.pod'      => '$(INST_LIBDIR)/Dialog/Screen/Menu.pod',
    }
  );
