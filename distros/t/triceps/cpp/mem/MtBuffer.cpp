//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The common buffer base of all the row implementations.

#include <mem/MtBuffer.h>
#include <stdlib.h>
#include <stdio.h>

namespace TRICEPS_NS {

/////////////////////// MtBuffer ////////////////////////

void *MtBuffer::operator new(size_t basic, intptr_t variable)
{
	return malloc((intptr_t)basic + variable);
}

void MtBuffer::operator delete(void *ptr)
{
	free(ptr);
}

/////////////////////// VirtualMtBuffer ////////////////////////

void *VirtualMtBuffer::operator new(size_t basic, intptr_t variable)
{
	return malloc((intptr_t)basic + variable);
}

void VirtualMtBuffer::operator delete(void *ptr)
{
	free(ptr);
}

VirtualMtBuffer::~VirtualMtBuffer()
{ }

}; // TRICEPS_NS
