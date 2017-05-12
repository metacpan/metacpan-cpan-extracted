#include "defines.h"
#include "OOo.h"

char *Titles[] =
{
	"Number of Pages",	
	"Initial Creator",
	"Creator",
	"Comments",
	"Subject",
	"Language",
	"Date",
	"User Defined",
	"Creation Date",
	"Editing cycles",
	"Print Date",
	"Title",
	"Editing duration",
	"Keyword",
	"Table count",
	"Cell count",
	"Page count",
	"Paragraph count",
	"Word count",
	"Character count",
	"Image count",
	"Object count",
	"Ole object count",
};

mxml_type_t                             /* O - Data type */
    type_cb(mxml_node_t *node)              /* I - Element node */
    {
      const char    *type;                  /* Type string */


     /*
      * You can lookup attributes and/or use the element name, hierarchy, etc...
      */

      if ((type = mxmlElementGetAttr(node, "type")) == NULL)
	type = node->value.element.name;

      if (!strcmp(type, "integer"))
	return (MXML_INTEGER);
      else if (!strcmp(type, "opaque"))
	return (MXML_OPAQUE);
      else if (!strcmp(type, "real"))
	return (MXML_REAL);
      else
	return (MXML_TEXT);
    }



//********************************
// Constructor
//
OOo::OOo(void)
{
	
	m_errorcode = 0;
	m_oemcp = 1;
	m_tree = NULL;
	m_filepointer = NULL;
	m_Bufferlength = 0;
	
}

//********************************
// Destructor
// 
OOo::~OOo(void)
{
	if(m_buffer)
		free(m_buffer);
	
}


bool OOo::ConvertToAnsi(char *szUTF8, char *ansistr)
{
   // Convert to UNICODE:
   char *str;
   int size = MultiByteToWideChar(CP_UTF8, 0, szUTF8, -1, NULL, 0);
   if (size <= 0) return false;
   WCHAR *unicodeString = new WCHAR[size+1];
   size = MultiByteToWideChar(CP_UTF8, 0, szUTF8, -1, unicodeString, size+1);
   if (size <= 0) return false; // mem-leak!

   // Convert to ANSI:
 
   if(m_oemcp == 0) 
   {
	size = WideCharToMultiByte(CP_ACP, 0, unicodeString, -1, NULL, 0,NULL, NULL);
   	if (size <= 0) return false;
   	str = new char[size+1];
   
   	size = WideCharToMultiByte(CP_ACP, 0, unicodeString, -1, str,size+1, NULL, NULL);
   	if (size <= 0) return false; // mem-leak! 

   } else if(m_oemcp == 1)
   {
   	
	size = WideCharToMultiByte(CP_OEMCP, 0, unicodeString, -1, NULL, 0,NULL, NULL);
   	if (size <= 0) return false;
   	str = new char[size+1];
   
   	size = WideCharToMultiByte(CP_OEMCP, 0, unicodeString, -1, str,size+1, NULL, NULL);
   	if (size <= 0) return false; // mem-leak! 

   } else
    	return false;

	if(ansistr == NULL)
	{
		printf("Error ansistr == NULL\n");
		return false;
	}
    strcpy(ansistr,str);
    
	return true;
}


bool OOo::SetFile(FILE *filename)
{
	if(!filename) return false;
	m_filepointer = filename;
	return true;
}

//********************************
// Setting the buffer.
//
void OOo::SetBuffer(char *buff,bool oemcp)
{
	
	m_buffer = (char *)malloc(strlen(buff)*sizeof(char)+1);
	
	if(m_buffer==NULL) croak("Error allocating memmory!\n");
	
	m_Bufferlength = strlen(buff)+1;
	strcpy(m_buffer,buff);
	m_oemcp=oemcp;
}

//********************************
// Parsing the XML file
// 
bool OOo::ParseBuffer(HV *m_hv, AV *m_av)
{

	mxml_node_t *tmp, *node;
	mxml_index_t *ind;
	int errpos=0;
	int rv=0;
	m_Titles = m_av;
	SV *temp = NEWSV(0,0);
	char *buffer=(char*)malloc(m_Bufferlength);
	if(buffer == NULL) croak("Error allocating %d bytes\n", m_Bufferlength);
	
	ZeroMemory( buffer, m_Bufferlength);
	
	
    if(m_filepointer)
    {
       	m_tree=mxmlLoadFile(NULL, m_filepointer, MXML_NO_CALLBACK);
   		if(m_tree==NULL) return false;
    } else {
		m_tree=mxmlLoadString(NULL,m_buffer,type_cb);
		if(m_tree==NULL) return false; 
	}
		
	
	ind = mxmlIndexNew(m_tree,NULL,NULL);

	mxmlIndexReset(ind);
	
	ZeroMemory(  buffer, m_Bufferlength);
	
	node = mxmlIndexFind(ind, META_DOC_STAT_PAGE_COUNT,NULL);
	
	
	if(node)
	{
		
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child; 
				if(!ConvertToAnsi(node->value.text.string,buffer))
					return false;
				
				
				temp = newSVpvn( buffer, strlen(buffer));
				SvUTF8_on(temp);
				tmp = node->next;
				while(tmp) {
					if(tmp->type == MXML_TEXT)
					{
						sv_catpvn(temp, " ", strlen(" "));
						if(!ConvertToAnsi(tmp->value.text.string,buffer))
							return false;
						
						sv_catpvn(temp, buffer, strlen(buffer));
					}	
					tmp = tmp->next;
					
				}

				if(hv_store(m_hv, titles[10].RealName, (U32) strlen(titles[10].RealName),newSVsv(temp),0) == NULL)
					croak("Can not store in Hash!\n");
				av_push(m_Titles, newSVpvn(titles[10].RealName, strlen(titles[10].RealName)));
			} 
		}
	} //else
		//if(hv_store(m_hv, "Number of Pages", (U32) strlen("Number of Pages"),newSVpv("none",0),0) == NULL)
		//	croak("Can not store in Hash!\n");


	mxmlIndexReset(ind);
	node = mxmlIndexFind(ind, META_INITIAL_CREATOR,NULL);
	
	if(node)
	{
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child; 
				if(!ConvertToAnsi(node->value.text.string,buffer))
					return false;
				temp = newSVpvn( buffer, strlen(buffer));
				SvUTF8_on(temp);

				tmp = node->next;
				while(tmp) {
					if(tmp->type == MXML_TEXT)
					{
						sv_catpvn(temp, " ", strlen(" "));
						if(!ConvertToAnsi(tmp->value.text.string,buffer))
							return false;
						sv_catpvn(temp, buffer, strlen(buffer));
					}	
					tmp = tmp->next;
					
				}
				if(hv_store(m_hv, titles[8].RealName, (U32) strlen(titles[8].RealName),newSVsv(temp),0) == NULL)
					croak("Can not store in Hash!\n");

			} 
		}
	} else {
		if(hv_store(m_hv, titles[8].RealName, (U32) strlen(titles[8].RealName),newSVpv("none",0),0) == NULL)
			croak("Can not store in Hash!\n");

		av_push(m_Titles, newSVpvn(titles[8].RealName, strlen(titles[8].RealName)));
	}

	mxmlIndexReset(ind);
	node = mxmlIndexFind(ind, DC_CREATOR,NULL);
	
	if(node)
	{
		
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child; 
				if(!ConvertToAnsi(node->value.text.string,buffer))
					return false;

				temp = newSVpvn( buffer, strlen(buffer));
				
				SvUTF8_on(temp);
				tmp = node->next;
				while(tmp) {
					if(tmp->type == MXML_TEXT)
					{
						sv_catpvn(temp, " ", strlen(" "));
						if(!ConvertToAnsi(tmp->value.text.string,buffer))
							return false;

						sv_catpvn(temp, buffer, strlen(buffer));
						
					}	
					tmp = tmp->next;
					
				}
				
				if(hv_store(m_hv, titles[26].RealName, (U32) strlen(titles[26].RealName),newSVsv(temp),0) == NULL)
					croak("Can not store in Hash!\n");
					
			} 
		}
	} else
		if(hv_store(m_hv, titles[26].RealName, (U32) strlen(titles[26].RealName),newSVpv("none",0),0) == NULL)
			croak("Can not store in Hash!\n");

	av_push(m_Titles, newSVpvn(titles[26].RealName, strlen(titles[26].RealName)));

	mxmlIndexReset(ind);
	node = mxmlIndexFind(ind, DC_DESCRIPTION,NULL);
	
	if(node)
	{
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child; 
				if(!ConvertToAnsi(node->value.text.string,buffer))
						return false;
				
				temp = newSVpvn( buffer, strlen(buffer));
				
				SvUTF8_on(temp);
				tmp = node->next;
				while(tmp) {
					if(tmp->type == MXML_TEXT)
					{
						sv_catpvn(temp, " ", strlen(" "));
						if(!ConvertToAnsi(tmp->value.text.string,buffer))
							return false;
						
						sv_catpvn(temp, buffer, strlen(buffer));
						
					}	
					tmp = tmp->next;
					
				}
				if(hv_store(m_hv, titles[25].RealName, (U32) strlen(titles[25].RealName),newSVsv(temp),0) == NULL)
					croak("Can not store in Hash!\n");
			} 
		}
	} else
		if(hv_store(m_hv, titles[25].RealName, (U32) strlen(titles[25].RealName),newSVpv("none",0),0) == NULL)
			croak("Can not store in Hash!\n");

	av_push(m_Titles, newSVpvn(titles[25].RealName, strlen(titles[25].RealName)));

	mxmlIndexReset(ind);
	node = mxmlIndexFind(ind, DC_SUBJECT,NULL);
	
	if(node)
	{
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child; 
				if(!ConvertToAnsi(node->value.text.string,buffer))
					return false;
				temp = newSVpvn( buffer, strlen(buffer));
				
				SvUTF8_on(temp);
				tmp = node->next;
				while(tmp) {
					if(tmp->type == MXML_TEXT)
					{
						sv_catpvn(temp, " ", strlen(" "));
						if(!ConvertToAnsi(tmp->value.text.string,buffer))
							return false;
						sv_catpvn(temp, buffer, strlen(buffer));
						
					}	
					tmp = tmp->next;
					
				}
				if(hv_store(m_hv, titles[24].RealName, (U32) strlen(titles[24].RealName),newSVsv(temp),0) == NULL)
					croak("Can not store in Hash!\n");
			} 
		}
	} else
		if(hv_store(m_hv, titles[24].RealName, (U32) strlen(titles[24].RealName),newSVpv("none",0),0) == NULL)
			croak("Can not store in Hash!\n");

	av_push(m_Titles, newSVpvn(titles[24].RealName, strlen(titles[24].RealName)));

	mxmlIndexReset(ind);
	node = mxmlIndexFind(ind, DC_LANGUAGE,NULL);
	
	if(node)
	{
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child;
				if(!ConvertToAnsi(node->value.text.string,buffer))
						return false;
				if(hv_store(m_hv, titles[23].RealName, (U32) strlen(titles[23].RealName),newSVpv(buffer,0),0) == NULL)
					croak("Can not store in Hash!\n");
			} 
		}
	} else
		if(hv_store(m_hv, titles[23].RealName, (U32) strlen(titles[23].RealName),newSVpv("none",0),0) == NULL)
			croak("Can not store in Hash!\n");

	av_push(m_Titles, newSVpvn(titles[23].RealName, strlen(titles[23].RealName)));

	mxmlIndexReset(ind);
	node = mxmlIndexFind(ind, DC_DATE,NULL);
	
	if(node)
	{
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child;
				if(!ConvertToAnsi(node->value.text.string,buffer))
					return false;
				if(hv_store(m_hv, titles[22].RealName, (U32) strlen(titles[22].RealName),newSVpv(buffer,0),0) == NULL)
					croak("Can not store in Hash!\n");
			} 
		}
	} else
		if(hv_store(m_hv, titles[22].RealName, (U32) strlen(titles[22].RealName),newSVpv("none",0),0) == NULL)
			croak("Can not store in Hash!\n");

	av_push(m_Titles, newSVpvn(titles[22].RealName, strlen(titles[22].RealName)));

	mxmlIndexReset(ind);
	node = mxmlIndexFind(ind, META_USER_DEFINED,NULL);
	
	if(node)
	{
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child;
				if(!ConvertToAnsi(node->value.text.string,buffer))
					return false;
				if(hv_store(m_hv, titles[8].RealName, (U32) strlen(titles[8].RealName),newSVpv(buffer,0),0) == NULL)
					croak("Can not store in Hash!\n");
			} 
		}
	} else
		if(hv_store(m_hv, titles[8].RealName, (U32) strlen(titles[8].RealName),newSVpv("none",0),0) == NULL)
			croak("Can not store in Hash!\n");

	av_push(m_Titles, newSVpvn(titles[8].RealName, strlen(titles[8].RealName)));


	mxmlIndexReset(ind);
	node = mxmlIndexFind(ind, META_CREATION_DATE,NULL);
	
	if(node)
	{
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child;
				if(!ConvertToAnsi(node->value.text.string,buffer))
					return false;
				if(hv_store(m_hv, titles[2].RealName, (U32) strlen(titles[2].RealName),newSVpv(buffer,0),0) == NULL)
					croak("Can not store in Hash!\n");
			}
		}
	} else
		if(hv_store(m_hv, titles[2].RealName, (U32) strlen(titles[2].RealName),newSVpv("none",0),0) == NULL)
			croak("Can not store in Hash!\n");

	av_push(m_Titles, newSVpvn(titles[2].RealName, strlen(titles[2].RealName)));

	mxmlIndexReset(ind);
	node = mxmlIndexFind(ind, META_EDITING_CYCLES,NULL);
	
	if(node)
	{
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child;
				if(!ConvertToAnsi(node->value.text.string,buffer))
					return false;
				if(hv_store(m_hv, titles[4].RealName, (U32) strlen(titles[4].RealName),newSVpv(buffer,0),0) == NULL)
					croak("Can not store in Hash!\n");
			}
		}
	} else
		if(hv_store(m_hv, titles[4].RealName, (U32) strlen(titles[4].RealName),newSVpv("none",0),0) == NULL)
			croak("Can not store in Hash!\n");

	av_push(m_Titles, newSVpvn(titles[4].RealName, strlen(titles[4].RealName)));
		
	mxmlIndexReset(ind);
	node = mxmlIndexFind(ind, META_PRINT_DATE,NULL);
	
	if(node)
	{
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child;
				if(!ConvertToAnsi(node->value.text.string,buffer))
					return false;
				if(hv_store(m_hv, titles[3].RealName, (U32) strlen(titles[3].RealName),newSVpv(buffer,0),0) == NULL)
					croak("Can not store in Hash!\n");
			}
		}
	} else
		if(hv_store(m_hv, titles[3].RealName, (U32) strlen(titles[3].RealName),newSVpv("none",0),0) == NULL)
			croak("Can not store in Hash!\n");

	av_push(m_Titles, newSVpvn(titles[3].RealName, strlen(titles[3].RealName)));

	mxmlIndexReset(ind);
	node = mxmlIndexFind(ind, DC_TITLE,NULL);
	if(node)
	{
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child; 
				if(!ConvertToAnsi(node->value.text.string,buffer))
					return false;
				temp = newSVpvn( buffer, strlen(buffer));
				
				SvUTF8_on(temp);
				tmp = node->next;
				while(tmp) {
					if(tmp->type == MXML_TEXT)
					{
						sv_catpvn(temp, " ", strlen(" "));
						if(!ConvertToAnsi(tmp->value.text.string,buffer))
							return false;
						sv_catpvn(temp, buffer, strlen(buffer));
						
					}	
					tmp = tmp->next;
					
				}
				if(hv_store(m_hv, titles[21].RealName, (U32) strlen(titles[21].RealName),newSVsv(temp),0) == NULL)
					croak("Can not store in Hash!\n");
				
			}
		}
	} else
		if(hv_store(m_hv, titles[21].RealName, (U32) strlen(titles[21].RealName),newSVpv("none",0),0) == NULL)
			croak("Can not store in Hash!\n");

	av_push(m_Titles, newSVpvn(titles[21].RealName, strlen(titles[21].RealName)));


	mxmlIndexReset(ind);
	node = mxmlIndexFind(ind, META_EDITING_DURATION,NULL);
	if(node)
	{
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child;
				if(!ConvertToAnsi(node->value.text.string,buffer))
					return false;
				if(hv_store(m_hv, titles[5].RealName, (U32) strlen(titles[5].RealName),newSVpv(buffer,0),0) == NULL)
					croak("Can not store in Hash!\n");
			}
		}
	} else
		if(hv_store(m_hv, titles[5].RealName, (U32) strlen(titles[5].RealName),newSVpv("none",0),0) == NULL)
			croak("Can not store in Hash!\n");

	av_push(m_Titles, newSVpvn(titles[5].RealName, strlen(titles[5].RealName)));

	mxmlIndexReset(ind);
	node = mxmlIndexFind(ind, META_KEYWORD,NULL);
	if(node)
	{
		if(node->type == MXML_ELEMENT)
		{
			if(node->value.element.num_attrs == 0 && node->child->type == MXML_TEXT)
			{
				node = node->child; 
				if(!ConvertToAnsi(node->value.text.string,buffer))
					return false;
				temp = newSVpvn( buffer, strlen(buffer));
				
				tmp = node->next;
				while(tmp) {
					if(tmp->type == MXML_TEXT)
					{
						sv_catpvn(temp, " ", strlen(" "));
						if(!ConvertToAnsi(tmp->value.text.string,buffer))
							return false;
						sv_catpvn(temp, buffer, strlen(buffer));
						
					}	
					tmp = tmp->next;
					
				}

			}
		}
		if(hv_store(m_hv, titles[7].RealName, (U32) strlen(titles[7].RealName),newSVsv(temp),0) == NULL)
			croak("Can not store in Hash!\n");
	} else
		if(hv_store(m_hv, titles[7].RealName, (U32) strlen(titles[7].RealName),newSVpv("none",0),0) == NULL)
			croak("Can not store in Hash!\n");

	av_push(m_Titles, newSVpvn(titles[7].RealName, strlen(titles[7].RealName)));

	SummaryInfo(m_hv,m_tree);

	return true;
	
}

//********************************
// Document summary Info.
//
void OOo::SummaryInfo(HV *m_hv,mxml_node_t *m_tree)
{
	bool ret;
	mxml_node_t *temp = mxmlWalkNext(m_tree, m_tree, MXML_DESCEND);
	
	char *buffer = (char*)malloc(m_Bufferlength);
	char *name = (char*)malloc(m_Bufferlength);
	if(buffer == NULL || name==NULL) croak("Can not allocate %d bytes\n", m_Bufferlength);
	
	while(temp)
	{
			ret = DocumentSummary(temp, m_hv, name, buffer);
			temp = mxmlWalkNext(temp, m_tree, MXML_DESCEND);
	}
}

bool OOo::DocumentSummary(mxml_node_t *node, HV *m_hv, char *name, char *buffer)
{
	
	SV *temp = NEWSV(0,0);
	//mxml_node_t *tmp = new mxml_node_t;
	mxml_node_t *tmp = node;
	//memcpy((mxml_node_t*)tmp, (mxml_node_t*)node,sizeof(mxml_node_t));
	
	
	if(tmp->type==MXML_ELEMENT || tmp->type==4)
	{
		if((buffer = (char*)mxmlElementGetAttr(tmp, META_DOC_STAT_TABLE_COUNT)) != NULL) {
			if(hv_store(m_hv, titles[15].RealName, (U32)strlen(titles[15].RealName), newSVpv(buffer, 0),0) == NULL)
				croak("Can not store in Hash!\n");

		}

		if((buffer = (char*)mxmlElementGetAttr(tmp, META_DOC_STAT_CELL_COUNT)) != NULL) {
			if(hv_store(m_hv, titles[16].RealName, (U32)strlen(titles[16].RealName), newSVpv(buffer, 0),0) == NULL)
				croak("Can not store in Hash!\n");
		}

		if((buffer = (char*)mxmlElementGetAttr(tmp, META_DOC_STAT_PAGE_COUNT)) != NULL) {
			if(hv_store(m_hv, titles[10].RealName, (U32)strlen(titles[10].RealName), newSVpv(buffer, 0),0) == NULL)
				croak("Can not store in Hash!\n");
			
		}

		if((buffer = (char*)mxmlElementGetAttr(tmp, META_DOC_STAT_PARAGRAPH_COUNT)) != NULL) {
			if(hv_store(m_hv, titles[11].RealName, (U32)strlen(titles[11].RealName), newSVpv(buffer, 0),0) == NULL)
				croak("Can not store in Hash!\n");
		}

		if((buffer = (char*)mxmlElementGetAttr(tmp, META_DOC_STAT_WORD_COUNT)) != NULL) {
			if(hv_store(m_hv, titles[12].RealName, (U32)strlen(titles[12].RealName), newSVpv(buffer, 0),0) == NULL)
				croak("Can not store in Hash!\n");
		}

		if((buffer = (char*)mxmlElementGetAttr(tmp, META_DOC_STAT_CHARACTER_COUNT)) != NULL) {
			if(hv_store(m_hv, titles[13].RealName, (U32)strlen(titles[13].RealName), newSVpv(buffer, 0),0) == NULL)
				croak("Can not store in Hash!\n");
		}

		if((buffer = (char*)mxmlElementGetAttr(tmp, META_DOC_STAT_IMAGE_COUNT)) != NULL) {
			if(hv_store(m_hv, titles[14].RealName, (U32)strlen(titles[14].RealName), newSVpv(buffer, 0),0) == NULL)
				croak("Can not store in Hash!\n");
		}

		if((buffer = (char*)mxmlElementGetAttr(tmp, META_DOC_STAT_OBJECT_COUNT)) != NULL) {
			if(hv_store(m_hv, titles[17].RealName, (U32)strlen(titles[17].RealName), newSVpv(buffer, 0),0) == NULL)
				croak("Can not store in Hash!\n");
		}

		if((buffer = (char*)mxmlElementGetAttr(tmp, META_DOC_STAT_OLE_OBJECT_COUNT)) != NULL) {
			if(hv_store(m_hv, titles[18].RealName, (U32)strlen(titles[18].RealName), newSVpv(buffer, 0),0) == NULL)
				croak("Can not store in Hash!\n");
		}
		if((name = (char*)mxmlElementGetAttr(tmp, META_NAME)) != NULL)
		{
			
			if(tmp->child)
			{
				if(tmp->child->type==MXML_TEXT)
				{
					if(buffer == NULL)
						buffer=(char*)malloc(m_Bufferlength);

					tmp = tmp->child;
					while(tmp) {
						if(tmp->type == MXML_TEXT)
						{
							sv_catpvn(temp, " ", strlen(" "));
							if(!ConvertToAnsi(tmp->value.text.string,buffer))
								return false;
							sv_catpvn(temp, buffer, strlen(buffer));
						
						}	
						tmp = tmp->next;				
					}
					if(hv_store(m_hv, name, (U32) strlen(name),newSVsv(temp),0) == NULL)
						croak("Can not store in Hash!\n");
					
				}
			}
		}
	}
	return true;
}

	