# Copyright 2000-2001 ActiveState

"""Python DBI - Interface to Perl's DBI from Python.

A connection to the database is created and returned by the connect()
function.  Example:

  dbh = dbi.connect("DBI:mysql:database=test", "username", "password"
                     RaiseError = 1,
                     PrintError = 0,
                     AutoCommit = 1,
                    )

  sth = dbh.prepare("select * from foo")
  rows = sth.execute()
  while 1:
      row = sth.fetchrow_tuple()
      if not row:
          break
      print row

The object returned by connect() is actually the Perl DBI datahandle
object.  This means that the interface provided with be exactly like
that of the Perl DBI.  Extended documentation on DBI available from
the 'perldoc DBI' command.

The dbi2 module provide an interface to Perl DBI that conforms to
Python's own DB API.
"""

import perl

perl.require("DBI")


def connect(data_source, username, password="", **attr):
	"""Make a new connection to the database

The first parameter is the data_source string (something beginning with "DBI:").
Then there is a username and a password and at last other named configuration
parameters like; RaiseError, PrintError and AutoCommit.
"""
        dbh = perl.callm("connect", "DBI", data_source, username, password,
			            dict2hash(attr))
	return dbh

def available_drivers():
	return perl.callm_tuple("available_drivers", "DBI")

def data_sources(driver):
	return perl.callm_tuple("data_sources", "DBI", driver)

def trace(level, filename=None):
	return perl.callm("trace", "DBI", level, filename)

def dict2hash(dict):
	hash = perl.get_ref("%")
	hash.update(dict)
	return hash

