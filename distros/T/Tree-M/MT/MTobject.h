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

#ifndef MTOBJECT_H
#define MTOBJECT_H

extern int compdists;
extern int dimension;

#ifndef MIN
#define MIN(x, y) ((x<y)? (x): (y))
#define MAX(x, y) ((x>y)? (x): (y))
#endif

#include <stdio.h>
//#include <string.h>
#include "GiSTdefs.h"

/*
typedef struct term_weight {
	int id_term;
	float weight;
	struct term_weight *next;
} Term_Weight;

class Object : public GiSTobject	// the DB object class
{
public:
	int tot_term;
	Term_Weight	*lst_tw;

//	long wasted_space[100];	// only for debug purposes

	Object() {	// default constructor (needed)
		tot_term=0;
		lst_tw=NULL;
	}  

	Object(const Object& obj) {	// copy constructor (needed)
		Term_Weight **tail=&lst_tw;

		tot_term=obj.tot_term;
		for(Term_Weight *p=obj.lst_tw; p; p=p->next) {
			Term_Weight *m=new Term_Weight;

			m->id_term=p->id_term;
			m->weight=p->weight;
			*tail=m;
			tail=&(m->next);
		}
		*tail=NULL;
	}

	Object(char *key) {	// member constructor (needed)
		Term_Weight **tail=&lst_tw;

		memcpy(&tot_term, key, sizeof(int));
		for(int i=0; i<tot_term; i++) {
			Term_Weight *m=new Term_Weight;

			memcpy(&(m->id_term), key+sizeof(int)+i*(sizeof(int)+sizeof(float)), sizeof(int));
			memcpy(&(m->weight), key+sizeof(int)+i*(sizeof(int)+sizeof(float))+sizeof(int), sizeof(float));
			*tail=m;
			tail=&(m->next);
		}
		*tail=NULL;
	}

	Object(Term_Weight *p_x) {	// member constructor (needed)
		Term_Weight **tail=&lst_tw;

		tot_term=0;
		for(Term_Weight *p=p_x; p; p=p->next) {
			Term_Weight *m=new Term_Weight;

			m->id_term=p->id_term;
			m->weight=p->weight;
			tot_term++;
			*tail=m;
			tail=&(m->next);
		}
		*tail=NULL;
	}

	~Object() {	// destructor
		Term_Weight *p;

		for (Term_Weight *m=lst_tw; m; m=p) {
			p=m->next;
			delete m;
		}
	}

	Object& operator=(const Object& obj) {	// assignment operator (needed)
		Term_Weight *m, *p, **tail=&lst_tw;

		for (m=lst_tw; m; m=p) {
			p=m->next;
			delete m;
		}
		tot_term=obj.tot_term;
		for(p=obj.lst_tw; p; p=p->next) {
			m=new Term_Weight;
			m->id_term=p->id_term;
			m->weight=p->weight;
			*tail=m;
			tail=&(m->next);
		}
		*tail=NULL;
		return *this;
	}

	double area(double r) {	// only needed for statistic purposes (dependent on the metric, not applicable for non-vector metric spaces)
		return 0;
	};

	int operator==(const Object& obj);	// equality operator (needed)

	int operator!=(const Object& obj) { return !(*this==obj); };	// inequality operator (needed)

	double distance(const Object& other) const;	// distance method (needed)
	int CompressedLength() const;	// return the compressed size of this object
	void Compress(char *key) {	// object compression
		int i=0;

		memcpy(key, &tot_term, sizeof(int));
		for(Term_Weight *p=lst_tw; p; p=p->next) {
			memcpy(key+sizeof(int)+i*(sizeof(int)+sizeof(float)), &(p->id_term), sizeof(int));
			memcpy(key+sizeof(int)+i*(sizeof(int)+sizeof(float))+sizeof(int), &(p->weight), sizeof(float));
			i++;
		}
	}

#ifdef PRINTING_OBJECTS
	void Print(ostream& os) const;
#endif
};

double maxDist();	// return the maximum value for the distance between two objects
int sizeofObject();	// return the compressed size of each object (0 if objects have different sizes)

	Object *Read();	// read an object from standard input
	Object *Read(FILE *fp);	// read an object from a file
*/

#include "../object.h"

#endif
