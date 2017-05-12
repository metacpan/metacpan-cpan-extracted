#ifndef __LIST_H
#define __LIST_H

#include <windows.h>


///////////////////////////////////////////////////////////////////////////////
//
// class forward declarations
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// class to store data and links
//
///////////////////////////////////////////////////////////////////////////////

class Node;

typedef Node *PNode;


///////////////////////////////////////////////////////////////////////////////
//
// class to store chained links
//
///////////////////////////////////////////////////////////////////////////////

class List;

typedef List *PList;


///////////////////////////////////////////////////////////////////////////////
//
// class definitions
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// class to store data and links
//
///////////////////////////////////////////////////////////////////////////////

class Node
{
  // allow access to protected members
  friend class List;

 protected:
  // default constructor
  Node();

  // constructor with chain members
  Node(PNode prev, PNode next, PVOID data, BOOL autoDel = FALSE);

  // destructor
  ~Node();

  // get and set prev, next, data or autodel members
  PNode Prev() const;
  PNode Prev(PNode prev);

  PNode Next() const;
  PNode Next(PNode next);

  PVOID Data() const;
  PVOID Data(PVOID data);

  BOOL AutoDel() const;
  BOOL AutoDel(BOOL autoDel);

 private:
  PNode m_Prev, m_Next;
  PVOID m_Data;
  BOOL m_AutoDel;
};


///////////////////////////////////////////////////////////////////////////////
//
// class to store chained links
//
///////////////////////////////////////////////////////////////////////////////

class List
{
 public:
  // default constructor
  List();

  // destructor
  ~List();

  // gets head, tail, prev and next members
  PNode HeadPos() const;
  PNode TailPos() const;
  PNode PrevPos(PNode node) const;
  PNode NextPos(PNode node) const;

  // data access; head, tail, prev, next and this
  PVOID Head() const;
  PVOID Head(PVOID data, BOOL autoDel = FALSE);
  PVOID Tail() const;
  PVOID Tail(PVOID data, BOOL autoDel = FALSE);
  PVOID Prev(PNode node) const;
  PVOID Prev(PNode node, PVOID data, BOOL autoDel = FALSE);
  PVOID Next(PNode node) const;
  PVOID Next(PNode node, PVOID data, BOOL autoDel = FALSE);
  PVOID This(PNode node) const;
  PVOID This(PNode node, PVOID data, BOOL autoDel = FALSE);

  // adds a node at head or at tail position
  PNode AddHead(PVOID data, BOOL autoDel = FALSE);
  PNode AddTail(PVOID data, BOOL autoDel = FALSE);

  // removes a node from the chain
  BOOL Remove(PNode node);

  // removes all nodes
  BOOL RemoveAll();

  // removes all nodes which data member is null
  BOOL Compress();

  // checks the interity of the chain
  BOOL Check();

  // returns the number of nodes in the list
  DWORD Items() const;

  // returns if the list is empty or not
  BOOL IsEmpty() const;

 private:
  PNode m_Head, m_Tail;
  DWORD m_Items;
  CRITICAL_SECTION m_CritSect;
};


///////////////////////////////////////////////////////////////////////////////
//
// class to iterate a list
//
///////////////////////////////////////////////////////////////////////////////

class ListItr
{
 public:
  // constructor
  ListItr(PList listPtr = NULL, BOOL setAtHead = TRUE);

  // destructor
  ~ListItr();

  // gets and sets the app. list
  PList List() const;
  PList List(PList listPtr, BOOL setAtHead = TRUE);

  // sets the iterator at the beginning of the list
  PNode Reset(BOOL setAtHead = TRUE);

  // operators to walk thougth the list
  PVOID operator ++ ();
  PVOID operator ++ (int);
  PVOID operator -- ();
  PVOID operator -- (int);

  // operator to see if the iterator points to a valid node
  operator int ();

 private:
  PList m_List;
  PNode m_Node;
};


#endif
