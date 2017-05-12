Author: Jerzy Wachowiak; Version: 1.2; Last update: 2005-05-20.

==========================================
   Hints for deployment tools usage
==========================================


@ Utilities for preparing separate deployment tasks:

[1] xdTemplate.xls

xdTemplate allows convenient and structered intergration planing using 
spreadsheet. It enforces the consistent record format for every participant: 
description; role; hostname; port; username; password; resource; operating 
system (optional); home path (optional). The role can be only: sender, receiver
or archivist. Comments have to start with #. After planing integration export 
the resulting sheet to the comma separeted file (*.csv), which is used as input
for all other scripts. Customise spreadsheet to your planing needs expanding 
the range of columns and automating data input! Write your own
extensions scripts using the exported *.csv file.

[2] xdreg

USAGE:
./xdreg filename

DESCRIPTION:
xdreg registers accounts on the jabber server. The only input parameter
is a file. The records in the input file must have the format:
description; role; hostname; port; username; password; resource.
The role can be only: sender, receiver or archivist. Comments have to start 
with #.

[3] xdcnf

USAGE:
./xdcnf filename

DESCRIPTION:
xdcnf creates for scripts: sender, receiver and archivist configuration files 
respective sender.xml, receiver.xml and archivist.xml in the directories with
the name of their JID. The only input parameter is a file. The records in the
input file must have the format: description; role; hostname; port; username;
password; resource. The role can be only: sender, receiver or archivist. 
Comments have to start with #.

[4] xdosr

USAGE:
./xdosr filename

DESCRIPTION:
xdosr creates for scripts: sender, receiver and archivist registration files 
with Windows NT/2k/XP and Linux in the directories with the name of their JID. 
The usage is described in the generated files. The only input parameter is 
a file. The records in the input file must have the format: description; role; 
hostname; port; username; password; resource; operating system; home path. 
The role can be only: sender, receiver or archivist. Comments have to start 
with #.

[5] xdpg

USAGE:
./xdpg filename [database_name]

DESCRIPTION:
xdpg creates sql for the initialization of the xDash database on the PostgreSQL
in the directory with the name of archivist JID. The mandatory input parameter
is a file and optional a name for the result sql file. The records in the input
file must have the format: description; role; hostname; port; username; 
password; resource; operating system; home path. The role can be only: sender, 
receiver or archivist. Comments have to start with #.

[6] xdscr

USAGE:
./xdscr filename

DESCRIPTION:
xdscr creates scripts for sender, receiver and archivist execution files 
in the directories with the name of their JID. The usage and needed 
customisation are described in the generated files. The only input parameter
is a file.The records in the input file must have the format: description; role;
hostname; port; username; password; resource; operating system; home path. 
The role can be only: sender, receiver or archivist. Comments have to start 
with #.

[7] xdstraw

USAGE:
./xdstraw filename

DESCRIPTION:
xdstraw creates for Sender, Receiver and Archivist xml jabber test messages 
in directory straw inside directories with the name of their JID and copies the
the script straw to them. The usage of messages and of the script are described 
in the generated file ReadMe.txt and script built-in help. The only input 
parameter is a file. The records in the input file must have the format: 
description; role; hostname; port; username; password; resource.The role can 
be only: sender, receiver or archivist. Comments have to start with #.

[8] xdclean

USAGE:
./xdclean filename

DESCRIPTION:
xdclean compresses and tars directories with the name of their JID to 
a file with name pattern: username@host_ressource.tar.gz and removes 
the JID directories. The records in the input file must have the format: 
description; role; hostname; port; username; password; resource. The role can 
be: sender, receiver or archivist. Comments have to start with #.

[9] xdpkg

USAGE:
./xdpkg

DESCRIPTION:
xdpkg installs, using: apt-get -y install <package_name>, all the debian 
packages needed by xDash and gives hints about further manual configuration.


@ Scripts gluing separate tasks into one registration process:

[1] xdgo 

USAGE:
./xdgo filename [database_name]

DESCRIPTION:
xdgo glues xdreg, xdcnf, xdpg, xdosr, xdscr, xdstraw, xdclean. The mandatory 
input parameter is a filename and optional a name for the resulting active 
PostgreSQL database. The records in the input file must have the format: 
description; role; hostname; port; username; password; resource; operating 
system; home path. The role can be: sender, receiver or archivist. Comments 
have to start with #.


@ Auxiliary scripts and libraries:

[1] xdSRA.pm
xdSRA is a module needed by the scripts for parsing csv files. It depends on 
Text::CSV_XS from CPAN.

[2] straw

USAGE:
usage: $0 -h host -p port [-d directory]

DESCRIPTION:
straw opens on start an INET socket connection to the host and port specified 
in the argument line and starts a very simple shell. Shell input is interpreted 
as a file name in the straw current working directory or directory specyfied
in the argument line at start. The content of the file is read and transmitted
to the host and the answer is displayed. As straw is used mostly with XML 
protocols, XML is coloured but no pretty printing is used. To stop straw use 
CTR+C.

[3] chmod-xd

USAGE:
./chmod-xd options

DESCRIPTION:
chmod-xd changes permissions for files listed in the chmod-xd script,
see chmod command description for options details.

Author: Jerzy Wachowiak; Version: 1.1; Last update: 2004-07-01.

