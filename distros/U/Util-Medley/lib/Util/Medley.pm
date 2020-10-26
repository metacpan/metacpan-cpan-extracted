package Util::Medley;
$Util::Medley::VERSION = '0.052';
use Modern::Perl;
use Moose;

with
  'Util::Medley::Roles::Attributes::Cache',
  'Util::Medley::Roles::Attributes::Crypt',
  'Util::Medley::Roles::Attributes::DateTime',
  'Util::Medley::Roles::Attributes::File',
  'Util::Medley::Roles::Attributes::File::Zip',
  'Util::Medley::Roles::Attributes::Hostname',
  'Util::Medley::Roles::Attributes::List',
  'Util::Medley::Roles::Attributes::Logger',
  'Util::Medley::Roles::Attributes::PkgManager::RPM',
  'Util::Medley::Roles::Attributes::PkgManager::YUM',
  'Util::Medley::Roles::Attributes::Spawn',
  'Util::Medley::Roles::Attributes::String',
  'Util::Medley::Roles::Attributes::XML';

=head1 NAME

Util::Medley - A collection of commonly used utilities.

=head1 VERSION

version 0.052

=head1 SYNOPSIS

  use Util::Medley;  
  
  my $medley = Util::Medley->new;
 
  my $cache = $medley->Cache;
  my $crypt = $medley->Crypt;
  my $dt    = $medley->DateTime;
  ...
 
  OR you can create the objects directly.  Note: this module loads all
  classes in one shot.
 
  use Util::Medley;
   
  my $cache = Util::Medley::Cache->new;
  my $crypt = Util::Medley::Crypt->new;
  my $dt    = Util::Medley::DateTime->new;  
  ...
   
=head1 DESCRIPTION 

Let's face it, CPAN is huge and finding the right module to use can waste
a lot of time.  Once you find what you want, you may even have to refresh 
your memory on how to use it.  That's where Util::Medley comes in.  It is a 
collection of lightweight modules that provide a standard/consistent 
interface to commonly used modules all under one roof.

=over

=item L<Util::Medley::Cache>

=item L<Util::Medley::Crypt>

=item L<Util::Medley::DateTime>

=item L<Util::Medley::File>

=item L<Util::Medley::File::Zip>

=item L<Util::Medley::List>

=item L<Util::Medley::Logger>

=item L<Util::Medley::Spawn>

=item L<Util::Medley::String>

=item L<Util::Medley::XML>

=back

=cut

1;
