char *substring(char *string, int start, size_t count);

/********************************************
* The Class definition
*/

class  
Summary {
	public: 
		Summary(char *File);
		~Summary();
		int IsWin2000OrNT(void);
		int IsStgFile(void);
		int IsNTFS(void);
		SV* Read(void);
		SV* Write(SV* newinfo);
		SV* GetError(void);
		int IsOOoFile(void) { return(m_IsOOo); }
		void SetOEMCP(int oemcp) { m_oemcp=oemcp; }
		SV* _GetTitles(void);
		int HasError(void)
		{
			return m_IsError;
		}

	private:
		void CheckIfOOoFile(char *f)
		{
			m_IsOOo = 0;
			char *tmp;
			int len = 0;
			len = strlen(f);
			tmp = substring(f, len-3, 3);
			if(strcmp(tmp,"odp") == 0 || strcmp(tmp,"odg") == 0 || strcmp(tmp,"odt") == 0 || strcmp(tmp,"ods") == 0 || strcmp(tmp,"sxw") == 0 || strcmp(tmp,"sxc") == 0 ) m_IsOOo = 1;
		}
		void HrToString(HRESULT hr, char *string);
		void PropertyPIDToCaption(PROPSPEC propspec, char *title, bool DocSum);
		int ReadDocSummaryInformation(void);
		int ReadSummaryInformation(void);
		void SetErr(char *msg);
		int ReadOOo(void);
		int GetLang(void);
		bool ConvertToAnsi(char *szUTF8, char *ansistr);
		BOOL AnsiToOem(char *text);
	private:
		wchar_t m_File[2048];
		char * m_wFile;
		char * m_ModulePath; // including shlash
		char m_perror[1024];
		HRESULT m_hr;
		IPropertySetStorage *m_ipStg;
		HV* m_hv;
		AV* m_av;
		int m_IsOOo;	// 1 if the file is an OpenOffice document
		bool m_IsError;
		bool m_oemcp;
		SV* m_ptResult;
};


#ifndef  NUMELEM
# define NUMELEM(p) (sizeof(p)/sizeof(*p))
#endif



/*
  function substring()
  Author:  Joe Wright
  Date:    11/17/1998
*/
#define LEN 512 
char *substring(char *string, int start, size_t count) {
   static char str[LEN];
   str[0] = '\0'; /* The NUL string error return */
   if (string != NULL) {
      size_t len = strlen(string);
      if (start < 0)
         start = len + start;
      if (start >= 0 && start < len) {
         if (count == 0 || count > len - start)
            count = len - start;
         if (count < LEN) {
            strncpy(str, string + start, count);
            str[count] = 0;
         }
      }
   }
   //printf("start == %u, count == %u\n", (unsigned)start,(unsigned)count);
   return str;

} 


