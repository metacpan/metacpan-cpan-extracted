// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef UFAL_PARSITO_H
#define UFAL_PARSITO_H

#include <cstring>
#include <iostream>
#include <string>
#include <vector>

namespace ufal {
namespace parsito {

struct string_piece {
  const char* str;
  size_t len;

  string_piece() : str(nullptr), len(0) {}
  string_piece(const char* str) : str(str), len(strlen(str)) {}
  string_piece(const char* str, size_t len) : str(str), len(len) {}
  string_piece(const std::string& str) : str(str.c_str()), len(str.size()) {}
};

class node {
 public:
  int id;              // 0 is root, >0 is sentence node, <0 is undefined
  std::string form;    // form
  std::string lemma;   // lemma
  std::string upostag; // universal part-of-speech tag
  std::string xpostag; // language-specific part-of-speech tag
  std::string feats;   // list of morphological features
  int head;            // head, 0 is root, <0 is without parent
  std::string deprel;  // dependency relation to the head
  std::string deps;    // secondary dependencies
  std::string misc;    // miscellaneous information

  std::vector<int> children;

  node(int id = -1, const std::string& form = std::string()) : id(id), form(form), head(-1) {}
};

class tree {
 public:
  tree();

  std::vector<node> nodes;

  bool empty();
  void clear();
  node& add_node(const std::string& form);
  void set_head(int id, int head, const std::string& deprel);
  void unlink_all_nodes();

  static const std::string root_form;
};

// Input format
class tree_input_format {
 public:
  virtual ~tree_input_format() {}

  virtual bool read_block(std::istream& in, std::string& block) const = 0;
  virtual void set_text(string_piece text, bool make_copy = false) = 0;
  virtual bool next_tree(tree& t) = 0;
  const std::string& last_error() const;

  // Static factory methods
  static tree_input_format* new_input_format(const std::string& name);
  static tree_input_format* new_conllu_input_format();
};

// Output format
class tree_output_format {
 public:
  virtual ~tree_output_format() {}

  virtual void write_tree(const tree& t, std::string& output, const tree_input_format* additional_info = nullptr) const = 0;

  // Static factory methods
  static tree_output_format* new_output_format(const std::string& name);
  static tree_output_format* new_conllu_output_format();
};

// Current Parsito version
struct version {
  unsigned major;
  unsigned minor;
  unsigned patch;
  std::string prerelease;

  // Returns current version.
  static version current();
};

// Parser
class parser {
 public:
  virtual ~parser() {};

  virtual void parse(tree& t, unsigned beam_size = 0) const = 0;

  enum { NO_CACHE = 0, FULL_CACHE = 2147483647};
  static parser* load(const char* file, unsigned cache = 1000);
  static parser* load(std::istream& in, unsigned cache = 1000);
};

} // namespace parsito
} // namespace ufal

#endif
