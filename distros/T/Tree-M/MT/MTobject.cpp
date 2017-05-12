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

#include <stdio.h>
#include "MTobject.h"

//double W[9]={1, 2, 1, 2, 4, 2, 2, 4, 2};

/*
int
Object::CompressedLength() const
{
	return(sizeof(int)+tot_term*(sizeof(float)+sizeof(int)));
}

int
Object::operator==(const Object &obj)
{
	Term_Weight *m=obj.lst_tw, *n=lst_tw;

	while(n&&m) {
		if((n->id_term)!=(m->id_term)) return 0;
		if((n->weight)!=(m->weight)) return 0;
		n=n->next;
		m=m->next;
	}
	if(n||m) return 0;
	return 1;
}

double
Object::distance(const Object& other) const
{
	double dist=0.0;
	double s=0, r=0, t=0, sim;
	Term_Weight *m=other.lst_tw, *n=lst_tw;

	compdists++;
	while(m&&n) {
		if(m->id_term==n->id_term) {
			s=s+(m->weight*n->weight);
			r=r+pow(m->weight, 2);
			t=t+pow(n->weight, 2);
			m=m->next;
			n=n->next;
		}
		else if(m->id_term<n->id_term) {
			r=r+pow(m->weight, 2);
			m=m->next;
		}
		else {
			t=t+pow(n->weight, 2);
			n=n->next;
		}
	}
	while(m) {
		r=r+pow(m->weight, 2);
		m=m->next;
	}
	while(n) {
		t=t+pow(n->weight, 2);
		n=n->next;
	}
	sim=s/sqrt(r*t);
	dist=sqrt(2*(1-sim));
	return dist;
}

Object *Read()
{
	char cmdLine[1024];
	int totTerm;
	Term_Weight *head, **tail=&head, *next;

//	scanf("%s", cmdLine);
	scanf("%s", cmdLine);
	totTerm=atoi(cmdLine);
	for(int i=0; i<totTerm; i++) {
		Term_Weight *node=new Term_Weight;

		scanf("%s", cmdLine);
		node->id_term=atoi(cmdLine);
		scanf("%s", cmdLine);
		node->weight=atof(cmdLine);
		*tail=node;
		tail=&(node->next);
	}
	*tail=NULL;
	Object *obj=new Object(head);

	for(Term_Weight *node=head; node; node=next) {
		next=node->next;
		delete node;
	}
	return obj;
}

Object *Read(FILE *fp)
{
	char cmdLine[1024];
	int totTerm;
	Term_Weight *head, **tail=&head, *next;

//	fscanf(fp, "%s", cmdLine);
	fscanf(fp, "%s", cmdLine);
	totTerm=atoi(cmdLine);
	for(int i=0; i<totTerm; i++) {
		Term_Weight *node=new Term_Weight;

		fscanf(fp, "%s", cmdLine);
		node->id_term=atoi(cmdLine);
		fscanf(fp, "%s", cmdLine);
		node->weight=atof(cmdLine);
		*tail=node;
		tail=&(node->next);
	}
	*tail=NULL;
	Object *obj=new Object(head);

	for(Term_Weight *node=head; node; node=next) {
		next=node->next;
		delete node;
	}
	return obj;
}

int sizeofObject()
{
	return 0;	// objects of different sizes
}

double maxDist()
{
	return sqrt(2);
}

#ifdef PRINTING_OBJECTS
void
Object::Print(ostream& os) const
{
	os << "(";
	for(Term_Weight *p=lst_tw; p; p=p->next) {
		os << p->id_term;
		os << ": " << p->weight << ", ";
	}
	os << ")";
}
#endif
*/

