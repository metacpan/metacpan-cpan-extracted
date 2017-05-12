// Mode: -*- C++ -*-

//          GiSTfile.h
//
// Copyright (c) 1996, Regents of the University of California
// $Header: /cvsroot/Tree-M/GiST/GiSTfile.h,v 1.2 2001/05/23 02:11:14 root Exp $

#ifndef GISTFILE_H
#define GISTFILE_H

#include "GiSTstore.h"

// GiSTfile is a simple storage class for GiSTs to work over 
// UNIX/NT files.

class GiSTfile: public GiSTstore {
public:
  GiSTfile(): GiSTstore() {}

  virtual void Create(const char *filename);
  virtual void Open(const char *filename);
  virtual void Close();

  virtual void Read(GiSTpage page, char *buf);
  virtual void Write(GiSTpage page, const char *buf);
  virtual GiSTpage Allocate();
  virtual void Deallocate(GiSTpage page);
  //virtual void Sync() {}
  //virtual int PageSize() const { return 4096; }

private:
  int fileHandle;
};

#endif
