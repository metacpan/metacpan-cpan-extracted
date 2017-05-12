#include "model/fault_tree/fault_tree.h"

#include <iostream>
#include <cassert>

using namespace std;

ostream& Output_Descriptive_Input_Sequence(ostream& in_ostream, const Fault_Tree& in_fault_tree, const Input_Sequence& in_input_sequence)
{
  Input_Sequence::const_iterator an_event;
  for (an_event = in_input_sequence.begin(); an_event != in_input_sequence.end(); an_event++)
  {
    in_ostream << in_fault_tree.Get_Event_Description(*an_event) << " (id: " << *an_event << ")";

    Input_Sequence::const_iterator next_event(an_event);
    next_event++;
    if (next_event != in_input_sequence.end())
      in_ostream << ", ";
  }

  return in_ostream;
}

// This output function uses a custom input sequence output routine that
// prints event descriptions (from the fault tree) instead of relying on the
// default << output of Input_Sequence.
ostream& operator<< (ostream& in_ostream, const Fault_Tree& in_fault_tree)
{
  in_ostream << "== System event:" << endl;
  in_ostream << in_fault_tree.Get_Event_Description(in_fault_tree.Get_System_Event()) << " (id: " << in_fault_tree.Get_System_Event() << ", replication: " <<
    in_fault_tree.Get_Replication(in_fault_tree.Get_System_Event()) << ")" << endl;

  in_ostream << "== Basic events:" << endl;
  if (in_fault_tree.Get_Basic_Events().size() > 0)
  {
    set<Event>::const_iterator an_event;

    for (an_event = in_fault_tree.Get_Basic_Events().begin(); an_event != in_fault_tree.Get_Basic_Events().end(); an_event++)
      in_ostream << in_fault_tree.Get_Event_Description(*an_event) << " (id: " << *an_event << ", replication: " <<
        in_fault_tree.Get_Replication(*an_event) << ")" << endl;
  }
  else
    in_ostream << "<NONE>" << endl;

  in_ostream << "== AND gates:" << endl;
  if (in_fault_tree.Get_And_Gates().size() > 0)
  {
    set<Event>::const_iterator an_event;

    for (an_event = in_fault_tree.Get_And_Gates().begin(); an_event != in_fault_tree.Get_And_Gates().end(); an_event++)
    {
      in_ostream << in_fault_tree.Get_Event_Description(*an_event) << " (id: " << *an_event << ", replication: " <<
        in_fault_tree.Get_Replication(*an_event) << ", inputs: ";
      Output_Descriptive_Input_Sequence(in_ostream, in_fault_tree, in_fault_tree.Get_Gate_Inputs(*an_event));
      in_ostream << ")" << endl;
    }
  }
  else
    in_ostream << "<NONE>" << endl;

  in_ostream << "== OR gates:" << endl;
  if (in_fault_tree.Get_Or_Gates().size() > 0)
  {
    set<Event>::const_iterator an_event;

    for (an_event = in_fault_tree.Get_Or_Gates().begin(); an_event != in_fault_tree.Get_Or_Gates().end(); an_event++)
    {
      in_ostream << in_fault_tree.Get_Event_Description(*an_event) << " (id: " << *an_event << ", replication: " <<
        in_fault_tree.Get_Replication(*an_event) << ", inputs: ";
      Output_Descriptive_Input_Sequence(in_ostream, in_fault_tree, in_fault_tree.Get_Gate_Inputs(*an_event));
      in_ostream << ")" << endl;
    }
  }
  else
    in_ostream << "<NONE>" << endl;

  in_ostream << "== PAND gates:" << endl;
  if (in_fault_tree.Get_Pand_Gates().size() > 0)
  {
    set<Event>::const_iterator an_event;

    for (an_event = in_fault_tree.Get_Pand_Gates().begin(); an_event != in_fault_tree.Get_Pand_Gates().end(); an_event++)
    {
      in_ostream << in_fault_tree.Get_Event_Description(*an_event) << " (id: " << *an_event << ", replication: " <<
        in_fault_tree.Get_Replication(*an_event) << ", inputs: ";
      Output_Descriptive_Input_Sequence(in_ostream, in_fault_tree, in_fault_tree.Get_Gate_Inputs(*an_event));
      in_ostream << ")" << endl;
    }
  }
  else
    in_ostream << "<NONE>" << endl;

  in_ostream << "== Spare gates:" << endl;
  if (in_fault_tree.Get_Spare_Gates().size() > 0)
  {
    set<Event>::const_iterator an_event;

    for (an_event = in_fault_tree.Get_Spare_Gates().begin(); an_event != in_fault_tree.Get_Spare_Gates().end(); an_event++)
    {
      in_ostream << in_fault_tree.Get_Event_Description(*an_event) << " (id: " << *an_event << ", replication: " <<
        in_fault_tree.Get_Replication(*an_event) << ", inputs: ";
      Output_Descriptive_Input_Sequence(in_ostream, in_fault_tree, in_fault_tree.Get_Gate_Inputs(*an_event));
      in_ostream << ")" << endl;
    }
  }
  else
    in_ostream << "<NONE>" << endl;

  in_ostream << "== Threshold gates:" << endl;
  if (in_fault_tree.Get_Threshold_Gates().size() > 0)
  {
    // This is like Output_Descriptive_Input_Sequence, but also includes the
    // threshold value of the threshold gate.
    set<Event>::const_iterator an_event;

    for (an_event = in_fault_tree.Get_Threshold_Gates().begin(); an_event != in_fault_tree.Get_Threshold_Gates().end(); an_event++)
    {
      in_ostream << in_fault_tree.Get_Event_Description(*an_event) << " (id: " << *an_event << ", replication: " <<
        in_fault_tree.Get_Replication(*an_event) << ", inputs: ";
      Output_Descriptive_Input_Sequence(in_ostream, in_fault_tree, in_fault_tree.Get_Gate_Inputs(*an_event));
      in_ostream << ", threshold: " << in_fault_tree.Get_Threshold(*an_event);
      in_ostream << ")" << endl;
    }
  }
  else
    in_ostream << "<NONE>" << endl;

  in_ostream << "== SEQ constraints:" << endl;
  if (in_fault_tree.Get_SEQ_Constraints().size() > 0)
  {
    set<Input_Sequence>::const_iterator an_seq;
    for (an_seq = in_fault_tree.Get_SEQ_Constraints().begin(); an_seq != in_fault_tree.Get_SEQ_Constraints().end(); an_seq++)
    {
      Output_Descriptive_Input_Sequence(in_ostream, in_fault_tree, *an_seq);
      in_ostream << endl;
    }
  }
  else
    in_ostream << "<NONE>" << endl;

  in_ostream << "== FDEP constraints:" << endl;
  if (in_fault_tree.Get_FDEP_Constraints().size() > 0)
  {
    set<Functional_Dependency>::const_iterator an_fdep;
    for (an_fdep = in_fault_tree.Get_FDEP_Constraints().begin(); an_fdep != in_fault_tree.Get_FDEP_Constraints().end(); an_fdep++)
    {
      in_ostream << in_fault_tree.Get_Event_Description((*an_fdep).Get_Trigger()) << " (id: " << (*an_fdep).Get_Trigger() << ") -> ";
      Output_Descriptive_Input_Sequence(in_ostream, in_fault_tree, (*an_fdep).Get_Dependents());
      in_ostream << endl;
    }
  }
  else
    in_ostream << "<NONE>" << endl;

  return in_ostream;
}

Fault_Tree::Fault_Tree()
{
  system_event_initialized = false;
}

Fault_Tree::Fault_Tree(const Fault_Tree& in_fault_tree)
{
  *this = in_fault_tree;
}

Fault_Tree::~Fault_Tree()
{
}

void Fault_Tree::Clear()
{
  basic_events.clear();
  and_gates.clear();
  or_gates.clear();
  threshold_gates.clear();
  pand_gates.clear();
  spare_gates.clear();
  seq_constraints.clear();
  fdep_constraints.clear();
  thresholds.clear();
  inputs.clear();
  gates_input_to.clear();
  gates.clear();
  events.clear();
  replications.clear();
  event_descriptions.clear();
  seq_descriptions.clear();
  fdep_descriptions.clear();

  system_event_initialized = false;
}

void Fault_Tree::Set_System_Event(const Event& in_system_event)
{
  system_event = in_system_event;
  system_event_initialized = true;
}

void Fault_Tree::Unset_System_Event()
{
  Event unknown;
  system_event = unknown;
  system_event_initialized = false;
}

void Fault_Tree::Insert_Basic_Event(const Event& in_basic_event,
                            const Replication& in_replication)
{
  basic_events.insert(in_basic_event);
  events.insert(in_basic_event);
  replications[in_basic_event] = in_replication;
}

void Fault_Tree::Insert_And_Gate(const Event& in_and_gate)
{
  and_gates.insert(in_and_gate);
  gates.insert(in_and_gate);
  events.insert(in_and_gate);
  replications[in_and_gate] = 1;
}

void Fault_Tree::Insert_Or_Gate(const Event& in_or_gate)
{
  or_gates.insert(in_or_gate);
  gates.insert(in_or_gate);
  events.insert(in_or_gate);
  replications[in_or_gate] = 1;
}

void Fault_Tree::Insert_Threshold_Gate(const Event& in_threshold_gate,
                           const Threshold& in_threshold)
{
  threshold_gates.insert(in_threshold_gate);
  gates.insert(in_threshold_gate);
  events.insert(in_threshold_gate);
  thresholds[in_threshold_gate] = in_threshold;
  replications[in_threshold_gate] = 1;
}

void Fault_Tree::Insert_Pand_Gate(const Event& in_pand_gate)
{
  pand_gates.insert(in_pand_gate);
  gates.insert(in_pand_gate);
  events.insert(in_pand_gate);
  replications[in_pand_gate] = 1;
}

void Fault_Tree::Insert_Spare_Gate(const Event& in_spare_gate)
{
  spare_gates.insert(in_spare_gate);
  gates.insert(in_spare_gate);
  events.insert(in_spare_gate);
  replications[in_spare_gate] = 1;
}

void Fault_Tree::Insert_SEQ_Constraint(const Input_Sequence& in_sequence)
{
  seq_constraints.insert(in_sequence);
}

void Fault_Tree::Insert_FDEP_Constraint(const Functional_Dependency& in_fdep)
{
  fdep_constraints.insert(in_fdep);
}

void Fault_Tree::Remove_Basic_Event(const Event& in_basic_event)
{
  basic_events.erase(in_basic_event);
  events.erase(in_basic_event);
  replications.erase(in_basic_event);
}

void Fault_Tree::Remove_And_Gate(const Event& in_and_gate)
{
  and_gates.erase(in_and_gate);
  gates.erase(in_and_gate);
  events.erase(in_and_gate);
}

void Fault_Tree::Remove_Or_Gate(const Event& in_or_gate)
{
  or_gates.erase(in_or_gate);
  gates.erase(in_or_gate);
  events.erase(in_or_gate);
}

void Fault_Tree::Remove_Threshold_Gate(const Event& in_threshold_gate)
{
  threshold_gates.erase(in_threshold_gate);
  gates.erase(in_threshold_gate);
  events.erase(in_threshold_gate);
  thresholds.erase(in_threshold_gate);
}

void Fault_Tree::Remove_Pand_Gate(const Event& in_pand_gate)
{
  pand_gates.erase(in_pand_gate);
  gates.erase(in_pand_gate);
  events.erase(in_pand_gate);
}

void Fault_Tree::Remove_Spare_Gate(const Event& in_spare_gate)
{
  spare_gates.erase(in_spare_gate);
  gates.erase(in_spare_gate);
  events.erase(in_spare_gate);
}

void Fault_Tree::Remove_SEQ_Constraint(const Input_Sequence& in_sequence)
{
  seq_constraints.erase(in_sequence);
}

void Fault_Tree::Remove_FDEP_Constraint(const Functional_Dependency& in_fdep)
{
  fdep_constraints.erase(in_fdep);
}

const set<Event>& Fault_Tree::Get_Basic_Events() const
{
  return basic_events;
}

const set<Event>& Fault_Tree::Get_And_Gates() const
{
  return and_gates;
}

const set<Event>& Fault_Tree::Get_Or_Gates() const
{
  return or_gates;
}

const set<Event>& Fault_Tree::Get_Threshold_Gates() const
{
  return threshold_gates;
}

const set<Event>& Fault_Tree::Get_Pand_Gates() const
{
  return pand_gates;
}

const set<Event>& Fault_Tree::Get_Spare_Gates() const
{
  return spare_gates;
}

const set<Event>& Fault_Tree::Get_Gates() const
{
  return gates;
}

const set<Event>& Fault_Tree::Get_Events() const
{
  return events;
}

const Event& Fault_Tree::Get_System_Event() const
{
  assert(system_event_initialized);

  return system_event;
}

const set<Input_Sequence>& Fault_Tree::Get_SEQ_Constraints() const
{
  return seq_constraints;
}

const set<Functional_Dependency>& Fault_Tree::Get_FDEP_Constraints() const
{
  return fdep_constraints;
}

const Replication_Map& Fault_Tree::Get_Replication_Map() const
{
  return replications;
}

void Fault_Tree::Set_Gate_Inputs(const Event& in_gate, const Input_Sequence& in_inputs)
{
  inputs[in_gate] = in_inputs;

  Input_Sequence::const_iterator an_input;
  for (an_input = in_inputs.begin(); an_input != in_inputs.end(); an_input++)
    gates_input_to[*an_input].insert(in_gate);
}

void Fault_Tree::Remove_Gate_Inputs(const Event& in_gate)
{
  Input_Sequence::const_iterator an_input;
  for (an_input = inputs[in_gate].begin(); an_input != inputs[in_gate].end(); an_input++)
    gates_input_to[*an_input].erase(in_gate);

  inputs.erase(in_gate);
}

const Input_Sequence& Fault_Tree::Get_Gate_Inputs(const Event& in_gate) const
{
  assert(inputs.find(in_gate) != inputs.end());

  return (*inputs.find(in_gate)).second;
}

const set<Event>& Fault_Tree::Get_Gates_Event_Is_Input_To(const Event& in_event) const
{
  static set<Event> empty;

  if(gates_input_to.find(in_event) == gates_input_to.end())
    return empty;

  return (*gates_input_to.find(in_event)).second;
}

const set<Event> Fault_Tree::Get_FDEP_Triggers_Of_Event(const Event& in_event) const
{
  set<Event> triggers_of_event;

  const set<Functional_Dependency> fault_tree_fdeps = Get_FDEP_Constraints();

  set<Functional_Dependency>::const_iterator an_fdep;
  for (an_fdep = fault_tree_fdeps.begin(); an_fdep != fault_tree_fdeps.end(); an_fdep++)
  {
    Input_Sequence dependents = (*an_fdep).Get_Dependents();

    if (dependents.find(in_event) != dependents.end())
      triggers_of_event.insert((*an_fdep).Get_Trigger());
  }

  return triggers_of_event;
}


const set<Input_Sequence> Fault_Tree::Get_FDEP_Dependents_Of_Event(const Event& in_event) const
{
  set<Input_Sequence> dependents_of_event;

  const set<Functional_Dependency> fault_tree_fdeps = Get_FDEP_Constraints();

  set<Functional_Dependency>::const_iterator an_fdep;
  for (an_fdep = fault_tree_fdeps.begin(); an_fdep != fault_tree_fdeps.end(); an_fdep++)
  {
    if ((*an_fdep).Get_Trigger() == in_event)
      dependents_of_event.insert((*an_fdep).Get_Dependents());
  }

  return dependents_of_event;
}


void Fault_Tree::Set_Replication(const Event& in_event, const Replication& in_replication)
{
  replications[in_event] = in_replication;
}

const Replication& Fault_Tree::Get_Replication(const Event& in_event) const
{
  return (*replications.find(in_event)).second;
}


void Fault_Tree::Set_Threshold(const Event& in_threshold_gate, const Threshold& in_threshold)
{
  thresholds[in_threshold_gate] = in_threshold;
}

const Threshold& Fault_Tree::Get_Threshold(const Event& in_threshold_gate) const
{
  return (*thresholds.find(in_threshold_gate)).second;
}


void Fault_Tree::Set_Event_Description(const Event& in_event, const string& in_description)
{
  event_descriptions[in_event] = in_description;
}

void Fault_Tree::Remove_Event_Description(const Event& in_event)
{
  event_descriptions.erase(in_event);
}

const string& Fault_Tree::Get_Event_Description(const Event& in_event) const
{
  assert(event_descriptions.find(in_event) != event_descriptions.end());

  return (*event_descriptions.find(in_event)).second;
}

const bijection<Event, string>& Fault_Tree::Get_Event_Descriptions() const
{
  return event_descriptions;
}

void Fault_Tree::Set_SEQ_Description(const Input_Sequence& in_seq,const string& in_description)
{
  seq_descriptions[in_seq] = in_description;
}

void Fault_Tree::Remove_SEQ_Description(const Input_Sequence& in_seq)
{
  seq_descriptions.erase(in_seq);
}

const string& Fault_Tree::Get_SEQ_Description(const Input_Sequence& in_seq) const
{
  assert(seq_descriptions.find(in_seq) != seq_descriptions.end());

  return (*seq_descriptions.find(in_seq)).second;
}

void Fault_Tree::Set_FDEP_Description(const Functional_Dependency& in_fdep, const string& in_description)
{
  fdep_descriptions[in_fdep] = in_description;
}

void Fault_Tree::Remove_FDEP_Description(const Functional_Dependency& in_fdep)
{
  fdep_descriptions.erase(in_fdep);
}

const string& Fault_Tree::Get_FDEP_Description(const Functional_Dependency& in_fdep) const
{
  assert(fdep_descriptions.find(in_fdep) != fdep_descriptions.end());

  return (*fdep_descriptions.find(in_fdep)).second;
}

const bool Fault_Tree::Event_Not_Referenced(const Event &in_event)
{
  if (events.find(in_event) != events.end())
    return false;

  set<Input_Sequence>::const_iterator an_seq;
  for(an_seq = seq_constraints.begin(); an_seq != seq_constraints.end(); an_seq++)
  {
    if ((*an_seq).find(in_event) != (*an_seq).end())
      return false;
  }

  set<Functional_Dependency>::const_iterator an_fdep;
  for(an_fdep = fdep_constraints.begin(); an_fdep != fdep_constraints.end(); an_fdep++)
  {
    Input_Sequence dependents = (*an_fdep).Get_Dependents();
    if (dependents.find(in_event) != dependents.end())
      return false;

    if ((*an_fdep).Get_Trigger() == in_event)
      return false;
  }

  if (system_event_initialized)
  {
    if (Get_System_Event() == in_event)
      return false;
  }

  if (gates_input_to[in_event].size() > 0)
    return false;

  return true;
}
