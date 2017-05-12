Author: Jerzy Wachowiak; Version: 1.1; Last update: 2005-05-20.

==========================================
   Hints for administrative tools usage
==========================================

@ The idea behind administrative tools is to have 2 sets of utilities.
The first one deals with messages and statistcs belonging to one single thread,
the second one deals on statistics without distinction of thread for the whole
archive. The admin can check the state of the integration looking at the 
statistics of all threads and than look closer at single threads,
where something went wrong.


@ Utilities acting on a one choosen thread:

[1] xdshow

USAGE:
./xdshow -d database [-u user] [-p password] -t thread [-ms]

DESCRIPTION:
xdshow displays messages and statistics belonging to a thread from the database:
-m		shows only messages belonging to the thread (option);
-s		shows only statistic belonging to the thread (option);
-t thread	the message thread to act on;
-d name		PostgreSQL database name;
-u user		username, if no switch, root assumed;
-p password	password, if no switch, root password assumed.

OUTPUT:

[1] -m switch (messages):
thread varchar( 250 );
entrytime timestamp;
fromuser varchar( 257 );
server varchar( 342 );
resource varchar( 250 );
type varchar( 20 );
subject varchar( 500 );
body text;
errorcode int;
errordescription varchar( 500 )

[2] -s switch (statistics):
thread varchar( 250 ) not null;
lastupdate timestamp;
starttime timestamp;
deltatime interval default '0 second';
sender1_occurence int not null default '0';
...
senderX_occurence int not null default '0';
receiver1_occurence  int not null default '0';
receiver1_result int not null default '0';
...
receiverX_occurence  int not null default '0';
receiverX_result int not null default '0';
error_counter int not null default '0'

[2] xddelete

USAGE:
./xddelete -d database [-u user] [-p password] -t thread [-ms]

DESCRIPTION: 
xddelete removes messages and statistics belonging to a thread from the 
database and returns number of deleted messages and statistics:
-m		deletes only messages belonging to the thread (option);
-s		deletes only statistics belonging to the thread (option);
-t thread	the message thread to act on;
-d name		PostgreSQL database name;
-u user		username, if no switch, root assumed;
-p password	user password, if no switch, root password assumed.

OUTPUT:
number of removed messages;
number of removed statistics

@ Utilties acting on all messages and statisctics fulfilling the conditions:

[1] xdlist

USAGE: 
./xdlist -d database [-u user] [-p password] [-gbrfwt] [-o time]

DESCRIPTION:
xdlist displays message statistics from the database:
-g		good jobs, jobs done by receiver without errors (option);
-b		bad jobs, some errors reported by receiver (option);
-r		running job, sender or receiver message still missing (option);
-f		finished jobs, both sender and receiver sent a message (option);
-w		warning, messages with the same thread arrived several times
		from sender or receiver (option);
-o time		at least delta time in seconds between sender and receiver 
		message arrival (option); 
-t		lists only threads, no other information (option);
-d name		PostgreSQL database name;
-u user		username, if no switch, root assumed;
-p password	user password, if no switch, root password assumed.

OUTPUT:
thread varchar( 250 ) not null;
lastupdate timestamp;
starttime timestamp;
deltatime interval default '0 second';
sender1_occurence int not null default '0';
...
senderX_occurence int not null default '0';
receiver1_occurence  int not null default '0';
receiver1_result int not null default '0';
...
receiverX_occurence  int not null default '0';
receiverX_result int not null default '0';
error_counter int not null default '0'

[2] xdpurge

USAGE:
./xdpurge -d database [-u user] [-p password] [-gbrfw] [-o time]

DESCRIPTION:
xdpurge deletes all messages and statistics fulfilling the conditions
from the database and returns number of deleted messages and statistics:
-g		good jobs, jobs done without errors by receiver (option);
-b		bad jobs, some errors reported by receiver (option);
-r		running job, sender or receiver message still missing (option);
-f		finished jobs, both sender and receiver sent a message (option);
-w		warning, messages with the same thread arrived several times
		from sender or receiver (option);
-o time		at least delta time in seconds between sender and receiver 
		message arrival (option); 
-d name		PostgreSQL database name;
-u user		username, if no switch, root assumed;
-p password	user password, if no switch, root password assumed.

OUTPUT:
number of removed messages;
number of removed statistics

@ Auxiliary scripts

[1] chmod-xd

USAGE:
./chmod-xd options

DESCRIPTION:
chmod-xd changes permissions for files listed in the chmod-xd script.
See chmod man pages for option details!
