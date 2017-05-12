/*********************************************************************
*                                                                    *
* Copyright (c) 1997,1998, 1999                                      *
* Multimedia DB Group and DEIS - CSITE-CNR,                          *
* University of Bologna, Bologna, ITALY.                             *
*                                                                    *
* All Rights Reserved.                                               *
*                                                                    *
* Permission to use, copy, and distribute this software and its      *
* documentation for NON-COMMERCIAL purposes and without fee is       *
* hereby granted provided  that this copyright notice appears in     *
* all copies.                                                        *
*                                                                    *
* THE AUTHORS MAKE NO REPRESENTATIONS OR WARRANTIES ABOUT THE        *
* SUITABILITY OF THE SOFTWARE, EITHER EXPRESS OR IMPLIED, INCLUDING  *
* BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY,      *
* FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. THE AUTHOR  *
* SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY LICENSEE AS A      *
* RESULT OF USING, MODIFYING OR DISTRIBUTING THIS SOFTWARE OR ITS    *
* DERIVATIVES.                                                       *
*                                                                    *
*********************************************************************/

#ifndef MTFILE_H
#define MTFILE_H

#include "GiSTstore.h"

//	MTfile is a simple storage class for GiSTs to work over 
//	UNIX/NT files. It is a copy of the GiSTfile class.

class MTfile: public GiSTstore {
	unsigned int page;
        struct Page {
          GiSTpage page;
          char *buf;
          int dirty;
          int seq;
        };
        Page *cache;
        unsigned int cachesize;

        Page *newpage(GiSTpage page);
        Page *findpage(GiSTpage page);
        void flushpage(Page *p);
public:
        void setcache(unsigned int pages);

	MTfile(unsigned int pagesize)
          : GiSTstore(), page(pagesize), cachesize(0)
          {
            setcache (16);
          }

        ~MTfile();

	void Create(const char *filename);
	void Open(const char *filename);
	void Close();

	void Read(GiSTpage page, char *buf);
	void Write(GiSTpage page, const char *buf);
	GiSTpage Allocate();
	void Deallocate(GiSTpage page);
	void Sync();
	int PageSize() const { return page; }

private:
	int fileHandle;
};

#endif
