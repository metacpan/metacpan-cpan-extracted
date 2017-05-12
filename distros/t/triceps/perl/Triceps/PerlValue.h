//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// Representation of the Perl values that can be passed to the other threads.

// Include TricepsPerl.h before this one.

// ###################################################################################

#ifndef __TricepsPerl_PerlValue_h__
#define __TricepsPerl_PerlValue_h__

#include <common/Conf.h>
#include <type/RowType.h>
#include <type/HoldRowTypes.h>

using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

// To pass the table types between the threads, all their Perl
// arguments have to be saved as the C++ internal representation and
// then converted back when imported into the new Perl thread.
class PerlValue : public Mtarget
{
public:
	// represents, what kind of value is stored here
	enum Choice {
		UNDEF,
		INT,
		FLOAT,
		STRING,
		ARRAY, // really an array reference
		HASH, // really a hash reference
		ROW_TYPE,
		ROW,
	};

	Choice choice_;
	// since the bulk is the object values that can't be unioned,
	// no point in bothering about an union at all
	IV i_; // INT
	double f_; // FLOAT
	string s_; // STRING
	vector<Autoref<PerlValue> > v_; // ARRAY and the values for HASH
	vector<string> k_; // keys for HASH
	Autoref<RowType> rowType_; // ROW_TYPE
	Rowref row_;

	// The default constructor sets the choice_ to UNDEF,
	// then a value can be parsed into it with parse().
	PerlValue();

	// Parse a Perl value into this object.
	// @param v - the Perl value to parse; if it's an AV or HV, it will
	//        be parsed recursively
	// @return - NULL on success, or an Errors reference if the Perl
	//        value can not be converted
	Erref parse(SV *v);

	// Create a new SV restored from this value.
	// The row type objects get copied, since normally the restore
	// would happen in a different thread than creation, and having
	// a separate copy makes things more efficient between the threads.
	//
	// @param holder - helper object that makes sure that multiple
	//        references to the same row type stay multiple references
	//        to the same copied row type, not multiple row types
	//        (unless it's NULL, which reverts to plain copying).
	//        The caller has to keep a reference to the holder for
	//        the duration.
	// @return - the restored value, with the reference count of 1
	SV *restore(HoldRowTypes *holder) const;

	// Compare for equality.
	bool equals(const PerlValue *other) const;

	// Make a new PerlValue by parsing an SV.
	// 
	// Throws an Exception if it can not be parsed.
	//
	// @param v - the Perl value to parse; if it's an AV or HV, it will
	//        be parsed recursively
	static PerlValue *make(SV *v);
};

// The wrapping is mostly for testing but may have some uses...
extern WrapMagic magicWrapPerlValue;
typedef Wrap<magicWrapPerlValue, PerlValue> WrapPerlValue;

}; // Triceps::TricepsPerl
}; // Triceps


#endif // __TricepsPerl_PerlValue_h__

