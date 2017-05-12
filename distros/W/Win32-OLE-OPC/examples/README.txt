This directory contains the following example scripts:

browserproperties.pl
    This example shows the properties of the browser interface on all the
    installed servers.

groups.pl
    This example uses groups, group, items and item objects to get and set
    data from the server.  You will have to supply the OPC path names of some
    items and the server they are in for this to do anything.

    Search for the string 'Put your values in here' and put them there!

    The variables should be set like this:

        $server is the progid of your OPC server.

        @items_read is an array of strings each of which is an OPC path name.
        The script translates these into item id's by using the
        Win32::OLE::OPC::GetItemIdFromName which is not a part of the OPC
        standard browser interface but is pretty useful.

        %items_write is a hash whose keys are the OPC names of items to write
        and whose value is the value you want to write.  The script reads
        the original value, writes the new value, waits two seconds and then
        writes the original value back.

items.pl
    This example lists all the items in the server address space listing all
    the properties of that item.  It uses the OPC browser methods to do this.

serverproperties.pl
    This example shows the properties of all the installed servers.

tiedhash.pl
    This example lists all the items in the server address space listing all
    the properties of that item.  It uses a tied hash to do this.  This method
    of accessing the server is very convenient but not terribly efficient.


It is assumed that you are using the FactorySoft OPC automation DLL which
has the progid 'OPC.Automation' as your OPC dispatch inteface for your OPC
server.
