# Provide an interface to DBI that conforms to the Python DB API spec
# http://www.python.org/topics/database/DatabaseAPI-2.0.html
#
# Todo:
#   - get exceptions right
#   - improve efficiency
#   - give access extra DBI methods and Driver specific methods
#   - how to deal with datefields?
#
# Copyright 2001 ActiveState

"""Expose Perl's DBI though the Python DB API v2 interface.

This module give access to Perl's DBI through with an interface that
conforms to the DB API:

    http://www.python.org/topics/database/DatabaseAPI-2.0.html

This module should probably not be regarded as thread safe since there
might be Perl DBI drivers that are not.  The DBI paramstyle is
'qmark'.

Example:

    import dbi2

    d = dbi2.connect("DBI:mysql:database=test", "root", "")

    c = d.cursor()

    c.execute("select * from foo")
    print "Rowcount =", c.rowcount

    print c.description
    while 1:
        row = c.fetchone()
        if not row:
           break
        print row

    c.close()

The 'dbi' module provide an interface to the raw Perl DBI.
"""

apilevel = "2.0"  # target, but not really there yet
threadsafety = 0
paramstyle="qmark"

perl = None

def connect(*arg):
    """Connect to the database

The first parameter is the DBI source string.  Then optional username
and password follows.
"""
    return apply(connection, arg)

class connection:
    def __init__(self, dsn, user=None, password=None):
        global perl
        if not perl:
            import perl
            perl.require("DBI")

        conf = perl.get_ref("%")
        conf["RaiseError"] = 0
        conf["PrintError"] = 0
        conf["AutoCommit"] = 1

        self.dbh = perl.callm("connect", "DBI", dsn, user, password, conf)
        if self.dbh is None:
            raise OperationalError, perl.eval("$DBI::errstr")

        self.dbh["RaiseError"] = 1
        
        try:
            self.dbh["AutoCommit"] = 0
            self.autocommit = 0
        except:
            self.autocommit = 1
            

    def commit(self):
        self.dbh.commit()

    def rollback(self):
        self.dbh.rollback()

    def cursor(self):
        return cursor(self.dbh)

    def close(self):
        self.dbh.disconnect()
        self.dbh = None

    def __del__(self):
        try:
            # XXX should we??
            self.dbh.disconnect()
        except:
            pass

class cursor:
    def __init__(self, dbh):
        self.dbh = dbh
        self.arraysize = 1

    def execute(self, operation, *param):
        self.sth = self.dbh.prepare(operation)
        apply(self.sth.execute, param)
        self._get_types()

    def executemany(self, operation, parameters):
        self.sth = self.dbh.prepare(operation)
        for p in parameters:
            apply(self.sth.execute, p)
        self._get_types()
        return rowcount

    def _get_types(self):
        self.types = map(lambda s: TYPES.get(s, (s, str)),
                         tuple(self.sth["TYPE"]))

    def __getattr__(self, attr):
        if attr == "rowcount":
            return self.sth.rows()
        elif attr == "description":
            return self._description()
        else:
            raise AttributeError, attr
        
    def _description(self):
        name = tuple(self.sth["NAME"])
        dsize = (0,) * len(name) # DBI does have this info
        isize = dsize
        types = map(lambda s: s[0], self.types)
        prec = tuple(self.sth["PRECISION"])
        scale = tuple(self.sth["SCALE"])
        null = tuple(self.sth["NULLABLE"])
        return zip(name, dsize, isize, types, prec, scale, null)

    def fetchone(self):
        row = list(self.sth.fetchrow_tuple())
        if not row:
            return None
        for i in range(len(self.types)):
            row[i] = self.types[i][1](row[i])
        return row

    def fetchmany(self, size=None):
        if not size:
            size = self.arraysize
        res = []
        while size >= 1:
            row = self.fetchone()
            if not row:
                break
            res.append(row)
            size = size - 1
        return res

    def fetchall(self):
        res = []
        while 1:
            row = self.fetchone()
            if not row:
                break
            res.append(row)
        return res

    def setinputsizes(self, sizes):
        pass

    def setoutputsize(self, size, column=None):
        pass

    def close(self):
        try:
            self.sth.finish()
        except:
            pass
        self.sth = None
        self.dbh = None

# Type constructors
def Date(year, month, day):
    return "%04d-%02d-%02d" % (year, month, day)

def Time(hour, min, sec):
    return "%2d:%02d:%02d" % (hour, min, sec)

def Timestamp(year, month, day, hour, min, sec):
    return Date(year, month, day) + " " + Time(hour, min, sec)

import time

def DateFromTicks(ticks):
    return apply(Date,time.localtime(ticks)[:3])

def TimeFromTicks(ticks):
    return apply(Time,time.localtime(ticks)[3:6])

def TimestampFromTicks(ticks):
    return apply(Timestamp,time.localtime(ticks)[:6])

Binary = str

def toNum(s):
    float(s)

TYPES = {
      1: ("CHAR", str),
      2: ("NUMERIC", toNum),
      3: ("DECIMAL", toNum),
      4: ("INTEGER", int),
      5: ("SMALLINT", int),
      6: ("FLOAT", float),
      7: ("REAL", float),
      8: ("DOUBLE", float),
      9: ("DATE", str),
     10: ("TIME", str),
     11: ("TIMESTAMP", str),
     12: ("VARCHAR", str),
     -1: ("LONGVARCHAR", str),
     -2: ("BINARY", str),
     -3: ("VARBINARY", str),
     -4: ("LONGVARBINARY", str),
     -5: ("BIGINT", long),
     -6: ("TINYINT", int),
     -7: ("BIT", int),
     -8: ("WCHAR", str),
     -9: ("WVARCHAR", str),
    -10: ("WLONGVARCHAR", str),
}

class TYPE:
    def __init__(self,*values):
	self.values = values

    def __cmp__(self,other):
	if other in self.values:
	    return 0
	if other < self.values:
	    return 1
	else:
	    return -1

STRING   = TYPE("CHAR", "VARCHAR", "LONGVARCHAR")
BINARY   = TYPE("BINARY", "VARBINARY", "LONGVARBINARY")
NUMBER   = TYPE("NUMERIC", "DECIMAL", "INTEGER", "SMALLINT",
                "FLOAT", "REAL", "DOUBLE",
                "BIGINT", "TINYINT", "BIT")
DATETIME = TYPE("DATE", "TIME", "TIMESTAMP")
ROWID    = TYPE()

## /* Standard SQL datatypes (ANSI/ODBC type numbering)            */
## #define SQL_ALL_TYPES           0
## #define SQL_CHAR                1
## #define SQL_NUMERIC             2
## #define SQL_DECIMAL             3
## #define SQL_INTEGER             4
## #define SQL_SMALLINT            5
## #define SQL_FLOAT               6
## #define SQL_REAL                7
## #define SQL_DOUBLE              8
## #define SQL_DATE                9       /* SQL_DATETIME in CLI! */
## #define SQL_TIME                10
## #define SQL_TIMESTAMP           11
## #define SQL_VARCHAR             12

## /* Other SQL datatypes (ODBC type numbering)                    */
## #define SQL_LONGVARCHAR         (-1)
## #define SQL_BINARY              (-2)
## #define SQL_VARBINARY           (-3)
## #define SQL_LONGVARBINARY       (-4)
## #define SQL_BIGINT              (-5)    /* too big for IV       */
## #define SQL_TINYINT             (-6)

## /* Support for Unicode and SQL92 */
## #define SQL_BIT                 (-7)
## #define SQL_WCHAR               (-8)
## #define SQL_WVARCHAR            (-9)
## #define SQL_WLONGVARCHAR        (-10)


# Exceptions
import exceptions

class Error(exceptions.StandardError):
    pass

class Warning(exceptions.StandardError):
    pass

class InterfaceError(Error):
    pass

class DatabaseError(Error):
    pass

class InternalError(DatabaseError):
    pass

class OperationalError(DatabaseError):
    pass

class ProgrammingError(DatabaseError):
    pass

class IntegrityError(DatabaseError):
    pass

class DataError(DatabaseError):
    pass

class NotSupportedError(DatabaseError):
    pass

if not __builtins__.has_key("zip"):
    def zip(*args):
        # for 1.5.2 which does not provide zip as a builtin
        i = 0
        res = []
        try:
            while 1:
                e = []
                for a in args:
                    e.append(a[i])
                res.append(tuple(e))
                i = i + 1
        except IndexError:
            pass
        return tuple(res)
