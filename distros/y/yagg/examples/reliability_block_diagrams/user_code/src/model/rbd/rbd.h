
#ifndef RBD_H
#define RBD_H

#ifdef WIN32
// Suppress warnings about debug identifiers being truncated to 255 characters
#pragma warning (disable:4786)
#endif

#include <set>
#include <string>

using namespace std;

#include "rbd/component.h"
#include "rbd/block.h"
#include "rbd/block_set.h"
#include "rbd/dests_map.h"
#include "rbd/phys_to_log_map.h"
#include "basic_types/bijection.h"

class RBD
{
public:
  RBD();
  RBD(const RBD& in_rbd);
  virtual ~RBD();

  const RBD& operator= (const RBD &in_rbd);

  friend bool operator< (const RBD& in_first, const RBD& in_second);
  friend bool operator==(const RBD& in_first, const RBD& in_second);
  friend bool operator!=(const RBD& in_first, const RBD& in_second);
  friend ostream& operator<< (ostream& in_ostream, const RBD& in_rbd);

  void Clear();

  void Insert_Component(const Component& in_component);
  void Insert_Reliability_Block(const Block& in_block);

  void Remove_Component(const Component& in_component);
  void Remove_Reliability_Block(const Block& in_block);

  const set<Component>& Get_Components() const;
  const Block& Get_Source_Block() const;
  const Block& Get_Sink_Block() const;
  const Block_Set& Get_Reliability_Blocks() const;

  // Setting and getting the inputs for a gate.
  void Set_Block_Outputs(const Block& in_block, const Block_Set& in_outputs);
  void Remove_Block_Outputs(const Block& in_block);
  const bool Block_Has_Outputs(const Block& in_block) const;
  const Block_Set& Get_Block_Outputs(const Block& in_block) const;
  const Block_Set Get_Block_Is_Output_To(const Block& in_Block) const;
  const Dests_Map Get_Dests_Map() const;

  void Set_Phys_To_Log_Map(const Component& in_component, const Block_Set& in_block_set);
  void Remove_Phys_To_Log_Map(const Component& in_component);
  const Block_Set& Get_Phys_To_Log_Map(const Component& in_component) const;
  const bool Containing_Component_Exists(const Block& in_Block) const;
  const Component& Get_Component_Containing(const Block& in_Block) const;

  // Descriptions aren't in the spec, but are very useful
  void Set_Block_Description(const Block& in_block,const string& in_description);
	void Remove_Block_Description(const Block& in_block);
	const string& Get_Block_Description(const Block& in_block) const;
  void Set_Component_Description(const Component& in_component,const string& in_description);
  void Remove_Component_Description(const Component& in_component);
  const string& Get_Component_Description(const Component& in_component) const;
  const bijection<Component,string>& Get_Component_Descriptions() const;

  const bool Is_Directly_Output_To(const Block& in_first, const Block& in_second, const Dests_Map& dests) const;
  const bool Is_Output_To(const Block& in_first, const Block& in_second, const Dests_Map& dests) const;

	const bool Block_Is_Referenced(const Block& in_block) const;
protected:

  Block source_block;
  Block sink_block;

  Block_Set reliability_blocks;

  set<Component> components;

  Dests_Map dests;

  Phys_To_Log_Map phys_to_log_map;

  // Descriptions aren't in the spec, but are very useful
  bijection<Block, string> block_descriptions;
  bijection<Component, string> component_descriptions;
 
};

inline bool operator<(const RBD& in_first, const RBD& in_second)
{
  if (in_first.source_block < in_second.source_block)
    return true;
  else if (in_first.source_block != in_second.source_block)
    return false;

  if (in_first.sink_block < in_second.sink_block)
    return true;
  else if (in_first.sink_block != in_second.sink_block)
    return false;

  if (in_first.reliability_blocks < in_second.reliability_blocks)
    return true;
  else if (in_first.reliability_blocks != in_second.reliability_blocks)
    return false;

  if (in_first.components < in_second.components)
    return true;
  else if (in_first.components != in_second.components)
    return false;

  if (in_first.dests < in_second.dests)
    return true;
  else if (in_first.dests != in_second.dests)
    return false;

  if (in_first.phys_to_log_map < in_second.phys_to_log_map)
    return true;
  else if (in_first.phys_to_log_map != in_second.phys_to_log_map)
    return false;

  if (in_first.block_descriptions < in_second.block_descriptions)
    return true;
  else if (in_first.block_descriptions != in_second.block_descriptions)
    return false;

  if (in_first.component_descriptions < in_second.component_descriptions)
    return true;
  else
    return false;
}


inline bool operator==(const RBD& in_first, const RBD& in_second)
{
  return ((in_first.source_block == in_second.source_block) &&
          (in_first.sink_block == in_second.sink_block) &&
          (in_first.reliability_blocks == in_second.reliability_blocks) &&
          (in_first.components == in_second.components) &&
          (in_first.dests == in_second.dests) &&
          (in_first.phys_to_log_map == in_second.phys_to_log_map) &&
          (in_first.block_descriptions == in_second.block_descriptions) &&
          (in_first.component_descriptions == in_second.component_descriptions));
}

inline bool operator!=(const RBD& in_first, const RBD& in_second)
{
  return !(in_first == in_second);
}

inline const RBD& RBD::operator=(const RBD& in_rbd)
{
  source_block = in_rbd.source_block;
  sink_block = in_rbd.sink_block;
  reliability_blocks = in_rbd.reliability_blocks;
  components = in_rbd.components;
  dests = in_rbd.dests;
  phys_to_log_map = in_rbd.phys_to_log_map;
  block_descriptions = in_rbd.block_descriptions;
  component_descriptions = in_rbd.component_descriptions;

  return *this;
}

#endif // RBD_H
