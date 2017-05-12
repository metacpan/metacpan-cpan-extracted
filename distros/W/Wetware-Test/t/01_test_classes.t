#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";
use Test::Class::Load "$Bin/lib";

#-------------------------------------------------------------------------------

__END__

=pod

=head1 NAME

01_test_classes.t - Load and run unit test modules based on L<Test::Class>


=head1 SYNOPSIS

  ./Build test --test_files=t/00_unit/01_test_classes.t

  prove -b t/00_unit/01_test_classes.t

=head1 DESCRIPTION

This is an implementaton of the Test::Class::Load being used
directly.

=cut
