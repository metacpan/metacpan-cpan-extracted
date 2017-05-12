#ifndef INC_LANGUAGE_DEFINES_H
#define INC_LANGUAGE_DEFINES_H

static const struct
{
	char *friendlyname_eng;
	VARTYPE vt;	// Type, only VT_LPSTR
	ULONG ulKind;
	int IsOOo;
} writeable[] =
{
	{ "Title", VT_LPSTR, 0, 2 },
	{ "Author", VT_LPSTR, 0, 0 },
	{ "Keywords", VT_LPSTR, 0, 0 },
	{ "Comments", VT_LPSTR, 0, 0 },
	{ "Category", VT_LPSTR, 0, 0 },
	{ "Subject", VT_LPSTR, 0, 2 },
	{ "Description", VT_LPSTR, 0, 1 },
	{ "User Defined", VT_LPSTR, 0, 1 },
	{ "Company", VT_LPSTR, 0, 0 },
	{ "Manager", VT_LPSTR, 0, 0 },
	{ "Category", VT_LPSTR, 0, 0 }
};

// structure for Document Summary informations
static const struct
{
	char *friendlyname_eng;
	char *friendlyname_ger;
	unsigned int id;
	int docsummary;		// 1 Document Summary 0 Summary Information
} SummaryInformation[] = 
{
	{ "Category", "Kategorie", PIDDSI_CATEGORY, 1 },
	{ "PresentationTarget", "PresentationTarget", PIDDSI_PRESFORMAT, 1  },
	{ "Bytes", "Bytes", PIDDSI_BYTECOUNT, 1 },
	{ "Lines", "Zeilen", PIDDSI_LINECOUNT, 1 },
	{ "Paragraphs", "Paragraphen", PIDDSI_PARCOUNT, 1 },
	{ "Slides", "Folien", PIDDSI_SLIDECOUNT, 1 },
	{ "Notes", "Notes", PIDDSI_NOTECOUNT, 1 },
	{ "HiddenSlides", "Versteckte Folien", PIDDSI_HIDDENCOUNT, 1 },
	{ "MMClips", "MMClips", PIDDSI_MMCLIPCOUNT, 1 },
	{ "ScaleCrop", "ScaleCrop", PIDDSI_SCALE, 1 },
	{ "HeadingPairs", "HeadingPairs", PIDDSI_HEADINGPAIR, 1 },
	{ "TitlesofParts", "TitlesofParts", PIDDSI_DOCPARTS, 1 },
	{ "Manager", "Manager", PIDDSI_MANAGER, 1 },
	{ "Company", "Firma", PIDDSI_COMPANY, 1 },
	{ "LinksUpToDate", "LinksUpToDate", PIDDSI_LINKSDIRTY, 1 },
	{ "Title", "Titel", PIDSI_TITLE, 0 },
	{ "Subject", "Betreff", PIDSI_SUBJECT, 0 },
	{ "Author", "Autor", PIDSI_AUTHOR, 0 },
	{ "Keywords", "Stichwörter", PIDSI_KEYWORDS, 0 },
	{ "Comments", "Kommentare", PIDSI_COMMENTS, 0 },
	{ "Template", "Template", PIDSI_TEMPLATE, 0 },
	{ "Last Saved By", "Zuletzt gesichert von", PIDSI_LASTAUTHOR, 0 },
	{ "Revision Number", "Revisions Nummer", PIDSI_REVNUMBER, 0 },
	{ "Total Editing Time", "Gesamte Editierzeit", PIDSI_EDITTIME, 0 },
	{ "Last Printed", "Zuletzt gedruckt", PIDSI_LASTPRINTED, 0 },
	{ "Create Time/Date", "Erstell Zeit/Datum", PIDSI_CREATE_DTM, 0 },
	{ "Last saved Time/Date", "Letzte Sicherung", PIDSI_LASTSAVE_DTM, 0 },
	{ "Number of Pages", "Anzahl Seiten", PIDSI_PAGECOUNT, 0 },
	{ "Number of Words", "Anzahl Wörter", PIDSI_WORDCOUNT, 0 },
	{ "Number of Characters", "Anzahl Zeichen", PIDSI_CHARCOUNT, 0 },
	{ "Thumbnail", "Thumbnail", PIDSI_THUMBNAIL, 0 },
	{ "Name of Creating Application", "Name de Erstellprogrammes", PIDSI_APPNAME, 0 },
	{ "Security", "Sicherheit", PIDSI_DOC_SECURITY, 0 }
	
};

#endif