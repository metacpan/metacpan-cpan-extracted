
#define	MASTER			0x00
#define	DAUGHTER		0x01

#define	FREE_ITEM		0xffffffff

#define	START_NUM_OF_DAUGHTERS	0x02
#define	START_NUM_OF_ODBCS		0x02

	class CMom{
		public:
			CMom();
			CMom(DWORD dThread);
			~CMom();
			int	Total();
			int	TotalElements();
			BOOL	Add(void *pObject);
			BOOL	Add(DWORD dID, void *pObject);
			int	Remove(DWORD dID);
			void *operator[](DWORD dID);
			DWORD operator[](void *pObject);

			static int	iTotalHistory;
			int	iHistory;

		private:
			int	InitMom();
			BOOL AddToList(DWORD dID, void *pObject);

			void	**pList;			//	List of Obect *'s
			DWORD	*pItems;		//	List of identifiers (connection #)
			int		iNumOfEntries;	//	0 to x
			int		iType;
			int		iNextID;
			int		iInUse;
	} typedef CMOM;

#ifdef _CMOM_
	CMOM *cMom = 0;
	CRITICAL_SECTION	gCSMom;
#else
	extern	CRITICAL_SECTION	gCSMom;	
#endif
