#include "rbd.h"
#include <iostream>
#include <cassert>

using namespace std;

ostream& Output_Descriptive_Block_Set(ostream& in_ostream, const RBD& in_rbd, const Block_Set& in_block_set)
{
  Block_Set::const_iterator a_block;
  for (a_block = in_block_set.begin(); a_block != in_block_set.end(); a_block++)
  {
    in_ostream << in_rbd.Get_Block_Description(*a_block) << " (id: " << *a_block << ")";

    Block_Set::const_iterator next_block(a_block);
    next_block++;
    if (next_block != in_block_set.end())
      in_ostream << ", ";
  }

  return in_ostream;
}

// This output function uses a custom block set output routine that
// prints block descriptions (from the rbd) instead of relying on the
// default << output of Block_Set.
ostream& operator<< (ostream& in_ostream, const RBD& in_rbd)
{
  in_ostream << "== Source block:" << endl;
    in_ostream << in_rbd.Get_Block_Description(in_rbd.Get_Source_Block()) <<
    " (id: " << in_rbd.Get_Source_Block() << ")" << endl;

  in_ostream << "== Sink block:" << endl;
    in_ostream << in_rbd.Get_Block_Description(in_rbd.Get_Sink_Block()) <<
    " (id: " << in_rbd.Get_Sink_Block() << ")" << endl;

  in_ostream << "== Components:" << endl;
  if (in_rbd.Get_Components().size() > 0)
  {
    set<Component>::const_iterator a_component;

    for (a_component = in_rbd.Get_Components().begin(); a_component != in_rbd.Get_Components().end(); a_component++)
    {
      in_ostream << in_rbd.Get_Component_Description(*a_component) << " (id: " <<
        *a_component << ", associated blocks: ";
      Output_Descriptive_Block_Set(in_ostream, in_rbd, in_rbd.Get_Phys_To_Log_Map(*a_component));
      in_ostream << ")" << endl;
    }
  }
  else
    in_ostream << "<NONE>" << endl;

  in_ostream << "== Reliability blocks:" << endl;
  if (in_rbd.Get_Reliability_Blocks().size() > 0)
  {
    set<Block>::const_iterator a_block;

    for (a_block = in_rbd.Get_Reliability_Blocks().begin(); a_block != in_rbd.Get_Reliability_Blocks().end(); a_block++)
    {
      in_ostream << in_rbd.Get_Block_Description(*a_block) << " (id: " <<
        *a_block << ", outputs to: ";
      Output_Descriptive_Block_Set(in_ostream, in_rbd, in_rbd.Get_Block_Outputs(*a_block));
      in_ostream << ")" << endl;
    }
  }
  else
    in_ostream << "<NONE>" << endl;

  return in_ostream;
}

RBD::RBD()
{
}

RBD::RBD(const RBD& in_rbd)
{
  *this = in_rbd;
}

RBD::~RBD()
{
}

void RBD::Clear()
{
  reliability_blocks.clear();
  components.clear();
  dests.clear();
  phys_to_log_map.clear();
  block_descriptions.clear();
  component_descriptions.clear();
}

void RBD::Insert_Reliability_Block(const Block& in_block)
{
  assert (in_block != sink_block && in_block != source_block);

  reliability_blocks.insert(in_block);
}

void RBD::Insert_Component(const Component& in_component)
{
  components.insert(in_component);
}

void RBD::Remove_Reliability_Block(const Block& in_block)
{
  assert (in_block != sink_block && in_block != source_block);

  reliability_blocks.erase(in_block);
}

void RBD::Remove_Component(const Component& in_component)
{
  components.erase(in_component);
}

const Block& RBD::Get_Source_Block() const
{
  return source_block;
}

const Block& RBD::Get_Sink_Block() const
{
  return sink_block;
}

const Block_Set& RBD::Get_Reliability_Blocks() const
{
  return reliability_blocks;
}

const set<Component>& RBD::Get_Components() const
{
  return components;
}

const Dests_Map RBD::Get_Dests_Map() const
{
  return dests;
}

/*****************************************
Components
 *****************************************/
void RBD::Set_Phys_To_Log_Map(const Component& in_component, const Block_Set& in_block_set)
{
  phys_to_log_map[in_component] = in_block_set;
}

void RBD::Remove_Phys_To_Log_Map(const Component& in_component)
{
  phys_to_log_map.erase(in_component);
}

const Block_Set& RBD::Get_Phys_To_Log_Map(const Component& in_component) const
{
  assert(phys_to_log_map.find(in_component) != phys_to_log_map.end());

  return phys_to_log_map(in_component);
}

const bool RBD::Containing_Component_Exists(const Block& in_block) const
{
  assert (in_block != sink_block && in_block != source_block);

  set<Component> comp_set = Get_Components();

  set<Component>::const_iterator component;
  for (component = comp_set.begin(); component != comp_set.end(); component++)
  {
    Block_Set blocks_of_component = Get_Phys_To_Log_Map(*component);

    if (blocks_of_component.find(in_block) != blocks_of_component.end())
      return true;
  }

  return false;
}

const Component& RBD::Get_Component_Containing(const Block& in_block) const
{
  assert (in_block != sink_block && in_block != source_block);

  set<Component> comp_set = Get_Components();

  set<Component>::const_iterator component;
  for (component = comp_set.begin(); component != comp_set.end(); component++)
  {
    Block_Set blocks_of_component = Get_Phys_To_Log_Map(*component);

    if (blocks_of_component.find(in_block) != blocks_of_component.end())
      return *component;
  }

  assert(false);
  return *component;
}

const bool RBD::Block_Is_Referenced(const Block& in_block) const
{
	if (reliability_blocks.find(in_block) != reliability_blocks.end() ||
			Get_Source_Block() == in_block || Get_Sink_Block() == in_block)
		return true;

	for (Dests_Map::const_iterator it = dests.begin(); it != dests.end(); it++)
		if (it->first == in_block ||
				it->second.find(in_block) != it->second.end())
			return true;

	if (Containing_Component_Exists(in_block))
		return true;

	return false;
}

void RBD::Set_Block_Outputs(const Block& in_block, const Block_Set& in_outputs)
{
  dests[in_block] = in_outputs;
}

void RBD::Remove_Block_Outputs(const Block& in_block)
{
  dests.erase(in_block);
}

const bool RBD::Block_Has_Outputs(const Block& in_block) const
{
  return (dests.find(in_block) != dests.end());
}

//returns the set of blocks in_block outputs to
const Block_Set& RBD::Get_Block_Outputs(const Block& in_block) const
{
  assert(dests.find(in_block) != dests.end());

  return dests(in_block);
}

//returns the set of blocks that use in_block as an output
const Block_Set RBD::Get_Block_Is_Output_To(const Block& in_block) const
{
  Block_Set blocks_output_to;

  if (Block_Has_Outputs(source_block))
  {
    Block_Set output_blocks = Get_Block_Outputs(source_block);

    if (output_blocks.find(in_block) != output_blocks.end())
      blocks_output_to.insert(source_block);
  }


  Block_Set::const_iterator block;
  for (block = reliability_blocks.begin(); block != reliability_blocks.end(); block++)
  {
    if (Block_Has_Outputs(*block))
    {
      Block_Set output_blocks = Get_Block_Outputs(*block);

      if (output_blocks.find(in_block) != output_blocks.end())
        blocks_output_to.insert(*block);
    }
  }

  return blocks_output_to;
}

const bool RBD::Is_Directly_Output_To(const Block& in_first, const Block& in_second, const Dests_Map& dests) const
{
  Block_Set outputs = dests(in_first);

  Block_Set::const_iterator output_it;
  for(output_it = outputs.begin(); output_it != outputs.end(); output_it++)
  {
    if (in_second == *output_it)
    {
      return true;
    }
  }

  return false;
}

const bool RBD::Is_Output_To(const Block& in_first, const Block& in_second, const Dests_Map& dests) const
{
  if (Is_Directly_Output_To(in_first, in_second, dests))
  {
    return true;
  }
  else
  {
    Block_Set outputs = dests(in_first);

    Block_Set::const_iterator output_it;
    for(output_it = outputs.begin(); output_it != outputs.end(); output_it++)
    {
      if (*output_it!=Get_Sink_Block() 
	  && Is_Directly_Output_To(*output_it, in_second, dests))
      {
        return true;
      }
    }
  }
  
  return false;
}


void RBD::Set_Block_Description(const Block& in_block, const string& in_description)
{
  block_descriptions[in_block] = in_description;
}

void RBD::Remove_Block_Description(const Block& in_block)
{
	block_descriptions.erase(in_block);
}

const string& RBD::Get_Block_Description(const Block& in_block) const
{
  assert(block_descriptions.find(in_block) != block_descriptions.end());

  return block_descriptions(in_block);
}

void RBD::Set_Component_Description(const Component& in_component,const string& in_description)
{
  component_descriptions[in_component] = in_description;
}

void RBD::Remove_Component_Description(const Component& in_component)
{
	component_descriptions.erase(in_component);
}

const string& RBD::Get_Component_Description(const Component& in_component) const
{
  assert(component_descriptions.find(in_component) != component_descriptions.end());

  return component_descriptions(in_component);
}

const bijection<Component,string>& RBD::Get_Component_Descriptions() const
{
  return component_descriptions;
}


