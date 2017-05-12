#ifndef FAULT_TREE_H
#define FAULT_TREE_H

#ifdef WIN32
// Suppress warnings about debug identifiers being truncated to 255 characters
#pragma warning (disable:4786)
#endif

#include <set>
#include <string>
#include <iostream>

using namespace std;

#include "model/basic_types/bijection.h"
#include "model/fault_tree/replication.h"
#include "model/fault_tree/threshold.h"
#include "model/basic_types/event.h"
#include "model/fault_tree/input_sequence.h"
#include "model/fault_tree/inputs_map.h"
#include "model/fault_tree/threshold_map.h"
#include "model/fault_tree/replication_map.h"
#include "model/fault_tree/functional_dependency.h"

class Fault_Tree
{
public:
  Fault_Tree();
  Fault_Tree(const Fault_Tree& in_fault_tree);
  virtual ~Fault_Tree();

  const Fault_Tree& operator= (const Fault_Tree &in_fault_tree);

  friend bool operator< (const Fault_Tree& in_first, const Fault_Tree& in_second);
  friend bool operator==(const Fault_Tree& in_first, const Fault_Tree& in_second);
  friend bool operator!=(const Fault_Tree& in_first, const Fault_Tree& in_second);
  friend ostream& operator<< (ostream& in_ostream, const Fault_Tree& in_fault_tree);

  void Clear();

  // Inserting and removing events. This would be a lot simpler if we used
  // polymorphism. For now we'll stick to the specification.
  void Set_System_Event(const Event& in_system_event);
  void Unset_System_Event();

  void Insert_Basic_Event(const Event& in_basic_event,
                          const Replication& replication);

  void Insert_And_Gate(const Event& in_and_gate);
  void Insert_Or_Gate(const Event& in_or_gate);
  void Insert_Threshold_Gate(const Event& in_threshold_gate, const Threshold& in_threshold);
  void Insert_Pand_Gate(const Event& in_pand_gate);
  void Insert_Spare_Gate(const Event& in_spare_gate);
  void Insert_SEQ_Constraint(const Input_Sequence& in_sequence);
  void Insert_FDEP_Constraint(const Functional_Dependency& in_fdep);

  void Remove_Basic_Event(const Event& in_basic_event);

  void Remove_And_Gate(const Event& in_and_gate);
  void Remove_Or_Gate(const Event& in_or_gate);
  void Remove_Threshold_Gate(const Event& in_threshold_gate);
  void Remove_Pand_Gate(const Event& in_pand_gate);
  void Remove_Spare_Gate(const Event& in_spare_gate);
  void Remove_SEQ_Constraint(const Input_Sequence& in_sequence);
  void Remove_FDEP_Constraint(const Functional_Dependency& in_fdep);


  // Getting all the events and constraints of a certain type
  const set<Event>& Get_Basic_Events() const;

  const set<Event>& Get_And_Gates() const;
  const set<Event>& Get_Or_Gates() const;
  const set<Event>& Get_Threshold_Gates() const;
  const set<Event>& Get_Pand_Gates() const;
  const set<Event>& Get_Spare_Gates() const;

  const set<Event>& Get_Gates() const;
  const set<Event>& Get_Events() const;
  const Event& Get_System_Event() const;

  const set<Input_Sequence>& Get_SEQ_Constraints() const;
  const set<Functional_Dependency>& Get_FDEP_Constraints() const;

  const Replication_Map& Get_Replication_Map() const;


  // Setting and getting the inputs for a gate.
  void Set_Gate_Inputs(const Event& in_gate, const Input_Sequence& in_inputs);
  void Remove_Gate_Inputs(const Event& in_gate);
  const Input_Sequence& Get_Gate_Inputs(const Event& in_gate) const;
  const set<Event> Get_Gates_Event_Is_Input_To(const Event& in_event) const;
  const set<Event> Get_FDEP_Triggers_Of_Event(const Event& in_event) const;
  const set<Input_Sequence> Get_FDEP_Dependents_Of_Event(const Event& in_event) const;


  // Setting and getting the replication for an event
  void Set_Replication(const Event& in_event, const Replication& in_replication);
  const Replication& Get_Replication(const Event& in_event) const;

  // Setting and getting the threshold for a threshold gate
  void Set_Threshold(const Event& in_threshold_gate, const Threshold& in_threshold);
  const Threshold& Get_Threshold(const Event& in_threshold_gate) const;


  // Descriptions aren't in the spec, but are very useful
  void Set_Event_Description(const Event& in_event,const string& in_description);
  void Remove_Event_Description(const Event& in_event);
  const string& Get_Event_Description(const Event& in_event) const;
  const bijection<Event, string>& Get_Event_Descriptions() const;
  void Set_SEQ_Description(const Input_Sequence& in_seq,const string& in_description);
  void Remove_SEQ_Description(const Input_Sequence& in_seq);
  const string& Get_SEQ_Description(const Input_Sequence& in_seq) const;
  void Set_FDEP_Description(const Functional_Dependency& in_fdep, const string& in_description);
  void Remove_FDEP_Description(const Functional_Dependency& in_fdep);
  const string& Get_FDEP_Description(const Functional_Dependency& in_fdep) const;

  const bool Event_Not_Referenced(const Event &in_event);

protected:
  set<Event> basic_events;

  set<Event> and_gates;
  set<Event> or_gates;
  set<Event> threshold_gates;
  set<Event> pand_gates;
  set<Event> spare_gates;

  set<Input_Sequence> seq_constraints;
  set<Functional_Dependency> fdep_constraints;

  Threshold_Map thresholds;

  Inputs_Map inputs;

  set<Event> gates;
  set<Event> events;
  Event system_event;
  bool system_event_initialized;

  Replication_Map replications;

  // Descriptions aren't in the spec, but are very useful
  bijection<Event, string> event_descriptions;
  bijection<Input_Sequence, string> seq_descriptions;
  bijection<Functional_Dependency, string> fdep_descriptions;
};

inline bool operator<(const Fault_Tree& in_first, const Fault_Tree& in_second)
{
  if (in_first.system_event_initialized && in_second.system_event_initialized)
  {
    if (in_first.system_event < in_second.system_event)
      return true;
    else if (in_first.system_event != in_second.system_event)
      return false;
  }

  if (in_first.basic_events < in_second.basic_events)
    return true;
  else if (in_first.basic_events != in_second.basic_events)
    return false;

  if (in_first.and_gates < in_second.and_gates)
    return true;
  else if (in_first.and_gates != in_second.and_gates)
    return false;

  if (in_first.or_gates < in_second.or_gates)
    return true;
  else if (in_first.or_gates != in_second.or_gates)
    return false;

  if (in_first.threshold_gates < in_second.threshold_gates)
    return true;
  else if (in_first.threshold_gates != in_second.threshold_gates)
    return false;

  if (in_first.pand_gates < in_second.pand_gates)
    return true;
  else if (in_first.pand_gates != in_second.pand_gates)
    return false;

  if (in_first.spare_gates < in_second.spare_gates)
    return true;
  else if (in_first.spare_gates != in_second.spare_gates)
    return false;

  if (in_first.seq_constraints < in_second.seq_constraints)
    return true;
  else if (in_first.seq_constraints != in_second.seq_constraints)
    return false;

  if (in_first.fdep_constraints < in_second.fdep_constraints)
    return true;
  else if (in_first.fdep_constraints != in_second.fdep_constraints)
    return false;

  if (in_first.thresholds < in_second.thresholds)
    return true;
  else if (in_first.thresholds != in_second.thresholds)
    return false;

  if (in_first.inputs < in_second.inputs)
    return true;
  else if (in_first.inputs != in_second.inputs)
    return false;

  if (in_first.gates < in_second.gates)
    return true;
  else if (in_first.gates != in_second.gates)
    return false;

  if (in_first.events < in_second.events)
    return true;
  else if (in_first.events != in_second.events)
    return false;

  if (in_first.replications < in_second.replications)
    return true;
  else if (in_first.replications != in_second.replications)
    return false;

  if (in_first.event_descriptions < in_second.event_descriptions)
    return true;
  else if (in_first.event_descriptions != in_second.event_descriptions)
    return false;

  if (in_first.seq_descriptions < in_second.seq_descriptions)
    return true;
  else if (in_first.seq_descriptions != in_second.seq_descriptions)
    return false;

  if (in_first.fdep_descriptions < in_second.fdep_descriptions)
    return true;
  else
    return false;
}

inline bool operator==(const Fault_Tree& in_first, const Fault_Tree& in_second)
{
  return ((in_first.system_event_initialized == in_second.system_event_initialized) &&
          (!in_first.system_event_initialized ||
            (in_first.system_event == in_second.system_event)) &&
          (in_first.basic_events == in_second.basic_events) &&
          (in_first.and_gates == in_second.and_gates) &&
          (in_first.or_gates == in_second.or_gates) &&
          (in_first.threshold_gates == in_second.threshold_gates) &&
          (in_first.pand_gates == in_second.pand_gates) &&
          (in_first.spare_gates == in_second.spare_gates) &&
          (in_first.seq_constraints == in_second.seq_constraints) &&
          (in_first.fdep_constraints == in_second.fdep_constraints) &&
          (in_first.thresholds == in_second.thresholds) &&
          (in_first.inputs == in_second.inputs) &&
          (in_first.gates == in_second.gates) &&
          (in_first.events == in_second.events) &&
          (in_first.replications == in_second.replications) &&
          (in_first.event_descriptions == in_second.event_descriptions) &&
          (in_first.seq_descriptions == in_second.seq_descriptions) &&
          (in_first.fdep_descriptions == in_second.fdep_descriptions));
}

inline bool operator!=(const Fault_Tree& in_first, const Fault_Tree& in_second)
{
  return !(in_first == in_second);
}


inline const Fault_Tree& Fault_Tree::operator=(const Fault_Tree& in_fault_tree)
{
  system_event_initialized = in_fault_tree.system_event_initialized;
  system_event = in_fault_tree.system_event;

  basic_events = in_fault_tree.basic_events;

  and_gates = in_fault_tree.and_gates;
  or_gates = in_fault_tree.or_gates;
  threshold_gates = in_fault_tree.threshold_gates;
  pand_gates = in_fault_tree.pand_gates;
  spare_gates = in_fault_tree.spare_gates;

  seq_constraints = in_fault_tree.seq_constraints;
  fdep_constraints = in_fault_tree.fdep_constraints;

  thresholds = in_fault_tree.thresholds;

  inputs = in_fault_tree.inputs;

  gates = in_fault_tree.gates;
  events = in_fault_tree.events;

  replications = in_fault_tree.replications;

  event_descriptions = in_fault_tree.event_descriptions;
  seq_descriptions = in_fault_tree.seq_descriptions;
  fdep_descriptions = in_fault_tree.fdep_descriptions;

  return *this;
}

#endif // FAULT_TREE_H
