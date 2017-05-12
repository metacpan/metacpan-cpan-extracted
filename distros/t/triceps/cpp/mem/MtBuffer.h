//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The common buffer base of all the row implementations.

#ifndef __Triceps_MtBuffer_h__
#define __Triceps_MtBuffer_h__

#include <common/Common.h>
#include <mem/Mtarget.h>

namespace TRICEPS_NS {

// It's essentially an Mtarget-ed array of bytes, where a particular
// MtBufferType knows how to interpret these bytes. This includes the deletion.
// DON'T delete these objects directly, do it through the specific subclass
// or through the appropriate row (factory) type.
// It can be used to store any other byte array, like a C string, too.

// A way to limit the deletion privileges to certain classes,
// if some class is allowed to delete the buffers directly, it must
// inherit from MtBufferOwner.
class MtBufferOwner;

// The subclasses of this MAY NOT HAVE VIRTUAL FUNCTIONS or all the
// memory locations will go askew. If needed, use a VirtualMtBuffer.
class MtBuffer : public Mtarget
{
	friend class MtBufferOwner; // may delete the buffers
public:
	
	enum { ALIGN = 8 }; // default alignment of the payload from the start of structure

	// The offset calculation is a helper for the case of the completely
	// manual layout of the internals.
	// XXX and it doesn't help much either, because the variable
	// argument of new() is already exclusive of Mtarget
	
	// get the starting offset for the payload
	static size_t payloadOffset()
	{
		return ((sizeof(Mtarget) + ALIGN - 1) / ALIGN) * ALIGN;
	}
	// With a constant argument this should also devolve into a constant
	// computation, but just in case, provide also the default definit constant.
	static size_t payloadOffset(size_t align)
	{
		return ((sizeof(Mtarget) + align - 1) / align) * align;
	}

	// @param basic - provided by C++ compiler, size of the basic structure
	// @param variable - size of the additional storage (may be negative)
	static void *operator new(size_t basic, intptr_t variable);
	static void operator delete(void *ptr);

protected:
	// Delete either as a specific subclass's instance, or through the
	// row type class (see MtBufferOwner).
	~MtBuffer()
	{ }
};

// see the comment at declaration
class MtBufferOwner
{
protected:
	// After the subclass is done with destroying the contents of the buffer,
	// call here to destroy it.
	static void callDeleteMtBuffer(MtBuffer *r)
	{
		delete r;
	}
};

// A version with virtual table, allowing to define the destructors directly.
class VirtualMtBuffer : public Mtarget
{
public:
	
	enum { ALIGN = MtBuffer::ALIGN }; // default alignment of the payload from the start of structure

	// The offset calculation is a helper for the case of the completely
	// manual layout of the internals.
	// XXX and it doesn't help much either, because the variable
	// argument of new() is already exclusive of Mtarget
	
	// get the starting offset for the payload
	static size_t payloadOffset()
	{
		return ((sizeof(Mtarget) + ALIGN - 1) / ALIGN) * ALIGN;
	}
	// With a constant argument this should also devolve into a constant
	// computation, but just in case, provide also the default definit constant.
	static size_t payloadOffset(size_t align)
	{
		return ((sizeof(Mtarget) + align - 1) / align) * align;
	}

	// @param basic - provided by C++ compiler, size of the basic structure
	// @param variable - size of the additional storage (may be negative)
	static void *operator new(size_t basic, intptr_t variable);
	static void operator delete(void *ptr);

	virtual ~VirtualMtBuffer();
};

}; // TRICEPS_NS

#endif // __Triceps_MtBuffer_h__
