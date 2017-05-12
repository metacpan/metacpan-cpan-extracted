# gh_nls-nl.pl -- 
# RCS Status      : $Id: gh_nls-nl.pl,v 1.11 2002-11-25 22:25:15+01 jv Exp $
# SCCS Status     : %Z%@ %M%	%I%
# Author          : Johan Vromans
# Created On      : Thu Jun 11 13:35:49 1992
# Last Modified By: Johan Vromans
# Last Modified On: Mon Nov 25 16:19:21 2002
# Update Count    : 37
# Status          : OK

# Native Language Support -- NL (Dutch)

# This file contains all info to support a language.
# It is used by genhdr.pl to generate laguage dependent include files.


# Official names for header keywords.
# These names will be rendered if needed.
#
our @hdr_name;
$hdr_name[$::HDR_NULL]        = '';
$hdr_name[$::HDR_ABSENT]      = 'Afwezig';
$hdr_name[$::HDR_AUTHOR]      = 'Auteur';
$hdr_name[$::HDR_CC]          = 'C.c.';
$hdr_name[$::HDR_CITY]        = 'Plaats';
$hdr_name[$::HDR_CLOSING]     = 'Groet';
$hdr_name[$::HDR_CMPY]        = 'Bedrijfscode';
$hdr_name[$::HDR_COMPANY]     = 'Bedrijf';
$hdr_name[$::HDR_DATE]        = 'Datum';
$hdr_name[$::HDR_DEPT]        = 'Afdeling';
$hdr_name[$::HDR_DOCID]       = 'Doc-Id';
$hdr_name[$::HDR_DOCUMENTSTYLE] = 'Documentopmaak';
$hdr_name[$::HDR_ENCL]        = 'Bijlage';
$hdr_name[$::HDR_FROM]        = 'Van';
$hdr_name[$::HDR_INDEX]       = 'Index';
$hdr_name[$::HDR_MEETING]     = 'Vergadering';
$hdr_name[$::HDR_MHID]        = 'MH-Id';
$hdr_name[$::HDR_NEXT]        = 'Volgdoc';
$hdr_name[$::HDR_NOTE]        = 'TechNote';
$hdr_name[$::HDR_NUMBER]      = 'Volgnummer';
$hdr_name[$::HDR_OFFERING]    = 'Offerte';
$hdr_name[$::HDR_OPENING]     = 'Aanhef';
$hdr_name[$::HDR_OK]          = 'Akkoord';
$hdr_name[$::HDR_OPTIONS]     = 'Opties';
$hdr_name[$::HDR_PHONE]       = 'Telefoon';
$hdr_name[$::HDR_PRESENT]     = 'Aanwezig';
$hdr_name[$::HDR_PROJECT]     = 'Project';
$hdr_name[$::HDR_REF]         = 'Referentie';
$hdr_name[$::HDR_SECR]        = 'Notulist';
$hdr_name[$::HDR_SECTION]     = 'Sectie';
$hdr_name[$::HDR_SLIDES]      = 'Presentatie';
$hdr_name[$::HDR_SUBJECT]     = 'Betreft';
$hdr_name[$::HDR_TITLE]       = 'Titel';
$hdr_name[$::HDR_TO]          = 'Aan';
$hdr_name[$::HDR_VERSION]     = 'Versie';

# Alternative names for header keywords.
# These names are recognized in input documents.
# They may include the official names also.
#
our %hdr_aliases =
    (
    # NL variants
    'Aan',		$::HDR_TO,
    'Aanhef',		$::HDR_OPENING,
    'Aanwezig',		$::HDR_PRESENT,
    'Accoord',		$::HDR_OK,
    'Afdeling',		$::HDR_DEPT,
    'Afwezig',		$::HDR_ABSENT,
    'Akkoord',		$::HDR_OK,
    'Auteur',		$::HDR_AUTHOR,
    'Auteurs',		$::HDR_AUTHOR,
    'Bedrijf',		$::HDR_COMPANY,
    'Bedrijfscode',	$::HDR_CMPY,
    'Betreft',		$::HDR_SUBJECT,
    'Bijl',		$::HDR_ENCL,
    'Bijl.',		$::HDR_ENCL,
    'Bijlage',		$::HDR_ENCL,
    'Bijlagen',		$::HDR_ENCL,
    'Brief',		$::HDR_REF,
    'Cc',		$::HDR_CC,
    'Datum',		$::HDR_DATE,
    'Docid',		$::HDR_DOCID,
    'Documentopmaak',	$::HDR_DOCUMENTSTYLE,
    'Firma',		$::HDR_COMPANY,
    'Firmacode',	$::HDR_CMPY,
    'Groep',		$::HDR_DEPT,
    'Groet',		$::HDR_CLOSING,
    'Kaart',		$::HDR_SECTION,
    'Mhid',		$::HDR_MHID,
    'Note',		$::HDR_NOTE,
    'Notulist',		$::HDR_SECR,
    'Nummer',		$::HDR_NUMBER,
    'Offerte',		$::HDR_OFFERING,
    'Optie',		$::HDR_OPTIONS,
    'Opties',		$::HDR_OPTIONS,
    'Options',		$::HDR_OPTIONS,
    'Plaats',		$::HDR_CITY,
    'Presentatie',	$::HDR_SLIDES,
    'Projekt',		$::HDR_PROJECT,
    'Ref',		$::HDR_REF,
    'Ref.',		$::HDR_REF,
    'Referentie',	$::HDR_REF,
    'Sectie',		$::HDR_SECTION,
    'Slides',		$::HDR_SLIDES,
    'Technote',		$::HDR_NOTE,
    'Tel',		$::HDR_PHONE,
    'Tel.',		$::HDR_PHONE,
    'Telefoon',		$::HDR_PHONE,
    'Titel',		$::HDR_TITLE,
    'Van',		$::HDR_FROM,
    'Vergadering',	$::HDR_MEETING,
    'Versie',		$::HDR_VERSION,
    'Volgdoc',		$::HDR_NEXT,
    'Volgnummer',	$::HDR_NUMBER,
     );		        

# Names of months, zero relative.
#
our @month_names =
    ('januari',	'februari',	'maart',
     'april',	'mei',		'juni',
     'juli',	'augustus',	'september',
     'oktober',	'november',	'december');

# Specify $nls_day_after_month if the desired date format is
# Month DD, Year instead of DD Month Year.
#
# $nls_day_after_month = 1;

# Text entries:
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
# PAT_CONFIGMGT   Detect configuration or status management (REPORT only)
# PAT_ANNOUNCE    Detect chapters that should start a new page (MREP only)

our @nls_table;
$nls_table[$TXT_LANG]		= 'Dutch';
$nls_table[$TXT_LANGUAGE]	= 'Nederlands';
$nls_table[$TXT_MEMO]		= 'Intern Memo';
$nls_table[$TXT_TOC]		= 'Inhoudsopgave';
$nls_table[$TXT_COS]		= 'Inhoud van Sectie';
$nls_table[$TXT_PAGE]		= 'pagina';
$nls_table[$TXT_SECTION]	= 'Sectie';
$nls_table[$TXT_MAP]		= 'Kaart';
$nls_table[$TXT_REF]		= 'Ref.';
$nls_table[$TXT_PHEXT]		= 'tst.';
$nls_table[$TXT_CLOSING]	= 'Met vriendelijke groeten,';
$nls_table[$TXT_CONFMGT]	= 'Configuratie-Management';
$nls_table[$TXT_CONFSTAT]	= 'Configuratie-status';
$nls_table[$TXT_DRAFT]		= ' CONCEPT ';
$nls_table[$TXT_INDEX]		= 'Index';

$nls_table[$FMT_MEETING]	= '%de Vergadering';

$nls_table[$PAT_CONFIGMGT]	= '^config.*(status|management)$';
$nls_table[$PAT_ANNOUNCE]	= '^(mededelingen|a[ck]tielijst|besluitenlijst)\s*$';
