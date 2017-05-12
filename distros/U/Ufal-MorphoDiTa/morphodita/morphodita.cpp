// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// This file is a bundle of all sources and headers of MorphoDiTa library.
// Comments and copyrights of all individual files are kept.

#include <algorithm>
#include <atomic>
#include <cassert>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <iterator>
#include <map>
#include <memory>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace ufal {
namespace morphodita {

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

namespace utils {

using namespace std;

// Assert that int is at least 4B
static_assert(sizeof(int) >= sizeof(int32_t), "Int must be at least 4B wide!");

// Assert that we are on a little endian system
#ifdef __BYTE_ORDER__
static_assert(__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__, "Only little endian systems are supported!");
#endif

#define runtime_failure(message) exit((cerr << message << endl, 1))

} // namespace utils

/////////
// File: common.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

using namespace utils;

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

namespace utils {

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

} // namespace utils

/////////
// File: derivator/derivator.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2016 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

struct derivated_lemma {
  string lemma;
};

class derivator {
 public:
  virtual ~derivator() {}

  // For given lemma, return the parent in the derivation graph.
  // The lemma is assumed to be lemma id and any lemma comments are ignored.
  virtual bool parent(string_piece lemma, derivated_lemma& parent) const = 0;

  // For given lemma, return the children in the derivation graph.
  // The lemma is assumed to be lemma id and any lemma comments are ignored.
  virtual bool children(string_piece lemma, vector<derivated_lemma>& children) const = 0;
};

/////////
// File: derivator/derivation_formatter.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2016 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class derivation_formatter {
 public:
  virtual ~derivation_formatter() {}

  // Perform the required derivation and store it directly in the lemma.
  virtual void format_derivation(string& lemma) const = 0;

  // Static factory methods.
  static derivation_formatter* new_none_derivation_formatter();
  static derivation_formatter* new_root_derivation_formatter(const derivator* derinet);
  static derivation_formatter* new_path_derivation_formatter(const derivator* derinet);
  static derivation_formatter* new_tree_derivation_formatter(const derivator* derinet);
  // String version of static factory method.
  static derivation_formatter* new_derivation_formatter(string_piece name, const derivator* derinet);
};

/////////
// File: derivator/derivation_formatter.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2016 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class none_derivation_formatter : public derivation_formatter {
  virtual void format_derivation(string& /*lemma*/) const override {}
};

derivation_formatter* derivation_formatter::new_none_derivation_formatter() {
  return new none_derivation_formatter();
}

class root_derivation_formatter : public derivation_formatter {
 public:
  root_derivation_formatter(const derivator* derinet) : derinet(derinet) {}

  virtual void format_derivation(string& lemma) const override {
    for (derivated_lemma parent; derinet->parent(lemma, parent); )
      lemma.assign(parent.lemma);
  }

 private:
  const derivator* derinet;
};

derivation_formatter* derivation_formatter::new_root_derivation_formatter(const derivator* derinet) {
  return derinet ? new root_derivation_formatter(derinet) : nullptr;
}

class path_derivation_formatter : public derivation_formatter {
 public:
  path_derivation_formatter(const derivator* derinet) : derinet(derinet) {}

  virtual void format_derivation(string& lemma) const override {
    string current(lemma);
    for (derivated_lemma parent; derinet->parent(current, parent); current.swap(parent.lemma))
      lemma.append(" ").append(parent.lemma);
  }

 private:
  const derivator* derinet;
};

derivation_formatter* derivation_formatter::new_path_derivation_formatter(const derivator* derinet) {
  return derinet ? new path_derivation_formatter(derinet) : nullptr;
}

class tree_derivation_formatter : public derivation_formatter {
 public:
  tree_derivation_formatter(const derivator* derinet) : derinet(derinet) {}

  virtual void format_derivation(string& lemma) const override {
    string root(lemma);
    for (derivated_lemma parent; derinet->parent(root, parent); root.swap(parent.lemma)) {}
    format_tree(root, lemma);
  }

  void format_tree(const string& root, string& tree) const {
    vector<derivated_lemma> children;

    tree.append(" ").append(root);
    if (derinet->children(root, children))
      for (auto&& child : children)
        format_tree(child.lemma, tree);
    tree.push_back(' ');
  }

 private:
  const derivator* derinet;
};

derivation_formatter* derivation_formatter::new_tree_derivation_formatter(const derivator* derinet) {
  return derinet ? new tree_derivation_formatter(derinet) : nullptr;
}

derivation_formatter* derivation_formatter::new_derivation_formatter(string_piece name, const derivator* derinet) {
  if (name == "none") return new_none_derivation_formatter();
  if (name == "root") return new_root_derivation_formatter(derinet);
  if (name == "path") return new_path_derivation_formatter(derinet);
  if (name == "tree") return new_tree_derivation_formatter(derinet);
  return nullptr;
}

/////////
// File: tokenizer/tokenizer.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Range of a token, measured in Unicode characters, not UTF8 bytes.
struct token_range {
  size_t start;
  size_t length;

  token_range() {}
  token_range(size_t start, size_t length) : start(start), length(length) {}
};

class tokenizer {
 public:
  virtual ~tokenizer() {}

  virtual void set_text(string_piece text, bool make_copy = false) = 0;
  virtual bool next_sentence(vector<string_piece>* forms, vector<token_range>* tokens) = 0;

  // Static factory methods
  static tokenizer* new_vertical_tokenizer();

  static tokenizer* new_czech_tokenizer();
  static tokenizer* new_english_tokenizer();
  static tokenizer* new_generic_tokenizer();
};

/////////
// File: morpho/morpho.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

struct tagged_form {
  string form;
  string tag;

  tagged_form() {}
  tagged_form(const string& form, const string& tag) : form(form), tag(tag) {}
};

struct tagged_lemma {
  string lemma;
  string tag;

  tagged_lemma() {}
  tagged_lemma(const string& lemma, const string& tag) : lemma(lemma), tag(tag) {}
};

struct tagged_lemma_forms {
  string lemma;
  vector<tagged_form> forms;

  tagged_lemma_forms() {}
  tagged_lemma_forms(const string& lemma) : lemma(lemma) {}
};

class morpho {
 public:
  virtual ~morpho() {}

  static morpho* load(istream& is);
  static morpho* load(const char* fname);

  enum guesser_mode { NO_GUESSER = 0, GUESSER = 1 };

  // Perform morphologic analysis of a form. The form is given by a pointer and
  // length and therefore does not need to be '\0' terminated.  The guesser
  // parameter specifies whether a guesser can be used if the form is not found
  // in the dictionary. Output is assigned to the lemmas vector.
  //
  // If the form is found in the dictionary, analyses are assigned to lemmas
  // and NO_GUESSER returned. If guesser == GUESSER and the form analyses are
  // found using a guesser, they are assigned to lemmas and GUESSER is
  // returned.  Otherwise <0 is returned and lemmas are filled with one
  // analysis containing given form as lemma and a tag for unknown word.
  virtual int analyze(string_piece form, guesser_mode guesser, vector<tagged_lemma>& lemmas) const = 0;

  // Perform morphologic generation of a lemma. The lemma is given by a pointer
  // and length and therefore does not need to be '\0' terminated. Optionally
  // a tag_wildcard can be specified (or be NULL) and if so, results are
  // filtered using this wildcard. The guesser parameter speficies whether
  // a guesser can be used if the lemma is not found in the dictionary. Output
  // is assigned to the forms vector.
  //
  // Tag_wildcard can be either NULL or a wildcard applied to the results.
  // A ? in the wildcard matches any character, [bytes] matches any of the
  // bytes and [^bytes] matches any byte different from the specified ones.
  // A - has no special meaning inside the bytes and if ] is first in bytes, it
  // does not end the bytes group.
  //
  // If the given lemma is only a raw lemma, all lemma ids with this raw lemma
  // are returned. Otherwise only matching lemma ids are returned, ignoring any
  // lemma comments. For every found lemma, matching forms are filtered using
  // the tag_wildcard. If at least one lemma is found in the dictionary,
  // NO_GUESSER is returned. If guesser == GUESSER and the lemma is found by
  // the guesser, GUESSER is returned. Otherwise, forms are cleared and <0 is
  // returned.
  virtual int generate(string_piece lemma, const char* tag_wildcard, guesser_mode guesser, vector<tagged_lemma_forms>& forms) const = 0;

  // Rawlemma and lemma id identification
  virtual int raw_lemma_len(string_piece lemma) const = 0;
  virtual int lemma_id_len(string_piece lemma) const = 0;

  // Rawform identification
  virtual int raw_form_len(string_piece form) const = 0;

  // Construct a new tokenizer instance appropriate for this morphology.
  // Can return NULL if no such tokenizer exists.
  virtual tokenizer* new_tokenizer() const = 0;

  // Return a derivator for this morphology, or NULL if it does not exist.
  // The returned instance is owned by the morphology and should not be deleted.
  virtual const derivator* get_derivator() const;

 protected:
  unique_ptr<derivator> derinet;
};

/////////
// File: morpho/small_stringops.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
inline bool small_memeq(const void* a, const void* b, size_t len);
inline void small_memcpy(void* dest, const void* src, size_t len);

// Definitions
bool small_memeq(const void* a_void, const void* b_void, size_t len) {
  const char* a = (const char*)a_void;
  const char* b = (const char*)b_void;

  while (len--)
    if (*a++ != *b++)
      return false;
  return true;
}

void small_memcpy(void* dest_void, const void* src_void, size_t len) {
  char* dest = (char*)dest_void;
  const char* src = (const char*)src_void;

  while (len--)
    *dest++ = *src++;
}

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

namespace utils {

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

} // namespace utils

/////////
// File: utils/binary_encoder.h
/////////

// This file is part of UFAL C++ Utils <http://github.com/ufal/cpp_utils/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

namespace utils {

//
// Declarations
//

class binary_encoder {
 public:
  inline binary_encoder();

  inline void add_1B(unsigned val);
  inline void add_2B(unsigned val);
  inline void add_4B(unsigned val);
  inline void add_float(double val);
  inline void add_double(double val);
  inline void add_str(string_piece str);
  inline void add_data(string_piece data);
  template <class T> inline void add_data(const vector<T>& data);
  template <class T> inline void add_data(const T* data, size_t elements);

  vector<unsigned char> data;
};

//
// Definitions
//

binary_encoder::binary_encoder() {
  data.reserve(16);
}

void binary_encoder::add_1B(unsigned val) {
  if (uint8_t(val) != val) runtime_failure("Should encode value " << val << " in one byte!");
  data.push_back(val);
}

void binary_encoder::add_2B(unsigned val) {
  if (uint16_t(val) != val) runtime_failure("Should encode value " << val << " in one byte!");
  data.insert(data.end(), (unsigned char*) &val, ((unsigned char*) &val) + sizeof(uint16_t));
}

void binary_encoder::add_4B(unsigned val) {
  if (uint32_t(val) != val) runtime_failure("Should encode value " << val << " in one byte!");
  data.insert(data.end(), (unsigned char*) &val, ((unsigned char*) &val) + sizeof(uint32_t));
}

void binary_encoder::add_float(double val) {
  data.insert(data.end(), (unsigned char*) &val, ((unsigned char*) &val) + sizeof(float));
}

void binary_encoder::add_double(double val) {
  data.insert(data.end(), (unsigned char*) &val, ((unsigned char*) &val) + sizeof(double));
}

void binary_encoder::add_str(string_piece str) {
  add_1B(str.len < 255 ? str.len : 255);
  if (!(str.len < 255)) add_4B(str.len);
  add_data(str);
}

void binary_encoder::add_data(string_piece data) {
  this->data.insert(this->data.end(), (const unsigned char*) data.str, (const unsigned char*) (data.str + data.len));
}

template <class T>
void binary_encoder::add_data(const vector<T>& data) {
  this->data.insert(this->data.end(), (const unsigned char*) data.data(), (const unsigned char*) (data.data() + data.size()));
}

template <class T>
void binary_encoder::add_data(const T* data, size_t elements) {
  this->data.insert(this->data.end(), (const unsigned char*) data, (const unsigned char*) (data + elements));
}

} // namespace utils

/////////
// File: utils/pointer_decoder.h
/////////

// This file is part of UFAL C++ Utils <http://github.com/ufal/cpp_utils/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

namespace utils {

//
// Declarations
//

class pointer_decoder {
 public:
  inline pointer_decoder(const unsigned char*& data);
  inline unsigned next_1B();
  inline unsigned next_2B();
  inline unsigned next_4B();
  inline void next_str(string& str);
  template <class T> inline const T* next(unsigned elements);

 private:
  const unsigned char*& data;
};

//
// Definitions
//

pointer_decoder::pointer_decoder(const unsigned char*& data) : data(data) {}

unsigned pointer_decoder::next_1B() {
  return *data++;
}

unsigned pointer_decoder::next_2B() {
  unsigned result = *(uint16_t*)data;
  data += sizeof(uint16_t);
  return result;
}

unsigned pointer_decoder::next_4B() {
  unsigned result = *(uint32_t*)data;
  data += sizeof(uint32_t);
  return result;
}

void pointer_decoder::next_str(string& str) {
  unsigned len = next_1B();
  if (len == 255) len = next_4B();
  str.assign(next<char>(len), len);
}

template <class T> const T* pointer_decoder::next(unsigned elements) {
  const T* result = (const T*) data;
  data += sizeof(T) * elements;
  return result;
}

} // namespace utils

/////////
// File: morpho/persistent_unordered_map.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
class persistent_unordered_map {
 public:
  // Accessing function
  template <class EntrySize>
  inline const unsigned char* at(const char* str, int len, EntrySize entry_size) const;

  template <class T>
  inline const T* at_typed(const char* str, int len) const;

  template <class EntryProcess>
  inline void iter(const char* str, int len, EntryProcess entry_process) const;

  template <class EntryProcess>
  inline void iter_all(EntryProcess entry_process) const;

  // Two helper functions accessing some internals
  inline int max_length() const;
  inline const unsigned char* data_start(int len) const;

  // Creation functions
  persistent_unordered_map() {}
  template <class Entry, class EntryEncode>
  persistent_unordered_map(const unordered_map<string, Entry>& map, double load_factor, EntryEncode entry_encode);
  template <class Entry, class EntryEncode>
  persistent_unordered_map(const unordered_map<string, Entry>& map, double load_factor, bool add_prefixes, bool add_suffixes, EntryEncode entry_encode);

  // Manual creation functions
  inline void resize(unsigned elems);
  inline void add(const char* str, int str_len, int data_len);
  inline void done_adding();
  inline unsigned char* fill(const char* str, int str_len, int data_len);
  inline void done_filling();

  // Serialization
  inline void load(binary_decoder& data);
  inline void save(binary_encoder& enc);

 private:
  struct fnv_hash;
  vector<fnv_hash> hashes;

  template <class Entry, class EntryEncode>
  void construct(const map<string, Entry>& map, double load_factor, EntryEncode entry_encode);
};

// Definitions
struct persistent_unordered_map::fnv_hash {
  fnv_hash(unsigned num) {
    mask = 1;
    while (mask < num)
      mask <<= 1;
    hash.resize(mask + 1);
    mask--;
  }
  fnv_hash(binary_decoder& data) {
    uint32_t size = data.next_4B();
    mask = size - 2;
    hash.resize(size);
    memcpy(hash.data(), data.next<uint32_t>(size), size * sizeof(uint32_t));

    size = data.next_4B();
    this->data.resize(size);
    memcpy(this->data.data(), data.next<char>(size), size);
  }

  inline uint32_t index(const char* data, int len) const {
    if (len <= 0) return 0;
    if (len == 1) return *(const uint8_t*)data;
    if (len == 2) return *(const uint16_t*)data;

    uint32_t hash = 2166136261U;
    while (len--)
      hash = (hash ^ unsigned(*data++)) * 16777619U;
    return hash & mask;
  }

  inline void save(binary_encoder& enc);

  unsigned mask;
  vector<uint32_t> hash;
  vector<unsigned char> data;
};

template <class EntrySize>
const unsigned char* persistent_unordered_map::at(const char* str, int len, EntrySize entry_size) const {
  if (unsigned(len) >= hashes.size()) return nullptr;

  unsigned index = hashes[len].index(str, len);
  const unsigned char* data = hashes[len].data.data() + hashes[len].hash[index];
  const unsigned char* end = hashes[len].data.data() + hashes[len].hash[index+1];

  if (len <= 2)
    return data != end ? data + len : nullptr;

  while (data < end) {
    if (small_memeq(str, data, len)) return data + len;
    data += len;
    pointer_decoder decoder(data);
    entry_size(decoder);
  }

  return nullptr;
}

template <class T>
const T* persistent_unordered_map::at_typed(const char* str, int len) const {
  if (unsigned(len) >= hashes.size()) return nullptr;

  unsigned index = hashes[len].index(str, len);
  const unsigned char* data = hashes[len].data.data() + hashes[len].hash[index];
  const unsigned char* end = hashes[len].data.data() + hashes[len].hash[index+1];

  if (len <= 2)
    return data != end ? (const T*)(data + len) : nullptr;

  while (data < end) {
    if (small_memeq(str, data, len)) return (const T*)(data + len);
    data += len + sizeof(T);
  }

  return nullptr;
}

template <class EntryProcess>
void persistent_unordered_map::iter(const char* str, int len, EntryProcess entry_process) const {
  if (unsigned(len) >= hashes.size()) return;

  unsigned index = hashes[len].index(str, len);
  const unsigned char* data = hashes[len].data.data() + hashes[len].hash[index];
  const unsigned char* end = hashes[len].data.data() + hashes[len].hash[index+1];

  while (data < end) {
    auto start = (const char*) data;
    data += len;
    pointer_decoder decoder(data);
    entry_process(start, decoder);
  }
}

template <class EntryProcess>
void persistent_unordered_map::iter_all(EntryProcess entry_process) const {
  for (unsigned len = 0; len < hashes.size(); len++) {
    const unsigned char* data = hashes[len].data.data();
    const unsigned char* end = data + hashes[len].data.size();

    while (data < end) {
      auto start = (const char*) data;
      data += len;
      pointer_decoder decoder(data);
      entry_process(start, len, decoder);
    }
  }
}

int persistent_unordered_map::max_length() const {
  return hashes.size();
}

const unsigned char* persistent_unordered_map::data_start(int len) const {
  return unsigned(len) < hashes.size() ? hashes[len].data.data() : nullptr;
}

void persistent_unordered_map::resize(unsigned elems) {
  if (hashes.size() == 0) hashes.emplace_back(1);
  else if (hashes.size() == 1) hashes.emplace_back(1<<8);
  else if (hashes.size() == 2) hashes.emplace_back(1<<16);
  else hashes.emplace_back(elems);
}

void persistent_unordered_map::add(const char* str, int str_len, int data_len) {
  if (unsigned(str_len) < hashes.size())
    hashes[str_len].hash[hashes[str_len].index(str, str_len)] += str_len + data_len;
}

void persistent_unordered_map::done_adding() {
  for (auto&& hash : hashes) {
    int total = 0;
    for (auto&& len : hash.hash) total += len, len = total - len;
    hash.data.resize(total);
  }
}

unsigned char* persistent_unordered_map::fill(const char* str, int str_len, int data_len) {
  if (unsigned(str_len) < hashes.size()) {
    unsigned index = hashes[str_len].index(str, str_len);
    unsigned offset = hashes[str_len].hash[index];
    small_memcpy(hashes[str_len].data.data() + offset, str, str_len);
    hashes[str_len].hash[index] += str_len + data_len;
    return hashes[str_len].data.data() + offset + str_len;
  }
  return nullptr;
}

void persistent_unordered_map::done_filling() {
  for (auto&& hash : hashes)
    for (int i = hash.hash.size() - 1; i >= 0; i--)
      hash.hash[i] = i > 0 ? hash.hash[i-1] : 0;
}

void persistent_unordered_map::load(binary_decoder& data) {
  unsigned sizes = data.next_1B();

  hashes.clear();
  for (unsigned i = 0; i < sizes; i++)
    hashes.emplace_back(data);
}

/////////
// File: derivator/derivator_dictionary.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2016 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class derivator_dictionary : public derivator {
 public:
  virtual bool parent(string_piece lemma, derivated_lemma& parent) const override;
  virtual bool children(string_piece lemma, vector<derivated_lemma>& children) const override;

  bool load(istream& is);

 private:
  friend class morpho;
  const morpho* dictionary;
  persistent_unordered_map derinet;
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

namespace utils {

class binary_decoder;
class binary_encoder;

class compressor {
 public:
  static bool load(istream& is, binary_decoder& data);
  static bool save(ostream& os, const binary_encoder& enc);
};

} // namespace utils

/////////
// File: derivator/derivator_dictionary.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2016 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

bool derivator_dictionary::parent(string_piece lemma, derivated_lemma& parent) const {
  if (dictionary) lemma.len = dictionary->lemma_id_len(lemma);

  auto lemma_data = derinet.at(lemma.str, lemma.len, [](pointer_decoder& data) {
    data.next<char>(data.next_1B());
    data.next_4B();
    data.next<uint32_t>(data.next_2B());
  });
  if (lemma_data) {
    auto parent_encoded = *(uint32_t*)(lemma_data + 1 + *lemma_data);
    if (parent_encoded) {
      unsigned parent_len = parent_encoded & 0xFF;
      auto parent_data = derinet.data_start(parent_len) + (parent_encoded >> 8);
      parent.lemma.assign((const char*) parent_data, parent_len);
      if (parent_data[parent_len])
        parent.lemma.append((const char*) parent_data + parent_len + 1, parent_data[parent_len]);
      return true;
    }
  }
  parent.lemma.clear();
  return false;
}

bool derivator_dictionary::children(string_piece lemma, vector<derivated_lemma>& children) const {
  if (dictionary) lemma.len = dictionary->lemma_id_len(lemma);

  auto lemma_data = derinet.at(lemma.str, lemma.len, [](pointer_decoder& data) {
    data.next<char>(data.next_1B());
    data.next_4B();
    data.next<uint32_t>(data.next_2B());
  });
  if (lemma_data) {
    auto children_len = *(uint16_t*)(lemma_data + 1 + *lemma_data + 4);
    auto children_encoded = (uint32_t*)(lemma_data + 1 + *lemma_data + 4 + 2);
    if (children_len) {
      children.resize(children_len);
      for (unsigned i = 0; i < children_len; i++) {
        unsigned child_len = children_encoded[i] & 0xFF;
        auto child_data = derinet.data_start(child_len) + (children_encoded[i] >> 8);
        children[i].lemma.assign((const char*) child_data, child_len);
        if (child_data[child_len])
          children[i].lemma.append((const char*) child_data + child_len + 1, child_data[child_len]);
      }
      return true;
    }
  }
  children.clear();
  return false;
}

bool derivator_dictionary::load(istream& is) {
  binary_decoder data;
  if (!compressor::load(is, data)) return false;

  try {
    for (int i = data.next_1B(); i > 0; i--)
      derinet.resize(data.next_4B());

    unsigned data_position = data.tell();
    vector<char> lemma, parent;
    for (int pass = 1; pass <= 3; pass++) {
      if (pass > 1) data.seek(data_position);

      lemma.clear();
      for (int i = data.next_4B(); i > 0; i--) {
        lemma.resize(lemma.size() - data.next_1B());
        for (int i = data.next_1B(); i > 0; i--)
          lemma.push_back(data.next_1B());

        unsigned char lemma_comment_len = data.next_1B();
        const char* lemma_comment = lemma_comment_len ? data.next<char>(lemma_comment_len) : nullptr;

        unsigned children = data.next_2B();

        if (pass == 3) parent.clear();
        enum { REMOVE_START = 1, REMOVE_END = 2, ADD_START = 4, ADD_END = 8 };
        int operations = data.next_1B();
        if (operations) {
          int remove_start = operations & REMOVE_START ? data.next_1B() : 0;
          int remove_end = operations & REMOVE_END ? data.next_1B() : 0;
          if (operations & ADD_START) {
            int add_start = data.next_1B();
            const char* str = data.next<char>(add_start);
            if (pass == 3) parent.assign(str, str + add_start);
          }
          if (pass == 3) parent.insert(parent.end(), lemma.begin() + remove_start, lemma.end() - remove_end);
          if (operations & ADD_END) {
            int add_end = data.next_1B();
            const char* str = data.next<char>(add_end);
            if (pass == 3) parent.insert(parent.end(), str, str + add_end);
          }
        }

        if (pass == 1) {
          derinet.add(lemma.data(), lemma.size(), 1 + lemma_comment_len + 4 + 2 + 4 * children);
        } else if (pass == 2) {
          unsigned char* lemma_data = derinet.fill(lemma.data(), lemma.size(), 1 + lemma_comment_len + 4 + 2 + 4 * children);
          *lemma_data++ = lemma_comment_len;
          while (lemma_comment_len--) *lemma_data++ = *lemma_comment++;
          *(uint32_t*)(lemma_data) = 0; lemma_data += sizeof(uint32_t);
          *(uint16_t*)(lemma_data) = children; lemma_data += sizeof(uint16_t);
          if (children) ((uint32_t*)lemma_data)[children - 1] = 0;
        } else if (pass == 3 && !parent.empty()) {
          auto lemma_data = derinet.at(lemma.data(), lemma.size(), [](pointer_decoder& data) {
            data.next<char>(data.next_1B());
            data.next_4B();
            data.next<uint32_t>(data.next_2B());
          });
          auto parent_data = derinet.at(parent.data(), parent.size(), [](pointer_decoder& data) {
            data.next<char>(data.next_1B());
            data.next_4B();
            data.next<uint32_t>(data.next_2B());
          });
          assert(lemma_data && parent_data);

          unsigned parent_offset = parent_data - parent.size() - derinet.data_start(parent.size());
          assert(parent.size() < (1<<8) && parent_offset < (1<<24));
          *(uint32_t*)(lemma_data + 1 + *lemma_data) = (parent_offset << 8) | parent.size();

          unsigned lemma_offset = lemma_data - lemma.size() - derinet.data_start(lemma.size());
          assert(lemma.size() < (1<<8) && lemma_offset < (1<<24));
          auto children_len = *(uint16_t*)(parent_data + 1 + *parent_data + 4);
          auto children = (uint32_t*)(parent_data + 1 + *parent_data + 4 + 2);
          auto child_index = children[children_len-1];
          children[child_index] = (lemma_offset << 8) | lemma.size();
          if (child_index+1 < children_len) children[children_len-1]++;
        }
      }

      if (pass == 1)
        derinet.done_adding();
      if (pass == 2)
        derinet.done_filling();
    }
  } catch (binary_decoder_error&) {
    return false;
  }
  return true;
}

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
// UniLib version: 3.1.1
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
// UniLib version: 3.1.1
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
  if (((unsigned char)*str) < 0x80) return (unsigned char)*str++;
  else if (((unsigned char)*str) < 0xC0) return ++str, REPLACEMENT_CHAR;
  else if (((unsigned char)*str) < 0xE0) {
    char32_t res = (((unsigned char)*str++) & 0x1F) << 6;
    if (((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return REPLACEMENT_CHAR;
    return res + (((unsigned char)*str++) & 0x3F);
  } else if (((unsigned char)*str) < 0xF0) {
    char32_t res = (((unsigned char)*str++) & 0x0F) << 12;
    if (((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return REPLACEMENT_CHAR;
    res += (((unsigned char)*str++) & 0x3F) << 6;
    if (((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return REPLACEMENT_CHAR;
    return res + (((unsigned char)*str++) & 0x3F);
  } else if (((unsigned char)*str) < 0xF8) {
    char32_t res = (((unsigned char)*str++) & 0x07) << 18;
    if (((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return REPLACEMENT_CHAR;
    res += (((unsigned char)*str++) & 0x3F) << 12;
    if (((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return REPLACEMENT_CHAR;
    res += (((unsigned char)*str++) & 0x3F) << 6;
    if (((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return REPLACEMENT_CHAR;
    return res + (((unsigned char)*str++) & 0x3F);
  } else return ++str, REPLACEMENT_CHAR;
}

char32_t utf8::decode(const char*& str, size_t& len) {
  if (!len) return 0;
  --len;
  if (((unsigned char)*str) < 0x80) return (unsigned char)*str++;
  else if (((unsigned char)*str) < 0xC0) return ++str, REPLACEMENT_CHAR;
  else if (((unsigned char)*str) < 0xE0) {
    char32_t res = (((unsigned char)*str++) & 0x1F) << 6;
    if (len <= 0 || ((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return REPLACEMENT_CHAR;
    return res + ((--len, ((unsigned char)*str++)) & 0x3F);
  } else if (((unsigned char)*str) < 0xF0) {
    char32_t res = (((unsigned char)*str++) & 0x0F) << 12;
    if (len <= 0 || ((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return REPLACEMENT_CHAR;
    res += ((--len, ((unsigned char)*str++)) & 0x3F) << 6;
    if (len <= 0 || ((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return REPLACEMENT_CHAR;
    return res + ((--len, ((unsigned char)*str++)) & 0x3F);
  } else if (((unsigned char)*str) < 0xF8) {
    char32_t res = (((unsigned char)*str++) & 0x07) << 18;
    if (len <= 0 || ((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return REPLACEMENT_CHAR;
    res += ((--len, ((unsigned char)*str++)) & 0x3F) << 12;
    if (len <= 0 || ((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return REPLACEMENT_CHAR;
    res += ((--len, ((unsigned char)*str++)) & 0x3F) << 6;
    if (len <= 0 || ((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return REPLACEMENT_CHAR;
    return res + ((--len, ((unsigned char)*str++)) & 0x3F);
  } else return ++str, REPLACEMENT_CHAR;
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
// File: morpho/casing_variants.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

inline void generate_casing_variants(string_piece form, string& form_uclc, string& form_lc) {
  using namespace unilib;

  // Detect uppercase+titlecase characters.
  bool first_Lut = false; // first character is uppercase or titlecase
  bool rest_has_Lut = false; // any character but first is uppercase or titlecase
  {
    string_piece form_tmp = form;
    first_Lut = unicode::category(utf8::decode(form_tmp.str, form_tmp.len)) & unicode::Lut;
    while (form_tmp.len && !rest_has_Lut)
      rest_has_Lut = unicode::category(utf8::decode(form_tmp.str, form_tmp.len)) & unicode::Lut;
  }

  // Generate all casing variants if needed (they are different than given form).
  // We only replace letters with their lowercase variants.
  // - form_uclc: first uppercase, rest lowercase
  // - form_lc: all lowercase

  if (first_Lut && !rest_has_Lut) { // common case allowing fast execution
    form_lc.reserve(form.len);
    string_piece form_tmp = form;
    utf8::append(form_lc, unicode::lowercase(utf8::decode(form_tmp.str, form_tmp.len)));
    form_lc.append(form_tmp.str, form_tmp.len);
  } else if (!first_Lut && rest_has_Lut) {
    form_lc.reserve(form.len);
    utf8::map(unicode::lowercase, form.str, form.len, form_lc);
  } else if (first_Lut && rest_has_Lut) {
    form_lc.reserve(form.len);
    form_uclc.reserve(form.len);
    string_piece form_tmp = form;
    char32_t first = utf8::decode(form_tmp.str, form_tmp.len);
    utf8::append(form_lc, unicode::lowercase(first));
    utf8::append(form_uclc, first);
    while (form_tmp.len) {
      char32_t lowercase = unicode::lowercase(utf8::decode(form_tmp.str, form_tmp.len));
      utf8::append(form_lc, lowercase);
      utf8::append(form_uclc, lowercase);
    }
  }
}

/////////
// File: morpho/czech_lemma_addinfo.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
struct czech_lemma_addinfo {
  inline static int raw_lemma_len(string_piece lemma);
  inline static int lemma_id_len(string_piece lemma);
  inline static string format(const unsigned char* addinfo, int addinfo_len);
  inline static bool generatable(const unsigned char* addinfo, int addinfo_len);

  inline int parse(string_piece lemma, bool die_on_failure = false);
  inline bool match_lemma_id(const unsigned char* other_addinfo, int other_addinfo_len);

  vector<unsigned char> data;
};

// Definitions
int czech_lemma_addinfo::raw_lemma_len(string_piece lemma) {
  // Lemma ends by a '-[0-9]', '`' or '_' on non-first position.
  for (unsigned len = 1; len < lemma.len; len++)
    if (lemma.str[len] == '`' || lemma.str[len] == '_' ||
        (lemma.str[len] == '-' && len+1 < lemma.len && lemma.str[len+1] >= '0' && lemma.str[len+1] <= '9'))
      return len;
  return lemma.len;
}

int czech_lemma_addinfo::lemma_id_len(string_piece lemma) {
  // Lemma ends by a '-[0-9]', '`' or '_' on non-first position.
  for (unsigned len = 1; len < lemma.len; len++) {
    if (lemma.str[len] == '`' || lemma.str[len] == '_')
      return len;
    if (lemma.str[len] == '-' && len+1 < lemma.len && lemma.str[len+1] >= '0' && lemma.str[len+1] <= '9') {
      len += 2;
      while (len < lemma.len && lemma.str[len] >= '0' && lemma.str[len] <= '9') len++;
      return len;
    }
  }
  return lemma.len;
}

string czech_lemma_addinfo::format(const unsigned char* addinfo, int addinfo_len) {
  string res;

  if (addinfo_len) {
    res.reserve(addinfo_len + 4);
    if (addinfo[0] != 255) {
      char num[5];
      sprintf(num, "-%u", addinfo[0]);
      res += num;
    }
    for (int i = 1; i < addinfo_len; i++)
      res += addinfo[i];
  }

  return res;
}

bool czech_lemma_addinfo::generatable(const unsigned char* addinfo, int addinfo_len) {
  for (int i = 1; i + 2 < addinfo_len; i++)
    if (addinfo[i] == '_' && addinfo[i+1] == ',' && addinfo[i+2] == 'x')
      return false;

  return true;
}

int czech_lemma_addinfo::parse(string_piece lemma, bool die_on_failure) {
  data.clear();

  const char* lemma_info = lemma.str + raw_lemma_len(lemma);
  if (lemma_info < lemma.str + lemma.len) {
    int lemma_num = 255;
    const char* lemma_additional_info = lemma_info;

    if (*lemma_info == '-') {
      lemma_num = strtol(lemma_info + 1, (char**) &lemma_additional_info, 10);

      if (lemma_additional_info == lemma_info + 1 || (*lemma_additional_info != '\0' && *lemma_additional_info != '`' && *lemma_additional_info != '_') || lemma_num < 0 || lemma_num >= 255) {
        if (die_on_failure)
          runtime_failure("Lemma number " << lemma_num << " in lemma " << lemma << " out of range!");
        else
          lemma_num = 255;
      }
    }
    data.emplace_back(lemma_num);
    while (lemma_additional_info < lemma.str + lemma.len)
      data.push_back(*(unsigned char*)lemma_additional_info++);

    if (data.size() > 255) {
      if (die_on_failure)
        runtime_failure("Too long lemma info " << lemma_info << " in lemma " << lemma << '!');
      else
        data.resize(255);
    }
  }

  return lemma_info - lemma.str;
}

bool czech_lemma_addinfo::match_lemma_id(const unsigned char* other_addinfo, int other_addinfo_len) {
  if (data.empty()) return true;
  if (data[0] != 255 && (!other_addinfo_len || other_addinfo[0] != data[0])) return false;
  return true;
}

/////////
// File: morpho/tag_filter.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
class tag_filter {
 public:
  tag_filter(const char* filter = nullptr);

  inline bool matches(const char* tag) const;

 private:
  struct char_filter {
    char_filter(int pos, bool negate, const char* chars, int len) : pos(pos), negate(negate), chars(chars), len(len) {}

    int pos;
    bool negate;
    const char* chars;
    int len;
  };

  string wildcard;
  std::vector<char_filter> filters;
};

// Definitions
inline bool tag_filter::matches(const char* tag) const {
  if (filters.empty()) return true;

  int tag_pos = 0;
  for (auto&& filter : filters) {
    while (tag_pos < filter.pos)
      if (!tag[tag_pos++])
        return true;

    // We assume filter.len >= 1.
    bool matched = (*filter.chars == tag[tag_pos]) ^ filter.negate;
    for (int i = 1; i < filter.len && !matched; i++)
      matched = (filter.chars[i] == tag[tag_pos]) ^ filter.negate;
    if (!matched) return false;
  }
  return true;
}

/////////
// File: morpho/morpho_dictionary.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
template <class LemmaAddinfo>
class morpho_dictionary {
 public:
  void load(binary_decoder& data);
  void analyze(string_piece form, vector<tagged_lemma>& lemmas) const;
  bool generate(string_piece lemma, const tag_filter& filter, vector<tagged_lemma_forms>& lemmas_forms) const;
 private:
  persistent_unordered_map lemmas, roots, suffixes;

  vector<string> tags;
  vector<vector<pair<string, vector<uint16_t>>>> classes;
};

// Definitions
template <class LemmaAddinfo>
void morpho_dictionary<LemmaAddinfo>::load(binary_decoder& data) {
  // Prepare lemmas and roots hashes
  for (int i = data.next_1B(); i > 0; i--)
    lemmas.resize(data.next_4B());
  for (int i = data.next_1B(); i > 0; i--)
    roots.resize(data.next_4B());

  // Perform two pass over the lemmas and roots data, filling the hashes.

  vector<char> lemma(max(lemmas.max_length(), roots.max_length()));
  vector<char> root(max(lemmas.max_length(), roots.max_length()));
  unsigned data_position = data.tell();
  for (int pass = 1; pass <= 2; pass++) {
    if (pass > 1) data.seek(data_position);

    int lemma_len = 0;
    int root_len = 0;

    for (int i = data.next_4B(); i > 0; i--) {
      lemma_len -= data.next_1B();
      for (int i = data.next_1B(); i > 0; i--)
        lemma[lemma_len++] = data.next_1B();
      unsigned char lemma_info_len = data.next_1B();
      const char* lemma_info = lemma_info_len ? data.next<char>(lemma_info_len) : nullptr;
      unsigned lemma_roots = data.next_1B();

      unsigned char* lemma_data /* to keep compiler happy */ = nullptr;
      unsigned lemma_offset /* to keep compiler happy */ = 0;

      if (pass == 1) {
        lemmas.add(lemma.data(), lemma_len, 1 + lemma_info_len + 1 + lemma_roots * (sizeof(uint32_t) + sizeof(uint8_t) + sizeof(uint16_t)));
      } else /*if (pass == 2)*/ {
        lemma_data = lemmas.fill(lemma.data(), lemma_len, 1 + lemma_info_len + 1 + lemma_roots * (sizeof(uint32_t) + sizeof(uint8_t) + sizeof(uint16_t)));
        lemma_offset = lemma_data - lemma_len - lemmas.data_start(lemma_len);

        *lemma_data++ = lemma_info_len;
        if (lemma_info_len) small_memcpy(lemma_data, lemma_info, lemma_info_len), lemma_data += lemma_info_len;
        *lemma_data++ = lemma_roots;
      }

      small_memcpy(root.data(), lemma.data(), lemma_len); root_len = lemma_len;
      for (unsigned i = 0; i < lemma_roots; i++) {
        enum { REMOVE_START = 1, REMOVE_END = 2, ADD_START = 4, ADD_END = 8 };
        int operations = data.next_1B();
        if (operations & REMOVE_START) { int from = data.next_1B(), to = 0; while (from < root_len) root[to++] = root[from++]; root_len = to; }
        if (operations & REMOVE_END) root_len -= data.next_1B();
        if (operations & ADD_START) {
          int from = root_len, to = from + data.next_1B(); while (from > 0) root[--to] = root[--from]; root_len += to;
          for (int i = 0; i < to; i++) root[i] = data.next_1B();
        }
        if (operations & ADD_END)
          for (int len = data.next_1B(); len > 0; len--)
            root[root_len++] = data.next_1B();
        uint16_t clas = data.next_2B();

        if (pass == 1) { // for each root
          roots.add(root.data(), root_len, sizeof(uint16_t) + sizeof(uint32_t) + sizeof(uint8_t));
        } else /*if (pass == 2)*/ {
          unsigned char* root_data = roots.fill(root.data(), root_len, sizeof(uint16_t) + sizeof(uint32_t) + sizeof(uint8_t));
          unsigned root_offset = root_data - root_len - roots.data_start(root_len);

          *(uint16_t*)(root_data) = clas; root_data += sizeof(uint16_t);
          *(uint32_t*)(root_data) = lemma_offset; root_data += sizeof(uint32_t);
          *(uint8_t*)(root_data) = lemma_len; root_data += sizeof(uint8_t);
          assert(uint8_t(lemma_len) == lemma_len);

          *(uint32_t*)(lemma_data) = root_offset; lemma_data += sizeof(uint32_t);
          *(uint8_t*)(lemma_data) = root_len; lemma_data += sizeof(uint8_t);
          *(uint16_t*)(lemma_data) = clas; lemma_data += sizeof(uint16_t);
          assert(uint8_t(root_len) == root_len);
        }
      }
    }

    if (pass == 1) { // after the whole pass
      lemmas.done_adding();
      roots.done_adding();
    } else /*if (pass == 2)*/ {
      lemmas.done_filling();
      roots.done_filling();
    }
  }

  // Load tags
  tags.resize(data.next_2B());
  for (auto&& tag : tags) {
    tag.resize(data.next_1B());
    for (unsigned i = 0; i < tag.size(); i++)
      tag[i] = data.next_1B();
  }

  // Load suffixes
  suffixes.load(data);

  // Fill classes from suffixes
  suffixes.iter_all([this](const char* suffix, int len, pointer_decoder& data) mutable {
    unsigned classes_len = data.next_2B();
    const uint16_t* classes_ptr = data.next<uint16_t>(classes_len);
    const uint16_t* indices_ptr = data.next<uint16_t>(classes_len);
    const uint16_t* tags_ptr = data.next<uint16_t>(data.next_2B());

    string suffix_str(suffix, len);
    for (unsigned i = 0; i < classes_len; i++) {
      if (classes_ptr[i] >= classes.size()) classes.resize(classes_ptr[i] + 1);
      classes[classes_ptr[i]].emplace_back(suffix_str, vector<uint16_t>(tags_ptr + indices_ptr[i], tags_ptr + indices_ptr[i+1]));
    }
  });
}

template <class LemmaAddinfo>
void morpho_dictionary<LemmaAddinfo>::analyze(string_piece form, vector<tagged_lemma>& lemmas) const {
  int max_suffix_len = suffixes.max_length();

  uint16_t* suff_stack[16]; vector<uint16_t*> suff_heap;
  uint16_t** suff = max_suffix_len <= 16 ? suff_stack : (suff_heap.resize(max_suffix_len), suff_heap.data());
  int suff_len = 0;
  for (int i = form.len; i >= 0 && suff_len < max_suffix_len; i--, suff_len++) {
    suff[suff_len] = (uint16_t*) suffixes.at(form.str + i, suff_len, [](pointer_decoder& data) {
      data.next<uint16_t>(2 * data.next_2B());
      data.next<uint16_t>(data.next_2B());
    });
    if (!suff[suff_len]) break;
  }

  for (int root_len = int(form.len) - --suff_len; suff_len >= 0 && root_len < int(roots.max_length()); suff_len--, root_len++)
    if (*suff[suff_len]) {
      unsigned suff_classes = *suff[suff_len];
      uint16_t* suff_data = suff[suff_len] + 1;

      roots.iter(form.str, root_len, [&](const char* root, pointer_decoder& root_data) {
        unsigned root_class = root_data.next_2B();
        unsigned lemma_offset = root_data.next_4B();
        unsigned lemma_len = root_data.next_1B();

        if (small_memeq(form.str, root, root_len)) {
          uint16_t* suffix_class_ptr = lower_bound(suff_data, suff_data + suff_classes, root_class);
          if (suffix_class_ptr < suff_data + suff_classes && *suffix_class_ptr == root_class) {
            const unsigned char* lemma_data = this->lemmas.data_start(lemma_len) + lemma_offset;
            string lemma((const char*)lemma_data, lemma_len);
            if (lemma_data[lemma_len]) lemma += LemmaAddinfo::format(lemma_data + lemma_len + 1, lemma_data[lemma_len]);

            uint16_t* suff_tag_indices = suff_data + suff_classes;
            uint16_t* suff_tags = suff_tag_indices + suff_classes + 1;
            for (unsigned i = suff_tag_indices[suffix_class_ptr - suff_data]; i < suff_tag_indices[suffix_class_ptr - suff_data + 1]; i++)
              lemmas.emplace_back(lemma, tags[suff_tags[i]]);
          }
        }
      });
    }
}

template <class LemmaAddinfo>
bool morpho_dictionary<LemmaAddinfo>::generate(string_piece lemma, const tag_filter& filter, vector<tagged_lemma_forms>& lemmas_forms) const {
  LemmaAddinfo addinfo;
  int raw_lemma_len = addinfo.parse(lemma);
  bool matched_lemma = false;

  lemmas.iter(lemma.str, raw_lemma_len, [&](const char* lemma_str, pointer_decoder& data) {
    unsigned lemma_info_len = data.next_1B();
    const auto* lemma_info = data.next<unsigned char>(lemma_info_len);
    unsigned lemma_roots_len = data.next_1B();
    auto* lemma_roots_ptr = data.next<unsigned char>(lemma_roots_len * (sizeof(uint32_t) + sizeof(uint8_t) + sizeof(uint16_t)));

    if (small_memeq(lemma.str, lemma_str, raw_lemma_len) && addinfo.match_lemma_id(lemma_info, lemma_info_len) && LemmaAddinfo::generatable(lemma_info, lemma_info_len)) {
      matched_lemma = true;

      vector<tagged_form>* forms = nullptr;
      pointer_decoder lemma_roots(lemma_roots_ptr);
      for (unsigned i = 0; i < lemma_roots_len; i++) {
        unsigned root_offset = lemma_roots.next_4B();
        unsigned root_len = lemma_roots.next_1B();
        unsigned clas = lemma_roots.next_2B();

        const unsigned char* root_data = roots.data_start(root_len) + root_offset;
        for (auto&& suffix : classes[clas]) {
          string root_with_suffix;
          for (auto&& tag : suffix.second)
            if (filter.matches(tags[tag].c_str())) {
              if (!forms) {
                lemmas_forms.emplace_back(string(lemma.str, raw_lemma_len) + LemmaAddinfo::format(lemma_info, lemma_info_len));
                forms = &lemmas_forms.back().forms;
              }

              if (root_with_suffix.empty() && root_len + suffix.first.size()) {
                root_with_suffix.reserve(root_len + suffix.first.size());
                root_with_suffix.assign((const char*)root_data, root_len);
                root_with_suffix.append(suffix.first);
              }

              forms->emplace_back(root_with_suffix, tags[tag]);
            }
        }
      }
    }
  });

  return matched_lemma;
}

/////////
// File: morpho/morpho_prefix_guesser.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
template <class MorphoDictionary>
class morpho_prefix_guesser {
 public:
  morpho_prefix_guesser(const MorphoDictionary& dictionary) : dictionary(dictionary) {}

  void load(binary_decoder& data);
  void analyze(string_piece form, vector<tagged_lemma>& lemmas);
  bool generate(string_piece lemma, const tag_filter& filter, vector<tagged_lemma_forms>& lemmas_forms);

 private:
  const MorphoDictionary& dictionary;
  vector<tag_filter> tag_filters;
  persistent_unordered_map prefixes_initial, prefixes_middle;
};

// Definitions
template <class MorphoDictionary>
void morpho_prefix_guesser<MorphoDictionary>::load(binary_decoder& data) {
  // Load and construct tag filters
  for (unsigned tag_filters_len = data.next_1B(); tag_filters_len; tag_filters_len--) {
    unsigned tag_filter_len = data.next_1B();
    string tag_filter(data.next<char>(tag_filter_len), tag_filter_len);

    tag_filters.emplace_back(tag_filter.c_str());
  }

  // Load prefixes
  prefixes_initial.load(data);
  prefixes_middle.load(data);
}

// Analyze can return non-unique lemma-tag pairs.
template <class MorphoDictionary>
void morpho_prefix_guesser<MorphoDictionary>::analyze(string_piece form, vector<tagged_lemma>& lemmas) {
  if (!form.len) return;

  vector<char> form_tmp;
  vector<unsigned> middle_masks;
  middle_masks.reserve(form.len);

  for (unsigned initial = 0; initial < form.len; initial++) {
    // Match the initial prefix.
    unsigned initial_mask = (1<<tag_filters.size()) - 1; // full mask for empty initial prefix
    if (initial) {
      auto found = prefixes_initial.at_typed<uint32_t>(form.str, initial);
      if (!found) break;
      initial_mask = *found;
    }

    // If we have found an initial prefix (including the empty one), match middle prefixes.
    if (initial_mask) {
      middle_masks.resize(initial);
      middle_masks.emplace_back(initial_mask);
      for (unsigned middle = initial; middle < middle_masks.size(); middle++) {
        if (!middle_masks[middle]) continue;
        // Try matching middle prefixes from current index.
        for (unsigned i = middle + 1; i < form.len; i++) {
          auto found = prefixes_middle.at_typed<uint32_t>(form.str + middle, i - middle);
          if (!found) break;
          if (*found) {
            if (i + 1 > middle_masks.size()) middle_masks.resize(i + 1);
            middle_masks[i] |= middle_masks[middle] & *found;
          }
        }

        // Try matching word forms if at least one middle prefix was found.
        if (middle > initial && middle < form.len ) {
          if (initial) {
            if (form_tmp.empty()) form_tmp.assign(form.str, form.str + form.len);
            small_memcpy(form_tmp.data() + middle - initial, form.str, initial);
          }
          unsigned lemmas_ori_size = lemmas.size();
          dictionary.analyze(string_piece((initial ? form_tmp.data() : form.str) + middle - initial, form.len - middle + initial), lemmas);
          unsigned lemmas_new_size = lemmas_ori_size;
          for (unsigned i = lemmas_ori_size; i < lemmas.size(); i++) {
            for (unsigned filter = 0; filter < tag_filters.size(); filter++)
              if ((middle_masks[middle] & (1<<filter)) && tag_filters[filter].matches(lemmas[i].tag.c_str())) {
                if (i == lemmas_new_size) {
                  lemmas[lemmas_new_size].lemma.insert(0, form.str + initial, middle - initial);
                } else {
                  lemmas[lemmas_new_size].lemma.reserve(lemmas[i].lemma.size() + middle - initial);
                  lemmas[lemmas_new_size].lemma.assign(form.str + initial, middle - initial);
                  lemmas[lemmas_new_size].lemma.append(lemmas[i].lemma);
                  lemmas[lemmas_new_size].tag = lemmas[i].tag;
                }
                lemmas_new_size++;
                break;
              }
          }
          if (lemmas_new_size < lemmas.size()) lemmas.erase(lemmas.begin() + lemmas_new_size, lemmas.end());
        }
      }
    }
  }
}

template <class MorphoDictionary>
bool morpho_prefix_guesser<MorphoDictionary>::generate(string_piece /*lemma*/, const tag_filter& /*filter*/, vector<tagged_lemma_forms>& /*lemmas_forms*/) {
  // Not implemented yet. Is it actually needed?
  return false;
}

/////////
// File: morpho/morpho_statistical_guesser.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class morpho_statistical_guesser {
 public:
  void load(binary_decoder& data);
  typedef vector<string> used_rules;
  void analyze(string_piece form, vector<tagged_lemma>& lemmas, used_rules* used);

 private:
  vector<string> tags;
  unsigned default_tag;
  persistent_unordered_map rules;
};

/////////
// File: tokenizer/unicode_tokenizer.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class unicode_tokenizer : public tokenizer {
 public:
  enum { URL_EMAIL_LATEST = 2 };
  unicode_tokenizer(unsigned url_email_tokenizer);

  virtual void set_text(string_piece text, bool make_copy = false) override;
  virtual bool next_sentence(vector<string_piece>* forms, vector<token_range>* tokens) override;

  virtual bool next_sentence(vector<token_range>& tokens) = 0;

 protected:
  struct char_info {
    char32_t chr;
    unilib::unicode::category_t cat;
    const char* str;

    char_info(char32_t chr, const char* str) : chr(chr), cat(unilib::unicode::category(chr)), str(str) {}
  };
  vector<char_info> chars;
  size_t current;

  bool tokenize_url_email(vector<token_range>& tokens);
  bool emergency_sentence_split(const vector<token_range>& tokens);
  bool is_eos(const vector<token_range>& tokens, char32_t eos_chr, const unordered_set<string>* abbreviations);

 private:
  unsigned url_email_tokenizer;
  string text_buffer;
  vector<token_range> tokens_buffer;
  string eos_buffer;
};

/////////
// File: tokenizer/ragel_tokenizer.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class ragel_tokenizer : public unicode_tokenizer {
 public:
  ragel_tokenizer(unsigned url_email_tokenizer);

 protected:
  static inline uint8_t ragel_char(const char_info& chr);

 private:
  static void initialize_ragel_map();
  static vector<uint8_t> ragel_map;
  static atomic_flag ragel_map_flag;
  static void ragel_map_add(char32_t chr, uint8_t mapping);

  friend class unicode_tokenizer;
  static bool ragel_url_email(unsigned version, const vector<char_info>& chars, size_t& current_char, vector<token_range>& tokens);
};

uint8_t ragel_tokenizer::ragel_char(const char_info& chr) {
  return chr.chr < ragel_map.size() && ragel_map[chr.chr] != 128 ? ragel_map[chr.chr] : 128 + (uint32_t(chr.cat) * uint32_t(0x077CB531U) >> 27);
}

/////////
// File: tokenizer/czech_tokenizer.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class czech_tokenizer : public ragel_tokenizer {
 public:
  enum tokenizer_language { CZECH = 0, SLOVAK = 1 };
  enum { LATEST = 2 };
  czech_tokenizer(tokenizer_language language, unsigned version, const morpho* m = nullptr);

  virtual bool next_sentence(vector<token_range>& tokens) override;

 private:
  const morpho* m;
  const unordered_set<string>* abbreviations;
  vector<tagged_lemma> lemmas;

  void merge_hyphenated(vector<token_range>& tokens);

  static const unordered_set<string> abbreviations_czech;
  static const unordered_set<string> abbreviations_slovak;
};

/////////
// File: morpho/czech_morpho.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class czech_morpho : public morpho {
 public:
  using morpho_language = czech_tokenizer::tokenizer_language;

  czech_morpho(morpho_language language, unsigned version) : language(language), version(version) {}

  virtual int analyze(string_piece form, morpho::guesser_mode guesser, vector<tagged_lemma>& lemmas) const override;
  virtual int generate(string_piece lemma, const char* tag_wildcard, guesser_mode guesser, vector<tagged_lemma_forms>& forms) const override;
  virtual int raw_lemma_len(string_piece lemma) const override;
  virtual int lemma_id_len(string_piece lemma) const override;
  virtual int raw_form_len(string_piece form) const override;
  virtual tokenizer* new_tokenizer() const override;

  bool load(istream& is);
 private:
  inline void analyze_special(string_piece form, vector<tagged_lemma>& lemmas) const;

  morpho_language language;
  unsigned version;
  morpho_dictionary<czech_lemma_addinfo> dictionary;
  unique_ptr<morpho_prefix_guesser<decltype(dictionary)>> prefix_guesser;
  unique_ptr<morpho_statistical_guesser> statistical_guesser;

  string unknown_tag = "X@-------------";
  string number_tag = "C=-------------";
  string punctuation_tag = "Z:-------------";
};

/////////
// File: morpho/czech_morpho.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

bool czech_morpho::load(istream& is) {
  binary_decoder data;
  if (!compressor::load(is, data)) return false;

  try {
    // Load tag length
    unsigned tag_length = data.next_1B();
    if (tag_length < unknown_tag.size()) unknown_tag.erase(tag_length);
    if (tag_length < number_tag.size()) number_tag.erase(tag_length);
    if (tag_length < punctuation_tag.size()) punctuation_tag.erase(tag_length);

    // Load dictionary
    dictionary.load(data);

    // Optionally prefix guesser if present
    prefix_guesser.reset();
    if (data.next_1B()) {
      prefix_guesser.reset(new morpho_prefix_guesser<decltype(dictionary)>(dictionary));
      prefix_guesser->load(data);
    }

    // Optionally statistical guesser if present
    statistical_guesser.reset();
    if (data.next_1B()) {
      statistical_guesser.reset(new morpho_statistical_guesser());
      statistical_guesser->load(data);
    }
  } catch (binary_decoder_error&) {
    return false;
  }

  return data.is_end();
}

int czech_morpho::analyze(string_piece form, guesser_mode guesser, vector<tagged_lemma>& lemmas) const {
  lemmas.clear();

  if (form.len) {
    // Generate all casing variants if needed (they are different than given form).
    string form_uclc; // first uppercase, rest lowercase
    string form_lc;   // all lowercase
    generate_casing_variants(form, form_uclc, form_lc);

    // Start by analysing using the dictionary and all casing variants.
    dictionary.analyze(form, lemmas);
    if (!form_uclc.empty()) dictionary.analyze(form_uclc, lemmas);
    if (!form_lc.empty()) dictionary.analyze(form_lc, lemmas);
    if (!lemmas.empty()) return NO_GUESSER;

    // Then call analyze_special to handle numbers and punctuation.
    analyze_special(form, lemmas);
    if (!lemmas.empty()) return NO_GUESSER;

    // For the prefix guesser, use only form_lc.
    if (guesser == GUESSER && prefix_guesser)
      prefix_guesser->analyze(form_lc.empty() ? form : form_lc, lemmas);
    bool prefix_guesser_guesses = !lemmas.empty();

    // For the statistical guesser, use all casing variants.
    if (guesser == GUESSER && statistical_guesser) {
      if (form_uclc.empty() && form_lc.empty())
        statistical_guesser->analyze(form, lemmas, nullptr);
      else {
        morpho_statistical_guesser::used_rules used_rules; used_rules.reserve(3);
        statistical_guesser->analyze(form, lemmas, &used_rules);
        if (!form_uclc.empty()) statistical_guesser->analyze(form_uclc, lemmas, &used_rules);
        if (!form_lc.empty()) statistical_guesser->analyze(form_lc, lemmas, &used_rules);
      }
    }

    // Make sure results are unique lemma-tag pairs. Statistical guesser produces
    // unique lemma-tag pairs, but prefix guesser does not.
    if (prefix_guesser_guesses) {
      sort(lemmas.begin(), lemmas.end(), [](const tagged_lemma& a, const tagged_lemma& b) {
        int lemma_compare = a.lemma.compare(b.lemma);
        return lemma_compare < 0 || (lemma_compare == 0 && a.tag < b.tag);
      });
      auto lemmas_end = unique(lemmas.begin(), lemmas.end(), [](const tagged_lemma& a, const tagged_lemma& b) {
        return a.lemma == b.lemma && a.tag == b.tag;
      });
      if (lemmas_end != lemmas.end()) lemmas.erase(lemmas_end, lemmas.end());
    }

    if (!lemmas.empty()) return GUESSER;
  }

  lemmas.emplace_back(string(form.str, form.len), unknown_tag);
  return -1;
}

int czech_morpho::generate(string_piece lemma, const char* tag_wildcard, morpho::guesser_mode guesser, vector<tagged_lemma_forms>& forms) const {
  forms.clear();

  tag_filter filter(tag_wildcard);

  if (lemma.len) {
    if (dictionary.generate(lemma, filter, forms))
      return NO_GUESSER;

    if (guesser == GUESSER && prefix_guesser)
      if (prefix_guesser->generate(lemma, filter, forms))
        return GUESSER;
  }

  return -1;
}

int czech_morpho::raw_lemma_len(string_piece lemma) const {
  return czech_lemma_addinfo::raw_lemma_len(lemma);
}

int czech_morpho::lemma_id_len(string_piece lemma) const {
  return czech_lemma_addinfo::lemma_id_len(lemma);
}

int czech_morpho::raw_form_len(string_piece form) const {
  return form.len;
}

tokenizer* czech_morpho::new_tokenizer() const {
  return new czech_tokenizer(language, version, this);
}

// What characters are considered punctuation except for the ones in unicode Punctuation category.
static bool punctuation_additional[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1/*$*/,
  0,0,0,0,0,0,1/*+*/,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1/*<*/,1/*=*/,1/*>*/,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,1/*^*/,0,1/*`*/,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1/*|*/,0,1/*~*/,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1/*ˇ*/};

// What characters of unicode Punctuation category are not considered punctuation.
static bool punctuation_exceptions[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,1/*§*/};

void czech_morpho::analyze_special(string_piece form, vector<tagged_lemma>& lemmas) const {
  using namespace unilib;

  // Analyzer for numbers and punctuation.
  // Number is anything matching [+-]? is_Pn* ([.,] is_Pn*)? ([Ee] [+-]? is_Pn+)? for at least one is_Pn* nonempty.
  // Punctuation is any form beginning with either unicode punctuation or punctuation_exceptions character.
  // Beware that numbers takes precedence, so - is punctuation, -3 is number, -. is punctuation, -.3 is number.
  if (!form.len) return;

  string_piece form_ori = form;
  char32_t first = utf8::decode(form.str, form.len);

  // Try matching a number.
  char32_t codepoint = first;
  bool any_digit = false;
  if (codepoint == '+' || codepoint == '-') codepoint = utf8::decode(form.str, form.len);
  while (unicode::category(codepoint) & unicode::N) any_digit = true, codepoint = utf8::decode(form.str, form.len);
  if ((codepoint == '.' && form.len) || codepoint == ',') codepoint = utf8::decode(form.str, form.len);
  while (unicode::category(codepoint) & unicode::N) any_digit = true, codepoint = utf8::decode(form.str, form.len);
  if (any_digit && (codepoint == 'e' || codepoint == 'E')) {
    codepoint = utf8::decode(form.str, form.len);
    if (codepoint == '+' || codepoint == '-') codepoint = utf8::decode(form.str, form.len);
    any_digit = false;
    while (unicode::category(codepoint) & unicode::N) any_digit = true, codepoint = utf8::decode(form.str, form.len);
  }

  if (any_digit && !form.len && (!codepoint || codepoint == '.')) {
    lemmas.emplace_back(string(form_ori.str, form_ori.len - (codepoint == '.')), number_tag);
  } else if ((first < sizeof(punctuation_additional) && punctuation_additional[first]) ||
             ((unicode::category(first) & unicode::P) && (first >= sizeof(punctuation_exceptions) || !punctuation_exceptions[first])))
    lemmas.emplace_back(string(form_ori.str, form_ori.len), punctuation_tag);
}

/////////
// File: morpho/english_lemma_addinfo.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
struct english_lemma_addinfo {
  inline static int raw_lemma_len(string_piece lemma);
  inline static int lemma_id_len(string_piece lemma);
  inline static string format(const unsigned char* addinfo, int addinfo_len);
  inline static bool generatable(const unsigned char* addinfo, int addinfo_len);

  inline int parse(string_piece lemma, bool die_on_failure = false);
  inline bool match_lemma_id(const unsigned char* other_addinfo, int other_addinfo_len);

  vector<unsigned char> data;
};

// Definitions
int english_lemma_addinfo::raw_lemma_len(string_piece lemma) {
  // Lemma ends either by
  // - '^' on non-first position followed by nothing or [A-Za-z][-A-Za-z]*
  // - '+' on non-first position followed by nothing
  for (unsigned len = 1; len < lemma.len; len++) {
    if (len + 1 == lemma.len && (lemma.str[len] == '^' || lemma.str[len] == '+'))
      return len;
    if (len + 1 < lemma.len && lemma.str[len] == '^') {
      bool ok = true;
      for (unsigned i = len + 1; ok && i < lemma.len; i++)
        ok &= (lemma.str[i] >= 'A' && lemma.str[i] <= 'Z') ||
            (lemma.str[i] >= 'a' && lemma.str[i] <= 'z') ||
            (i > len + 1 && lemma.str[i] == '-');
      if (ok) return len;
    }
  }
  return lemma.len;
}

int english_lemma_addinfo::lemma_id_len(string_piece lemma) {
  // No lemma comments.
  return lemma.len;
}

string english_lemma_addinfo::format(const unsigned char* addinfo, int addinfo_len) {
  return string((const char*) addinfo, addinfo_len);
}

bool english_lemma_addinfo::generatable(const unsigned char* /*addinfo*/, int /*addinfo_len*/) {
  return true;
}

int english_lemma_addinfo::parse(string_piece lemma, bool /*die_on_failure*/) {
  data.clear();

  size_t len = raw_lemma_len(lemma);
  for (size_t i = len; i < lemma.len; i++)
    data.push_back(lemma.str[i]);

  return len;
}

bool english_lemma_addinfo::match_lemma_id(const unsigned char* other_addinfo, int other_addinfo_len) {
  if (data.empty()) return true;
  if (data.size() == 1 && data[0] == '^') return other_addinfo_len > 0 && other_addinfo[0] == '^';
  if (data.size() == 1 && data[0] == '+') return other_addinfo_len == 0;
  return data.size() == size_t(other_addinfo_len) && small_memeq(data.data(), other_addinfo, other_addinfo_len);
}

/////////
// File: morpho/english_morpho_guesser.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class english_morpho_guesser {
 public:
  void load(binary_decoder& data);
  void analyze(string_piece form, string_piece form_lc, vector<tagged_lemma>& lemmas) const;
  bool analyze_proper_names(string_piece form, string_piece form_lc, vector<tagged_lemma>& lemmas) const;

 private:
  inline void add(const string& tag, const string& form, vector<tagged_lemma>& lemmas) const;
  inline void add(const string& tag, const string& tag2, const string& form, vector<tagged_lemma>& lemmas) const;
  inline void add(const string& tag, const string& form, unsigned negation_len, vector<tagged_lemma>& lemmas) const;
  inline void add(const string& tag, const string& tag2, const string& form, unsigned negation_len, vector<tagged_lemma>& lemmas) const;
  void add_NNS(const string& form, unsigned negation_len, vector<tagged_lemma>& lemmas) const;
  void add_NNPS(const string& form, vector<tagged_lemma>& lemmas) const;
  void add_VBG(const string& form, vector<tagged_lemma>& lemmas) const;
  void add_VBD_VBN(const string& form, vector<tagged_lemma>& lemmas) const;
  void add_VBZ(const string& form, vector<tagged_lemma>& lemmas) const;
  void add_JJR_RBR(const string& form, unsigned negation_len, vector<tagged_lemma>& lemmas) const;
  void add_JJS_RBS(const string& form, unsigned negation_len, vector<tagged_lemma>& lemmas) const;

  enum { NEGATION_LEN = 0, TO_FOLLOW = 1, TOTAL = 2 };
  vector<string> exceptions_tags;
  persistent_unordered_map exceptions;
  persistent_unordered_map negations;
  string CD = "CD", FW = "FW", JJ = "JJ", JJR = "JJR", JJS = "JJS",
         NN = "NN", NNP = "NNP", NNPS = "NNPS", NNS = "NNS", RB = "RB",
         RBR = "RBR", RBS = "RBS", SYM = "SYM", VB = "VB", VBD = "VBD",
         VBG = "VBG", VBN = "VBN", VBP = "VBP", VBZ = "VBZ";
};

/////////
// File: morpho/english_morpho.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class english_morpho : public morpho {
 public:
  english_morpho(unsigned version) : version(version) {}

  virtual int analyze(string_piece form, morpho::guesser_mode guesser, vector<tagged_lemma>& lemmas) const override;
  virtual int generate(string_piece lemma, const char* tag_wildcard, guesser_mode guesser, vector<tagged_lemma_forms>& forms) const override;
  virtual int raw_lemma_len(string_piece lemma) const override;
  virtual int lemma_id_len(string_piece lemma) const override;
  virtual int raw_form_len(string_piece form) const override;
  virtual tokenizer* new_tokenizer() const override;

  bool load(istream& is);
 private:
  inline void analyze_special(string_piece form, vector<tagged_lemma>& lemmas) const;

  unsigned version;
  morpho_dictionary<english_lemma_addinfo> dictionary;
  english_morpho_guesser morpho_guesser;

  string unknown_tag = "UNK";
  string number_tag = "CD", nnp_tag = "NNP", ls_tag = "LS";
  string open_quotation_tag = "``", close_quotation_tag = "''";
  string open_parenthesis_tag = "(", close_parenthesis_tag = ")";
  string comma_tag = ",", dot_tag = ".", punctuation_tag = ":", hash_tag = "#", dollar_tag = "$";
  string sym_tag = "SYM", jj_tag = "JJ", nn_tag = "NN", nns_tag = "NNS", cc_tag = "CC", pos_tag = "POS", in_tag = "IN";
};

/////////
// File: tokenizer/english_tokenizer.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class english_tokenizer : public ragel_tokenizer {
 public:
  enum { LATEST = 2 };
  english_tokenizer(unsigned version);

  virtual bool next_sentence(vector<token_range>& tokens) override;

 private:
  void split_token(vector<token_range>& tokens);

  static const unordered_set<string> abbreviations;
};

/////////
// File: morpho/english_morpho.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

bool english_morpho::load(istream& is) {
  binary_decoder data;
  if (!compressor::load(is, data)) return false;

  try {
    dictionary.load(data);
    morpho_guesser.load(data);
  } catch (binary_decoder_error&) {
    return false;
  }

  return data.is_end();
}

int english_morpho::analyze(string_piece form, guesser_mode guesser, vector<tagged_lemma>& lemmas) const {
  lemmas.clear();

  if (form.len) {
    // Generate all casing variants if needed (they are different than given form).
    string form_uclc; // first uppercase, rest lowercase
    string form_lc;   // all lowercase
    generate_casing_variants(form, form_uclc, form_lc);

    // Start by analysing using the dictionary and all casing variants.
    dictionary.analyze(form, lemmas);
    if (!form_uclc.empty()) dictionary.analyze(form_uclc, lemmas);
    if (!form_lc.empty()) dictionary.analyze(form_lc, lemmas);
    if (!lemmas.empty())
      return guesser == NO_GUESSER || !morpho_guesser.analyze_proper_names(form, form_lc.empty() ? form : form_lc, lemmas) ? NO_GUESSER : GUESSER;

    // Then call analyze_special to handle numbers, punctuation and symbols.
    analyze_special(form, lemmas);
    if (!lemmas.empty()) return NO_GUESSER;

    // Use English guesser on form_lc if allowed.
    if (guesser == GUESSER)
      morpho_guesser.analyze(form, form_lc.empty() ? form : form_lc, lemmas);
    if (!lemmas.empty()) return GUESSER;
  }

  lemmas.emplace_back(string(form.str, form.len), unknown_tag);
  return -1;
}

int english_morpho::generate(string_piece lemma, const char* tag_wildcard, morpho::guesser_mode /*guesser*/, vector<tagged_lemma_forms>& forms) const {
  forms.clear();

  tag_filter filter(tag_wildcard);

  if (lemma.len) {
    if (dictionary.generate(lemma, filter, forms))
      return NO_GUESSER;
  }

  return -1;
}

int english_morpho::raw_lemma_len(string_piece lemma) const {
  return english_lemma_addinfo::raw_lemma_len(lemma);
}

int english_morpho::lemma_id_len(string_piece lemma) const {
  return english_lemma_addinfo::lemma_id_len(lemma);
}

int english_morpho::raw_form_len(string_piece form) const {
  return form.len;
}

tokenizer* english_morpho::new_tokenizer() const {
  return new english_tokenizer(version <= 2 ? 1 : 2);
}

void english_morpho::analyze_special(string_piece form, vector<tagged_lemma>& lemmas) const {
  using namespace unilib;

  // Analyzer for numbers and punctuation.
  if (!form.len) return;

  // One-letter punctuation exceptions.
  if (form.len == 1)
    switch(*form.str) {
      case '.':
      case '!':
      case '?': lemmas.emplace_back(string(form.str, form.len), dot_tag); return;
      case ',': lemmas.emplace_back(string(form.str, form.len), comma_tag); return;
      case '#': lemmas.emplace_back(string(form.str, form.len), hash_tag); return;
      case '$': lemmas.emplace_back(string(form.str, form.len), dollar_tag); return;
      case '[': lemmas.emplace_back(string(form.str, form.len), sym_tag); return;
      case ']': lemmas.emplace_back(string(form.str, form.len), sym_tag); return;
      case '%': lemmas.emplace_back(string(form.str, form.len), jj_tag);
                lemmas.emplace_back(string(form.str, form.len), nn_tag); return;
      case '&': lemmas.emplace_back(string(form.str, form.len), cc_tag);
                lemmas.emplace_back(string(form.str, form.len), sym_tag); return;
      case '*': lemmas.emplace_back(string(form.str, form.len), sym_tag);
                lemmas.emplace_back(string(form.str, form.len), nn_tag); return;
      case '@': lemmas.emplace_back(string(form.str, form.len), sym_tag);
                lemmas.emplace_back(string(form.str, form.len), in_tag); return;
      case '\'': lemmas.emplace_back(string(form.str, form.len), close_quotation_tag);
                 lemmas.emplace_back(string(form.str, form.len), pos_tag); return;
    }

  // Try matching a number: [+-]? is_Pn* (, is_Pn{3})? (. is_Pn*)? (s | [Ee] [+-]? is_Pn+)? with at least one digit
  string_piece number = form;
  char32_t codepoint = utf8::decode(number.str, number.len);
  bool any_digit = false;
  if (codepoint == '+' || codepoint == '-') codepoint = utf8::decode(number.str, number.len);
  while (unicode::category(codepoint) & unicode::N) any_digit = true, codepoint = utf8::decode(number.str, number.len);
  while (codepoint == ',') {
    string_piece group = number;
    if (unicode::category(utf8::decode(group.str, group.len) & ~unicode::N)) break;
    if (unicode::category(utf8::decode(group.str, group.len) & ~unicode::N)) break;
    if (unicode::category(utf8::decode(group.str, group.len) & ~unicode::N)) break;
    any_digit = true;
    number = group;
    codepoint = utf8::decode(number.str, number.len);
  }
  if (codepoint == '.' && number.len) {
    codepoint = utf8::decode(number.str, number.len);
    while (unicode::category(codepoint) & unicode::N) any_digit = true, codepoint = utf8::decode(number.str, number.len);
  }
  if (version >= 2 && any_digit && codepoint == 's' && !number.len) {
    lemmas.emplace_back(string(form.str, form.len), number_tag);
    lemmas.emplace_back(string(form.str, form.len - 1), nns_tag);
    return;
  }
  if (any_digit && (codepoint == 'e' || codepoint == 'E')) {
    codepoint = utf8::decode(number.str, number.len);
    if (codepoint == '+' || codepoint == '-') codepoint = utf8::decode(number.str, number.len);
    any_digit = false;
    while (unicode::category(codepoint) & unicode::N) any_digit = true, codepoint = utf8::decode(number.str, number.len);
  }
  if (any_digit && !number.len && (!codepoint || codepoint == '.')) {
    lemmas.emplace_back(string(form.str, form.len - (codepoint == '.')), number_tag);
    lemmas.emplace_back(string(form.str, form.len - (codepoint == '.')), nnp_tag);
    if (form.len == 1 + (codepoint == '.') && *form.str >= '1' && *form.str <= '9')
      lemmas.emplace_back(string(form.str, form.len - (codepoint == '.')), ls_tag);
    return;
  }

  // Open quotation, end quotation, open parentheses, end parentheses, symbol, or other
  string_piece punctuation = form;
  bool open_quotation = true, close_quotation = true, open_parenthesis = true, close_parenthesis = true, any_punctuation = true, symbol = true;
  while ((symbol || any_punctuation) && punctuation.len) {
    codepoint = utf8::decode(punctuation.str, punctuation.len);
    if (open_quotation) open_quotation = codepoint == '`' || unicode::category(codepoint) & unicode::Pi;
    if (close_quotation) close_quotation = codepoint == '\'' || codepoint == '"' || unicode::category(codepoint) & unicode::Pf;
    if (open_parenthesis) open_parenthesis = unicode::category(codepoint) & unicode::Ps;
    if (close_parenthesis) close_parenthesis = unicode::category(codepoint) & unicode::Pe;
    if (any_punctuation) any_punctuation = unicode::category(codepoint) & unicode::P;
    if (symbol) symbol = codepoint == '*' || unicode::category(codepoint) & unicode::S;
  }
  if (!punctuation.len && open_quotation) { lemmas.emplace_back(string(form.str, form.len), open_quotation_tag); return; }
  if (!punctuation.len && close_quotation) { lemmas.emplace_back(string(form.str, form.len), close_quotation_tag); return; }
  if (!punctuation.len && open_parenthesis) { lemmas.emplace_back(string(form.str, form.len), open_parenthesis_tag); return; }
  if (!punctuation.len && close_parenthesis) { lemmas.emplace_back(string(form.str, form.len), close_parenthesis_tag); return; }
  if (!punctuation.len && symbol) { lemmas.emplace_back(string(form.str, form.len), sym_tag); return; }
  if (!punctuation.len && any_punctuation) { lemmas.emplace_back(string(form.str, form.len), punctuation_tag); return; }
}

/////////
// File: morpho/english_morpho_guesser.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// This code is a reimplementation of morphologic analyzer Morphium
// by Johanka Spoustová (Treex::Tool::EnglishMorpho::Analysis Perl module)
// and reimplementation of morphologic lemmatizer by Martin Popel
// (Treex::Tool::EnglishMorpho::Lemmatizer Perl module). The latter is based
// on morpha:
//   Minnen, G., J. Carroll and D. Pearce (2001). Applied morphological
//   processing of English, Natural Language Engineering, 7(3). 207-223.
// Morpha has been released under LGPL as a part of RASP system
//   http://ilexir.co.uk/applications/rasp/.

void english_morpho_guesser::load(binary_decoder& data) {
  unsigned tags = data.next_2B();
  exceptions_tags.clear();
  exceptions_tags.reserve(tags);
  while (tags--) {
    unsigned len = data.next_1B();
    exceptions_tags.emplace_back(string(data.next<char>(len), len));
  }

  exceptions.load(data);
  negations.load(data);
}

static const char _tag_guesser_actions[] = {
	0, 1, 0, 1, 1, 1, 2, 1, 
	3, 1, 4, 1, 5, 1, 6, 1, 
	7, 2, 2, 6, 2, 2, 7, 2, 
	4, 6, 2, 4, 7, 2, 5, 6, 
	2, 5, 7, 2, 6, 7, 3, 2, 
	6, 7, 3, 4, 6, 7, 3, 5, 
	6, 7
};

static const unsigned char _tag_guesser_key_offsets[] = {
	0, 19, 26, 34, 42, 50, 58, 66, 
	74, 82, 90, 100, 108, 116, 124, 132, 
	145, 153, 161, 168, 179, 195, 212, 220, 
	228, 236
};

static const char _tag_guesser_trans_keys[] = {
	45, 46, 99, 100, 103, 105, 109, 110, 
	114, 115, 116, 118, 120, 48, 57, 65, 
	90, 97, 122, 45, 48, 57, 65, 90, 
	97, 122, 45, 114, 48, 57, 65, 90, 
	97, 122, 45, 111, 48, 57, 65, 90, 
	97, 122, 45, 109, 48, 57, 65, 90, 
	97, 122, 45, 101, 48, 57, 65, 90, 
	97, 122, 45, 115, 48, 57, 65, 90, 
	97, 122, 45, 101, 48, 57, 65, 90, 
	97, 122, 45, 108, 48, 57, 65, 90, 
	97, 122, 45, 115, 48, 57, 65, 90, 
	97, 122, 45, 97, 101, 111, 48, 57, 
	65, 90, 98, 122, 45, 101, 48, 57, 
	65, 90, 97, 122, 45, 108, 48, 57, 
	65, 90, 97, 122, 45, 109, 48, 57, 
	65, 90, 97, 122, 45, 105, 48, 57, 
	65, 90, 97, 122, 45, 97, 101, 105, 
	111, 117, 121, 48, 57, 65, 90, 98, 
	122, 45, 115, 48, 57, 65, 90, 97, 
	122, 45, 101, 48, 57, 65, 90, 97, 
	122, 45, 48, 57, 65, 90, 97, 122, 
	45, 101, 114, 115, 116, 48, 57, 65, 
	90, 97, 122, 45, 46, 105, 109, 118, 
	120, 48, 57, 65, 90, 97, 98, 99, 
	100, 101, 122, 45, 46, 101, 105, 109, 
	118, 120, 48, 57, 65, 90, 97, 98, 
	99, 100, 102, 122, 45, 110, 48, 57, 
	65, 90, 97, 122, 45, 105, 48, 57, 
	65, 90, 97, 122, 45, 101, 48, 57, 
	65, 90, 97, 122, 45, 115, 48, 57, 
	65, 90, 97, 122, 0
};

static const char _tag_guesser_single_lengths[] = {
	13, 1, 2, 2, 2, 2, 2, 2, 
	2, 2, 4, 2, 2, 2, 2, 7, 
	2, 2, 1, 5, 6, 7, 2, 2, 
	2, 2
};

static const char _tag_guesser_range_lengths[] = {
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 5, 5, 3, 3, 
	3, 3
};

static const unsigned char _tag_guesser_index_offsets[] = {
	0, 17, 22, 28, 34, 40, 46, 52, 
	58, 64, 70, 78, 84, 90, 96, 102, 
	113, 119, 125, 130, 139, 151, 164, 170, 
	176, 182
};

static const char _tag_guesser_indicies[] = {
	1, 2, 5, 6, 7, 5, 5, 8, 
	9, 10, 11, 5, 5, 3, 4, 4, 
	0, 13, 14, 15, 15, 12, 13, 16, 
	14, 15, 15, 12, 13, 17, 14, 15, 
	15, 12, 13, 18, 14, 15, 15, 12, 
	13, 18, 14, 15, 15, 12, 13, 19, 
	14, 15, 15, 12, 13, 20, 14, 15, 
	15, 12, 13, 18, 14, 15, 15, 12, 
	13, 21, 14, 15, 15, 12, 13, 22, 
	23, 24, 14, 15, 15, 12, 13, 25, 
	14, 15, 15, 12, 13, 23, 14, 15, 
	15, 12, 13, 23, 14, 15, 15, 12, 
	13, 26, 14, 15, 15, 12, 28, 15, 
	15, 15, 15, 15, 15, 29, 26, 26, 
	27, 31, 4, 32, 33, 33, 30, 13, 
	23, 14, 15, 15, 12, 13, 14, 15, 
	15, 12, 13, 34, 35, 36, 37, 14, 
	15, 15, 12, 13, 38, 39, 39, 39, 
	39, 14, 15, 15, 39, 15, 12, 13, 
	38, 40, 39, 39, 39, 39, 14, 15, 
	15, 39, 15, 12, 13, 41, 14, 15, 
	15, 12, 13, 42, 14, 15, 15, 12, 
	13, 18, 14, 15, 15, 12, 13, 43, 
	14, 15, 15, 12, 0
};

static const char _tag_guesser_trans_targs[] = {
	18, 19, 20, 18, 18, 20, 21, 22, 
	23, 24, 16, 25, 18, 19, 18, 1, 
	3, 4, 18, 7, 8, 10, 11, 18, 
	13, 12, 18, 18, 19, 18, 18, 19, 
	18, 18, 2, 5, 6, 9, 20, 20, 
	18, 14, 15, 17
};

static const char _tag_guesser_trans_actions[] = {
	29, 46, 29, 32, 11, 11, 11, 11, 
	11, 11, 0, 11, 13, 35, 15, 0, 
	0, 0, 1, 0, 0, 0, 0, 3, 
	0, 0, 5, 17, 38, 20, 23, 42, 
	26, 9, 0, 0, 0, 0, 13, 0, 
	7, 0, 0, 0
};

static const char _tag_guesser_eof_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 15, 15, 0, 0, 
	0, 0
};

static const int tag_guesser_start = 0;

void english_morpho_guesser::analyze(string_piece form, string_piece form_lc, vector<tagged_lemma>& lemmas) const {
  // Try exceptions list
  auto* exception = exceptions.at(form_lc.str, form_lc.len, [](pointer_decoder& data){
    for (unsigned len = data.next_1B(); len; len--) {
      data.next<char>(data.next_1B());
      data.next<uint16_t>(data.next_1B());
    }
  });

  if (exception) {
    // Found in exceptions list
    pointer_decoder data(exception);
    for (unsigned len = data.next_1B(); len; len--) {
      unsigned lemma_len = data.next_1B();
      string lemma(data.next<char>(lemma_len), lemma_len);
      for (unsigned tags = data.next_1B(); tags; tags--)
        lemmas.emplace_back(lemma, exceptions_tags[data.next_2B()]);
    }
  } else {
    // Try stripping negative prefix and use rule guesser
    string lemma_lc(form_lc.str, form_lc.len);
    // Try finding negative prefix
    unsigned negation_len = 0;
    for (unsigned prefix = 1; prefix <= form_lc.len; prefix++) {
      auto found = negations.at(form_lc.str, prefix, [](pointer_decoder& data){ data.next<unsigned char>(TOTAL); });
      if (!found) break;
      if (found[NEGATION_LEN]) {
        if (form_lc.len - prefix >= found[TO_FOLLOW]) negation_len = found[NEGATION_LEN];
      }
    }

    // Add default tags
    add(FW, lemma_lc, lemmas);
    add(JJ, lemma_lc, negation_len, lemmas);
    add(RB, lemma_lc, negation_len, lemmas);
    add(NN, lemma_lc, negation_len, lemmas);
    add_NNS(lemma_lc, negation_len, lemmas);

    // Add specialized tags
    const char* p = form_lc.str; int cs;
    bool added_JJR_RBR = false, added_JJS_RBS = false, added_SYM = false, added_CD = false;
    
	{
	cs = tag_guesser_start;
	}

	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == ( (form_lc.str + form_lc.len)) )
		goto _test_eof;
_resume:
	_keys = _tag_guesser_trans_keys + _tag_guesser_key_offsets[cs];
	_trans = _tag_guesser_index_offsets[cs];

	_klen = _tag_guesser_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( ( form_lc.str[form_lc.len - 1 - (p - form_lc.str)]) < *_mid )
				_upper = _mid - 1;
			else if ( ( form_lc.str[form_lc.len - 1 - (p - form_lc.str)]) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _tag_guesser_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( ( form_lc.str[form_lc.len - 1 - (p - form_lc.str)]) < _mid[0] )
				_upper = _mid - 2;
			else if ( ( form_lc.str[form_lc.len - 1 - (p - form_lc.str)]) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _tag_guesser_indicies[_trans];
	cs = _tag_guesser_trans_targs[_trans];

	if ( _tag_guesser_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _tag_guesser_actions + _tag_guesser_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
	{ if (!added_JJR_RBR) added_JJR_RBR = true, add_JJR_RBR(lemma_lc, negation_len, lemmas); }
	break;
	case 1:
	{ if (!added_JJS_RBS) added_JJS_RBS = true, add_JJS_RBS(lemma_lc, negation_len, lemmas); }
	break;
	case 2:
	{ add_VBG(lemma_lc, lemmas); }
	break;
	case 3:
	{ add_VBD_VBN(lemma_lc, lemmas); }
	break;
	case 4:
	{ add_VBZ(lemma_lc, lemmas); }
	break;
	case 5:
	{ add(VB, lemma_lc, lemmas); add(VBP, lemma_lc, lemmas); }
	break;
	case 6:
	{ if (!added_SYM) added_SYM = true, add(SYM, lemma_lc, lemmas); }
	break;
	case 7:
	{ if (!added_CD) added_CD = true, add(CD, lemma_lc, lemmas); }
	break;
		}
	}

_again:
	if ( ++p != ( (form_lc.str + form_lc.len)) )
		goto _resume;
	_test_eof: {}
	if ( p == ( (form_lc.str + form_lc.len)) )
	{
	const char *__acts = _tag_guesser_actions + _tag_guesser_eof_actions[cs];
	unsigned int __nacts = (unsigned int) *__acts++;
	while ( __nacts-- > 0 ) {
		switch ( *__acts++ ) {
	case 7:
	{ if (!added_CD) added_CD = true, add(CD, lemma_lc, lemmas); }
	break;
		}
	}
	}

	}

  }

  // Add proper names
  analyze_proper_names(form, form_lc, lemmas);
}

bool english_morpho_guesser::analyze_proper_names(string_piece form, string_piece form_lc, vector<tagged_lemma>& lemmas) const {
  // NNP if form_lc != form or form.str[0] =~ /[0-9']/, NNPS if form_lc != form
  bool is_NNP = form.str != form_lc.str || (form.len && (*form.str == '\'' || (*form.str >= '0' && *form.str <= '9')));
  bool is_NNPS = form.str != form_lc.str;
  if (!is_NNP && !is_NNPS) return false;

  bool was_NNP = false, was_NNPS = false;
  for (auto&& lemma : lemmas) {
    was_NNP |= lemma.tag == NNP;
    was_NNPS |= lemma.tag == NNPS;
  }
  if (!((is_NNP && !was_NNP) || (is_NNPS && !was_NNPS))) return false;

  string lemma(form.str, form.len);
  if (is_NNP && !was_NNP) add(NNP, lemma, lemmas);
  if (is_NNPS && !was_NNPS) add_NNPS(lemma, lemmas);
  return true;
}

inline void english_morpho_guesser::add(const string& tag, const string& form, vector<tagged_lemma>& lemmas) const {
  lemmas.emplace_back(form, tag);
}

inline void english_morpho_guesser::add(const string& tag, const string& tag2, const string& form, vector<tagged_lemma>& lemmas) const {
  add(tag, form, lemmas);
  add(tag2, form, lemmas);
}

inline void english_morpho_guesser::add(const string& tag, const string& form, unsigned negation_len, vector<tagged_lemma>& lemmas) const {
  lemmas.emplace_back(negation_len ? form.substr(negation_len) + "^" + form.substr(0, negation_len) : form, tag);
}

inline void english_morpho_guesser::add(const string& tag, const string& tag2, const string& form, unsigned negation_len, vector<tagged_lemma>& lemmas) const {
  add(tag, form, negation_len, lemmas);
  add(tag2, form, negation_len, lemmas);
}

// Common definitions (written backwards)
#define REM(str, len) (str.substr(0, str.size() - len))
#define REM_ADD(str, len, add) (str.substr(0, str.size() - len).append(add))

static const char _NNS_actions[] = {
	0, 1, 0, 1, 1, 1, 2, 1, 
	3, 1, 4, 1, 5, 1, 6, 1, 
	7, 1, 8, 1, 9, 1, 10, 1, 
	11, 1, 12, 1, 13
};

static const char _NNS_key_offsets[] = {
	0, 0, 2, 3, 4, 5, 7, 17, 
	17, 29, 30, 35, 35, 36, 37, 37, 
	37, 44, 45, 53, 63, 72
};

static const char _NNS_trans_keys[] = {
	110, 115, 101, 109, 101, 99, 115, 98, 
	100, 102, 104, 106, 110, 112, 116, 118, 
	122, 104, 122, 98, 100, 102, 103, 106, 
	110, 112, 116, 118, 120, 111, 97, 101, 
	105, 111, 117, 105, 119, 104, 105, 111, 
	115, 118, 120, 122, 115, 97, 101, 105, 
	110, 111, 114, 115, 117, 98, 100, 102, 
	104, 106, 110, 112, 116, 118, 122, 97, 
	101, 105, 111, 117, 121, 122, 98, 120, 
	0
};

static const char _NNS_single_lengths[] = {
	0, 2, 1, 1, 1, 2, 0, 0, 
	2, 1, 5, 0, 1, 1, 0, 0, 
	7, 1, 8, 0, 7, 0
};

static const char _NNS_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 5, 0, 
	5, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 5, 1, 0
};

static const char _NNS_index_offsets[] = {
	0, 0, 3, 5, 7, 9, 12, 18, 
	19, 27, 29, 35, 36, 38, 40, 41, 
	42, 50, 52, 61, 67, 76
};

static const char _NNS_indicies[] = {
	0, 2, 1, 3, 1, 4, 1, 6, 
	5, 7, 7, 1, 8, 8, 8, 8, 
	8, 1, 9, 11, 10, 10, 10, 10, 
	10, 10, 1, 12, 1, 13, 13, 13, 
	13, 13, 1, 14, 15, 1, 16, 1, 
	17, 1, 18, 19, 20, 21, 22, 7, 
	23, 1, 24, 1, 25, 25, 25, 26, 
	25, 27, 28, 29, 1, 30, 30, 30, 
	30, 30, 1, 31, 31, 31, 31, 31, 
	31, 33, 32, 1, 17, 0
};

static const char _NNS_trans_targs[] = {
	2, 0, 4, 3, 15, 15, 16, 15, 
	7, 15, 15, 17, 15, 11, 15, 13, 
	15, 15, 5, 6, 8, 18, 12, 20, 
	15, 15, 9, 10, 15, 19, 15, 15, 
	14, 21
};

static const char _NNS_trans_actions[] = {
	0, 0, 0, 0, 1, 27, 27, 21, 
	0, 23, 25, 25, 19, 0, 17, 0, 
	5, 11, 0, 0, 0, 21, 0, 21, 
	3, 9, 0, 0, 15, 9, 7, 13, 
	0, 15
};

static const int NNS_start = 1;

void english_morpho_guesser::add_NNS(const string& form, unsigned negation_len, vector<tagged_lemma>& lemmas) const {
  const char* p = form.c_str() + negation_len; int cs;
  char best = 'z'; unsigned remove = 0; const char* append = nullptr;
  
	{
	cs = NNS_start;
	}

	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == ( (form.c_str() + form.size())) )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _NNS_trans_keys + _NNS_key_offsets[cs];
	_trans = _NNS_index_offsets[cs];

	_klen = _NNS_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( ( form[form.size() - 1 - (p - form.c_str() - negation_len)]) < *_mid )
				_upper = _mid - 1;
			else if ( ( form[form.size() - 1 - (p - form.c_str() - negation_len)]) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _NNS_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( ( form[form.size() - 1 - (p - form.c_str() - negation_len)]) < _mid[0] )
				_upper = _mid - 2;
			else if ( ( form[form.size() - 1 - (p - form.c_str() - negation_len)]) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _NNS_indicies[_trans];
	cs = _NNS_trans_targs[_trans];

	if ( _NNS_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _NNS_actions + _NNS_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
	{ if (best > 'a') best = 'a', remove = 2, append = "an";    }
	break;
	case 1:
	{ if (best > 'b') best = 'b', remove = 1, append = nullptr; }
	break;
	case 2:
	{ if (best > 'c') best = 'c', remove = 3, append = "fe";    }
	break;
	case 3:
	{ if (best > 'd') best = 'd', remove = 2, append = nullptr; }
	break;
	case 4:
	{ if (best > 'e') best = 'e', remove = 1, append = nullptr; }
	break;
	case 5:
	{ if (best > 'f') best = 'f', remove = 2, append = nullptr; }
	break;
	case 6:
	{ if (best > 'g') best = 'g', remove = 1, append = nullptr; }
	break;
	case 7:
	{ if (best > 'h') best = 'h', remove = 2, append = nullptr; }
	break;
	case 8:
	{ if (best > 'i') best = 'i', remove = 1, append = nullptr; }
	break;
	case 9:
	{ if (best > 'j') best = 'j', remove = 1, append = nullptr; }
	break;
	case 10:
	{ if (best > 'k') best = 'k', remove = 2, append = nullptr; }
	break;
	case 11:
	{ if (best > 'l') best = 'l', remove = 3, append = "y";     }
	break;
	case 12:
	{ if (best > 'm') best = 'm', remove = 2, append = nullptr; }
	break;
	case 13:
	{ if (best > 'n') best = 'n', remove = 1, append = nullptr; }
	break;
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != ( (form.c_str() + form.size())) )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

  add(NNS, form.substr(0, form.size() - remove).append(append ? append : ""), negation_len, lemmas);
}

static const char _NNPS_actions[] = {
	0, 1, 1, 1, 2, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	9, 1, 10, 1, 11, 1, 12, 1, 
	14, 1, 15, 1, 16, 2, 0, 1, 
	2, 3, 4, 2, 13, 14
};

static const unsigned char _NNPS_key_offsets[] = {
	0, 0, 4, 6, 8, 10, 12, 16, 
	36, 36, 60, 62, 72, 72, 74, 76, 
	78, 78, 98, 98, 100, 102, 104, 104, 
	118, 120, 136, 156, 174, 174
};

static const char _NNPS_trans_keys[] = {
	78, 83, 110, 115, 69, 101, 77, 109, 
	77, 109, 69, 101, 67, 83, 99, 115, 
	66, 68, 70, 72, 74, 78, 80, 84, 
	86, 90, 98, 100, 102, 104, 106, 110, 
	112, 116, 118, 122, 72, 90, 104, 122, 
	66, 68, 70, 71, 74, 78, 80, 84, 
	86, 88, 98, 100, 102, 103, 106, 110, 
	112, 116, 118, 120, 79, 111, 65, 69, 
	73, 79, 85, 97, 101, 105, 111, 117, 
	73, 105, 87, 119, 87, 119, 66, 68, 
	70, 72, 74, 78, 80, 84, 86, 90, 
	98, 100, 102, 104, 106, 110, 112, 116, 
	118, 122, 73, 105, 69, 101, 69, 101, 
	72, 73, 79, 83, 86, 88, 90, 104, 
	105, 111, 115, 118, 120, 122, 83, 115, 
	65, 69, 73, 78, 79, 82, 83, 85, 
	97, 101, 105, 110, 111, 114, 115, 117, 
	66, 68, 70, 72, 74, 78, 80, 84, 
	86, 90, 98, 100, 102, 104, 106, 110, 
	112, 116, 118, 122, 65, 69, 73, 79, 
	85, 89, 90, 97, 101, 105, 111, 117, 
	121, 122, 66, 88, 98, 120, 72, 73, 
	79, 83, 86, 88, 90, 104, 105, 111, 
	115, 118, 120, 122, 0
};

static const char _NNPS_single_lengths[] = {
	0, 4, 2, 2, 2, 2, 4, 0, 
	0, 4, 2, 10, 0, 2, 2, 2, 
	0, 0, 0, 2, 2, 2, 0, 14, 
	2, 16, 0, 14, 0, 14
};

static const char _NNPS_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 10, 
	0, 10, 0, 0, 0, 0, 0, 0, 
	0, 10, 0, 0, 0, 0, 0, 0, 
	0, 0, 10, 2, 0, 0
};

static const unsigned char _NNPS_index_offsets[] = {
	0, 0, 5, 8, 11, 14, 17, 22, 
	33, 34, 49, 52, 63, 64, 67, 70, 
	73, 74, 85, 86, 89, 92, 95, 96, 
	111, 114, 131, 142, 159, 160
};

static const char _NNPS_indicies[] = {
	0, 2, 3, 4, 1, 5, 6, 1, 
	7, 8, 1, 8, 8, 1, 10, 11, 
	9, 12, 12, 12, 12, 1, 13, 13, 
	13, 13, 13, 13, 13, 13, 13, 13, 
	1, 14, 16, 15, 16, 15, 15, 15, 
	15, 15, 15, 15, 15, 15, 15, 15, 
	1, 17, 17, 1, 18, 18, 18, 18, 
	18, 18, 18, 18, 18, 18, 1, 19, 
	20, 21, 1, 22, 23, 1, 23, 23, 
	1, 24, 25, 25, 25, 25, 25, 25, 
	25, 25, 25, 25, 1, 26, 21, 21, 
	1, 6, 6, 1, 11, 11, 9, 1, 
	27, 28, 29, 30, 31, 12, 32, 27, 
	33, 29, 30, 34, 12, 32, 1, 35, 
	35, 1, 36, 36, 36, 37, 36, 38, 
	39, 40, 36, 36, 36, 37, 36, 38, 
	39, 40, 1, 41, 41, 41, 41, 41, 
	41, 41, 41, 41, 41, 1, 42, 42, 
	42, 42, 42, 42, 44, 42, 42, 42, 
	42, 42, 42, 44, 43, 43, 1, 24, 
	27, 33, 29, 30, 34, 12, 32, 27, 
	33, 29, 30, 34, 12, 32, 1, 0
};

static const char _NNPS_trans_targs[] = {
	2, 0, 5, 20, 21, 3, 4, 22, 
	22, 22, 23, 29, 22, 8, 22, 22, 
	24, 22, 12, 22, 14, 15, 22, 22, 
	22, 18, 22, 6, 7, 9, 25, 13, 
	27, 17, 19, 22, 22, 10, 11, 22, 
	26, 22, 22, 16, 28
};

static const char _NNPS_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 29, 
	1, 27, 27, 27, 21, 0, 35, 25, 
	25, 19, 0, 17, 0, 0, 32, 5, 
	11, 0, 23, 0, 0, 0, 21, 0, 
	21, 0, 0, 3, 9, 0, 0, 15, 
	9, 7, 13, 0, 15
};

static const int NNPS_start = 1;

void english_morpho_guesser::add_NNPS(const string& form, vector<tagged_lemma>& lemmas) const {
  const char* p = form.c_str(); int cs;
  char best = 'z'; unsigned remove = 0; const char* append = nullptr;
  
	{
	cs = NNPS_start;
	}

	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == ( (form.c_str() + form.size())) )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _NNPS_trans_keys + _NNPS_key_offsets[cs];
	_trans = _NNPS_index_offsets[cs];

	_klen = _NNPS_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( ( form[form.size() - 1 - (p - form.c_str())]) < *_mid )
				_upper = _mid - 1;
			else if ( ( form[form.size() - 1 - (p - form.c_str())]) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _NNPS_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( ( form[form.size() - 1 - (p - form.c_str())]) < _mid[0] )
				_upper = _mid - 2;
			else if ( ( form[form.size() - 1 - (p - form.c_str())]) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _NNPS_indicies[_trans];
	cs = _NNPS_trans_targs[_trans];

	if ( _NNPS_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _NNPS_actions + _NNPS_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
	{ if (best > 'a') best = 'a', remove = 2, append = "AN";    }
	break;
	case 1:
	{ if (best > 'b') best = 'b', remove = 2, append = "an";    }
	break;
	case 2:
	{ if (best > 'c') best = 'c', remove = 1, append = nullptr; }
	break;
	case 3:
	{ if (best > 'd') best = 'd', remove = 3, append = "FE";    }
	break;
	case 4:
	{ if (best > 'e') best = 'e', remove = 3, append = "fe";    }
	break;
	case 5:
	{ if (best > 'f') best = 'f', remove = 2, append = nullptr; }
	break;
	case 6:
	{ if (best > 'g') best = 'g', remove = 1, append = nullptr; }
	break;
	case 7:
	{ if (best > 'h') best = 'h', remove = 2, append = nullptr; }
	break;
	case 8:
	{ if (best > 'i') best = 'i', remove = 1, append = nullptr; }
	break;
	case 9:
	{ if (best > 'j') best = 'j', remove = 2, append = nullptr; }
	break;
	case 10:
	{ if (best > 'k') best = 'k', remove = 1, append = nullptr; }
	break;
	case 11:
	{ if (best > 'l') best = 'l', remove = 1, append = nullptr; }
	break;
	case 12:
	{ if (best > 'm') best = 'm', remove = 2, append = nullptr; }
	break;
	case 13:
	{ if (best > 'n') best = 'n', remove = 3, append = "Y";     }
	break;
	case 14:
	{ if (best > 'o') best = 'o', remove = 3, append = "y";     }
	break;
	case 15:
	{ if (best > 'p') best = 'p', remove = 2, append = nullptr; }
	break;
	case 16:
	{ if (best > 'q') best = 'q', remove = 1, append = nullptr; }
	break;
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != ( (form.c_str() + form.size())) )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

  add(NNPS, form.substr(0, form.size() - remove).append(append ? append : ""), lemmas);
}

static const char _VBG_actions[] = {
	0, 1, 1, 1, 2, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 9, 1, 
	10, 1, 11, 1, 12, 1, 13, 1, 
	14, 1, 15, 1, 16, 1, 17, 2, 
	0, 12, 2, 3, 4, 2, 5, 9, 
	2, 5, 10, 2, 8, 9, 2, 9, 
	10, 2, 11, 12, 3, 0, 2, 12, 
	3, 2, 11, 12
};

static const short _VBG_key_offsets[] = {
	0, 0, 1, 2, 3, 9, 14, 24, 
	29, 34, 44, 46, 47, 48, 49, 50, 
	51, 52, 59, 66, 68, 70, 71, 72, 
	73, 74, 75, 76, 81, 89, 90, 91, 
	92, 93, 94, 96, 97, 98, 99, 100, 
	101, 102, 127, 127, 136, 137, 142, 153, 
	162, 171, 181, 186, 191, 197, 207, 207, 
	216, 228, 229, 240, 240, 249, 258, 267, 
	276, 285, 290, 302, 313, 318, 324, 334, 
	344, 355, 362, 373, 382, 391, 391, 402, 
	413, 415, 416, 417, 417, 418, 426, 437, 
	442, 448, 458, 468, 479, 486, 497, 504, 
	510, 519, 528, 537, 543
};

static const char _VBG_trans_keys[] = {
	103, 110, 105, 97, 101, 105, 111, 117, 
	121, 97, 101, 105, 111, 117, 98, 100, 
	102, 104, 106, 110, 112, 116, 118, 122, 
	97, 101, 105, 111, 117, 97, 101, 105, 
	111, 117, 98, 100, 102, 104, 106, 110, 
	112, 116, 118, 122, 98, 114, 105, 114, 
	112, 105, 109, 101, 97, 101, 105, 111, 
	117, 98, 122, 97, 101, 105, 111, 117, 
	98, 122, 97, 122, 98, 114, 105, 114, 
	112, 105, 109, 101, 97, 101, 105, 111, 
	117, 97, 101, 105, 110, 111, 115, 117, 
	120, 105, 112, 105, 109, 101, 98, 114, 
	105, 114, 112, 105, 109, 101, 98, 99, 
	100, 102, 103, 104, 106, 107, 108, 109, 
	110, 111, 112, 113, 114, 115, 116, 117, 
	118, 119, 120, 121, 122, 97, 105, 97, 
	98, 101, 105, 111, 117, 122, 99, 120, 
	113, 97, 101, 105, 111, 117, 98, 99, 
	100, 105, 111, 117, 122, 97, 101, 102, 
	120, 97, 100, 101, 105, 111, 117, 122, 
	98, 120, 97, 101, 102, 105, 111, 117, 
	122, 98, 120, 97, 101, 103, 105, 110, 
	111, 117, 122, 98, 120, 97, 101, 105, 
	111, 117, 101, 110, 111, 115, 120, 101, 
	110, 111, 112, 115, 120, 97, 101, 104, 
	105, 111, 116, 117, 122, 98, 120, 97, 
	101, 105, 106, 111, 117, 122, 98, 120, 
	98, 99, 100, 105, 107, 111, 117, 122, 
	97, 101, 102, 120, 105, 97, 101, 105, 
	108, 111, 114, 117, 119, 122, 98, 120, 
	97, 101, 105, 109, 111, 117, 122, 98, 
	120, 97, 101, 105, 110, 111, 117, 122, 
	98, 120, 97, 101, 105, 111, 112, 117, 
	122, 98, 120, 97, 101, 105, 111, 113, 
	117, 122, 98, 120, 97, 101, 105, 111, 
	114, 117, 122, 98, 120, 97, 101, 105, 
	111, 117, 98, 99, 100, 105, 108, 111, 
	116, 117, 97, 101, 102, 122, 101, 110, 
	111, 115, 120, 98, 104, 106, 116, 118, 
	122, 101, 110, 111, 115, 120, 101, 110, 
	111, 112, 115, 120, 101, 105, 110, 111, 
	115, 120, 98, 116, 118, 122, 101, 105, 
	110, 111, 115, 120, 98, 116, 118, 122, 
	101, 110, 111, 115, 120, 98, 104, 106, 
	116, 118, 122, 98, 101, 110, 111, 114, 
	115, 120, 101, 110, 111, 115, 120, 98, 
	104, 106, 116, 118, 122, 97, 101, 105, 
	111, 115, 117, 122, 98, 120, 97, 101, 
	105, 111, 116, 117, 122, 98, 120, 122, 
	98, 100, 102, 104, 106, 110, 112, 116, 
	118, 120, 122, 98, 100, 102, 104, 106, 
	110, 112, 116, 118, 120, 98, 114, 112, 
	114, 113, 97, 101, 105, 108, 111, 117, 
	98, 122, 101, 110, 111, 115, 120, 98, 
	104, 106, 116, 118, 122, 101, 110, 111, 
	115, 120, 101, 110, 111, 112, 115, 120, 
	101, 105, 110, 111, 115, 120, 98, 116, 
	118, 122, 101, 105, 110, 111, 115, 120, 
	98, 116, 118, 122, 101, 110, 111, 115, 
	120, 98, 104, 106, 116, 118, 122, 98, 
	101, 110, 111, 114, 115, 120, 101, 110, 
	111, 115, 120, 98, 104, 106, 116, 118, 
	122, 97, 101, 105, 111, 117, 98, 122, 
	97, 101, 105, 111, 117, 121, 97, 101, 
	105, 111, 117, 118, 122, 98, 120, 97, 
	101, 105, 111, 117, 119, 122, 98, 120, 
	97, 101, 105, 111, 117, 120, 122, 98, 
	119, 97, 101, 105, 111, 117, 121, 97, 
	101, 105, 111, 117, 121, 122, 98, 120, 
	0
};

static const char _VBG_single_lengths[] = {
	0, 1, 1, 1, 6, 5, 0, 5, 
	5, 0, 2, 1, 1, 1, 1, 1, 
	1, 5, 5, 0, 2, 1, 1, 1, 
	1, 1, 1, 5, 8, 1, 1, 1, 
	1, 1, 2, 1, 1, 1, 1, 1, 
	1, 23, 0, 7, 1, 5, 7, 7, 
	7, 8, 5, 5, 6, 8, 0, 7, 
	8, 1, 9, 0, 7, 7, 7, 7, 
	7, 5, 8, 5, 5, 6, 6, 6, 
	5, 7, 5, 7, 7, 0, 1, 1, 
	2, 1, 1, 0, 1, 6, 5, 5, 
	6, 6, 6, 5, 7, 5, 5, 6, 
	7, 7, 7, 6, 7
};

static const char _VBG_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 5, 0, 
	0, 5, 0, 0, 0, 0, 0, 0, 
	0, 1, 1, 1, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 1, 0, 1, 0, 0, 2, 1, 
	1, 1, 0, 0, 0, 1, 0, 1, 
	2, 0, 1, 0, 1, 1, 1, 1, 
	1, 0, 2, 3, 0, 0, 2, 2, 
	3, 0, 3, 1, 1, 0, 5, 5, 
	0, 0, 0, 0, 0, 1, 3, 0, 
	0, 2, 2, 3, 0, 3, 1, 0, 
	1, 1, 1, 0, 1
};

static const short _VBG_index_offsets[] = {
	0, 0, 2, 4, 6, 13, 19, 25, 
	31, 37, 43, 46, 48, 50, 52, 54, 
	56, 58, 65, 72, 74, 77, 79, 81, 
	83, 85, 87, 89, 95, 104, 106, 108, 
	110, 112, 114, 117, 119, 121, 123, 125, 
	127, 129, 154, 155, 164, 166, 172, 182, 
	191, 200, 210, 216, 222, 229, 239, 240, 
	249, 260, 262, 273, 274, 283, 292, 301, 
	310, 319, 325, 336, 345, 351, 358, 367, 
	376, 385, 393, 402, 411, 420, 421, 428, 
	435, 438, 440, 442, 443, 445, 453, 462, 
	468, 475, 484, 493, 502, 510, 519, 526, 
	533, 542, 551, 560, 567
};

static const unsigned char _VBG_indicies[] = {
	0, 1, 2, 1, 3, 1, 4, 4, 
	4, 4, 4, 4, 1, 5, 5, 5, 
	5, 6, 1, 7, 7, 7, 7, 7, 
	1, 8, 8, 8, 8, 9, 1, 5, 
	5, 5, 5, 10, 1, 11, 11, 11, 
	11, 11, 1, 11, 12, 1, 11, 1, 
	13, 1, 11, 1, 14, 1, 11, 1, 
	11, 1, 5, 5, 5, 5, 6, 15, 
	1, 5, 5, 5, 5, 6, 16, 1, 
	4, 1, 17, 18, 1, 17, 1, 19, 
	1, 17, 1, 20, 1, 17, 1, 17, 
	1, 21, 22, 21, 23, 24, 1, 25, 
	26, 25, 27, 28, 29, 25, 30, 1, 
	31, 1, 31, 1, 32, 1, 31, 1, 
	31, 1, 33, 34, 1, 33, 1, 35, 
	1, 33, 1, 36, 1, 33, 1, 33, 
	1, 38, 39, 40, 41, 42, 43, 44, 
	45, 46, 47, 48, 49, 50, 51, 52, 
	53, 54, 55, 56, 57, 58, 59, 60, 
	37, 1, 1, 61, 62, 61, 61, 61, 
	61, 63, 63, 1, 64, 1, 65, 65, 
	65, 65, 65, 1, 67, 68, 67, 66, 
	66, 66, 67, 66, 67, 1, 69, 62, 
	69, 69, 69, 69, 63, 63, 1, 61, 
	61, 62, 61, 61, 61, 63, 63, 1, 
	66, 66, 68, 66, 70, 66, 66, 67, 
	67, 1, 71, 71, 71, 71, 71, 1, 
	72, 73, 74, 75, 76, 1, 72, 73, 
	74, 11, 75, 76, 1, 61, 61, 62, 
	61, 61, 77, 61, 63, 63, 1, 78, 
	61, 61, 61, 62, 61, 61, 63, 63, 
	1, 63, 79, 63, 61, 62, 61, 61, 
	63, 61, 63, 1, 7, 1, 61, 61, 
	61, 68, 61, 80, 61, 80, 67, 67, 
	1, 5, 61, 61, 61, 62, 61, 61, 
	63, 63, 1, 81, 81, 82, 62, 81, 
	81, 63, 63, 1, 81, 81, 81, 81, 
	62, 81, 63, 63, 1, 61, 61, 61, 
	61, 62, 61, 63, 63, 1, 61, 83, 
	61, 84, 62, 61, 63, 63, 1, 5, 
	5, 5, 5, 6, 1, 85, 86, 85, 
	5, 86, 5, 86, 6, 5, 85, 1, 
	87, 88, 89, 90, 91, 85, 85, 85, 
	1, 87, 92, 89, 93, 94, 1, 87, 
	92, 89, 17, 93, 94, 1, 87, 17, 
	88, 89, 90, 91, 85, 85, 1, 87, 
	20, 88, 89, 90, 91, 85, 85, 1, 
	95, 88, 89, 90, 91, 85, 85, 85, 
	1, 17, 87, 92, 89, 18, 93, 94, 
	1, 87, 97, 89, 98, 99, 96, 96, 
	96, 1, 66, 66, 66, 66, 100, 66, 
	67, 67, 1, 101, 102, 103, 61, 62, 
	61, 63, 63, 1, 104, 106, 106, 106, 
	106, 106, 106, 105, 107, 107, 107, 107, 
	107, 107, 1, 31, 108, 1, 31, 1, 
	109, 1, 105, 110, 104, 5, 5, 5, 
	112, 5, 6, 111, 1, 113, 114, 115, 
	116, 117, 111, 111, 111, 1, 113, 118, 
	115, 119, 120, 1, 113, 118, 115, 33, 
	119, 120, 1, 113, 33, 114, 115, 116, 
	117, 111, 111, 1, 113, 36, 114, 115, 
	116, 117, 111, 111, 1, 121, 114, 115, 
	116, 117, 111, 111, 111, 1, 33, 113, 
	118, 115, 34, 119, 120, 1, 113, 123, 
	115, 124, 125, 122, 122, 122, 1, 5, 
	5, 5, 5, 6, 111, 1, 4, 4, 
	4, 4, 4, 4, 1, 66, 66, 66, 
	66, 66, 68, 67, 67, 1, 81, 81, 
	81, 81, 81, 62, 63, 63, 1, 81, 
	81, 81, 81, 81, 62, 63, 63, 1, 
	126, 126, 126, 126, 126, 4, 1, 127, 
	127, 127, 127, 127, 129, 130, 128, 1, 
	0
};

static const char _VBG_trans_targs[] = {
	2, 0, 3, 41, 42, 42, 44, 42, 
	42, 44, 44, 51, 52, 13, 15, 42, 
	42, 68, 69, 23, 25, 77, 78, 83, 
	84, 42, 80, 29, 82, 31, 33, 42, 
	32, 87, 88, 37, 39, 4, 43, 46, 
	47, 48, 49, 53, 55, 56, 58, 60, 
	61, 19, 62, 63, 64, 75, 76, 95, 
	96, 97, 98, 99, 100, 5, 45, 42, 
	42, 6, 7, 42, 45, 8, 50, 9, 
	10, 11, 12, 14, 16, 54, 42, 57, 
	59, 17, 18, 65, 66, 67, 74, 20, 
	70, 22, 71, 72, 21, 24, 26, 73, 
	67, 70, 71, 72, 45, 27, 85, 94, 
	42, 42, 79, 28, 81, 30, 42, 86, 
	93, 34, 89, 36, 90, 91, 35, 38, 
	40, 92, 86, 89, 90, 91, 65, 65, 
	42, 42, 45
};

static const char _VBG_trans_actions[] = {
	0, 0, 0, 29, 23, 15, 15, 3, 
	46, 46, 40, 0, 0, 0, 0, 5, 
	34, 0, 0, 0, 0, 15, 15, 15, 
	15, 11, 11, 0, 11, 0, 0, 9, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 21, 
	0, 0, 0, 23, 0, 0, 19, 19, 
	7, 0, 0, 49, 49, 0, 49, 0, 
	0, 0, 0, 0, 0, 19, 17, 19, 
	49, 0, 0, 27, 27, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	25, 25, 25, 25, 56, 0, 9, 9, 
	13, 43, 43, 0, 9, 0, 37, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 7, 7, 7, 7, 23, 1, 
	31, 1, 52
};

static const char _VBG_eof_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 3, 0, 0, 3, 3, 
	3, 3, 0, 3, 3, 3, 0, 3, 
	3, 0, 3, 0, 3, 3, 3, 3, 
	3, 0, 0, 25, 25, 25, 25, 25, 
	25, 25, 25, 3, 3, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 7, 
	7, 7, 7, 7, 7, 7, 0, 0, 
	3, 3, 3, 0, 3
};

static const int VBG_start = 1;

void english_morpho_guesser::add_VBG(const string& form, vector<tagged_lemma>& lemmas) const {
  const char* p = form.c_str(); int cs;
  char best = 'z'; unsigned remove = 0; const char* append = nullptr;
  
	{
	cs = VBG_start;
	}

	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == ( (form.c_str() + form.size())) )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _VBG_trans_keys + _VBG_key_offsets[cs];
	_trans = _VBG_index_offsets[cs];

	_klen = _VBG_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( ( form[form.size() - 1 - (p - form.c_str())]) < *_mid )
				_upper = _mid - 1;
			else if ( ( form[form.size() - 1 - (p - form.c_str())]) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _VBG_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( ( form[form.size() - 1 - (p - form.c_str())]) < _mid[0] )
				_upper = _mid - 2;
			else if ( ( form[form.size() - 1 - (p - form.c_str())]) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _VBG_indicies[_trans];
	cs = _VBG_trans_targs[_trans];

	if ( _VBG_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _VBG_actions + _VBG_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
	{ if (best > 'a') best = 'a', remove = 3, append = nullptr; }
	break;
	case 1:
	{ if (best > 'b') best = 'b', remove = 3, append = "e";     }
	break;
	case 2:
	{ if (best > 'c') best = 'c', remove = 3, append = nullptr; }
	break;
	case 3:
	{ if (best > 'd') best = 'd', remove = 3, append = "e";     }
	break;
	case 4:
	{ if (best > 'e') best = 'e', remove = 3, append = nullptr; }
	break;
	case 5:
	{ if (best > 'f') best = 'f', remove = 3, append = "e";     }
	break;
	case 6:
	{ if (best > 'g') best = 'g', remove = 3, append = nullptr; }
	break;
	case 7:
	{ if (best > 'h') best = 'h', remove = 3, append = "e";     }
	break;
	case 8:
	{ if (best > 'i') best = 'i', remove = 3, append = nullptr; }
	break;
	case 9:
	{ if (best > 'j') best = 'j', remove = 3, append = "e";     }
	break;
	case 10:
	{ if (best > 'k') best = 'k', remove = 3, append = nullptr; }
	break;
	case 11:
	{ if (best > 'l') best = 'l', remove = 3, append = "e";     }
	break;
	case 12:
	{ if (best > 'm') best = 'm', remove = 3, append = nullptr; }
	break;
	case 13:
	{ if (best > 'n') best = 'n', remove = 3, append = "e";     }
	break;
	case 14:
	{ if (best > 'o') best = 'o', remove = 3, append = nullptr; }
	break;
	case 15:
	{ if (best > 'p') best = 'p', remove = 3, append = "e";     }
	break;
	case 16:
	{ if (best > 'q') best = 'q', remove = 3, append = nullptr; }
	break;
	case 17:
	{ if (best > 'r') best = 'r', remove = 3, append = "e";     }
	break;
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != ( (form.c_str() + form.size())) )
		goto _resume;
	_test_eof: {}
	if ( p == ( (form.c_str() + form.size())) )
	{
	const char *__acts = _VBG_actions + _VBG_eof_actions[cs];
	unsigned int __nacts = (unsigned int) *__acts++;
	while ( __nacts-- > 0 ) {
		switch ( *__acts++ ) {
	case 2:
	{ if (best > 'c') best = 'c', remove = 3, append = nullptr; }
	break;
	case 5:
	{ if (best > 'f') best = 'f', remove = 3, append = "e";     }
	break;
	case 15:
	{ if (best > 'p') best = 'p', remove = 3, append = "e";     }
	break;
		}
	}
	}

	_out: {}
	}

  add(VBG, form.substr(0, form.size() - remove).append(append ? append : ""), lemmas);
}

static const char _VBD_VBN_actions[] = {
	0, 1, 0, 1, 2, 1, 3, 1, 
	4, 1, 5, 1, 6, 1, 7, 1, 
	8, 1, 9, 1, 10, 1, 11, 1, 
	13, 1, 14, 1, 15, 1, 16, 1, 
	17, 2, 1, 16, 2, 4, 5, 2, 
	8, 16, 2, 9, 13, 2, 9, 14, 
	2, 12, 13, 2, 13, 14, 2, 15, 
	16, 3, 1, 3, 16, 3, 3, 15, 
	16
};

static const short _VBD_VBN_key_offsets[] = {
	0, 0, 2, 3, 9, 14, 24, 29, 
	34, 44, 46, 47, 48, 49, 50, 51, 
	52, 60, 67, 74, 76, 77, 78, 79, 
	80, 81, 82, 87, 95, 96, 97, 98, 
	99, 100, 102, 103, 104, 105, 106, 107, 
	108, 114, 115, 140, 140, 149, 150, 155, 
	166, 175, 184, 194, 199, 204, 210, 220, 
	220, 229, 241, 242, 253, 253, 262, 271, 
	280, 289, 298, 303, 316, 327, 332, 338, 
	348, 358, 369, 376, 387, 396, 405, 405, 
	416, 427, 429, 430, 431, 431, 432, 440, 
	451, 456, 462, 472, 482, 493, 500, 511, 
	518, 524, 533, 542, 551
};

static const char _VBD_VBN_trans_keys[] = {
	100, 110, 101, 97, 101, 105, 111, 117, 
	121, 97, 101, 105, 111, 117, 98, 100, 
	102, 104, 106, 110, 112, 116, 118, 122, 
	97, 101, 105, 111, 117, 97, 101, 105, 
	111, 117, 98, 100, 102, 104, 106, 110, 
	112, 116, 118, 122, 98, 114, 105, 114, 
	112, 105, 109, 101, 97, 101, 105, 111, 
	117, 121, 98, 122, 97, 101, 105, 111, 
	117, 98, 122, 97, 101, 105, 111, 117, 
	98, 122, 98, 114, 105, 114, 112, 105, 
	109, 101, 97, 101, 105, 111, 117, 97, 
	101, 105, 110, 111, 115, 117, 120, 105, 
	112, 105, 109, 101, 98, 114, 105, 114, 
	112, 105, 109, 101, 97, 101, 105, 111, 
	117, 121, 101, 98, 99, 100, 102, 103, 
	104, 105, 106, 107, 108, 109, 110, 112, 
	113, 114, 115, 116, 117, 118, 119, 120, 
	121, 122, 97, 111, 97, 98, 101, 105, 
	111, 117, 122, 99, 120, 113, 97, 101, 
	105, 111, 117, 98, 99, 100, 105, 111, 
	117, 122, 97, 101, 102, 120, 97, 100, 
	101, 105, 111, 117, 122, 98, 120, 97, 
	101, 102, 105, 111, 117, 122, 98, 120, 
	97, 101, 103, 105, 110, 111, 117, 122, 
	98, 120, 97, 101, 105, 111, 117, 101, 
	110, 111, 115, 120, 101, 110, 111, 112, 
	115, 120, 97, 101, 104, 105, 111, 116, 
	117, 122, 98, 120, 97, 101, 105, 106, 
	111, 117, 122, 98, 120, 98, 99, 100, 
	105, 107, 111, 117, 122, 97, 101, 102, 
	120, 105, 97, 101, 105, 108, 111, 114, 
	117, 119, 122, 98, 120, 97, 101, 105, 
	109, 111, 117, 122, 98, 120, 97, 101, 
	105, 110, 111, 117, 122, 98, 120, 97, 
	101, 105, 111, 112, 117, 122, 98, 120, 
	97, 101, 105, 111, 113, 117, 122, 98, 
	120, 97, 101, 105, 111, 114, 117, 122, 
	98, 120, 97, 101, 105, 111, 117, 98, 
	99, 100, 105, 108, 110, 111, 116, 117, 
	97, 101, 102, 122, 101, 110, 111, 115, 
	120, 98, 104, 106, 116, 118, 122, 101, 
	110, 111, 115, 120, 101, 110, 111, 112, 
	115, 120, 101, 105, 110, 111, 115, 120, 
	98, 116, 118, 122, 101, 105, 110, 111, 
	115, 120, 98, 116, 118, 122, 101, 110, 
	111, 115, 120, 98, 104, 106, 116, 118, 
	122, 98, 101, 110, 111, 114, 115, 120, 
	101, 110, 111, 115, 120, 98, 104, 106, 
	116, 118, 122, 97, 101, 105, 111, 115, 
	117, 122, 98, 120, 97, 101, 105, 111, 
	116, 117, 122, 98, 120, 122, 98, 100, 
	102, 104, 106, 110, 112, 116, 118, 120, 
	122, 98, 100, 102, 104, 106, 110, 112, 
	116, 118, 120, 98, 114, 112, 114, 113, 
	97, 101, 105, 108, 111, 117, 98, 122, 
	101, 110, 111, 115, 120, 98, 104, 106, 
	116, 118, 122, 101, 110, 111, 115, 120, 
	101, 110, 111, 112, 115, 120, 101, 105, 
	110, 111, 115, 120, 98, 116, 118, 122, 
	101, 105, 110, 111, 115, 120, 98, 116, 
	118, 122, 101, 110, 111, 115, 120, 98, 
	104, 106, 116, 118, 122, 98, 101, 110, 
	111, 114, 115, 120, 101, 110, 111, 115, 
	120, 98, 104, 106, 116, 118, 122, 97, 
	101, 105, 111, 117, 98, 122, 97, 101, 
	105, 111, 117, 121, 97, 101, 105, 111, 
	117, 118, 122, 98, 120, 97, 101, 105, 
	111, 117, 119, 122, 98, 120, 97, 101, 
	105, 111, 117, 120, 122, 98, 119, 97, 
	101, 105, 111, 117, 121, 122, 98, 120, 
	0
};

static const char _VBD_VBN_single_lengths[] = {
	0, 2, 1, 6, 5, 0, 5, 5, 
	0, 2, 1, 1, 1, 1, 1, 1, 
	6, 5, 5, 2, 1, 1, 1, 1, 
	1, 1, 5, 8, 1, 1, 1, 1, 
	1, 2, 1, 1, 1, 1, 1, 1, 
	6, 1, 23, 0, 7, 1, 5, 7, 
	7, 7, 8, 5, 5, 6, 8, 0, 
	7, 8, 1, 9, 0, 7, 7, 7, 
	7, 7, 5, 9, 5, 5, 6, 6, 
	6, 5, 7, 5, 7, 7, 0, 1, 
	1, 2, 1, 1, 0, 1, 6, 5, 
	5, 6, 6, 6, 5, 7, 5, 5, 
	6, 7, 7, 7, 7
};

static const char _VBD_VBN_range_lengths[] = {
	0, 0, 0, 0, 0, 5, 0, 0, 
	5, 0, 0, 0, 0, 0, 0, 0, 
	1, 1, 1, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 1, 0, 1, 0, 0, 2, 
	1, 1, 1, 0, 0, 0, 1, 0, 
	1, 2, 0, 1, 0, 1, 1, 1, 
	1, 1, 0, 2, 3, 0, 0, 2, 
	2, 3, 0, 3, 1, 1, 0, 5, 
	5, 0, 0, 0, 0, 0, 1, 3, 
	0, 0, 2, 2, 3, 0, 3, 1, 
	0, 1, 1, 1, 1
};

static const short _VBD_VBN_index_offsets[] = {
	0, 0, 3, 5, 12, 18, 24, 30, 
	36, 42, 45, 47, 49, 51, 53, 55, 
	57, 65, 72, 79, 82, 84, 86, 88, 
	90, 92, 94, 100, 109, 111, 113, 115, 
	117, 119, 122, 124, 126, 128, 130, 132, 
	134, 141, 143, 168, 169, 178, 180, 186, 
	196, 205, 214, 224, 230, 236, 243, 253, 
	254, 263, 274, 276, 287, 288, 297, 306, 
	315, 324, 333, 339, 351, 360, 366, 373, 
	382, 391, 400, 408, 417, 426, 435, 436, 
	443, 450, 453, 455, 457, 458, 460, 468, 
	477, 483, 490, 499, 508, 517, 525, 534, 
	541, 548, 557, 566, 575
};

static const unsigned char _VBD_VBN_indicies[] = {
	0, 2, 1, 3, 1, 4, 4, 4, 
	4, 4, 4, 1, 5, 5, 5, 5, 
	6, 1, 7, 7, 7, 7, 7, 1, 
	8, 8, 8, 8, 9, 1, 5, 5, 
	5, 5, 10, 1, 11, 11, 11, 11, 
	11, 1, 11, 12, 1, 11, 1, 13, 
	1, 11, 1, 14, 1, 11, 1, 11, 
	1, 4, 4, 4, 4, 4, 16, 15, 
	1, 5, 5, 5, 5, 6, 17, 1, 
	5, 5, 5, 5, 6, 18, 1, 19, 
	20, 1, 19, 1, 21, 1, 19, 1, 
	22, 1, 19, 1, 19, 1, 23, 24, 
	23, 25, 26, 1, 27, 28, 27, 29, 
	30, 31, 27, 32, 1, 33, 1, 33, 
	1, 34, 1, 33, 1, 33, 1, 35, 
	36, 1, 35, 1, 37, 1, 35, 1, 
	38, 1, 35, 1, 35, 1, 39, 39, 
	39, 39, 39, 4, 1, 40, 1, 42, 
	43, 44, 45, 46, 47, 48, 49, 50, 
	51, 52, 53, 54, 55, 56, 57, 58, 
	59, 60, 61, 62, 63, 64, 41, 1, 
	1, 65, 66, 65, 65, 65, 65, 4, 
	4, 1, 67, 1, 68, 68, 68, 68, 
	68, 1, 70, 71, 70, 69, 69, 69, 
	70, 69, 70, 1, 72, 66, 72, 72, 
	72, 72, 4, 4, 1, 65, 65, 66, 
	65, 65, 65, 4, 4, 1, 69, 69, 
	71, 69, 73, 69, 69, 70, 70, 1, 
	74, 74, 74, 74, 74, 1, 75, 76, 
	77, 78, 79, 1, 75, 76, 77, 11, 
	78, 79, 1, 65, 65, 66, 65, 65, 
	80, 65, 4, 4, 1, 81, 65, 65, 
	65, 66, 65, 65, 4, 4, 1, 4, 
	82, 4, 65, 66, 65, 65, 4, 65, 
	4, 1, 7, 1, 65, 65, 65, 71, 
	65, 83, 65, 83, 70, 70, 1, 5, 
	65, 65, 65, 66, 65, 65, 4, 4, 
	1, 84, 84, 85, 66, 84, 84, 4, 
	4, 1, 84, 84, 84, 84, 66, 84, 
	4, 4, 1, 65, 65, 65, 65, 66, 
	65, 4, 4, 1, 65, 86, 65, 87, 
	66, 65, 4, 4, 1, 5, 5, 5, 
	5, 6, 1, 88, 89, 88, 5, 89, 
	89, 5, 89, 6, 5, 88, 1, 90, 
	91, 92, 93, 94, 88, 88, 88, 1, 
	90, 95, 92, 96, 97, 1, 90, 95, 
	92, 19, 96, 97, 1, 90, 19, 91, 
	92, 93, 94, 88, 88, 1, 90, 22, 
	91, 92, 93, 94, 88, 88, 1, 98, 
	91, 92, 93, 94, 88, 88, 88, 1, 
	19, 90, 95, 92, 20, 96, 97, 1, 
	90, 100, 92, 101, 102, 99, 99, 99, 
	1, 69, 69, 69, 69, 103, 69, 70, 
	70, 1, 104, 105, 106, 65, 66, 65, 
	4, 4, 1, 107, 109, 109, 109, 109, 
	109, 109, 108, 110, 110, 110, 110, 110, 
	110, 1, 33, 111, 1, 33, 1, 112, 
	1, 108, 113, 107, 5, 5, 5, 115, 
	5, 6, 114, 1, 116, 117, 118, 119, 
	120, 114, 114, 114, 1, 116, 121, 118, 
	122, 123, 1, 116, 121, 118, 35, 122, 
	123, 1, 116, 35, 117, 118, 119, 120, 
	114, 114, 1, 116, 38, 117, 118, 119, 
	120, 114, 114, 1, 124, 117, 118, 119, 
	120, 114, 114, 114, 1, 35, 116, 121, 
	118, 36, 122, 123, 1, 116, 126, 118, 
	127, 128, 125, 125, 125, 1, 5, 5, 
	5, 5, 6, 114, 1, 4, 4, 4, 
	4, 4, 4, 1, 69, 69, 69, 69, 
	69, 71, 70, 70, 1, 84, 84, 84, 
	84, 84, 66, 4, 4, 1, 84, 84, 
	84, 84, 84, 66, 4, 4, 1, 129, 
	129, 129, 129, 129, 131, 132, 130, 1, 
	0
};

static const char _VBD_VBN_trans_targs[] = {
	2, 0, 41, 42, 43, 43, 45, 43, 
	43, 45, 45, 52, 53, 12, 14, 43, 
	43, 43, 43, 69, 70, 22, 24, 78, 
	79, 84, 85, 43, 81, 28, 83, 30, 
	32, 43, 31, 88, 89, 36, 38, 66, 
	43, 3, 44, 47, 48, 49, 50, 54, 
	16, 56, 57, 59, 61, 62, 63, 64, 
	65, 76, 77, 96, 97, 98, 99, 40, 
	100, 4, 46, 43, 5, 6, 43, 46, 
	7, 51, 8, 9, 10, 11, 13, 15, 
	55, 43, 58, 60, 17, 18, 66, 67, 
	68, 75, 19, 71, 21, 72, 73, 20, 
	23, 25, 74, 68, 71, 72, 73, 46, 
	26, 86, 95, 43, 43, 80, 27, 82, 
	29, 43, 87, 94, 33, 90, 35, 91, 
	92, 34, 37, 39, 93, 87, 90, 91, 
	92, 66, 43, 43, 46
};

static const char _VBD_VBN_trans_actions[] = {
	0, 0, 0, 31, 29, 25, 25, 5, 
	51, 51, 45, 0, 0, 0, 0, 15, 
	39, 9, 36, 0, 0, 0, 0, 25, 
	25, 25, 25, 21, 21, 0, 21, 0, 
	0, 19, 0, 0, 0, 0, 0, 29, 
	1, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 27, 0, 0, 0, 0, 
	0, 0, 29, 17, 0, 0, 54, 54, 
	0, 54, 0, 0, 0, 0, 0, 0, 
	29, 27, 29, 54, 0, 0, 13, 13, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 7, 7, 7, 7, 61, 
	0, 19, 19, 23, 48, 48, 0, 19, 
	0, 42, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 17, 17, 17, 
	17, 3, 33, 3, 57
};

static const char _VBD_VBN_eof_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 5, 0, 0, 5, 
	5, 5, 5, 0, 5, 5, 5, 0, 
	5, 5, 0, 5, 0, 5, 5, 5, 
	5, 5, 0, 0, 11, 11, 11, 11, 
	11, 11, 11, 11, 5, 5, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 17, 
	17, 17, 17, 17, 17, 17, 17, 0, 
	0, 5, 5, 5, 5
};

static const int VBD_VBN_start = 1;

void english_morpho_guesser::add_VBD_VBN(const string& form, vector<tagged_lemma>& lemmas) const {
  const char* p = form.c_str(); int cs;
  char best = 'z'; unsigned remove = 0; const char* append = nullptr;
  
	{
	cs = VBD_VBN_start;
	}

	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == ( (form.c_str() + form.size())) )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _VBD_VBN_trans_keys + _VBD_VBN_key_offsets[cs];
	_trans = _VBD_VBN_index_offsets[cs];

	_klen = _VBD_VBN_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( ( form[form.size() - 1 - (p - form.c_str())]) < *_mid )
				_upper = _mid - 1;
			else if ( ( form[form.size() - 1 - (p - form.c_str())]) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _VBD_VBN_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( ( form[form.size() - 1 - (p - form.c_str())]) < _mid[0] )
				_upper = _mid - 2;
			else if ( ( form[form.size() - 1 - (p - form.c_str())]) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _VBD_VBN_indicies[_trans];
	cs = _VBD_VBN_trans_targs[_trans];

	if ( _VBD_VBN_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _VBD_VBN_actions + _VBD_VBN_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
	{ if (best > 'a') best = 'a', remove = 1, append = nullptr; }
	break;
	case 1:
	{ if (best > 'b') best = 'b', remove = 2, append = nullptr; }
	break;
	case 2:
	{ if (best > 'c') best = 'c', remove = 1, append = nullptr; }
	break;
	case 3:
	{ if (best > 'd') best = 'd', remove = 2, append = nullptr; }
	break;
	case 4:
	{ if (best > 'e') best = 'e', remove = 1, append = nullptr; }
	break;
	case 5:
	{ if (best > 'f') best = 'f', remove = 2, append = nullptr; }
	break;
	case 7:
	{ if (best > 'h') best = 'h', remove = 2, append = nullptr; }
	break;
	case 8:
	{ if (best > 'i') best = 'i', remove = 3, append = "y";     }
	break;
	case 9:
	{ if (best > 'j') best = 'j', remove = 1, append = nullptr; }
	break;
	case 10:
	{ if (best > 'k') best = 'k', remove = 2, append = nullptr; }
	break;
	case 11:
	{ if (best > 'l') best = 'l', remove = 1, append = nullptr; }
	break;
	case 12:
	{ if (best > 'm') best = 'm', remove = 2, append = nullptr; }
	break;
	case 13:
	{ if (best > 'n') best = 'n', remove = 1, append = nullptr; }
	break;
	case 14:
	{ if (best > 'o') best = 'o', remove = 2, append = nullptr; }
	break;
	case 15:
	{ if (best > 'p') best = 'p', remove = 1, append = nullptr; }
	break;
	case 16:
	{ if (best > 'q') best = 'q', remove = 2, append = nullptr; }
	break;
	case 17:
	{ if (best > 'r') best = 'r', remove = 1, append = nullptr; }
	break;
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != ( (form.c_str() + form.size())) )
		goto _resume;
	_test_eof: {}
	if ( p == ( (form.c_str() + form.size())) )
	{
	const char *__acts = _VBD_VBN_actions + _VBD_VBN_eof_actions[cs];
	unsigned int __nacts = (unsigned int) *__acts++;
	while ( __nacts-- > 0 ) {
		switch ( *__acts++ ) {
	case 3:
	{ if (best > 'd') best = 'd', remove = 2, append = nullptr; }
	break;
	case 6:
	{ if (best > 'g') best = 'g', remove = 1, append = nullptr; }
	break;
	case 9:
	{ if (best > 'j') best = 'j', remove = 1, append = nullptr; }
	break;
		}
	}
	}

	_out: {}
	}

  add(VBD, VBN, form.substr(0, form.size() - remove).append(append ? append : ""), lemmas);
}

static const char _VBZ_actions[] = {
	0, 1, 0, 1, 1, 1, 2, 1, 
	3, 1, 4, 1, 5, 1, 6, 1, 
	7, 1, 8
};

static const char _VBZ_key_offsets[] = {
	0, 0, 1, 2, 4, 14, 14, 25, 
	26, 31, 31, 31, 31, 37, 45, 54
};

static const char _VBZ_trans_keys[] = {
	115, 101, 99, 115, 98, 100, 102, 104, 
	106, 110, 112, 116, 118, 122, 122, 98, 
	100, 102, 104, 106, 110, 112, 116, 118, 
	120, 111, 97, 101, 105, 111, 117, 104, 
	105, 111, 115, 120, 122, 97, 101, 105, 
	110, 111, 114, 115, 117, 97, 101, 105, 
	111, 117, 121, 122, 98, 120, 0
};

static const char _VBZ_single_lengths[] = {
	0, 1, 1, 2, 0, 0, 1, 1, 
	5, 0, 0, 0, 6, 8, 7, 0
};

static const char _VBZ_range_lengths[] = {
	0, 0, 0, 0, 5, 0, 5, 0, 
	0, 0, 0, 0, 0, 0, 1, 0
};

static const char _VBZ_index_offsets[] = {
	0, 0, 2, 4, 7, 13, 14, 21, 
	23, 29, 30, 31, 32, 39, 48, 57
};

static const char _VBZ_indicies[] = {
	0, 1, 3, 2, 4, 4, 1, 5, 
	5, 5, 5, 5, 1, 6, 7, 7, 
	7, 7, 7, 7, 1, 8, 1, 9, 
	9, 9, 9, 9, 1, 8, 10, 1, 
	11, 12, 13, 14, 4, 15, 1, 16, 
	16, 16, 17, 16, 18, 19, 16, 1, 
	20, 20, 20, 20, 20, 20, 22, 21, 
	1, 10, 0
};

static const char _VBZ_trans_targs[] = {
	2, 0, 11, 12, 11, 5, 11, 11, 
	11, 9, 11, 3, 4, 6, 13, 14, 
	11, 7, 8, 11, 11, 10, 15
};

static const char _VBZ_trans_actions[] = {
	0, 0, 17, 17, 11, 0, 13, 15, 
	9, 0, 3, 0, 0, 0, 11, 11, 
	1, 0, 0, 7, 5, 0, 7
};

static const int VBZ_start = 1;

void english_morpho_guesser::add_VBZ(const string& form, vector<tagged_lemma>& lemmas) const {
  const char* p = form.c_str(); int cs;
  char best = 'z'; unsigned remove = 0; const char* append = nullptr;
  
	{
	cs = VBZ_start;
	}

	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == ( (form.c_str() + form.size())) )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _VBZ_trans_keys + _VBZ_key_offsets[cs];
	_trans = _VBZ_index_offsets[cs];

	_klen = _VBZ_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( ( form[form.size() - 1 - (p - form.c_str())]) < *_mid )
				_upper = _mid - 1;
			else if ( ( form[form.size() - 1 - (p - form.c_str())]) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _VBZ_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( ( form[form.size() - 1 - (p - form.c_str())]) < _mid[0] )
				_upper = _mid - 2;
			else if ( ( form[form.size() - 1 - (p - form.c_str())]) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _VBZ_indicies[_trans];
	cs = _VBZ_trans_targs[_trans];

	if ( _VBZ_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _VBZ_actions + _VBZ_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
	{ if (best > 'a') best = 'a', remove = 1, append = nullptr; }
	break;
	case 1:
	{ if (best > 'b') best = 'b', remove = 2, append = nullptr; }
	break;
	case 2:
	{ if (best > 'c') best = 'c', remove = 1, append = nullptr; }
	break;
	case 3:
	{ if (best > 'd') best = 'd', remove = 2, append = nullptr; }
	break;
	case 4:
	{ if (best > 'e') best = 'e', remove = 1, append = nullptr; }
	break;
	case 5:
	{ if (best > 'f') best = 'f', remove = 2, append = nullptr; }
	break;
	case 6:
	{ if (best > 'g') best = 'g', remove = 3, append = "y";     }
	break;
	case 7:
	{ if (best > 'h') best = 'h', remove = 2, append = nullptr; }
	break;
	case 8:
	{ if (best > 'i') best = 'i', remove = 1, append = nullptr; }
	break;
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != ( (form.c_str() + form.size())) )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

  add(VBZ, form.substr(0, form.size() - remove).append(append ? append : ""), lemmas);
}

static const char _JJR_RBR_actions[] = {
	0, 1, 0, 1, 1, 1, 3, 1, 
	4, 1, 5, 2, 1, 4, 2, 2, 
	5, 2, 4, 5
};

static const unsigned char _JJR_RBR_key_offsets[] = {
	0, 0, 1, 2, 26, 26, 32, 37, 
	50, 56, 62, 73, 79, 85, 91, 102, 
	103, 109, 115, 117, 123, 129, 135, 146, 
	152, 163, 169, 175, 181
};

static const char _JJR_RBR_trans_keys[] = {
	114, 101, 98, 99, 100, 101, 102, 103, 
	104, 105, 106, 107, 108, 109, 110, 112, 
	113, 114, 115, 116, 117, 118, 119, 120, 
	121, 122, 97, 98, 101, 105, 111, 117, 
	97, 101, 105, 111, 117, 98, 99, 100, 
	105, 111, 117, 122, 97, 101, 102, 109, 
	112, 120, 97, 100, 101, 105, 111, 117, 
	97, 101, 102, 105, 111, 117, 97, 101, 
	103, 105, 111, 117, 122, 98, 109, 112, 
	120, 97, 101, 104, 105, 111, 117, 97, 
	101, 105, 106, 111, 117, 97, 101, 105, 
	107, 111, 117, 97, 101, 105, 108, 111, 
	117, 122, 98, 109, 112, 120, 101, 97, 
	101, 105, 109, 111, 117, 97, 101, 105, 
	110, 111, 117, 97, 122, 97, 101, 105, 
	111, 112, 117, 97, 101, 105, 111, 113, 
	117, 97, 101, 105, 111, 114, 117, 97, 
	101, 105, 111, 115, 117, 122, 98, 109, 
	112, 120, 97, 101, 105, 111, 116, 117, 
	97, 101, 105, 111, 117, 118, 122, 98, 
	109, 112, 120, 97, 101, 105, 111, 117, 
	119, 97, 101, 105, 111, 117, 120, 97, 
	101, 105, 111, 117, 121, 97, 101, 105, 
	111, 117, 122, 0
};

static const char _JJR_RBR_single_lengths[] = {
	0, 1, 1, 24, 0, 6, 5, 7, 
	6, 6, 7, 6, 6, 6, 7, 1, 
	6, 6, 0, 6, 6, 6, 7, 6, 
	7, 6, 6, 6, 6
};

static const char _JJR_RBR_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 3, 
	0, 0, 2, 0, 0, 0, 2, 0, 
	0, 0, 1, 0, 0, 0, 2, 0, 
	2, 0, 0, 0, 0
};

static const unsigned char _JJR_RBR_index_offsets[] = {
	0, 0, 2, 4, 29, 30, 37, 43, 
	54, 61, 68, 78, 85, 92, 99, 109, 
	111, 118, 125, 127, 134, 141, 148, 158, 
	165, 175, 182, 189, 196
};

static const char _JJR_RBR_indicies[] = {
	0, 1, 2, 1, 4, 5, 6, 7, 
	8, 9, 10, 11, 12, 13, 14, 15, 
	16, 17, 18, 19, 20, 21, 7, 22, 
	23, 24, 25, 26, 3, 1, 27, 28, 
	27, 27, 27, 27, 1, 29, 29, 29, 
	29, 29, 1, 30, 31, 30, 27, 27, 
	27, 30, 27, 30, 30, 1, 27, 28, 
	27, 27, 27, 27, 1, 27, 27, 28, 
	27, 27, 27, 1, 27, 27, 31, 27, 
	27, 27, 30, 30, 30, 1, 27, 27, 
	28, 27, 27, 27, 1, 27, 27, 27, 
	28, 27, 27, 1, 27, 27, 27, 28, 
	27, 27, 1, 27, 27, 27, 32, 27, 
	27, 30, 30, 30, 1, 1, 33, 27, 
	27, 27, 28, 27, 27, 1, 34, 34, 
	34, 28, 34, 34, 1, 29, 1, 34, 
	34, 34, 34, 28, 34, 1, 27, 27, 
	27, 27, 28, 27, 1, 27, 27, 27, 
	27, 28, 27, 1, 27, 27, 27, 27, 
	31, 27, 30, 30, 30, 1, 27, 27, 
	27, 27, 28, 27, 1, 27, 27, 27, 
	27, 27, 31, 30, 30, 30, 1, 34, 
	34, 34, 34, 34, 28, 1, 34, 34, 
	34, 34, 34, 28, 1, 27, 27, 27, 
	27, 27, 28, 1, 27, 27, 27, 27, 
	27, 28, 1, 0
};

static const char _JJR_RBR_trans_targs[] = {
	2, 0, 3, 4, 5, 7, 8, 4, 
	9, 10, 11, 4, 12, 13, 14, 16, 
	17, 19, 20, 21, 22, 23, 24, 25, 
	26, 27, 28, 6, 4, 4, 4, 4, 
	15, 4, 18
};

static const char _JJR_RBR_trans_actions[] = {
	0, 0, 0, 9, 9, 9, 9, 17, 
	9, 9, 9, 14, 9, 9, 9, 9, 
	9, 9, 9, 9, 9, 9, 9, 9, 
	9, 9, 9, 7, 3, 5, 7, 11, 
	11, 1, 7
};

static const int JJR_RBR_start = 1;

void english_morpho_guesser::add_JJR_RBR(const string& form, unsigned negation_len, vector<tagged_lemma>& lemmas) const {
  const char* p = form.c_str() + negation_len; int cs;
  char best = 'z'; unsigned remove = 0; const char* append = nullptr;
  
	{
	cs = JJR_RBR_start;
	}

	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == ( (form.c_str() + form.size())) )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JJR_RBR_trans_keys + _JJR_RBR_key_offsets[cs];
	_trans = _JJR_RBR_index_offsets[cs];

	_klen = _JJR_RBR_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( ( form[form.size() - 1 - (p - form.c_str() - negation_len)]) < *_mid )
				_upper = _mid - 1;
			else if ( ( form[form.size() - 1 - (p - form.c_str() - negation_len)]) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JJR_RBR_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( ( form[form.size() - 1 - (p - form.c_str() - negation_len)]) < _mid[0] )
				_upper = _mid - 2;
			else if ( ( form[form.size() - 1 - (p - form.c_str() - negation_len)]) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JJR_RBR_indicies[_trans];
	cs = _JJR_RBR_trans_targs[_trans];

	if ( _JJR_RBR_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JJR_RBR_actions + _JJR_RBR_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
	{ if (best > 'a') best = 'a', remove = 2, append = nullptr; }
	break;
	case 1:
	{ if (best > 'b') best = 'b', remove = 3, append = nullptr; }
	break;
	case 2:
	{ if (best > 'c') best = 'c', remove = 3, append = "y";     }
	break;
	case 3:
	{ if (best > 'd') best = 'd', remove = 2, append = nullptr; }
	break;
	case 4:
	{ if (best > 'e') best = 'e', remove = 1, append = nullptr; }
	break;
	case 5:
	{ if (best > 'f') best = 'f', remove = 2, append = nullptr; }
	break;
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != ( (form.c_str() + form.size())) )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

  add(JJR, RBR, form.substr(0, form.size() - remove).append(append ? append : ""), negation_len, lemmas);
}

static const char _JJS_RBS_actions[] = {
	0, 1, 1, 1, 2, 1, 4, 1, 
	5, 2, 0, 5, 2, 1, 4, 2, 
	3, 5
};

static const unsigned char _JJS_RBS_key_offsets[] = {
	0, 0, 1, 2, 3, 25, 25, 25, 
	31, 44, 50, 56, 67, 73, 79, 85, 
	96, 102, 108, 114, 120, 126, 137, 143, 
	154, 160, 166, 172, 178, 178, 183, 183, 
	183, 184
};

static const char _JJS_RBS_trans_keys[] = {
	116, 115, 101, 98, 99, 100, 102, 103, 
	104, 105, 106, 107, 108, 109, 110, 112, 
	113, 114, 115, 116, 118, 119, 120, 121, 
	122, 97, 98, 101, 105, 111, 117, 98, 
	99, 100, 105, 111, 117, 122, 97, 101, 
	102, 109, 112, 120, 97, 100, 101, 105, 
	111, 117, 97, 101, 102, 105, 111, 117, 
	97, 101, 103, 105, 111, 117, 122, 98, 
	109, 112, 120, 97, 101, 104, 105, 111, 
	117, 97, 101, 105, 106, 111, 117, 97, 
	101, 105, 107, 111, 117, 97, 101, 105, 
	108, 111, 117, 122, 98, 109, 112, 120, 
	97, 101, 105, 109, 111, 117, 97, 101, 
	105, 110, 111, 117, 97, 101, 105, 111, 
	112, 117, 97, 101, 105, 111, 113, 117, 
	97, 101, 105, 111, 114, 117, 97, 101, 
	105, 111, 115, 117, 122, 98, 109, 112, 
	120, 97, 101, 105, 111, 116, 117, 97, 
	101, 105, 111, 117, 118, 122, 98, 109, 
	112, 120, 97, 101, 105, 111, 117, 119, 
	97, 101, 105, 111, 117, 120, 97, 101, 
	105, 111, 117, 121, 97, 101, 105, 111, 
	117, 122, 97, 101, 105, 111, 117, 101, 
	97, 122, 0
};

static const char _JJS_RBS_single_lengths[] = {
	0, 1, 1, 1, 22, 0, 0, 6, 
	7, 6, 6, 7, 6, 6, 6, 7, 
	6, 6, 6, 6, 6, 7, 6, 7, 
	6, 6, 6, 6, 0, 5, 0, 0, 
	1, 0
};

static const char _JJS_RBS_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	3, 0, 0, 2, 0, 0, 0, 2, 
	0, 0, 0, 0, 0, 2, 0, 2, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 1
};

static const unsigned char _JJS_RBS_index_offsets[] = {
	0, 0, 2, 4, 6, 29, 30, 31, 
	38, 49, 56, 63, 73, 80, 87, 94, 
	104, 111, 118, 125, 132, 139, 149, 156, 
	166, 173, 180, 187, 194, 195, 201, 202, 
	203, 205
};

static const char _JJS_RBS_indicies[] = {
	0, 1, 2, 1, 3, 1, 5, 6, 
	7, 8, 9, 10, 11, 12, 13, 14, 
	15, 16, 17, 18, 19, 20, 21, 22, 
	23, 24, 25, 26, 4, 27, 28, 29, 
	30, 29, 29, 29, 29, 27, 31, 32, 
	31, 29, 29, 29, 31, 29, 31, 31, 
	27, 29, 30, 29, 29, 29, 29, 27, 
	29, 29, 30, 29, 29, 29, 27, 29, 
	29, 32, 29, 29, 29, 31, 31, 31, 
	27, 29, 29, 30, 29, 29, 29, 27, 
	29, 29, 29, 30, 29, 29, 27, 29, 
	29, 29, 30, 29, 29, 27, 29, 29, 
	29, 33, 29, 29, 31, 31, 31, 27, 
	29, 29, 29, 30, 29, 29, 27, 34, 
	34, 34, 30, 34, 34, 27, 34, 34, 
	34, 34, 30, 34, 27, 29, 29, 29, 
	29, 30, 29, 27, 29, 29, 29, 29, 
	30, 29, 27, 29, 29, 29, 29, 32, 
	29, 31, 31, 31, 27, 29, 29, 29, 
	29, 30, 29, 27, 29, 29, 29, 29, 
	29, 32, 31, 31, 31, 27, 34, 34, 
	34, 34, 34, 30, 27, 34, 34, 34, 
	34, 34, 30, 27, 29, 29, 29, 29, 
	29, 30, 27, 29, 29, 29, 29, 29, 
	30, 27, 1, 35, 35, 35, 35, 35, 
	28, 28, 27, 28, 36, 35, 28, 0
};

static const char _JJS_RBS_trans_targs[] = {
	2, 0, 3, 4, 5, 7, 8, 9, 
	10, 11, 12, 31, 13, 14, 15, 16, 
	17, 18, 19, 20, 21, 22, 23, 24, 
	25, 26, 27, 6, 28, 29, 30, 30, 
	30, 32, 33, 28, 28
};

static const char _JJS_RBS_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 3, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 7, 5, 1, 5, 
	12, 12, 5, 15, 9
};

static const int JJS_RBS_start = 1;

void english_morpho_guesser::add_JJS_RBS(const string& form, unsigned negation_len, vector<tagged_lemma>& lemmas) const {
  const char* p = form.c_str() + negation_len; int cs;
  char best = 'z'; unsigned remove = 0; const char* append = nullptr;
  
	{
	cs = JJS_RBS_start;
	}

	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == ( (form.c_str() + form.size())) )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JJS_RBS_trans_keys + _JJS_RBS_key_offsets[cs];
	_trans = _JJS_RBS_index_offsets[cs];

	_klen = _JJS_RBS_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( ( form[form.size() - 1 - (p - form.c_str() - negation_len)]) < *_mid )
				_upper = _mid - 1;
			else if ( ( form[form.size() - 1 - (p - form.c_str() - negation_len)]) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JJS_RBS_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( ( form[form.size() - 1 - (p - form.c_str() - negation_len)]) < _mid[0] )
				_upper = _mid - 2;
			else if ( ( form[form.size() - 1 - (p - form.c_str() - negation_len)]) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JJS_RBS_indicies[_trans];
	cs = _JJS_RBS_trans_targs[_trans];

	if ( _JJS_RBS_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JJS_RBS_actions + _JJS_RBS_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
	{ if (best > 'a') best = 'a', remove = 3, append = nullptr; }
	break;
	case 1:
	{ if (best > 'b') best = 'b', remove = 4, append = nullptr; }
	break;
	case 2:
	{ if (best > 'c') best = 'c', remove = 4, append = "y";     }
	break;
	case 3:
	{ if (best > 'd') best = 'd', remove = 3, append = nullptr; }
	break;
	case 4:
	{ if (best > 'e') best = 'e', remove = 2, append = nullptr; }
	break;
	case 5:
	{ if (best > 'f') best = 'f', remove = 3, append = nullptr; }
	break;
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != ( (form.c_str() + form.size())) )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

  add(JJS, RBS, form.substr(0, form.size() - remove).append(append ? append : ""), negation_len, lemmas);
}

/////////
// File: morpho/external_morpho.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class external_morpho : public morpho {
 public:
  external_morpho(unsigned version) : version(version) {}

  virtual int analyze(string_piece form, morpho::guesser_mode guesser, vector<tagged_lemma>& lemmas) const override;
  virtual int generate(string_piece lemma, const char* tag_wildcard, guesser_mode guesser, vector<tagged_lemma_forms>& forms) const override;
  virtual int raw_lemma_len(string_piece lemma) const override;
  virtual int lemma_id_len(string_piece lemma) const override;
  virtual int raw_form_len(string_piece form) const override;
  virtual tokenizer* new_tokenizer() const override;

  bool load(istream& is);

 private:
  unsigned version;

  string unknown_tag;
};

/////////
// File: tokenizer/generic_tokenizer.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class generic_tokenizer : public ragel_tokenizer {
 public:
  enum { LATEST = 2 };
  generic_tokenizer(unsigned version);

  virtual bool next_sentence(vector<token_range>& tokens) override;
};

/////////
// File: morpho/external_morpho.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

bool external_morpho::load(istream& is) {
  binary_decoder data;
  if (!compressor::load(is, data)) return false;

  try {
    // Load unknown_tag
    unsigned length = data.next_1B();
    unknown_tag.assign(data.next<char>(length), length);
  } catch (binary_decoder_error&) {
    return false;
  }

  return data.is_end();
}

int external_morpho::analyze(string_piece form, guesser_mode /*guesser*/, vector<tagged_lemma>& lemmas) const {
  lemmas.clear();

  if (form.len) {
    // Start by skipping the first form
    string_piece lemmatags = form;
    while (lemmatags.len && *lemmatags.str != ' ') lemmatags.len--, lemmatags.str++;
    if (lemmatags.len) lemmatags.len--, lemmatags.str++;

    // Split lemmatags using ' ' into lemma-tag pairs.
    while (lemmatags.len) {
      auto lemma_start = lemmatags.str;
      while (lemmatags.len && *lemmatags.str != ' ') lemmatags.len--, lemmatags.str++;
      if (!lemmatags.len) break;
      auto lemma_len = lemmatags.str - lemma_start;
      lemmatags.len--, lemmatags.str++;

      auto tag_start = lemmatags.str;
      while (lemmatags.len && *lemmatags.str != ' ') lemmatags.len--, lemmatags.str++;
      auto tag_len = lemmatags.str - tag_start;
      if (lemmatags.len) lemmatags.len--, lemmatags.str++;

      lemmas.emplace_back(string(lemma_start, lemma_len), string(tag_start, tag_len));
    }

    if (!lemmas.empty()) return NO_GUESSER;
  }

  lemmas.emplace_back(string(form.str, form.len), unknown_tag);
  return -1;
}

int external_morpho::generate(string_piece lemma, const char* tag_wildcard, morpho::guesser_mode /*guesser*/, vector<tagged_lemma_forms>& forms) const {
  forms.clear();

  tag_filter filter(tag_wildcard);

  if (lemma.len) {
    // Start by locating the lemma
    string_piece formtags = lemma;
    while (formtags.len && *formtags.str != ' ') formtags.len--, formtags.str++;
    string_piece real_lemma(lemma.str, lemma.len - formtags.len);
    if (formtags.len) formtags.len--, formtags.str++;

    // Split formtags using ' ' into form-tag pairs.
    bool any_result = false;
    while (formtags.len) {
      auto form_start = formtags.str;
      while (formtags.len && *formtags.str != ' ') formtags.len--, formtags.str++;
      if (!formtags.len) break;
      auto form_len = formtags.str - form_start;
      formtags.len--, formtags.str++;

      auto tag_start = formtags.str;
      while (formtags.len && *formtags.str != ' ') formtags.len--, formtags.str++;
      auto tag_len = formtags.str - tag_start;
      if (formtags.len) formtags.len--, formtags.str++;

      any_result = true;
      string tag(tag_start, tag_len);
      if (filter.matches(tag.c_str())) {
        if (forms.empty()) forms.emplace_back(string(real_lemma.str, real_lemma.len));
        forms.back().forms.emplace_back(string(form_start, form_len), tag);
      }
    }

    if (any_result) return NO_GUESSER;
  }

  return -1;
}

int external_morpho::raw_lemma_len(string_piece lemma) const {
  unsigned lemma_len = 0;
  while (lemma_len < lemma.len && lemma.str[lemma_len] != ' ') lemma_len++;
  return lemma_len;
}

int external_morpho::lemma_id_len(string_piece lemma) const {
  unsigned lemma_len = 0;
  while (lemma_len < lemma.len && lemma.str[lemma_len] != ' ') lemma_len++;
  return lemma_len;
}

int external_morpho::raw_form_len(string_piece form) const {
  unsigned form_len = 0;
  while (form_len < form.len && form.str[form_len] != ' ') form_len++;
  return form_len;
}

tokenizer* external_morpho::new_tokenizer() const {
  return new generic_tokenizer(version);
}

/////////
// File: morpho/generic_lemma_addinfo.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
struct generic_lemma_addinfo {
  inline static int raw_lemma_len(string_piece lemma);
  inline static int lemma_id_len(string_piece lemma);
  inline static string format(const unsigned char* addinfo, int addinfo_len);
  inline static bool generatable(const unsigned char* addinfo, int addinfo_len);

  inline int parse(string_piece lemma, bool die_on_failure = false);
  inline bool match_lemma_id(const unsigned char* other_addinfo, int other_addinfo_len);

  vector<unsigned char> data;
};

// Definitions
int generic_lemma_addinfo::raw_lemma_len(string_piece lemma) {
  return lemma.len;
}

int generic_lemma_addinfo::lemma_id_len(string_piece lemma) {
  return lemma.len;
}

string generic_lemma_addinfo::format(const unsigned char* /*addinfo*/, int /*addinfo_len*/) {
  return string();
}

bool generic_lemma_addinfo::generatable(const unsigned char* /*addinfo*/, int /*addinfo_len*/) {
  return true;
}

int generic_lemma_addinfo::parse(string_piece lemma, bool /*die_on_failure*/) {
  return lemma.len;
}

bool generic_lemma_addinfo::match_lemma_id(const unsigned char* /*other_addinfo*/, int /*other_addinfo_len*/) {
  return true;
}

/////////
// File: morpho/generic_morpho.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class generic_morpho : public morpho {
 public:
  generic_morpho(unsigned version) : version(version) {}

  virtual int analyze(string_piece form, morpho::guesser_mode guesser, vector<tagged_lemma>& lemmas) const override;
  virtual int generate(string_piece lemma, const char* tag_wildcard, guesser_mode guesser, vector<tagged_lemma_forms>& forms) const override;
  virtual int raw_lemma_len(string_piece lemma) const override;
  virtual int lemma_id_len(string_piece lemma) const override;
  virtual int raw_form_len(string_piece form) const override;
  virtual tokenizer* new_tokenizer() const override;

  bool load(istream& is);
 private:
  inline void analyze_special(string_piece form, vector<tagged_lemma>& lemmas) const;

  unsigned version;
  morpho_dictionary<generic_lemma_addinfo> dictionary;
  unique_ptr<morpho_statistical_guesser> statistical_guesser;

  string unknown_tag, number_tag, punctuation_tag, symbol_tag;
};

/////////
// File: morpho/generic_morpho.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

bool generic_morpho::load(istream& is) {
  binary_decoder data;
  if (!compressor::load(is, data)) return false;

  try {
    // Load tags
    unsigned length = data.next_1B();
    unknown_tag.assign(data.next<char>(length), length);
    length = data.next_1B();
    number_tag.assign(data.next<char>(length), length);
    length = data.next_1B();
    punctuation_tag.assign(data.next<char>(length), length);
    length = data.next_1B();
    symbol_tag.assign(data.next<char>(length), length);

    // Load dictionary
    dictionary.load(data);

    // Optionally statistical guesser if present
    statistical_guesser.reset();
    if (data.next_1B()) {
      statistical_guesser.reset(new morpho_statistical_guesser());
      statistical_guesser->load(data);
    }
  } catch (binary_decoder_error&) {
    return false;
  }

  return data.is_end();
}

int generic_morpho::analyze(string_piece form, guesser_mode guesser, vector<tagged_lemma>& lemmas) const {
  lemmas.clear();

  if (form.len) {
    // Generate all casing variants if needed (they are different than given form).
    string form_uclc; // first uppercase, rest lowercase
    string form_lc;   // all lowercase
    generate_casing_variants(form, form_uclc, form_lc);

    // Start by analysing using the dictionary and all casing variants.
    dictionary.analyze(form, lemmas);
    if (!form_uclc.empty()) dictionary.analyze(form_uclc, lemmas);
    if (!form_lc.empty()) dictionary.analyze(form_lc, lemmas);
    if (!lemmas.empty()) return NO_GUESSER;

    // Then call analyze_special to handle numbers, punctuation and symbols.
    analyze_special(form, lemmas);
    if (!lemmas.empty()) return NO_GUESSER;

    // For the statistical guesser, use all casing variants.
    if (guesser == GUESSER && statistical_guesser) {
      if (form_uclc.empty() && form_lc.empty())
        statistical_guesser->analyze(form, lemmas, nullptr);
      else {
        morpho_statistical_guesser::used_rules used_rules; used_rules.reserve(3);
        statistical_guesser->analyze(form, lemmas, &used_rules);
        if (!form_uclc.empty()) statistical_guesser->analyze(form_uclc, lemmas, &used_rules);
        if (!form_lc.empty()) statistical_guesser->analyze(form_lc, lemmas, &used_rules);
      }
    }
    if (!lemmas.empty()) return GUESSER;
  }

  lemmas.emplace_back(string(form.str, form.len), unknown_tag);
  return -1;
}

int generic_morpho::generate(string_piece lemma, const char* tag_wildcard, morpho::guesser_mode /*guesser*/, vector<tagged_lemma_forms>& forms) const {
  forms.clear();

  tag_filter filter(tag_wildcard);

  if (lemma.len) {
    if (dictionary.generate(lemma, filter, forms))
      return NO_GUESSER;
  }

  return -1;
}

int generic_morpho::raw_lemma_len(string_piece lemma) const {
  return generic_lemma_addinfo::raw_lemma_len(lemma);
}

int generic_morpho::lemma_id_len(string_piece lemma) const {
  return generic_lemma_addinfo::lemma_id_len(lemma);
}

int generic_morpho::raw_form_len(string_piece form) const {
  return form.len;
}

tokenizer* generic_morpho::new_tokenizer() const {
  return new generic_tokenizer(version);
}

void generic_morpho::analyze_special(string_piece form, vector<tagged_lemma>& lemmas) const {
  using namespace unilib;

  // Analyzer for numbers, punctuation and symbols.
  // Number is anything matching [+-]? is_Pn* ([.,] is_Pn*)? ([Ee] [+-]? is_Pn+)? for at least one is_Pn* nonempty.
  // Punctuation is any form beginning with either unicode punctuation or punctuation_exceptions character.
  // Beware that numbers takes precedence, so - is punctuation, -3 is number, -. is punctuation, -.3 is number.
  if (!form.len) return;

  string_piece number = form;
  char32_t first = utf8::decode(number.str, number.len);

  // Try matching a number.
  char32_t codepoint = first;
  bool any_digit = false;
  if (codepoint == '+' || codepoint == '-') codepoint = utf8::decode(number.str, number.len);
  while (unicode::category(codepoint) & unicode::N) any_digit = true, codepoint = utf8::decode(number.str, number.len);
  if ((codepoint == '.' && number.len) || codepoint == ',') codepoint = utf8::decode(number.str, number.len);
  while (unicode::category(codepoint) & unicode::N) any_digit = true, codepoint = utf8::decode(number.str, number.len);
  if (any_digit && (codepoint == 'e' || codepoint == 'E')) {
    codepoint = utf8::decode(number.str, number.len);
    if (codepoint == '+' || codepoint == '-') codepoint = utf8::decode(number.str, number.len);
    any_digit = false;
    while (unicode::category(codepoint) & unicode::N) any_digit = true, codepoint = utf8::decode(number.str, number.len);
  }

  if (any_digit && !number.len && (!codepoint || codepoint == '.')) {
    lemmas.emplace_back(string(form.str, form.len - (codepoint == '.')), number_tag);
    return;
  }

  // Try matching punctuation or symbol.
  bool punctuation = true, symbol = true;
  string_piece form_ori = form;
  while (form.len) {
    codepoint = utf8::decode(form.str, form.len);
    punctuation = punctuation && unicode::category(codepoint) & unicode::P;
    symbol = symbol && unicode::category(codepoint) & unicode::S;
  }
  if (punctuation)
    lemmas.emplace_back(string(form_ori.str, form_ori.len), punctuation_tag);
  else if (symbol)
    lemmas.emplace_back(string(form_ori.str, form_ori.len), symbol_tag);
}

/////////
// File: morpho/morpho_ids.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class morpho_ids {
 public:
  enum morpho_id {
    CZECH = 0,
    ENGLISH_V1 = 1,
    GENERIC = 2,
    EXTERNAL = 3,
    ENGLISH_V2 = 4,
    ENGLISH_V3 = 5, ENGLISH = ENGLISH_V3,
    SLOVAK_PDT = 6,
    DERIVATOR_DICTIONARY = 7,
  };

  static bool parse(const string& str, morpho_id& id) {
    if (str == "czech") return id = CZECH, true;
    if (str == "english") return id = ENGLISH, true;
    if (str == "external") return id = EXTERNAL, true;
    if (str == "generic") return id = GENERIC, true;
    if (str == "slovak_pdt") return id = SLOVAK_PDT, true;
    return false;
  }
};

typedef morpho_ids::morpho_id morpho_id;

/////////
// File: utils/new_unique_ptr.h
/////////

// This file is part of UFAL C++ Utils <http://github.com/ufal/cpp_utils/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

namespace utils {

template<typename T, typename... Args>
unique_ptr<T> new_unique_ptr(Args&&... args) {
  return unique_ptr<T>(new T(std::forward<Args>(args)...));
}

} // namespace utils

/////////
// File: morpho/morpho.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

morpho* morpho::load(istream& is) {
  morpho_id id = morpho_id(is.get());
  switch (id) {
    case morpho_ids::CZECH:
      {
        auto res = new_unique_ptr<czech_morpho>(czech_morpho::morpho_language::CZECH, 1);
        if (res->load(is)) return res.release();
        break;
      }
    case morpho_ids::ENGLISH_V1:
    case morpho_ids::ENGLISH_V2:
    case morpho_ids::ENGLISH_V3:
      {
        auto res = new_unique_ptr<english_morpho>(id == morpho_ids::ENGLISH_V1 ? 1 :
                                                  id == morpho_ids::ENGLISH_V2 ? 2 :
                                                  3);
        if (res->load(is)) return res.release();
        break;
      }
    case morpho_ids::EXTERNAL:
      {
        auto res = new_unique_ptr<external_morpho>(1);
        if (res->load(is)) return res.release();
        break;
      }
    case morpho_ids::GENERIC:
      {
        auto res = new_unique_ptr<generic_morpho>(1);
        if (res->load(is)) return res.release();
        break;
      }
    case morpho_ids::SLOVAK_PDT:
      {
        auto res = new_unique_ptr<czech_morpho>(czech_morpho::morpho_language::SLOVAK, 3);
        if (res->load(is)) return res.release();
        break;
      }
    case morpho_ids::DERIVATOR_DICTIONARY:
      {
        auto derinet = new_unique_ptr<derivator_dictionary>();
        if (!derinet->load(is)) return nullptr;

        unique_ptr<morpho> dictionary(load(is));
        if (!dictionary) return nullptr;
        derinet->dictionary = dictionary.get();
        dictionary->derinet.reset(derinet.release());
        return dictionary.release();
      }
  }

  return nullptr;
}

morpho* morpho::load(const char* fname) {
  ifstream f(fname, ifstream::binary);
  if (!f) return nullptr;

  return load(f);
}

const derivator* morpho::get_derivator() const {
  return derinet.get();
}

/////////
// File: morpho/morpho_statistical_guesser.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

void morpho_statistical_guesser::load(binary_decoder& data) {
  // Load tags and default tag
  tags.resize(data.next_2B());
  for (auto&& tag : tags) {
    tag.resize(data.next_1B());
    for (unsigned i = 0; i < tag.size(); i++)
      tag[i] = data.next_1B();
  }
  default_tag = data.next_2B();

  // Load rules
  rules.load(data);
}

// Helper method for analyze.
static bool contains(morpho_statistical_guesser::used_rules* used, const string& rule) {
  if (!used) return false;

  for (auto&& used_rule : *used)
    if (used_rule == rule)
      return true;

  return false;
}

// Produces unique lemma-tag pairs.
void morpho_statistical_guesser::analyze(string_piece form, vector<tagged_lemma>& lemmas, morpho_statistical_guesser::used_rules* used) {
  unsigned lemmas_initial_size = lemmas.size();

  // We have rules in format "suffix prefix" in rules.
  // Find the matching rule with longest suffix and of those with longest prefix.
  string rule_label; rule_label.reserve(12);
  unsigned suffix_len = 0;
  for (; suffix_len < form.len; suffix_len++) {
    rule_label.push_back(form.str[form.len - (suffix_len + 1)]);
    if (!rules.at(rule_label.c_str(), rule_label.size(), [](pointer_decoder& data){ data.next<char>(data.next_2B()); }))
      break;
  }

  for (suffix_len++; suffix_len--; ) {
    rule_label.resize(suffix_len);
    rule_label.push_back(' ');

    const unsigned char* rule = nullptr;
    unsigned rule_prefix_len = 0;
    for (unsigned prefix_len = 0; prefix_len + suffix_len <= form.len; prefix_len++) {
      if (prefix_len) rule_label.push_back(form.str[prefix_len - 1]);
      const unsigned char* found = rules.at(rule_label.c_str(), rule_label.size(), [](pointer_decoder& data){ data.next<char>(data.next_2B()); });
      if (!found) break;
      if (*(found += sizeof(uint16_t))) {
        rule = found;
        rule_prefix_len = prefix_len;
      }
    }

    if (rule) {
      rule_label.resize(suffix_len + 1 + rule_prefix_len);
      if (rule_label.size() > 1 && !contains(used, rule_label)) { // ignore rule ' '
        if (used) used->push_back(rule_label);
        for (int rules_len = *rule++; rules_len; rules_len--) {
          unsigned pref_del_len = *rule++; const char* pref_del = (const char*)rule; rule += pref_del_len;
          unsigned pref_add_len = *rule++; const char* pref_add = (const char*)rule; rule += pref_add_len;
          unsigned suff_del_len = *rule++; const char* suff_del = (const char*)rule; rule += suff_del_len;
          unsigned suff_add_len = *rule++; const char* suff_add = (const char*)rule; rule += suff_add_len;
          unsigned tags_len = *rule++; const uint16_t* tags = (const uint16_t*)rule; rule += tags_len * sizeof(uint16_t);

          if (pref_del_len + suff_del_len > form.len ||
              (pref_del_len && !small_memeq(pref_del, form.str, pref_del_len)) ||
              (suff_del_len && !small_memeq(suff_del, form.str + form.len - suff_del_len, suff_del_len)))
            continue;

          string lemma;
          lemma.reserve(form.len + pref_add_len - pref_del_len + suff_add_len - suff_del_len);
          if (pref_add_len) lemma.append(pref_add, pref_add_len);
          if (pref_del_len + suff_del_len < form.len) lemma.append(form.str + pref_del_len, form.len - pref_del_len - suff_del_len);
          if (suff_add_len) lemma.append(suff_add, suff_add_len);
          while (tags_len--)
            lemmas.emplace_back(lemma, this->tags[*tags++]);
        }
      }
      break;
    }
  }

  // If nothing was found, use default tag.
  if (lemmas.size() == lemmas_initial_size)
    if (!contains(used, string())) {
      if (used) used->push_back(string());
      lemmas.emplace_back(string(form.str, form.len), tags[default_tag]);
    }
}

/////////
// File: morpho/tag_filter.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

tag_filter::tag_filter(const char* filter) {
  if (!filter) return;

  wildcard.assign(filter);
  filter = wildcard.c_str();

  for (int tag_pos = 0; *filter; tag_pos++, filter++) {
    if (*filter == '?') continue;
    if (*filter == '[') {
      filter++;

      bool negate = false;
      if (*filter == '^') negate = true, filter++;

      const char* chars = filter;
      for (bool first = true; *filter && (first || *filter != ']'); first = false) filter++;

      filters.emplace_back(tag_pos, negate, chars, filter - chars);
      if (!*filter) break;
    } else {
      filters.emplace_back(tag_pos, false, filter, 1);
    }
  }
}

/////////
// File: tagger/tagger.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class tagger {
 public:
  virtual ~tagger() {}

  static tagger* load(const char* fname);
  static tagger* load(istream& is);

  // Return morpho associated with the tagger. Do not delete the pointer, it is
  // owned by the tagger instance and deleted in the tagger destructor.
  virtual const morpho* get_morpho() const = 0;

  // Perform morphologic analysis and subsequent disambiguation.
  virtual void tag(const vector<string_piece>& forms, vector<tagged_lemma>& tags, morpho::guesser_mode guesser = morpho::guesser_mode(-1)) const = 0;

  // Perform disambiguation only on given analyses.
  virtual void tag_analyzed(const vector<string_piece>& forms, const vector<vector<tagged_lemma>>& analyses, vector<int>& tags) const = 0;

  // Construct a new tokenizer instance appropriate for this tagger.
  // Can return NULL if no such tokenizer exists.
  // Is equal to get_morpho()->new_tokenizer.
  tokenizer* new_tokenizer() const;
};

/////////
// File: tagger/elementary_features.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
enum elementary_feature_type { PER_FORM, PER_TAG, DYNAMIC };
enum elementary_feature_range { ONLY_CURRENT, ANY_OFFSET };

typedef uint32_t elementary_feature_value;
enum :elementary_feature_value { elementary_feature_unknown = 0, elementary_feature_empty = 1 };

struct elementary_feature_description {
  string name;
  elementary_feature_type type;
  elementary_feature_range range;
  int index;
  int map_index;
};

template<class Map>
class elementary_features {
 public:
  bool load(istream& is);
  bool save(ostream& out);

  vector<Map> maps;
};

class persistent_elementary_feature_map : public persistent_unordered_map {
 public:
  persistent_elementary_feature_map() : persistent_unordered_map() {}
  persistent_elementary_feature_map(const persistent_unordered_map&& map) : persistent_unordered_map(map) {}

  elementary_feature_value value(const char* feature, int len) const {
    auto* it = at_typed<elementary_feature_value>(feature, len);
    return it ? *it : elementary_feature_unknown;
  }
};

// Definitions
template <class Map>
inline bool elementary_features<Map>::load(istream& is) {
  binary_decoder data;
  if (!compressor::load(is, data)) return false;

  try {
    maps.resize(data.next_1B());
    for (auto&& map : maps)
      map.load(data);
  } catch (binary_decoder_error&) {
    return false;
  }

  return data.is_end();
}

/////////
// File: tagger/vli.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
template <class T>
class vli {
 public:
  static int max_length();
  static void encode(T value, char*& where);
  static T decode(const char*& from);
};

// Definitions
template <>
inline int vli<uint32_t>::max_length() {
  return 5;
}

template <>
inline void vli<uint32_t>::encode(uint32_t value, char*& where) {
  if (value < 0x80) *where++ = value;
  else if (value < 0x4000) *where++ = (value >> 7) | 0x80u, *where++ = value & 0x7Fu;
  else if (value < 0x200000) *where++ = (value >> 14) | 0x80u, *where++ = ((value >> 7) & 0x7Fu) | 0x80u, *where++ = value & 0x7Fu;
  else if (value < 0x10000000) *where++ = (value >> 21) | 0x80u, *where++ = ((value >> 14) & 0x7Fu) | 0x80u, *where++ = ((value >> 7) & 0x7Fu) | 0x80u, *where++ = value & 0x7Fu;
  else *where++ = (value >> 28) | 0x80u, *where++ = ((value >> 21) & 0x7Fu) | 0x80u, *where++ = ((value >> 14) & 0x7Fu) | 0x80u, *where++ = ((value >> 7) & 0x7Fu) | 0x80u, *where++ = value & 0x7Fu;
}

template <>
inline uint32_t vli<uint32_t>::decode(const char*& from) {
  uint32_t value = 0;
  while (((unsigned char)(*from)) & 0x80u) value = (value << 7) | (((unsigned char)(*from++)) ^ 0x80u);
  value = (value << 7) | ((unsigned char)(*from++));
  return value;
}

/////////
// File: tagger/feature_sequences.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
typedef int32_t feature_sequence_score;
typedef int64_t feature_sequences_score;

struct feature_sequence_element {
  elementary_feature_type type;
  int elementary_index;
  int sequence_index;

  feature_sequence_element() {}
  feature_sequence_element(elementary_feature_type type, int elementary_index, int sequence_index) : type(type), elementary_index(elementary_index), sequence_index(sequence_index) {}
};

struct feature_sequence {
  vector<feature_sequence_element> elements;
  int dependant_range = 1;
};

template <class ElementaryFeatures, class Map>
class feature_sequences {
 public:
  typedef typename ElementaryFeatures::per_form_features per_form_features;
  typedef typename ElementaryFeatures::per_tag_features per_tag_features;
  typedef typename ElementaryFeatures::dynamic_features dynamic_features;

  void parse(int window_size, istream& is);
  bool load(istream& is);
  bool save(ostream& os);

  struct cache;

  inline void initialize_sentence(const vector<string_piece>& forms, const vector<vector<tagged_lemma>>& analyses, cache& c) const;
  inline void compute_dynamic_features(int form_index, int tag_index, const dynamic_features* prev_dynamic, dynamic_features& dynamic, cache& c) const;
  inline feature_sequences_score score(int form_index, int tags_window[], int tags_unchanged, dynamic_features& dynamic, cache& c) const;
  void feature_keys(int form_index, int tags_window[], int tags_unchanged, dynamic_features& dynamic, vector<string>& keys, cache& c) const;

  ElementaryFeatures elementary;
  vector<Map> scores;
  vector<feature_sequence> sequences;
};

class persistent_feature_sequence_map : public persistent_unordered_map {
 public:
  persistent_feature_sequence_map() : persistent_unordered_map() {}
  persistent_feature_sequence_map(const persistent_unordered_map&& map) : persistent_unordered_map(map) {}

  feature_sequence_score score(const char* feature, int len) const {
    auto* it = at_typed<feature_sequence_score>(feature, len);
    return it ? *it : 0;
  }
};

template <class ElementaryFeatures> using persistent_feature_sequences = feature_sequences<ElementaryFeatures, persistent_feature_sequence_map>;

// Definitions
template <class ElementaryFeatures, class Map>
inline bool feature_sequences<ElementaryFeatures, Map>::load(istream& is) {
  if (!elementary.load(is)) return false;

  binary_decoder data;
  if (!compressor::load(is, data)) return false;

  try {
    sequences.resize(data.next_1B());
    for (auto&& sequence : sequences) {
      sequence.dependant_range = data.next_4B();
      sequence.elements.resize(data.next_1B());
      for (auto&& element : sequence.elements) {
        element.type = elementary_feature_type(data.next_4B());
        element.elementary_index = data.next_4B();
        element.sequence_index = data.next_4B();
      }
    }

    scores.resize(data.next_1B());
    for (auto&& score : scores)
      score.load(data);
  } catch (binary_decoder_error&) {
    return false;
  }

  return data.is_end();
}

template <class ElementaryFeatures, class Map>
struct feature_sequences<ElementaryFeatures, Map>::cache {
  const vector<string_piece>* forms;
  const vector<vector<tagged_lemma>>* analyses;
  vector<per_form_features> elementary_per_form;
  vector<vector<per_tag_features>> elementary_per_tag;

  struct cache_element {
    vector<char> key;
    int key_size;
    feature_sequence_score score;

    cache_element(int elements) : key(vli<elementary_feature_value>::max_length() * elements), key_size(0), score(0) {}
  };
  vector<cache_element> caches;
  vector<const per_tag_features*> window;
  vector<char> key;
  feature_sequences_score score;

  cache(const feature_sequences<ElementaryFeatures, Map>& self) : score(0) {
    caches.reserve(self.sequences.size());
    int max_sequence_elements = 0, max_window_size = 1;
    for (auto&& sequence : self.sequences) {
      caches.emplace_back(sequence.elements.size());
      if (int(sequence.elements.size()) > max_sequence_elements) max_sequence_elements = sequence.elements.size();
      for (auto&& element : sequence.elements)
        if (element.type == PER_TAG && 1 - element.sequence_index > max_window_size)
          max_window_size = 1 - element.sequence_index;
    }
    key.resize(max_sequence_elements * vli<elementary_feature_value>::max_length());
    window.resize(max_window_size);
  }
};

template <class ElementaryFeatures, class Map>
void feature_sequences<ElementaryFeatures, Map>::initialize_sentence(const vector<string_piece>& forms, const vector<vector<tagged_lemma>>& analyses, cache& c) const {
  // Store forms and forms_size
  c.forms = &forms;
  c.analyses = &analyses;

  // Enlarge elementary features vectors if needed
  if (forms.size() > c.elementary_per_form.size()) c.elementary_per_form.resize(forms.size() * 2);
  if (forms.size() > c.elementary_per_tag.size()) c.elementary_per_tag.resize(forms.size() * 2);
  for (unsigned i = 0; i < forms.size(); i++)
    if (analyses[i].size() > c.elementary_per_tag[i].size())
      c.elementary_per_tag[i].resize(analyses[i].size() * 2);

  // Compute elementary features
  elementary.compute_features(forms, analyses, c.elementary_per_form, c.elementary_per_tag);

  // Clear score cache, because scores may have been modified
  c.score = 0;
  for (auto&& cache : c.caches)
    cache.key_size = cache.score = 0;
}

template <class ElementaryFeatures, class Map>
void feature_sequences<ElementaryFeatures, Map>::compute_dynamic_features(int form_index, int tag_index, const dynamic_features* prev_dynamic, dynamic_features& dynamic, cache& c) const {
  elementary.compute_dynamic_features((*c.analyses)[form_index][tag_index], c.elementary_per_form[form_index], c.elementary_per_tag[form_index][tag_index], form_index > 0 ? prev_dynamic : nullptr, dynamic);
}

template <class ElementaryFeatures, class Map>
feature_sequences_score feature_sequences<ElementaryFeatures, Map>::score(int form_index, int tags_window[], int tags_unchanged, dynamic_features& dynamic, cache& c) const {
  // Start by creating a window of per_tag_features*
  for (int i = 0; i < int(c.window.size()) && form_index - i >= 0; i++)
    c.window[i] = &c.elementary_per_tag[form_index - i][tags_window[i]];

  // Compute the score
  feature_sequences_score result = c.score;
  for (unsigned i = 0; i < sequences.size(); i++) {
    if (tags_unchanged >= sequences[i].dependant_range)
      break;

    char* key = c.key.data();
    for (unsigned j = 0; j < sequences[i].elements.size(); j++) {
      auto& element = sequences[i].elements[j];
      elementary_feature_value value;

      switch (element.type) {
        case PER_FORM:
          value = form_index + element.sequence_index < 0 || unsigned(form_index + element.sequence_index) >= c.forms->size() ? elementary_feature_empty : c.elementary_per_form[form_index + element.sequence_index].values[element.elementary_index];
          break;
        case PER_TAG:
          value = form_index + element.sequence_index < 0 ? elementary_feature_empty : c.window[-element.sequence_index]->values[element.elementary_index];
          break;
        case DYNAMIC:
        default:
          value = dynamic.values[element.elementary_index];
      }

      if (value == elementary_feature_unknown) {
        key = c.key.data();
        break;
      }
      vli<elementary_feature_value>::encode(value, key);
    }

    result -= c.caches[i].score;
    int key_size = key - c.key.data();
    if (!key_size) {
      c.caches[i].score = 0;
      c.caches[i].key_size = 0;
    } else if (key_size != c.caches[i].key_size || !small_memeq(c.key.data(), c.caches[i].key.data(), key_size)) {
      c.caches[i].score = scores[i].score(c.key.data(), key_size);
      c.caches[i].key_size = key_size;
      small_memcpy(c.caches[i].key.data(), c.key.data(), key_size);
    }
    result += c.caches[i].score;
  }

  c.score = result;
  return result;
}

template <class ElementaryFeatures, class Map>
void feature_sequences<ElementaryFeatures, Map>::feature_keys(int form_index, int tags_window[], int tags_unchanged, dynamic_features& dynamic, vector<string>& keys, cache& c) const {
  score(form_index, tags_window, tags_unchanged, dynamic, c);

  keys.resize(c.caches.size());
  for (unsigned i = 0; i < c.caches.size(); i++)
    keys[i].assign(c.caches[i].key.data(), c.caches[i].key_size);
}

/////////
// File: tagger/viterbi.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
template <class FeatureSequences>
class viterbi {
 public:
  viterbi(const FeatureSequences& features, int decoding_order, int window_size)
      : features(features), decoding_order(decoding_order), window_size(window_size) {}

  struct cache;
  void tag(const vector<string_piece>& forms, const vector<vector<tagged_lemma>>& analyses, cache& c, vector<int>& tags) const;

 private:
  struct node;

  const FeatureSequences& features;
  int decoding_order, window_size;
};

// Definitions
template <class FeatureSequences>
struct viterbi<FeatureSequences>::cache {
  vector<node> nodes;
  typename FeatureSequences::cache features_cache;

  cache(const viterbi<FeatureSequences>& self) : features_cache(self.features) {}
};

template <class FeatureSequences>
struct viterbi<FeatureSequences>::node {
  int tag;
  int prev;
  feature_sequences_score score;
  typename FeatureSequences::dynamic_features dynamic;
};

template <class FeatureSequences>
void viterbi<FeatureSequences>::tag(const vector<string_piece>& forms, const vector<vector<tagged_lemma>>& analyses, cache& c, vector<int>& tags) const {
  if (!forms.size()) return;

  // Count number of nodes and allocate
  unsigned nodes = 0;
  for (unsigned i = 0, states = 1; i < forms.size(); i++) {
    if (analyses[i].empty()) return;
    states = (i+1 >= unsigned(decoding_order) ? states / analyses[i-decoding_order+1].size() : states) * analyses[i].size();
    nodes += states;
  }
  if (nodes > c.nodes.size()) c.nodes.resize(nodes);

  // Init feature sequences
  features.initialize_sentence(forms, analyses, c.features_cache);

  int window_stack[16]; vector<int> window_heap;
  int* window = window_size <= 16 ? window_stack : (window_heap.resize(window_size), window_heap.data());
  typename FeatureSequences::dynamic_features dynamic;
  feature_sequences_score score;

  // Compute all nodes score
  int nodes_prev = -1, nodes_now = 0;
  for (unsigned i = 0; i < forms.size(); i++) {
    int nodes_next = nodes_now;

    for (int j = 0; j < window_size; j++) window[j] = -1;
    for (int tag = 0; tag < int(analyses[i].size()); tag++)
      for (int prev = nodes_prev; prev < nodes_now; prev++) {
        // Compute predecessors and number of unchanges
        int same_tags = window[0] == tag;
        window[0] = tag;
        for (int p = prev, n = 1; p >= 0 && n < window_size; p = c.nodes[p].prev, n++) {
          same_tags += same_tags == n && window[n] == c.nodes[p].tag;
          window[n] = c.nodes[p].tag;
        }

        // Compute dynamic elementary features and score
        features.compute_dynamic_features(i, tag, prev >= 0 ? &c.nodes[prev].dynamic : nullptr, dynamic, c.features_cache);
        score = (nodes_prev + 1 == nodes_now && analyses[i].size() == 1 ? 0 : features.score(i, window, same_tags, dynamic, c.features_cache)) +
            (prev >= 0 ? c.nodes[prev].score : 0);

        // Update existing node or create a new one
        if (same_tags >= decoding_order-1) {
          if (score <= c.nodes[nodes_next-1].score) continue;
          nodes_next--;
        }
        c.nodes[nodes_next].tag = tag;
        c.nodes[nodes_next].prev = prev;
        c.nodes[nodes_next].score = score;
        c.nodes[nodes_next++].dynamic = dynamic;
      }

    nodes_prev = nodes_now;
    nodes_now = nodes_next;
  }

  // Choose the best ending node
  int best = nodes_prev;
  for (int node = nodes_prev + 1; node < nodes_now; node++)
    if (c.nodes[node].score > c.nodes[best].score)
      best = node;

  for (int i = forms.size() - 1; i >= 0; i--, best = c.nodes[best].prev)
    tags[i] = c.nodes[best].tag;
}

/////////
// File: tagger/conllu_elementary_features.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
template <class Map>
class conllu_elementary_features : public elementary_features<Map> {
 public:
  conllu_elementary_features();

  enum features_per_form { FORM, FOLLOWING_VERB_TAG, FOLLOWING_VERB_FORM, NUM, CAP, DASH, PREFIX1, PREFIX2, PREFIX3, PREFIX4, PREFIX5, PREFIX6, PREFIX7, PREFIX8, PREFIX9, SUFFIX1, SUFFIX2, SUFFIX3, SUFFIX4, SUFFIX5, SUFFIX6, SUFFIX7, SUFFIX8, SUFFIX9, PER_FORM_TOTAL };
  enum features_per_tag { TAG, TAG_UPOS, TAG_CASE, TAG_GENDER, TAG_NUMBER, TAG_NEGATIVE, TAG_PERSON, LEMMA, PER_TAG_TOTAL };
  enum features_dynamic { PREVIOUS_VERB_TAG, PREVIOUS_VERB_FORM, PREVIOUS_OR_CURRENT_VERB_TAG, PREVIOUS_OR_CURRENT_VERB_FORM, DYNAMIC_TOTAL };
  enum features_map { MAP_NONE = -1, MAP_FORM, MAP_PREFIX1, MAP_PREFIX2, MAP_PREFIX3, MAP_PREFIX4, MAP_PREFIX5, MAP_PREFIX6, MAP_PREFIX7, MAP_PREFIX8, MAP_PREFIX9, MAP_SUFFIX1, MAP_SUFFIX2, MAP_SUFFIX3, MAP_SUFFIX4, MAP_SUFFIX5, MAP_SUFFIX6, MAP_SUFFIX7, MAP_SUFFIX8, MAP_SUFFIX9, MAP_TAG, MAP_TAG_UPOS, MAP_TAG_CASE, MAP_TAG_GENDER, MAP_TAG_NUMBER, MAP_TAG_NEGATIVE, MAP_TAG_PERSON, MAP_LEMMA, MAP_TOTAL } ;

  struct per_form_features { elementary_feature_value values[PER_FORM_TOTAL]; };
  struct per_tag_features { elementary_feature_value values[PER_TAG_TOTAL]; };
  struct dynamic_features { elementary_feature_value values[DYNAMIC_TOTAL]; };

  static vector<elementary_feature_description> descriptions;

  void compute_features(const vector<string_piece>& forms, const vector<vector<tagged_lemma>>& analyses, vector<per_form_features>& per_form, vector<vector<per_tag_features>>& per_tag) const;
  inline void compute_dynamic_features(const tagged_lemma& tag, const per_form_features& per_form, const per_tag_features& per_tag, const dynamic_features* prev_dynamic, dynamic_features& dynamic) const;

  using elementary_features<Map>::maps;
};

typedef conllu_elementary_features<persistent_elementary_feature_map> persistent_conllu_elementary_features;

// Definitions
template <class Map>
conllu_elementary_features<Map>::conllu_elementary_features() {
  maps.resize(MAP_TOTAL);
}

template <class Map>
vector<elementary_feature_description> conllu_elementary_features<Map>::descriptions = {
  {"Form", PER_FORM, ANY_OFFSET, FORM, MAP_FORM},
  {"FollowingVerbTag", PER_FORM, ANY_OFFSET, FOLLOWING_VERB_TAG, MAP_TAG},
  {"FollowingVerbForm", PER_FORM, ANY_OFFSET, FOLLOWING_VERB_FORM, MAP_FORM},
  {"Num", PER_FORM, ONLY_CURRENT, NUM, MAP_NONE},
  {"Cap", PER_FORM, ONLY_CURRENT, CAP, MAP_NONE},
  {"Dash", PER_FORM, ONLY_CURRENT, DASH, MAP_NONE},
  {"Prefix1", PER_FORM, ONLY_CURRENT, PREFIX1, MAP_PREFIX1},
  {"Prefix2", PER_FORM, ONLY_CURRENT, PREFIX2, MAP_PREFIX2},
  {"Prefix3", PER_FORM, ONLY_CURRENT, PREFIX3, MAP_PREFIX3},
  {"Prefix4", PER_FORM, ONLY_CURRENT, PREFIX4, MAP_PREFIX4},
  {"Prefix5", PER_FORM, ONLY_CURRENT, PREFIX5, MAP_PREFIX5},
  {"Prefix6", PER_FORM, ONLY_CURRENT, PREFIX6, MAP_PREFIX6},
  {"Prefix7", PER_FORM, ONLY_CURRENT, PREFIX7, MAP_PREFIX7},
  {"Prefix8", PER_FORM, ONLY_CURRENT, PREFIX8, MAP_PREFIX8},
  {"Prefix9", PER_FORM, ONLY_CURRENT, PREFIX9, MAP_PREFIX9},
  {"Suffix1", PER_FORM, ONLY_CURRENT, SUFFIX1, MAP_SUFFIX1},
  {"Suffix2", PER_FORM, ONLY_CURRENT, SUFFIX2, MAP_SUFFIX2},
  {"Suffix3", PER_FORM, ONLY_CURRENT, SUFFIX3, MAP_SUFFIX3},
  {"Suffix4", PER_FORM, ONLY_CURRENT, SUFFIX4, MAP_SUFFIX4},
  {"Suffix5", PER_FORM, ONLY_CURRENT, SUFFIX5, MAP_SUFFIX5},
  {"Suffix6", PER_FORM, ONLY_CURRENT, SUFFIX6, MAP_SUFFIX6},
  {"Suffix7", PER_FORM, ONLY_CURRENT, SUFFIX7, MAP_SUFFIX7},
  {"Suffix8", PER_FORM, ONLY_CURRENT, SUFFIX8, MAP_SUFFIX8},
  {"Suffix9", PER_FORM, ONLY_CURRENT, SUFFIX9, MAP_SUFFIX9},

  {"Tag", PER_TAG, ANY_OFFSET, TAG, MAP_TAG},
  {"TagUPos", PER_TAG, ANY_OFFSET, TAG_UPOS, MAP_TAG_UPOS},
  {"TagCase", PER_TAG, ANY_OFFSET, TAG_CASE, MAP_TAG_CASE},
  {"TagGender", PER_TAG, ANY_OFFSET, TAG_GENDER, MAP_TAG_GENDER},
  {"TagNumber", PER_TAG, ANY_OFFSET, TAG_NUMBER, MAP_TAG_NUMBER},
  {"TagNegative", PER_TAG, ANY_OFFSET, TAG_NEGATIVE, MAP_TAG_NEGATIVE},
  {"TagPerson", PER_TAG, ANY_OFFSET, TAG_PERSON, MAP_TAG_PERSON},
  {"Lemma", PER_TAG, ANY_OFFSET, LEMMA, MAP_LEMMA},

  {"PreviousVerbTag", DYNAMIC, ANY_OFFSET, PREVIOUS_VERB_TAG, MAP_TAG},
  {"PreviousVerbForm", DYNAMIC, ANY_OFFSET, PREVIOUS_VERB_FORM, MAP_FORM},
};

template <class Map>
void conllu_elementary_features<Map>::compute_features(const vector<string_piece>& forms, const vector<vector<tagged_lemma>>& analyses, vector<per_form_features>& per_form, vector<vector<per_tag_features>>& per_tag) const {
  using namespace unilib;

  // We process the sentence in reverse order, so that we can compute FollowingVerbTag and FollowingVerbLemma directly.
  elementary_feature_value following_verb_tag = elementary_feature_empty, following_verb_form = elementary_feature_empty;
  for (unsigned i = forms.size(); i--;) {
    int verb_candidate = -1;

    // Per_tag features and verb_candidate
    for (unsigned j = 0; j < analyses[i].size(); j++) {
      const string& tag = analyses[i][j].tag;
      const string& lemma = analyses[i][j].lemma;

      // Tag consists of three parts separated by tag[0] character
      // - first is TAG_UPOS,
      // - second is TAG_LPOS,
      // - then there is any number of | separated named fields in format Name=Value
      per_tag[i][j].values[TAG] = maps[MAP_TAG].value(tag.c_str(), tag.size());
      per_tag[i][j].values[TAG_UPOS] = per_tag[i][j].values[TAG_CASE] = per_tag[i][j].values[TAG_GENDER] = elementary_feature_empty;
      per_tag[i][j].values[TAG_NUMBER] = per_tag[i][j].values[TAG_NEGATIVE] = per_tag[i][j].values[TAG_PERSON] = elementary_feature_empty;
      per_tag[i][j].values[LEMMA] = j && analyses[i][j-1].lemma == lemma ? per_tag[i][j-1].values[LEMMA] :
          maps[MAP_LEMMA].value(lemma.c_str(), lemma.size());

      char separator = tag[0];
      size_t index = tag.find(separator, 1);
      if (index == string::npos) index = tag.size();
      per_tag[i][j].values[TAG_UPOS] = maps[MAP_TAG_UPOS].value(tag.c_str() + (index ? 1 : 0), index - (index ? 1 : 0));

      if (index < tag.size()) index++;
      if (index < tag.size()) index = tag.find(separator, index);
      if (index < tag.size()) index++;
      for (size_t length; index < tag.size(); index += length + 1) {
        length = tag.find('|', index);
        length = (length == string::npos ? tag.size() : length) - index;

        for (size_t equal_sign = 0; equal_sign + 1 < length; equal_sign++)
          if (tag[index + equal_sign] == '=') {
            int value = -1, map;
            switch (equal_sign) {
              case 4:
                if (tag.compare(index, equal_sign, "Case") == 0) value = TAG_CASE, map = MAP_TAG_CASE;
                break;
              case 6:
                if (tag.compare(index, equal_sign, "Gender") == 0) value = TAG_GENDER, map = MAP_TAG_GENDER;
                if (tag.compare(index, equal_sign, "Number") == 0) value = TAG_NUMBER, map = MAP_TAG_NUMBER;
                if (tag.compare(index, equal_sign, "Person") == 0) value = TAG_PERSON, map = MAP_TAG_PERSON;
                break;
              case 8:
                if (tag.compare(index, equal_sign, "Negative") == 0) value = TAG_NEGATIVE, map = MAP_TAG_NEGATIVE;
                break;
            }

            if (value >= 0)
              per_tag[i][j].values[value] = maps[map].value(tag.c_str() + index + equal_sign + 1, length - equal_sign - 1);
            break;
          }
      }

      if (tag.size() >= 2 && tag[1] == 'V') {
        int tag_compare;
        verb_candidate = verb_candidate < 0 || (tag_compare = tag.compare(analyses[i][verb_candidate].tag), tag_compare < 0) || (tag_compare == 0 && lemma < analyses[i][verb_candidate].lemma) ? j : verb_candidate;
      }
    }

    // Per_form features
    per_form[i].values[FORM] = maps[MAP_FORM].value(forms[i].str, forms[i].len);
    per_form[i].values[FOLLOWING_VERB_TAG] = following_verb_tag;
    per_form[i].values[FOLLOWING_VERB_FORM] = following_verb_form;

    // Update following_verb_{tag,lemma} _after_ filling FOLLOWING_VERB_{TAG,LEMMA}.
    if (verb_candidate >= 0) {
      following_verb_tag = per_tag[i][verb_candidate].values[TAG];
      following_verb_form = per_form[i].values[FORM];
    }

    // Ortographic per_form features if needed
    if (analyses[i].size() == 1) {
      per_form[i].values[NUM] = per_form[i].values[CAP] = per_form[i].values[DASH] = elementary_feature_unknown;
      per_form[i].values[PREFIX1] = per_form[i].values[PREFIX2] = per_form[i].values[PREFIX3] = elementary_feature_unknown;
      per_form[i].values[PREFIX4] = per_form[i].values[PREFIX5] = per_form[i].values[PREFIX6] = elementary_feature_unknown;
      per_form[i].values[PREFIX7] = per_form[i].values[PREFIX8] = per_form[i].values[PREFIX9] = elementary_feature_unknown;
      per_form[i].values[SUFFIX1] = per_form[i].values[SUFFIX2] = per_form[i].values[SUFFIX3] = elementary_feature_unknown;
      per_form[i].values[SUFFIX4] = per_form[i].values[SUFFIX5] = per_form[i].values[SUFFIX6] = elementary_feature_unknown;
      per_form[i].values[SUFFIX7] = per_form[i].values[SUFFIX8] = per_form[i].values[SUFFIX9] = elementary_feature_unknown;
    } else if (forms[i].len <= 0) {
      per_form[i].values[NUM] = per_form[i].values[CAP] = per_form[i].values[DASH] = elementary_feature_empty + 1;
      per_form[i].values[PREFIX1] = per_form[i].values[PREFIX2] = per_form[i].values[PREFIX3] = elementary_feature_empty;
      per_form[i].values[PREFIX4] = per_form[i].values[PREFIX5] = per_form[i].values[PREFIX6] = elementary_feature_empty;
      per_form[i].values[PREFIX7] = per_form[i].values[PREFIX8] = per_form[i].values[PREFIX9] = elementary_feature_empty;
      per_form[i].values[SUFFIX1] = per_form[i].values[SUFFIX2] = per_form[i].values[SUFFIX3] = elementary_feature_empty;
      per_form[i].values[SUFFIX4] = per_form[i].values[SUFFIX5] = per_form[i].values[SUFFIX6] = elementary_feature_empty;
      per_form[i].values[SUFFIX7] = per_form[i].values[SUFFIX8] = per_form[i].values[SUFFIX9] = elementary_feature_empty;
    } else {
      string_piece form = forms[i];
      const char* form_start = form.str;

      bool num = false, cap = false, dash = false;
      size_t indices[18] = {0, form.len, form.len, form.len, form.len, form.len, form.len, form.len, form.len, form.len, 0, 0, 0, 0, 0, 0, 0, 0}; // careful here regarding forms shorter than 9 characters
      int index = 0;
      while (form.len) {
        indices[(index++) % 18] = form.str - form_start;

        unicode::category_t cat = unicode::category(utf8::decode(form.str, form.len));
        num = num || cat & unicode::N;
        cap = cap || cat & unicode::Lut;
        dash = dash || cat & unicode::Pd;

        if (index == 10 || (!form.len && index < 10)) {
          per_form[i].values[PREFIX1] = maps[MAP_PREFIX1].value(form_start, indices[1]);
          per_form[i].values[PREFIX2] = maps[MAP_PREFIX2].value(form_start, indices[2]);
          per_form[i].values[PREFIX3] = maps[MAP_PREFIX3].value(form_start, indices[3]);
          per_form[i].values[PREFIX4] = maps[MAP_PREFIX4].value(form_start, indices[4]);
          per_form[i].values[PREFIX5] = maps[MAP_PREFIX5].value(form_start, indices[5]);
          per_form[i].values[PREFIX6] = maps[MAP_PREFIX6].value(form_start, indices[6]);
          per_form[i].values[PREFIX7] = maps[MAP_PREFIX7].value(form_start, indices[7]);
          per_form[i].values[PREFIX8] = maps[MAP_PREFIX8].value(form_start, indices[8]);
          per_form[i].values[PREFIX9] = maps[MAP_PREFIX9].value(form_start, indices[9]);
        }
      }
      per_form[i].values[SUFFIX1] = maps[MAP_SUFFIX1].value(form_start + indices[(index+18-1) % 18], form.str - form_start - indices[(index+18-1) % 18]);
      per_form[i].values[SUFFIX2] = maps[MAP_SUFFIX2].value(form_start + indices[(index+18-2) % 18], form.str - form_start - indices[(index+18-2) % 18]);
      per_form[i].values[SUFFIX3] = maps[MAP_SUFFIX3].value(form_start + indices[(index+18-3) % 18], form.str - form_start - indices[(index+18-3) % 18]);
      per_form[i].values[SUFFIX4] = maps[MAP_SUFFIX4].value(form_start + indices[(index+18-4) % 18], form.str - form_start - indices[(index+18-4) % 18]);
      per_form[i].values[SUFFIX5] = maps[MAP_SUFFIX5].value(form_start + indices[(index+18-5) % 18], form.str - form_start - indices[(index+18-5) % 18]);
      per_form[i].values[SUFFIX6] = maps[MAP_SUFFIX6].value(form_start + indices[(index+18-6) % 18], form.str - form_start - indices[(index+18-6) % 18]);
      per_form[i].values[SUFFIX7] = maps[MAP_SUFFIX7].value(form_start + indices[(index+18-7) % 18], form.str - form_start - indices[(index+18-7) % 18]);
      per_form[i].values[SUFFIX8] = maps[MAP_SUFFIX8].value(form_start + indices[(index+18-8) % 18], form.str - form_start - indices[(index+18-8) % 18]);
      per_form[i].values[SUFFIX9] = maps[MAP_SUFFIX9].value(form_start + indices[(index+18-9) % 18], form.str - form_start - indices[(index+18-9) % 18]);
      per_form[i].values[NUM] = elementary_feature_empty + 1 + num;
      per_form[i].values[CAP] = elementary_feature_empty + 1 + cap;
      per_form[i].values[DASH] = elementary_feature_empty + 1 + dash;
    }
  }
}

template <class Map>
void conllu_elementary_features<Map>::compute_dynamic_features(const tagged_lemma& tag, const per_form_features& per_form, const per_tag_features& per_tag, const dynamic_features* prev_dynamic, dynamic_features& dynamic) const {
  if (prev_dynamic) {
    dynamic.values[PREVIOUS_VERB_TAG] = prev_dynamic->values[PREVIOUS_OR_CURRENT_VERB_TAG];
    dynamic.values[PREVIOUS_VERB_FORM] = prev_dynamic->values[PREVIOUS_OR_CURRENT_VERB_FORM];
  } else {
    dynamic.values[PREVIOUS_VERB_TAG] = elementary_feature_empty;
    dynamic.values[PREVIOUS_VERB_FORM] = elementary_feature_empty;
  }

  if (tag.tag.size() >= 2 && tag.tag[1] == 'V') {
    dynamic.values[PREVIOUS_OR_CURRENT_VERB_TAG] = per_tag.values[TAG];
    dynamic.values[PREVIOUS_OR_CURRENT_VERB_FORM] = per_form.values[FORM];
  } else {
    dynamic.values[PREVIOUS_OR_CURRENT_VERB_TAG] = dynamic.values[PREVIOUS_VERB_TAG];
    dynamic.values[PREVIOUS_OR_CURRENT_VERB_FORM] = dynamic.values[PREVIOUS_VERB_FORM];
  }
}

/////////
// File: tagger/czech_elementary_features.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
template <class Map>
class czech_elementary_features : public elementary_features<Map> {
 public:
  czech_elementary_features();

  enum features_per_form { FORM, FOLLOWING_VERB_TAG, FOLLOWING_VERB_LEMMA, NUM, CAP, DASH, PREFIX1, PREFIX2, PREFIX3, PREFIX4, SUFFIX1, SUFFIX2, SUFFIX3, SUFFIX4, PER_FORM_TOTAL };
  enum features_per_tag { TAG, TAG3, TAG5, TAG25, LEMMA, PER_TAG_TOTAL };
  enum features_dynamic { PREVIOUS_VERB_TAG, PREVIOUS_VERB_LEMMA, PREVIOUS_OR_CURRENT_VERB_TAG, PREVIOUS_OR_CURRENT_VERB_LEMMA, DYNAMIC_TOTAL };
  enum features_map { MAP_NONE = -1, MAP_FORM, MAP_LEMMA, MAP_PREFIX1, MAP_PREFIX2, MAP_PREFIX3, MAP_PREFIX4, MAP_SUFFIX1, MAP_SUFFIX2, MAP_SUFFIX3, MAP_SUFFIX4, MAP_TAG, MAP_TAG3, MAP_TAG5, MAP_TAG25, MAP_TOTAL } ;

  struct per_form_features { elementary_feature_value values[PER_FORM_TOTAL]; };
  struct per_tag_features { elementary_feature_value values[PER_TAG_TOTAL]; };
  struct dynamic_features { elementary_feature_value values[DYNAMIC_TOTAL]; };

  static vector<elementary_feature_description> descriptions;

  void compute_features(const vector<string_piece>& forms, const vector<vector<tagged_lemma>>& analyses, vector<per_form_features>& per_form, vector<vector<per_tag_features>>& per_tag) const;
  inline void compute_dynamic_features(const tagged_lemma& tag, const per_form_features& per_form, const per_tag_features& per_tag, const dynamic_features* prev_dynamic, dynamic_features& dynamic) const;

  using elementary_features<Map>::maps;
};

typedef czech_elementary_features<persistent_elementary_feature_map> persistent_czech_elementary_features;

// Definitions
template <class Map>
czech_elementary_features<Map>::czech_elementary_features() {
  maps.resize(MAP_TOTAL);
}

template <class Map>
vector<elementary_feature_description> czech_elementary_features<Map>::descriptions = {
  {"Form", PER_FORM, ANY_OFFSET, FORM, MAP_FORM},
  {"FollowingVerbTag", PER_FORM, ANY_OFFSET, FOLLOWING_VERB_TAG, MAP_TAG},
  {"FollowingVerbLemma", PER_FORM, ANY_OFFSET, FOLLOWING_VERB_LEMMA, MAP_LEMMA },
  {"Num", PER_FORM, ONLY_CURRENT, NUM, MAP_NONE},
  {"Cap", PER_FORM, ONLY_CURRENT, CAP, MAP_NONE},
  {"Dash", PER_FORM, ONLY_CURRENT, DASH, MAP_NONE},
  {"Prefix1", PER_FORM, ONLY_CURRENT, PREFIX1, MAP_PREFIX1},
  {"Prefix2", PER_FORM, ONLY_CURRENT, PREFIX2, MAP_PREFIX2},
  {"Prefix3", PER_FORM, ONLY_CURRENT, PREFIX3, MAP_PREFIX3},
  {"Prefix4", PER_FORM, ONLY_CURRENT, PREFIX4, MAP_PREFIX4},
  {"Suffix1", PER_FORM, ONLY_CURRENT, SUFFIX1, MAP_SUFFIX1},
  {"Suffix2", PER_FORM, ONLY_CURRENT, SUFFIX2, MAP_SUFFIX2},
  {"Suffix3", PER_FORM, ONLY_CURRENT, SUFFIX3, MAP_SUFFIX3},
  {"Suffix4", PER_FORM, ONLY_CURRENT, SUFFIX4, MAP_SUFFIX4},

  {"Tag", PER_TAG, ANY_OFFSET, TAG, MAP_TAG},
  {"Tag3", PER_TAG, ANY_OFFSET, TAG3, MAP_TAG3},
  {"Tag5", PER_TAG, ANY_OFFSET, TAG5, MAP_TAG5},
  {"Tag25", PER_TAG, ANY_OFFSET, TAG25, MAP_TAG25},
  {"Lemma", PER_TAG, ANY_OFFSET, LEMMA, MAP_LEMMA},

  {"PreviousVerbTag", DYNAMIC, ANY_OFFSET, PREVIOUS_VERB_TAG, MAP_TAG},
  {"PreviousVerbLemma", DYNAMIC, ANY_OFFSET, PREVIOUS_VERB_LEMMA, MAP_LEMMA}
};

template <class Map>
void czech_elementary_features<Map>::compute_features(const vector<string_piece>& forms, const vector<vector<tagged_lemma>>& analyses, vector<per_form_features>& per_form, vector<vector<per_tag_features>>& per_tag) const {
  using namespace unilib;

  // We process the sentence in reverse order, so that we can compute FollowingVerbTag and FollowingVerbLemma directly.
  elementary_feature_value following_verb_tag = elementary_feature_empty, following_verb_lemma = elementary_feature_empty;
  for (unsigned i = forms.size(); i--;) {
    int verb_candidate = -1;

    // Per_tag features and verb_candidate
    for (unsigned j = 0; j < analyses[i].size(); j++) {
      char tag25[2];
      per_tag[i][j].values[TAG] = maps[MAP_TAG].value(analyses[i][j].tag.c_str(), analyses[i][j].tag.size());
      per_tag[i][j].values[TAG3] = analyses[i][j].tag.size() >= 3 ? maps[MAP_TAG3].value(analyses[i][j].tag.c_str() + 2, 1) : elementary_feature_empty;
      per_tag[i][j].values[TAG5] = analyses[i][j].tag.size() >= 5 ? maps[MAP_TAG5].value(analyses[i][j].tag.c_str() + 4, 1) : elementary_feature_empty;
      per_tag[i][j].values[TAG25] = analyses[i][j].tag.size() >= 5 ? maps[MAP_TAG25].value((tag25[0] = analyses[i][j].tag[1], tag25[1] = analyses[i][j].tag[4], tag25), 2) : elementary_feature_empty;
      per_tag[i][j].values[LEMMA] = j && analyses[i][j-1].lemma == analyses[i][j].lemma ? per_tag[i][j-1].values[LEMMA] :
          maps[MAP_LEMMA].value(analyses[i][j].lemma.c_str(), analyses[i][j].lemma.size());

      if (analyses[i][j].tag[0] == 'V') {
        int tag_compare;
        verb_candidate = verb_candidate < 0 || (tag_compare = analyses[i][j].tag.compare(analyses[i][verb_candidate].tag), tag_compare < 0) || (tag_compare == 0 && analyses[i][j].lemma < analyses[i][verb_candidate].lemma) ? j : verb_candidate;
      }
    }

    // Per_form features
    per_form[i].values[FORM] = maps[MAP_FORM].value(forms[i].str, forms[i].len);
    per_form[i].values[FOLLOWING_VERB_TAG] = following_verb_tag;
    per_form[i].values[FOLLOWING_VERB_LEMMA] = following_verb_lemma;

    // Update following_verb_{tag,lemma} _after_ filling FOLLOWING_VERB_{TAG,LEMMA}.
    if (verb_candidate >= 0) {
      following_verb_tag = per_tag[i][verb_candidate].values[TAG];
      following_verb_lemma = per_tag[i][verb_candidate].values[LEMMA];
    }

    // Ortographic per_form features if needed
    if (analyses[i].size() == 1) {
      per_form[i].values[NUM] = per_form[i].values[CAP] = per_form[i].values[DASH] = elementary_feature_unknown;
      per_form[i].values[PREFIX1] = per_form[i].values[PREFIX2] = per_form[i].values[PREFIX3] = per_form[i].values[PREFIX4] = elementary_feature_unknown;
      per_form[i].values[SUFFIX1] = per_form[i].values[SUFFIX2] = per_form[i].values[SUFFIX3] = per_form[i].values[SUFFIX4] = elementary_feature_unknown;
    } else if (forms[i].len <= 0) {
      per_form[i].values[NUM] = per_form[i].values[CAP] = per_form[i].values[DASH] = elementary_feature_empty + 1;
      per_form[i].values[PREFIX1] = per_form[i].values[PREFIX2] = per_form[i].values[PREFIX3] = per_form[i].values[PREFIX4] = elementary_feature_empty;
      per_form[i].values[SUFFIX1] = per_form[i].values[SUFFIX2] = per_form[i].values[SUFFIX3] = per_form[i].values[SUFFIX4] = elementary_feature_empty;
    } else {
      string_piece form = forms[i];
      const char* form_start = form.str;

      bool num = false, cap = false, dash = false;
      size_t indices[8] = {0, form.len, form.len, form.len, form.len, 0, 0, 0}; // careful here regarding forms shorter than 4 characters
      int index = 0;
      while (form.len) {
        indices[(index++)&7] = form.str - form_start;

        unicode::category_t cat = unicode::category(utf8::decode(form.str, form.len));
        num = num || cat & unicode::N;
        cap = cap || cat & unicode::Lut;
        dash = dash || cat & unicode::Pd;

        if (index == 5 || (!form.len && index < 5)) {
          per_form[i].values[PREFIX1] = maps[MAP_PREFIX1].value(form_start, indices[1]);
          per_form[i].values[PREFIX2] = maps[MAP_PREFIX2].value(form_start, indices[2]);
          per_form[i].values[PREFIX3] = maps[MAP_PREFIX3].value(form_start, indices[3]);
          per_form[i].values[PREFIX4] = maps[MAP_PREFIX4].value(form_start, indices[4]);
        }
      }
      per_form[i].values[SUFFIX1] = maps[MAP_SUFFIX1].value(form_start + indices[(index-1)&7], form.str - form_start - indices[(index-1)&7]);
      per_form[i].values[SUFFIX2] = maps[MAP_SUFFIX2].value(form_start + indices[(index-2)&7], form.str - form_start - indices[(index-2)&7]);
      per_form[i].values[SUFFIX3] = maps[MAP_SUFFIX3].value(form_start + indices[(index-3)&7], form.str - form_start - indices[(index-3)&7]);
      per_form[i].values[SUFFIX4] = maps[MAP_SUFFIX4].value(form_start + indices[(index-4)&7], form.str - form_start - indices[(index-4)&7]);
      per_form[i].values[NUM] = elementary_feature_empty + 1 + num;
      per_form[i].values[CAP] = elementary_feature_empty + 1 + cap;
      per_form[i].values[DASH] = elementary_feature_empty + 1 + dash;
    }
  }
}

template <class Map>
void czech_elementary_features<Map>::compute_dynamic_features(const tagged_lemma& tag, const per_form_features& /*per_form*/, const per_tag_features& per_tag, const dynamic_features* prev_dynamic, dynamic_features& dynamic) const {
  if (prev_dynamic) {
    dynamic.values[PREVIOUS_VERB_TAG] = prev_dynamic->values[PREVIOUS_OR_CURRENT_VERB_TAG];
    dynamic.values[PREVIOUS_VERB_LEMMA] = prev_dynamic->values[PREVIOUS_OR_CURRENT_VERB_LEMMA];
  } else {
    dynamic.values[PREVIOUS_VERB_TAG] = elementary_feature_empty;
    dynamic.values[PREVIOUS_VERB_LEMMA] = elementary_feature_empty;
  }

  if (tag.tag[0] == 'V') {
    dynamic.values[PREVIOUS_OR_CURRENT_VERB_TAG] = per_tag.values[TAG];
    dynamic.values[PREVIOUS_OR_CURRENT_VERB_LEMMA] = per_tag.values[LEMMA];
  } else {
    dynamic.values[PREVIOUS_OR_CURRENT_VERB_TAG] = dynamic.values[PREVIOUS_VERB_TAG];
    dynamic.values[PREVIOUS_OR_CURRENT_VERB_LEMMA] = dynamic.values[PREVIOUS_VERB_LEMMA];
  }
}

/////////
// File: tagger/generic_elementary_features.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
template <class Map>
class generic_elementary_features : public elementary_features<Map> {
 public:
  generic_elementary_features();

  enum features_per_form { FORM, FOLLOWING_VERB_TAG, FOLLOWING_VERB_LEMMA, NUM, CAP, DASH, PREFIX1, PREFIX2, PREFIX3, PREFIX4, PREFIX5, PREFIX6, PREFIX7, PREFIX8, PREFIX9, SUFFIX1, SUFFIX2, SUFFIX3, SUFFIX4, SUFFIX5, SUFFIX6, SUFFIX7, SUFFIX8, SUFFIX9, PER_FORM_TOTAL };
  enum features_per_tag { TAG, TAG1, TAG2, TAG3, TAG4, TAG5, LEMMA, PER_TAG_TOTAL };
  enum features_dynamic { PREVIOUS_VERB_TAG, PREVIOUS_VERB_LEMMA, PREVIOUS_OR_CURRENT_VERB_TAG, PREVIOUS_OR_CURRENT_VERB_LEMMA, DYNAMIC_TOTAL };
  enum features_map { MAP_NONE = -1, MAP_FORM, MAP_PREFIX1, MAP_PREFIX2, MAP_PREFIX3, MAP_PREFIX4, MAP_PREFIX5, MAP_PREFIX6, MAP_PREFIX7, MAP_PREFIX8, MAP_PREFIX9, MAP_SUFFIX1, MAP_SUFFIX2, MAP_SUFFIX3, MAP_SUFFIX4, MAP_SUFFIX5, MAP_SUFFIX6, MAP_SUFFIX7, MAP_SUFFIX8, MAP_SUFFIX9, MAP_TAG, MAP_TAG1, MAP_TAG2, MAP_TAG3, MAP_TAG4, MAP_TAG5, MAP_LEMMA, MAP_TOTAL } ;

  struct per_form_features { elementary_feature_value values[PER_FORM_TOTAL]; };
  struct per_tag_features { elementary_feature_value values[PER_TAG_TOTAL]; };
  struct dynamic_features { elementary_feature_value values[DYNAMIC_TOTAL]; };

  static vector<elementary_feature_description> descriptions;

  void compute_features(const vector<string_piece>& forms, const vector<vector<tagged_lemma>>& analyses, vector<per_form_features>& per_form, vector<vector<per_tag_features>>& per_tag) const;
  inline void compute_dynamic_features(const tagged_lemma& tag, const per_form_features& per_form, const per_tag_features& per_tag, const dynamic_features* prev_dynamic, dynamic_features& dynamic) const;

  using elementary_features<Map>::maps;
};

typedef generic_elementary_features<persistent_elementary_feature_map> persistent_generic_elementary_features;

// Definitions
template <class Map>
generic_elementary_features<Map>::generic_elementary_features() {
  maps.resize(MAP_TOTAL);
}

template <class Map>
vector<elementary_feature_description> generic_elementary_features<Map>::descriptions = {
  {"Form", PER_FORM, ANY_OFFSET, FORM, MAP_FORM},
  {"FollowingVerbTag", PER_FORM, ANY_OFFSET, FOLLOWING_VERB_TAG, MAP_TAG},
  {"FollowingVerbLemma", PER_FORM, ANY_OFFSET, FOLLOWING_VERB_LEMMA, MAP_LEMMA },
  {"Num", PER_FORM, ONLY_CURRENT, NUM, MAP_NONE},
  {"Cap", PER_FORM, ONLY_CURRENT, CAP, MAP_NONE},
  {"Dash", PER_FORM, ONLY_CURRENT, DASH, MAP_NONE},
  {"Prefix1", PER_FORM, ONLY_CURRENT, PREFIX1, MAP_PREFIX1},
  {"Prefix2", PER_FORM, ONLY_CURRENT, PREFIX2, MAP_PREFIX2},
  {"Prefix3", PER_FORM, ONLY_CURRENT, PREFIX3, MAP_PREFIX3},
  {"Prefix4", PER_FORM, ONLY_CURRENT, PREFIX4, MAP_PREFIX4},
  {"Prefix5", PER_FORM, ONLY_CURRENT, PREFIX5, MAP_PREFIX5},
  {"Prefix6", PER_FORM, ONLY_CURRENT, PREFIX6, MAP_PREFIX6},
  {"Prefix7", PER_FORM, ONLY_CURRENT, PREFIX7, MAP_PREFIX7},
  {"Prefix8", PER_FORM, ONLY_CURRENT, PREFIX8, MAP_PREFIX8},
  {"Prefix9", PER_FORM, ONLY_CURRENT, PREFIX9, MAP_PREFIX9},
  {"Suffix1", PER_FORM, ONLY_CURRENT, SUFFIX1, MAP_SUFFIX1},
  {"Suffix2", PER_FORM, ONLY_CURRENT, SUFFIX2, MAP_SUFFIX2},
  {"Suffix3", PER_FORM, ONLY_CURRENT, SUFFIX3, MAP_SUFFIX3},
  {"Suffix4", PER_FORM, ONLY_CURRENT, SUFFIX4, MAP_SUFFIX4},
  {"Suffix5", PER_FORM, ONLY_CURRENT, SUFFIX5, MAP_SUFFIX5},
  {"Suffix6", PER_FORM, ONLY_CURRENT, SUFFIX6, MAP_SUFFIX6},
  {"Suffix7", PER_FORM, ONLY_CURRENT, SUFFIX7, MAP_SUFFIX7},
  {"Suffix8", PER_FORM, ONLY_CURRENT, SUFFIX8, MAP_SUFFIX8},
  {"Suffix9", PER_FORM, ONLY_CURRENT, SUFFIX9, MAP_SUFFIX9},

  {"Tag", PER_TAG, ANY_OFFSET, TAG, MAP_TAG},
  {"Tag1", PER_TAG, ANY_OFFSET, TAG1, MAP_TAG1},
  {"Tag2", PER_TAG, ANY_OFFSET, TAG2, MAP_TAG2},
  {"Tag3", PER_TAG, ANY_OFFSET, TAG3, MAP_TAG3},
  {"Tag4", PER_TAG, ANY_OFFSET, TAG4, MAP_TAG4},
  {"Tag5", PER_TAG, ANY_OFFSET, TAG5, MAP_TAG5},
  {"Lemma", PER_TAG, ANY_OFFSET, LEMMA, MAP_LEMMA},

  {"PreviousVerbTag", DYNAMIC, ANY_OFFSET, PREVIOUS_VERB_TAG, MAP_TAG},
  {"PreviousVerbLemma", DYNAMIC, ANY_OFFSET, PREVIOUS_VERB_LEMMA, MAP_LEMMA}
};

template <class Map>
void generic_elementary_features<Map>::compute_features(const vector<string_piece>& forms, const vector<vector<tagged_lemma>>& analyses, vector<per_form_features>& per_form, vector<vector<per_tag_features>>& per_tag) const {
  using namespace unilib;

  // We process the sentence in reverse order, so that we can compute FollowingVerbTag and FollowingVerbLemma directly.
  elementary_feature_value following_verb_tag = elementary_feature_empty, following_verb_lemma = elementary_feature_empty;
  for (unsigned i = forms.size(); i--;) {
    int verb_candidate = -1;

    // Per_tag features and verb_candidate
    for (unsigned j = 0; j < analyses[i].size(); j++) {
      per_tag[i][j].values[TAG] = maps[MAP_TAG].value(analyses[i][j].tag.c_str(), analyses[i][j].tag.size());
      per_tag[i][j].values[TAG1] = analyses[i][j].tag.size() >= 1 ? maps[MAP_TAG1].value(analyses[i][j].tag.c_str() + 0, 1) : elementary_feature_empty;
      per_tag[i][j].values[TAG2] = analyses[i][j].tag.size() >= 2 ? maps[MAP_TAG2].value(analyses[i][j].tag.c_str() + 1, 1) : elementary_feature_empty;
      per_tag[i][j].values[TAG3] = analyses[i][j].tag.size() >= 3 ? maps[MAP_TAG3].value(analyses[i][j].tag.c_str() + 2, 1) : elementary_feature_empty;
      per_tag[i][j].values[TAG4] = analyses[i][j].tag.size() >= 4 ? maps[MAP_TAG4].value(analyses[i][j].tag.c_str() + 3, 1) : elementary_feature_empty;
      per_tag[i][j].values[TAG5] = analyses[i][j].tag.size() >= 5 ? maps[MAP_TAG5].value(analyses[i][j].tag.c_str() + 4, 1) : elementary_feature_empty;
      per_tag[i][j].values[LEMMA] = j && analyses[i][j-1].lemma == analyses[i][j].lemma ? per_tag[i][j-1].values[LEMMA] :
          maps[MAP_LEMMA].value(analyses[i][j].lemma.c_str(), analyses[i][j].lemma.size());

      if (analyses[i][j].tag[0] == 'V') {
        int tag_compare;
        verb_candidate = verb_candidate < 0 || (tag_compare = analyses[i][j].tag.compare(analyses[i][verb_candidate].tag), tag_compare < 0) || (tag_compare == 0 && analyses[i][j].lemma < analyses[i][verb_candidate].lemma) ? j : verb_candidate;
      }
    }

    // Per_form features
    per_form[i].values[FORM] = maps[MAP_FORM].value(forms[i].str, forms[i].len);
    per_form[i].values[FOLLOWING_VERB_TAG] = following_verb_tag;
    per_form[i].values[FOLLOWING_VERB_LEMMA] = following_verb_lemma;

    // Update following_verb_{tag,lemma} _after_ filling FOLLOWING_VERB_{TAG,LEMMA}.
    if (verb_candidate >= 0) {
      following_verb_tag = per_tag[i][verb_candidate].values[TAG];
      following_verb_lemma = per_tag[i][verb_candidate].values[LEMMA];
    }

    // Ortographic per_form features if needed
    if (analyses[i].size() == 1) {
      per_form[i].values[NUM] = per_form[i].values[CAP] = per_form[i].values[DASH] = elementary_feature_unknown;
      per_form[i].values[PREFIX1] = per_form[i].values[PREFIX2] = per_form[i].values[PREFIX3] = elementary_feature_unknown;
      per_form[i].values[PREFIX4] = per_form[i].values[PREFIX5] = per_form[i].values[PREFIX6] = elementary_feature_unknown;
      per_form[i].values[PREFIX7] = per_form[i].values[PREFIX8] = per_form[i].values[PREFIX9] = elementary_feature_unknown;
      per_form[i].values[SUFFIX1] = per_form[i].values[SUFFIX2] = per_form[i].values[SUFFIX3] = elementary_feature_unknown;
      per_form[i].values[SUFFIX4] = per_form[i].values[SUFFIX5] = per_form[i].values[SUFFIX6] = elementary_feature_unknown;
      per_form[i].values[SUFFIX7] = per_form[i].values[SUFFIX8] = per_form[i].values[SUFFIX9] = elementary_feature_unknown;
    } else if (forms[i].len <= 0) {
      per_form[i].values[NUM] = per_form[i].values[CAP] = per_form[i].values[DASH] = elementary_feature_empty + 1;
      per_form[i].values[PREFIX1] = per_form[i].values[PREFIX2] = per_form[i].values[PREFIX3] = elementary_feature_empty;
      per_form[i].values[PREFIX4] = per_form[i].values[PREFIX5] = per_form[i].values[PREFIX6] = elementary_feature_empty;
      per_form[i].values[PREFIX7] = per_form[i].values[PREFIX8] = per_form[i].values[PREFIX9] = elementary_feature_empty;
      per_form[i].values[SUFFIX1] = per_form[i].values[SUFFIX2] = per_form[i].values[SUFFIX3] = elementary_feature_empty;
      per_form[i].values[SUFFIX4] = per_form[i].values[SUFFIX5] = per_form[i].values[SUFFIX6] = elementary_feature_empty;
      per_form[i].values[SUFFIX7] = per_form[i].values[SUFFIX8] = per_form[i].values[SUFFIX9] = elementary_feature_empty;
    } else {
      string_piece form = forms[i];
      const char* form_start = form.str;

      bool num = false, cap = false, dash = false;
      size_t indices[18] = {0, form.len, form.len, form.len, form.len, form.len, form.len, form.len, form.len, form.len, 0, 0, 0, 0, 0, 0, 0, 0}; // careful here regarding forms shorter than 9 characters
      int index = 0;
      while (form.len) {
        indices[(index++) % 18] = form.str - form_start;

        unicode::category_t cat = unicode::category(utf8::decode(form.str, form.len));
        num = num || cat & unicode::N;
        cap = cap || cat & unicode::Lut;
        dash = dash || cat & unicode::Pd;

        if (index == 10 || (!form.len && index < 10)) {
          per_form[i].values[PREFIX1] = maps[MAP_PREFIX1].value(form_start, indices[1]);
          per_form[i].values[PREFIX2] = maps[MAP_PREFIX2].value(form_start, indices[2]);
          per_form[i].values[PREFIX3] = maps[MAP_PREFIX3].value(form_start, indices[3]);
          per_form[i].values[PREFIX4] = maps[MAP_PREFIX4].value(form_start, indices[4]);
          per_form[i].values[PREFIX5] = maps[MAP_PREFIX5].value(form_start, indices[5]);
          per_form[i].values[PREFIX6] = maps[MAP_PREFIX6].value(form_start, indices[6]);
          per_form[i].values[PREFIX7] = maps[MAP_PREFIX7].value(form_start, indices[7]);
          per_form[i].values[PREFIX8] = maps[MAP_PREFIX8].value(form_start, indices[8]);
          per_form[i].values[PREFIX9] = maps[MAP_PREFIX9].value(form_start, indices[9]);
        }
      }
      per_form[i].values[SUFFIX1] = maps[MAP_SUFFIX1].value(form_start + indices[(index+18-1) % 18], form.str - form_start - indices[(index+18-1) % 18]);
      per_form[i].values[SUFFIX2] = maps[MAP_SUFFIX2].value(form_start + indices[(index+18-2) % 18], form.str - form_start - indices[(index+18-2) % 18]);
      per_form[i].values[SUFFIX3] = maps[MAP_SUFFIX3].value(form_start + indices[(index+18-3) % 18], form.str - form_start - indices[(index+18-3) % 18]);
      per_form[i].values[SUFFIX4] = maps[MAP_SUFFIX4].value(form_start + indices[(index+18-4) % 18], form.str - form_start - indices[(index+18-4) % 18]);
      per_form[i].values[SUFFIX5] = maps[MAP_SUFFIX5].value(form_start + indices[(index+18-5) % 18], form.str - form_start - indices[(index+18-5) % 18]);
      per_form[i].values[SUFFIX6] = maps[MAP_SUFFIX6].value(form_start + indices[(index+18-6) % 18], form.str - form_start - indices[(index+18-6) % 18]);
      per_form[i].values[SUFFIX7] = maps[MAP_SUFFIX7].value(form_start + indices[(index+18-7) % 18], form.str - form_start - indices[(index+18-7) % 18]);
      per_form[i].values[SUFFIX8] = maps[MAP_SUFFIX8].value(form_start + indices[(index+18-8) % 18], form.str - form_start - indices[(index+18-8) % 18]);
      per_form[i].values[SUFFIX9] = maps[MAP_SUFFIX9].value(form_start + indices[(index+18-9) % 18], form.str - form_start - indices[(index+18-9) % 18]);
      per_form[i].values[NUM] = elementary_feature_empty + 1 + num;
      per_form[i].values[CAP] = elementary_feature_empty + 1 + cap;
      per_form[i].values[DASH] = elementary_feature_empty + 1 + dash;
    }
  }
}

template <class Map>
void generic_elementary_features<Map>::compute_dynamic_features(const tagged_lemma& tag, const per_form_features& /*per_form*/, const per_tag_features& per_tag, const dynamic_features* prev_dynamic, dynamic_features& dynamic) const {
  if (prev_dynamic) {
    dynamic.values[PREVIOUS_VERB_TAG] = prev_dynamic->values[PREVIOUS_OR_CURRENT_VERB_TAG];
    dynamic.values[PREVIOUS_VERB_LEMMA] = prev_dynamic->values[PREVIOUS_OR_CURRENT_VERB_LEMMA];
  } else {
    dynamic.values[PREVIOUS_VERB_TAG] = elementary_feature_empty;
    dynamic.values[PREVIOUS_VERB_LEMMA] = elementary_feature_empty;
  }

  if (tag.tag[0] == 'V') {
    dynamic.values[PREVIOUS_OR_CURRENT_VERB_TAG] = per_tag.values[TAG];
    dynamic.values[PREVIOUS_OR_CURRENT_VERB_LEMMA] = per_tag.values[LEMMA];
  } else {
    dynamic.values[PREVIOUS_OR_CURRENT_VERB_TAG] = dynamic.values[PREVIOUS_VERB_TAG];
    dynamic.values[PREVIOUS_OR_CURRENT_VERB_LEMMA] = dynamic.values[PREVIOUS_VERB_LEMMA];
  }
}

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

namespace utils {

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

} // namespace utils

/////////
// File: tagger/perceptron_tagger.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Declarations
template<class FeatureSequences>
class perceptron_tagger : public tagger {
 public:
  perceptron_tagger(int decoding_order, int window_size);

  bool load(istream& is);
  virtual const morpho* get_morpho() const override;
  virtual void tag(const vector<string_piece>& forms, vector<tagged_lemma>& tags, morpho::guesser_mode guesser = morpho::guesser_mode(-1)) const override;
  virtual void tag_analyzed(const vector<string_piece>& forms, const vector<vector<tagged_lemma>>& analyses, vector<int>& tags) const override;

 private:
  int decoding_order, window_size;

  unique_ptr<morpho> dict;
  bool use_guesser;
  FeatureSequences features;
  typedef viterbi<FeatureSequences> viterbi_decoder;
  viterbi_decoder decoder;
  struct cache {
    vector<string_piece> forms;
    vector<vector<tagged_lemma>> analyses;
    vector<int> tags;
    typename viterbi_decoder::cache decoder_cache;

    cache(const perceptron_tagger<FeatureSequences>& self) : decoder_cache(self.decoder) {}
  };

  mutable threadsafe_stack<cache> caches;
};

// Definitions

template<class FeatureSequences>
perceptron_tagger<FeatureSequences>::perceptron_tagger(int decoding_order, int window_size)
  : decoding_order(decoding_order), window_size(window_size), decoder(features, decoding_order, window_size) {}

template<class FeatureSequences>
bool perceptron_tagger<FeatureSequences>::load(istream& is) {
  if (dict.reset(morpho::load(is)), !dict) return false;
  use_guesser = is.get();
  if (!features.load(is)) return false;
  return true;
}

template<class FeatureSequences>
const morpho* perceptron_tagger<FeatureSequences>::get_morpho() const {
  return dict.get();
}

template<class FeatureSequences>
void perceptron_tagger<FeatureSequences>::tag(const vector<string_piece>& forms, vector<tagged_lemma>& tags, morpho::guesser_mode guesser) const {
  tags.clear();
  if (!dict) return;

  cache* c = caches.pop();
  if (!c) c = new cache(*this);

  c->forms.resize(forms.size());
  if (c->analyses.size() < forms.size()) c->analyses.resize(forms.size());
  for (unsigned i = 0; i < forms.size(); i++) {
    c->forms[i] = forms[i];
    c->forms[i].len = dict->raw_form_len(forms[i]);
    dict->analyze(forms[i], guesser >= 0 ? guesser : use_guesser ? morpho::GUESSER : morpho::NO_GUESSER, c->analyses[i]);
  }

  if (c->tags.size() < forms.size()) c->tags.resize(forms.size() * 2);
  decoder.tag(c->forms, c->analyses, c->decoder_cache, c->tags);

  for (unsigned i = 0; i < forms.size(); i++)
    tags.emplace_back(c->analyses[i][c->tags[i]]);

  caches.push(c);
}

template<class FeatureSequences>
void perceptron_tagger<FeatureSequences>::tag_analyzed(const vector<string_piece>& forms, const vector<vector<tagged_lemma>>& analyses, vector<int>& tags) const {
  tags.clear();

  cache* c = caches.pop();
  if (!c) c = new cache(*this);

  tags.resize(forms.size());
  decoder.tag(forms, analyses, c->decoder_cache, tags);

  caches.push(c);
}

/////////
// File: tagger/tagger_ids.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class tagger_ids {
 public:
  enum tagger_id {
    CZECH2 = 0, CZECH3 = 1, CZECH2_3 = 6,
    /* 2 was used internally for ENGLISH3, but never released publicly */
    GENERIC2 = 3, GENERIC3 = 4, GENERIC4 = 5, GENERIC2_3 = 7,
    CONLLU2 = 8, CONLLU2_3 = 9, CONLLU3 = 10,
  };

  static bool parse(const string& str, tagger_id& id) {
    if (str == "czech2") return id = CZECH2, true;
    if (str == "czech2_3") return id = CZECH2_3, true;
    if (str == "czech3") return id = CZECH3, true;
    if (str == "generic2") return id = GENERIC2, true;
    if (str == "generic2_3") return id = GENERIC2_3, true;
    if (str == "generic3") return id = GENERIC3, true;
    if (str == "generic4") return id = GENERIC4, true;
    if (str == "conllu2") return id = CONLLU2, true;
    if (str == "conllu2_3") return id = CONLLU2_3, true;
    if (str == "conllu3") return id = CONLLU3, true;
    return false;
  }

  static int decoding_order(tagger_id id) {
    switch (id) {
      case CZECH2: return 2;
      case CZECH2_3: return 2;
      case CZECH3: return 3;
      case GENERIC2: return 2;
      case GENERIC2_3: return 2;
      case GENERIC3: return 3;
      case GENERIC4: return 4;
      case CONLLU2: return 2;
      case CONLLU2_3: return 2;
      case CONLLU3: return 3;
    }
    return 0;
  }

  static int window_size(tagger_id id) {
    switch (id) {
      case CZECH2_3: return 3;
      case GENERIC2_3: return 3;
      case CONLLU2_3: return 3;
      default: break;
    }
    return decoding_order(id);
  }
};

typedef tagger_ids::tagger_id tagger_id;

/////////
// File: tagger/tagger.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

tagger* tagger::load(istream& is) {
  tagger_id id = tagger_id(is.get());
  switch (id) {
    case tagger_ids::CZECH2:
    case tagger_ids::CZECH2_3:
    case tagger_ids::CZECH3:
      {
        auto res = new_unique_ptr<perceptron_tagger<persistent_feature_sequences<persistent_czech_elementary_features>>>(tagger_ids::decoding_order(id), tagger_ids::window_size(id));
        if (res->load(is)) return res.release();
        break;
      }
    case tagger_ids::GENERIC2:
    case tagger_ids::GENERIC2_3:
    case tagger_ids::GENERIC3:
    case tagger_ids::GENERIC4:
      {
        auto res = new_unique_ptr<perceptron_tagger<persistent_feature_sequences<persistent_generic_elementary_features>>>(tagger_ids::decoding_order(id), tagger_ids::window_size(id));
        if (res->load(is)) return res.release();
        break;
      }
    case tagger_ids::CONLLU2:
    case tagger_ids::CONLLU2_3:
    case tagger_ids::CONLLU3:
      {
        auto res = new_unique_ptr<perceptron_tagger<persistent_feature_sequences<persistent_conllu_elementary_features>>>(tagger_ids::decoding_order(id), tagger_ids::window_size(id));
        if (res->load(is)) return res.release();
        break;
      }
  }

  return nullptr;
}

tagger* tagger::load(const char* fname) {
  ifstream f(fname, ifstream::binary);
  if (!f) return nullptr;

  return load(f);
}

tokenizer* tagger::new_tokenizer() const {
  auto morpho = get_morpho();
  return morpho ? morpho->new_tokenizer() : nullptr;
}

/////////
// File: tagset_converter/tagset_converter.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class tagset_converter {
 public:
  virtual ~tagset_converter() {}

  // Convert a tag-lemma pair to a different tag set.
  virtual void convert(tagged_lemma& tagged_lemma) const = 0;
  // Convert a result of analysis to a different tag set. Apart from calling
  // convert, any repeated entry is removed.
  virtual void convert_analyzed(vector<tagged_lemma>& tagged_lemmas) const = 0;
  // Convert a result of generation to a different tag set. Apart from calling
  // convert, any repeated entry is removed.
  virtual void convert_generated(vector<tagged_lemma_forms>& forms) const = 0;

  // Static factory methods
  static tagset_converter* new_identity_converter();

  static tagset_converter* new_pdt_to_conll2009_converter();
  static tagset_converter* new_strip_lemma_comment_converter(const morpho& dictionary);
  static tagset_converter* new_strip_lemma_id_converter(const morpho& dictionary);
};

// Helper method for creating tagset_converter from instance name.
tagset_converter* new_tagset_converter(const string& name, const morpho& dictionary);

// Helper methods making sure remapped results are unique.
void tagset_converter_unique_analyzed(vector<tagged_lemma>& tagged_lemmas);
void tagset_converter_unique_generated(vector<tagged_lemma_forms>& forms);

/////////
// File: tagset_converter/identity_tagset_converter.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class identity_tagset_converter : public tagset_converter {
 public:
  virtual void convert(tagged_lemma& tagged_lemma) const override;
  virtual void convert_analyzed(vector<tagged_lemma>& tagged_lemmas) const override;
  virtual void convert_generated(vector<tagged_lemma_forms>& forms) const override;
};

/////////
// File: tagset_converter/identity_tagset_converter.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

void identity_tagset_converter::convert(tagged_lemma& /*tagged_lemma*/) const {}

void identity_tagset_converter::convert_analyzed(vector<tagged_lemma>& /*tagged_lemmas*/) const {}

void identity_tagset_converter::convert_generated(vector<tagged_lemma_forms>& /*forms*/) const {}

/////////
// File: tagset_converter/pdt_to_conll2009_tagset_converter.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class pdt_to_conll2009_tagset_converter : public tagset_converter {
 public:
  virtual void convert(tagged_lemma& tagged_lemma) const override;
  virtual void convert_analyzed(vector<tagged_lemma>& tagged_lemmas) const override;
  virtual void convert_generated(vector<tagged_lemma_forms>& forms) const override;

 private:
  inline void convert_tag(const string& lemma, string& tag) const;
  inline bool convert_lemma(string& lemma) const;
};

/////////
// File: tagset_converter/pdt_to_conll2009_tagset_converter.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

static const char* names[15] = {"POS", "SubPOS", "Gen", "Num", "Cas", "PGe", "PNu", "Per", "Ten", "Gra", "Neg", "Voi", "", "", "Var"};

inline void pdt_to_conll2009_tagset_converter::convert_tag(const string& lemma, string& tag) const {
  char pdt_tag[15];
  strncpy(pdt_tag, tag.c_str(), 15);

  // Clear the tag
  tag.clear();

  // Fill FEAT of filled tag characters
  for (int i = 0; i < 15 && pdt_tag[i]; i++)
    if (pdt_tag[i] != '-') {
      if (!tag.empty()) tag.push_back('|');
      tag.append(names[i]);
      tag.push_back('=');
      tag.push_back(pdt_tag[i]);
    }

  // Try adding Sem FEAT
  for (unsigned i = 0; i + 2 < lemma.size(); i++)
    if (lemma[i] == '_' && lemma[i + 1] == ';') {
      if (!tag.empty()) tag.push_back('|');
      tag.append("Sem=");
      tag.push_back(lemma[i + 2]);
      break;
    }
}

inline bool pdt_to_conll2009_tagset_converter::convert_lemma(string& lemma) const {
  unsigned raw_lemma = czech_lemma_addinfo::raw_lemma_len(lemma);
  return raw_lemma < lemma.size() ? (lemma.resize(raw_lemma), true) : false;
}

void pdt_to_conll2009_tagset_converter::convert(tagged_lemma& tagged_lemma) const {
  convert_tag(tagged_lemma.lemma, tagged_lemma.tag);
  convert_lemma(tagged_lemma.lemma);
}

void pdt_to_conll2009_tagset_converter::convert_analyzed(vector<tagged_lemma>& tagged_lemmas) const {
  bool lemma_changed = false;

  for (auto&& tagged_lemma : tagged_lemmas) {
    convert_tag(tagged_lemma.lemma, tagged_lemma.tag);
    lemma_changed |= convert_lemma(tagged_lemma.lemma);
  }

  // If no lemma was changed or there is 1 analysis, no duplicates could be created.
  if (!lemma_changed || tagged_lemmas.size() < 2) return;

  tagset_converter_unique_analyzed(tagged_lemmas);
}

void pdt_to_conll2009_tagset_converter::convert_generated(vector<tagged_lemma_forms>& forms) const {
  bool lemma_changed = false;

  for (auto&& tagged_lemma_forms : forms) {
    for (auto&& tagged_form : tagged_lemma_forms.forms)
      convert_tag(tagged_lemma_forms.lemma, tagged_form.tag);
    lemma_changed |= convert_lemma(tagged_lemma_forms.lemma);
  }

  // If no lemma was changed or there is 1 analysis, no duplicates could be created.
  if (!lemma_changed || forms.size() < 2) return;

  tagset_converter_unique_generated(forms);
}

/////////
// File: tagset_converter/strip_lemma_comment_tagset_converter.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class strip_lemma_comment_tagset_converter : public tagset_converter {
 public:
  strip_lemma_comment_tagset_converter(const morpho& dictionary) : dictionary(dictionary) {}

  virtual void convert(tagged_lemma& tagged_lemma) const override;
  virtual void convert_analyzed(vector<tagged_lemma>& tagged_lemmas) const override;
  virtual void convert_generated(vector<tagged_lemma_forms>& forms) const override;

 private:
  inline bool convert_lemma(string& lemma) const;
  const morpho& dictionary;
};

/////////
// File: tagset_converter/strip_lemma_comment_tagset_converter.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

inline bool strip_lemma_comment_tagset_converter::convert_lemma(string& lemma) const {
  unsigned lemma_id_len = dictionary.lemma_id_len(lemma);
  return lemma_id_len < lemma.size() ? (lemma.resize(lemma_id_len), true) : false;
}

void strip_lemma_comment_tagset_converter::convert(tagged_lemma& tagged_lemma) const {
  convert_lemma(tagged_lemma.lemma);
}

void strip_lemma_comment_tagset_converter::convert_analyzed(vector<tagged_lemma>& tagged_lemmas) const {
  bool lemma_changed = false;

  for (auto&& tagged_lemma : tagged_lemmas)
    lemma_changed |= convert_lemma(tagged_lemma.lemma);

  // If no lemma was changed or there is 1 analysis, no duplicates could be created.
  if (!lemma_changed || tagged_lemmas.size() < 2) return;

  tagset_converter_unique_analyzed(tagged_lemmas);
}

void strip_lemma_comment_tagset_converter::convert_generated(vector<tagged_lemma_forms>& forms) const {
  bool lemma_changed = false;

  for (auto&& tagged_lemma_forms : forms)
    lemma_changed |= convert_lemma(tagged_lemma_forms.lemma);

  // If no lemma was changed or there is 1 analysis, no duplicates could be created.
  if (!lemma_changed || forms.size() < 2) return;

  tagset_converter_unique_generated(forms);
}

/////////
// File: tagset_converter/strip_lemma_id_tagset_converter.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class strip_lemma_id_tagset_converter : public tagset_converter {
 public:
  strip_lemma_id_tagset_converter(const morpho& dictionary) : dictionary(dictionary) {}

  virtual void convert(tagged_lemma& tagged_lemma) const override;
  virtual void convert_analyzed(vector<tagged_lemma>& tagged_lemmas) const override;
  virtual void convert_generated(vector<tagged_lemma_forms>& forms) const override;

 private:
  inline bool convert_lemma(string& lemma) const;
  const morpho& dictionary;
};

/////////
// File: tagset_converter/strip_lemma_id_tagset_converter.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

inline bool strip_lemma_id_tagset_converter::convert_lemma(string& lemma) const {
  unsigned raw_lemma_len = dictionary.raw_lemma_len(lemma);
  return raw_lemma_len < lemma.size() ? (lemma.resize(raw_lemma_len), true) : false;
}

void strip_lemma_id_tagset_converter::convert(tagged_lemma& tagged_lemma) const {
  convert_lemma(tagged_lemma.lemma);
}

void strip_lemma_id_tagset_converter::convert_analyzed(vector<tagged_lemma>& tagged_lemmas) const {
  bool lemma_changed = false;

  for (auto&& tagged_lemma : tagged_lemmas)
    lemma_changed |= convert_lemma(tagged_lemma.lemma);

  // If no lemma was changed or there is 1 analysis, no duplicates could be created.
  if (!lemma_changed || tagged_lemmas.size() < 2) return;

  tagset_converter_unique_analyzed(tagged_lemmas);
}

void strip_lemma_id_tagset_converter::convert_generated(vector<tagged_lemma_forms>& forms) const {
  bool lemma_changed = false;

  for (auto&& tagged_lemma_forms : forms)
    lemma_changed |= convert_lemma(tagged_lemma_forms.lemma);

  // If no lemma was changed or there is 1 analysis, no duplicates could be created.
  if (!lemma_changed || forms.size() < 2) return;

  tagset_converter_unique_generated(forms);
}

/////////
// File: tagset_converter/tagset_converter.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

tagset_converter* tagset_converter::new_identity_converter() {
  return new identity_tagset_converter();
}

tagset_converter* tagset_converter::new_pdt_to_conll2009_converter() {
  return new pdt_to_conll2009_tagset_converter();
}

tagset_converter* tagset_converter::new_strip_lemma_comment_converter(const morpho& dictionary) {
  return new strip_lemma_comment_tagset_converter(dictionary);
}

tagset_converter* tagset_converter::new_strip_lemma_id_converter(const morpho& dictionary) {
  return new strip_lemma_id_tagset_converter(dictionary);
}

tagset_converter* new_tagset_converter(const string& name, const morpho& dictionary) {
  if (name == "pdt_to_conll2009") return tagset_converter::new_pdt_to_conll2009_converter();
  if (name == "strip_lemma_comment") return tagset_converter::new_strip_lemma_comment_converter(dictionary);
  if (name == "strip_lemma_id") return tagset_converter::new_strip_lemma_id_converter(dictionary);
  return nullptr;
}

void tagset_converter_unique_analyzed(vector<tagged_lemma>& tagged_lemmas) {
  // Remove possible lemma-tag pair duplicates
  struct tagged_lemma_comparator {
    inline static bool eq(const tagged_lemma& a, const tagged_lemma& b) { return a.lemma == b.lemma && a.tag == b.tag; }
    inline static bool lt(const tagged_lemma& a, const tagged_lemma& b) { int lemma_compare = a.lemma.compare(b.lemma); return lemma_compare < 0 || (lemma_compare == 0 && a.tag < b.tag); }
  };

  sort(tagged_lemmas.begin(), tagged_lemmas.end(), tagged_lemma_comparator::lt);
  tagged_lemmas.resize(unique(tagged_lemmas.begin(), tagged_lemmas.end(), tagged_lemma_comparator::eq) - tagged_lemmas.begin());
}

void tagset_converter_unique_generated(vector<tagged_lemma_forms>& forms) {
  // Regroup and if needed remove duplicate form-tag pairs for each lemma
  for (unsigned i = 0; i < forms.size(); i++) {
    bool any_merged = false;
    for (unsigned j = forms.size() - 1; j > i; j--)
      if (forms[j].lemma == forms[i].lemma) {
        // Same lemma was found. Merge form-tag pairs
        for (auto&& tagged_form : forms[j].forms)
          forms[i].forms.emplace_back(move(tagged_form));

        // Remove lemma j by moving it to end and deleting
        if (j < forms.size() - 1) {
          forms[j].lemma.swap(forms[forms.size() - 1].lemma);
          forms[j].forms.swap(forms[forms.size() - 1].forms);
        }
        forms.pop_back();
        any_merged = true;
      }

    if (any_merged && forms[i].forms.size() > 1) {
      // Remove duplicate form-tag pairs
      struct tagged_form_comparator {
        inline static bool eq(const tagged_form& a, const tagged_form& b) { return a.tag == b.tag && a.form == b.form; }
        inline static bool lt(const tagged_form& a, const tagged_form& b) { int tag_compare = a.tag.compare(b.tag); return tag_compare < 0 || (tag_compare == 0 && a.form < b.form); }
      };

      sort(forms[i].forms.begin(), forms[i].forms.end(), tagged_form_comparator::lt);
      forms[i].forms.resize(unique(forms[i].forms.begin(), forms[i].forms.end(), tagged_form_comparator::eq) - forms[i].forms.begin());
    }
  }
}

/////////
// File: tokenizer/czech_tokenizer.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

static const char _czech_tokenizer_cond_offsets[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2
};

static const char _czech_tokenizer_cond_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 2, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0
};

static const short _czech_tokenizer_cond_keys[] = {
	43u, 43u, 45u, 45u, 0
};

static const char _czech_tokenizer_cond_spaces[] = {
	1, 0, 0
};

static const unsigned char _czech_tokenizer_key_offsets[] = {
	0, 0, 17, 29, 43, 46, 51, 54, 
	89, 94, 98, 101, 105, 110, 111, 116, 
	117, 122, 136, 143, 148, 151, 163
};

static const short _czech_tokenizer_trans_keys[] = {
	13u, 32u, 34u, 40u, 91u, 96u, 123u, 129u, 
	133u, 135u, 147u, 150u, 162u, 9u, 10u, 65u, 
	90u, 34u, 40u, 91u, 96u, 123u, 129u, 133u, 
	135u, 150u, 162u, 65u, 90u, 13u, 32u, 34u, 
	39u, 41u, 59u, 93u, 125u, 139u, 141u, 147u, 
	161u, 9u, 10u, 159u, 48u, 57u, 43u, 45u, 
	159u, 48u, 57u, 159u, 48u, 57u, 9u, 10u, 
	13u, 32u, 33u, 44u, 46u, 47u, 63u, 129u, 
	131u, 135u, 142u, 147u, 157u, 159u, 160u, 301u, 
	557u, 811u, 1067u, 0u, 42u, 48u, 57u, 58u, 
	64u, 65u, 90u, 91u, 96u, 97u, 122u, 123u, 
	255u, 9u, 10u, 13u, 32u, 147u, 9u, 13u, 
	32u, 147u, 9u, 32u, 147u, 9u, 10u, 32u, 
	147u, 9u, 10u, 13u, 32u, 147u, 13u, 9u, 
	10u, 13u, 32u, 147u, 10u, 9u, 10u, 13u, 
	32u, 147u, 13u, 32u, 34u, 39u, 41u, 59u, 
	93u, 125u, 139u, 141u, 147u, 161u, 9u, 10u, 
	44u, 46u, 69u, 101u, 159u, 48u, 57u, 69u, 
	101u, 159u, 48u, 57u, 159u, 48u, 57u, 129u, 
	131u, 135u, 151u, 155u, 157u, 65u, 90u, 97u, 
	122u, 142u, 143u, 159u, 48u, 57u, 0
};

static const char _czech_tokenizer_single_lengths[] = {
	0, 13, 10, 12, 1, 3, 1, 21, 
	5, 4, 3, 4, 5, 1, 5, 1, 
	5, 12, 5, 3, 1, 6, 1
};

static const char _czech_tokenizer_range_lengths[] = {
	0, 2, 1, 1, 1, 1, 1, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 1, 1, 1, 1, 3, 1
};

static const unsigned char _czech_tokenizer_index_offsets[] = {
	0, 0, 16, 28, 42, 45, 50, 53, 
	82, 88, 93, 97, 102, 108, 110, 116, 
	118, 124, 138, 145, 150, 153, 163
};

static const char _czech_tokenizer_indicies[] = {
	1, 1, 2, 2, 2, 2, 2, 3, 
	2, 3, 1, 2, 2, 1, 3, 0, 
	2, 2, 2, 2, 2, 3, 2, 3, 
	2, 2, 3, 0, 4, 4, 5, 5, 
	5, 5, 5, 5, 5, 5, 4, 5, 
	4, 0, 6, 6, 0, 7, 7, 8, 
	8, 0, 8, 8, 0, 10, 11, 12, 
	10, 13, 9, 13, 9, 13, 16, 16, 
	16, 16, 10, 16, 15, 13, 9, 17, 
	9, 17, 9, 15, 9, 16, 9, 16, 
	9, 14, 10, 19, 20, 10, 10, 18, 
	10, 21, 10, 10, 18, 10, 10, 10, 
	18, 10, 21, 10, 10, 18, 10, 22, 
	23, 10, 10, 18, 25, 24, 10, 22, 
	26, 10, 10, 18, 25, 24, 10, 23, 
	26, 10, 10, 18, 4, 4, 5, 5, 
	5, 5, 5, 5, 5, 5, 4, 5, 
	4, 27, 28, 28, 29, 29, 15, 15, 
	27, 29, 29, 6, 6, 27, 8, 8, 
	27, 16, 16, 16, 16, 16, 16, 16, 
	16, 16, 27, 15, 15, 27, 0
};

static const char _czech_tokenizer_trans_targs[] = {
	7, 1, 2, 7, 1, 3, 19, 6, 
	20, 7, 8, 12, 16, 17, 0, 18, 
	21, 22, 7, 9, 11, 10, 13, 14, 
	7, 7, 15, 7, 4, 5
};

static const char _czech_tokenizer_trans_actions[] = {
	1, 0, 0, 2, 3, 0, 4, 0, 
	0, 7, 0, 0, 0, 4, 0, 4, 
	0, 0, 8, 0, 0, 0, 0, 0, 
	9, 10, 0, 11, 0, 0
};

static const char _czech_tokenizer_to_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 5, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0
};

static const char _czech_tokenizer_from_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 6, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0
};

static const unsigned char _czech_tokenizer_eof_trans[] = {
	0, 1, 1, 1, 1, 1, 1, 0, 
	19, 19, 19, 19, 19, 25, 19, 25, 
	19, 28, 28, 28, 28, 28, 28
};

static const int czech_tokenizer_start = 7;

// The list of lower cased words that when preceding eos do not end sentence.
const unordered_set<string> czech_tokenizer::abbreviations_czech = {
  // Titles
  "prof", "csc", "drsc", "doc", "phd", "ph", "d",
  "judr", "mddr", "mudr", "mvdr", "paeddr", "paedr", "phdr", "rndr", "rsdr", "dr",
  "ing", "arch", "mgr", "bc", "mag", "mba", "bca", "mga",
  "gen", "plk", "pplk", "npor", "por", "ppor", "kpt", "mjr", "sgt", "pls", "p", "s",
  "p", "pí", "fa", "fy", "mr", "mrs", "ms", "miss", "tr", "sv",
  // Geographic names
  "angl", "fr", "čes", "ces", "čs", "cs", "slov", "něm", "nem", "it", "pol", "maď", "mad", "rus",
  "sev", "vých", "vych", "již", "jiz", "záp", "zap",
  // Common abbrevs
  "adr", "č", "c", "eg", "ev", "g", "hod", "j", "kr", "m", "max", "min", "mj", "např", "napr",
  "okr", "popř", "popr", "pozn", "r", "ř", "red", "rep", "resp", "srov", "st", "stř", "str",
  "sv", "tel", "tj", "tzv", "ú", "u", "uh", "ul", "um", "zl", "zn",
};

const unordered_set<string> czech_tokenizer::abbreviations_slovak = {
  // Titles
  "prof", "csc", "drsc", "doc", "phd", "ph", "d",
  "judr", "mddr", "mudr", "mvdr", "paeddr", "paedr", "phdr", "rndr", "rsdr", "dr",
  "ing", "arch", "mgr", "bc", "mag", "mba", "bca", "mga",
  "gen", "plk", "pplk", "npor", "por", "ppor", "kpt", "mjr", "sgt", "pls", "p", "s",
  "p", "pí", "fa", "fy", "mr", "mrs", "ms", "miss", "tr", "sv",
  // Geographic names
  "angl", "fr", "čes", "ces", "čs", "cs", "slov", "nem", "it", "poľ", "pol", "maď", "mad",
  "rus", "sev", "vých", "vych", "juž", "juz", "záp", "zap",
  // Common abbrevs
  "adr", "č", "c", "eg", "ev", "g", "hod", "j", "kr", "m", "max", "min", "mj", "napr",
  "okr", "popr", "pozn", "r", "red", "rep", "resp", "srov", "st", "str",
  "sv", "tel", "tj", "tzv", "ú", "u", "uh", "ul", "um", "zl", "zn",
};

czech_tokenizer::czech_tokenizer(tokenizer_language language, unsigned version, const morpho* m)
  : ragel_tokenizer(version <= 1 ? 1 : 2), m(m) {
  switch (language) {
    case CZECH:
      abbreviations = &abbreviations_czech;
      break;
    case SLOVAK:
      abbreviations = &abbreviations_slovak;
      break;
  }
}

void czech_tokenizer::merge_hyphenated(vector<token_range>& tokens) {
  using namespace unilib;

  if (!m) return;
  if (tokens.empty() || chars[tokens.back().start].cat & ~unicode::L) return;

  unsigned matched_hyphens = 0;
  for (unsigned hyphens = 1; hyphens <= 2; hyphens++) {
    // Are the tokens a sequence of 'hyphens' hyphenated tokens?
    if (tokens.size() < 2*hyphens + 1) break;
    unsigned first_hyphen = tokens.size() - 2*hyphens;
    if (tokens[first_hyphen].length != 1 || chars[tokens[first_hyphen].start].cat & ~unicode::P ||
        tokens[first_hyphen].start + tokens[first_hyphen].length != tokens[first_hyphen + 1].start ||
        tokens[first_hyphen-1].start + tokens[first_hyphen-1].length != tokens[first_hyphen].start ||
        chars[tokens[first_hyphen-1].start].cat & ~unicode::L)
      break;

    if (m->analyze(string_piece(chars[tokens[first_hyphen-1].start].str, chars[tokens.back().start + tokens.back().length].str - chars[tokens[first_hyphen-1].start].str), morpho::NO_GUESSER, lemmas) >= 0)
      matched_hyphens = hyphens;
  }

  if (matched_hyphens) {
    unsigned first = tokens.size() - 2*matched_hyphens - 1;
    tokens[first].length = tokens.back().start + tokens.back().length - tokens[first].start;
    tokens.resize(first + 1);
  }
}

bool czech_tokenizer::next_sentence(vector<token_range>& tokens) {
  using namespace unilib;

  int cs, act;
  size_t ts, te;
  size_t whitespace = 0; // Suppress "may be uninitialized" warning

  while (tokenize_url_email(tokens))
    if (emergency_sentence_split(tokens))
      return true;
  
	{
	cs = czech_tokenizer_start;
	ts = 0;
	te = 0;
	act = 0;
	}

	{
	int _klen;
	const short *_keys;
	int _trans;
	short _widec;

	if ( ( current) == ( (chars.size() - 1)) )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	switch ( _czech_tokenizer_from_state_actions[cs] ) {
	case 6:
	{ts = ( current);}
	break;
	}

	_widec = ( ragel_char(chars[current]));
	_klen = _czech_tokenizer_cond_lengths[cs];
	_keys = _czech_tokenizer_cond_keys + (_czech_tokenizer_cond_offsets[cs]*2);
	if ( _klen > 0 ) {
		const short *_lower = _keys;
		const short *_mid;
		const short *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( _widec < _mid[0] )
				_upper = _mid - 2;
			else if ( _widec > _mid[1] )
				_lower = _mid + 2;
			else {
				switch ( _czech_tokenizer_cond_spaces[_czech_tokenizer_cond_offsets[cs] + ((_mid - _keys)>>1)] ) {
	case 0: {
		_widec = (short)(256u + (( ragel_char(chars[current])) - 0u));
		if ( 
 !current || (chars[current-1].cat & ~(unicode::L | unicode::M | unicode::N | unicode::Pd))  ) _widec += 256;
		break;
	}
	case 1: {
		_widec = (short)(768u + (( ragel_char(chars[current])) - 0u));
		if ( 
 !current || ((chars[current-1].cat & ~(unicode::L | unicode::M | unicode::N)) && chars[current-1].chr != '+')  ) _widec += 256;
		break;
	}
				}
				break;
			}
		}
	}

	_keys = _czech_tokenizer_trans_keys + _czech_tokenizer_key_offsets[cs];
	_trans = _czech_tokenizer_index_offsets[cs];

	_klen = _czech_tokenizer_single_lengths[cs];
	if ( _klen > 0 ) {
		const short *_lower = _keys;
		const short *_mid;
		const short *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( _widec < *_mid )
				_upper = _mid - 1;
			else if ( _widec > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _czech_tokenizer_range_lengths[cs];
	if ( _klen > 0 ) {
		const short *_lower = _keys;
		const short *_mid;
		const short *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( _widec < _mid[0] )
				_upper = _mid - 2;
			else if ( _widec > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _czech_tokenizer_indicies[_trans];
_eof_trans:
	cs = _czech_tokenizer_trans_targs[_trans];

	if ( _czech_tokenizer_trans_actions[_trans] == 0 )
		goto _again;

	switch ( _czech_tokenizer_trans_actions[_trans] ) {
	case 3:
	{ whitespace = current; }
	break;
	case 4:
	{te = ( current)+1;}
	break;
	case 7:
	{te = ( current)+1;{ tokens.emplace_back(ts, te - ts);
          merge_hyphenated(tokens);
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 2:
	{te = ( current)+1;{
          bool eos = is_eos(tokens, chars[ts].chr, abbreviations);
          for (current = ts; current < whitespace; current++)
            tokens.emplace_back(current, 1);
          {( current) = (( whitespace))-1;}
          if (eos) {( current)++; goto _out; }
        }}
	break;
	case 10:
	{te = ( current)+1;{
          if (!tokens.empty()) {( current)++; goto _out; }
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 11:
	{te = ( current);( current)--;{ tokens.emplace_back(ts, te - ts);
          merge_hyphenated(tokens);
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 8:
	{te = ( current);( current)--;{
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 9:
	{te = ( current);( current)--;{
          if (!tokens.empty()) {( current)++; goto _out; }
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 1:
	{{( current) = ((te))-1;}{ tokens.emplace_back(ts, te - ts);
          merge_hyphenated(tokens);
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	}

_again:
	switch ( _czech_tokenizer_to_state_actions[cs] ) {
	case 5:
	{ts = 0;}
	break;
	}

	if ( cs == 0 )
		goto _out;
	if ( ++( current) != ( (chars.size() - 1)) )
		goto _resume;
	_test_eof: {}
	if ( ( current) == ( (chars.size() - 1)) )
	{
	if ( _czech_tokenizer_eof_trans[cs] > 0 ) {
		_trans = _czech_tokenizer_eof_trans[cs] - 1;
		goto _eof_trans;
	}
	}

	_out: {}
	}

  (void)act; // Suppress unused variable warning

  return !tokens.empty();
}

/////////
// File: tokenizer/english_tokenizer.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// The list of lowercased words that when preceding eos do not end sentence.
const unordered_set<string> english_tokenizer::abbreviations = {
  // Titles
  "adj", "adm", "adv", "assoc", "asst", "bart", "bldg", "brig", "bros", "capt",
  "cmdr", "col", "comdr", "con", "corp", "cpl", "d", "dr", "dr", "drs", "ens",
  "gen", "gov", "hon", "hosp", "hr", "insp", "lt", "mm", "mr", "mrs", "ms",
  "maj", "messrs", "mlle", "mme", "mr", "mrs", "ms", "msgr", "op", "ord",
  "pfc", "ph", "phd", "prof", "pvt", "rep", "reps", "res", "rev", "rt", "sen",
  "sens", "sfc", "sgt", "sr", "st", "supt", "surg", "univ",
  // Common abbrevs
  "addr", "approx", "apr", "aug", "calif", "co", "corp", "dec", "def", "e",
  "e.g", "eg", "feb", "fla", "ft", "gen", "gov", "hrs", "i.", "i.e", "ie",
  "inc", "jan", "jr", "ltd", "mar", "max", "min", "mph", "mt", "n", "nov",
  "oct", "ont", "pa", "pres", "rep", "rev", "s", "sec", "sen", "sep", "sept",
  "sgt", "sr", "tel", "un", "univ", "v", "va", "vs", "w", "yrs",
};

static const char _english_tokenizer_split_token_key_offsets[] = {
	0, 0, 16, 20, 22, 26, 28, 30, 
	32, 34, 36, 44, 46, 50, 52, 54, 
	56, 58, 60, 62, 64, 66, 68, 72, 
	74, 76, 78, 80, 82, 82
};

static const unsigned char _english_tokenizer_split_token_trans_keys[] = {
	65u, 68u, 69u, 76u, 77u, 78u, 83u, 84u, 
	97u, 100u, 101u, 108u, 109u, 110u, 115u, 116u, 
	78u, 84u, 110u, 116u, 78u, 110u, 65u, 79u, 
	97u, 111u, 87u, 119u, 71u, 103u, 84u, 116u, 
	79u, 111u, 39u, 161u, 77u, 82u, 86u, 89u, 
	109u, 114u, 118u, 121u, 77u, 109u, 69u, 73u, 
	101u, 105u, 76u, 108u, 39u, 161u, 68u, 100u, 
	76u, 108u, 39u, 161u, 69u, 101u, 82u, 114u, 
	79u, 111u, 77u, 109u, 39u, 79u, 111u, 161u, 
	78u, 110u, 78u, 110u, 78u, 110u, 65u, 97u, 
	67u, 99u, 0
};

static const char _english_tokenizer_split_token_single_lengths[] = {
	0, 16, 4, 2, 4, 2, 2, 2, 
	2, 2, 8, 2, 4, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 4, 2, 
	2, 2, 2, 2, 0, 0
};

static const char _english_tokenizer_split_token_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0
};

static const unsigned char _english_tokenizer_split_token_index_offsets[] = {
	0, 0, 17, 22, 25, 30, 33, 36, 
	39, 42, 45, 54, 57, 62, 65, 68, 
	71, 74, 77, 80, 83, 86, 89, 94, 
	97, 100, 103, 106, 109, 110
};

static const char _english_tokenizer_split_token_indicies[] = {
	0, 2, 3, 4, 2, 5, 2, 6, 
	0, 2, 3, 4, 2, 5, 2, 6, 
	1, 7, 8, 7, 8, 1, 9, 9, 
	1, 10, 11, 10, 11, 1, 12, 12, 
	1, 12, 12, 1, 13, 13, 1, 11, 
	11, 1, 14, 14, 1, 15, 2, 2, 
	16, 15, 2, 2, 16, 1, 17, 17, 
	1, 18, 11, 18, 11, 1, 12, 12, 
	1, 19, 19, 1, 12, 12, 1, 2, 
	2, 1, 20, 20, 1, 21, 21, 1, 
	22, 22, 1, 23, 23, 1, 12, 12, 
	1, 24, 25, 25, 24, 1, 14, 14, 
	1, 26, 26, 1, 27, 27, 1, 28, 
	28, 1, 12, 12, 1, 1, 1, 0
};

static const char _english_tokenizer_split_token_trans_targs[] = {
	2, 0, 9, 10, 16, 17, 22, 3, 
	7, 4, 5, 6, 28, 8, 29, 11, 
	14, 12, 13, 15, 18, 19, 20, 21, 
	23, 24, 25, 26, 27
};

static const char _english_tokenizer_split_token_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 1, 
	1, 0, 0, 0, 0, 0, 2, 1, 
	1, 0, 0, 0, 1, 0, 0, 0, 
	0, 0, 1, 0, 0
};

static const char _english_tokenizer_split_token_eof_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 3, 0
};

static const int english_tokenizer_split_token_start = 1;

void english_tokenizer::split_token(vector<token_range>& tokens) {
  if (tokens.empty() || chars[tokens.back().start].cat & ~unilib::unicode::L) return;

  size_t index = tokens.back().start, end = index + tokens.back().length;
  int cs;
  size_t split_mark = 0, split_len = 0;
  
	{
	cs = english_tokenizer_split_token_start;
	}

	{
	int _klen;
	const unsigned char *_keys;
	int _trans;

	if ( ( index) == ( end) )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _english_tokenizer_split_token_trans_keys + _english_tokenizer_split_token_key_offsets[cs];
	_trans = _english_tokenizer_split_token_index_offsets[cs];

	_klen = _english_tokenizer_split_token_single_lengths[cs];
	if ( _klen > 0 ) {
		const unsigned char *_lower = _keys;
		const unsigned char *_mid;
		const unsigned char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( ( ragel_char(chars[tokens.back().start + end - index - 1])) < *_mid )
				_upper = _mid - 1;
			else if ( ( ragel_char(chars[tokens.back().start + end - index - 1])) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _english_tokenizer_split_token_range_lengths[cs];
	if ( _klen > 0 ) {
		const unsigned char *_lower = _keys;
		const unsigned char *_mid;
		const unsigned char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( ( ragel_char(chars[tokens.back().start + end - index - 1])) < _mid[0] )
				_upper = _mid - 2;
			else if ( ( ragel_char(chars[tokens.back().start + end - index - 1])) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _english_tokenizer_split_token_indicies[_trans];
	cs = _english_tokenizer_split_token_trans_targs[_trans];

	if ( _english_tokenizer_split_token_trans_actions[_trans] == 0 )
		goto _again;

	switch ( _english_tokenizer_split_token_trans_actions[_trans] ) {
	case 1:
	{ split_mark = index - tokens.back().start + 1; }
	break;
	case 2:
	{ split_mark = index - tokens.back().start + 1; }
	{ split_len = split_mark; {( index)++; goto _out; } }
	break;
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++( index) != ( end) )
		goto _resume;
	_test_eof: {}
	if ( ( index) == ( end) )
	{
	switch ( _english_tokenizer_split_token_eof_actions[cs] ) {
	case 3:
	{ split_len = split_mark; {( index)++; goto _out; } }
	break;
	}
	}

	_out: {}
	}

  if (split_len && split_len < end) {
    tokens.back().length -= split_len;
    tokens.emplace_back(end - split_len, split_len);
  }
}

static const char _english_tokenizer_cond_offsets[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2
};

static const char _english_tokenizer_cond_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 2, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0
};

static const short _english_tokenizer_cond_keys[] = {
	43u, 43u, 45u, 45u, 0
};

static const char _english_tokenizer_cond_spaces[] = {
	1, 0, 0
};

static const unsigned char _english_tokenizer_key_offsets[] = {
	0, 0, 17, 29, 43, 46, 49, 52, 
	55, 60, 63, 98, 103, 107, 110, 114, 
	119, 120, 125, 126, 131, 145, 152, 156, 
	161, 164, 179, 192, 206
};

static const short _english_tokenizer_trans_keys[] = {
	13u, 32u, 34u, 40u, 91u, 96u, 123u, 129u, 
	133u, 135u, 147u, 150u, 162u, 9u, 10u, 65u, 
	90u, 34u, 40u, 91u, 96u, 123u, 129u, 133u, 
	135u, 150u, 162u, 65u, 90u, 13u, 32u, 34u, 
	39u, 41u, 59u, 93u, 125u, 139u, 141u, 147u, 
	161u, 9u, 10u, 159u, 48u, 57u, 159u, 48u, 
	57u, 159u, 48u, 57u, 159u, 48u, 57u, 43u, 
	45u, 159u, 48u, 57u, 159u, 48u, 57u, 9u, 
	10u, 13u, 32u, 33u, 44u, 46u, 47u, 63u, 
	129u, 131u, 135u, 142u, 147u, 157u, 159u, 160u, 
	301u, 557u, 811u, 1067u, 0u, 42u, 48u, 57u, 
	58u, 64u, 65u, 90u, 91u, 96u, 97u, 122u, 
	123u, 255u, 9u, 10u, 13u, 32u, 147u, 9u, 
	13u, 32u, 147u, 9u, 32u, 147u, 9u, 10u, 
	32u, 147u, 9u, 10u, 13u, 32u, 147u, 13u, 
	9u, 10u, 13u, 32u, 147u, 10u, 9u, 10u, 
	13u, 32u, 147u, 13u, 32u, 34u, 39u, 41u, 
	59u, 93u, 125u, 139u, 141u, 147u, 161u, 9u, 
	10u, 44u, 46u, 69u, 101u, 159u, 48u, 57u, 
	44u, 46u, 69u, 101u, 69u, 101u, 159u, 48u, 
	57u, 159u, 48u, 57u, 39u, 45u, 129u, 131u, 
	135u, 151u, 155u, 157u, 161u, 65u, 90u, 97u, 
	122u, 142u, 143u, 45u, 129u, 131u, 135u, 151u, 
	155u, 157u, 65u, 90u, 97u, 122u, 142u, 143u, 
	39u, 129u, 131u, 135u, 151u, 155u, 157u, 161u, 
	65u, 90u, 97u, 122u, 142u, 143u, 159u, 48u, 
	57u, 0
};

static const char _english_tokenizer_single_lengths[] = {
	0, 13, 10, 12, 1, 1, 1, 1, 
	3, 1, 21, 5, 4, 3, 4, 5, 
	1, 5, 1, 5, 12, 5, 4, 3, 
	1, 9, 7, 8, 1
};

static const char _english_tokenizer_range_lengths[] = {
	0, 2, 1, 1, 1, 1, 1, 1, 
	1, 1, 7, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 1, 1, 0, 1, 
	1, 3, 3, 3, 1
};

static const unsigned char _english_tokenizer_index_offsets[] = {
	0, 0, 16, 28, 42, 45, 48, 51, 
	54, 59, 62, 91, 97, 102, 106, 111, 
	117, 119, 125, 127, 133, 147, 154, 159, 
	164, 167, 180, 191, 203
};

static const char _english_tokenizer_indicies[] = {
	1, 1, 2, 2, 2, 2, 2, 3, 
	2, 3, 1, 2, 2, 1, 3, 0, 
	2, 2, 2, 2, 2, 3, 2, 3, 
	2, 2, 3, 0, 4, 4, 5, 5, 
	5, 5, 5, 5, 5, 5, 4, 5, 
	4, 0, 6, 6, 0, 7, 7, 0, 
	8, 8, 0, 9, 9, 0, 10, 10, 
	11, 11, 0, 11, 11, 0, 13, 14, 
	15, 13, 16, 12, 16, 12, 16, 19, 
	19, 19, 19, 13, 19, 18, 16, 12, 
	20, 12, 20, 12, 18, 12, 19, 12, 
	19, 12, 17, 13, 22, 23, 13, 13, 
	21, 13, 24, 13, 13, 21, 13, 13, 
	13, 21, 13, 24, 13, 13, 21, 13, 
	25, 26, 13, 13, 21, 28, 27, 13, 
	25, 29, 13, 13, 21, 28, 27, 13, 
	26, 29, 13, 13, 21, 4, 4, 5, 
	5, 5, 5, 5, 5, 5, 5, 4, 
	5, 4, 30, 31, 32, 33, 33, 18, 
	18, 30, 31, 32, 33, 33, 30, 33, 
	33, 9, 9, 30, 11, 11, 30, 34, 
	35, 19, 19, 19, 19, 19, 19, 34, 
	19, 19, 19, 30, 35, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 30, 34, 
	19, 19, 19, 19, 19, 19, 34, 19, 
	19, 19, 30, 18, 18, 30, 0
};

static const char _english_tokenizer_trans_targs[] = {
	10, 1, 2, 10, 1, 3, 5, 6, 
	22, 23, 9, 24, 10, 11, 15, 19, 
	20, 0, 21, 25, 28, 10, 12, 14, 
	13, 16, 17, 10, 10, 18, 10, 4, 
	7, 8, 26, 27
};

static const char _english_tokenizer_trans_actions[] = {
	1, 0, 0, 2, 3, 0, 0, 0, 
	4, 4, 0, 0, 7, 0, 0, 0, 
	4, 0, 4, 0, 0, 8, 0, 0, 
	0, 0, 0, 9, 10, 0, 11, 0, 
	0, 0, 0, 0
};

static const char _english_tokenizer_to_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 5, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0
};

static const char _english_tokenizer_from_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 6, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0
};

static const unsigned char _english_tokenizer_eof_trans[] = {
	0, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 0, 22, 22, 22, 22, 22, 
	28, 22, 28, 22, 31, 31, 31, 31, 
	31, 31, 31, 31, 31
};

static const int english_tokenizer_start = 10;

english_tokenizer::english_tokenizer(unsigned version) : ragel_tokenizer(version <= 1 ? 1 : 2) {}

bool english_tokenizer::next_sentence(vector<token_range>& tokens) {
  using namespace unilib;

  int cs, act;
  size_t ts, te;
  size_t whitespace = 0; // Suppress "may be uninitialized" warning

  while (tokenize_url_email(tokens))
    if (emergency_sentence_split(tokens))
      return true;
  
	{
	cs = english_tokenizer_start;
	ts = 0;
	te = 0;
	act = 0;
	}

	{
	int _klen;
	const short *_keys;
	int _trans;
	short _widec;

	if ( ( current) == ( (chars.size() - 1)) )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	switch ( _english_tokenizer_from_state_actions[cs] ) {
	case 6:
	{ts = ( current);}
	break;
	}

	_widec = ( ragel_char(chars[current]));
	_klen = _english_tokenizer_cond_lengths[cs];
	_keys = _english_tokenizer_cond_keys + (_english_tokenizer_cond_offsets[cs]*2);
	if ( _klen > 0 ) {
		const short *_lower = _keys;
		const short *_mid;
		const short *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( _widec < _mid[0] )
				_upper = _mid - 2;
			else if ( _widec > _mid[1] )
				_lower = _mid + 2;
			else {
				switch ( _english_tokenizer_cond_spaces[_english_tokenizer_cond_offsets[cs] + ((_mid - _keys)>>1)] ) {
	case 0: {
		_widec = (short)(256u + (( ragel_char(chars[current])) - 0u));
		if ( 
 !current || (chars[current-1].cat & ~(unicode::L | unicode::M | unicode::N | unicode::Pd))  ) _widec += 256;
		break;
	}
	case 1: {
		_widec = (short)(768u + (( ragel_char(chars[current])) - 0u));
		if ( 
 !current || ((chars[current-1].cat & ~(unicode::L | unicode::M | unicode::N)) && chars[current-1].chr != '+')  ) _widec += 256;
		break;
	}
				}
				break;
			}
		}
	}

	_keys = _english_tokenizer_trans_keys + _english_tokenizer_key_offsets[cs];
	_trans = _english_tokenizer_index_offsets[cs];

	_klen = _english_tokenizer_single_lengths[cs];
	if ( _klen > 0 ) {
		const short *_lower = _keys;
		const short *_mid;
		const short *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( _widec < *_mid )
				_upper = _mid - 1;
			else if ( _widec > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _english_tokenizer_range_lengths[cs];
	if ( _klen > 0 ) {
		const short *_lower = _keys;
		const short *_mid;
		const short *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( _widec < _mid[0] )
				_upper = _mid - 2;
			else if ( _widec > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _english_tokenizer_indicies[_trans];
_eof_trans:
	cs = _english_tokenizer_trans_targs[_trans];

	if ( _english_tokenizer_trans_actions[_trans] == 0 )
		goto _again;

	switch ( _english_tokenizer_trans_actions[_trans] ) {
	case 3:
	{ whitespace = current; }
	break;
	case 4:
	{te = ( current)+1;}
	break;
	case 7:
	{te = ( current)+1;{ tokens.emplace_back(ts, te - ts);
          split_token(tokens);
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 2:
	{te = ( current)+1;{
          bool eos = is_eos(tokens, chars[ts].chr, &abbreviations);
          for (current = ts; current < whitespace; current++)
            tokens.emplace_back(current, 1);
          {( current) = (( whitespace))-1;}
          if (eos) {( current)++; goto _out; }
        }}
	break;
	case 10:
	{te = ( current)+1;{
          if (!tokens.empty()) {( current)++; goto _out; }
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 11:
	{te = ( current);( current)--;{ tokens.emplace_back(ts, te - ts);
          split_token(tokens);
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 8:
	{te = ( current);( current)--;{
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 9:
	{te = ( current);( current)--;{
          if (!tokens.empty()) {( current)++; goto _out; }
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 1:
	{{( current) = ((te))-1;}{ tokens.emplace_back(ts, te - ts);
          split_token(tokens);
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	}

_again:
	switch ( _english_tokenizer_to_state_actions[cs] ) {
	case 5:
	{ts = 0;}
	break;
	}

	if ( cs == 0 )
		goto _out;
	if ( ++( current) != ( (chars.size() - 1)) )
		goto _resume;
	_test_eof: {}
	if ( ( current) == ( (chars.size() - 1)) )
	{
	if ( _english_tokenizer_eof_trans[cs] > 0 ) {
		_trans = _english_tokenizer_eof_trans[cs] - 1;
		goto _eof_trans;
	}
	}

	_out: {}
	}

  (void)act; // Suppress unused variable warning

  return !tokens.empty();
}

/////////
// File: tokenizer/generic_tokenizer.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

static const char _generic_tokenizer_cond_offsets[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2
};

static const char _generic_tokenizer_cond_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 2, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0
};

static const short _generic_tokenizer_cond_keys[] = {
	43u, 43u, 45u, 45u, 0
};

static const char _generic_tokenizer_cond_spaces[] = {
	1, 0, 0
};

static const unsigned char _generic_tokenizer_key_offsets[] = {
	0, 0, 17, 29, 43, 46, 51, 54, 
	89, 94, 98, 101, 105, 110, 111, 116, 
	117, 122, 136, 142, 147, 150, 162
};

static const short _generic_tokenizer_trans_keys[] = {
	13u, 32u, 34u, 40u, 91u, 96u, 123u, 129u, 
	133u, 135u, 147u, 150u, 162u, 9u, 10u, 65u, 
	90u, 34u, 40u, 91u, 96u, 123u, 129u, 133u, 
	135u, 150u, 162u, 65u, 90u, 13u, 32u, 34u, 
	39u, 41u, 59u, 93u, 125u, 139u, 141u, 147u, 
	161u, 9u, 10u, 159u, 48u, 57u, 43u, 45u, 
	159u, 48u, 57u, 159u, 48u, 57u, 9u, 10u, 
	13u, 32u, 33u, 44u, 46u, 47u, 63u, 129u, 
	131u, 135u, 142u, 147u, 157u, 159u, 160u, 301u, 
	557u, 811u, 1067u, 0u, 42u, 48u, 57u, 58u, 
	64u, 65u, 90u, 91u, 96u, 97u, 122u, 123u, 
	255u, 9u, 10u, 13u, 32u, 147u, 9u, 13u, 
	32u, 147u, 9u, 32u, 147u, 9u, 10u, 32u, 
	147u, 9u, 10u, 13u, 32u, 147u, 13u, 9u, 
	10u, 13u, 32u, 147u, 10u, 9u, 10u, 13u, 
	32u, 147u, 13u, 32u, 34u, 39u, 41u, 59u, 
	93u, 125u, 139u, 141u, 147u, 161u, 9u, 10u, 
	46u, 69u, 101u, 159u, 48u, 57u, 69u, 101u, 
	159u, 48u, 57u, 159u, 48u, 57u, 129u, 131u, 
	135u, 151u, 155u, 157u, 65u, 90u, 97u, 122u, 
	142u, 143u, 159u, 48u, 57u, 0
};

static const char _generic_tokenizer_single_lengths[] = {
	0, 13, 10, 12, 1, 3, 1, 21, 
	5, 4, 3, 4, 5, 1, 5, 1, 
	5, 12, 4, 3, 1, 6, 1
};

static const char _generic_tokenizer_range_lengths[] = {
	0, 2, 1, 1, 1, 1, 1, 7, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 1, 1, 1, 1, 3, 1
};

static const unsigned char _generic_tokenizer_index_offsets[] = {
	0, 0, 16, 28, 42, 45, 50, 53, 
	82, 88, 93, 97, 102, 108, 110, 116, 
	118, 124, 138, 144, 149, 152, 162
};

static const char _generic_tokenizer_indicies[] = {
	1, 1, 2, 2, 2, 2, 2, 3, 
	2, 3, 1, 2, 2, 1, 3, 0, 
	2, 2, 2, 2, 2, 3, 2, 3, 
	2, 2, 3, 0, 4, 4, 5, 5, 
	5, 5, 5, 5, 5, 5, 4, 5, 
	4, 0, 6, 6, 0, 7, 7, 8, 
	8, 0, 8, 8, 0, 10, 11, 12, 
	10, 13, 9, 13, 9, 13, 16, 16, 
	16, 16, 10, 16, 15, 13, 9, 17, 
	9, 17, 9, 15, 9, 16, 9, 16, 
	9, 14, 10, 19, 20, 10, 10, 18, 
	10, 21, 10, 10, 18, 10, 10, 10, 
	18, 10, 21, 10, 10, 18, 10, 22, 
	23, 10, 10, 18, 25, 24, 10, 22, 
	26, 10, 10, 18, 25, 24, 10, 23, 
	26, 10, 10, 18, 4, 4, 5, 5, 
	5, 5, 5, 5, 5, 5, 4, 5, 
	4, 27, 28, 29, 29, 15, 15, 27, 
	29, 29, 6, 6, 27, 8, 8, 27, 
	16, 16, 16, 16, 16, 16, 16, 16, 
	16, 27, 15, 15, 27, 0
};

static const char _generic_tokenizer_trans_targs[] = {
	7, 1, 2, 7, 1, 3, 19, 6, 
	20, 7, 8, 12, 16, 17, 0, 18, 
	21, 22, 7, 9, 11, 10, 13, 14, 
	7, 7, 15, 7, 4, 5
};

static const char _generic_tokenizer_trans_actions[] = {
	1, 0, 0, 2, 3, 0, 4, 0, 
	0, 7, 0, 0, 0, 4, 0, 4, 
	0, 0, 8, 0, 0, 0, 0, 0, 
	9, 10, 0, 11, 0, 0
};

static const char _generic_tokenizer_to_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 5, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0
};

static const char _generic_tokenizer_from_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 6, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0
};

static const unsigned char _generic_tokenizer_eof_trans[] = {
	0, 1, 1, 1, 1, 1, 1, 0, 
	19, 19, 19, 19, 19, 25, 19, 25, 
	19, 28, 28, 28, 28, 28, 28
};

static const int generic_tokenizer_start = 7;

generic_tokenizer::generic_tokenizer(unsigned version) : ragel_tokenizer(version <= 1 ? 1 : 2) {}

bool generic_tokenizer::next_sentence(vector<token_range>& tokens) {
  using namespace unilib;

  int cs, act;
  size_t ts, te;
  size_t whitespace = 0; // Suppress "may be uninitialized" warning

  while (tokenize_url_email(tokens))
    if (emergency_sentence_split(tokens))
      return true;
  
	{
	cs = generic_tokenizer_start;
	ts = 0;
	te = 0;
	act = 0;
	}

	{
	int _klen;
	const short *_keys;
	int _trans;
	short _widec;

	if ( ( current) == ( (chars.size() - 1)) )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	switch ( _generic_tokenizer_from_state_actions[cs] ) {
	case 6:
	{ts = ( current);}
	break;
	}

	_widec = ( ragel_char(chars[current]));
	_klen = _generic_tokenizer_cond_lengths[cs];
	_keys = _generic_tokenizer_cond_keys + (_generic_tokenizer_cond_offsets[cs]*2);
	if ( _klen > 0 ) {
		const short *_lower = _keys;
		const short *_mid;
		const short *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( _widec < _mid[0] )
				_upper = _mid - 2;
			else if ( _widec > _mid[1] )
				_lower = _mid + 2;
			else {
				switch ( _generic_tokenizer_cond_spaces[_generic_tokenizer_cond_offsets[cs] + ((_mid - _keys)>>1)] ) {
	case 0: {
		_widec = (short)(256u + (( ragel_char(chars[current])) - 0u));
		if ( 
 !current || (chars[current-1].cat & ~(unicode::L | unicode::M | unicode::N | unicode::Pd))  ) _widec += 256;
		break;
	}
	case 1: {
		_widec = (short)(768u + (( ragel_char(chars[current])) - 0u));
		if ( 
 !current || ((chars[current-1].cat & ~(unicode::L | unicode::M | unicode::N)) && chars[current-1].chr != '+')  ) _widec += 256;
		break;
	}
				}
				break;
			}
		}
	}

	_keys = _generic_tokenizer_trans_keys + _generic_tokenizer_key_offsets[cs];
	_trans = _generic_tokenizer_index_offsets[cs];

	_klen = _generic_tokenizer_single_lengths[cs];
	if ( _klen > 0 ) {
		const short *_lower = _keys;
		const short *_mid;
		const short *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( _widec < *_mid )
				_upper = _mid - 1;
			else if ( _widec > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _generic_tokenizer_range_lengths[cs];
	if ( _klen > 0 ) {
		const short *_lower = _keys;
		const short *_mid;
		const short *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( _widec < _mid[0] )
				_upper = _mid - 2;
			else if ( _widec > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _generic_tokenizer_indicies[_trans];
_eof_trans:
	cs = _generic_tokenizer_trans_targs[_trans];

	if ( _generic_tokenizer_trans_actions[_trans] == 0 )
		goto _again;

	switch ( _generic_tokenizer_trans_actions[_trans] ) {
	case 3:
	{ whitespace = current; }
	break;
	case 4:
	{te = ( current)+1;}
	break;
	case 7:
	{te = ( current)+1;{ tokens.emplace_back(ts, te - ts);
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 2:
	{te = ( current)+1;{
          bool eos = is_eos(tokens, chars[ts].chr, nullptr);
          for (current = ts; current < whitespace; current++)
            tokens.emplace_back(current, 1);
          {( current) = (( whitespace))-1;}
          if (eos) {( current)++; goto _out; }
        }}
	break;
	case 10:
	{te = ( current)+1;{
          if (!tokens.empty()) {( current)++; goto _out; }
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 11:
	{te = ( current);( current)--;{ tokens.emplace_back(ts, te - ts);
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 8:
	{te = ( current);( current)--;{
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 9:
	{te = ( current);( current)--;{
          if (!tokens.empty()) {( current)++; goto _out; }
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	case 1:
	{{( current) = ((te))-1;}{ tokens.emplace_back(ts, te - ts);
          current = te;
          do
            if (emergency_sentence_split(tokens)) { ( current)--; {( current)++; goto _out; } }
          while (tokenize_url_email(tokens));
          ( current)--;
        }}
	break;
	}

_again:
	switch ( _generic_tokenizer_to_state_actions[cs] ) {
	case 5:
	{ts = 0;}
	break;
	}

	if ( cs == 0 )
		goto _out;
	if ( ++( current) != ( (chars.size() - 1)) )
		goto _resume;
	_test_eof: {}
	if ( ( current) == ( (chars.size() - 1)) )
	{
	if ( _generic_tokenizer_eof_trans[cs] > 0 ) {
		_trans = _generic_tokenizer_eof_trans[cs] - 1;
		goto _eof_trans;
	}
	}

	_out: {}
	}

  (void)act; // Suppress unused variable warning

  return !tokens.empty();
}

/////////
// File: tokenizer/ragel_tokenizer.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

static const char _ragel_url_email_cond_offsets[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 2, 3, 3, 4, 5, 
	6, 7, 8, 9, 10, 11, 12, 13, 
	14, 15, 16
};

static const char _ragel_url_email_cond_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 1, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 1, 1, 0, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1
};

static const short _ragel_url_email_cond_keys[] = {
	41u, 41u, 47u, 47u, 47u, 47u, 41u, 41u, 
	47u, 47u, 47u, 47u, 47u, 47u, 47u, 47u, 
	47u, 47u, 47u, 47u, 47u, 47u, 47u, 47u, 
	47u, 47u, 47u, 47u, 47u, 47u, 47u, 47u, 
	47u, 47u, 0
};

static const char _ragel_url_email_cond_spaces[] = {
	1, 0, 0, 1, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0
};

static const short _ragel_url_email_key_offsets[] = {
	0, 0, 15, 29, 41, 54, 63, 71, 
	78, 86, 92, 100, 117, 145, 154, 162, 
	171, 179, 188, 196, 204, 215, 225, 233, 
	241, 252, 262, 270, 278, 289, 299, 315, 
	330, 346, 360, 376, 393, 409, 426, 442, 
	459, 475, 491, 510, 528, 544, 560, 579, 
	597, 613, 629, 648, 666, 682, 698, 714, 
	725, 726, 741, 752, 756, 773, 801, 812, 
	823, 834, 848, 861, 879, 893, 908, 926, 
	944, 962, 983
};

static const short _ragel_url_email_trans_keys[] = {
	33u, 48u, 49u, 50u, 95u, 36u, 37u, 39u, 
	46u, 51u, 57u, 65u, 90u, 97u, 122u, 33u, 
	58u, 64u, 95u, 36u, 37u, 39u, 46u, 48u, 
	57u, 65u, 90u, 97u, 122u, 33u, 95u, 36u, 
	37u, 39u, 46u, 48u, 57u, 65u, 90u, 97u, 
	122u, 33u, 64u, 95u, 36u, 37u, 39u, 46u, 
	48u, 57u, 65u, 90u, 97u, 122u, 48u, 49u, 
	50u, 51u, 57u, 65u, 90u, 97u, 122u, 45u, 
	46u, 48u, 57u, 65u, 90u, 97u, 122u, 45u, 
	48u, 57u, 65u, 90u, 97u, 122u, 45u, 46u, 
	48u, 57u, 65u, 90u, 97u, 122u, 48u, 57u, 
	65u, 90u, 97u, 122u, 45u, 46u, 48u, 57u, 
	65u, 90u, 97u, 122u, 33u, 39u, 41u, 61u, 
	95u, 36u, 47u, 48u, 57u, 58u, 59u, 63u, 
	64u, 65u, 90u, 97u, 122u, 33u, 39u, 40u, 
	44u, 46u, 61u, 63u, 95u, 129u, 131u, 135u, 
	151u, 809u, 1065u, 36u, 38u, 42u, 57u, 58u, 
	59u, 64u, 90u, 97u, 122u, 142u, 143u, 155u, 
	159u, 48u, 49u, 50u, 51u, 57u, 65u, 90u, 
	97u, 122u, 45u, 46u, 48u, 57u, 65u, 90u, 
	97u, 122u, 48u, 49u, 50u, 51u, 57u, 65u, 
	90u, 97u, 122u, 45u, 46u, 48u, 57u, 65u, 
	90u, 97u, 122u, 48u, 49u, 50u, 51u, 57u, 
	65u, 90u, 97u, 122u, 45u, 46u, 48u, 57u, 
	65u, 90u, 97u, 122u, 45u, 46u, 48u, 57u, 
	65u, 90u, 97u, 122u, 45u, 46u, 53u, 48u, 
	52u, 54u, 57u, 65u, 90u, 97u, 122u, 45u, 
	46u, 48u, 53u, 54u, 57u, 65u, 90u, 97u, 
	122u, 45u, 46u, 48u, 57u, 65u, 90u, 97u, 
	122u, 45u, 46u, 48u, 57u, 65u, 90u, 97u, 
	122u, 45u, 46u, 53u, 48u, 52u, 54u, 57u, 
	65u, 90u, 97u, 122u, 45u, 46u, 48u, 53u, 
	54u, 57u, 65u, 90u, 97u, 122u, 45u, 46u, 
	48u, 57u, 65u, 90u, 97u, 122u, 45u, 46u, 
	48u, 57u, 65u, 90u, 97u, 122u, 45u, 46u, 
	53u, 48u, 52u, 54u, 57u, 65u, 90u, 97u, 
	122u, 45u, 46u, 48u, 53u, 54u, 57u, 65u, 
	90u, 97u, 122u, 33u, 45u, 46u, 58u, 64u, 
	95u, 36u, 37u, 39u, 44u, 48u, 57u, 65u, 
	90u, 97u, 122u, 33u, 45u, 58u, 64u, 95u, 
	36u, 37u, 39u, 46u, 48u, 57u, 65u, 90u, 
	97u, 122u, 33u, 45u, 46u, 58u, 64u, 95u, 
	36u, 37u, 39u, 44u, 48u, 57u, 65u, 90u, 
	97u, 122u, 33u, 58u, 64u, 95u, 36u, 37u, 
	39u, 46u, 48u, 57u, 65u, 90u, 97u, 122u, 
	33u, 45u, 46u, 58u, 64u, 95u, 36u, 37u, 
	39u, 44u, 48u, 57u, 65u, 90u, 97u, 122u, 
	33u, 48u, 49u, 50u, 58u, 64u, 95u, 36u, 
	37u, 39u, 46u, 51u, 57u, 65u, 90u, 97u, 
	122u, 33u, 45u, 46u, 58u, 64u, 95u, 36u, 
	37u, 39u, 44u, 48u, 57u, 65u, 90u, 97u, 
	122u, 33u, 48u, 49u, 50u, 58u, 64u, 95u, 
	36u, 37u, 39u, 46u, 51u, 57u, 65u, 90u, 
	97u, 122u, 33u, 45u, 46u, 58u, 64u, 95u, 
	36u, 37u, 39u, 44u, 48u, 57u, 65u, 90u, 
	97u, 122u, 33u, 48u, 49u, 50u, 58u, 64u, 
	95u, 36u, 37u, 39u, 46u, 51u, 57u, 65u, 
	90u, 97u, 122u, 33u, 45u, 46u, 58u, 64u, 
	95u, 36u, 37u, 39u, 44u, 48u, 57u, 65u, 
	90u, 97u, 122u, 33u, 45u, 46u, 58u, 64u, 
	95u, 36u, 37u, 39u, 44u, 48u, 57u, 65u, 
	90u, 97u, 122u, 33u, 45u, 46u, 53u, 58u, 
	64u, 95u, 36u, 37u, 39u, 44u, 48u, 52u, 
	54u, 57u, 65u, 90u, 97u, 122u, 33u, 45u, 
	46u, 58u, 64u, 95u, 36u, 37u, 39u, 44u, 
	48u, 53u, 54u, 57u, 65u, 90u, 97u, 122u, 
	33u, 45u, 46u, 58u, 64u, 95u, 36u, 37u, 
	39u, 44u, 48u, 57u, 65u, 90u, 97u, 122u, 
	33u, 45u, 46u, 58u, 64u, 95u, 36u, 37u, 
	39u, 44u, 48u, 57u, 65u, 90u, 97u, 122u, 
	33u, 45u, 46u, 53u, 58u, 64u, 95u, 36u, 
	37u, 39u, 44u, 48u, 52u, 54u, 57u, 65u, 
	90u, 97u, 122u, 33u, 45u, 46u, 58u, 64u, 
	95u, 36u, 37u, 39u, 44u, 48u, 53u, 54u, 
	57u, 65u, 90u, 97u, 122u, 33u, 45u, 46u, 
	58u, 64u, 95u, 36u, 37u, 39u, 44u, 48u, 
	57u, 65u, 90u, 97u, 122u, 33u, 45u, 46u, 
	58u, 64u, 95u, 36u, 37u, 39u, 44u, 48u, 
	57u, 65u, 90u, 97u, 122u, 33u, 45u, 46u, 
	53u, 58u, 64u, 95u, 36u, 37u, 39u, 44u, 
	48u, 52u, 54u, 57u, 65u, 90u, 97u, 122u, 
	33u, 45u, 46u, 58u, 64u, 95u, 36u, 37u, 
	39u, 44u, 48u, 53u, 54u, 57u, 65u, 90u, 
	97u, 122u, 33u, 45u, 46u, 58u, 64u, 95u, 
	36u, 37u, 39u, 44u, 48u, 57u, 65u, 90u, 
	97u, 122u, 33u, 45u, 46u, 58u, 64u, 95u, 
	36u, 37u, 39u, 44u, 48u, 57u, 65u, 90u, 
	97u, 122u, 33u, 45u, 46u, 58u, 64u, 95u, 
	36u, 37u, 39u, 44u, 48u, 57u, 65u, 90u, 
	97u, 122u, 33u, 47u, 95u, 36u, 37u, 39u, 
	57u, 65u, 90u, 97u, 122u, 47u, 33u, 48u, 
	49u, 50u, 95u, 36u, 37u, 39u, 46u, 51u, 
	57u, 65u, 90u, 97u, 122u, 45u, 46u, 58u, 
	303u, 559u, 48u, 57u, 65u, 90u, 97u, 122u, 
	303u, 559u, 48u, 57u, 33u, 39u, 41u, 61u, 
	95u, 36u, 47u, 48u, 57u, 58u, 59u, 63u, 
	64u, 65u, 90u, 97u, 122u, 33u, 39u, 40u, 
	44u, 46u, 61u, 63u, 95u, 129u, 131u, 135u, 
	151u, 809u, 1065u, 36u, 38u, 42u, 57u, 58u, 
	59u, 64u, 90u, 97u, 122u, 142u, 143u, 155u, 
	159u, 45u, 46u, 58u, 303u, 559u, 48u, 57u, 
	65u, 90u, 97u, 122u, 45u, 46u, 58u, 303u, 
	559u, 48u, 57u, 65u, 90u, 97u, 122u, 45u, 
	46u, 58u, 303u, 559u, 48u, 57u, 65u, 90u, 
	97u, 122u, 45u, 46u, 53u, 58u, 303u, 559u, 
	48u, 52u, 54u, 57u, 65u, 90u, 97u, 122u, 
	45u, 46u, 58u, 303u, 559u, 48u, 53u, 54u, 
	57u, 65u, 90u, 97u, 122u, 33u, 45u, 46u, 
	58u, 64u, 95u, 303u, 559u, 36u, 37u, 39u, 
	44u, 48u, 57u, 65u, 90u, 97u, 122u, 33u, 
	95u, 303u, 559u, 36u, 37u, 39u, 46u, 48u, 
	57u, 65u, 90u, 97u, 122u, 33u, 64u, 95u, 
	303u, 559u, 36u, 37u, 39u, 46u, 48u, 57u, 
	65u, 90u, 97u, 122u, 33u, 45u, 46u, 58u, 
	64u, 95u, 303u, 559u, 36u, 37u, 39u, 44u, 
	48u, 57u, 65u, 90u, 97u, 122u, 33u, 45u, 
	46u, 58u, 64u, 95u, 303u, 559u, 36u, 37u, 
	39u, 44u, 48u, 57u, 65u, 90u, 97u, 122u, 
	33u, 45u, 46u, 58u, 64u, 95u, 303u, 559u, 
	36u, 37u, 39u, 44u, 48u, 57u, 65u, 90u, 
	97u, 122u, 33u, 45u, 46u, 53u, 58u, 64u, 
	95u, 303u, 559u, 36u, 37u, 39u, 44u, 48u, 
	52u, 54u, 57u, 65u, 90u, 97u, 122u, 33u, 
	45u, 46u, 58u, 64u, 95u, 303u, 559u, 36u, 
	37u, 39u, 44u, 48u, 53u, 54u, 57u, 65u, 
	90u, 97u, 122u, 0
};

static const char _ragel_url_email_single_lengths[] = {
	0, 5, 4, 2, 3, 3, 2, 1, 
	2, 0, 2, 5, 14, 3, 2, 3, 
	2, 3, 2, 2, 3, 2, 2, 2, 
	3, 2, 2, 2, 3, 2, 6, 5, 
	6, 4, 6, 7, 6, 7, 6, 7, 
	6, 6, 7, 6, 6, 6, 7, 6, 
	6, 6, 7, 6, 6, 6, 6, 3, 
	1, 5, 5, 2, 5, 14, 5, 5, 
	5, 6, 5, 8, 4, 5, 8, 8, 
	8, 9, 8
};

static const char _ragel_url_email_range_lengths[] = {
	0, 5, 5, 5, 5, 3, 3, 3, 
	3, 3, 3, 6, 7, 3, 3, 3, 
	3, 3, 3, 3, 4, 4, 3, 3, 
	4, 4, 3, 3, 4, 4, 5, 5, 
	5, 5, 5, 5, 5, 5, 5, 5, 
	5, 5, 6, 6, 5, 5, 6, 6, 
	5, 5, 6, 6, 5, 5, 5, 4, 
	0, 5, 3, 1, 6, 7, 3, 3, 
	3, 4, 4, 5, 5, 5, 5, 5, 
	5, 6, 6
};

static const short _ragel_url_email_index_offsets[] = {
	0, 0, 11, 21, 29, 38, 45, 51, 
	56, 62, 66, 72, 84, 106, 113, 119, 
	126, 132, 139, 145, 151, 159, 166, 172, 
	178, 186, 193, 199, 205, 213, 220, 232, 
	243, 255, 265, 277, 290, 302, 315, 327, 
	340, 352, 364, 378, 391, 403, 415, 429, 
	442, 454, 466, 480, 493, 505, 517, 529, 
	537, 539, 550, 559, 563, 575, 597, 606, 
	615, 624, 635, 645, 659, 669, 680, 694, 
	708, 722, 738
};

static const char _ragel_url_email_indicies[] = {
	0, 2, 3, 4, 0, 0, 0, 5, 
	6, 6, 1, 0, 7, 8, 0, 0, 
	0, 0, 0, 0, 1, 9, 9, 9, 
	9, 9, 9, 9, 1, 9, 8, 9, 
	9, 9, 9, 9, 9, 1, 10, 11, 
	12, 13, 14, 14, 1, 15, 16, 14, 
	14, 14, 1, 15, 14, 14, 14, 1, 
	15, 17, 14, 14, 14, 1, 14, 18, 
	18, 1, 15, 17, 14, 19, 19, 1, 
	20, 21, 21, 20, 20, 20, 21, 20, 
	20, 21, 21, 1, 22, 22, 24, 22, 
	22, 23, 22, 23, 23, 23, 23, 23, 
	25, 26, 23, 23, 22, 23, 23, 23, 
	23, 1, 27, 28, 29, 30, 18, 18, 
	1, 15, 31, 14, 14, 14, 1, 32, 
	33, 34, 35, 18, 18, 1, 15, 36, 
	14, 14, 14, 1, 37, 38, 39, 40, 
	18, 18, 1, 15, 36, 35, 14, 14, 
	1, 15, 36, 32, 14, 14, 1, 15, 
	36, 41, 35, 32, 14, 14, 1, 15, 
	36, 32, 14, 14, 14, 1, 15, 31, 
	30, 14, 14, 1, 15, 31, 27, 14, 
	14, 1, 15, 31, 42, 30, 27, 14, 
	14, 1, 15, 31, 27, 14, 14, 14, 
	1, 15, 16, 13, 14, 14, 1, 15, 
	16, 10, 14, 14, 1, 15, 16, 43, 
	13, 10, 14, 14, 1, 15, 16, 10, 
	14, 14, 14, 1, 0, 44, 45, 7, 
	8, 0, 0, 0, 46, 46, 46, 1, 
	0, 44, 7, 8, 0, 0, 0, 46, 
	46, 46, 1, 0, 44, 47, 7, 8, 
	0, 0, 0, 46, 46, 46, 1, 0, 
	7, 8, 0, 0, 0, 46, 48, 48, 
	1, 0, 44, 47, 7, 8, 0, 0, 
	0, 46, 49, 49, 1, 0, 50, 51, 
	52, 7, 8, 0, 0, 0, 53, 48, 
	48, 1, 0, 44, 54, 7, 8, 0, 
	0, 0, 46, 46, 46, 1, 0, 55, 
	56, 57, 7, 8, 0, 0, 0, 58, 
	48, 48, 1, 0, 44, 59, 7, 8, 
	0, 0, 0, 46, 46, 46, 1, 0, 
	60, 61, 62, 7, 8, 0, 0, 0, 
	63, 48, 48, 1, 0, 44, 59, 7, 
	8, 0, 0, 0, 58, 46, 46, 1, 
	0, 44, 59, 7, 8, 0, 0, 0, 
	55, 46, 46, 1, 0, 44, 59, 64, 
	7, 8, 0, 0, 0, 58, 55, 46, 
	46, 1, 0, 44, 59, 7, 8, 0, 
	0, 0, 55, 46, 46, 46, 1, 0, 
	44, 54, 7, 8, 0, 0, 0, 53, 
	46, 46, 1, 0, 44, 54, 7, 8, 
	0, 0, 0, 50, 46, 46, 1, 0, 
	44, 54, 65, 7, 8, 0, 0, 0, 
	53, 50, 46, 46, 1, 0, 44, 54, 
	7, 8, 0, 0, 0, 50, 46, 46, 
	46, 1, 0, 44, 45, 7, 8, 0, 
	0, 0, 5, 46, 46, 1, 0, 44, 
	45, 7, 8, 0, 0, 0, 2, 46, 
	46, 1, 0, 44, 45, 66, 7, 8, 
	0, 0, 0, 5, 2, 46, 46, 1, 
	0, 44, 45, 7, 8, 0, 0, 0, 
	2, 46, 46, 46, 1, 0, 44, 47, 
	7, 8, 0, 0, 0, 46, 67, 67, 
	1, 0, 44, 47, 7, 8, 0, 0, 
	0, 46, 68, 68, 1, 0, 44, 47, 
	69, 8, 0, 0, 0, 46, 68, 68, 
	1, 9, 70, 9, 9, 9, 9, 9, 
	1, 71, 1, 0, 2, 3, 4, 0, 
	0, 0, 5, 46, 46, 1, 15, 17, 
	72, 21, 23, 14, 19, 19, 1, 21, 
	23, 72, 1, 20, 21, 21, 20, 20, 
	20, 21, 20, 20, 21, 21, 1, 22, 
	22, 24, 22, 22, 23, 22, 23, 23, 
	23, 23, 23, 25, 26, 23, 23, 22, 
	23, 23, 23, 23, 1, 15, 17, 72, 
	21, 23, 14, 14, 14, 1, 15, 17, 
	72, 21, 23, 40, 14, 14, 1, 15, 
	17, 72, 21, 23, 37, 14, 14, 1, 
	15, 17, 73, 72, 21, 23, 40, 37, 
	14, 14, 1, 15, 17, 72, 21, 23, 
	37, 14, 14, 14, 1, 0, 44, 47, 
	74, 8, 0, 21, 23, 0, 0, 46, 
	49, 49, 1, 9, 9, 21, 23, 9, 
	9, 75, 9, 9, 1, 9, 8, 9, 
	21, 23, 9, 9, 75, 9, 9, 1, 
	0, 44, 47, 74, 8, 0, 21, 23, 
	0, 0, 46, 46, 46, 1, 0, 44, 
	47, 74, 8, 0, 21, 23, 0, 0, 
	63, 46, 46, 1, 0, 44, 47, 74, 
	8, 0, 21, 23, 0, 0, 60, 46, 
	46, 1, 0, 44, 47, 76, 74, 8, 
	0, 21, 23, 0, 0, 63, 60, 46, 
	46, 1, 0, 44, 47, 74, 8, 0, 
	21, 23, 0, 0, 60, 46, 46, 46, 
	1, 0
};

static const char _ragel_url_email_trans_targs[] = {
	2, 0, 30, 48, 50, 49, 52, 3, 
	5, 4, 6, 26, 28, 27, 8, 7, 
	13, 9, 10, 58, 11, 60, 12, 61, 
	61, 12, 61, 14, 22, 24, 23, 15, 
	16, 18, 20, 19, 17, 62, 63, 65, 
	64, 21, 25, 29, 31, 35, 32, 33, 
	34, 67, 36, 44, 46, 45, 37, 38, 
	40, 42, 41, 39, 70, 71, 73, 72, 
	43, 47, 51, 53, 54, 55, 56, 57, 
	59, 66, 68, 69, 74
};

static const char _ragel_url_email_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 1, 0, 1, 0, 1, 
	2, 3, 4, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 1, 1, 1, 
	1, 0, 0, 0, 0, 0, 0, 0, 
	0, 1, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 1, 1, 1, 1, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	1, 1, 1, 1, 1
};

static const int ragel_url_email_start = 1;

vector<uint8_t> ragel_tokenizer::ragel_map;
atomic_flag ragel_tokenizer::ragel_map_flag = ATOMIC_FLAG_INIT;

ragel_tokenizer::ragel_tokenizer(unsigned url_email_tokenizer) : unicode_tokenizer(url_email_tokenizer) {
  initialize_ragel_map();
}

void ragel_tokenizer::initialize_ragel_map() {
  while (ragel_map_flag.test_and_set()) {}
  if (ragel_map.empty()) {
    for (uint8_t ascii = 0; ascii < 128; ascii++)
      ragel_map.push_back(ascii);

    ragel_map_add(U'\u2026', 160); // horizontal ellipsis (TRIPLE DOT)
    ragel_map_add(U'\u2019', 161); // right single quotation mark
    ragel_map_add(U'\u2018', 162); // left single quotation mark
    ragel_map_add(U'\u2010', 163); // hyphen
  }
  ragel_map_flag.clear();
}

void ragel_tokenizer::ragel_map_add(char32_t chr, uint8_t mapping) {
  if (chr >= ragel_map.size())
    ragel_map.resize(chr + 1, 128);
  ragel_map[chr] = mapping;
}

bool ragel_tokenizer::ragel_url_email(unsigned version, const vector<char_info>& chars, size_t& current, vector<token_range>& tokens) {
  int cs;

  size_t start = current, end = current, parens = 0;
  
	{
	cs = ragel_url_email_start;
	}

	{
	int _klen;
	const short *_keys;
	int _trans;
	short _widec;

	if ( ( current) == ( (chars.size() - 1)) )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_widec = ( ragel_char(chars[current]));
	_klen = _ragel_url_email_cond_lengths[cs];
	_keys = _ragel_url_email_cond_keys + (_ragel_url_email_cond_offsets[cs]*2);
	if ( _klen > 0 ) {
		const short *_lower = _keys;
		const short *_mid;
		const short *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( _widec < _mid[0] )
				_upper = _mid - 2;
			else if ( _widec > _mid[1] )
				_lower = _mid + 2;
			else {
				switch ( _ragel_url_email_cond_spaces[_ragel_url_email_cond_offsets[cs] + ((_mid - _keys)>>1)] ) {
	case 0: {
		_widec = (short)(256u + (( ragel_char(chars[current])) - 0u));
		if ( 
 version >= 2  ) _widec += 256;
		break;
	}
	case 1: {
		_widec = (short)(768u + (( ragel_char(chars[current])) - 0u));
		if ( 
parens ) _widec += 256;
		break;
	}
				}
				break;
			}
		}
	}

	_keys = _ragel_url_email_trans_keys + _ragel_url_email_key_offsets[cs];
	_trans = _ragel_url_email_index_offsets[cs];

	_klen = _ragel_url_email_single_lengths[cs];
	if ( _klen > 0 ) {
		const short *_lower = _keys;
		const short *_mid;
		const short *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( _widec < *_mid )
				_upper = _mid - 1;
			else if ( _widec > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _ragel_url_email_range_lengths[cs];
	if ( _klen > 0 ) {
		const short *_lower = _keys;
		const short *_mid;
		const short *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( _widec < _mid[0] )
				_upper = _mid - 2;
			else if ( _widec > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _ragel_url_email_indicies[_trans];
	cs = _ragel_url_email_trans_targs[_trans];

	if ( _ragel_url_email_trans_actions[_trans] == 0 )
		goto _again;

	switch ( _ragel_url_email_trans_actions[_trans] ) {
	case 3:
	{parens-=!!parens;}
	break;
	case 1:
	{ end = current + 1; }
	break;
	case 2:
	{parens++;}
	{ end = current + 1; }
	break;
	case 4:
	{parens-=!!parens;}
	{ end = current + 1; }
	break;
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++( current) != ( (chars.size() - 1)) )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

  if (end > start) {
    tokens.emplace_back(start, end - start);
    current = end;
    return true;
  } else {
    current = start;
    return false;
  }
}

/////////
// File: tokenizer/vertical_tokenizer.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class vertical_tokenizer : public unicode_tokenizer {
 public:
  vertical_tokenizer() : unicode_tokenizer(0) {}

  virtual bool next_sentence(vector<token_range>& tokens) override;
};

/////////
// File: tokenizer/tokenizer.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

tokenizer* tokenizer::new_vertical_tokenizer() {
  return new vertical_tokenizer();
}

tokenizer* tokenizer::new_czech_tokenizer() {
  return new czech_tokenizer(czech_tokenizer::CZECH, czech_tokenizer::LATEST);
}

tokenizer* tokenizer::new_english_tokenizer() {
  return new english_tokenizer(english_tokenizer::LATEST);
}

tokenizer* tokenizer::new_generic_tokenizer() {
  return new generic_tokenizer(generic_tokenizer::LATEST);
}

/////////
// File: tokenizer/unicode_tokenizer.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

unicode_tokenizer::unicode_tokenizer(unsigned url_email_tokenizer) : url_email_tokenizer(url_email_tokenizer) {
  ragel_tokenizer::initialize_ragel_map();

  set_text(string_piece(nullptr, 0));
}

void unicode_tokenizer::set_text(string_piece text, bool make_copy /*= false*/) {
  using namespace unilib;

  if (make_copy && text.str) {
    text_buffer.assign(text.str, text.len);
    text.str = text_buffer.c_str();
  }
  current = 0;

  chars.clear();
  for (const char* curr_str = text.str; text.len; curr_str = text.str)
    chars.emplace_back(utf8::decode(text.str, text.len), curr_str);
  chars.emplace_back(0, text.str);
}

bool unicode_tokenizer::next_sentence(vector<string_piece>* forms, vector<token_range>* tokens_ptr) {
  vector<token_range>& tokens = tokens_ptr ? *tokens_ptr : tokens_buffer;
  tokens.clear();
  if (forms) forms->clear();
  if (current >= chars.size() - 1) return false;

  bool result = next_sentence(tokens);
  if (forms)
    for (auto&& token : tokens)
      forms->emplace_back(chars[token.start].str, chars[token.start + token.length].str - chars[token.start].str);

  return result;
}

bool unicode_tokenizer::tokenize_url_email(vector<token_range>& tokens) {
  if (current >= chars.size() - 1) return false;

  return url_email_tokenizer ? ragel_tokenizer::ragel_url_email(url_email_tokenizer, chars, current, tokens) : false;
}

bool unicode_tokenizer::emergency_sentence_split(const vector<token_range>& tokens) {
  using namespace unilib;

  // Implement emergency splitting for large sentences
  return tokens.size() >= 500 ||
         (tokens.size() >= 450 && chars[tokens.back().start].cat & unicode::P) ||
         (tokens.size() >= 400 && chars[tokens.back().start].cat & unicode::Po);
}

bool unicode_tokenizer::is_eos(const vector<token_range>& tokens, char32_t eos_chr, const unordered_set<string>* abbreviations) {
  using namespace unilib;

  if (eos_chr == '.' && !tokens.empty()) {
    // Ignore one-letter capitals before dot
    if (tokens.back().length == 1 && chars[tokens.back().start].cat & unicode::Lut)
      return false;

    // Ignore specified abbreviations
    if (abbreviations) {
      eos_buffer.clear();
      for (size_t i = 0; i < tokens.back().length; i++)
        utf8::append(eos_buffer, unicode::lowercase(chars[tokens.back().start + i].chr));
      if (abbreviations->count(eos_buffer))
        return false;
    }
  }
  return true;
}

/////////
// File: tokenizer/vertical_tokenizer.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

bool vertical_tokenizer::next_sentence(vector<token_range>& tokens) {
  if (current >= chars.size() - 1) return false;

  while (true) {
    size_t line_start = current;
    while (current < chars.size() - 1 && chars[current].chr != '\r' && chars[current].chr != '\n') current++;

    size_t line_end = current;
    if (current < chars.size() - 1) {
      current++;
      if (current < chars.size() - 1 &&
          ((chars[current-1].chr == '\r' && chars[current].chr == '\n') ||
           (chars[current-1].chr == '\n' && chars[current].chr == '\r')))
        current++;
    }

    if (line_start < line_end)
      tokens.emplace_back(line_start, line_end - line_start);
    else
      break;
  }

  return true;
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
// UniLib version: 3.1.1
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
// UniLib version: 3.1.1
// Unicode version: 8.0.0

namespace unilib {

bool utf8::valid(const char* str) {
  for (; *str; str++)
    if (((unsigned char)*str) >= 0x80) {
      if (((unsigned char)*str) < 0xC0) return false;
      else if (((unsigned char)*str) < 0xE0) {
        str++; if (((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return false;
      } else if (((unsigned char)*str) < 0xF0) {
        str++; if (((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return false;
        str++; if (((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return false;
      } else if (((unsigned char)*str) < 0xF8) {
        str++; if (((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return false;
        str++; if (((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return false;
        str++; if (((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return false;
      } else return false;
    }
  return true;
}

bool utf8::valid(const char* str, size_t len) {
  for (; len > 0; str++, len--)
    if (((unsigned char)*str) >= 0x80) {
      if (((unsigned char)*str) < 0xC0) return false;
      else if (((unsigned char)*str) < 0xE0) {
        str++; if (!--len || ((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return false;
      } else if (((unsigned char)*str) < 0xF0) {
        str++; if (!--len || ((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return false;
        str++; if (!--len || ((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return false;
      } else if (((unsigned char)*str) < 0xF8) {
        str++; if (!--len || ((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return false;
        str++; if (!--len || ((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return false;
        str++; if (!--len || ((unsigned char)*str) < 0x80 || ((unsigned char)*str) >= 0xC0) return false;
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
// UniLib version: 3.1.1
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
// UniLib version: 3.1.1
// Unicode version: 8.0.0

namespace unilib {

// Returns current version.
version version::current() {
  return {3, 1, 1, ""};
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

namespace utils {

// Start of LZMA compression library by Igor Pavlov
namespace lzma {

// Types.h -- Basic types
// 2010-10-09 : Igor Pavlov : Public domain
#ifndef UFAL_CPPUTILS_COMPRESSOR_LZMA_TYPES_H
#define UFAL_CPPUTILS_COMPRESSOR_LZMA_TYPES_H

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

#endif // UFAL_CPPUTILS_COMPRESSOR_LZMA_TYPES_H

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

#ifndef UFAL_CPPUTILS_COMPRESSOR_LZMA_ALLOCATOR_H
#define UFAL_CPPUTILS_COMPRESSOR_LZMA_ALLOCATOR_H
static void *LzmaAlloc(void* /*p*/, size_t size) { return new char[size]; }
static void LzmaFree(void* /*p*/, void *address) { delete[] (char*) address; }
static lzma::ISzAlloc lzmaAllocator = { LzmaAlloc, LzmaFree };
#endif // UFAL_CPPUTILS_COMPRESSOR_LZMA_ALLOCATOR_H

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

} // namespace utils

/////////
// File: version/version.h
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class version {
 public:
  unsigned major;
  unsigned minor;
  unsigned patch;
  string prerelease;

  // Returns current MorphoDiTa version.
  static version current();

  // Returns multi-line formated version and copyright string.
  static string version_and_copyright(const string& other_libraries = string());
};

/////////
// File: version/version.cpp
/////////

// This file is part of MorphoDiTa <http://github.com/ufal/morphodita/>.
//
// Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
// Mathematics and Physics, Charles University in Prague, Czech Republic.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

version version::current() {
  return {1, 9, 2, ""};
}

// Returns multi-line formated version and copyright string.
string version::version_and_copyright(const string& other_libraries) {
  ostringstream info;

  auto morphodita = version::current();
  auto unilib = unilib::version::current();

  info << "MorphoDiTa version " << morphodita.major << '.' << morphodita.minor << '.' << morphodita.patch
       << (morphodita.prerelease.empty() ? "" : "-") << morphodita.prerelease
       << " (using UniLib " << unilib.major << '.' << unilib.minor << '.' << unilib.patch
       << (other_libraries.empty() ? "" : " and ") << other_libraries << ")\n"
          "Copyright 2015 by Institute of Formal and Applied Linguistics, Faculty of\n"
          "Mathematics and Physics, Charles University in Prague, Czech Republic.";

  return info.str();
}

} // namespace morphodita
} // namespace ufal
