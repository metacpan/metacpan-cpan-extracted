#ifndef __LIST_CPP
#define __LIST_CPP

#include "list.h"


///////////////////////////////////////////////////////////////////////////////
//
// class implementation to store data and links
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// default constructor; creates an empty node 
//
// param: 
//
// result: none
//
///////////////////////////////////////////////////////////////////////////////

Node::Node()
{
  // prev, next and data are null
  m_Prev = m_Next = NULL;
  m_Data = NULL;

  // don't do an auto delete
  m_AutoDel = FALSE;
}


///////////////////////////////////////////////////////////////////////////////
//
// creates an node with an data value and connects to prev and next
//
// param: 
//
// result: none
//
///////////////////////////////////////////////////////////////////////////////

Node::Node(PNode prev, PNode next, PVOID data, BOOL autoDel)
{
  // connect node
  Prev(prev);
  Next(next);
	
  // set data value
  m_Data = data;

  // set auto delete flag
  m_AutoDel = autoDel;
}


///////////////////////////////////////////////////////////////////////////////
//
// destructor
//
// param: 
//
// result: none
//
///////////////////////////////////////////////////////////////////////////////

Node::~Node()
{
  // disconnect from list
  if(m_Prev)
    m_Prev->m_Next = m_Next;

  if(m_Next)
    m_Next->m_Prev = m_Prev;

  // if auto delete ist set delete data pointer
  if(m_Data && m_AutoDel)
    delete m_Data;

  m_Prev = m_Next = NULL;
  m_Data = NULL;
  m_AutoDel = FALSE;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the previous node
//
// param: 
//
// result: m_Prev
//
///////////////////////////////////////////////////////////////////////////////

PNode Node::Prev() const
{
  return m_Prev;
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the previous node and returns the node set
//
// param:  prev - previous node to set
//
// result: m_Prev
//
///////////////////////////////////////////////////////////////////////////////

PNode Node::Prev(PNode prev)
{
  if(prev)
    prev->m_Next = this;

  return m_Prev = prev;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the next node
//
// param: 
//
// result: m_Next
//
///////////////////////////////////////////////////////////////////////////////

PNode Node::Next() const
{
  return m_Next;
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the next node and returns the node set
//
// param:  next - previous node to set
//
// result: m_Next
//
///////////////////////////////////////////////////////////////////////////////

PNode Node::Next(PNode next)
{
  if(next)
    next->m_Prev = this;

  return m_Next = next;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the data value
//
// param: 
//
// result: m_Data
//
///////////////////////////////////////////////////////////////////////////////

PVOID Node::Data() const
{
  return m_Data;
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the data value and returns the data set
//
// param:  data - data value to set
//
// result: m_Data
//
///////////////////////////////////////////////////////////////////////////////

PVOID Node::Data(PVOID data)
{
  // if auto delete is set delete current data
  if(m_Data && m_AutoDel)
    delete m_Data;

  return m_Data = data;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the auto delete value
//
// param: 
//
// result: m_AutoDel
//
///////////////////////////////////////////////////////////////////////////////

BOOL Node::AutoDel() const
{
  return m_AutoDel;
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the auto delete value and returns the value set
//
// param:  autoDel - auto delete value to set
//
// result: m_AutoDel
//
///////////////////////////////////////////////////////////////////////////////

BOOL Node::AutoDel(BOOL autoDel)
{
  return m_AutoDel = autoDel;
}


///////////////////////////////////////////////////////////////////////////////
//
// class implementation to store chained links
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// default constructor; creates an empty list
//
// param:  
//
// result: 
//
///////////////////////////////////////////////////////////////////////////////

List::List()
{
  // first an last node are null
  m_Head = m_Tail = NULL;
  m_Items = 0;
	
  // initialize a critical section object
  InitializeCriticalSection(&m_CritSect);
}


///////////////////////////////////////////////////////////////////////////////
//
// destructor; removes all nodes in the list
//
// param:  
//
// result: 
//
///////////////////////////////////////////////////////////////////////////////

List::~List()
{
  RemoveAll();

  // free the critical section object
  DeleteCriticalSection(&m_CritSect);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the first node in the list
//
// param: 
//
// result: m_Head
//
///////////////////////////////////////////////////////////////////////////////

PNode List::HeadPos() const
{
  PNode headNode;

  //EnterCriticalSection(m_CritSect);
  headNode = m_Head;
  //LeaveCriticalSection(m_CritSect);

  return headNode;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the last node in the list
//
// param: 
//
// result: m_Tail
//
///////////////////////////////////////////////////////////////////////////////

PNode List::TailPos() const
{
  PNode tailNode;

  //EnterCriticalSection(m_CritSect);
  tailNode = m_Tail;
  //LeaveCriticalSection(m_CritSect);

  return tailNode;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the node before a node
//
// param:  node
//
// result: previous node from node ( if there is one) or null
//
///////////////////////////////////////////////////////////////////////////////

PNode List::PrevPos(PNode node) const
{
  PNode prevNode;

  //EnterCriticalSection(m_CritSect);
  prevNode = node ? node->Prev() : NULL;
  //LeaveCriticalSection(m_CritSect);

  return prevNode;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the node after a node
//
// param:  node
//
// result: next node from node ( if there is one) or null
//
///////////////////////////////////////////////////////////////////////////////

PNode List::NextPos(PNode node) const
{
  PNode nextNode;

  //EnterCriticalSection(m_CritSect);
  nextNode = node ? node->Next() : NULL;
  //LeaveCriticalSection(m_CritSect);

  return nextNode;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the data pointer from the first node in the list
//
// param:  
//
// result: data pointer from head ( if there is one) or null
//
///////////////////////////////////////////////////////////////////////////////

PVOID List::Head() const
{
  PVOID head;

  //EnterCriticalSection(m_CritSect);
  head = m_Head ? m_Head->Data() : NULL;
  //LeaveCriticalSection(m_CritSect);

  return head;
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the data pointer in the first node in the list
//
// param:  data    - data pointer to set
//         autoDel - turn autoDel on or off
//
// result: data pointer set
//
///////////////////////////////////////////////////////////////////////////////

PVOID List::Head(PVOID data, BOOL autoDel)
{
  if(m_Head) {
    // if auto delete is on we have to delete the old pointer
    if(m_Head->AutoDel() && m_Head->Data())
      delete m_Head->Data();

    m_Head->Data(data);
    m_Head->AutoDel(autoDel);
  }

  return m_Head ? m_Head->Data() : NULL;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the data pointer from the last node in the list
//
// param:  
//
// result: data pointer from tail ( if there is one) or null
//
///////////////////////////////////////////////////////////////////////////////

PVOID List::Tail() const
{
  return m_Tail ? m_Tail->Data() : NULL;
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the data pointer in the last node in the list
//
// param:  data    - data pointer to set
//         autoDel - turn autoDel on or off
//
// result: data pointer set
//
///////////////////////////////////////////////////////////////////////////////

PVOID List::Tail(PVOID data, BOOL autoDel)
{
  if(m_Tail) {
    // if auto delete is on we have to delete the old pointer
    if(m_Tail->AutoDel() && m_Tail->Data())
      delete m_Tail->Data();

    m_Tail->Data(data);
    m_Tail->AutoDel(autoDel);
  }

  return m_Tail ? m_Tail->Data() : NULL;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the data pointer from the node before node
//
// param:  node - current node
//
// result: data pointer from node before node ( if there is one) or null
//
///////////////////////////////////////////////////////////////////////////////

PVOID List::Prev(PNode node) const
{
  return node && node->Prev() ? node->Prev()->Data() : NULL;
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the data pointer in the node before node
//
// param:  node    - current node
//         data    - data pointer to set
//         autoDel - turn autoDel on or off
//
// result: data pointer set
//
///////////////////////////////////////////////////////////////////////////////

PVOID List::Prev(PNode node, PVOID data, BOOL autoDel)
{
  PNode prevNode = node ? node->Prev() : NULL;
	
  if(prevNode) {
    // if auto delete is set delete the old data pointer
    if(prevNode->AutoDel() && prevNode->Data())
      delete prevNode->Data();

    prevNode->Data(data);
    prevNode->AutoDel(autoDel);
  }

  return prevNode ? prevNode->Data() : NULL;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the data pointer from the node after node
//
// param:  node - current node
//
// result: data pointer from node after node ( if there is one) or null
//
///////////////////////////////////////////////////////////////////////////////

PVOID List::Next(PNode node) const
{
  return node && node->Next() ? node->Next()->Data() : NULL;
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the data pointer in the after before node
//
// param:  node    - current node
//         data    - data pointer to set
//         autoDel - turn autoDel on or off
//
// result: data pointer set
//
///////////////////////////////////////////////////////////////////////////////

PVOID List::Next(PNode node, PVOID data, BOOL autoDel)
{
  PNode nextNode = node ? node->Next() : NULL;
	
  if(nextNode) {
    // if auto delete is set delete the old data pointer
    if(nextNode->AutoDel() && nextNode->Data())
      delete nextNode->Data();

    nextNode->Data(data);
    nextNode->AutoDel(autoDel);
  }

  return nextNode ? nextNode->Data() : NULL;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the data pointer from node
//
// param:  node - current node
//
// result: data pointer from node ( if there is one) or null
//
///////////////////////////////////////////////////////////////////////////////

PVOID List::This(PNode node) const
{
  return node ? node->Data() : NULL;
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the data pointer in node
//
// param:  node    - current node
//         data    - data pointer to set
//         autoDel - turn autoDel on or off
//
// result: data pointer set
//
///////////////////////////////////////////////////////////////////////////////

PVOID List::This(PNode node, PVOID data, BOOL autoDel)
{
  if(node) {
    // if auto delete is set delete the old data pointer
    if(node->AutoDel() && node->Data())
      delete node->Data();

    node->Data(data);
    node->AutoDel(autoDel);
  }

  return node ? node->Data() : NULL;
}


///////////////////////////////////////////////////////////////////////////////
//
// creates a new node at head of list and stores the data pointer
//
// param:  data    - data pointer to set
//         autoDel - turn autoDel on or off
//
// result: pointer to created node
//
///////////////////////////////////////////////////////////////////////////////

PNode List::AddHead(PVOID data, BOOL autoDel)
{
  // alloc memory for the new node
  PNode node = new Node(NULL, m_Head, data, autoDel);
	
  if(node) {
    m_Head = node;

    // connect the node in the list
    if(!m_Tail)
      m_Tail = node;

    m_Items++;
  }

  return node;
}


///////////////////////////////////////////////////////////////////////////////
//
// creates a new node at head of list and stores the data pointer
//
// param:  data    - data pointer to set
//         autoDel - turn autoDel on or off
//
// result: pointer to created node
//
///////////////////////////////////////////////////////////////////////////////

PNode List::AddTail(PVOID data, BOOL autoDel)
{
  // alloc memory for the new node
  PNode node = new Node(m_Tail, NULL, data, autoDel);
	
  if(node) {
    // connect the node in the list
    if(!m_Head)
      m_Head = node;

    m_Tail = node;

    m_Items++;
  }

  return node;
}


///////////////////////////////////////////////////////////////////////////////
//
// removes a node from the list; there is no check, if the node belongs to the 
// list
//
// param:  node - node to remove
//
// result: true  - success
//         false - failure (node was null)
//
///////////////////////////////////////////////////////////////////////////////

BOOL List::Remove(PNode node)
{
  if(node) {
    // look on first and last postion of list
    if(node == m_Head)
      m_Head = node->Next();

    if(node == m_Tail)
      m_Tail = node->Prev();

    delete node;
    m_Items--;

    return TRUE;
  }

  return FALSE;
}


///////////////////////////////////////////////////////////////////////////////
//
// removes all nodes from the list
//
// param:  
//
// result: true  - success
//         false - failure
//
///////////////////////////////////////////////////////////////////////////////

BOOL List::RemoveAll()
{
  // clear all nodes
  for(PNode node = m_Head; node;) {
    PNode tmpNode = node->Next();

    delete node;

    node = tmpNode;
  }

  // reset list members
  m_Head = m_Tail = NULL;
  m_Items = 0;

  return TRUE;
}


///////////////////////////////////////////////////////////////////////////////
//
// removes all nodes from the list which data pointer are null 
//
// param:  
//
// result: true  - success
//         false - failure
//
///////////////////////////////////////////////////////////////////////////////

BOOL List::Compress()
{
  // clear all nodes if the data pointer is null
  for(PNode node = m_Head; node;) {
    PNode tmpNode = node->Next();

    if(!node->Data())
      Remove(node);

    node = tmpNode;
  }

  return TRUE;
}


///////////////////////////////////////////////////////////////////////////////
//
// checks the integrity of the list (first forward and then backward)
//
// param:  
//
// result: true  - success (integrity is ok)
//         false - failure (integrity has a failure)
//
///////////////////////////////////////////////////////////////////////////////

BOOL List::Check()
{
  {
    // first walk forward
    for(PNode node = m_Head; node; ) {
      if(node->Next() == m_Tail)
        break;

      if(!node->Next())
        return FALSE;
    }
  }
  // then walk backward
  for(PNode node = m_Tail; node; ) {
    if(node->Prev() == m_Head)
      break;

    if(!node->Prev())
      return FALSE;
  }

  return TRUE;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the number of nodes in the list
//
// param:  
//
// result: number of nodes
//
///////////////////////////////////////////////////////////////////////////////

DWORD List::Items() const
{
  return m_Items;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets if the list is empty or not
//
// param:  
//
// result: true  - list is empty
//         false - list is not empty
//
///////////////////////////////////////////////////////////////////////////////

BOOL List::IsEmpty() const
{
  return m_Items ? TRUE : FALSE;
}


///////////////////////////////////////////////////////////////////////////////
//
// class implementation to iterate a list
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// constructor for a list iterator
//
// param:  list      - pointer to a list
//         setAtHead - iterator begins at head
//
// result: 
//
///////////////////////////////////////////////////////////////////////////////

ListItr::ListItr(PList listPtr, BOOL setAtHead)
{
  m_Node = 
    (m_List = listPtr) ? setAtHead ? listPtr->HeadPos() : listPtr->TailPos() : NULL;
}


///////////////////////////////////////////////////////////////////////////////
//
// destructor for a list iterator
//
// param:  
//
// result: 
//
///////////////////////////////////////////////////////////////////////////////

ListItr::~ListItr()
{
}


///////////////////////////////////////////////////////////////////////////////
//
// returns a pointer to the list attached with the list iterator
//
// param:  
//
// result: pointer to attached list
//
///////////////////////////////////////////////////////////////////////////////

PList ListItr::List() const
{
  return m_List;
}


///////////////////////////////////////////////////////////////////////////////
//
// attaches a list with the list iterator
//
// param:  list      - pointer to list to attach
//         setAtHead - position where the iterator begins
//
// result: pointer to attached list
//
///////////////////////////////////////////////////////////////////////////////

PList ListItr::List(PList listPtr, BOOL setAtHead)
{
  m_Node = 
    (m_List = listPtr) ? setAtHead ? listPtr->HeadPos() : listPtr->TailPos() : NULL;

  return m_List;
}


///////////////////////////////////////////////////////////////////////////////
//
// resets the iterator at begin or end of the list
//
// param:  setAtHead - position where the iterator begins
//
// result: pointer to attached list
//
///////////////////////////////////////////////////////////////////////////////

PNode ListItr::Reset(BOOL setAtHead)
{
  return m_Node = 
    m_List ? setAtHead ? m_List->HeadPos() : m_List->TailPos() : NULL;
}


///////////////////////////////////////////////////////////////////////////////
//
// iteration operator for the list (pre-inkrement)
//
// param:  
//
// result: pointer the data for current node
//
///////////////////////////////////////////////////////////////////////////////

PVOID ListItr::operator ++ ()
{
  return (m_Node = m_List && m_Node ? m_List->NextPos(m_Node) : NULL) ? 
    m_List->This(m_Node) : NULL;
}


///////////////////////////////////////////////////////////////////////////////
//
// iteration operator for the list (post-inkrement)
//
// param:  
//
// result: pointer the data for current node
//
///////////////////////////////////////////////////////////////////////////////

PVOID ListItr::operator ++ (int)
{
  PVOID data = m_List && m_Node ? m_List->This(m_Node) : NULL;

  m_Node = m_List && m_Node ? m_List->NextPos(m_Node) : NULL;
	
  return data;
}


///////////////////////////////////////////////////////////////////////////////
//
// iteration operator for the list (pre-inkrement)
//
// param:  
//
// result: pointer the data for current node
//
///////////////////////////////////////////////////////////////////////////////

PVOID ListItr::operator -- ()
{
  return (m_Node = m_List && m_Node ? m_List->PrevPos(m_Node) : NULL) ? 
    m_List->This(m_Node) : NULL;
}


///////////////////////////////////////////////////////////////////////////////
//
// iteration operator for the list (post-inkrement)
//
// param:  
//
// result: pointer the data for current node
//
///////////////////////////////////////////////////////////////////////////////
PVOID ListItr::operator -- (int)
{
  PVOID data = m_List && m_Node ? m_List->This(m_Node) : NULL;

  m_Node = m_List && m_Node ? m_List->PrevPos(m_Node) : NULL;
	
  return data;
}


///////////////////////////////////////////////////////////////////////////////
//
// conversation operator for the list; checks if begin or end of list is reached
//
// param:  
//
// result: true  - begin or end is not reached
//         false - begin or end is reached
//
///////////////////////////////////////////////////////////////////////////////

ListItr::operator int ()
{
  return m_List && m_Node ? TRUE : FALSE;
}


#endif
