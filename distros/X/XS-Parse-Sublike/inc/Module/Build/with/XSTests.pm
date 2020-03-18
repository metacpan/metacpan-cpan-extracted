package Module::Build::with::XSTests;

use strict;
use warnings;

use base qw( Module::Build );

# Stolen and edited from Module::Build::Base::_infer_xs_spec
sub _infer_xs_spec
{
   my $self = shift;
   my ( $file ) = @_;

   my $spec = $self->SUPER::_infer_xs_spec( $file );

   if( $file =~ m{^t/} ) {
      $spec->{$_} = File::Spec->catdir( "t", $spec->{$_} )
         for qw( archdir bs_file lib_file );
   }

   return $spec;
}

# Various bits stolen from Module::Build::Base::
#    process_xs_files()
sub ACTION_testlib
{
   my $self = shift;

   my $testxsfiles = $self->_find_file_by_type('xs', 't');

   foreach my $from ( sort keys %$testxsfiles ) {
      my $to = $testxsfiles->{$from};

      if( $to ne $from ) {
         $self->add_to_cleanup( $to );
         $self->copy_if_modified( from => $from, to => $to );
      }

      $self->process_xs( $to );
   }
}

sub ACTION_test
{
   my $self = shift;
   $self->depends_on( "testlib" );

   $self->SUPER::ACTION_test( @_ );
}

0x55AA;
