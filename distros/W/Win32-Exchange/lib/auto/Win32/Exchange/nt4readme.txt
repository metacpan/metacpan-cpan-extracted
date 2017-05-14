********Note for users using NT4.  The following announcement is largely conjecture, but:

If you find yourself using NT4 with this module and then suddenly, without notice you start recieving:
LDAP_SERVER_DOWN messages (0x8007203a), when you know the server is up, and you know you haven't changed a thing..

It's time to upgrade to Win2K, reinstall ADSI 2.5, or worse, reinstall NT4 on your system (so in 6 months you can 
do this again :)  )

From what I can gather from M$, ADSI 2.5 was just sort of thrown together for NT4, and there's not a lot of
dependency checking, so it fails intermittently (and without notice) if you start installing/removing other software.

Again, I am sorry for your loss, but I am telling you this from experience.

So, if you want to use NT4, install ADSI 2.5, get the ADSI SDK from MS and register the ADSSecurity.dll
for the security manipulations, and then NEVER install/remove any other software or security updates on
this box again!

If this doesn't get you to use Win2K nothing will, but don't say I didn't warn you.

Check out the example.pl for a list of current functions.  Documentation to follow (but I have none for now).

Thanks,

Steven Manross
steven@manross.net