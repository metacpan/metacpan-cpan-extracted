#ifndef COMPONENT_H
#define COMPONENT_H

#ifdef WIN32
// Suppress warnings about debug identifiers being truncated to 255 characters
#pragma warning (disable:4786)
#endif

#include "basic_types/event.h"

// An RBD component is the same thing as an FA basic event.
typedef Event Component;

#endif // COMPONENT_H
