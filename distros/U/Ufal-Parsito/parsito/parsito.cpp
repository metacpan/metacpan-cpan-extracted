// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// This file is a bundle of all sources and headers of Parsito library.
// Comments and copyrights of all individual files are kept.

#include <algorithm>
#include <atomic>
#include <cassert>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <iterator>
#include <limits>
#include <list>
#include <memory>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace ufal {
namespace parsito {

/////////
// File: utils/common.h
/////////

// This file is part of UFAL C++ Utils <http://github.com/ufal/cpp_utils/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Headers available in all sources

using namespace std;

// Assert that int is at least 4B
static_assert(sizeof(int) >= sizeof(int32_t), "Int must be at least 4B wide!");

// Assert that we are on a little endian system
#ifdef __BYTE_ORDER__
static_assert(__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__, "Only little endian systems are supported!");
#endif

#define runtime_failure(message) exit((cerr << message << endl, 1))

/////////
// File: utils/string_piece.h
/////////

// This file is part of UFAL C++ Utils <http://github.com/ufal/cpp_utils/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

struct string_piece {
  const char* str;
  size_t len;

  string_piece() : str(nullptr), len(0) {}
  string_piece(const char* str) : str(str), len(strlen(str)) {}
  string_piece(const char* str, size_t len) : str(str), len(len) {}
  string_piece(const string& str) : str(str.c_str()), len(str.size()) {}
};

inline ostream& operator<<(ostream& os, const string_piece& str) {
  return os.write(str.str, str.len);
}

inline bool operator==(const string_piece& a, const string_piece& b) {
  return a.len == b.len && memcmp(a.str, b.str, a.len) == 0;
}

inline bool operator!=(const string_piece& a, const string_piece& b) {
  return a.len != b.len || memcmp(a.str, b.str, a.len) != 0;
}

/////////
// File: common.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.


/////////
// File: tree/node.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class node {
 public:
  int id;         // 0 is root, >0 is sentence node, <0 is undefined
  string form;    // form
  string lemma;   // lemma
  string upostag; // universal part-of-speech tag
  string xpostag; // language-specific part-of-speech tag
  string feats;   // list of morphological features
  int head;       // head, 0 is root, <0 is without parent
  string deprel;  // dependency relation to the head
  string deps;    // secondary dependencies
  string misc;    // miscellaneous information

  vector<int> children;

  node(int id = -1, const string& form = string()) : id(id), form(form), head(-1) {}
};

/////////
// File: tree/tree.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class tree {
 public:
  tree();

  vector<node> nodes;

  bool empty();
  void clear();
  node& add_node(const string& form);
  void set_head(int id, int head, const string& deprel);
  void unlink_all_nodes();

  static const string root_form;
};

/////////
// File: configuration/configuration.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class configuration {
 public:
  void init(tree* t);
  bool final();

  tree* t;
  vector<int> stack;
  vector<int> buffer;
};

/////////
// File: configuration/configuration.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

void configuration::init(tree* t) {
  assert(t);

  t->unlink_all_nodes();
  this->t = t;

  stack.clear();
  if (!t->nodes.empty()) stack.push_back(0);

  buffer.clear();
  buffer.reserve(t->nodes.size());
  for (size_t i = t->nodes.size(); i > 1; i--)
    buffer.push_back(i - 1);
}

bool configuration::final() {
  return buffer.empty() && stack.size() <= 1;
}

/////////
// File: configuration/node_extractor.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class node_extractor {
 public:
  unsigned node_count() const;
  void extract(const configuration& conf, vector<int>& nodes) const;

  bool create(string_piece description, string& error);

 private:
  enum start_t { STACK = 0, BUFFER = 1 };
  enum direction_t { PARENT = 0, CHILD = 1 };
  struct node_selector {
    pair<start_t, int> start;
    vector<pair<direction_t, int>> directions;

    node_selector(start_t start, int start_index) : start(start, start_index) {}
  };

  vector<node_selector> selectors;
};

/////////
// File: utils/parse_int.h
/////////

// This file is part of UFAL C++ Utils <http://github.com/ufal/cpp_utils/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

//
// Declarations
//

// Try to parse an int from given string. If the int cannot be parsed or does
// not fit into int, false is returned and the error string is filled using the
// value_name argument.
inline bool parse_int(string_piece str, const char* value_name, int& value, string& error);

// Try to parse an int from given string. If the int cannot be parsed or does
// not fit into int, an error is displayed and program exits.
inline int parse_int(string_piece str, const char* value_name);

//
// Definitions
//

bool parse_int(string_piece str, const char* value_name, int& value, string& error) {
  string_piece original = str;

  // Skip spaces
  while (str.len && (str.str[0] == ' ' || str.str[0] == '\f' || str.str[0] == '\n' || str.str[0] == '\r' || str.str[0] == '\t' || str.str[0] == '\v'))
    str.str++, str.len--;

  // Allow minus
  bool positive = true;
  if (str.len && str.str[0] == '-') {
    positive = false;
    str.str++, str.len--;
  }

  // Parse value, checking for overflow/underflow
  if (!str.len) return error.assign("Cannot parse ").append(value_name).append(" int value '").append(original.str, original.len).append("': empty string."), false;
  if (!(str.str[0] >= '0' || str.str[0] <= '9')) return error.assign("Cannot parse ").append(value_name).append(" int value '").append(original.str, original.len).append("': non-digit character found."), false;

  value = 0;
  while (str.len && str.str[0] >= '0' && str.str[0] <= '9') {
    if (positive) {
      if (value > (numeric_limits<int>::max() - (str.str[0] - '0')) / 10)
        return error.assign("Cannot parse ").append(value_name).append(" int value '").append(original.str, original.len).append("': overflow occured."), false;
      value = 10 * value + (str.str[0] - '0');
    } else {
      if (value < (numeric_limits<int>::min() + (str.str[0] - '0')) / 10)
        return error.assign("Cannot parse ").append(value_name).append(" int value '").append(original.str, original.len).append("': underflow occured."), false;
      value = 10 * value - (str.str[0] - '0');
    }
    str.str++, str.len--;
  }

  // Skip spaces
  while (str.len && (str.str[0] == ' ' || str.str[0] == '\f' || str.str[0] == '\n' || str.str[0] == '\r' || str.str[0] == '\t' || str.str[0] == '\v'))
    str.str++, str.len--;

  // Check for remaining characters
  if (str.len) return error.assign("Cannot parse ").append(value_name).append(" int value '").append(original.str, original.len).append("': non-digit character found."), false;

  return true;
}

int parse_int(string_piece str, const char* value_name) {
  int result;
  string error;

  if (!parse_int(str, value_name, result, error))
    runtime_failure(error);

  return result;
}

/////////
// File: utils/split.h
/////////

// This file is part of UFAL C++ Utils <http://github.com/ufal/cpp_utils/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

//
// Declarations
//

// Split given text on the separator character.
inline void split(const string& text, char sep, vector<string>& tokens);
inline void split(string_piece text, char sep, vector<string_piece>& tokens);

//
// Definitions
//

void split(const string& text, char sep, vector<string>& tokens) {
  tokens.clear();
  if (text.empty()) return;

  string::size_type index = 0;
  for (string::size_type next; (next = text.find(sep, index)) != string::npos; index = next + 1)
    tokens.emplace_back(text, index, next - index);

  tokens.emplace_back(text, index);
}

void split(string_piece text, char sep, vector<string_piece>& tokens) {
  tokens.clear();
  if (!text.len) return;

  const char* str = text.str;
  for (const char* next; (next = (const char*) memchr(str, sep, text.str + text.len - str)); str = next + 1)
    tokens.emplace_back(str, next - str);

  tokens.emplace_back(str, text.str + text.len - str);
}

/////////
// File: configuration/node_extractor.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

unsigned node_extractor::node_count() const {
  return selectors.size();
}

void node_extractor::extract(const configuration& conf, vector<int>& nodes) const {
  nodes.clear();
  for (auto&& selector : selectors) {
    // Start by locating starting node
    int current = -1;
    switch (selector.start.first) {
      case STACK:
        if (selector.start.second < int(conf.stack.size()))
          current = conf.stack[conf.stack.size() - 1 - selector.start.second];
        break;
      case BUFFER:
        if (selector.start.second < int(conf.buffer.size()))
          current = conf.buffer[conf.buffer.size() - 1 - selector.start.second];
        break;
    }

    // Follow directions to the final node
    if (current >= 0)
      for (auto&& direction : selector.directions) {
        const node& node = conf.t->nodes[current];
        switch (direction.first) {
          case PARENT:
            current = node.head ? node.head : -1;
            break;
          case CHILD:
            current = direction.second >= 0 && direction.second < int(node.children.size()) ?
                        node.children[direction.second] :
                      direction.second < 0 && -direction.second <= int(node.children.size()) ?
                        node.children[node.children.size() + direction.second] :
                        -1;
            break;
        }
        if (current <= 0) break;
      }

    // Add the selected node
    nodes.push_back(current);
  }
}

bool node_extractor::create(string_piece description, string& error) {
  selectors.clear();
  error.clear();

  vector<string_piece> lines, parts, words;
  split(description, '\n', lines);
  for (auto&& line : lines) {
    if (!line.len || line.str[0] == '#') continue;

    // Separate start and directions
    split(line, ',', parts);

    // Parse start
    split(parts[0], ' ', words);
    if (words.size() != 2)
      return error.assign("The node selector '").append(parts[0].str, parts[0].len).append("' on line '").append(line.str, line.len).append("' does not contain two space separated values!"), false;

    start_t start;
    if (words[0] == "stack")
      start = STACK;
    else if (words[0] == "buffer")
      start = BUFFER;
    else
      return error.assign("Cannot parse starting location '").append(words[0].str, words[0].len).append("' on line '").append(line.str, line.len).append(".!"), false;

    int start_index;
    if (!parse_int(words[1], "starting index", start_index, error)) return false;

    selectors.emplace_back(start, start_index);

    // Parse directions
    for (size_t i = 1; i < parts.size(); i++) {
      split(parts[i], ' ', words);
      if (words.empty())
        return error.assign("Empty node selector on line '").append(line.str, line.len).append(".!"), false;

      if (words[0] == "parent") {
        if (words.size() != 1)
          return error.assign("The node selector '").append(parts[i].str, parts[i].len).append("' on line '").append(line.str, line.len).append("' does not contain one space separated value!"), false;
        selectors.back().directions.emplace_back(PARENT, 0);
      } else if (words[0] == "child") {
        if (words.size() != 2)
          return error.assign("The node selector '").append(parts[i].str, parts[i].len).append("' on line '").append(line.str, line.len).append("' does not contain two space separated values!"), false;
        int child_index;
        if (!parse_int(words[1], "child index", child_index, error)) return false;
        selectors.back().directions.emplace_back(CHILD, child_index);
      } else {
        return error.assign("Cannot parse direction location '").append(words[0].str, words[0].len).append("' on line '").append(line.str, line.len).append(".!"), false;
      }
    }
  }

  return true;
}

/////////
// File: configuration/value_extractor.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class value_extractor {
 public:
  void extract(const node& n, string& value) const;

  bool create(string_piece description, string& error);

 private:
  enum value_t { FORM = 0, LEMMA = 1, LEMMA_ID = 2, TAG = 3, UNIVERSAL_TAG = 4,
    FEATS = 5, UNIVERSAL_TAG_FEATS = 6, DEPREL = 7 };
  value_t selector;
};

/////////
// File: configuration/value_extractor.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

void value_extractor::extract(const node& n, string& value) const {
  switch (selector) {
    case FORM:
      value.assign(n.form);
      break;
    case LEMMA:
      value.assign(n.lemma);
      break;
    case LEMMA_ID:
      if (!n.misc.empty()) {
        // Try finding LId= in misc column
        auto lid = n.misc.find("LId=");
        if (lid != string::npos) {
          lid += 4;

          // Find optional | ending the lemma_id
          auto lid_end = n.misc.find('|', lid);
          if (lid_end == string::npos) lid_end = n.misc.size();

          // Store the lemma_id
          value.assign(n.misc, lid, lid_end - lid);
          break;
        }
      }
      value.assign(n.lemma);
      break;
    case TAG:
      value.assign(n.xpostag);
      break;
    case UNIVERSAL_TAG:
      value.assign(n.upostag);
      break;
    case FEATS:
      value.assign(n.feats);
      break;
    case UNIVERSAL_TAG_FEATS:
      value.assign(n.upostag).append(n.feats);
      break;
    case DEPREL:
      value.assign(n.deprel);
      break;
  }
}

bool value_extractor::create(string_piece description, string& error) {
  error.clear();

  if (description == "form")
    selector = FORM;
  else if (description == "lemma")
    selector = LEMMA;
  else if (description == "lemma_id")
    selector = LEMMA_ID;
  else if (description == "tag")
    selector = TAG;
  else if (description == "universal_tag")
    selector = UNIVERSAL_TAG;
  else if (description == "feats")
    selector = FEATS;
  else if (description == "universal_tag_feats")
    selector = UNIVERSAL_TAG_FEATS;
  else if (description == "deprel")
    selector = DEPREL;
  else
    return error.assign("Cannot parse value selector '").append(description.str, description.len).append("'!"), false;

  return true;
}

/////////
// File: embedding/embedding.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class binary_decoder;
class binary_encoder;

class embedding {
 public:
  unsigned dimension;

  int lookup_word(const string& word, string& buffer) const;
  int unknown_word() const;
  float* weight(int id); // nullptr for wrong id
  const float* weight(int id) const; // nullpt for wrong id

  bool can_update_weights(int id) const;

  void load(binary_decoder& data);
  void save(binary_encoder& enc) const;
  void create(unsigned dimension, int updatable_index, const vector<pair<string, vector<float>>>& words, const vector<float>& unknown_weights);
 private:
  int updatable_index, unknown_index;

  unordered_map<string, int> dictionary;
  vector<float> weights;
};

/////////
// File: unilib/unicode.h
/////////

// This file is part of UniLib <http://github.com/ufal/unilib/>.
//
// Copyright 2014 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// UniLib version: 3.1.0
// Unicode version: 8.0.0

namespace unilib {

class unicode {
  enum : uint8_t {
    _Lu = 1, _Ll = 2, _Lt = 3, _Lm = 4, _Lo = 5,
    _Mn = 6, _Mc = 7, _Me = 8,
    _Nd = 9, _Nl = 10, _No = 11,
    _Pc = 12, _Pd = 13, _Ps = 14, _Pe = 15, _Pi = 16, _Pf = 17, _Po = 18,
    _Sm = 19, _Sc = 20, _Sk = 21, _So = 22,
    _Zs = 23, _Zl = 24, _Zp = 25,
    _Cc = 26, _Cf = 27, _Cs = 28, _Co = 29, _Cn = 30
  };

 public:
  typedef uint32_t category_t;
  enum : category_t {
    Lu = 1 << _Lu, Ll = 1 << _Ll, Lt = 1 << _Lt, Lut = Lu | Lt, LC = Lu | Ll | Lt,
      Lm = 1 << _Lm, Lo = 1 << _Lo, L = Lu | Ll | Lt | Lm | Lo,
    Mn = 1 << _Mn, Mc = 1 << _Mc, Me = 1 << _Me, M = Mn | Mc | Me,
    Nd = 1 << _Nd, Nl = 1 << _Nl, No = 1 << _No, N = Nd | Nl | No,
    Pc = 1 << _Pc, Pd = 1 << _Pd, Ps = 1 << _Ps, Pe = 1 << _Pe, Pi = 1 << _Pi,
      Pf = 1 << _Pf, Po = 1 << _Po, P = Pc | Pd | Ps | Pe | Pi | Pf | Po,
    Sm = 1 << _Sm, Sc = 1 << _Sc, Sk = 1 << _Sk, So = 1 << _So, S = Sm | Sc | Sk | So,
    Zs = 1 << _Zs, Zl = 1 << _Zl, Zp = 1 << _Zp, Z = Zs | Zl | Zp,
    Cc = 1 << _Cc, Cf = 1 << _Cf, Cs = 1 << _Cs, Co = 1 << _Co, Cn = 1 << _Cn, C = Cc | Cf | Cs | Co | Cn
  };

  static inline category_t category(char32_t chr);

  static inline char32_t lowercase(char32_t chr);
  static inline char32_t uppercase(char32_t chr);
  static inline char32_t titlecase(char32_t chr);

 private:
  static const char32_t CHARS = 0x110000;
  static const int32_t DEFAULT_CAT = Cn;

  static const uint8_t category_index[CHARS >> 8];
  static const uint8_t category_block[][256];
  static const uint8_t othercase_index[CHARS >> 8];
  static const char32_t othercase_block[][256];

  enum othercase_type { LOWER_ONLY = 1, UPPERTITLE_ONLY = 2, LOWER_THEN_UPPER = 3, UPPER_THEN_TITLE = 4, TITLE_THEN_LOWER = 5 };
};

unicode::category_t unicode::category(char32_t chr) {
  return chr < CHARS ? 1 << category_block[category_index[chr >> 8]][chr & 0xFF] : DEFAULT_CAT;
}

char32_t unicode::lowercase(char32_t chr) {
  if (chr < CHARS) {
    char32_t othercase = othercase_block[othercase_index[chr >> 8]][chr & 0xFF];
    if ((othercase & 0xFF) == othercase_type::LOWER_ONLY) return othercase >> 8;
    if ((othercase & 0xFF) == othercase_type::LOWER_THEN_UPPER) return othercase >> 8;
    if ((othercase & 0xFF) == othercase_type::TITLE_THEN_LOWER) return othercase_block[othercase_index[(othercase >> 8) >> 8]][(othercase >> 8) & 0xFF] >> 8;
  }
  return chr;
}

char32_t unicode::uppercase(char32_t chr) {
  if (chr < CHARS) {
    char32_t othercase = othercase_block[othercase_index[chr >> 8]][chr & 0xFF];
    if ((othercase & 0xFF) == othercase_type::UPPERTITLE_ONLY) return othercase >> 8;
    if ((othercase & 0xFF) == othercase_type::UPPER_THEN_TITLE) return othercase >> 8;
    if ((othercase & 0xFF) == othercase_type::LOWER_THEN_UPPER) return othercase_block[othercase_index[(othercase >> 8) >> 8]][(othercase >> 8) & 0xFF] >> 8;
  }
  return chr;
}

char32_t unicode::titlecase(char32_t chr) {
  if (chr < CHARS) {
    char32_t othercase = othercase_block[othercase_index[chr >> 8]][chr & 0xFF];
    if ((othercase & 0xFF) == othercase_type::UPPERTITLE_ONLY) return othercase >> 8;
    if ((othercase & 0xFF) == othercase_type::TITLE_THEN_LOWER) return othercase >> 8;
    if ((othercase & 0xFF) == othercase_type::UPPER_THEN_TITLE) return othercase_block[othercase_index[(othercase >> 8) >> 8]][(othercase >> 8) & 0xFF] >> 8;
  }
  return chr;
}

} // namespace unilib

/////////
// File: unilib/utf8.h
/////////

// This file is part of UniLib <http://github.com/ufal/unilib/>.
//
// Copyright 2014 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// UniLib version: 3.1.0
// Unicode version: 8.0.0

namespace unilib {

class utf8 {
 public:
  static bool valid(const char* str);
  static bool valid(const char* str, size_t len);
  static inline bool valid(const std::string& str);

  static inline char32_t decode(const char*& str);
  static inline char32_t decode(const char*& str, size_t& len);
  static inline char32_t first(const char* str);
  static inline char32_t first(const char* str, size_t len);
  static inline char32_t first(const std::string& str);

  static void decode(const char* str, std::u32string& decoded);
  static void decode(const char* str, size_t len, std::u32string& decoded);
  static inline void decode(const std::string& str, std::u32string& decoded);

  class string_decoder {
   public:
    class iterator;
    inline iterator begin();
    inline iterator end();
   private:
    inline string_decoder(const char* str);
    const char* str;
    friend class utf8;
  };
  static inline string_decoder decoder(const char* str);
  static inline string_decoder decoder(const std::string& str);

  class buffer_decoder {
   public:
    class iterator;
    inline iterator begin();
    inline iterator end();
   private:
    inline buffer_decoder(const char* str, size_t len);
    const char* str;
    size_t len;
    friend class utf8;
  };
  static inline buffer_decoder decoder(const char* str, size_t len);

  static inline void append(char*& str, char32_t chr);
  static inline void append(std::string& str, char32_t chr);
  static void encode(const std::u32string& str, std::string& encoded);

  template<class F> static void map(F f, const char* str, std::string& result);
  template<class F> static void map(F f, const char* str, size_t len, std::string& result);
  template<class F> static void map(F f, const std::string& str, std::string& result);

 private:
  static const char REPLACEMENT_CHAR = '?';
};

bool utf8::valid(const std::string& str) {
  return valid(str.c_str());
}

char32_t utf8::decode(const char*& str) {
  const unsigned char*& ptr = (const unsigned char*&) str;
  if (*ptr < 0x80) return *ptr++;
  else if (*ptr < 0xC0) return ++ptr, REPLACEMENT_CHAR;
  else if (*ptr < 0xE0) {
    char32_t res = (*ptr++ & 0x1F) << 6;
    if (*ptr < 0x80 || *ptr >= 0xC0) return REPLACEMENT_CHAR;
    return res + ((*ptr++) & 0x3F);
  } else if (*ptr < 0xF0) {
    char32_t res = (*ptr++ & 0x0F) << 12;
    if (*ptr < 0x80 || *ptr >= 0xC0) return REPLACEMENT_CHAR;
    res += ((*ptr++) & 0x3F) << 6;
    if (*ptr < 0x80 || *ptr >= 0xC0) return REPLACEMENT_CHAR;
    return res + ((*ptr++) & 0x3F);
  } else if (*ptr < 0xF8) {
    char32_t res = (*ptr++ & 0x07) << 18;
    if (*ptr < 0x80 || *ptr >= 0xC0) return REPLACEMENT_CHAR;
    res += ((*ptr++) & 0x3F) << 12;
    if (*ptr < 0x80 || *ptr >= 0xC0) return REPLACEMENT_CHAR;
    res += ((*ptr++) & 0x3F) << 6;
    if (*ptr < 0x80 || *ptr >= 0xC0) return REPLACEMENT_CHAR;
    return res + ((*ptr++) & 0x3F);
  } else return ++ptr, REPLACEMENT_CHAR;
}

char32_t utf8::decode(const char*& str, size_t& len) {
  const unsigned char*& ptr = (const unsigned char*&) str;
  if (!len) return 0; len--;
  if (*ptr < 0x80) return *ptr++;
  else if (*ptr < 0xC0) return ++ptr, REPLACEMENT_CHAR;
  else if (*ptr < 0xE0) {
    char32_t res = (*ptr++ & 0x1F) << 6;
    if (len <= 0 || *ptr < 0x80 || *ptr >= 0xC0) return REPLACEMENT_CHAR;
    return res + ((--len, *ptr++) & 0x3F);
  } else if (*ptr < 0xF0) {
    char32_t res = (*ptr++ & 0x0F) << 12;
    if (len <= 0 || *ptr < 0x80 || *ptr >= 0xC0) return REPLACEMENT_CHAR;
    res += ((--len, *ptr++) & 0x3F) << 6;
    if (len <= 0 || *ptr < 0x80 || *ptr >= 0xC0) return REPLACEMENT_CHAR;
    return res + ((--len, *ptr++) & 0x3F);
  } else if (*ptr < 0xF8) {
    char32_t res = (*ptr++ & 0x07) << 18;
    if (len <= 0 || *ptr < 0x80 || *ptr >= 0xC0) return REPLACEMENT_CHAR;
    res += ((--len, *ptr++) & 0x3F) << 12;
    if (len <= 0 || *ptr < 0x80 || *ptr >= 0xC0) return REPLACEMENT_CHAR;
    res += ((--len, *ptr++) & 0x3F) << 6;
    if (len <= 0 || *ptr < 0x80 || *ptr >= 0xC0) return REPLACEMENT_CHAR;
    return res + ((--len, *ptr++) & 0x3F);
  } else return ++ptr, REPLACEMENT_CHAR;
}

char32_t utf8::first(const char* str) {
  return decode(str);
}

char32_t utf8::first(const char* str, size_t len) {
  return decode(str, len);
}

char32_t utf8::first(const std::string& str) {
  return first(str.c_str());
}

void utf8::decode(const std::string& str, std::u32string& decoded) {
  decode(str.c_str(), decoded);
}

class utf8::string_decoder::iterator : public std::iterator<std::input_iterator_tag, char32_t> {
 public:
  iterator(const char* str) : codepoint(0), next(str) { operator++(); }
  iterator(const iterator& it) : codepoint(it.codepoint), next(it.next) {}
  iterator& operator++() { if (next) { codepoint = decode(next); if (!codepoint) next = nullptr; } return *this; }
  iterator operator++(int) { iterator tmp(*this); operator++(); return tmp; }
  bool operator==(const iterator& other) const { return next == other.next; }
  bool operator!=(const iterator& other) const { return next != other.next; }
  const char32_t& operator*() { return codepoint; }
 private:
  char32_t codepoint;
  const char* next;
};

utf8::string_decoder::string_decoder(const char* str) : str(str) {}

utf8::string_decoder::iterator utf8::string_decoder::begin() {
  return iterator(str);
}

utf8::string_decoder::iterator utf8::string_decoder::end() {
  return iterator(nullptr);
}

utf8::string_decoder utf8::decoder(const char* str) {
  return string_decoder(str);
}

utf8::string_decoder utf8::decoder(const std::string& str) {
  return string_decoder(str.c_str());
}

class utf8::buffer_decoder::iterator : public std::iterator<std::input_iterator_tag, char32_t> {
 public:
  iterator(const char* str, size_t len) : codepoint(0), next(str), len(len) { operator++(); }
  iterator(const iterator& it) : codepoint(it.codepoint), next(it.next), len(it.len) {}
  iterator& operator++() { if (!len) next = nullptr; if (next) codepoint = decode(next, len); return *this; }
  iterator operator++(int) { iterator tmp(*this); operator++(); return tmp; }
  bool operator==(const iterator& other) const { return next == other.next; }
  bool operator!=(const iterator& other) const { return next != other.next; }
  const char32_t& operator*() { return codepoint; }
 private:
  char32_t codepoint;
  const char* next;
  size_t len;
};

utf8::buffer_decoder::buffer_decoder(const char* str, size_t len) : str(str), len(len) {}

utf8::buffer_decoder::iterator utf8::buffer_decoder::begin() {
  return iterator(str, len);
}

utf8::buffer_decoder::iterator utf8::buffer_decoder::end() {
  return iterator(nullptr, 0);
}

utf8::buffer_decoder utf8::decoder(const char* str, size_t len) {
  return buffer_decoder(str, len);
}

void utf8::append(char*& str, char32_t chr) {
  if (chr < 0x80) *str++ = chr;
  else if (chr < 0x800) { *str++ = 0xC0 + (chr >> 6); *str++ = 0x80 + (chr & 0x3F); }
  else if (chr < 0x10000) { *str++ = 0xE0 + (chr >> 12); *str++ = 0x80 + ((chr >> 6) & 0x3F); *str++ = 0x80 + (chr & 0x3F); }
  else if (chr < 0x200000) { *str++ = 0xF0 + (chr >> 18); *str++ = 0x80 + ((chr >> 12) & 0x3F); *str++ = 0x80 + ((chr >> 6) & 0x3F); *str++ = 0x80 + (chr & 0x3F); }
  else *str++ = REPLACEMENT_CHAR;
}

void utf8::append(std::string& str, char32_t chr) {
  if (chr < 0x80) str += chr;
  else if (chr < 0x800) { str += 0xC0 + (chr >> 6); str += 0x80 + (chr & 0x3F); }
  else if (chr < 0x10000) { str += 0xE0 + (chr >> 12); str += 0x80 + ((chr >> 6) & 0x3F); str += 0x80 + (chr & 0x3F); }
  else if (chr < 0x200000) { str += 0xF0 + (chr >> 18); str += 0x80 + ((chr >> 12) & 0x3F); str += 0x80 + ((chr >> 6) & 0x3F); str += 0x80 + (chr & 0x3F); }
  else str += REPLACEMENT_CHAR;
}

template<class F> void utf8::map(F f, const char* str, std::string& result) {
  result.clear();

  for (char32_t chr; (chr = decode(str)); )
    append(result, f(chr));
}

template<class F> void utf8::map(F f, const char* str, size_t len, std::string& result) {
  result.clear();

  while (len)
    append(result, f(decode(str, len)));
}

template<class F> void utf8::map(F f, const std::string& str, std::string& result) {
  map(f, str.c_str(), result);
}

} // namespace unilib

/////////
// File: utils/binary_decoder.h
/////////

// This file is part of UFAL C++ Utils <http://github.com/ufal/cpp_utils/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

//
// Declarations
//

class binary_decoder_error : public runtime_error {
 public:
  explicit binary_decoder_error(const char* description) : runtime_error(description) {}
};

class binary_decoder {
 public:
  inline unsigned char* fill(unsigned len);

  inline unsigned next_1B() throw (binary_decoder_error);
  inline unsigned next_2B() throw (binary_decoder_error);
  inline unsigned next_4B() throw (binary_decoder_error);
  inline void next_str(string& str) throw (binary_decoder_error);
  template <class T> inline const T* next(unsigned elements) throw (binary_decoder_error);

  inline bool is_end();
  inline unsigned tell();
  inline void seek(unsigned pos) throw (binary_decoder_error);

 private:
  vector<unsigned char> buffer;
  const unsigned char* data;
  const unsigned char* data_end;
};

//
// Definitions
//

unsigned char* binary_decoder::fill(unsigned len) {
  buffer.resize(len);
  data = buffer.data();
  data_end = buffer.data() + len;

  return buffer.data();
}

unsigned binary_decoder::next_1B() throw (binary_decoder_error) {
  if (data + 1 > data_end) throw binary_decoder_error("No more data in binary_decoder");
  return *data++;
}

unsigned binary_decoder::next_2B() throw (binary_decoder_error) {
  if (data + sizeof(uint16_t) > data_end) throw binary_decoder_error("No more data in binary_decoder");
  unsigned result = *(uint16_t*)data;
  data += sizeof(uint16_t);
  return result;
}

unsigned binary_decoder::next_4B() throw (binary_decoder_error) {
  if (data + sizeof(uint32_t) > data_end) throw binary_decoder_error("No more data in binary_decoder");
  unsigned result = *(uint32_t*)data;
  data += sizeof(uint32_t);
  return result;
}

void binary_decoder::next_str(string& str) throw (binary_decoder_error) {
  unsigned len = next_1B();
  if (len == 255) len = next_4B();
  str.assign(next<char>(len), len);
}

template <class T> const T* binary_decoder::next(unsigned elements) throw (binary_decoder_error) {
  if (data + sizeof(T) * elements > data_end) throw binary_decoder_error("No more data in binary_decoder");
  const T* result = (const T*) data;
  data += sizeof(T) * elements;
  return result;
}

bool binary_decoder::is_end() {
  return data >= data_end;
}

unsigned binary_decoder::tell() {
  return data - buffer.data();
}

void binary_decoder::seek(unsigned pos) throw (binary_decoder_error) {
  if (pos > buffer.size()) throw binary_decoder_error("Cannot seek past end of binary_decoder");
  data = buffer.data() + pos;
}

/////////
// File: embedding/embedding.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

int embedding::lookup_word(const string& word, string& buffer) const {
  using namespace unilib;

  auto it = dictionary.find(word);
  if (it != dictionary.end()) return it->second;

  // We now apply several heuristics to find a match

  // Try locating uppercase/titlecase characters which we could lowercase
  bool first = true;
  unicode::category_t first_category = 0, other_categories = 0;
  for (auto&& chr : utf8::decoder(word)) {
    (first ? first_category : other_categories) |= unicode::category(chr);
    first = false;
  }

  if ((first_category & unicode::Lut) && (other_categories & unicode::Lut)) {
    // Lowercase all characters but the first
    buffer.clear();
    first = true;
    for (auto&& chr : utf8::decoder(word)) {
      utf8::append(buffer, first ? chr : unicode::lowercase(chr));
      first = false;
    }

    it = dictionary.find(buffer);
    if (it != dictionary.end()) return it->second;
  }

  if ((first_category & unicode::Lut) || (other_categories & unicode::Lut)) {
    utf8::map(unicode::lowercase, word, buffer);

    it = dictionary.find(buffer);
    if (it != dictionary.end()) return it->second;
  }

  // If the word starts with digit and contain only digits and non-letter characters
  // i.e. large number, date, time, try replacing it with first digit only.
  if ((first_category & unicode::N) && !(other_categories & unicode::L)) {
    buffer.clear();
    utf8::append(buffer, utf8::first(word));

    it = dictionary.find(buffer);
    if (it != dictionary.end()) return it->second;
  }

  return unknown_index;
}

int embedding::unknown_word() const {
  return unknown_index;
}

float* embedding::weight(int id) {
  if (id < 0 || id * dimension >= weights.size()) return nullptr;
  return weights.data() + id * dimension;
}

const float* embedding::weight(int id) const {
  if (id < 0 || id * dimension >= weights.size()) return nullptr;
  return weights.data() + id * dimension;
}

void embedding::load(binary_decoder& data) {
  // Load dimemsion
  dimension = data.next_4B();

  updatable_index = numeric_limits<decltype(updatable_index)>::max();

  // Load dictionary
  dictionary.clear();
  string word;
  for (unsigned size = data.next_4B(); size; size--) {
    data.next_str(word);
    dictionary.emplace(word, dictionary.size());
  }

  unknown_index = data.next_1B() ? dictionary.size() : -1;

  // Load weights
  const float* weights_ptr = data.next<float>(dimension * (dictionary.size() + (unknown_index >= 0)));
  weights.assign(weights_ptr, weights_ptr + dimension * (dictionary.size() + (unknown_index >= 0)));
}

/////////
// File: network/activation_function.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

struct activation_function {
  enum type { TANH = 0, CUBIC = 1 };

  static bool create(string_piece name, type& activation) {
    if (name == "tanh") return activation = TANH, true;
    if (name == "cubic") return activation = CUBIC, true;
    return false;
  }
};

/////////
// File: network/neural_network.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class neural_network {
 public:
  typedef vector<vector<vector<float>>> embeddings_cache;

  void propagate(const vector<embedding>& embeddings, const vector<const vector<int>*>& embedding_ids_sequences,
                 vector<float>& hidden_layer, vector<float>& outcomes, const embeddings_cache* cache = nullptr, bool softmax = true) const;

  void load(binary_decoder& data);
  void generate_tanh_cache();
  void generate_embeddings_cache(const vector<embedding>& embeddings, embeddings_cache& cache, unsigned max_words) const;

 private:
  friend class neural_network_trainer;

  void load_matrix(binary_decoder& data, vector<vector<float>>& m);

  activation_function::type hidden_layer_activation;
  vector<vector<float>> weights[2];

  vector<float> tanh_cache;
};

/////////
// File: network/neural_network.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

void neural_network::load_matrix(binary_decoder& data, vector<vector<float>>& m) {
  unsigned rows = data.next_4B();
  unsigned columns = data.next_4B();

  m.resize(rows);
  for (auto&& row : m) {
    const float* row_ptr = data.next<float>(columns);
    row.assign(row_ptr, row_ptr + columns);
  }
}

void neural_network::load(binary_decoder& data) {
  hidden_layer_activation = activation_function::type(data.next_1B());
  load_matrix(data, weights[0]);
  load_matrix(data, weights[1]);
}

void neural_network::propagate(const vector<embedding>& embeddings, const vector<const vector<int>*>& embedding_ids_sequences,
                               vector<float>& hidden_layer, vector<float>& outcomes, const embeddings_cache* cache, bool softmax) const {
  assert(!weights[0].empty());
  assert(!weights[1].empty());
  for (auto&& embedding_ids : embedding_ids_sequences) if (embedding_ids) assert(embeddings.size() == embedding_ids->size());

  unsigned hidden_layer_size = weights[0].front().size();
  unsigned outcomes_size = weights[1].front().size();

  outcomes.assign(outcomes_size, 0);

  // Hidden layer
  hidden_layer.assign(hidden_layer_size, 0);

  unsigned index = 0;
  for (unsigned sequence = 0; sequence < embedding_ids_sequences.size(); sequence++)
    for (unsigned i = 0; i < embeddings.size(); index += embeddings[i].dimension, i++)
      if (embedding_ids_sequences[sequence] && embedding_ids_sequences[sequence]->at(i) >= 0) {
        unsigned word = embedding_ids_sequences[sequence]->at(i);
        if (cache && i < cache->size() && word < cache->at(i).size()) {
          // Use cache
          const float* precomputed = cache->at(i)[word].data() + sequence * hidden_layer_size;
          for (unsigned j = 0; j < hidden_layer_size; j++)
            hidden_layer[j] += precomputed[j];
        } else {
          // Compute directly
          const float* embedding = embeddings[i].weight(word);
          for (unsigned j = 0; j < embeddings[i].dimension; j++)
            for (unsigned k = 0; k < hidden_layer_size; k++)
              hidden_layer[k] += embedding[j] * weights[0][index + j][k];
        }
      }
  for (unsigned i = 0; i < hidden_layer_size; i++) // Bias
    hidden_layer[i] += weights[0][index][i];

  // Activation function
  switch (hidden_layer_activation) {
    case activation_function::TANH:
      if (!tanh_cache.empty())
        for (auto&& weight : hidden_layer)
          weight = weight <= -10 ? -1 : weight >= 10 ? 1 : tanh_cache[int(weight * 32768 + 10 * 32768)];
      else
        for (auto&& weight : hidden_layer)
          weight = tanh(weight);
      break;
    case activation_function::CUBIC:
      for (auto&& weight : hidden_layer)
        weight = weight * weight * weight;
      break;
  }

  for (unsigned i = 0; i < hidden_layer_size; i++)
    for (unsigned j = 0; j < outcomes_size; j++)
      outcomes[j] += hidden_layer[i] * weights[1][i][j];
  for (unsigned i = 0; i < outcomes_size; i++) // Bias
    outcomes[i] += weights[1][hidden_layer_size][i];

  // Softmax if requested
  if (softmax) {
    float max = outcomes[0];
    for (unsigned i = 1; i < outcomes_size; i++) if (outcomes[i] > max) max = outcomes[i];

    float sum = 0;
    for (unsigned i = 0; i < outcomes_size; i++) sum += (outcomes[i] = exp(outcomes[i] - max));
    sum = 1 / sum;

    for (unsigned i = 0; i < outcomes_size; i++) outcomes[i] *= sum;
  }
}

void neural_network::generate_tanh_cache() {
  tanh_cache.resize(2 * 10 * 32768);
  for (unsigned i = 0; i < tanh_cache.size(); i++)
    tanh_cache[i] = tanh(i / 32768.0 - 10);
}

void neural_network::generate_embeddings_cache(const vector<embedding>& embeddings, embeddings_cache& cache, unsigned max_words) const {
  unsigned embeddings_dim = 0;
  for (auto&& embedding : embeddings) embeddings_dim += embedding.dimension;

  unsigned sequences = weights[0].size() / embeddings_dim;
  assert(sequences * embeddings_dim + 1 == weights[0].size());

  unsigned hidden_layer_size = weights[0].front().size();

  cache.resize(embeddings.size());
  for (unsigned i = 0, weight_index = 0; i < embeddings.size(); weight_index += embeddings[i].dimension, i++) {
    unsigned words = 0;
    while (words < max_words && embeddings[i].weight(words)) words++;

    cache[i].resize(words);
    for (unsigned word = 0; word < words; word++) {
      const float* embedding = embeddings[i].weight(word);

      cache[i][word].assign(sequences * hidden_layer_size, 0);
      for (unsigned sequence = 0, index = weight_index; sequence < sequences; index += embeddings_dim, sequence++)
        for (unsigned j = 0; j < embeddings[i].dimension; j++)
          for (unsigned k = 0; k < hidden_layer_size; k++)
            cache[i][word][sequence * hidden_layer_size + k] += embedding[j] * weights[0][index + j][k];
    }
  }
}

/////////
// File: parser/parser.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Parser
class parser {
 public:
  virtual ~parser() {};

  virtual void parse(tree& t, unsigned beam_size = 0) const = 0;

  enum { NO_CACHE = 0, FULL_CACHE = 2147483647};
  static parser* load(const char* file, unsigned cache = 1000);
  static parser* load(istream& in, unsigned cache = 1000);

 protected:
  virtual void load(binary_decoder& data, unsigned cache) = 0;
  static parser* create(const string& name);
};

/////////
// File: transition/transition.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Abstract transition class
class transition {
 public:
  virtual ~transition() {}

  virtual bool applicable(const configuration& conf) const = 0;
  virtual int perform(configuration& conf) const = 0;
};

// Specific transition classes
class transition_left_arc : public transition {
 public:
  transition_left_arc(const string& label) : label(label) {}

  virtual bool applicable(const configuration& conf) const override;
  virtual int perform(configuration& conf) const override;
 private:
  string label;
};

class transition_right_arc : public transition {
 public:
  transition_right_arc(const string& label) : label(label) {}

  virtual bool applicable(const configuration& conf) const override;
  virtual int perform(configuration& conf) const override;
 private:
  string label;
};

class transition_shift : public transition {
 public:
  virtual bool applicable(const configuration& conf) const override;
  virtual int perform(configuration& conf) const override;
};

class transition_swap : public transition {
 public:
  virtual bool applicable(const configuration& conf) const override;
  virtual int perform(configuration& conf) const override;
};

class transition_left_arc_2 : public transition {
 public:
  transition_left_arc_2(const string& label) : label(label) {}

  virtual bool applicable(const configuration& conf) const override;
  virtual int perform(configuration& conf) const override;
 private:
  string label;
};

class transition_right_arc_2 : public transition {
 public:
  transition_right_arc_2(const string& label) : label(label) {}

  virtual bool applicable(const configuration& conf) const override;
  virtual int perform(configuration& conf) const override;
 private:
  string label;
};

/////////
// File: transition/transition_oracle.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class transition_oracle {
 public:
  virtual ~transition_oracle() {}

  struct predicted_transition {
    unsigned best;
    unsigned to_follow;

    predicted_transition(unsigned best, unsigned to_follow) : best(best), to_follow(to_follow) {}
  };

  class tree_oracle {
   public:
    virtual ~tree_oracle() {}

    virtual predicted_transition predict(const configuration& conf, unsigned network_outcome, unsigned iteration) const = 0;
    virtual void interesting_transitions(const configuration& conf, vector<unsigned>& transitions) const = 0;
  };

  virtual unique_ptr<tree_oracle> create_tree_oracle(const tree& gold) const = 0;
};

/////////
// File: transition/transition_system.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class transition_system {
 public:
  virtual ~transition_system() {}

  virtual unsigned transition_count() const;
  virtual bool applicable(const configuration& conf, unsigned transition) const;
  virtual int perform(configuration& conf, unsigned transition) const;
  virtual transition_oracle* oracle(const string& name) const = 0;

  static transition_system* create(const string& name, const vector<string>& labels);

 protected:
  transition_system(const vector<string>& labels) : labels(labels) {}

  const vector<string>& labels;
  vector<unique_ptr<transition>> transitions;
};

/////////
// File: utils/threadsafe_stack.h
/////////

// This file is part of UFAL C++ Utils <http://github.com/ufal/cpp_utils/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

//
// Declarations
//

template <class T>
class threadsafe_stack {
 public:
  inline void push(T* t);
  inline T* pop();

 private:
  vector<unique_ptr<T>> stack;
  atomic_flag lock = ATOMIC_FLAG_INIT;
};

//
// Definitions
//

template <class T>
void threadsafe_stack<T>::push(T* t) {
  while (lock.test_and_set(memory_order_acquire)) {}
  stack.emplace_back(t);
  lock.clear(memory_order_release);
}

template <class T>
T* threadsafe_stack<T>::pop() {
  T* res = nullptr;

  while (lock.test_and_set(memory_order_acquire)) {}
  if (!stack.empty()) {
    res = stack.back().release();
    stack.pop_back();
  }
  lock.clear(memory_order_release);

  return res;
}

/////////
// File: parser/parser_nn.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class parser_nn : public parser {
 public:
  virtual void parse(tree& t, unsigned beam_size = 0) const override;

 protected:
  virtual void load(binary_decoder& data, unsigned cache) override;

 private:
  friend class parser_nn_trainer;
  void parse_greedy(tree& t) const;
  void parse_beam_search(tree& t, unsigned beam_size) const;

  vector<string> labels;
  unique_ptr<transition_system> system;

  node_extractor nodes;

  vector<value_extractor> values;
  vector<embedding> embeddings;

  neural_network network;
  neural_network::embeddings_cache embeddings_cache;

  struct workspace {
    configuration conf;

    string word, word_buffer;
    vector<vector<int>> embeddings;
    vector<vector<string>> embeddings_values;

    vector<int> extracted_nodes;
    vector<const vector<int>*> extracted_embeddings;

    vector<float> outcomes, network_buffer;

    // Beam-size structures
    struct beam_size_configuration {
      configuration conf;
      vector<int> heads;
      vector<string> deprels;
      double cost;

      void refresh_tree();
      void save_tree();
    };
    struct beam_size_alternative {
      const beam_size_configuration* bs_conf;
      int transition;
      double cost;
      bool operator<(const beam_size_alternative& other) const { return cost > other.cost; }

      beam_size_alternative(const beam_size_configuration* bs_conf, int transition, double cost)
          : bs_conf(bs_conf), transition(transition), cost(cost) {}
    };
    vector<beam_size_configuration> bs_confs[2]; size_t bs_confs_size[2];
    vector<beam_size_alternative> bs_alternatives;
  };
  mutable threadsafe_stack<workspace> workspaces;
};

/////////
// File: utils/compressor.h
/////////

// This file is part of UFAL C++ Utils <http://github.com/ufal/cpp_utils/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class binary_decoder;
class binary_encoder;

class compressor {
 public:
  static bool load(istream& is, binary_decoder& data);
  static bool save(ostream& os, const binary_encoder& enc);
};

/////////
// File: parser/parser.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

parser* parser::load(const char* file, unsigned cache) {
  ifstream in(file, ifstream::in | ifstream::binary);
  if (!in.is_open()) return nullptr;
  return load(in, cache);
}

parser* parser::load(istream& in, unsigned cache) {
  unique_ptr<parser> result;

  binary_decoder data;
  if (!compressor::load(in, data)) return nullptr;

  try {
    string name;
    data.next_str(name);

    result.reset(create(name));
    if (!result) return nullptr;

    result->load(data, cache);
  } catch (binary_decoder_error&) {
    return nullptr;
  }

  return result && data.is_end() ? result.release() : nullptr;
}

parser* parser::create(const string& name) {
  if (name == "nn") return new parser_nn();
  return nullptr;
}

/////////
// File: parser/parser_nn.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

void parser_nn::parse(tree& t, unsigned beam_size) const {
  if (beam_size > 1)
    parse_beam_search(t, beam_size);
  else
    parse_greedy(t);
}

void parser_nn::parse_greedy(tree& t) const {
  assert(system);

  // Retrieve or create workspace
  workspace* w = workspaces.pop();
  if (!w) w = new workspace();

  // Create configuration
  w->conf.init(&t);

  // Compute embeddings of all nodes
  if (w->embeddings.size() < t.nodes.size()) w->embeddings.resize(t.nodes.size());
  for (size_t i = 0; i < t.nodes.size(); i++) {
    if (w->embeddings[i].size() < embeddings.size()) w->embeddings[i].resize(embeddings.size());
    for (size_t j = 0; j < embeddings.size(); j++) {
      values[j].extract(t.nodes[i], w->word);
      w->embeddings[i][j] = embeddings[j].lookup_word(w->word, w->word_buffer);
    }
  }

  // Compute which transitions to perform and perform them
  while (!w->conf.final()) {
    // Extract nodes from the configuration
    nodes.extract(w->conf, w->extracted_nodes);
    w->extracted_embeddings.resize(w->extracted_nodes.size());
    for (size_t i = 0; i < w->extracted_nodes.size(); i++)
      w->extracted_embeddings[i] = w->extracted_nodes[i] >= 0 ? &w->embeddings[w->extracted_nodes[i]] : nullptr;

    // Classify using neural network
    network.propagate(embeddings, w->extracted_embeddings, w->network_buffer, w->outcomes, &embeddings_cache, false);

    // Find most probable applicable transition
    int best = -1;
    for (unsigned i = 0; i < w->outcomes.size(); i++)
      if (system->applicable(w->conf, i) && (best < 0 || w->outcomes[i] > w->outcomes[best]))
        best = i;

    // Perform the best transition
    int child = system->perform(w->conf, best);

    // If a node was linked, recompute its embeddings as deprel has changed
    if (child >= 0)
      for (size_t i = 0; i < embeddings.size(); i++) {
        values[i].extract(t.nodes[child], w->word);
        w->embeddings[child][i] = embeddings[i].lookup_word(w->word, w->word_buffer);
      }
  }

  // Store workspace
  workspaces.push(w);
}

void parser_nn::parse_beam_search(tree& t, unsigned beam_size) const {
  assert(system);

  // Retrieve or create workspace
  workspace* w = workspaces.pop();
  if (!w) w = new workspace();

  // Allocate and initialize configuration
  for (int i = 0; i < 2; i++) {
    w->bs_confs[i].resize(beam_size);
    w->bs_confs_size[i] = 0;
  }
  w->bs_confs[0][0].cost = 0;
  w->bs_confs[0][0].conf.init(&t);
  w->bs_confs[0][0].save_tree();
  w->bs_confs_size[0] = 1;

  // Compute embeddings of all nodes
  if (w->embeddings.size() < t.nodes.size()) w->embeddings.resize(t.nodes.size());
  if (w->embeddings_values.size() < t.nodes.size()) w->embeddings_values.resize(t.nodes.size());
  for (size_t i = 0; i < t.nodes.size(); i++) {
    if (w->embeddings[i].size() < embeddings.size()) w->embeddings[i].resize(embeddings.size());
    if (w->embeddings_values[i].size() < embeddings.size()) w->embeddings_values[i].resize(embeddings.size());
    for (size_t j = 0; j < embeddings.size(); j++) {
      values[j].extract(t.nodes[i], w->embeddings_values[i][j]);
      w->embeddings[i][j] = embeddings[j].lookup_word(w->embeddings_values[i][j], w->word_buffer);
    }
  }

  // Compute which transitions to perform and perform them
  size_t iteration = 0;
  for (bool all_final = false; !all_final; iteration++) {
    all_final = true;
    w->bs_alternatives.clear();

    for (size_t c = 0; c < w->bs_confs_size[iteration & 1]; c++) {
      auto& bs_conf = w->bs_confs[iteration & 1][c];

      if (bs_conf.conf.final()) {
        if (w->bs_alternatives.size() == beam_size) {
          if (bs_conf.cost <= w->bs_alternatives[0].cost) continue;
          pop_heap(w->bs_alternatives.begin(), w->bs_alternatives.end());
          w->bs_alternatives.pop_back();
        }
        w->bs_alternatives.emplace_back(&bs_conf, -1, bs_conf.cost);
        push_heap(w->bs_alternatives.begin(), w->bs_alternatives.end());
        continue;
      }
      all_final = false;

      bs_conf.refresh_tree();
      // Update embeddings for all nodes
      for (size_t i = 0; i < t.nodes.size(); i++)
        for (size_t j = 0; j < embeddings.size(); j++) {
          values[j].extract(t.nodes[i], w->word);
          if (w->word != w->embeddings_values[i][j]) {
            w->embeddings[i][j] = embeddings[j].lookup_word(w->word, w->word_buffer);
            w->embeddings_values[i][j].assign(w->word);
          }
        }

      // Extract nodes from the configuration
      nodes.extract(bs_conf.conf, w->extracted_nodes);
      w->extracted_embeddings.resize(w->extracted_nodes.size());
      for (size_t i = 0; i < w->extracted_nodes.size(); i++)
        w->extracted_embeddings[i] = w->extracted_nodes[i] >= 0 ? &w->embeddings[w->extracted_nodes[i]] : nullptr;

      // Classify using neural network
      network.propagate(embeddings, w->extracted_embeddings, w->network_buffer, w->outcomes, &embeddings_cache);

      // Store all alternatives
      for (unsigned i = 0; i < w->outcomes.size(); i++)
        if (system->applicable(bs_conf.conf, i)) {
          double cost = (bs_conf.cost * iteration + log(w->outcomes[i])) / (iteration + 1);
          if (w->bs_alternatives.size() == beam_size) {
            if (cost <= w->bs_alternatives[0].cost) continue;
            pop_heap(w->bs_alternatives.begin(), w->bs_alternatives.end());
            w->bs_alternatives.pop_back();
          }
          w->bs_alternatives.emplace_back(&bs_conf, i, cost);
          push_heap(w->bs_alternatives.begin(), w->bs_alternatives.end());
        }
    }

    w->bs_confs_size[(iteration + 1) & 1] = 0;
    for (auto&& alternative : w->bs_alternatives) {
      auto& bs_conf_new = w->bs_confs[(iteration + 1) & 1][w->bs_confs_size[(iteration + 1) & 1]++];
      bs_conf_new = *alternative.bs_conf;
      bs_conf_new.cost = alternative.cost;
      if (alternative.transition >= 0) {
        bs_conf_new.refresh_tree();
        system->perform(bs_conf_new.conf, alternative.transition);
        bs_conf_new.save_tree();
      }
    }
  }

  // Return the best tree
  size_t best = 0;
  for (size_t i = 1; i < w->bs_confs_size[iteration & 1]; i++)
    if (w->bs_confs[iteration & 1][i].cost > w->bs_confs[iteration & 1][best].cost)
      best = i;
  w->bs_confs[iteration & 1][best].refresh_tree();

  // Store workspace
  workspaces.push(w);
}

void parser_nn::workspace::beam_size_configuration::refresh_tree() {
  for (auto&& node : conf.t->nodes) node.children.clear();
  for (size_t i = 0; i < conf.t->nodes.size(); i++) {
    conf.t->nodes[i].head = heads[i];
    conf.t->nodes[i].deprel = deprels[i];
    if (heads[i] >= 0) conf.t->nodes[heads[i]].children.push_back(i);
  }
}

void parser_nn::workspace::beam_size_configuration::save_tree() {
  if (conf.t->nodes.size() > heads.size()) heads.resize(conf.t->nodes.size());
  if (conf.t->nodes.size() > deprels.size()) deprels.resize(conf.t->nodes.size());
  for (size_t i = 0; i < conf.t->nodes.size(); i++) {
    heads[i] = conf.t->nodes[i].head;
    deprels[i] = conf.t->nodes[i].deprel;
  }
}

void parser_nn::load(binary_decoder& data, unsigned cache) {
  string description, error;

  // Load labels
  labels.resize(data.next_2B());
  for (auto&& label : labels)
    data.next_str(label);

  // Load transition system
  string system_name;
  data.next_str(system_name);
  system.reset(transition_system::create(system_name, labels));
  if (!system) throw binary_decoder_error("Cannot load transition system");

  // Load node extractor
  data.next_str(description);
  if (!nodes.create(description, error))
    throw binary_decoder_error(error.c_str());

  // Load value extractors and embeddings
  values.resize(data.next_2B());
  for (auto&& value : values) {
    data.next_str(description);
    if (!value.create(description, error))
      throw binary_decoder_error(error.c_str());
  }

  embeddings.resize(values.size());
  for (auto&& embedding : embeddings)
    embedding.load(data);

  // Load the network
  network.load(data);
  network.generate_tanh_cache();
  network.generate_embeddings_cache(embeddings, embeddings_cache, cache);
}

/////////
// File: transition/transition.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Left arc
bool transition_left_arc::applicable(const configuration& conf) const {
  return conf.stack.size() >= 2 && conf.stack[conf.stack.size() - 2];
}

int transition_left_arc::perform(configuration& conf) const {
  assert(applicable(conf));

  int parent = conf.stack.back(); conf.stack.pop_back();
  int child = conf.stack.back(); conf.stack.pop_back();
  conf.stack.push_back(parent);
  conf.t->set_head(child, parent, label);
  return child;
}

// Right arc
bool transition_right_arc::applicable(const configuration& conf) const {
  return conf.stack.size() >= 2;
}

int transition_right_arc::perform(configuration& conf) const {
  assert(applicable(conf));

  int child = conf.stack.back(); conf.stack.pop_back();
  int parent = conf.stack.back();
  conf.t->set_head(child, parent, label);
  return child;
}

// Shift
bool transition_shift::applicable(const configuration& conf) const {
  return !conf.buffer.empty();
}

int transition_shift::perform(configuration& conf) const {
  assert(applicable(conf));

  conf.stack.push_back(conf.buffer.back());
  conf.buffer.pop_back();
  return -1;
}

// Swap
bool transition_swap::applicable(const configuration& conf) const {
  return conf.stack.size() >= 2 && conf.stack[conf.stack.size() - 2] && conf.stack[conf.stack.size() - 2] < conf.stack[conf.stack.size() - 1];
}

int transition_swap::perform(configuration& conf) const {
  assert(applicable(conf));

  int top = conf.stack.back(); conf.stack.pop_back();
  int to_buffer = conf.stack.back(); conf.stack.pop_back();
  conf.stack.push_back(top);
  conf.buffer.push_back(to_buffer);
  return -1;
}

// Left arc 2
bool transition_left_arc_2::applicable(const configuration& conf) const {
  return conf.stack.size() >= 3 && conf.stack[conf.stack.size() - 3];
}

int transition_left_arc_2::perform(configuration& conf) const {
  assert(applicable(conf));

  int parent = conf.stack.back(); conf.stack.pop_back();
  int ignore = conf.stack.back(); conf.stack.pop_back();
  int child = conf.stack.back(); conf.stack.pop_back();
  conf.stack.push_back(ignore);
  conf.stack.push_back(parent);
  conf.t->set_head(child, parent, label);
  return child;
}

// Right arc 2
bool transition_right_arc_2::applicable(const configuration& conf) const {
  return conf.stack.size() >= 3;
}

int transition_right_arc_2::perform(configuration& conf) const {
  assert(applicable(conf));

  int child = conf.stack.back(); conf.stack.pop_back();
  int to_buffer = conf.stack.back(); conf.stack.pop_back();
  int parent = conf.stack.back();
  conf.buffer.push_back(to_buffer);
  conf.t->set_head(child, parent, label);
  return child;
}

/////////
// File: transition/transition_system_link2.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class transition_system_link2 : public transition_system {
 public:
  transition_system_link2(const vector<string>& labels);

  virtual transition_oracle* oracle(const string& name) const override;
};

/////////
// File: transition/transition_system_projective.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class transition_system_projective : public transition_system {
 public:
  transition_system_projective(const vector<string>& labels);

  virtual transition_oracle* oracle(const string& name) const override;
};

/////////
// File: transition/transition_system_swap.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class transition_system_swap : public transition_system {
 public:
  transition_system_swap(const vector<string>& labels);

  virtual transition_oracle* oracle(const string& name) const override;
};

/////////
// File: transition/transition_system.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

unsigned transition_system::transition_count() const {
  return transitions.size();
}

bool transition_system::applicable(const configuration& conf, unsigned transition) const {
  assert(transition < transitions.size());

  return transitions[transition]->applicable(conf);
}

int transition_system::perform(configuration& conf, unsigned transition) const {
  assert(transition < transitions.size());

  return transitions[transition]->perform(conf);
}

transition_system* transition_system::create(const string& name, const vector<string>& labels) {
  if (name == "projective") return new transition_system_projective(labels);
  if (name == "swap") return new transition_system_swap(labels);
  if (name == "link2") return new transition_system_link2(labels);
  return nullptr;
}

/////////
// File: transition/transition_system_link2.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

transition_system_link2::transition_system_link2(const vector<string>& labels) : transition_system(labels) {
  transitions.emplace_back(new transition_shift());
  for (auto&& label : labels) {
    transitions.emplace_back(new transition_left_arc(label));
    transitions.emplace_back(new transition_right_arc(label));
    transitions.emplace_back(new transition_left_arc_2(label));
    transitions.emplace_back(new transition_right_arc_2(label));
  }
}

// Static oracle
class transition_system_link2_oracle_static : public transition_oracle {
 public:
  transition_system_link2_oracle_static(const vector<string>& labels) : labels(labels) {}

  class tree_oracle_static : public transition_oracle::tree_oracle {
   public:
    tree_oracle_static(const vector<string>& labels, const tree& gold) : labels(labels), gold(gold) {}
    virtual predicted_transition predict(const configuration& conf, unsigned network_outcome, unsigned iteration) const override;
    virtual void interesting_transitions(const configuration& conf, vector<unsigned>& transitions) const override;
   private:
    const vector<string>& labels;
    const tree& gold;
  };

  virtual unique_ptr<tree_oracle> create_tree_oracle(const tree& gold) const override;
 private:
  const vector<string>& labels;
};

unique_ptr<transition_oracle::tree_oracle> transition_system_link2_oracle_static::create_tree_oracle(const tree& gold) const {
  return unique_ptr<transition_oracle::tree_oracle>(new tree_oracle_static(labels, gold));
}

void transition_system_link2_oracle_static::tree_oracle_static::interesting_transitions(const configuration& conf, vector<unsigned>& transitions) const {
  transitions.clear();

  // Shift
  if (!conf.buffer.empty()) transitions.push_back(0);

  // Arcs
  unsigned parents[4] = {1, 2, 1, 3};
  unsigned children[4] = {2, 1, 3, 1};
  for (int direction = 0; direction < 4; direction++)
    if (conf.stack.size() >= parents[direction] && conf.stack.size() >= children[direction]) {
      int parent = conf.stack[conf.stack.size() - parents[direction]];
      int child = conf.stack[conf.stack.size() - children[direction]];

      // Allow arc_2 only when seeing golden edge.
      if (direction >= 2 && gold.nodes[child].head != parent) continue;

      for (size_t i = 0; i < labels.size(); i++)
        if (gold.nodes[child].deprel == labels[i])
          transitions.push_back(1 + 4*i + direction);
    }
}

transition_oracle::predicted_transition transition_system_link2_oracle_static::tree_oracle_static::predict(const configuration& conf, unsigned /*network_outcome*/, unsigned /*iteration*/) const {
  // Arcs
  unsigned parents[4] = {1, 2, 1, 3};
  unsigned children[4] = {2, 1, 3, 1};
  for (int direction = 0; direction < 4; direction++)
    if (conf.stack.size() >= parents[direction] && conf.stack.size() >= children[direction]) {
      int parent = conf.stack[conf.stack.size() - parents[direction]];
      int child = conf.stack[conf.stack.size() - children[direction]];

      if (gold.nodes[child].head == parent && gold.nodes[child].children.size() == conf.t->nodes[child].children.size()) {
        for (size_t i = 0; i < labels.size(); i++)
          if (gold.nodes[child].deprel == labels[i])
            return predicted_transition(1 + 4*i + direction, 1 + 4*i + direction);

        assert(!"label was not found");
      }
    }

  // Otherwise, just shift
  return predicted_transition(0, 0);
}

// Oracle factory method
transition_oracle* transition_system_link2::oracle(const string& name) const {
  if (name == "static") return new transition_system_link2_oracle_static(labels);
  return nullptr;
}

/////////
// File: transition/transition_system_projective.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

transition_system_projective::transition_system_projective(const vector<string>& labels) : transition_system(labels) {
  transitions.emplace_back(new transition_shift());
  for (auto&& label : labels) {
    transitions.emplace_back(new transition_left_arc(label));
    transitions.emplace_back(new transition_right_arc(label));
  }
}

// Static oracle
class transition_system_projective_oracle_static : public transition_oracle {
 public:
  transition_system_projective_oracle_static(const vector<string>& labels) : labels(labels) {}

  class tree_oracle_static : public transition_oracle::tree_oracle {
   public:
    tree_oracle_static(const vector<string>& labels, const tree& gold) : labels(labels), gold(gold) {}
    virtual predicted_transition predict(const configuration& conf, unsigned network_outcome, unsigned iteration) const override;
    virtual void interesting_transitions(const configuration& conf, vector<unsigned>& transitions) const override;
   private:
    const vector<string>& labels;
    const tree& gold;
  };

  virtual unique_ptr<tree_oracle> create_tree_oracle(const tree& gold) const override;
 private:
  const vector<string>& labels;
};

unique_ptr<transition_oracle::tree_oracle> transition_system_projective_oracle_static::create_tree_oracle(const tree& gold) const {
  return unique_ptr<transition_oracle::tree_oracle>(new tree_oracle_static(labels, gold));
}

void transition_system_projective_oracle_static::tree_oracle_static::interesting_transitions(const configuration& conf, vector<unsigned>& transitions) const {
  transitions.clear();
  if (!conf.buffer.empty()) transitions.push_back(0);
  if (conf.stack.size() >= 2)
    for (int direction = 0; direction < 2; direction++) {
      int child = conf.stack[conf.stack.size() - 2 + direction];
      for (size_t i = 0; i < labels.size(); i++)
        if (gold.nodes[child].deprel == labels[i])
          transitions.push_back(1 + 2*i + direction);
    }
}

transition_oracle::predicted_transition transition_system_projective_oracle_static::tree_oracle_static::predict(const configuration& conf, unsigned /*network_outcome*/, unsigned /*iteration*/) const {
  // Use left if appropriate
  if (conf.stack.size() >= 2) {
    int parent = conf.stack[conf.stack.size() - 1];
    int child = conf.stack[conf.stack.size() - 2];
    if (gold.nodes[child].head == parent) {
      for (size_t i = 0; i < labels.size(); i++)
        if (gold.nodes[child].deprel == labels[i])
          return predicted_transition(1 + 2*i, 1 + 2*i);

      assert(!"label was not found");
    }
  }

  // Use right if appropriate
  if (conf.stack.size() >= 2) {
    int child = conf.stack[conf.stack.size() - 1];
    int parent = conf.stack[conf.stack.size() - 2];
    if (gold.nodes[child].head == parent &&
        (conf.buffer.empty() || gold.nodes[child].children.empty() || gold.nodes[child].children.back() < conf.buffer.back())) {
      for (size_t i = 0; i < labels.size(); i++)
        if (gold.nodes[child].deprel == labels[i])
          return predicted_transition(1 + 2*i + 1, 1 + 2*i + 1);

      assert(!"label was not found");
    }
  }

  // Otherwise, just shift
  return predicted_transition(0, 0);
}

// Dynamic oracle
class transition_system_projective_oracle_dynamic : public transition_oracle {
 public:
  transition_system_projective_oracle_dynamic(const vector<string>& labels) : labels(labels) {}

  class tree_oracle_dynamic : public transition_oracle::tree_oracle {
   public:
    tree_oracle_dynamic(const vector<string>& labels, const tree& gold) : labels(labels), gold(gold), oracle_static(labels, gold) {}
    virtual predicted_transition predict(const configuration& conf, unsigned network_outcome, unsigned iteration) const override;
    virtual void interesting_transitions(const configuration& conf, vector<unsigned>& transitions) const override;
   private:
    const vector<string>& labels;
    const tree& gold;
    transition_system_projective_oracle_static::tree_oracle_static oracle_static;
  };

  virtual unique_ptr<tree_oracle> create_tree_oracle(const tree& gold) const override;
 private:
  const vector<string>& labels;
};

unique_ptr<transition_oracle::tree_oracle> transition_system_projective_oracle_dynamic::create_tree_oracle(const tree& gold) const {
  return unique_ptr<transition_oracle::tree_oracle>(new tree_oracle_dynamic(labels, gold));
}

void transition_system_projective_oracle_dynamic::tree_oracle_dynamic::interesting_transitions(const configuration& conf, vector<unsigned>& transitions) const {
  transitions.clear();
  if (!conf.buffer.empty()) transitions.push_back(0);
  if (conf.stack.size() >= 2)
    for (int direction = 0; direction < 2; direction++) {
      int child = conf.stack[conf.stack.size() - 2 + direction];
      for (size_t i = 0; i < labels.size(); i++)
        if (gold.nodes[child].deprel == labels[i])
          transitions.push_back(1 + 2*i + direction);
    }
}

transition_oracle::predicted_transition transition_system_projective_oracle_dynamic::tree_oracle_dynamic::predict(const configuration& conf, unsigned network_outcome, unsigned iteration) const {
  // Use static oracle in the first iteration
  if (iteration <= 1)
    return oracle_static.predict(conf, network_outcome, iteration);

  // Use dynamic programming to compute transition leading to best parse tree

  // Start by computing the right stack
  vector<int> right_stack;

  unordered_set<int> right_stack_inserted;
  if (!conf.buffer.empty()) {
    int buffer_start = conf.buffer.back();
    for (size_t i = conf.buffer.size(); i--; ) {
      const auto& node = conf.buffer[i];
      bool to_right_stack = gold.nodes[node].head < buffer_start;
      for (auto&& child : gold.nodes[node].children)
        to_right_stack |= child < buffer_start || right_stack_inserted.count(child);
      if (to_right_stack) {
        right_stack.push_back(node);
        right_stack_inserted.insert(node);
      }
    }
  }

  // Fill the array T from the 2014 Goldberg paper
  class t_representation {
   public:
    t_representation(const vector<int>& stack, const vector<int>& right_stack, const tree& gold, const vector<string>& labels)
        : stack(stack), right_stack(right_stack), gold(gold), labels(labels) {
      for (int i = 0; i < 2; i++) {
        costs[i].reserve((stack.size() + right_stack.size()) * (stack.size() + right_stack.size()));
        transitions[i].reserve((stack.size() + right_stack.size()) * (stack.size() + right_stack.size()));
      }
    }

    void prepare(unsigned diagonal) {
      costs[diagonal & 1].assign((diagonal + 1) * (diagonal + 1), gold.nodes.size() + 1);
      transitions[diagonal & 1].assign((diagonal + 1) * (diagonal + 1), -1);
    }

    int& cost(unsigned i, unsigned j, unsigned h) { return costs[(i+j) & 1][i * (i+j+1) + h]; }
    int& transition(unsigned i, unsigned j, unsigned h) { return transitions[(i+j) & 1][i * (i+j+1) + h]; }

    int node(unsigned i, unsigned /*j*/, unsigned h) const { return h <= i ? stack[stack.size() - 1 - i + h] : right_stack[h - i - 1]; }
    int edge_cost(int parent, int child) const { return gold.nodes[child].head != parent; }
    int which_arc_transition(int parent, int child) const {
      for (size_t i = 0; i < labels.size(); i++)
        if (gold.nodes[child].deprel == labels[i])
          return 1 + 2*i + (child > parent);
      assert(!"label was not found");
      return 0; // To keep VS 2015 happy and warning-free
    }

   private:
    const vector<int>& stack;
    const vector<int>& right_stack;
    const tree& gold;
    const vector<string>& labels;
    vector<int> costs[2], transitions[2];
  } t(conf.stack, right_stack, gold, labels);

  t.prepare(0);
  t.cost(0, 0, 0) = 0;
  for (unsigned diagonal = 0; diagonal < conf.stack.size() + right_stack.size(); diagonal++) {
    t.prepare(diagonal + 1);
    for (unsigned i = diagonal > right_stack.size() ? diagonal - right_stack.size() : 0; i <= diagonal && i < conf.stack.size(); i++) {
      unsigned j = diagonal - i;

      // Try extending stack
      if (i+1 < conf.stack.size())
        for (unsigned h = 0; h <= diagonal; h++) {
          int h_node = t.node(i, j, h), new_node = t.node(i+1, j, 0);
          if (new_node && t.cost(i, j, h) + t.edge_cost(h_node, new_node) < t.cost(i+1, j, h+1) + (t.transition(i, j, h) != 0)) {
            t.cost(i+1, j, h+1) = t.cost(i, j, h) + t.edge_cost(h_node, new_node);
            t.transition(i+1, j, h+1) = t.transition(i, j, h) >= 0 ? t.transition(i, j, h) : t.which_arc_transition(h_node, new_node);
          }
          if (t.cost(i, j, h) + t.edge_cost(new_node, h_node) < t.cost(i+1, j, 0) + (t.transition(i, j, h) != 0)) {
            t.cost(i+1, j, 0) = t.cost(i, j, h) + t.edge_cost(new_node, h_node);
            t.transition(i+1, j, 0) = t.transition(i, j, h) >= 0 ? t.transition(i, j, h) : t.which_arc_transition(new_node, h_node);
          }
        }

      // Try extending right_stack
      if (j+1 < right_stack.size() + 1)
        for (unsigned h = 0; h <= diagonal; h++) {
          int h_node = t.node(i, j, h), new_node = t.node(i, j+1, diagonal+1);
          if (t.cost(i, j, h) + t.edge_cost(h_node, new_node) < t.cost(i, j+1, h) + (t.transition(i, j, h) > 0)) {
            t.cost(i, j+1, h) = t.cost(i, j, h) + t.edge_cost(h_node, new_node);
            t.transition(i, j+1, h) = t.transition(i, j, h) >= 0 ? t.transition(i, j, h) : 0;
          }
          if (h_node && t.cost(i, j, h) + t.edge_cost(new_node, h_node) < t.cost(i, j+1, diagonal+1) + (t.transition(i, j, h) > 0)) {
            t.cost(i, j+1, diagonal+1) = t.cost(i, j, h) + t.edge_cost(new_node, h_node);
            t.transition(i, j+1, diagonal+1) = t.transition(i, j, h) >= 0 ? t.transition(i, j, h) : 0;
          }
        }
    }
  }

  return predicted_transition(t.transition(conf.stack.size() - 1, right_stack.size(), 0), network_outcome);
}

// Oracle factory method
transition_oracle* transition_system_projective::oracle(const string& name) const {
  if (name == "static") return new transition_system_projective_oracle_static(labels);
  if (name == "dynamic") return new transition_system_projective_oracle_dynamic(labels);
  return nullptr;
}

/////////
// File: transition/transition_system_swap.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

transition_system_swap::transition_system_swap(const vector<string>& labels) : transition_system(labels) {
  transitions.emplace_back(new transition_shift());
  transitions.emplace_back(new transition_swap());
  for (auto&& label : labels) {
    transitions.emplace_back(new transition_left_arc(label));
    transitions.emplace_back(new transition_right_arc(label));
  }
}

// Static oracle
class transition_system_swap_oracle_static : public transition_oracle {
 public:
  transition_system_swap_oracle_static(const vector<string>& labels, bool lazy) : labels(labels), lazy(lazy) {}

  class tree_oracle_static : public transition_oracle::tree_oracle {
   public:
    tree_oracle_static(const vector<string>& labels, const tree& gold, vector<int>&& projective_order, vector<int>&& projective_components)
        : labels(labels), gold(gold), projective_order(projective_order), projective_components(projective_components) {}
    virtual predicted_transition predict(const configuration& conf, unsigned network_outcome, unsigned iteration) const override;
    virtual void interesting_transitions(const configuration& conf, vector<unsigned>& transitions) const override;
   private:
    const vector<string>& labels;
    const tree& gold;
    const vector<int> projective_order;
    const vector<int> projective_components;
  };

  virtual unique_ptr<tree_oracle> create_tree_oracle(const tree& gold) const override;
 private:
  void create_projective_order(const tree& gold, int node, vector<int>& projective_order, int& projective_index) const;
  void create_projective_component(const tree& gold, int node, vector<int>& projective_components, int component_index) const;

  const vector<string>& labels;
  bool lazy;
};

unique_ptr<transition_oracle::tree_oracle> transition_system_swap_oracle_static::create_tree_oracle(const tree& gold) const {
  vector<int> projective_order(gold.nodes.size());
  int projective_index;
  create_projective_order(gold, 0, projective_order, projective_index);

  vector<int> projective_components;
  if (lazy) {
    tree_oracle_static projective_oracle(labels, gold, vector<int>(), vector<int>());
    configuration conf;
    tree t = gold;
    transition_system_swap system(labels);

    conf.init(&t);
    while (!conf.final()) {
      auto prediction = projective_oracle.predict(conf, 0, 0);
      if (!system.applicable(conf, prediction.to_follow)) break;
      system.perform(conf, prediction.to_follow);
    }

    projective_components.assign(gold.nodes.size(), 0);
    for (auto&& node : conf.stack)
      if (node)
        create_projective_component(t, node, projective_components, node);
  }

  return unique_ptr<transition_oracle::tree_oracle>(new tree_oracle_static(labels, gold, move(projective_order), move(projective_components)));
}

void transition_system_swap_oracle_static::create_projective_order(const tree& gold, int node, vector<int>& projective_order, int& projective_index) const {
  unsigned child_index = 0;
  while (child_index < gold.nodes[node].children.size() && gold.nodes[node].children[child_index] < node)
    create_projective_order(gold, gold.nodes[node].children[child_index++], projective_order, projective_index);
  projective_order[node] = projective_index++;
  while (child_index < gold.nodes[node].children.size())
    create_projective_order(gold, gold.nodes[node].children[child_index++], projective_order, projective_index);
}

void transition_system_swap_oracle_static::create_projective_component(const tree& gold, int node, vector<int>& projective_components, int component_index) const {
  projective_components[node] = component_index;
  for (auto&& child : gold.nodes[node].children)
    create_projective_component(gold, child, projective_components, component_index);
}

void transition_system_swap_oracle_static::tree_oracle_static::interesting_transitions(const configuration& conf, vector<unsigned>& transitions) const {
  transitions.clear();
  if (!conf.buffer.empty()) transitions.push_back(0);
  if (conf.stack.size() >= 2) {
    // Swap
    if (!projective_order.empty()) {
      int last = conf.stack[conf.stack.size() - 1];
      int prev = conf.stack[conf.stack.size() - 2];
      if (projective_order[last] < projective_order[prev] &&
          (projective_components.empty() ||
           (conf.buffer.empty() || projective_components[last] != projective_components[conf.buffer.back()])))
        transitions.push_back(1);
    }

    // Arcs
    for (int direction = 0; direction < 2; direction++) {
      int child = conf.stack[conf.stack.size() - 2 + direction];
      for (size_t i = 0; i < labels.size(); i++)
        if (gold.nodes[child].deprel == labels[i])
          transitions.push_back(2 + 2*i + direction);
    }
  }
}

transition_oracle::predicted_transition transition_system_swap_oracle_static::tree_oracle_static::predict(const configuration& conf, unsigned /*network_outcome*/, unsigned /*iteration*/) const {
  // Use left if appropriate
  if (conf.stack.size() >= 2) {
    int parent = conf.stack[conf.stack.size() - 1];
    int child = conf.stack[conf.stack.size() - 2];
    if (gold.nodes[child].head == parent && gold.nodes[child].children.size() == conf.t->nodes[child].children.size()) {
      for (size_t i = 0; i < labels.size(); i++)
        if (gold.nodes[child].deprel == labels[i])
          return predicted_transition(2 + 2*i, 2 + 2*i);

      assert(!"label was not found");
    }
  }

  // Use right if appropriate
  if (conf.stack.size() >= 2) {
    int child = conf.stack[conf.stack.size() - 1];
    int parent = conf.stack[conf.stack.size() - 2];
    if (gold.nodes[child].head == parent && gold.nodes[child].children.size() == conf.t->nodes[child].children.size()) {
      for (size_t i = 0; i < labels.size(); i++)
        if (gold.nodes[child].deprel == labels[i])
          return predicted_transition(2 + 2*i + 1, 2 + 2*i + 1);

      assert(!"label was not found");
    }
  }

  // Use swap if appropriate
  if (conf.stack.size() >= 2 && !projective_order.empty()) {
    int last = conf.stack[conf.stack.size() - 1];
    int prev = conf.stack[conf.stack.size() - 2];
    if (projective_order[last] < projective_order[prev] &&
        (projective_components.empty() ||
         (conf.buffer.empty() || projective_components[last] != projective_components[conf.buffer.back()])))
      return predicted_transition(1, 1);
  }

  // Otherwise, just shift
  return predicted_transition(0, 0);
}

// Oracle factory method
transition_oracle* transition_system_swap::oracle(const string& name) const {
  if (name == "static_eager") return new transition_system_swap_oracle_static(labels, false);
  if (name == "static_lazy") return new transition_system_swap_oracle_static(labels, true);
  return nullptr;
}

/////////
// File: tree/tree.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

const string tree::root_form = "<root>";

tree::tree() {
  add_node(root_form);
}

bool tree::empty() {
  return nodes.size() == 1;
}

void tree::clear() {
  nodes.clear();
  node& root = add_node(root_form);
  root.lemma = root.upostag = root.xpostag = root.feats = root_form;
}

node& tree::add_node(const string& form) {
  nodes.emplace_back(nodes.size(), form);
  return nodes.back();
}

void tree::set_head(int id, int head, const string& deprel) {
  assert(id >= 0 && id < int(nodes.size()));
  assert(head < int(nodes.size()));

  // Remove existing head
  if (nodes[id].head >= 0) {
    auto& children = nodes[nodes[id].head].children;
    for (size_t i = children.size(); i && children[i-1] >= id; i--)
      if (children[i-1] == id) {
        children.erase(children.begin() + i - 1);
        break;
      }
  }

  // Set new head
  nodes[id].head = head;
  nodes[id].deprel = deprel;
  if (head >= 0) {
    auto& children = nodes[head].children;
    size_t i = children.size();
    while (i && children[i-1] > id) i--;
    if (!i || children[i-1] < id) children.insert(children.begin() + i, id);
  }
}

void tree::unlink_all_nodes() {
  for (auto&& node : nodes) {
    node.head = -1;
    node.deprel.clear();
    node.children.clear();
  }
}

/////////
// File: tree/tree_format.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Input format
class tree_input_format {
 public:
  virtual ~tree_input_format() {}

  virtual bool read_block(istream& in, string& block) const = 0;
  virtual void set_text(string_piece text, bool make_copy = false) = 0;
  virtual bool next_tree(tree& t) = 0;
  const string& last_error() const;

  // Static factory methods
  static tree_input_format* new_input_format(const string& name);
  static tree_input_format* new_conllu_input_format();

 protected:
  string error;
};

// Output format
class tree_output_format {
 public:
  virtual ~tree_output_format() {}

  virtual void write_tree(const tree& t, string& output, const tree_input_format* additional_info = nullptr) const = 0;

  // Static factory methods
  static tree_output_format* new_output_format(const string& name);
  static tree_output_format* new_conllu_output_format();
};

/////////
// File: tree/tree_format_conllu.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Input CoNLL-U format
class tree_input_format_conllu : public tree_input_format {
 public:
  virtual bool read_block(istream& in, string& block) const override;
  virtual void set_text(string_piece text, bool make_copy = false) override;
  virtual bool next_tree(tree& t) override;

 private:
  friend class tree_output_format_conllu;
  vector<string_piece> comments;
  vector<pair<int, string_piece>> multiword_tokens;

  string_piece text;
  string text_copy;
};

// Output CoNLL-U format
class tree_output_format_conllu : public tree_output_format {
 public:
  virtual void write_tree(const tree& t, string& output, const tree_input_format* additional_info = nullptr) const override;

 private:
  static const string underscore;
  const string& underscore_on_empty(const string& str) const { return str.empty() ? underscore : str; }
};

/////////
// File: tree/tree_format.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

const string& tree_input_format::last_error() const {
  return error;
}

// Input Static factory methods
tree_input_format* tree_input_format::new_conllu_input_format() {
  return new tree_input_format_conllu();
}

tree_input_format* tree_input_format::new_input_format(const string& name) {
  if (name == "conllu") return new_conllu_input_format();
  return nullptr;
}

// Output static factory methods
tree_output_format* tree_output_format::new_conllu_output_format() {
  return new tree_output_format_conllu();
}

tree_output_format* tree_output_format::new_output_format(const string& name) {
  if (name == "conllu") return new_conllu_output_format();
  return nullptr;
}

/////////
// File: tree/tree_format_conllu.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Input CoNLL-U format

bool tree_input_format_conllu::read_block(istream& in, string& block) const {
  block.clear();

  string line;
  while (getline(in, line)) {
    block.append(line).push_back('\n');
    if (line.empty()) break;
  }

  return !block.empty();
}

void tree_input_format_conllu::set_text(string_piece text, bool make_copy) {
  if (make_copy) {
    text_copy.assign(text.str, text.len);
    text = string_piece(text_copy.c_str(), text_copy.size());
  }
  this->text = text;
}

bool tree_input_format_conllu::next_tree(tree& t) {
  error.clear();
  t.clear();
  comments.clear();
  multiword_tokens.clear();
  int last_multiword_token = 0;

  vector<string_piece> tokens, parts;
  while (text.len) {
    // Read line
    string_piece line(text.str, 0);
    while (line.len < text.len && line.str[line.len] != '\n') line.len++;
    text.str += line.len + (line.len < text.len);
    text.len -= line.len + (line.len < text.len);

    // Empty lines denote end of tree, unless at the beginning
    if (!line.len) {
      if (t.empty()) continue;
      break;
    }

    if (*line.str == '#') {
      // Store comments at the beginning and ignore the rest
      if (t.empty()) comments.push_back(line);
      continue;
    }

    // Parse another tree node
    split(line, '\t', tokens);
    if (tokens.size() != 10)
      return error.assign("The CoNLL-U line '").append(line.str, line.len).append("' does not contain 10 columns!") , false;

    // Store and skip multiword tokens
    if (memchr(tokens[0].str, '-', tokens[0].len)) {
      split(tokens[0], '-', parts);
      if (parts.size() != 2)
        return error.assign("Cannot parse ID of multiword token '").append(line.str, line.len).append("'!") , false;
      int from, to;
      if (!parse_int(parts[0], "CoNLL-U id", from, error) || !parse_int(parts[1], "CoNLL-U id", to, error))
        return false;
      if (from != int(t.nodes.size()))
        return error.assign("Incorrect ID '").append(parts[0].str, parts[0].len).append("' of multiword token '").append(line.str, line.len).append("'!"), false;
      if (to < from)
        return error.assign("Incorrect range '").append(tokens[0].str, tokens[0].len).append("' of multiword token '").append(line.str, line.len).append("'!"), false;
      if (from <= last_multiword_token)
        return error.assign("Multiword token '").append(line.str, line.len).append("' overlaps with the previous one!"), false;
      last_multiword_token = to;
      multiword_tokens.emplace_back(from, line);
      continue;
    }

    // Parse node ID and head
    int id;
    if (!parse_int(tokens[0], "CoNLL-U id", id, error))
      return false;
    if (id != int(t.nodes.size()))
      return error.assign("Incorrect ID '").append(tokens[0].str, tokens[0].len).append("' of CoNLL-U line '").append(line.str, line.len).append("'!"), false;

    int head;
    if (tokens[6].len == 1 && tokens[6].str[0] == '_') {
      head = -1;
    } else {
      if (!parse_int(tokens[6], "CoNLL-U head", head, error))
        return false;
      if (head < 0)
        return error.assign("Numeric head value '").append(tokens[0].str, tokens[0].len).append("' cannot be negative!"), false;
    }

    // Add new node
    auto& node = t.add_node(string(tokens[1].str, tokens[1].len));
    if (!(tokens[2].len == 1 && tokens[2].str[0] == '_')) node.lemma.assign(tokens[2].str, tokens[2].len);
    if (!(tokens[3].len == 1 && tokens[3].str[0] == '_')) node.upostag.assign(tokens[3].str, tokens[3].len);
    if (!(tokens[4].len == 1 && tokens[4].str[0] == '_')) node.xpostag.assign(tokens[4].str, tokens[4].len);
    if (!(tokens[5].len == 1 && tokens[5].str[0] == '_')) node.feats.assign(tokens[5].str, tokens[5].len);
    node.head = head;
    if (!(tokens[7].len == 1 && tokens[7].str[0] == '_')) node.deprel.assign(tokens[7].str, tokens[7].len);
    if (!(tokens[8].len == 1 && tokens[8].str[0] == '_')) node.deps.assign(tokens[8].str, tokens[8].len);
    if (!(tokens[9].len == 1 && tokens[9].str[0] == '_')) node.misc.assign(tokens[9].str, tokens[9].len);
  }

  // Check that we got word for the last multiword token
  if (last_multiword_token >= int(t.nodes.size()))
    return error.assign("There are words missing for multiword token '").append(multiword_tokens.back().second.str, multiword_tokens.back().second.len).append("'!"), false;

  // Set heads correctly
  for (auto&& node : t.nodes)
    if (node.id && node.head >= 0) {
      if (node.head >= int(t.nodes.size()))
        return error.assign("Node ID '").append(to_string(node.id)).append("' form '").append(node.form).append("' has too large head: '").append(to_string(node.head)).append("'!"), false;
      t.set_head(node.id, node.head, node.deprel);
    }

  return !t.empty();
}

// Output CoNLL-U format

const string tree_output_format_conllu::underscore = "_";

void tree_output_format_conllu::write_tree(const tree& t, string& output, const tree_input_format* additional_info) const {
  output.clear();

  // Try casting input format to CoNLL-U
  auto input_conllu = dynamic_cast<const tree_input_format_conllu*>(additional_info);
  size_t input_conllu_multiword_tokens = 0;

  // Comments if present
  if (input_conllu)
    for (auto&& comment : input_conllu->comments)
      output.append(comment.str, comment.len).push_back('\n');

  // Print out the tokens
  for (int i = 1 /*skip the root node*/; i < int(t.nodes.size()); i++) {
    // Write multiword token if present
    if (input_conllu && input_conllu_multiword_tokens < input_conllu->multiword_tokens.size() &&
        i == input_conllu->multiword_tokens[input_conllu_multiword_tokens].first) {
      output.append(input_conllu->multiword_tokens[input_conllu_multiword_tokens].second.str,
                    input_conllu->multiword_tokens[input_conllu_multiword_tokens].second.len).push_back('\n');
      input_conllu_multiword_tokens++;
    }

    // Write the token
    output.append(to_string(i)).push_back('\t');
    output.append(t.nodes[i].form).push_back('\t');
    output.append(underscore_on_empty(t.nodes[i].lemma)).push_back('\t');
    output.append(underscore_on_empty(t.nodes[i].upostag)).push_back('\t');
    output.append(underscore_on_empty(t.nodes[i].xpostag)).push_back('\t');
    output.append(underscore_on_empty(t.nodes[i].feats)).push_back('\t');
    output.append(t.nodes[i].head < 0 ? "_" : to_string(t.nodes[i].head)).push_back('\t');
    output.append(underscore_on_empty(t.nodes[i].deprel)).push_back('\t');
    output.append(underscore_on_empty(t.nodes[i].deps)).push_back('\t');
    output.append(underscore_on_empty(t.nodes[i].misc)).push_back('\n');
  }
  output.push_back('\n');
}

/////////
// File: unilib/unicode.cpp
/////////

// This file is part of UniLib <http://github.com/ufal/unilib/>.
//
// Copyright 2014 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// UniLib version: 3.1.0
// Unicode version: 8.0.0

namespace unilib {

const char32_t unicode::CHARS;

const int32_t unicode::DEFAULT_CAT;

const uint8_t unicode::category_index[unicode::CHARS >> 8] = {
  0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,17,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,33,41,42,43,44,45,46,47,48,39,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,49,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,50,51,17,17,17,52,17,53,54,55,56,57,58,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,59,60,60,60,60,60,60,60,60,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,17,62,63,17,64,65,66,67,68,69,70,71,72,17,73,74,75,76,77,78,79,80,79,81,82,83,84,85,86,87,88,89,79,90,79,79,79,79,79,17,17,17,91,92,93,79,79,79,79,79,79,79,79,79,79,17,17,17,17,94,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,17,17,95,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,17,17,96,97,79,79,79,98,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,99,79,79,79,79,79,79,79,79,79,79,79,100,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,101,102,103,104,105,106,107,108,39,39,109,79,79,79,79,79,79,79,79,79,79,79,79,79,110,79,79,79,79,79,111,79,112,113,114,115,39,116,117,118,119,120,79,79,79,79,79,79,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,
    17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,121,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,122,123,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,124,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,17,17,125,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,
    79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,
    79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,
    79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,
    79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,126,127,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,79,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,
    61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,128,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,61,128
};

const uint8_t unicode::category_block[][256] = {
  {_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Zs,_Po,_Po,_Po,_Sc,_Po,_Po,_Po,_Ps,_Pe,_Po,_Sm,_Po,_Pd,_Po,_Po,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Po,_Po,_Sm,_Sm,_Sm,_Po,_Po,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ps,_Po,_Pe,_Sk,_Pc,_Sk,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ps,_Sm,_Pe,_Sm,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Cc,_Zs,_Po,_Sc,_Sc,_Sc,_Sc,_So,_Po,_Sk,_So,_Lo,_Pi,_Sm,_Cf,_So,_Sk,_So,_Sm,_No,_No,_Sk,_Ll,_Po,_Po,_Sk,_No,_Lo,_Pf,_No,_No,_No,_Po,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Sm,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Sm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll},
  {_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Ll,_Ll,_Lu,_Lu,_Ll,_Lu,_Ll,_Lu,_Lu,_Ll,_Lu,_Lu,_Lu,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Ll,_Lu,_Lu,_Ll,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Lu,_Lu,_Ll,_Lu,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Lu,_Ll,_Lu,_Ll,_Ll,_Lu,_Ll,_Lu,_Lu,_Ll,_Lu,_Lu,_Lu,_Ll,_Lu,_Ll,_Lu,_Lu,_Ll,_Ll,_Lo,_Lu,_Ll,_Ll,_Ll,_Lo,_Lo,_Lo,_Lo,_Lu,_Lt,_Ll,_Lu,_Lt,_Ll,_Lu,_Lt,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Ll,_Lu,_Lt,_Ll,_Lu,_Ll,_Lu,_Lu,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll},
  {_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Ll,_Lu,_Lu,_Ll,_Ll,_Lu,_Ll,_Lu,_Lu,_Lu,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lo,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Sk,_Sk,_Sk,_Sk,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Lm,_Lm,_Lm,_Lm,_Lm,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Lm,_Sk,_Lm,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk},
  {_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Lu,_Ll,_Lu,_Ll,_Lm,_Sk,_Lu,_Ll,_Cn,_Cn,_Lm,_Ll,_Ll,_Ll,_Po,_Lu,_Cn,_Cn,_Cn,_Cn,_Sk,_Sk,_Lu,_Po,_Lu,_Lu,_Lu,_Cn,_Lu,_Cn,_Lu,_Lu,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Ll,_Ll,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Ll,_Sm,_Lu,_Ll,_Lu,_Lu,_Ll,_Ll,_Lu,_Lu,_Lu},
  {_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_So,_Mn,_Mn,_Mn,_Mn,_Mn,_Me,_Me,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll},
  {_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Cn,_Cn,_Lm,_Po,_Po,_Po,_Po,_Po,_Po,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Po,_Pd,_Cn,_Cn,_So,_So,_Sc,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Pd,_Mn,_Po,_Mn,_Mn,_Po,_Mn,_Mn,_Po,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Sm,_Sm,_Sm,_Po,_Po,_Sc,_Po,_Po,_So,_So,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Po,_Cf,_Cn,_Po,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lm,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Po,_Po,_Po,_Po,_Lo,_Lo,_Mn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Po,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cf,_So,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Lm,_Lm,_Mn,_Mn,_So,_Mn,_Mn,_Mn,_Mn,_Lo,_Lo,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Lo,_Lo,_Lo,_So,_So,_Lo},
  {_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Cn,_Cf,_Lo,_Mn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Lm,_Lm,_So,_Po,_Po,_Po,_Lm,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Lm,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Lm,_Mn,_Mn,_Mn,_Lm,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Cn,_Cn,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn},
  {_Mn,_Mn,_Mn,_Mc,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mc,_Mn,_Lo,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mc,_Mc,_Mc,_Mn,_Mc,_Mc,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Po,_Po,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Po,_Lm,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mc,_Mc,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Mn,_Lo,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Mc,_Mc,_Cn,_Cn,_Mc,_Mc,_Mn,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mc,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Mn,_Mn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Lo,_Lo,_Sc,_Sc,_No,_No,_No,_No,_No,_No,_So,_Sc,_Cn,_Cn,_Cn,_Cn},
  {_Cn,_Mn,_Mn,_Mc,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Cn,_Lo,_Lo,_Cn,_Lo,_Lo,_Cn,_Cn,_Mn,_Cn,_Mc,_Mc,_Mc,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Cn,_Cn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Mn,_Mn,_Lo,_Lo,_Lo,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mc,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Mn,_Lo,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Mn,_Mn,_Mc,_Cn,_Mc,_Mc,_Mn,_Cn,_Cn,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Mn,_Mn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Po,_Sc,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Cn,_Mn,_Mc,_Mc,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Mn,_Lo,_Mc,_Mn,_Mc,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Mc,_Mc,_Cn,_Cn,_Mc,_Mc,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mc,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Mn,_Mn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_So,_Lo,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Lo,_Lo,_Cn,_Lo,_Cn,_Lo,_Lo,_Cn,_Cn,_Cn,_Lo,_Lo,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Mc,_Mc,_Mn,_Mc,_Mc,_Cn,_Cn,_Cn,_Mc,_Mc,_Mc,_Cn,_Mc,_Mc,_Mc,_Mn,_Cn,_Cn,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mc,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_No,_No,_No,_So,_So,_So,_So,_So,_So,_Sc,_So,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Mn,_Mc,_Mc,_Mc,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Lo,_Mn,_Mn,_Mn,_Mc,_Mc,_Mc,_Mc,_Cn,_Mn,_Mn,_Mn,_Cn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Cn,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Mn,_Mn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_No,_So,_Cn,_Mn,_Mc,_Mc,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Mn,_Lo,_Mc,_Mn,_Mc,_Mc,_Mc,_Mc,_Mc,_Cn,_Mn,_Mc,_Mc,_Cn,_Mc,_Mc,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mc,_Mc,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Cn,_Lo,_Lo,_Mn,_Mn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Cn,_Mn,_Mc,_Mc,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Cn,_Mc,_Mc,_Mc,_Cn,_Mc,_Mc,_Mc,_Mn,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mc,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Mn,_Mn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_So,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Mc,_Mc,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Mn,_Cn,_Cn,_Cn,_Cn,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Cn,_Mn,_Cn,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Mc,_Mc,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Sc,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lm,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Po,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Cn,_Lo,_Cn,_Cn,_Lo,_Lo,_Cn,_Lo,_Cn,_Cn,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Cn,_Lo,_Cn,_Lo,_Cn,_Cn,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Mn,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Mn,_Mn,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lm,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_So,_So,_So,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_So,_Po,_So,_So,_So,_Mn,_Mn,_So,_So,_So,_So,_So,_So,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_So,_Mn,_So,_Mn,_So,_Mn,_Ps,_Pe,_Ps,_Pe,_Mc,_Mc,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Po,_Mn,_Mn,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_Mn,_So,_So,_So,_So,_So,_So,_Cn,_So,_So,_Po,_Po,_Po,_Po,_Po,_So,_So,_So,_So,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mn,_Mn,_Mc,_Mc,_Mn,_Mn,_Lo,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Po,_Po,_Po,_Po,_Po,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Mn,_Mn,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Lo,_Mc,_Mc,_Mc,_Lo,_Lo,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mc,_Mc,_Mn,_Mn,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mn,_Lo,_Mc,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Mc,_Mc,_Mc,_Mn,_So,_So,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Cn,_Lu,_Cn,_Cn,_Cn,_Cn,_Cn,_Lu,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Po,_Lm,_Lo,_Lo,_Lo},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Mn,_Mn,_Mn,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Cn,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Cn},
  {_Pd,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Po,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Zs,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Ps,_Pe,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Po,_Po,_Po,_Nl,_Nl,_Nl,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Cn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mn,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Po,_Po,_Po,_Lm,_Po,_Po,_Po,_Sc,_Lo,_Mn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Po,_Po,_Po,_Po,_Po,_Po,_Pd,_Po,_Po,_Po,_Po,_Mn,_Mn,_Mn,_Cf,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lm,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Mn,_Mn,_Mn,_Mc,_Mc,_Mc,_Mc,_Mn,_Mn,_Mc,_Mc,_Mc,_Cn,_Cn,_Cn,_Cn,_Mc,_Mc,_Mn,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_So,_Cn,_Cn,_Cn,_Po,_Po,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_No,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mc,_Mc,_Mn,_Cn,_Cn,_Po,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mn,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Mn,_Mc,_Mn,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Mn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Lm,_Po,_Po,_Po,_Po,_Po,_Po,_Cn,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Me,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Mn,_Mn,_Mn,_Mn,_Mc,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mn,_Mc,_Mc,_Mc,_Mc,_Mc,_Mn,_Mc,_Mc,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Mn,_Mn,_Mc,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mn,_Mn,_Mn,_Mn,_Mc,_Mc,_Mn,_Mn,_Mc,_Mn,_Mn,_Mn,_Lo,_Lo,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mc,_Mn,_Mn,_Mc,_Mc,_Mc,_Mn,_Mc,_Mn,_Mn,_Mn,_Mc,_Mc,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Po,_Po,_Po,_Po},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mc,_Mn,_Mn,_Cn,_Cn,_Cn,_Po,_Po,_Po,_Po,_Po,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Po,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Lo,_Lo,_Lo,_Lo,_Mn,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Mn,_Lo,_Lo,_Cn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Mn},
  {_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll},
  {_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Cn,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Cn,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Lu,_Cn,_Lu,_Cn,_Lu,_Cn,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lt,_Lt,_Lt,_Lt,_Lt,_Lt,_Lt,_Lt,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lt,_Lt,_Lt,_Lt,_Lt,_Lt,_Lt,_Lt,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lt,_Lt,_Lt,_Lt,_Lt,_Lt,_Lt,_Lt,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lt,_Sk,_Ll,_Sk,_Sk,_Sk,_Ll,_Ll,_Ll,_Cn,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lt,_Sk,_Sk,_Sk,_Ll,_Ll,_Ll,_Ll,_Cn,_Cn,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Cn,_Sk,_Sk,_Sk,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Sk,_Sk,_Sk,_Cn,_Cn,_Ll,_Ll,_Ll,_Cn,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lt,_Sk,_Sk,_Cn},
  {_Zs,_Zs,_Zs,_Zs,_Zs,_Zs,_Zs,_Zs,_Zs,_Zs,_Zs,_Cf,_Cf,_Cf,_Cf,_Cf,_Pd,_Pd,_Pd,_Pd,_Pd,_Pd,_Po,_Po,_Pi,_Pf,_Ps,_Pi,_Pi,_Pf,_Ps,_Pi,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Zl,_Zp,_Cf,_Cf,_Cf,_Cf,_Cf,_Zs,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Pi,_Pf,_Po,_Po,_Po,_Po,_Pc,_Pc,_Po,_Po,_Po,_Sm,_Ps,_Pe,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Sm,_Po,_Pc,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Zs,_Cf,_Cf,_Cf,_Cf,_Cf,_Cn,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_No,_Lm,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_Sm,_Sm,_Sm,_Ps,_Pe,_Lm,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Sm,_Sm,_Sm,_Ps,_Pe,_Cn,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Cn,_Cn,_Cn,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Sc,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Me,_Me,_Me,_Me,_Mn,_Me,_Me,_Me,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_So,_So,_Lu,_So,_So,_So,_So,_Lu,_So,_So,_Ll,_Lu,_Lu,_Lu,_Ll,_Ll,_Lu,_Lu,_Lu,_Ll,_So,_Lu,_So,_So,_Sm,_Lu,_Lu,_Lu,_Lu,_Lu,_So,_So,_So,_So,_So,_So,_Lu,_So,_Lu,_So,_Lu,_So,_Lu,_Lu,_Lu,_Lu,_So,_Ll,_Lu,_Lu,_Lu,_Lu,_Ll,_Lo,_Lo,_Lo,_Lo,_Ll,_So,_So,_Ll,_Ll,_Lu,_Lu,_Sm,_Sm,_Sm,_Sm,_Sm,_Lu,_Ll,_Ll,_Ll,_Ll,_So,_Sm,_So,_So,_Ll,_So,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Lu,_Ll,_Nl,_Nl,_Nl,_Nl,_No,_So,_So,_Cn,_Cn,_Cn,_Cn,_Sm,_Sm,_Sm,_Sm,_Sm,_So,_So,_So,_So,_So,_Sm,_Sm,_So,_So,_So,_So,_Sm,_So,_So,_Sm,_So,_So,_Sm,_So,_So,_So,_So,_So,_So,_So,_Sm,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Sm,_Sm,_So,_So,_Sm,_So,_Sm,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm},
  {_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm},
  {_So,_So,_So,_So,_So,_So,_So,_So,_Ps,_Pe,_Ps,_Pe,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Sm,_Sm,_So,_So,_So,_So,_So,_So,_So,_Ps,_Pe,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Sm,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Sm,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Sm,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Sm,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Sm,_Sm,_Sm,_Sm,_Sm,_Ps,_Pe,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So},
  {_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Ps,_Pe,_Ps,_Pe,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Ps,_Pe,_Sm,_Sm},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_So,_So,_Sm,_Sm,_Sm,_Sm,_Sm,_Sm,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Lu,_Ll,_Lu,_Lu,_Lu,_Ll,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Lu,_Lu,_Lu,_Ll,_Lu,_Ll,_Ll,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lm,_Lm,_Lu,_Lu,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Ll,_So,_So,_So,_So,_So,_So,_Lu,_Ll,_Lu,_Ll,_Mn,_Mn,_Mn,_Lu,_Ll,_Cn,_Cn,_Cn,_Cn,_Cn,_Po,_Po,_Po,_Po,_No,_Po,_Po},
  {_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Ll,_Cn,_Cn,_Cn,_Cn,_Cn,_Ll,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lm,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn},
  {_Po,_Po,_Pi,_Pf,_Pi,_Pf,_Po,_Po,_Po,_Pi,_Pf,_Po,_Pi,_Pf,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Pd,_Po,_Po,_Pd,_Po,_Pi,_Pf,_Po,_Po,_Pi,_Pf,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Po,_Po,_Po,_Po,_Po,_Lm,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Pd,_Pd,_Po,_Po,_Po,_Po,_Pd,_Po,_Ps,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn},
  {_Zs,_Po,_Po,_Po,_So,_Lm,_Lo,_Nl,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_So,_So,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Pd,_Ps,_Pe,_Pe,_So,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Mn,_Mn,_Mn,_Mn,_Mc,_Mc,_Pd,_Lm,_Lm,_Lm,_Lm,_Lm,_So,_So,_Nl,_Nl,_Nl,_Lm,_Lo,_Po,_So,_So,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Mn,_Mn,_Sk,_Sk,_Lm,_Lm,_Lo,_Pd,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Po,_Lm,_Lm,_Lm,_Lo},
  {_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_So,_So,_No,_No,_No,_No,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_No,_No,_No,_No,_No,_No,_No,_No,_So,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lm,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Po,_Po},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lm,_Po,_Po,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lo,_Mn,_Me,_Me,_Me,_Po,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Po,_Lm,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lm,_Lm,_Mn,_Mn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Mn,_Mn,_Po,_Po,_Po,_Po,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Sk,_Sk,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Ll,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lm,_Sk,_Sk,_Lu,_Ll,_Lu,_Ll,_Lo,_Lu,_Ll,_Lu,_Ll,_Ll,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Ll,_Lu,_Lu,_Lu,_Lu,_Cn,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Lu,_Ll,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lm,_Lm,_Ll,_Lo,_Lo,_Lo,_Lo,_Lo},
  {_Lo,_Lo,_Mn,_Lo,_Lo,_Lo,_Mn,_Lo,_Lo,_Lo,_Lo,_Mn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Mn,_Mn,_Mc,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_So,_So,_Sc,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Po,_Po,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mc,_Mc,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Po,_Po,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Po,_Po,_Po,_Lo,_Po,_Lo,_Cn,_Cn},
  {_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Po,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mc,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Mc,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mc,_Mc,_Mn,_Mc,_Mc,_Mc,_Mc,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Cn,_Lm,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Po,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Lm,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mc,_Mn,_Mn,_Mc,_Mc,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Mn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mc,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Po,_Po,_Po,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lm,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_So,_So,_So,_Lo,_Mc,_Mn,_Mc,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Lo,_Mn,_Mn,_Mn,_Lo,_Lo,_Mn,_Mn,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Lo,_Mn,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lm,_Po,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mn,_Mn,_Mc,_Mc,_Po,_Po,_Lo,_Lm,_Lm,_Mc,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Sk,_Lm,_Lm,_Lm,_Lm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Mn,_Mc,_Mc,_Mn,_Mc,_Mc,_Po,_Mc,_Mn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn},
  {_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs,_Cs},
  {_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Mn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Sm,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Cn,_Lo,_Lo,_Cn,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Sk,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Pe,_Ps,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Sc,_So,_Cn,_Cn},
  {_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Ps,_Pe,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Po,_Pd,_Pd,_Pc,_Pc,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Po,_Po,_Ps,_Pe,_Po,_Po,_Po,_Po,_Pc,_Pc,_Pc,_Po,_Po,_Po,_Cn,_Po,_Po,_Po,_Po,_Pd,_Ps,_Pe,_Ps,_Pe,_Ps,_Pe,_Po,_Po,_Po,_Sm,_Pd,_Sm,_Sm,_Sm,_Cn,_Po,_Sc,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cf},
  {_Cn,_Po,_Po,_Po,_Sc,_Po,_Po,_Po,_Ps,_Pe,_Po,_Sm,_Po,_Pd,_Po,_Po,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Po,_Po,_Sm,_Sm,_Sm,_Po,_Po,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ps,_Po,_Pe,_Sk,_Pc,_Sk,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ps,_Sm,_Pe,_Sm,_Ps,_Pe,_Po,_Ps,_Pe,_Po,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lm,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lm,_Lm,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Sc,_Sc,_Sm,_Sk,_So,_Sc,_Sc,_Cn,_So,_Sm,_Sm,_Sm,_Sm,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cf,_Cf,_Cf,_So,_So,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Po,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_No,_No,_No,_No,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_No,_No,_So,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Mn,_Cn,_Cn},
  {_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_No,_No,_No,_No,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Nl,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Nl,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Po,_Nl,_Nl,_Nl,_Nl,_Nl,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Cn,_Cn,_Cn,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Po,_No,_No,_No,_No,_No,_No,_No,_No,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_So,_So,_No,_No,_No,_No,_No,_No,_No,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_No,_No,_Lo,_Lo,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No},
  {_Lo,_Mn,_Mn,_Mn,_Cn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Mn,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Mn,_No,_No,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_No,_No,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_No,_No,_No,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_So,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_No,_No,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_No,_No,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Po,_Po,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No,_No},
  {_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Mc,_Mn,_Mc,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Mc,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mc,_Mc,_Mn,_Mn,_Po,_Po,_Cf,_Po,_Po,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Mn,_Mn,_Mn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Po,_Po,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Po,_Po,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mc,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mc,_Lo,_Lo,_Lo,_Lo,_Po,_Po,_Po,_Po,_Po,_Mn,_Mn,_Mn,_Po,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Lo,_Po,_Lo,_Po,_Po,_Po,_Cn,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Mc,_Mc,_Mn,_Mc,_Mn,_Mn,_Po,_Po,_Po,_Po,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Mn,_Mn,_Mc,_Mc,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Mn,_Lo,_Mc,_Mc,_Mn,_Mc,_Mc,_Mc,_Mc,_Cn,_Cn,_Mc,_Mc,_Cn,_Cn,_Mc,_Mc,_Mc,_Cn,_Cn,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mc,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Cn,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mn,_Mc,_Mc,_Mc,_Mc,_Mn,_Mn,_Mc,_Mn,_Mn,_Lo,_Lo,_Po,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Mc,_Mc,_Mc,_Mc,_Mn,_Mn,_Mc,_Mn,_Mn,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Po,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mc,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mc,_Mn,_Mc,_Mn,_Mn,_Po,_Po,_Po,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mc,_Mn,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mc,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Mc,_Mc,_Mn,_Mn,_Mn,_Mn,_Mc,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_No,_No,_Po,_Po,_Po,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo},
  {_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Nl,_Cn,_Po,_Po,_Po,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_Cn,_Cn,_Cn,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Po,_Po,_Po,_Po,_Po,_So,_So,_So,_So,_Lm,_Lm,_Lm,_Lm,_Po,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Cn,_No,_No,_No,_No,_No,_No,_No,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Mn,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Lm,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_So,_Mn,_Mn,_Po,_Cf,_Cf,_Cf,_Cf,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Mc,_Mc,_Mn,_Mn,_Mn,_So,_So,_So,_Mc,_Mc,_Mc,_Mc,_Mc,_Mc,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_So,_So,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Mn,_Mn,_Mn,_Mn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Mn,_Mn,_Mn,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Cn,_Lu,_Lu,_Cn,_Cn,_Lu,_Cn,_Cn,_Lu,_Lu,_Cn,_Cn,_Lu,_Lu,_Lu,_Lu,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Cn,_Ll,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll},
  {_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Cn,_Lu,_Lu,_Lu,_Lu,_Cn,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Cn,_Lu,_Lu,_Lu,_Lu,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Cn,_Lu,_Cn,_Cn,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Cn,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll},
  {_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Cn,_Cn,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Sm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Sm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Sm,_Ll,_Ll,_Ll,_Ll},
  {_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Sm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Sm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Sm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Sm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Sm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Lu,_Sm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Sm,_Ll,_Ll,_Ll,_Ll,_Ll,_Ll,_Lu,_Ll,_Cn,_Cn,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd,_Nd},
  {_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_So,_So,_So,_So,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_So,_So,_So,_So,_So,_So,_So,_So,_Mn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Mn,_So,_So,_Po,_Po,_Po,_Po,_Po,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Cn,_Lo,_Cn,_Cn,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Cn,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Cn,_Cn,_Cn,_Cn,_Lo,_Cn,_Lo,_Cn,_Lo,_Cn,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Cn,_Lo,_Cn,_Cn,_Lo,_Cn,_Lo,_Cn,_Lo,_Cn,_Lo,_Cn,_Lo,_Cn,_Lo,_Lo,_Cn,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Sm,_Sm,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_No,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So},
  {_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Sk,_Sk,_Sk,_Sk,_Sk},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_So,_So,_So,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_So,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Lo,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Cn,_Cf,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cf,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Mn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn,_Cn},
  {_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Co,_Cn,_Cn}
};

const uint8_t unicode::othercase_index[unicode::CHARS >> 8] = {
  0,1,2,3,4,5,6,6,6,6,6,6,6,6,6,6,7,6,6,8,6,6,6,6,6,6,6,6,6,9,10,11,6,12,6,6,13,6,6,6,6,6,6,6,14,15,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,16,17,6,6,6,18,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,19,6,6,6,6,20,6,6,6,6,6,6,6,21,6,6,6,6,6,6,6,6,6,6,6,22,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
    6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
    6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
    6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
    6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6
};

const char32_t unicode::othercase_block[][256] = {
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,24833,25089,25345,25601,25857,26113,26369,26625,26881,27137,27393,27649,27905,28161,28417,28673,28929,29185,29441,29697,29953,30209,30465,30721,30977,31233,0,0,0,0,0,0,16642,16898,17154,17410,17666,17922,18178,18434,18690,18946,19202,19458,19714,19970,20226,20482,20738,20994,21250,21506,21762,22018,22274,22530,22786,23042,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,236546,0,0,0,0,0,0,0,0,0,0,57345,57601,57857,58113,58369,58625,58881,59137,59393,59649,59905,60161,60417,60673,60929,61185,61441,61697,61953,62209,62465,62721,62977,0,63489,63745,64001,64257,64513,64769,65025,0,49154,49410,49666,49922,50178,50434,50690,50946,51202,51458,51714,51970,52226,52482,52738,52994,53250,53506,53762,54018,54274,54530,54786,0,55298,55554,55810,56066,56322,56578,56834,96258},
  {65793,65538,66305,66050,66817,66562,67329,67074,67841,67586,68353,68098,68865,68610,69377,69122,69889,69634,70401,70146,70913,70658,71425,71170,71937,71682,72449,72194,72961,72706,73473,73218,73985,73730,74497,74242,75009,74754,75521,75266,76033,75778,76545,76290,77057,76802,77569,77314,26881,18690,78593,78338,79105,78850,79617,79362,0,80385,80130,80897,80642,81409,81154,81921,81666,82433,82178,82945,82690,83457,83202,83969,83714,0,84737,84482,85249,84994,85761,85506,86273,86018,86785,86530,87297,87042,87809,87554,88321,88066,88833,88578,89345,89090,89857,89602,90369,90114,90881,90626,91393,91138,91905,91650,92417,92162,92929,92674,93441,93186,93953,93698,94465,94210,94977,94722,95489,95234,96001,95746,65281,96769,96514,97281,97026,97793,97538,21250,148226,152321,99073,98818,99585,99330,152577,100353,100098,153089,153345,101377,101122,0,122113,153857,154369,102913,102658,155649,156417,128514,157953,157697,104705,104450,146690,0,159489,160257,139266,161025,106753,106498,107265,107010,107777,107522,163841,108545,108290,164609,0,0,109825,109570,165889,110593,110338,166401,166657,111617,111362,112129,111874,168449,112897,112642,0,0,113921,113666,0,128770,0,0,0,0,115973,116227,115716,116741,116995,116484,117509,117763,117252,118273,118018,118785,118530,119297,119042,119809,119554,120321,120066,120833,120578,121345,121090,121857,121602,101890,122625,122370,123137,122882,123649,123394,124161,123906,124673,124418,125185,124930,125697,125442,126209,125954,126721,126466,0,127493,127747,127236,128257,128002,103681,114433,129281,129026,129793,129538,130305,130050,130817,130562},
  {131329,131074,131841,131586,132353,132098,132865,132610,133377,133122,133889,133634,134401,134146,134913,134658,135425,135170,135937,135682,136449,136194,136961,136706,137473,137218,137985,137730,138497,138242,139009,138754,105985,0,140033,139778,140545,140290,141057,140802,141569,141314,142081,141826,142593,142338,143105,142850,143617,143362,144129,143874,0,0,0,0,0,0,2909441,146433,146178,104961,2909697,2915842,2916098,147969,147714,98305,166145,166913,149249,148994,149761,149506,150273,150018,150785,150530,151297,151042,2912002,2911490,2912258,98562,99842,0,100610,100866,0,102146,0,102402,10988290,0,0,0,103170,10988546,0,103426,0,10980610,10988034,0,104194,103938,0,2908674,10988802,0,0,105474,0,2911746,105730,0,0,106242,0,0,0,0,0,0,0,2909186,0,0,108034,0,0,108802,0,0,0,10989826,110082,148482,110850,111106,148738,0,0,0,0,0,112386,0,0,0,0,0,0,0,0,0,0,10990082,10989570,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,235778,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,225537,225282,226049,225794,0,0,227073,226818,0,0,0,261378,261634,261890,0,258817,0,0,0,0,0,0,240641,0,240897,241153,241409,0,248833,0,249089,249345,0,241921,242177,242433,242689,242945,243201,243457,243713,243969,244225,244481,244737,244993,245249,245505,245761,246017,0,246529,246785,247041,247297,247553,247809,248065,248321,248577,230914,231426,231682,231938,0,233730,233986,234242,234498,234754,235010,235266,235522,235778,236034,236290,236546,236802,237058,237314,237570,237826,238338,238338,238594,238850,239106,239362,239618,239874,240130,240386,232450,232962,233218,251649,233986,235522,0,0,0,239106,237570,249602,252161,251906,252673,252418,253185,252930,253697,253442,254209,253954,254721,254466,255233,254978,255745,255490,256257,256002,256769,256514,257281,257026,257793,257538,236034,237826,260354,229122,243713,234754,0,260097,259842,258561,260865,260610,0,228097,228353,228609},
  {282625,282881,283137,283393,283649,283905,284161,284417,284673,284929,285185,285441,285697,285953,286209,286465,274433,274689,274945,275201,275457,275713,275969,276225,276481,276737,276993,277249,277505,277761,278017,278273,278529,278785,279041,279297,279553,279809,280065,280321,280577,280833,281089,281345,281601,281857,282113,282369,266242,266498,266754,267010,267266,267522,267778,268034,268290,268546,268802,269058,269314,269570,269826,270082,270338,270594,270850,271106,271362,271618,271874,272130,272386,272642,272898,273154,273410,273666,273922,274178,262146,262402,262658,262914,263170,263426,263682,263938,264194,264450,264706,264962,265218,265474,265730,265986,286977,286722,287489,287234,288001,287746,288513,288258,289025,288770,289537,289282,290049,289794,290561,290306,291073,290818,291585,291330,292097,291842,292609,292354,293121,292866,293633,293378,294145,293890,294657,294402,295169,294914,0,0,0,0,0,0,0,0,297729,297474,298241,297986,298753,298498,299265,299010,299777,299522,300289,300034,300801,300546,301313,301058,301825,301570,302337,302082,302849,302594,303361,303106,303873,303618,304385,304130,304897,304642,305409,305154,305921,305666,306433,306178,306945,306690,307457,307202,307969,307714,308481,308226,308993,308738,309505,309250,310017,309762,310529,310274,311041,310786,315137,311809,311554,312321,312066,312833,312578,313345,313090,313857,313602,314369,314114,314881,314626,311298,315649,315394,316161,315906,316673,316418,317185,316930,317697,317442,318209,317954,318721,318466,319233,318978,319745,319490,320257,320002,320769,320514,321281,321026,321793,321538,322305,322050,322817,322562,323329,323074,323841,323586,324353,324098,324865,324610,325377,325122,325889,325634,326401,326146,326913,326658,327425,327170},
  {327937,327682,328449,328194,328961,328706,329473,329218,329985,329730,330497,330242,331009,330754,331521,331266,332033,331778,332545,332290,333057,332802,333569,333314,334081,333826,334593,334338,335105,334850,335617,335362,336129,335874,336641,336386,337153,336898,337665,337410,338177,337922,338689,338434,339201,338946,339713,339458,0,352513,352769,353025,353281,353537,353793,354049,354305,354561,354817,355073,355329,355585,355841,356097,356353,356609,356865,357121,357377,357633,357889,358145,358401,358657,358913,359169,359425,359681,359937,360193,360449,360705,360961,361217,361473,361729,361985,0,0,0,0,0,0,0,0,0,0,340226,340482,340738,340994,341250,341506,341762,342018,342274,342530,342786,343042,343298,343554,343810,344066,344322,344578,344834,345090,345346,345602,345858,346114,346370,346626,346882,347138,347394,347650,347906,348162,348418,348674,348930,349186,349442,349698,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2949121,2949377,2949633,2949889,2950145,2950401,2950657,2950913,2951169,2951425,2951681,2951937,2952193,2952449,2952705,2952961,2953217,2953473,2953729,2953985,2954241,2954497,2954753,2955009,2955265,2955521,2955777,2956033,2956289,2956545,2956801,2957057,2957313,2957569,2957825,2958081,2958337,2958593,0,2959105,0,0,0,0,0,2960641,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,11235329,11235585,11235841,11236097,11236353,11236609,11236865,11237121,11237377,11237633,11237889,11238145,11238401,11238657,11238913,11239169,11239425,11239681,11239937,11240193,11240449,11240705,11240961,11241217,11241473,11241729,11241985,11242241,11242497,11242753,11243009,11243265,11243521,11243777,11244033,11244289,11244545,11244801,11245057,11245313,11245569,11245825,11246081,11246337,11246593,11246849,11247105,11247361,11247617,11247873,11248129,11248385,11248641,11248897,11249153,11249409,11249665,11249921,11250177,11250433,11250689,11250945,11251201,11251457,11251713,11251969,11252225,11252481,11252737,11252993,11253249,11253505,11253761,11254017,11254273,11254529,11254785,11255041,11255297,11255553,1308673,1308929,1309185,1309441,1309697,1309953,0,0,1306626,1306882,1307138,1307394,1307650,1307906,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10976514,0,0,0,2908930,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {1966337,1966082,1966849,1966594,1967361,1967106,1967873,1967618,1968385,1968130,1968897,1968642,1969409,1969154,1969921,1969666,1970433,1970178,1970945,1970690,1971457,1971202,1971969,1971714,1972481,1972226,1972993,1972738,1973505,1973250,1974017,1973762,1974529,1974274,1975041,1974786,1975553,1975298,1976065,1975810,1976577,1976322,1977089,1976834,1977601,1977346,1978113,1977858,1978625,1978370,1979137,1978882,1979649,1979394,1980161,1979906,1980673,1980418,1981185,1980930,1981697,1981442,1982209,1981954,1982721,1982466,1983233,1982978,1983745,1983490,1984257,1984002,1984769,1984514,1985281,1985026,1985793,1985538,1986305,1986050,1986817,1986562,1987329,1987074,1987841,1987586,1988353,1988098,1988865,1988610,1989377,1989122,1989889,1989634,1990401,1990146,1990913,1990658,1991425,1991170,1991937,1991682,1992449,1992194,1992961,1992706,1993473,1993218,1993985,1993730,1994497,1994242,1995009,1994754,1995521,1995266,1996033,1995778,1996545,1996290,1997057,1996802,1997569,1997314,1998081,1997826,1998593,1998338,1999105,1998850,1999617,1999362,2000129,1999874,2000641,2000386,2001153,2000898,2001665,2001410,2002177,2001922,2002689,2002434,2003201,2002946,2003713,2003458,2004225,2003970,0,0,0,0,0,1990658,0,0,57089,0,2007297,2007042,2007809,2007554,2008321,2008066,2008833,2008578,2009345,2009090,2009857,2009602,2010369,2010114,2010881,2010626,2011393,2011138,2011905,2011650,2012417,2012162,2012929,2012674,2013441,2013186,2013953,2013698,2014465,2014210,2014977,2014722,2015489,2015234,2016001,2015746,2016513,2016258,2017025,2016770,2017537,2017282,2018049,2017794,2018561,2018306,2019073,2018818,2019585,2019330,2020097,2019842,2020609,2020354,2021121,2020866,2021633,2021378,2022145,2021890,2022657,2022402,2023169,2022914,2023681,2023426,2024193,2023938,2024705,2024450,2025217,2024962,2025729,2025474,2026241,2025986,2026753,2026498,2027265,2027010,2027777,2027522,2028289,2028034,2028801,2028546,2029313,2029058,2029825,2029570,2030337,2030082,2030849,2030594,2031361,
    2031106},
  {2033666,2033922,2034178,2034434,2034690,2034946,2035202,2035458,2031617,2031873,2032129,2032385,2032641,2032897,2033153,2033409,2037762,2038018,2038274,2038530,2038786,2039042,0,0,2035713,2035969,2036225,2036481,2036737,2036993,0,0,2041858,2042114,2042370,2042626,2042882,2043138,2043394,2043650,2039809,2040065,2040321,2040577,2040833,2041089,2041345,2041601,2045954,2046210,2046466,2046722,2046978,2047234,2047490,2047746,2043905,2044161,2044417,2044673,2044929,2045185,2045441,2045697,2050050,2050306,2050562,2050818,2051074,2051330,0,0,2048001,2048257,2048513,2048769,2049025,2049281,0,0,0,2054402,0,2054914,0,2055426,0,2055938,0,2052353,0,2052865,0,2053377,0,2053889,2058242,2058498,2058754,2059010,2059266,2059522,2059778,2060034,2056193,2056449,2056705,2056961,2057217,2057473,2057729,2057985,2079234,2079490,2082818,2083074,2083330,2083586,2087426,2087682,2095106,2095362,2091522,2091778,2095618,2095874,0,0,2066434,2066690,2066946,2067202,2067458,2067714,2067970,2068226,2064385,2064641,2064897,2065153,2065409,2065665,2065921,2066177,2070530,2070786,2071042,2071298,2071554,2071810,2072066,2072322,2068481,2068737,2068993,2069249,2069505,2069761,2070017,2070273,2074626,2074882,2075138,2075394,2075650,2075906,2076162,2076418,2072577,2072833,2073089,2073345,2073601,2073857,2074113,2074369,2078722,2078978,0,2079746,0,0,0,0,2076673,2076929,2060289,2060545,2077441,0,235778,0,0,0,0,2083842,0,0,0,0,2060801,2061057,2061313,2061569,2081537,0,0,0,2086914,2087170,0,0,0,0,0,0,2084865,2085121,2061825,2062081,0,0,0,0,2091010,2091266,0,0,0,2092034,0,0,2088961,2089217,2062849,2063105,2090241,0,0,0,0,0,0,2096130,0,0,0,0,2062337,2062593,2063361,2063617,2093825,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,248065,0,0,0,27393,58625,0,0,0,0,0,0,2182657,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2175490,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2191361,2191617,2191873,2192129,2192385,2192641,2192897,2193153,2193409,2193665,2193921,2194177,2194433,2194689,2194945,2195201,2187266,2187522,2187778,2188034,2188290,2188546,2188802,2189058,2189314,2189570,2189826,2190082,2190338,2190594,2190850,2191106,0,0,0,2196481,2196226,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2412545,2412801,2413057,2413313,2413569,2413825,2414081,2414337,2414593,2414849,2415105,2415361,2415617,2415873,2416129,2416385,2416641,2416897,2417153,2417409,2417665,2417921,2418177,2418433,2418689,2418945,2405890,2406146,2406402,2406658,2406914,2407170,2407426,2407682,2407938,2408194,2408450,2408706,2408962,2409218,2409474,2409730,2409986,2410242,2410498,2410754,2411010,2411266,2411522,2411778,2412034,2412290,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {2895873,2896129,2896385,2896641,2896897,2897153,2897409,2897665,2897921,2898177,2898433,2898689,2898945,2899201,2899457,2899713,2899969,2900225,2900481,2900737,2900993,2901249,2901505,2901761,2902017,2902273,2902529,2902785,2903041,2903297,2903553,2903809,2904065,2904321,2904577,2904833,2905089,2905345,2905601,2905857,2906113,2906369,2906625,2906881,2907137,2907393,2907649,0,2883586,2883842,2884098,2884354,2884610,2884866,2885122,2885378,2885634,2885890,2886146,2886402,2886658,2886914,2887170,2887426,2887682,2887938,2888194,2888450,2888706,2888962,2889218,2889474,2889730,2889986,2890242,2890498,2890754,2891010,2891266,2891522,2891778,2892034,2892290,2892546,2892802,2893058,2893314,2893570,2893826,2894082,2894338,2894594,2894850,2895106,2895362,0,2908417,2908162,158465,1932545,163073,145922,146946,2910209,2909954,2910721,2910466,2911233,2910978,151809,160001,151553,152065,0,2913025,2912770,0,2913793,2913538,0,0,0,0,0,0,0,147201,147457,2916609,2916354,2917121,2916866,2917633,2917378,2918145,2917890,2918657,2918402,2919169,2918914,2919681,2919426,2920193,2919938,2920705,2920450,2921217,2920962,2921729,2921474,2922241,2921986,2922753,2922498,2923265,2923010,2923777,2923522,2924289,2924034,2924801,2924546,2925313,2925058,2925825,2925570,2926337,2926082,2926849,2926594,2927361,2927106,2927873,2927618,2928385,2928130,2928897,2928642,2929409,2929154,2929921,2929666,2930433,2930178,2930945,2930690,2931457,2931202,2931969,2931714,2932481,2932226,2932993,2932738,2933505,2933250,2934017,2933762,2934529,2934274,2935041,2934786,2935553,2935298,2936065,2935810,2936577,2936322,2937089,2936834,2937601,2937346,2938113,2937858,2938625,2938370,2939137,2938882,2939649,2939394,2940161,2939906,2940673,2940418,2941185,2940930,2941697,2941442,0,0,0,0,0,0,0,2944001,2943746,2944513,2944258,0,0,0,2945793,2945538,0,0,0,0,0,0,0,0,0,0,0,0},
  {1089538,1089794,1090050,1090306,1090562,1090818,1091074,1091330,1091586,1091842,1092098,1092354,1092610,1092866,1093122,1093378,1093634,1093890,1094146,1094402,1094658,1094914,1095170,1095426,1095682,1095938,1096194,1096450,1096706,1096962,1097218,1097474,1097730,1097986,1098242,1098498,1098754,1099010,0,1099522,0,0,0,0,0,1101058,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10895617,10895362,10896129,10895874,10896641,10896386,10897153,10896898,10897665,10897410,10898177,10897922,10898689,10898434,10899201,10898946,10899713,10899458,10900225,10899970,10900737,10900482,10901249,10900994,10901761,10901506,10902273,10902018,10902785,10902530,10903297,10903042,10903809,10903554,10904321,10904066,10904833,10904578,10905345,10905090,10905857,10905602,10906369,10906114,10906881,10906626,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10912001,10911746,10912513,10912258,10913025,10912770,10913537,10913282,10914049,10913794,10914561,10914306,10915073,10914818,10915585,10915330,10916097,10915842,10916609,10916354,10917121,10916866,10917633,10917378,10918145,10917890,10918657,10918402,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10953473,10953218,10953985,10953730,10954497,10954242,10955009,10954754,10955521,10955266,10956033,10955778,10956545,10956290,0,0,10957569,10957314,10958081,10957826,10958593,10958338,10959105,10958850,10959617,10959362,10960129,10959874,10960641,10960386,10961153,10960898,10961665,10961410,10962177,10961922,10962689,10962434,10963201,10962946,10963713,10963458,10964225,10963970,10964737,10964482,10965249,10964994,10965761,10965506,10966273,10966018,10966785,10966530,10967297,10967042,10967809,10967554,10968321,10968066,10968833,10968578,10969345,10969090,10969857,10969602,10970369,10970114,10970881,10970626,10971393,10971138,10971905,10971650,10972417,10972162,10972929,10972674,0,0,0,0,0,0,0,0,0,10975745,10975490,10976257,10976002,1931521,10977025,10976770,10977537,10977282,10978049,10977794,10978561,10978306,10979073,10978818,0,0,0,10980353,10980098,156929,0,0,10981633,10981378,10982145,10981890,0,0,10983169,10982914,10983681,10983426,10984193,10983938,10984705,10984450,10985217,10984962,10985729,10985474,10986241,10985986,10986753,10986498,10987265,10987010,10987777,10987522,157185,154625,155905,158721,0,0,171521,165633,171265,11227905,10990849,10990594,10991361,10991106,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10990338,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1286146,1286402,1286658,1286914,1287170,1287426,1287682,1287938,1288194,1288450,1288706,1288962,1289218,1289474,1289730,1289986,1290242,1290498,1290754,1291010,1291266,1291522,1291778,1292034,1292290,1292546,1292802,1293058,1293314,1293570,1293826,1294082,1294338,1294594,1294850,1295106,1295362,1295618,1295874,1296130,1296386,1296642,1296898,1297154,1297410,1297666,1297922,1298178,1298434,1298690,1298946,1299202,1299458,1299714,1299970,1300226,1300482,1300738,1300994,1301250,1301506,1301762,1302018,1302274,1302530,1302786,1303042,1303298,1303554,1303810,1304066,1304322,1304578,1304834,1305090,1305346,1305602,1305858,1306114,1306370,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,16728321,16728577,16728833,16729089,16729345,16729601,16729857,16730113,16730369,16730625,16730881,16731137,16731393,16731649,16731905,16732161,16732417,16732673,16732929,16733185,16733441,16733697,16733953,16734209,16734465,16734721,0,0,0,0,0,0,16720130,16720386,16720642,16720898,16721154,16721410,16721666,16721922,16722178,16722434,16722690,16722946,16723202,16723458,16723714,16723970,16724226,16724482,16724738,16724994,16725250,16725506,16725762,16726018,16726274,16726530,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {17049601,17049857,17050113,17050369,17050625,17050881,17051137,17051393,17051649,17051905,17052161,17052417,17052673,17052929,17053185,17053441,17053697,17053953,17054209,17054465,17054721,17054977,17055233,17055489,17055745,17056001,17056257,17056513,17056769,17057025,17057281,17057537,17057793,17058049,17058305,17058561,17058817,17059073,17059329,17059585,17039362,17039618,17039874,17040130,17040386,17040642,17040898,17041154,17041410,17041666,17041922,17042178,17042434,17042690,17042946,17043202,17043458,17043714,17043970,17044226,17044482,17044738,17044994,17045250,17045506,17045762,17046018,17046274,17046530,17046786,17047042,17047298,17047554,17047810,17048066,17048322,17048578,17048834,17049090,17049346,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,17612801,17613057,17613313,17613569,17613825,17614081,17614337,17614593,17614849,17615105,17615361,17615617,17615873,17616129,17616385,17616641,17616897,17617153,17617409,17617665,17617921,17618177,17618433,17618689,17618945,17619201,17619457,17619713,17619969,17620225,17620481,17620737,17620993,17621249,17621505,17621761,17622017,17622273,17622529,17622785,17623041,17623297,17623553,17623809,17624065,17624321,17624577,17624833,17625089,17625345,17625601,0,0,0,0,0,0,0,0,0,0,0,0,0,17596418,17596674,17596930,17597186,17597442,17597698,17597954,17598210,17598466,17598722,17598978,17599234,17599490,17599746,17600002,17600258,17600514,17600770,17601026,17601282,17601538,17601794,17602050,17602306,17602562,17602818,17603074,17603330,17603586,17603842,17604098,17604354,17604610,17604866,17605122,17605378,17605634,17605890,17606146,17606402,17606658,17606914,17607170,17607426,17607682,17607938,17608194,17608450,17608706,17608962,17609218,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,18399233,18399489,18399745,18400001,18400257,18400513,18400769,18401025,18401281,18401537,18401793,18402049,18402305,18402561,18402817,18403073,18403329,18403585,18403841,18404097,18404353,18404609,18404865,18405121,18405377,18405633,18405889,18406145,18406401,18406657,18406913,18407169,18391042,18391298,18391554,18391810,18392066,18392322,18392578,18392834,18393090,18393346,18393602,18393858,18394114,18394370,18394626,18394882,18395138,18395394,18395650,18395906,18396162,18396418,18396674,18396930,18397186,18397442,18397698,18397954,18398210,18398466,18398722,18398978,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
};

} // namespace unilib

/////////
// File: unilib/utf8.cpp
/////////

// This file is part of UniLib <http://github.com/ufal/unilib/>.
//
// Copyright 2014 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// UniLib version: 3.1.0
// Unicode version: 8.0.0

namespace unilib {

bool utf8::valid(const char* str) {
  for (const unsigned char*& ptr = (const unsigned char*&) str; *ptr; ptr++)
    if (*ptr >= 0x80) {
      if (*ptr < 0xC0) return false;
      else if (*ptr < 0xE0) {
        ptr++; if (*ptr < 0x80 || *ptr >= 0xC0) return false;
      } else if (*ptr < 0xF0) {
        ptr++; if (*ptr < 0x80 || *ptr >= 0xC0) return false;
        ptr++; if (*ptr < 0x80 || *ptr >= 0xC0) return false;
      } else if (*ptr < 0xF8) {
        ptr++; if (*ptr < 0x80 || *ptr >= 0xC0) return false;
        ptr++; if (*ptr < 0x80 || *ptr >= 0xC0) return false;
        ptr++; if (*ptr < 0x80 || *ptr >= 0xC0) return false;
      } else return false;
    }
  return true;
}

bool utf8::valid(const char* str, size_t len) {
  for (const unsigned char*& ptr = (const unsigned char*&) str; len > 0; ptr++, len--)
    if (*ptr >= 0x80) {
      if (*ptr < 0xC0) return false;
      else if (*ptr < 0xE0) {
        ptr++; if (!--len || *ptr < 0x80 || *ptr >= 0xC0) return false;
      } else if (*ptr < 0xF0) {
        ptr++; if (!--len || *ptr < 0x80 || *ptr >= 0xC0) return false;
        ptr++; if (!--len || *ptr < 0x80 || *ptr >= 0xC0) return false;
      } else if (*ptr < 0xF8) {
        ptr++; if (!--len || *ptr < 0x80 || *ptr >= 0xC0) return false;
        ptr++; if (!--len || *ptr < 0x80 || *ptr >= 0xC0) return false;
        ptr++; if (!--len || *ptr < 0x80 || *ptr >= 0xC0) return false;
      } else return false;
    }
  return true;
}

void utf8::decode(const char* str, std::u32string& decoded) {
  decoded.clear();

  for (char32_t chr; (chr = decode(str)); )
    decoded.push_back(chr);
}

void utf8::decode(const char* str, size_t len, std::u32string& decoded) {
  decoded.clear();

  while (len)
    decoded.push_back(decode(str, len));
}

void utf8::encode(const std::u32string& str, std::string& encoded) {
  encoded.clear();

  for (auto&& chr : str)
    append(encoded, chr);
}

const char utf8::REPLACEMENT_CHAR;

} // namespace unilib

/////////
// File: unilib/version.h
/////////

// This file is part of UniLib <http://github.com/ufal/unilib/>.
//
// Copyright 2014 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// UniLib version: 3.1.0
// Unicode version: 8.0.0

namespace unilib {

struct version {
  unsigned major;
  unsigned minor;
  unsigned patch;
  std::string prerelease;

  // Returns current version.
  static version current();
};

} // namespace unilib

/////////
// File: unilib/version.cpp
/////////

// This file is part of UniLib <http://github.com/ufal/unilib/>.
//
// Copyright 2014 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// UniLib version: 3.1.0
// Unicode version: 8.0.0

namespace unilib {

// Returns current version.
version version::current() {
  return {3, 1, 0, ""};
}

} // namespace unilib

/////////
// File: utils/compressor_load.cpp
/////////

// This file is part of UFAL C++ Utils <http://github.com/ufal/cpp_utils/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Start of LZMA compression library by Igor Pavlov
namespace lzma {

// Types.h -- Basic types
// 2010-10-09 : Igor Pavlov : Public domain

#define SZ_OK 0

#define SZ_ERROR_DATA 1
#define SZ_ERROR_MEM 2
#define SZ_ERROR_CRC 3
#define SZ_ERROR_UNSUPPORTED 4
#define SZ_ERROR_PARAM 5
#define SZ_ERROR_INPUT_EOF 6
#define SZ_ERROR_OUTPUT_EOF 7
#define SZ_ERROR_READ 8
#define SZ_ERROR_WRITE 9
#define SZ_ERROR_PROGRESS 10
#define SZ_ERROR_FAIL 11
#define SZ_ERROR_THREAD 12

#define SZ_ERROR_ARCHIVE 16
#define SZ_ERROR_NO_ARCHIVE 17

typedef int SRes;

#ifndef RINOK
#define RINOK(x) { int __result__ = (x); if (__result__ != 0) return __result__; }
#endif

/* The following interfaces use first parameter as pointer to structure */

struct IByteIn
{
  uint8_t (*Read)(void *p); /* reads one byte, returns 0 in case of EOF or error */
};

struct IByteOut
{
  void (*Write)(void *p, uint8_t b);
};

struct ISeqInStream
{
  SRes (*Read)(void *p, void *buf, size_t *size);
    /* if (input(*size) != 0 && output(*size) == 0) means end_of_stream.
       (output(*size) < input(*size)) is allowed */
};

/* it can return SZ_ERROR_INPUT_EOF */
SRes SeqInStream_Read(ISeqInStream *stream, void *buf, size_t size);
SRes SeqInStream_Read2(ISeqInStream *stream, void *buf, size_t size, SRes errorType);
SRes SeqInStream_ReadByte(ISeqInStream *stream, uint8_t *buf);

struct ISeqOutStream
{
  size_t (*Write)(void *p, const void *buf, size_t size);
    /* Returns: result - the number of actually written bytes.
       (result < size) means error */
};

enum ESzSeek
{
  SZ_SEEK_SET = 0,
  SZ_SEEK_CUR = 1,
  SZ_SEEK_END = 2
};

struct ISeekInStream
{
  SRes (*Read)(void *p, void *buf, size_t *size);  /* same as ISeqInStream::Read */
  SRes (*Seek)(void *p, int64_t *pos, ESzSeek origin);
};

struct ILookInStream
{
  SRes (*Look)(void *p, const void **buf, size_t *size);
    /* if (input(*size) != 0 && output(*size) == 0) means end_of_stream.
       (output(*size) > input(*size)) is not allowed
       (output(*size) < input(*size)) is allowed */
  SRes (*Skip)(void *p, size_t offset);
    /* offset must be <= output(*size) of Look */

  SRes (*Read)(void *p, void *buf, size_t *size);
    /* reads directly (without buffer). It's same as ISeqInStream::Read */
  SRes (*Seek)(void *p, int64_t *pos, ESzSeek origin);
};

SRes LookInStream_LookRead(ILookInStream *stream, void *buf, size_t *size);
SRes LookInStream_SeekTo(ILookInStream *stream, uint64_t offset);

/* reads via ILookInStream::Read */
SRes LookInStream_Read2(ILookInStream *stream, void *buf, size_t size, SRes errorType);
SRes LookInStream_Read(ILookInStream *stream, void *buf, size_t size);

#define LookToRead_BUF_SIZE (1 << 14)

struct CLookToRead
{
  ILookInStream s;
  ISeekInStream *realStream;
  size_t pos;
  size_t size;
  uint8_t buf[LookToRead_BUF_SIZE];
};

void LookToRead_CreateVTable(CLookToRead *p, int lookahead);
void LookToRead_Init(CLookToRead *p);

struct CSecToLook
{
  ISeqInStream s;
  ILookInStream *realStream;
};

void SecToLook_CreateVTable(CSecToLook *p);

struct CSecToRead
{
  ISeqInStream s;
  ILookInStream *realStream;
};

void SecToRead_CreateVTable(CSecToRead *p);

struct ICompressProgress
{
  SRes (*Progress)(void *p, uint64_t inSize, uint64_t outSize);
    /* Returns: result. (result != SZ_OK) means break.
       Value (uint64_t)(int64_t)-1 for size means unknown value. */
};

struct ISzAlloc
{
  void *(*Alloc)(void *p, size_t size);
  void (*Free)(void *p, void *address); /* address can be 0 */
};

#define IAlloc_Alloc(p, size) (p)->Alloc((p), size)
#define IAlloc_Free(p, a) (p)->Free((p), a)

// LzmaDec.h -- LZMA Decoder
// 2009-02-07 : Igor Pavlov : Public domain

/* #define _LZMA_PROB32 */
/* _LZMA_PROB32 can increase the speed on some CPUs,
   but memory usage for CLzmaDec::probs will be doubled in that case */

#ifdef _LZMA_PROB32
#define CLzmaProb uint32_t
#else
#define CLzmaProb uint16_t
#endif

/* ---------- LZMA Properties ---------- */

#define LZMA_PROPS_SIZE 5

struct CLzmaProps
{
  unsigned lc, lp, pb;
  uint32_t dicSize;
};

/* LzmaProps_Decode - decodes properties
Returns:
  SZ_OK
  SZ_ERROR_UNSUPPORTED - Unsupported properties
*/

SRes LzmaProps_Decode(CLzmaProps *p, const uint8_t *data, unsigned size);

/* ---------- LZMA Decoder state ---------- */

/* LZMA_REQUIRED_INPUT_MAX = number of required input bytes for worst case.
   Num bits = log2((2^11 / 31) ^ 22) + 26 < 134 + 26 = 160; */

#define LZMA_REQUIRED_INPUT_MAX 20

struct CLzmaDec
{
  CLzmaProps prop;
  CLzmaProb *probs;
  uint8_t *dic;
  const uint8_t *buf;
  uint32_t range, code;
  size_t dicPos;
  size_t dicBufSize;
  uint32_t processedPos;
  uint32_t checkDicSize;
  unsigned state;
  uint32_t reps[4];
  unsigned remainLen;
  int needFlush;
  int needInitState;
  uint32_t numProbs;
  unsigned tempBufSize;
  uint8_t tempBuf[LZMA_REQUIRED_INPUT_MAX];
};

#define LzmaDec_Construct(p) { (p)->dic = 0; (p)->probs = 0; }

void LzmaDec_Init(CLzmaDec *p);

/* There are two types of LZMA streams:
     0) Stream with end mark. That end mark adds about 6 bytes to compressed size.
     1) Stream without end mark. You must know exact uncompressed size to decompress such stream. */

enum ELzmaFinishMode
{
  LZMA_FINISH_ANY,   /* finish at any point */
  LZMA_FINISH_END    /* block must be finished at the end */
};

/* ELzmaFinishMode has meaning only if the decoding reaches output limit !!!

   You must use LZMA_FINISH_END, when you know that current output buffer
   covers last bytes of block. In other cases you must use LZMA_FINISH_ANY.

   If LZMA decoder sees end marker before reaching output limit, it returns SZ_OK,
   and output value of destLen will be less than output buffer size limit.
   You can check status result also.

   You can use multiple checks to test data integrity after full decompression:
     1) Check Result and "status" variable.
     2) Check that output(destLen) = uncompressedSize, if you know real uncompressedSize.
     3) Check that output(srcLen) = compressedSize, if you know real compressedSize.
        You must use correct finish mode in that case. */

enum ELzmaStatus
{
  LZMA_STATUS_NOT_SPECIFIED,               /* use main error code instead */
  LZMA_STATUS_FINISHED_WITH_MARK,          /* stream was finished with end mark. */
  LZMA_STATUS_NOT_FINISHED,                /* stream was not finished */
  LZMA_STATUS_NEEDS_MORE_INPUT,            /* you must provide more input bytes */
  LZMA_STATUS_MAYBE_FINISHED_WITHOUT_MARK  /* there is probability that stream was finished without end mark */
};

/* ELzmaStatus is used only as output value for function call */

/* ---------- Interfaces ---------- */

/* There are 3 levels of interfaces:
     1) Dictionary Interface
     2) Buffer Interface
     3) One Call Interface
   You can select any of these interfaces, but don't mix functions from different
   groups for same object. */

/* There are two variants to allocate state for Dictionary Interface:
     1) LzmaDec_Allocate / LzmaDec_Free
     2) LzmaDec_AllocateProbs / LzmaDec_FreeProbs
   You can use variant 2, if you set dictionary buffer manually.
   For Buffer Interface you must always use variant 1.

LzmaDec_Allocate* can return:
  SZ_OK
  SZ_ERROR_MEM         - Memory allocation error
  SZ_ERROR_UNSUPPORTED - Unsupported properties
*/
   
SRes LzmaDec_AllocateProbs(CLzmaDec *p, const uint8_t *props, unsigned propsSize, ISzAlloc *alloc);
void LzmaDec_FreeProbs(CLzmaDec *p, ISzAlloc *alloc);

SRes LzmaDec_Allocate(CLzmaDec *state, const uint8_t *prop, unsigned propsSize, ISzAlloc *alloc);
void LzmaDec_Free(CLzmaDec *state, ISzAlloc *alloc);

/* ---------- Dictionary Interface ---------- */

/* You can use it, if you want to eliminate the overhead for data copying from
   dictionary to some other external buffer.
   You must work with CLzmaDec variables directly in this interface.

   STEPS:
     LzmaDec_Constr()
     LzmaDec_Allocate()
     for (each new stream)
     {
       LzmaDec_Init()
       while (it needs more decompression)
       {
         LzmaDec_DecodeToDic()
         use data from CLzmaDec::dic and update CLzmaDec::dicPos
       }
     }
     LzmaDec_Free()
*/

/* LzmaDec_DecodeToDic
   
   The decoding to internal dictionary buffer (CLzmaDec::dic).
   You must manually update CLzmaDec::dicPos, if it reaches CLzmaDec::dicBufSize !!!

finishMode:
  It has meaning only if the decoding reaches output limit (dicLimit).
  LZMA_FINISH_ANY - Decode just dicLimit bytes.
  LZMA_FINISH_END - Stream must be finished after dicLimit.

Returns:
  SZ_OK
    status:
      LZMA_STATUS_FINISHED_WITH_MARK
      LZMA_STATUS_NOT_FINISHED
      LZMA_STATUS_NEEDS_MORE_INPUT
      LZMA_STATUS_MAYBE_FINISHED_WITHOUT_MARK
  SZ_ERROR_DATA - Data error
*/

SRes LzmaDec_DecodeToDic(CLzmaDec *p, size_t dicLimit,
    const uint8_t *src, size_t *srcLen, ELzmaFinishMode finishMode, ELzmaStatus *status);

/* ---------- Buffer Interface ---------- */

/* It's zlib-like interface.
   See LzmaDec_DecodeToDic description for information about STEPS and return results,
   but you must use LzmaDec_DecodeToBuf instead of LzmaDec_DecodeToDic and you don't need
   to work with CLzmaDec variables manually.

finishMode:
  It has meaning only if the decoding reaches output limit (*destLen).
  LZMA_FINISH_ANY - Decode just destLen bytes.
  LZMA_FINISH_END - Stream must be finished after (*destLen).
*/

SRes LzmaDec_DecodeToBuf(CLzmaDec *p, uint8_t *dest, size_t *destLen,
    const uint8_t *src, size_t *srcLen, ELzmaFinishMode finishMode, ELzmaStatus *status);

/* ---------- One Call Interface ---------- */

/* LzmaDecode

finishMode:
  It has meaning only if the decoding reaches output limit (*destLen).
  LZMA_FINISH_ANY - Decode just destLen bytes.
  LZMA_FINISH_END - Stream must be finished after (*destLen).

Returns:
  SZ_OK
    status:
      LZMA_STATUS_FINISHED_WITH_MARK
      LZMA_STATUS_NOT_FINISHED
      LZMA_STATUS_MAYBE_FINISHED_WITHOUT_MARK
  SZ_ERROR_DATA - Data error
  SZ_ERROR_MEM  - Memory allocation error
  SZ_ERROR_UNSUPPORTED - Unsupported properties
  SZ_ERROR_INPUT_EOF - It needs more bytes in input buffer (src).
*/

SRes LzmaDecode(uint8_t *dest, size_t *destLen, const uint8_t *src, size_t *srcLen,
    const uint8_t *propData, unsigned propSize, ELzmaFinishMode finishMode,
    ELzmaStatus *status, ISzAlloc *alloc);

// LzmaDec.c -- LZMA Decoder
// 2009-09-20 : Igor Pavlov : Public domain

#define kNumTopBits 24
#define kTopValue ((uint32_t)1 << kNumTopBits)

#define kNumBitModelTotalBits 11
#define kBitModelTotal (1 << kNumBitModelTotalBits)
#define kNumMoveBits 5

#define RC_INIT_SIZE 5

#define NORMALIZE if (range < kTopValue) { range <<= 8; code = (code << 8) | (*buf++); }

#define IF_BIT_0(p) ttt = *(p); NORMALIZE; bound = (range >> kNumBitModelTotalBits) * ttt; if (code < bound)
#define UPDATE_0(p) range = bound; *(p) = (CLzmaProb)(ttt + ((kBitModelTotal - ttt) >> kNumMoveBits));
#define UPDATE_1(p) range -= bound; code -= bound; *(p) = (CLzmaProb)(ttt - (ttt >> kNumMoveBits));
#define GET_BIT2(p, i, A0, A1) IF_BIT_0(p) \
  { UPDATE_0(p); i = (i + i); A0; } else \
  { UPDATE_1(p); i = (i + i) + 1; A1; }
#define GET_BIT(p, i) GET_BIT2(p, i, ; , ;)

#define TREE_GET_BIT(probs, i) { GET_BIT((probs + i), i); }
#define TREE_DECODE(probs, limit, i) \
  { i = 1; do { TREE_GET_BIT(probs, i); } while (i < limit); i -= limit; }

/* #define _LZMA_SIZE_OPT */

#ifdef _LZMA_SIZE_OPT
#define TREE_6_DECODE(probs, i) TREE_DECODE(probs, (1 << 6), i)
#else
#define TREE_6_DECODE(probs, i) \
  { i = 1; \
  TREE_GET_BIT(probs, i); \
  TREE_GET_BIT(probs, i); \
  TREE_GET_BIT(probs, i); \
  TREE_GET_BIT(probs, i); \
  TREE_GET_BIT(probs, i); \
  TREE_GET_BIT(probs, i); \
  i -= 0x40; }
#endif

#define NORMALIZE_CHECK if (range < kTopValue) { if (buf >= bufLimit) return DUMMY_ERROR; range <<= 8; code = (code << 8) | (*buf++); }

#define IF_BIT_0_CHECK(p) ttt = *(p); NORMALIZE_CHECK; bound = (range >> kNumBitModelTotalBits) * ttt; if (code < bound)
#define UPDATE_0_CHECK range = bound;
#define UPDATE_1_CHECK range -= bound; code -= bound;
#define GET_BIT2_CHECK(p, i, A0, A1) IF_BIT_0_CHECK(p) \
  { UPDATE_0_CHECK; i = (i + i); A0; } else \
  { UPDATE_1_CHECK; i = (i + i) + 1; A1; }
#define GET_BIT_CHECK(p, i) GET_BIT2_CHECK(p, i, ; , ;)
#define TREE_DECODE_CHECK(probs, limit, i) \
  { i = 1; do { GET_BIT_CHECK(probs + i, i) } while (i < limit); i -= limit; }

#define kNumPosBitsMax 4
#define kNumPosStatesMax (1 << kNumPosBitsMax)

#define kLenNumLowBits 3
#define kLenNumLowSymbols (1 << kLenNumLowBits)
#define kLenNumMidBits 3
#define kLenNumMidSymbols (1 << kLenNumMidBits)
#define kLenNumHighBits 8
#define kLenNumHighSymbols (1 << kLenNumHighBits)

#define LenChoice 0
#define LenChoice2 (LenChoice + 1)
#define LenLow (LenChoice2 + 1)
#define LenMid (LenLow + (kNumPosStatesMax << kLenNumLowBits))
#define LenHigh (LenMid + (kNumPosStatesMax << kLenNumMidBits))
#define kNumLenProbs (LenHigh + kLenNumHighSymbols)

#define kNumStates 12
#define kNumLitStates 7

#define kStartPosModelIndex 4
#define kEndPosModelIndex 14
#define kNumFullDistances (1 << (kEndPosModelIndex >> 1))

#define kNumPosSlotBits 6
#define kNumLenToPosStates 4

#define kNumAlignBits 4
#define kAlignTableSize (1 << kNumAlignBits)

#define kMatchMinLen 2
#define kMatchSpecLenStart (kMatchMinLen + kLenNumLowSymbols + kLenNumMidSymbols + kLenNumHighSymbols)

#define IsMatch 0
#define IsRep (IsMatch + (kNumStates << kNumPosBitsMax))
#define IsRepG0 (IsRep + kNumStates)
#define IsRepG1 (IsRepG0 + kNumStates)
#define IsRepG2 (IsRepG1 + kNumStates)
#define IsRep0Long (IsRepG2 + kNumStates)
#define PosSlot (IsRep0Long + (kNumStates << kNumPosBitsMax))
#define SpecPos (PosSlot + (kNumLenToPosStates << kNumPosSlotBits))
#define Align (SpecPos + kNumFullDistances - kEndPosModelIndex)
#define LenCoder (Align + kAlignTableSize)
#define RepLenCoder (LenCoder + kNumLenProbs)
#define Literal (RepLenCoder + kNumLenProbs)

#define LZMA_BASE_SIZE 1846
#define LZMA_LIT_SIZE 768

#define LzmaProps_GetNumProbs(p) ((uint32_t)LZMA_BASE_SIZE + (LZMA_LIT_SIZE << ((p)->lc + (p)->lp)))

#if Literal != LZMA_BASE_SIZE
StopCompilingDueBUG
#endif

#define LZMA_DIC_MIN (1 << 12)

/* First LZMA-symbol is always decoded.
And it decodes new LZMA-symbols while (buf < bufLimit), but "buf" is without last normalization
Out:
  Result:
    SZ_OK - OK
    SZ_ERROR_DATA - Error
  p->remainLen:
    < kMatchSpecLenStart : normal remain
    = kMatchSpecLenStart : finished
    = kMatchSpecLenStart + 1 : Flush marker
    = kMatchSpecLenStart + 2 : State Init Marker
*/

static int LzmaDec_DecodeReal(CLzmaDec *p, size_t limit, const uint8_t *bufLimit)
{
  CLzmaProb *probs = p->probs;

  unsigned state = p->state;
  uint32_t rep0 = p->reps[0], rep1 = p->reps[1], rep2 = p->reps[2], rep3 = p->reps[3];
  unsigned pbMask = ((unsigned)1 << (p->prop.pb)) - 1;
  unsigned lpMask = ((unsigned)1 << (p->prop.lp)) - 1;
  unsigned lc = p->prop.lc;

  uint8_t *dic = p->dic;
  size_t dicBufSize = p->dicBufSize;
  size_t dicPos = p->dicPos;
  
  uint32_t processedPos = p->processedPos;
  uint32_t checkDicSize = p->checkDicSize;
  unsigned len = 0;

  const uint8_t *buf = p->buf;
  uint32_t range = p->range;
  uint32_t code = p->code;

  do
  {
    CLzmaProb *prob;
    uint32_t bound;
    unsigned ttt;
    unsigned posState = processedPos & pbMask;

    prob = probs + IsMatch + (state << kNumPosBitsMax) + posState;
    IF_BIT_0(prob)
    {
      unsigned symbol;
      UPDATE_0(prob);
      prob = probs + Literal;
      if (checkDicSize != 0 || processedPos != 0)
        prob += (LZMA_LIT_SIZE * (((processedPos & lpMask) << lc) +
        (dic[(dicPos == 0 ? dicBufSize : dicPos) - 1] >> (8 - lc))));

      if (state < kNumLitStates)
      {
        state -= (state < 4) ? state : 3;
        symbol = 1;
        do { GET_BIT(prob + symbol, symbol) } while (symbol < 0x100);
      }
      else
      {
        unsigned matchByte = p->dic[(dicPos - rep0) + ((dicPos < rep0) ? dicBufSize : 0)];
        unsigned offs = 0x100;
        state -= (state < 10) ? 3 : 6;
        symbol = 1;
        do
        {
          unsigned bit;
          CLzmaProb *probLit;
          matchByte <<= 1;
          bit = (matchByte & offs);
          probLit = prob + offs + bit + symbol;
          GET_BIT2(probLit, symbol, offs &= ~bit, offs &= bit)
        }
        while (symbol < 0x100);
      }
      dic[dicPos++] = (uint8_t)symbol;
      processedPos++;
      continue;
    }
    else
    {
      UPDATE_1(prob);
      prob = probs + IsRep + state;
      IF_BIT_0(prob)
      {
        UPDATE_0(prob);
        state += kNumStates;
        prob = probs + LenCoder;
      }
      else
      {
        UPDATE_1(prob);
        if (checkDicSize == 0 && processedPos == 0)
          return SZ_ERROR_DATA;
        prob = probs + IsRepG0 + state;
        IF_BIT_0(prob)
        {
          UPDATE_0(prob);
          prob = probs + IsRep0Long + (state << kNumPosBitsMax) + posState;
          IF_BIT_0(prob)
          {
            UPDATE_0(prob);
            dic[dicPos] = dic[(dicPos - rep0) + ((dicPos < rep0) ? dicBufSize : 0)];
            dicPos++;
            processedPos++;
            state = state < kNumLitStates ? 9 : 11;
            continue;
          }
          UPDATE_1(prob);
        }
        else
        {
          uint32_t distance;
          UPDATE_1(prob);
          prob = probs + IsRepG1 + state;
          IF_BIT_0(prob)
          {
            UPDATE_0(prob);
            distance = rep1;
          }
          else
          {
            UPDATE_1(prob);
            prob = probs + IsRepG2 + state;
            IF_BIT_0(prob)
            {
              UPDATE_0(prob);
              distance = rep2;
            }
            else
            {
              UPDATE_1(prob);
              distance = rep3;
              rep3 = rep2;
            }
            rep2 = rep1;
          }
          rep1 = rep0;
          rep0 = distance;
        }
        state = state < kNumLitStates ? 8 : 11;
        prob = probs + RepLenCoder;
      }
      {
        unsigned limit, offset;
        CLzmaProb *probLen = prob + LenChoice;
        IF_BIT_0(probLen)
        {
          UPDATE_0(probLen);
          probLen = prob + LenLow + (posState << kLenNumLowBits);
          offset = 0;
          limit = (1 << kLenNumLowBits);
        }
        else
        {
          UPDATE_1(probLen);
          probLen = prob + LenChoice2;
          IF_BIT_0(probLen)
          {
            UPDATE_0(probLen);
            probLen = prob + LenMid + (posState << kLenNumMidBits);
            offset = kLenNumLowSymbols;
            limit = (1 << kLenNumMidBits);
          }
          else
          {
            UPDATE_1(probLen);
            probLen = prob + LenHigh;
            offset = kLenNumLowSymbols + kLenNumMidSymbols;
            limit = (1 << kLenNumHighBits);
          }
        }
        TREE_DECODE(probLen, limit, len);
        len += offset;
      }

      if (state >= kNumStates)
      {
        uint32_t distance;
        prob = probs + PosSlot +
            ((len < kNumLenToPosStates ? len : kNumLenToPosStates - 1) << kNumPosSlotBits);
        TREE_6_DECODE(prob, distance);
        if (distance >= kStartPosModelIndex)
        {
          unsigned posSlot = (unsigned)distance;
          int numDirectBits = (int)(((distance >> 1) - 1));
          distance = (2 | (distance & 1));
          if (posSlot < kEndPosModelIndex)
          {
            distance <<= numDirectBits;
            prob = probs + SpecPos + distance - posSlot - 1;
            {
              uint32_t mask = 1;
              unsigned i = 1;
              do
              {
                GET_BIT2(prob + i, i, ; , distance |= mask);
                mask <<= 1;
              }
              while (--numDirectBits != 0);
            }
          }
          else
          {
            numDirectBits -= kNumAlignBits;
            do
            {
              NORMALIZE
              range >>= 1;
              
              {
                uint32_t t;
                code -= range;
                t = (0 - ((uint32_t)code >> 31)); /* (uint32_t)((int32_t)code >> 31) */
                distance = (distance << 1) + (t + 1);
                code += range & t;
              }
              /*
              distance <<= 1;
              if (code >= range)
              {
                code -= range;
                distance |= 1;
              }
              */
            }
            while (--numDirectBits != 0);
            prob = probs + Align;
            distance <<= kNumAlignBits;
            {
              unsigned i = 1;
              GET_BIT2(prob + i, i, ; , distance |= 1);
              GET_BIT2(prob + i, i, ; , distance |= 2);
              GET_BIT2(prob + i, i, ; , distance |= 4);
              GET_BIT2(prob + i, i, ; , distance |= 8);
            }
            if (distance == (uint32_t)0xFFFFFFFF)
            {
              len += kMatchSpecLenStart;
              state -= kNumStates;
              break;
            }
          }
        }
        rep3 = rep2;
        rep2 = rep1;
        rep1 = rep0;
        rep0 = distance + 1;
        if (checkDicSize == 0)
        {
          if (distance >= processedPos)
            return SZ_ERROR_DATA;
        }
        else if (distance >= checkDicSize)
          return SZ_ERROR_DATA;
        state = (state < kNumStates + kNumLitStates) ? kNumLitStates : kNumLitStates + 3;
      }

      len += kMatchMinLen;

      if (limit == dicPos)
        return SZ_ERROR_DATA;
      {
        size_t rem = limit - dicPos;
        unsigned curLen = ((rem < len) ? (unsigned)rem : len);
        size_t pos = (dicPos - rep0) + ((dicPos < rep0) ? dicBufSize : 0);

        processedPos += curLen;

        len -= curLen;
        if (pos + curLen <= dicBufSize)
        {
          uint8_t *dest = dic + dicPos;
          ptrdiff_t src = (ptrdiff_t)pos - (ptrdiff_t)dicPos;
          const uint8_t *lim = dest + curLen;
          dicPos += curLen;
          do
            *(dest) = (uint8_t)*(dest + src);
          while (++dest != lim);
        }
        else
        {
          do
          {
            dic[dicPos++] = dic[pos];
            if (++pos == dicBufSize)
              pos = 0;
          }
          while (--curLen != 0);
        }
      }
    }
  }
  while (dicPos < limit && buf < bufLimit);
  NORMALIZE;
  p->buf = buf;
  p->range = range;
  p->code = code;
  p->remainLen = len;
  p->dicPos = dicPos;
  p->processedPos = processedPos;
  p->reps[0] = rep0;
  p->reps[1] = rep1;
  p->reps[2] = rep2;
  p->reps[3] = rep3;
  p->state = state;

  return SZ_OK;
}

static void LzmaDec_WriteRem(CLzmaDec *p, size_t limit)
{
  if (p->remainLen != 0 && p->remainLen < kMatchSpecLenStart)
  {
    uint8_t *dic = p->dic;
    size_t dicPos = p->dicPos;
    size_t dicBufSize = p->dicBufSize;
    unsigned len = p->remainLen;
    uint32_t rep0 = p->reps[0];
    if (limit - dicPos < len)
      len = (unsigned)(limit - dicPos);

    if (p->checkDicSize == 0 && p->prop.dicSize - p->processedPos <= len)
      p->checkDicSize = p->prop.dicSize;

    p->processedPos += len;
    p->remainLen -= len;
    while (len-- != 0)
    {
      dic[dicPos] = dic[(dicPos - rep0) + ((dicPos < rep0) ? dicBufSize : 0)];
      dicPos++;
    }
    p->dicPos = dicPos;
  }
}

static int LzmaDec_DecodeReal2(CLzmaDec *p, size_t limit, const uint8_t *bufLimit)
{
  do
  {
    size_t limit2 = limit;
    if (p->checkDicSize == 0)
    {
      uint32_t rem = p->prop.dicSize - p->processedPos;
      if (limit - p->dicPos > rem)
        limit2 = p->dicPos + rem;
    }
    RINOK(LzmaDec_DecodeReal(p, limit2, bufLimit));
    if (p->processedPos >= p->prop.dicSize)
      p->checkDicSize = p->prop.dicSize;
    LzmaDec_WriteRem(p, limit);
  }
  while (p->dicPos < limit && p->buf < bufLimit && p->remainLen < kMatchSpecLenStart);

  if (p->remainLen > kMatchSpecLenStart)
  {
    p->remainLen = kMatchSpecLenStart;
  }
  return 0;
}

enum ELzmaDummy
{
  DUMMY_ERROR, /* unexpected end of input stream */
  DUMMY_LIT,
  DUMMY_MATCH,
  DUMMY_REP
};

static ELzmaDummy LzmaDec_TryDummy(const CLzmaDec *p, const uint8_t *buf, size_t inSize)
{
  uint32_t range = p->range;
  uint32_t code = p->code;
  const uint8_t *bufLimit = buf + inSize;
  CLzmaProb *probs = p->probs;
  unsigned state = p->state;
  ELzmaDummy res;

  {
    CLzmaProb *prob;
    uint32_t bound;
    unsigned ttt;
    unsigned posState = (p->processedPos) & ((1 << p->prop.pb) - 1);

    prob = probs + IsMatch + (state << kNumPosBitsMax) + posState;
    IF_BIT_0_CHECK(prob)
    {
      UPDATE_0_CHECK

      /* if (bufLimit - buf >= 7) return DUMMY_LIT; */

      prob = probs + Literal;
      if (p->checkDicSize != 0 || p->processedPos != 0)
        prob += (LZMA_LIT_SIZE *
          ((((p->processedPos) & ((1 << (p->prop.lp)) - 1)) << p->prop.lc) +
          (p->dic[(p->dicPos == 0 ? p->dicBufSize : p->dicPos) - 1] >> (8 - p->prop.lc))));

      if (state < kNumLitStates)
      {
        unsigned symbol = 1;
        do { GET_BIT_CHECK(prob + symbol, symbol) } while (symbol < 0x100);
      }
      else
      {
        unsigned matchByte = p->dic[p->dicPos - p->reps[0] +
            ((p->dicPos < p->reps[0]) ? p->dicBufSize : 0)];
        unsigned offs = 0x100;
        unsigned symbol = 1;
        do
        {
          unsigned bit;
          CLzmaProb *probLit;
          matchByte <<= 1;
          bit = (matchByte & offs);
          probLit = prob + offs + bit + symbol;
          GET_BIT2_CHECK(probLit, symbol, offs &= ~bit, offs &= bit)
        }
        while (symbol < 0x100);
      }
      res = DUMMY_LIT;
    }
    else
    {
      unsigned len;
      UPDATE_1_CHECK;

      prob = probs + IsRep + state;
      IF_BIT_0_CHECK(prob)
      {
        UPDATE_0_CHECK;
        state = 0;
        prob = probs + LenCoder;
        res = DUMMY_MATCH;
      }
      else
      {
        UPDATE_1_CHECK;
        res = DUMMY_REP;
        prob = probs + IsRepG0 + state;
        IF_BIT_0_CHECK(prob)
        {
          UPDATE_0_CHECK;
          prob = probs + IsRep0Long + (state << kNumPosBitsMax) + posState;
          IF_BIT_0_CHECK(prob)
          {
            UPDATE_0_CHECK;
            NORMALIZE_CHECK;
            return DUMMY_REP;
          }
          else
          {
            UPDATE_1_CHECK;
          }
        }
        else
        {
          UPDATE_1_CHECK;
          prob = probs + IsRepG1 + state;
          IF_BIT_0_CHECK(prob)
          {
            UPDATE_0_CHECK;
          }
          else
          {
            UPDATE_1_CHECK;
            prob = probs + IsRepG2 + state;
            IF_BIT_0_CHECK(prob)
            {
              UPDATE_0_CHECK;
            }
            else
            {
              UPDATE_1_CHECK;
            }
          }
        }
        state = kNumStates;
        prob = probs + RepLenCoder;
      }
      {
        unsigned limit, offset;
        CLzmaProb *probLen = prob + LenChoice;
        IF_BIT_0_CHECK(probLen)
        {
          UPDATE_0_CHECK;
          probLen = prob + LenLow + (posState << kLenNumLowBits);
          offset = 0;
          limit = 1 << kLenNumLowBits;
        }
        else
        {
          UPDATE_1_CHECK;
          probLen = prob + LenChoice2;
          IF_BIT_0_CHECK(probLen)
          {
            UPDATE_0_CHECK;
            probLen = prob + LenMid + (posState << kLenNumMidBits);
            offset = kLenNumLowSymbols;
            limit = 1 << kLenNumMidBits;
          }
          else
          {
            UPDATE_1_CHECK;
            probLen = prob + LenHigh;
            offset = kLenNumLowSymbols + kLenNumMidSymbols;
            limit = 1 << kLenNumHighBits;
          }
        }
        TREE_DECODE_CHECK(probLen, limit, len);
        len += offset;
      }

      if (state < 4)
      {
        unsigned posSlot;
        prob = probs + PosSlot +
            ((len < kNumLenToPosStates ? len : kNumLenToPosStates - 1) <<
            kNumPosSlotBits);
        TREE_DECODE_CHECK(prob, 1 << kNumPosSlotBits, posSlot);
        if (posSlot >= kStartPosModelIndex)
        {
          int numDirectBits = ((posSlot >> 1) - 1);

          /* if (bufLimit - buf >= 8) return DUMMY_MATCH; */

          if (posSlot < kEndPosModelIndex)
          {
            prob = probs + SpecPos + ((2 | (posSlot & 1)) << numDirectBits) - posSlot - 1;
          }
          else
          {
            numDirectBits -= kNumAlignBits;
            do
            {
              NORMALIZE_CHECK
              range >>= 1;
              code -= range & (((code - range) >> 31) - 1);
              /* if (code >= range) code -= range; */
            }
            while (--numDirectBits != 0);
            prob = probs + Align;
            numDirectBits = kNumAlignBits;
          }
          {
            unsigned i = 1;
            do
            {
              GET_BIT_CHECK(prob + i, i);
            }
            while (--numDirectBits != 0);
          }
        }
      }
    }
  }
  NORMALIZE_CHECK;
  return res;
}

static void LzmaDec_InitRc(CLzmaDec *p, const uint8_t *data)
{
  p->code = ((uint32_t)data[1] << 24) | ((uint32_t)data[2] << 16) | ((uint32_t)data[3] << 8) | ((uint32_t)data[4]);
  p->range = 0xFFFFFFFF;
  p->needFlush = 0;
}

void LzmaDec_InitDicAndState(CLzmaDec *p, bool initDic, bool initState)
{
  p->needFlush = 1;
  p->remainLen = 0;
  p->tempBufSize = 0;

  if (initDic)
  {
    p->processedPos = 0;
    p->checkDicSize = 0;
    p->needInitState = 1;
  }
  if (initState)
    p->needInitState = 1;
}

void LzmaDec_Init(CLzmaDec *p)
{
  p->dicPos = 0;
  LzmaDec_InitDicAndState(p, true, true);
}

static void LzmaDec_InitStateReal(CLzmaDec *p)
{
  uint32_t numProbs = Literal + ((uint32_t)LZMA_LIT_SIZE << (p->prop.lc + p->prop.lp));
  uint32_t i;
  CLzmaProb *probs = p->probs;
  for (i = 0; i < numProbs; i++)
    probs[i] = kBitModelTotal >> 1;
  p->reps[0] = p->reps[1] = p->reps[2] = p->reps[3] = 1;
  p->state = 0;
  p->needInitState = 0;
}

SRes LzmaDec_DecodeToDic(CLzmaDec *p, size_t dicLimit, const uint8_t *src, size_t *srcLen,
    ELzmaFinishMode finishMode, ELzmaStatus *status)
{
  size_t inSize = *srcLen;
  (*srcLen) = 0;
  LzmaDec_WriteRem(p, dicLimit);
  
  *status = LZMA_STATUS_NOT_SPECIFIED;

  while (p->remainLen != kMatchSpecLenStart)
  {
      int checkEndMarkNow;

      if (p->needFlush != 0)
      {
        for (; inSize > 0 && p->tempBufSize < RC_INIT_SIZE; (*srcLen)++, inSize--)
          p->tempBuf[p->tempBufSize++] = *src++;
        if (p->tempBufSize < RC_INIT_SIZE)
        {
          *status = LZMA_STATUS_NEEDS_MORE_INPUT;
          return SZ_OK;
        }
        if (p->tempBuf[0] != 0)
          return SZ_ERROR_DATA;

        LzmaDec_InitRc(p, p->tempBuf);
        p->tempBufSize = 0;
      }

      checkEndMarkNow = 0;
      if (p->dicPos >= dicLimit)
      {
        if (p->remainLen == 0 && p->code == 0)
        {
          *status = LZMA_STATUS_MAYBE_FINISHED_WITHOUT_MARK;
          return SZ_OK;
        }
        if (finishMode == LZMA_FINISH_ANY)
        {
          *status = LZMA_STATUS_NOT_FINISHED;
          return SZ_OK;
        }
        if (p->remainLen != 0)
        {
          *status = LZMA_STATUS_NOT_FINISHED;
          return SZ_ERROR_DATA;
        }
        checkEndMarkNow = 1;
      }

      if (p->needInitState)
        LzmaDec_InitStateReal(p);
  
      if (p->tempBufSize == 0)
      {
        size_t processed;
        const uint8_t *bufLimit;
        if (inSize < LZMA_REQUIRED_INPUT_MAX || checkEndMarkNow)
        {
          int dummyRes = LzmaDec_TryDummy(p, src, inSize);
          if (dummyRes == DUMMY_ERROR)
          {
            memcpy(p->tempBuf, src, inSize);
            p->tempBufSize = (unsigned)inSize;
            (*srcLen) += inSize;
            *status = LZMA_STATUS_NEEDS_MORE_INPUT;
            return SZ_OK;
          }
          if (checkEndMarkNow && dummyRes != DUMMY_MATCH)
          {
            *status = LZMA_STATUS_NOT_FINISHED;
            return SZ_ERROR_DATA;
          }
          bufLimit = src;
        }
        else
          bufLimit = src + inSize - LZMA_REQUIRED_INPUT_MAX;
        p->buf = src;
        if (LzmaDec_DecodeReal2(p, dicLimit, bufLimit) != 0)
          return SZ_ERROR_DATA;
        processed = (size_t)(p->buf - src);
        (*srcLen) += processed;
        src += processed;
        inSize -= processed;
      }
      else
      {
        unsigned rem = p->tempBufSize, lookAhead = 0;
        while (rem < LZMA_REQUIRED_INPUT_MAX && lookAhead < inSize)
          p->tempBuf[rem++] = src[lookAhead++];
        p->tempBufSize = rem;
        if (rem < LZMA_REQUIRED_INPUT_MAX || checkEndMarkNow)
        {
          int dummyRes = LzmaDec_TryDummy(p, p->tempBuf, rem);
          if (dummyRes == DUMMY_ERROR)
          {
            (*srcLen) += lookAhead;
            *status = LZMA_STATUS_NEEDS_MORE_INPUT;
            return SZ_OK;
          }
          if (checkEndMarkNow && dummyRes != DUMMY_MATCH)
          {
            *status = LZMA_STATUS_NOT_FINISHED;
            return SZ_ERROR_DATA;
          }
        }
        p->buf = p->tempBuf;
        if (LzmaDec_DecodeReal2(p, dicLimit, p->buf) != 0)
          return SZ_ERROR_DATA;
        lookAhead -= (rem - (unsigned)(p->buf - p->tempBuf));
        (*srcLen) += lookAhead;
        src += lookAhead;
        inSize -= lookAhead;
        p->tempBufSize = 0;
      }
  }
  if (p->code == 0)
    *status = LZMA_STATUS_FINISHED_WITH_MARK;
  return (p->code == 0) ? SZ_OK : SZ_ERROR_DATA;
}

SRes LzmaDec_DecodeToBuf(CLzmaDec *p, uint8_t *dest, size_t *destLen, const uint8_t *src, size_t *srcLen, ELzmaFinishMode finishMode, ELzmaStatus *status)
{
  size_t outSize = *destLen;
  size_t inSize = *srcLen;
  *srcLen = *destLen = 0;
  for (;;)
  {
    size_t inSizeCur = inSize, outSizeCur, dicPos;
    ELzmaFinishMode curFinishMode;
    SRes res;
    if (p->dicPos == p->dicBufSize)
      p->dicPos = 0;
    dicPos = p->dicPos;
    if (outSize > p->dicBufSize - dicPos)
    {
      outSizeCur = p->dicBufSize;
      curFinishMode = LZMA_FINISH_ANY;
    }
    else
    {
      outSizeCur = dicPos + outSize;
      curFinishMode = finishMode;
    }

    res = LzmaDec_DecodeToDic(p, outSizeCur, src, &inSizeCur, curFinishMode, status);
    src += inSizeCur;
    inSize -= inSizeCur;
    *srcLen += inSizeCur;
    outSizeCur = p->dicPos - dicPos;
    memcpy(dest, p->dic + dicPos, outSizeCur);
    dest += outSizeCur;
    outSize -= outSizeCur;
    *destLen += outSizeCur;
    if (res != 0)
      return res;
    if (outSizeCur == 0 || outSize == 0)
      return SZ_OK;
  }
}

void LzmaDec_FreeProbs(CLzmaDec *p, ISzAlloc *alloc)
{
  alloc->Free(alloc, p->probs);
  p->probs = 0;
}

static void LzmaDec_FreeDict(CLzmaDec *p, ISzAlloc *alloc)
{
  alloc->Free(alloc, p->dic);
  p->dic = 0;
}

void LzmaDec_Free(CLzmaDec *p, ISzAlloc *alloc)
{
  LzmaDec_FreeProbs(p, alloc);
  LzmaDec_FreeDict(p, alloc);
}

SRes LzmaProps_Decode(CLzmaProps *p, const uint8_t *data, unsigned size)
{
  uint32_t dicSize;
  uint8_t d;
  
  if (size < LZMA_PROPS_SIZE)
    return SZ_ERROR_UNSUPPORTED;
  else
    dicSize = data[1] | ((uint32_t)data[2] << 8) | ((uint32_t)data[3] << 16) | ((uint32_t)data[4] << 24);
 
  if (dicSize < LZMA_DIC_MIN)
    dicSize = LZMA_DIC_MIN;
  p->dicSize = dicSize;

  d = data[0];
  if (d >= (9 * 5 * 5))
    return SZ_ERROR_UNSUPPORTED;

  p->lc = d % 9;
  d /= 9;
  p->pb = d / 5;
  p->lp = d % 5;

  return SZ_OK;
}

static SRes LzmaDec_AllocateProbs2(CLzmaDec *p, const CLzmaProps *propNew, ISzAlloc *alloc)
{
  uint32_t numProbs = LzmaProps_GetNumProbs(propNew);
  if (p->probs == 0 || numProbs != p->numProbs)
  {
    LzmaDec_FreeProbs(p, alloc);
    p->probs = (CLzmaProb *)alloc->Alloc(alloc, numProbs * sizeof(CLzmaProb));
    p->numProbs = numProbs;
    if (p->probs == 0)
      return SZ_ERROR_MEM;
  }
  return SZ_OK;
}

SRes LzmaDec_AllocateProbs(CLzmaDec *p, const uint8_t *props, unsigned propsSize, ISzAlloc *alloc)
{
  CLzmaProps propNew;
  RINOK(LzmaProps_Decode(&propNew, props, propsSize));
  RINOK(LzmaDec_AllocateProbs2(p, &propNew, alloc));
  p->prop = propNew;
  return SZ_OK;
}

SRes LzmaDec_Allocate(CLzmaDec *p, const uint8_t *props, unsigned propsSize, ISzAlloc *alloc)
{
  CLzmaProps propNew;
  size_t dicBufSize;
  RINOK(LzmaProps_Decode(&propNew, props, propsSize));
  RINOK(LzmaDec_AllocateProbs2(p, &propNew, alloc));
  dicBufSize = propNew.dicSize;
  if (p->dic == 0 || dicBufSize != p->dicBufSize)
  {
    LzmaDec_FreeDict(p, alloc);
    p->dic = (uint8_t *)alloc->Alloc(alloc, dicBufSize);
    if (p->dic == 0)
    {
      LzmaDec_FreeProbs(p, alloc);
      return SZ_ERROR_MEM;
    }
  }
  p->dicBufSize = dicBufSize;
  p->prop = propNew;
  return SZ_OK;
}

SRes LzmaDecode(uint8_t *dest, size_t *destLen, const uint8_t *src, size_t *srcLen,
    const uint8_t *propData, unsigned propSize, ELzmaFinishMode finishMode,
    ELzmaStatus *status, ISzAlloc *alloc)
{
  CLzmaDec p;
  SRes res;
  size_t inSize = *srcLen;
  size_t outSize = *destLen;
  *srcLen = *destLen = 0;
  if (inSize < RC_INIT_SIZE)
    return SZ_ERROR_INPUT_EOF;

  LzmaDec_Construct(&p);
  res = LzmaDec_AllocateProbs(&p, propData, propSize, alloc);
  if (res != 0)
    return res;
  p.dic = dest;
  p.dicBufSize = outSize;

  LzmaDec_Init(&p);
  
  *srcLen = inSize;
  res = LzmaDec_DecodeToDic(&p, outSize, src, srcLen, finishMode, status);

  if (res == SZ_OK && *status == LZMA_STATUS_NEEDS_MORE_INPUT)
    res = SZ_ERROR_INPUT_EOF;

  (*destLen) = p.dicPos;
  LzmaDec_FreeProbs(&p, alloc);
  return res;
}

} // namespace lzma
// End of LZMA compression library by Igor Pavlov

static void *LzmaAlloc(void* /*p*/, size_t size) { return new char[size]; }
static void LzmaFree(void* /*p*/, void *address) { delete[] (char*) address; }
static lzma::ISzAlloc lzmaAllocator = { LzmaAlloc, LzmaFree };

bool compressor::load(istream& is, binary_decoder& data) {
  uint32_t uncompressed_len, compressed_len, poor_crc;
  unsigned char props_encoded[LZMA_PROPS_SIZE];

  if (!is.read((char *) &uncompressed_len, sizeof(uncompressed_len))) return false;
  if (!is.read((char *) &compressed_len, sizeof(compressed_len))) return false;
  if (!is.read((char *) &poor_crc, sizeof(poor_crc))) return false;
  if (poor_crc != uncompressed_len * 19991 + compressed_len * 199999991 + 1234567890) return false;
  if (!is.read((char *) props_encoded, sizeof(props_encoded))) return false;

  vector<unsigned char> compressed(compressed_len);
  if (!is.read((char *) compressed.data(), compressed_len)) return false;

  lzma::ELzmaStatus status;
  size_t uncompressed_size = uncompressed_len, compressed_size = compressed_len;
  auto res = lzma::LzmaDecode(data.fill(uncompressed_len), &uncompressed_size, compressed.data(), &compressed_size, props_encoded, LZMA_PROPS_SIZE, lzma::LZMA_FINISH_ANY, &status, &lzmaAllocator);
  if (res != SZ_OK || uncompressed_size != uncompressed_len || compressed_size != compressed_len) return false;

  return true;
}

/////////
// File: version/version.h
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

struct version {
  unsigned major;
  unsigned minor;
  unsigned patch;
  std::string prerelease;

  // Returns current version.
  static version current();

  // Returns multi-line formated version and copyright string.
  static string version_and_copyright(const string& other_libraries = string());
};

/////////
// File: version/version.cpp
/////////

// This file is part of Parsito <http://github.com/ufal/parsito/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Returns current version.
version version::current() {
  return {1, 1, 0, ""};
}

// Returns multi-line formated version and copyright string.
string version::version_and_copyright(const string& other_libraries) {
  ostringstream info;

  auto parsito = version::current();
  auto unilib = unilib::version::current();

  info << "Parsito version " << parsito.major << '.' << parsito.minor << '.' << parsito.patch
       << (parsito.prerelease.empty() ? "" : "-") << parsito.prerelease
       << " (using UniLib " << unilib.major << '.' << unilib.minor << '.' << unilib.patch
       << (other_libraries.empty() ? "" : " and ") << other_libraries << ")\n"
          "Copyright 2015 by Institute of Formal and Applied Linguistics, Faculty of\n"
          "Mathematics and Physics, Charles University in Prague, Czech Republic.";

  return info.str();
}

} // namespace parsito
} // namespace ufal
