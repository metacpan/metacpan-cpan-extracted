#ifndef LIST_H
#define LIST_H

#include <ostream.h>
#include <assert.h>

// A template ordered list package, which is handy.
template <class T>
struct listnode {
	T entry;
	listnode<T> *prev, *next;
};

template <class T>
class list {
public:
	list(int func(T, T)): compare(func) { front=rear=NULL; }
	int IsEmpty() const { return front==NULL; }

	T First() const {
		assert(front!=NULL);
		return front->entry;
	}

	T Last() const {
		assert(rear!=NULL);
		return rear->entry;
	}

	T RemoveFirst() {
		assert(front!=NULL);
		listnode<T> *temp=front;
		T e=front->entry;

		front=front->next;
		if(front) front->prev=NULL;
		else rear=NULL;
		delete temp;
		return e;
	}

	T RemoveLast() {
		assert(rear!=NULL);
		listnode<T> *temp=rear;

		T e=rear->entry;
		rear=rear->prev;
		if(rear) rear->next=NULL;
		else front=NULL;
		delete temp;
		return e;
	}

	void Insert(T entry) {
		listnode<T> *temp=front;

		while((temp)&&(compare(temp->entry, entry)<0))
			temp=temp->next;
		if(temp) InsertBefore(temp, entry);
		else Append(entry);
	}

#ifdef PRINTING_OBJECTS
	void Print(ostream& os) const {
		listnode<T> *temp=front;

		os << "List entries:\n";
		while(temp) {
			os << "\t" << temp->entry;
			temp=temp->next;
		}
		os << endl;
	}
#endif
private:
	void Append(T entry) {
		listnode<T> *temp=new listnode<T>;

		temp->entry=entry;
		temp->prev=rear;
		temp->next=NULL;
		if(front==NULL) front=temp;
		else rear->next=temp;
		rear=temp;
	}

	void InsertAfter(listnode<T> *node, T entry) {
		listnode<T> *temp=new listnode<T>;

		temp->entry=entry;
		temp->prev=node;
		temp->next=node->next;
		node->next=temp;
		if(rear==node) rear=temp;
		else temp->next->prev=temp;
	}
	
	void InsertBefore(listnode<T> *node, T entry) {
		listnode<T> *temp=new listnode<T>;

		temp->entry=entry;
		temp->prev=node->prev;
		temp->next=node;
		node->prev=temp;
		if(front==node) front=temp;
		else temp->prev->next=temp;
	}
	
	listnode<T> *front, *rear;
	int (*compare)(T, T);	// should return <0 if T1<T2
};

#endif
