***************************************************************************
***************************************************************************
					oEdtk
***************************************************************************
***************************************************************************

You can find README and COPYING in ./lib/oEdtk

oEdtk IS A PROJECT FOR PRINTING PROCESSING specialized for
enhancement of data tracking and knowledge for industrial printing
processing.


    oEdtk Copyright (C) 2005-2026 G Chaillou Domingo, D Aunay, M Henrion, G Ballin

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
	edtk at free.fr
reference site is cpan.org
https://sourceforge.net/projects/oedtk/


INSTALLATION
***************************************************************************
With ActivPerl distribution, you can use PPM to install oEdtk module.
With all perl distributions you can use CPAN to install oEdtk module.
At least, you can download the last release from http://www.cpan.org/

BEFORE installation, you have to setup XML-LibXML :
Checking if XML-LibXML is set :
Perl -e "use XML::LibXML"

- windows : you have to setup XML-LibXML with PPM
			you should also install dmake utils with PPM
- Linux   : you have to setup XML-LibXML with your distribution's
			package installer (or rpm / apt-get install)

Command line for manual installation :
perl Makefile.PL
make                # use 'dmake' on Win32 (install it with cpan or ppm)
make test
make install
make clean


CONTENT OF THIS ARCHIVE
***************************************************************************
Root files :
	Makefile.PL			Makefile for installation
	MANIFEST			Manifest for installation
	MANIFEST.SKIP			Skip files
	README.md			this file
	CHANGES				Change history

Library (lib/) :
	lib/oEdtk.pm			main module dedicated for documentation
	lib/oEdtk/			core modules of the toolkit
		AddrField.pm  C7Doc.pm  C7Tag.pm  Config.pm  DBAdmin.pm
		DateField.pm  Dict.pm  Doc.pm  EDMS.pm  FPField.pm
		FatalsToEmail.pm  Field.pm  Main.pm  Messenger.pm
		OmgrIdxDoc.pm  Outmngr.pm  Record.pm  RecordParser.pm
		Run.pm  SignedField.pm  Spool.pm  TexDoc.pm  TexTag.pm
		Tracking.pm  Tracking2.pm  Util.pm  XPath.pm  dataEdtk.pm
		libC7.pm  libDev.pm  libXls.pm  logger.pm  logger2.pm
		trackEdtk.pm  tuiEdtk.pm
		COPYING			GNU GENERAL PUBLIC LICENSE
		README			README of the library
	lib/oEdtk/iniEdtk/		configuration templates and dictionaries
		char_dico.ini  country_dico.ini  edtk_dico.ini
		postal_dico_FR.ini  snip_address.ini  tplate.edtk.ini
		mail.acq.txt  mail.bat.txt  mail.report.acq.txt
		mail.txt.prod  mail.txt.test
	lib/oEdtk/lang/			message catalogues : en, es, fr
	lib/oEdtk/lib/			helper scripts shipped with the toolkit
		acq_Check.pl  acq_Load.pl  check_oEdtk_ini.pl  cob2pm.pl
		db_Create_Acq_Table.pl  db_Create_Params_Table.pl
		db_Create_Tracking_Table.pl  db_Edit_Tracking_Table.pl
		db_Schema_init.pl  db_copy.pl  db_historicize_ALL.pl
		db_historicize_index.pl  db_historicize_tracking.pl  db_move.pl
		edms_process.pl  edms_runner.pl  ged_process.pl
		index_Block_refs.pl  index_Check_omgr.pl
		index_Check_tracked_docs.pl  index_Mail_referent.pl
		index_Purge_DCLIB.pl  index_Remise_en_poste.pl  index_Run_lot.pl
		index_Statistics.pl  params_Export.pl  params_Import.pl
		tracking_Statistics.pl  backup_compo_lmndv.sh  backup_editique.sh
		mep_compo.sh  mep_editique.sh  short_test.sh
		cgi-bin/		CGI front-ends
			edtk.cgi  edtk_ged.cgi  edtk_ged.html
			edtk_inged.cgi  edtk_para.cgi  index.html
		html/			HTML pages
			edtk_ged.html  edtk_inged.html  index.html
		template/		application templates
			runEdtk.pl  template_C7.oEdtk  template_Xls.oEdtk
			00-MODELES/	sample applications
				sample-excel-3.pl  sample-index-omgr.pl
				doc/exemple-excel.csv  doc/exemple-excel.csv.idx

Test suite (t/) :
	t/00_load.t  t/10_main_date.t  t/11_main_num.t  t/12_main_text.t
	t/20_fields.t  t/21_dict_tags.t  t/30_dbadmin_pure.t  t/31_dbadmin_sqlite.t
	t/40_tracking_validate.t  t/50_edms_pure.t
	t/lib/TestOEdtk.pm		test helpers
	t/test.t  t/test_fixe_oEdtk.pl  t/test_csv_pg_copy.pl
	t/cp_fr  t/cp_fr.dat  t/cp_fr_fixe.dat  t/edtk.ini


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


AUTHORS
***************************************************************************
D Aunay, G Chaillou Domingo, M Henrion, G Ballin 2005-2026


 oEdtk is Copyright (C) 2005-2026, G Chaillou Domingo, D Aunay, M Henrion, G Ballin
