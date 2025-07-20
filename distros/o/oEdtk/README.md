***************************************************************************
***************************************************************************
					oEdtk   
***************************************************************************
***************************************************************************

You can find README and COPYING in ./lib/oEdtk

oEdtk IS A PROJECT FOR PRINTING PROCESSING specialized namespace for 
enhancement of data tracking and knowledge for industrial printing 
processing.


    oEdtk Copyright (C) 2005-2025 G Chaillou Domingo, D Aunay, M Henrion, G Ballin

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.


oEdtk is a package of methods that allow the user to quickly 
develop application for parsing data stream. Those methods allow
the user to prepare the data so that printing application build 
documents with these data.

This package is a toolkit for developping parsing application
dedicated to reports (LaTeX, CSV, Excel and DB). 
You would create application by loading stream documentation (such as
Cobol CopyBooks, XML or TXT). Developpers will customize their application. 
Then the core (basics functions) of this module is used by the 
applications to produce reports such as documents, mailings, invoices, banking 
statement, etc. 

You can contact us at 
	oedtk at free.fr
reference site is cpan.org


INSTALLATION
***************************************************************************
With ActivPerl distribution, you can use PPM to install oEdtk module.
With all perl distributions you can use CPAN to install oEdtk module.
At least, you can download the last release from http://www.cpan.org/

BEFORE installation, you have to setup XML-LibXML :
- windows : you have to setup XML-LibXML with PPM
			you should also install dmake utils with PPM
- Linux   : you have to setup XML-LibXML with your distribution's  
			package installer (or apt-get install)

Command line for manual installation :
perl Makefile.PL
make                # use 'dmake' on Win32 (install it with cpan or ppm)
make test
make install
make clean


CONTENT OF THIS ARC oEdtk is Copyright (C) 2005-2025, D Aunay, G Chaillou Domingo, M Henrion, G Ballin

HIVE
***************************************************************************
/lib/oEdtk.pm					main module dedicated for documentation
/lib/oEdtk/libEdtkC7.pm			methods for DSC Compuset integration
/lib/oEdtk/libEdtkDev.pm			general methods for developpements only
/lib/oEdtk/prodEdtk.pm			main methods used for production
/lib/oEdtk/prodEdtkXls.pm		methods used for excel docs production
/lib/oEdtk/trackEdtk.pm			module planned for production statistics
/lib/oEdtk/tuiEdtk.pm			text user interface for libEdtkDev
/lib/oEdtk/iniEdtk/tplate.edtk.ini	main configuration file template
/lib/oEdtk/logger.pm			module for logging (could be replaced by Log4perl)
/lib/oEdtk/dataEdtk.pm			Tests - copy group analysis for generator
/lib/oEdtk/README				this file
/lib/oEdtk/COPYING				GNU GENERAL PUBLIC LICENSE

/t/test.t						test plan for installation
/t/test_fixe_oEdtk.pl			simple test application for installation
/t/cp_fr_fixe.dat				test file for simple Excel test
/t/cp_fr.dat					test file for simple Excel test 2 (planned)

Makefile.PL					Makefile for installation
MANIFEST						Manifest for installation
MANIFEST.SKIP					Skip files
README						extract of this file


DEPENDENCIES
***************************************************************************

Config::IniFiles		(for develoments and tracking)
DBI					(for database : settings, Outputmanagement, tracking...)
List::MoreUtils
List::Util
Sys::Hostname

Term::ReadKey			(for developments only - used for tuiEdtk)

Spreadsheet::WriteExcel	(for excel document only)
OLE::Storage_Lite		(for Spreadsheet::WriteExcel only)
Parse::RecDescent		(for Spreadsheet::WriteExcel only)

Archive::Zip			(for Output management packaging)
charnames
Cwd
Date::Calc
Digest::MD5
File::Basename
File::Copy
File::Path
Net::FTP
Text::CSV

Email::Sender::Simple
Email::Sender::Transport::SMTP
Encode

Math::Round
overload
Scalar::Util

XML::LibXML			(for XML data inputs)
XML::XPath
XML::Writer

