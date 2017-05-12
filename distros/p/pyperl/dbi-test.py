#!/usr/bin/env python

import dbi

for d in dbi.available_drivers():
	print d;
	try:
		for s in dbi.data_sources(d):
			print "  ", s
	except:
		pass
print "----"

#dbh = dbi.connect("dbi:NullP:")

#$dbh = DBI->connect("DBI:mysql:database=fotodb", "gisle", "",
#                    {
#                      RaiseError => 1,
#                      PrintError => 0,
#                      AutoCommit => 1,
#                    }) || die;


dbh = dbi.connect("DBI:mysql:database=fotodb", "gisle",
		  RaiseError = 1,
		  PrintError = 0,
		  AutoCommit = 1,
	         )

try:
    dbh["AutoCommit"] = 0
except:
    print "Can't turn off AutoCommit"

sth = dbh.prepare("select * from img limit 5")
rows = sth.execute()
print rows

while 1:
	row = sth.fetchrow_tuple()
        if not row: break
	print row

dbh.disconnect()
