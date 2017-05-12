# gh_nls-uk.pl -- 
# RCS Status      : $Id: gh_nls-uk.pl,v 1.11 2002-11-25 22:25:15+01 jv Exp $
# SCCS Status     : %Z%@ %M%	%I%
# Author          : Johan Vromans
# Created On      : Thu Jun 11 13:35:49 1992
# Last Modified By: Johan Vromans
# Last Modified On: Mon Mar  9 21:09:42 1998
# Update Count    : 29
# Status          : OK

# Native Language Support -- UK (English)

# This file contains all info to support a language.
# It is used by genhdr.pl to generate laguage dependent include files.


# Official names for header keywords.
# These names will be rendered if needed.
#
$hdr_name[$HDR_NULL]        = '';
$hdr_name[$HDR_ABSENT]      = 'Absent';
$hdr_name[$HDR_AUTHOR]      = 'Author';
$hdr_name[$HDR_CC]          = 'C.c.';
$hdr_name[$HDR_CITY]        = 'City';
$hdr_name[$HDR_CLOSING]     = 'Closing';
$hdr_name[$HDR_CMPY]        = 'Cmpny';
$hdr_name[$HDR_COMPANY]     = 'Company';
$hdr_name[$HDR_DATE]        = 'Date';
$hdr_name[$HDR_DEPT]        = 'Dept.';
$hdr_name[$HDR_DOCID]       = 'Doc-Id';
$hdr_name[$HDR_DOCUMENTSTYLE]       = 'Documentstyle';
$hdr_name[$HDR_ENCL]        = 'Enclosure';
$hdr_name[$HDR_FROM]        = 'From';
$hdr_name[$HDR_INDEX]       = 'Index';
$hdr_name[$HDR_MEETING]     = 'Meeting';
$hdr_name[$HDR_MHID]        = 'MH-Id';
$hdr_name[$HDR_NEXT]        = 'Next';
$hdr_name[$HDR_NOTE]        = 'TechNote';
$hdr_name[$HDR_NUMBER]      = 'Number';
$hdr_name[$HDR_OFFERING]    = 'Offering';
$hdr_name[$HDR_OPENING]     = 'Opening';
$hdr_name[$HDR_OK]          = 'Approved';
$hdr_name[$HDR_OPTIONS]     = 'Options';
$hdr_name[$HDR_PHONE]       = 'Phone';
$hdr_name[$HDR_PRESENT]     = 'Present';
$hdr_name[$HDR_PROJECT]     = 'Project';
$hdr_name[$HDR_REF]         = 'Reference';
$hdr_name[$HDR_SECR]        = 'Secretary';
$hdr_name[$HDR_SECTION]     = 'Section';
$hdr_name[$HDR_SLIDES]      = 'Sheets';
$hdr_name[$HDR_SUBJECT]     = 'Subject';
$hdr_name[$HDR_TITLE]       = 'Title';
$hdr_name[$HDR_TO]          = 'To';
$hdr_name[$HDR_VERSION]     = 'Version';

# Alternative names for header keywords.
# These names are recognized in input documents.
# They may include the official names also.
#
%hdr_aliases =
    (
    # UK variants
    'Enclosures',	$HDR_ENCL,
    # NL variants (for compatibility)
    'Aan',		$HDR_TO,
    'Aanhef',		$HDR_OPENING,
    'Aanwezig',		$HDR_PRESENT,
    'Accoord',		$HDR_OK,
    'Afdeling',		$HDR_DEPT,
    'Afwezig',		$HDR_ABSENT,
    'Akkoord',		$HDR_OK,
    'Auteur',		$HDR_AUTHOR,
    'Auteurs',		$HDR_AUTHOR,
    'Bedrijf',		$HDR_COMPANY,
    'Bedrijfscode',	$HDR_CMPY,
    'Betreft',		$HDR_SUBJECT,
    'Bijl',		$HDR_ENCL,
    'Bijl.',		$HDR_ENCL,
    'Bijlage',		$HDR_ENCL,
    'Bijlagen',		$HDR_ENCL,
    'Brief',		$HDR_REF,
    'Cc',		$HDR_CC,
    'Datum',		$HDR_DATE,
    'Department',	$HDR_DEPT,
    'Dept',		$HDR_DEPT,
    'Docid',		$HDR_DOCID,
    'Documentopmaak',	$HDR_DOCUMENTSTYLE,
    'Firma',		$HDR_COMPANY,
    'Firmacode',	$HDR_CMPY,
    'Groep',		$HDR_DEPT,
    'Groet',		$HDR_CLOSING,
    'Kaart',		$HDR_SECTION,
    'Mhid',		$HDR_MHID,
    'Note',		$HDR_NOTE,
    'Notulist',		$HDR_SECR,
    'Nummer',		$HDR_NUMBER,
    'Offerte',		$HDR_OFFERING,
    'Optie',		$HDR_OPTIONS,
    'Opties',		$HDR_OPTIONS,
    'Plaats',		$HDR_CITY,
    'Presentatie',	$HDR_SLIDES,
    'Projekt',		$HDR_PROJECT,
    'Ref',		$HDR_REF,
    'Ref.',		$HDR_REF,
    'Referentie',	$HDR_REF,
    'Sectie',		$HDR_SECTION,
    'Slides',		$HDR_SLIDES,
    'Technote',		$HDR_NOTE,
    'Tel',		$HDR_PHONE,
    'Tel.',		$HDR_PHONE,
    'Telefoon',		$HDR_PHONE,
    'Titel',		$HDR_TITLE,
    'Van',		$HDR_FROM,
    'Vergadering',	$HDR_MEETING,
    'Versie',		$HDR_VERSION,
    'Volgdoc',		$HDR_NEXT,
    'Volgnummer',	$HDR_NUMBER,
     );		        

# Names of months, zero relative.
#
@month_names =
    ('January',	'February',	'March',
     'April',	'May',		'June',
     'July',	'August',	'September',
     'October',	'November',	'December');

# Specify $nls_day_after_month if the desired date format is
# Month DD, Year instead of DD Month Year.
#
$nls_day_after_month = 1;

# Text entries
# TXT_LANG        TeX: to designate hyphenation strategy
# TXT_LANGUAGE    Feedback
# TXT_MEMO        Title of memo documents (MEMO only)
# TXT_TOC         Table of Contents (REPORT, NOTE, IMP, OFFERING)
# TXT_COS         Contents of Section (IMP only)
# TXT_PAGE        'page' (IMP only)
# TXT_SECTION     Section (IMP only)
# TXT_MAP         Map (IMP only)
# TXT_REF         Ref. (used in LETTERs and OFFERINGs)
# TXT_PHEXT       Phone extension (MEMO only)
# TXT_CLOSING     Closing text (LETTER only)
# TXT_DRAFT	  Overlay text for drafts
# TXT_INDEX	  Text for Index section

# Formats:
# FMT_MEETING     Meeting #NN (MREP only)

# Patterns:
# PAT_CONFIGMGT   Detect configuration or status management (MREP only)
# PAT_ANNOUNCE    Detect chapters that should start a new page (MREP only)

$nls_table[$TXT_LANG]		= 
$nls_table[$TXT_LANGUAGE]	= 'English';
$nls_table[$TXT_MEMO]		= 'Memorandum';
$nls_table[$TXT_TOC]		= 'Table of Contents';
$nls_table[$TXT_COS]		= 'Contents of Section';
$nls_table[$TXT_PAGE]		= 'page';
$nls_table[$TXT_SECTION]	= 'Section';
$nls_table[$TXT_MAP]		= 'Map';
$nls_table[$TXT_REF]		= 'Ref.';
$nls_table[$TXT_PHEXT]		= 'ext.';
$nls_table[$TXT_CLOSING]	= 'Yours sincerely,';
$nls_table[$TXT_CONFMGT]	= 'Configuration Management';
$nls_table[$TXT_CONFSTAT]	= 'Configuration status';
$nls_table[$TXT_DRAFT]		= 'D R A F T';
$nls_table[$TXT_INDEX]		= 'Index';

$nls_table[$FMT_MEETING]	= 'Meeting #%d';

$nls_table[$PAT_CONFIGMGT]	= '^config.*(status|management)$';
$nls_table[$PAT_ANNOUNCE]	= '^(announcements|actions|decisions)\s*$';
