package Util::Medley;
$Util::Medley::VERSION = '0.008';
use Modern::Perl;
use Moose;

with 'Util::Medley::Roles::Attributes::Cache';
with 'Util::Medley::Roles::Attributes::Crypt';
with 'Util::Medley::Roles::Attributes::DateTime';
with 'Util::Medley::Roles::Attributes::File';
with 'Util::Medley::Roles::Attributes::File::Zip';
with 'Util::Medley::Roles::Attributes::List';
with 'Util::Medley::Roles::Attributes::Logger';
with 'Util::Medley::Roles::Attributes::Spawn';
with 'Util::Medley::Roles::Attributes::String';
with 'Util::Medley::Roles::Attributes::XML';

=head1 NAME

Util::Medley - A collection of commonly used utilities.

=head1 VERSION

version 0.008

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

=cut


1;
