//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Templates that help with the initialization and its result checking.

#ifndef __Triceps_Initialize_h__
#define __Triceps_Initialize_h__

namespace TRICEPS_NS {

// The wrappers for the classes that support the error reporting through
// getErrors(), like Type, and initialization like TableType.
// They allow to call the initialization inline:
//
// Autoref<SomeType> x = initialize((new SomeType)->addSomething());
// Autoref<SomeType> x = initializeOrThrow((new SomeType)->addSomething());
// Autoref<SomeType> x = checkOrThrow((new SomeType)->addSomething());
//
// The "orThrow" functions throw the Exception with the value returned
// from getErrors(). checkOrThrow() is intended for either classes that
// have no initialization, or to check the value later after initialization.
//
// The thrownn exception includes the stack trace.
//
// Normally the method initialize expects that the value is already
// in its final variable and returns nothing:
//
// Autoref<SomeType> x = (new SomeType)->addSomething();
// x->initialize();
// if (x->getErrors()->hasError()) {
//     ...
// }
//
// The functions below use the Onceref to make sure that the 
// constructed object is referenced and may have more references
// created and destroyed during initialization; and also to make
// sure that the object get destroyed on throwing.

// In templates the automatic casting between Autoref, Oceref and
// pointers doesn't work, so have to provide 3 separate versions
// of everything.

template<class T>
Onceref<T> initialize(Onceref<T> arg)
{
	arg->initialize();
	return arg;
};

template<class T>
Onceref<T> initialize(Autoref<T> arg)
{
	arg->initialize();
	return arg;
};

template<class T>
Onceref<T> initialize(T *ptr)
{
	Onceref<T> arg = ptr;
	arg->initialize();
	return arg;
};

template<class T>
Onceref<T> initializeOrThrow(Onceref<T> arg)
{
	arg->initialize();
	if (arg->getErrors()->hasError())
		throw Exception(arg->getErrors(), true);
	return arg;
};

template<class T>
Onceref<T> initializeOrThrow(Autoref<T> arg)
{
	arg->initialize();
	if (arg->getErrors()->hasError())
		throw Exception(arg->getErrors(), true);
	return arg;
};

template<class T>
Onceref<T> initializeOrThrow(T *ptr)
{
	Onceref<T> arg = ptr;
	arg->initialize();
	if (arg->getErrors()->hasError())
		throw Exception(arg->getErrors(), true);
	return arg;
};

template<class T>
Onceref<T> checkOrThrow(Onceref<T> arg)
{
	if (arg->getErrors()->hasError())
		throw Exception(arg->getErrors(), true);
	return arg;
};

template<class T>
Onceref<T> checkOrThrow(Autoref<T> arg)
{
	if (arg->getErrors()->hasError())
		throw Exception(arg->getErrors(), true);
	return arg;
};

template<class T>
Onceref<T> checkOrThrow(T *ptr)
{
	Onceref<T> arg = ptr;
	if (arg->getErrors()->hasError())
		throw Exception(arg->getErrors(), true);
	return arg;
};

}; // TRICEPS_NS

#endif // __Triceps_Initialize_h__

