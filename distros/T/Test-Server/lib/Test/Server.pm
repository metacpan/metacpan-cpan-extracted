package Test::Server;

=head1 NAME

Test::Server - what about test driven administration?

=head1 SYNOPSIS

	cp -r examples /etc/t
	cd /etc/t
	vim test-server.yaml
	prove /etc/t

	use Test::Server;
	Test::Server->run();

=head1 DESCRIPTION

Ever heard of test driven development? What about test driven administration?
Take a look around F<examples/> folder for example tests that you can run
agains your server.

The general configuration should be done through the F<test-server.yaml> and should
be managable by any non Perl awear admin (are there any?). Of course you are free to
put any other test that make sence for your server.

The idea behind this is following: You run C<prove /etc/t> and everything is
fine. Server is up and running. Life is nice. Then somebody calls you at 3am...
Oups! What went wrong? You login to the server (if possible of course) and run
the C<prove /etc/t> friend. Something failed? => fix it. Nothing failed?
=> write a test that will reveal that something is wrong && fix the problem
of course ;). And then at 6am go happily to sleep again...

To be the administration really test drive ;) you should be writing your tests
before you install the server...

Any other benefits? What about migration || reinstalation of the server? Do you
always remember what services || purpouses is the server used for? You just
C<scp> the F</etc/t> folder to the new machine and C<prove /etc/t> will tell
you. If not you'll write a test ;).

Or are you writing firewall rules and need to check if you didn't close some
ports that you should not? Check out the F<03_open-ports.t>.

I hope you'll enjoy the idea as I do. (until I find that there are 30 other
similar solutions like this...)

=cut

use warnings;
use strict;

our $VERSION = '0.06';

=head1 METHODS

=head2 run()

For the moment just runs C<prove /etc/t>. Any other better idea?

=cut

sub run {
	my $class = shift;
	
	system('prove', shift || '/etc/t');
}

1;


__END__

=head1 examples/

I have tried to organize F<examples/> a little bit. Tests with F<01_*> should be
run directly on the server. The other should run also remotely. Than there can
be a central "test" server that will collect all F</etc/t> folders (without 01_*)
and the test could be run also remotely. Testing remote access to the services.
Store the collected test in F</folder/server_name>, run C<prove -r /folder> and
watch how everything works(?)!. 

The tests starting with F<02_*> should be essential but short running tests that
should work in all cases and the rest of the tests will most likely fail if they
do.

=head2 files

=over 4

=item 01_hostname-and-interfaces.t

check hostname and ip resolution on interfaces

=item 01_running-processes.t

check running processes

=item 02_dns-resolution.t

query dns server and check for the answers

check also if the dns responses are fast enought

=item 02_disk-free.t

disk free/full check

=item 02_resolv.conf.t

query all nameserver-s in /etc/resolv.conf and make sure all are reachable.

=item 02_time-sync.t

compare local machine time with a ntp server to make sure both are in the sync.

For the idea thanks to Emmanuel Rodriguez Santiago.

=item 02_messages.t

Checks a file(s) and generates failed tests on every line found there.
Allows any program in the system to pass messages to the monitoring simply by
adding line into a file

=item 03_sites-ok.t

check web sites

=item 03_open-ports.t

Check if the ports are open and if the service is responding.

=item 03_cmd-output.t

Check the output of the shell command with a regexp. Check the exit code.

For the idea thanks to Aldo Calpini.

=item 03_find-huge-files.t

Check folders it there are not too many files and if the files (logs, tmp,
etc.) didn't grow too large.

=item 03_folder-file.t

File directory permissions and sizes for a directories
(e.g. Is cache dir writeable for httpd)

For the idea thanks to Peter Hartl.

=item 03_interfaces-ptr.t

check if interfaces has a PTR record which properly resolves back to interface ip

=item 03_wakeup.t

After given number of days a fail test will occure. The purpose is to make sure
monitoring team is receiving alarms properly. If the admins finds out that this
test fails for couple of days without anyone notice then there is something
wrong.

=item 03_net-hops.t

Does traceroute and check first or last N network hops to the host. It's using system
C<traceroute> program.

=back

=head2 TODO

=over 4

=item 03_smart.t

run `smartctl -q errorsonly -H -l selftest /dev/hda` and produce error if there will
be some output

=item 03_reachable.t

check with Net::Ping if hosts are reachable

=back

=head1 sky

There are no restrictions in Perl and there are no best solutions => so the
sky is the limit! (Or we our self are the limit?)

=head1 INSTALL

Check out the F<Build.PL> for the list of examples that are installed in F</etc/t>.

=head1 TODO

Any wishes || good ideas for general server tests should go here.
Do you have any? Send it! Or even better send the .t file.

	* connect to database and check if count of rows in all table doesn't exceed some number

=head1 SEE ALSO

L<http://testanything.org/>,
L<http://en.wikipedia.org/wiki/Test_Anything_Protocol>
and a book "Perl Testing: A Developer's Notebook"

L<Test::System>

If you like automation check out also L<Sysadm::Install> for system admin scripting.

=head1 AUTHOR

Jozef Kutej

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jozef Kutej

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
