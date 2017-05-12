//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A common way for reporting of the errors

#ifndef __Triceps_Errors_h__
#define __Triceps_Errors_h__

#include <vector>
#include <string>
#include <mem/Starget.h>

namespace TRICEPS_NS {

using namespace std;

// Each function that does the check for the correctness of data supplied
// by the user must return the detailed messages about these errors.
// The checking doesn't have to stop on the first error, it may continue
// to find as many errors in one go as possible.
// As the error detection unwinds, it has to preserve the hierarachy of
// messages returned.
class Errors: public Starget
{
public:
	// Since the error checking normally happens in one thread,
	// using the Stragtet should be fine.
	//
	// The messages from this element are collected in the parent vector,
	// and inheriting it allows to skip doing the wrappers for all its methods.
	//
	// This same structure can be used to report warnings too, so the flag
	// error_ shows that there actually was an error.
	
	// The default of false allows to collect the child errors by append(),
	// which would set it to true if any child found an error, and of course
	// the erro flag can be set directly in this object too.
	Errors(bool e = false);

	// A quick way to create an object with a ready error message.
	// This always sets the error flag.
	// @param msg - the error message (may be multi-line)
	Errors(const char *msg);
	Errors(const string &msg);

	// A quick way to create an object with a ready error message
	// and a child error. Convenient for re-throwing an Exception
	// with extra high-level information.
	// This always sets the error flag.
	// @param msg - the error message (may be multi-line)
	// @param clde - errors returned by child (or NULL)
	Errors(const string &msg, Autoref<Errors> clde);

	// Append a direct error message.
	// @param e - flag: true if error, false if warning
	// @param msg - the error message
	void appendMsg(bool e, const string &msg);

	// Append a direct error message.
	// @param e - flag: true if error, false if warning
	// @param msg - the error message that may contain line breaks in it,
	//        those will be broken up into the separate messages
	void appendMultiline(bool e, const string &msg);

	// Add information about a child's errors.
	// If the child had the error flag set, sets the error flag here too.
	// @param msg - message describing the child, will be added only if the
	//        child errors are not empty
	// @param clde - errors returned by child (or NULL)
	// @return - true if the child's errors were added
	//       (if at least one of two was true: clde contained any messages
	//       and/or an error indication flag)
	bool append(const string &msg, Autoref<Errors> clde);

	// Similar to append() but copies the errors from the child
	// to the parent's level instead of nesting them.
	// @param clde - errors returned by child (or NULL)
	// @return - true if the child's errors were added
	//       (if at least one of two was true: clde contained any messages
	//       and/or an error indication flag)
	bool absorb(Autoref<Errors> clde);

	// Replace the last message. The typical usage pattern is:
	//
	// if (e.append("", clde)) {
	//     string msg;
	//     // ... generate msg in some complicated way
	//     e.replaceMsg(msg);
	// }
	//
	// The idea is to create the identification message only if it's
	// actually needed, in case if this generation is very slow.
	// Most of the time just giving the message directly to append()
	// should be good enough.
	// @param msg - message describing the child, will be replaced in the
	//        last error record
	void replaceMsg(const string &msg);

	// Check recursively whether ethere are no messages.
	// May be called on a NULL pointer as well.
	// @return - true if there are no messages throughout hierarchy
	bool isEmpty();

	// Check if has an error.
	// May be called on a NULL pointer as well.
	// @return - true if has an error
	bool hasError()
	{
		if (this == NULL)
			return false;
		return error_;
	}
	
	// Print the messages recursively by appending them to a string.
	// @param res - the resulting string to append to
	// @param indent - initial indentation characters
	// @param subindent - indentation characters to add on each level
	void printTo(string &res, const string &indent = "", const string &subindent = "  ");

	// Print in a simple way and return the result string.
	// @param indent - initial indentation characters
	// @param subindent - indentation characters to add on each level
	// @return - the result string
	string print(const string &indent = "", const string &subindent = "  ");

	// Get the number of messages (without taking nesting into account).
	// (useful mostly for testing)
	size_t size() const
	{
		return elist_.size();
	}

	// clear the contents
	void clear();

public:
	// All the error messages are stored in these pairs, where both
	// components are optional
	struct Epair 
	{
		Epair();
		Epair(const string &msg, Autoref<Errors> child);

		string msg_; // message describing the error or the identity of a child object
		Autoref<Errors> child_; // errors from the child object
		// In the future, may also have the strucutred information about the location of error
		// (line numbers etc.)
	};

	vector <Epair> elist_; // list of errors
	bool error_; // true if there is an error somewhere, false if only warnings
};

// The typical error indication returned by the parsing functions.
// Is  a reference to Errors plus a couple of convenience methods.
class Erref: public Autoref<Errors>
{
public:
	typedef Autoref<Errors> Parent;

	// Define a constructor for each one of Autoref's.
	Erref()
	{ }
	Erref(Errors *t) :
		Parent(t)
	{ }
	Erref(const Parent &ar) :
		Parent(ar)
	{ }
	template <typename OtherTarget>
	Erref(const Autoref<OtherTarget> &ar) :
		Parent(ar)
	{ }

	// Add information about a child's errors, allocating an Errors
	// object if needed. The Erref may initially contain a NULL,
	// and will have a new Errors added to it before any error
	// gets added to it. Or if no errors are added, Erref is left unchanged.
	//
	// It's different from Errors::append in ignoring the non-error
	// messages returned by the child.
	//
	// An important point worth telling once more: if clde is NULL
	// or contains no errors, the Erref will be left unchanged.
	//
	// @param clde - errors returned by child (or NULL)
	// @param msg - message describing the child, will be added only if the
	//        child errors are not empty
	// @return - true if the child's errors were added
	//       (if clde had the error indication flag set)
	bool fAppend(Autoref<Errors> clde, const char *fmt, ...)
		__attribute__((format(printf, 3, 4))); // +1 for "this"

	// Add a message to the errors, allocating an Error object if needed.
	// The Erref may initially contain a NULL, and will have a new Errors 
	// created in it before addin an error. Always sets the error flag.
	//
	// @param fmt - the printf format string, followed by arguments. The 
	//        produced message may be multi-line.
	void f(const char *fmt, ...)
		__attribute__((format(printf, 2, 3))); // +1 for "this"
};

}; // TRICEPS_NS

#endif // __Triceps_Errors_h__
