# ----------------------------------------------------------------------
# Copyright (C) 2006 R Bernard Davison <rbdavison@cpan.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# ----------------------------------------------------------------------
# Derivative of XML::API::XHTML for WIX version 2 
# ----------------------------------------------------------------------
package XML::API::WIX2;

use strict;
use warnings;
use 5.006;
use base qw(XML::API);

our $VERSION = 0.02;

my $m_wix_dir = "C:/Program Files/Windows Installer XML v2/doc";
my $xsd = "$m_wix_dir/wix.xsd";

sub _doctype {
    return qq{};
}

sub _xsd {
    return $xsd;
}

sub _root_element {
    return 'Wix';
}

sub _root_attrs {
    return {xmlns => 'http://schemas.microsoft.com/wix/2003/01/wi'};
}


1;

__END__


=head1 NAME

XML::API::WIX2 - WIX source file generation through an object API

=head1 SYNOPSIS

As a simple example the following perl code:

  use XML::API;
  my $m_wxs = new XML::API('doctype' => 'WIX2', 'encoding' => 'UTF-8');

  $m_wxs->Product_open({
    Id => '12345678-1234-1234-1234-123456789012',
    Name => 'Test Package',
    Language => '1033',
    Version => '1.0.0.0',
    Manufacturer => 'Microsoft Corporation',
    });
  $m_wxs->Package({
    Id => '12345678-1234-1234-1234-123456789012',
    Description => 'My first Windows Installer package',
    Comments => 'This is my first attempt at creating a Windows Installer database',
    Manufacturer => 'Microsoft Corporation',
    InstallerVersion => '200',
    Compressed => 'yes',
    });
  $m_wxs->Media({ Id =>'1', Cabinet => 'product.cab', EmbedCab => 'yes'});
  $m_wxs->Directory_open({ Id => 'TARGETDIR', Name => 'SourceDir'});
  $m_wxs->Directory_open({ Id => "ProgramFilesFolder", Name => "PFiles"});
  $m_wxs->Directory_open({ Id => "TESTFILEPRODUCTDIR", Name => "TFolder", LongName => "TestFolder"});
  $m_wxs->Component_open({ Id => 'License', Guid => '12345678-1234-1234-1234-123456789012'});
  $m_wxs->File({ Id => "License", Name => "License.rtf", DiskId => "1", Source => "License.rtf"});
  $m_wxs->Component_close();
  $m_wxs->Directory_close();
  $m_wxs->Directory_close();
  $m_wxs->Directory_close();
  $m_wxs->Feature_open({ Id => 'License', Title => 'License files', Level => '1'});
  $m_wxs->ComponentRef({ Id => 'License' });
  $m_wxs->Feature_close();
  $m_wxs->Property({Id => "WIXUI_INSTALLDIR", Value => "TESTFILEPRODUCTDIR"});
  $m_wxs->UIRef({Id => "WixUI_Mondo"});
  $m_wxs->Product_close();
  $m_wxs->_print;

will produce the following nicely rendered output:
  
  <?xml version="1.0" encoding="UTF-8" ?>
  
  <Wix xmlns="http://schemas.microsoft.com/wix/2003/01/wi">
    <Product Id="12345678-1234-1234-1234-123456789012" Language="1033" Manufacturer="Microsoft Corporation" Name="Test Package" Version="1.0.0.0">
      <Package Comments="This is my first attempt at creating a Windows Installer database" Compressed="yes" Description="My first Windows Installer package" Id="12345678-1234-1234-1234-123456789012" InstallerVersion="200" Manufacturer="Microsoft Corporation" />
      <Media Cabinet="product.cab" EmbedCab="yes" Id="1" />
      <Directory Id="TARGETDIR" Name="SourceDir">
        <Directory Id="ProgramFilesFolder" Name="PFiles">
          <Directory Id="TESTFILEPRODUCTDIR" LongName="TestFolder" Name="TFolder">
            <Component Guid="12345678-1234-1234-1234-123456789012" Id="License">
              <File DiskId="1" Id="License" Name="License.rtf" Source="License.rtf" />
            </Component> <!-- Guid="12345678-1234-1234-1234-123456789012" Id="License"-->
          </Directory> <!-- Id="TESTFILEPRODUCTDIR" LongName="TestFolder" Name="TFolder"-->
        </Directory> <!-- Id="ProgramFilesFolder" Name="PFiles"-->
      </Directory> <!-- Id="TARGETDIR" Name="SourceDir"-->
      <Feature Id="License" Level="1" Title="License files">
        <ComponentRef Id="License" />
      </Feature> <!-- Id="License" Level="1" Title="License files"-->
      <Property Id="WIXUI_INSTALLDIR" Value="TESTFILEPRODUCTDIR" />
      <UIRef Id="WixUI_Mondo" />
    </Product> <!-- Id="12345678-1234-1234-1234-123456789012" Language="1033" Manufacturer="Microsoft Corporation" Name="Test Package" Version="1.0.0.0"-->
  </Wix> <!-- xmlns="http://schemas.microsoft.com/wix/2003/01/wi"-->

=head1 DESCRIPTION

B<XML::API::WIX2> is a perl object class for creating WIX version 2 source files.
The methods of a B<XML::API::WIX2> object are derived directly from the wix.xsd 
specification. 

B<At the time of writing the XML valiadation is not implemented in XML::API>. 
So make sure you follow the Wix specifications or the source won't compile.

=head1 SEE ALSO

 XML::API and XML::API::XHTML

=head1 AUTHOR

R Bernard Davison E<lt>rbdavison@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 R Bernard Davison E<lt>rbdavison@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut

