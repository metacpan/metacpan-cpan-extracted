#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "mxml.h"

static const struct
{
	const char *OOName;
	const char *RealName;
	int c;
} titles[] =
{
	{ META_NAME, 			"Name", 0},
	{ META_GENERATOR,		"Generator", 1},
	{ META_CREATION_DATE, 		"Creation Date", 2},
	{ META_PRINT_DATE,		"Print Date", 3},
	{ META_EDITING_CYCLES,		"Editing Cycles", 4 },
	{ META_EDITING_DURATION,	"Editing Duration", 5 },
	{ META_INITIAL_CREATOR,		"Initial Creator", 6 },
	{ META_KEYWORD,			"Keyword", 7 },
	{ META_USER_DEFINED,		"User Defined",8 },
	{ META_DOCUMENT_STATISTIC,	"Document Statistic",9 },
	{ META_DOC_STAT_PAGE_COUNT,	"Page Count",10 },
	{ META_DOC_STAT_PARAGRAPH_COUNT,"Paragraph Count",11 },
	{ META_DOC_STAT_WORD_COUNT,	"Word Count",12 },
	{ META_DOC_STAT_CHARACTER_COUNT,"Character Count",13 },
	{ META_DOC_STAT_IMAGE_COUNT,	"Image Count",14 },
	{ META_DOC_STAT_TABLE_COUNT,	"Table Count",15 },
	{ META_DOC_STAT_CELL_COUNT,	"Cell Count",16 },
	{ META_DOC_STAT_OBJECT_COUNT,	"Object Count",17 },
	{ META_DOC_STAT_OLE_OBJECT_COUNT,"Ole Object Count",18 },
	{ META_DOC_STAT_ROW_COUNT,	"Row Count",19 },
	{ META_DOC_STAT_DRAW_COUNT,	"Draw Count",20 },
	{ DC_TITLE,			"Title",21 },
	{ DC_DATE,			"Date",22 },
	{ DC_LANGUAGE,			"Language",23 },
	{ DC_SUBJECT,			"Subject",24 },
	{ DC_DESCRIPTION,		"Description",25 },
	{ DC_CREATOR,			"Creator",26 },
};




class OOo
{
	public:
		OOo(void);
		~OOo(void);
		bool SetFile(FILE *filename);
		void SetBuffer(char *buff, bool oemcp=1);
		bool ParseBuffer(HV *hv, AV *m_av);
	private:
	void SummaryInfo(HV *m_hv,mxml_node_t *m_tree);
	bool ConvertToAnsi(char *szUTF8, char *ansistr);
	bool DocumentSummary(mxml_node_t *node, HV* hv, char *name, char* buffer);

	char *m_buffer;
	SV *m_errorcode;
	AV *m_Titles;
	int m_utf8encoded;
	mxml_node_t *m_tree;
	FILE *m_filepointer;
	bool m_oemcp;
	int m_Bufferlength;
	
};
