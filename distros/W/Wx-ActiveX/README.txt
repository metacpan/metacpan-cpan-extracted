----------------------------------
 Wx::ActiveX 0.14
----------------------------------
  
    ActiveX interface for Wx
    
----------------------------------
 PPMs  
----------------------------------

    PPMs are available at http://www.wxperl.co.uk/
    
----------------------------------
 Build   
----------------------------------
  
    This is ActiveX so it is a MSWin specific module. You
    will need Wx >= 0.50 together with Alien::wxWidgets >=0.24.
 
    If you have built your own Alien::wxWidgets or installed
    a development PPM or PAR Distribution of Alien wxWidgets,
    then the standard methods should work:
    
    Development distributions 
  
    ------------------------
    MSVC & ActiveState Perl
    ------------------------
  
    perl Makefile.PL
    nmake
    nmake test
    nmake install
    
    ------------------------
    MinGW & ActiveState Perl
    ------------------------
    
    ActiveState Perl with a Win32::BuildNumber of 822 (Perl 5.8),
    1002 (Perl 5.10),  or greater.
    
    perl Makefile.PL
    dmake
    dmake test
    dmake install
    
    
    If you are using ActiveState Perl with a Win32::BuildNumber of 820 
    or lower, then you need ExtUtils:FakeConfig installed and should do:
    
    perl -MConfig_m Makefile.PL
    nmake
    nmake test
    nmake install
    
    You will need the free nmake from Microsoft to install
    ExtUtils:FakeConfig 0.10
        
    You don't need ExtUtils:FakeConfig or the -MConfig_m option if your 
    Win32::BuildNumber is 822 (Perl 5.8), 1002 (Perl 5.10),  or greater.
    
    ---------------
    Strawberry Perl
    ---------------
    
    perl Makefile.PL
    dmake
    dmake test
    dmake install
    


----------------------------------
 ORIGINAL AUTHOR 
----------------------------------

    Graciliano M. P


----------------------------------
 Current Maintainer 
----------------------------------
    Mark Dootson <mdootson@cpan.org>
