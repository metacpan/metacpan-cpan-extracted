#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
package Wetware::Test::Class::Load;

use strict;
use warnings;

use Test::Class;
use File::Find;
use File::Spec;

use Test::Class::Load qw();


sub import {
    my ( $class, @directories ) = @_;
 
   # this will filter out the CVS and .svn directories
   my $preprocess = sub {
   		my (@dirs_found) = @_;
   		my @dirs_to_use = grep {
   			$_ ne 'CVS' && $_ ne '.svn' 
   		} @dirs_found;
   		return @dirs_to_use;
   };
   
    foreach my $dir ( @directories ) {
        $dir = File::Spec->catdir( split '/', $dir );
        find(
            {   no_chdir => 1,
                wanted   => sub { Test::Class::Load::_load( $File::Find::name, $dir ) },
                 'preprocess' =>  $preprocess
            },
            $dir
        );
    }
}


1;

__END__

=head1 NAME

Wetware::Test::Class::Load - Load C<Test::Class> classes automatically.

=head1 DESCRIPTION

This changes the directories that will be checked. This way
it will not try to load and run any *.pm files in a CVS or .svn directory.

These are by default being copied from lib into blib by Module::Builder


=head1 SEE ALSO

Test::Class::Load


=cut