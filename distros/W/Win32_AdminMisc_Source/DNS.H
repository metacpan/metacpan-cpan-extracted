	struct DNS_STRUCT{
		char	*szIP;
		char	*szName;
		long	lLastUse; 				//	Time of last referenced
	};
	typedef struct DNS_STRUCT	sDNS;

	sDNS *AddDNSCache(char *szName, char *szIP);
 	sDNS *CheckDNSCache(char *szIP);
 	char *ResolveSiteName(char *szHost);
	char *DupString(char *szString);
	int RemoveCache(int	iEntry, int iFlag);
	int ResetDNSCache();

#ifdef _DNS_H_

			//	Cache for DNS Resolution...
	#define DNSCACHELIMIT	600
	#define	NAME			00
	#define	IP				01

	char		*szBlank	= "";			//	Default blank string
	int			iEnableDNSCache = 1;
	sDNS		**sDNSCache; 		 	//	Cached site and name: sDNSCache[]
	int			iDNSCacheCount = 0;		//	Number of cache entries
	long		lDNSCacheTime = 0;		//	Current cache time (just a reference number)
	int			iDNSCacheLimit = DNSCACHELIMIT;
#else
	extern	int			iEnableDNSCache;
//	extern	struct sDNS	**sDNSCache; 
	extern	int			iDNSCacheCount;
	extern	long		lDNSCacheTime; 
	extern	int			iDNSCacheLimit;
#endif
