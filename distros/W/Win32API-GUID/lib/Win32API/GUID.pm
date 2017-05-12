package Win32API::GUID;

use 5.008;

require Exporter;

our @ISA = qw (Exporter);
our @EXPORT = qw (CreateGuid);

our $VERSION = '0.2';

require XSLoader;
XSLoader::load('Win32API::GUID', $VERSION);

return 1;

__END__

=head1 NAME

Win32API::GUID - Perl extension for creating GUID.

=head1 SYNOPSIS

  use Win32API::GUID;
  print CreateGuid(); 

=head1 ABSTRACT

Win32API::GUID module provides very simple interface to Windows CoCreateGuid() 
function and returns a string representation of newly generated GUID.

=head1 DESCRIPTION

Win32API::GUID contains the single function CreateGuid() that returns new GUID 
every time it is called.

=head1 AUTHOR

Andrew Shitov, <andy@shitov.ru>

=head1 COPYRIGHT AND LICENSE

Win32API::GUID modude is a free software. 
You may redistribute and (or) modify it under the same terms as Perl.

=cut
