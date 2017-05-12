use Win32::ProcFarm::Parent;
use Win32::ProcFarm::Port;

$port_obj = Win32::ProcFarm::Port->new(9000, 1);

$interface = Win32::ProcFarm::Parent->new_async($port_obj, 'DirChild.pl', Win32::GetCwd);

$interface->connect;

$interface->execute('dir', 'C:\\');

until($interface->get_state eq 'fin') {
  print "Waiting for ReturnValue.\n";
  sleep(1);
}
print "GotReturnValue.\n";
print $interface->get_retval;
