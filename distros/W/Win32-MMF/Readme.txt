#######################################################################
#
# Win32::MMF - Win32 Memory Mapped File Support for Perl
# Version: 0.07 (15 Feb 2004)
#
# Author: Roger Lee <roger@cpan.org>
#
#######################################################################

This module provides Windows' native Memory Mapped File Service
for inter-process or intra-process communication under Windows.

The current version of Win32::MMF is available on CPAN at:

  http://search.cpan.org/search?query=Win32::MMF

The following is a quick overview of the look and feel of the module:

  # ===== Object Oriented Interface =====
  use Win32::MMF;

  # --- in process 1 ---
  my $ns1 = Win32::MMF->new( -namespace => "MySharedmem" );

  $ns1->setvar('varid', $data);

  # --- in process 2 ---
  my $ns2 = Win32::MMF->new( -namespace => "MySharedmem" )
          or die "namespace not exist";

  $data = $ns2->getvar('varid');


  # ==== Tied Interface ====
  use Win32::MMF::Shareable { namespace => 'MySharedmem' };

  tie my $scalar, "Win32::MMF::Shareable", "varid";
  $scalar = 'Hello world';

  tie my $s2, "Win32::MMF::Shareable", "varid";
  print "$s2\n";    # should print 'Hello world'


Full documentation is available in POD format inside MMF.pm.

This is the first release of the module and the functionality is limited.
But it will not stay that way for long as I will add more functionality soon.

Enjoy. ;-)

