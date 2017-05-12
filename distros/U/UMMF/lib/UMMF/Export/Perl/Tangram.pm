package UMMF::Export::Perl::Tangram;

use 5.6.0;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/04/06 };
our $VERSION = do { my @r = (q$Revision: 1.10 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Export::Perl::Tangram - Tangram O/R tools.

=head1 SYNOPSIS

=head1 DESCRIPTION

This package provides tools for managing Tangram persistance from UML models.

=head1 USAGE

perl -MUMMF::Export::Perl::Tangram -e 'UMMF::Export::Perl::Tangram::main(@ARGV)' <dirs-to-scan>

=head1 EXPORT

None exported.

=head1 TO DO

=over 4

=back

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/05/02

=head1 SEE ALSO

L<UMMF::Export::Perl|UMMF::Export::Perl>,
L<UMMF::Export::Perl::Tangram::Storage|UMMF::Export::Perl::Tangram::Storage>,
L<UMMF::Export::Perl::Tangram::Schema|UMMF::Export::Perl::Schema>

=head1 VERSION

$Revision: 1.10 $

=head1 METHODS

=cut

#######################################################################

use base qw(UMMF::Core::Object);

#######################################################################


use UMMF::Export::Perl::Tangram::Schema;
use UMMF::Export::Perl::Tangram::Storage;
use Carp qw(confess);

#######################################################################


#######################################################################


sub main
{
  my (@args) = @_;

  if ( $args[0] eq __PACKAGE__ ) {
    shift @args;
  }

  my $action = shift @args;
  if ( grep($action eq $_, 'deploy', 'retreat') ) {
    my $to_db;
    if ( $args[0] eq '--to-db' ) {
      $to_db = shift @args;
    }

    my $s = UMMF::Export::Perl::Tangram::Schema->new;

    # Find all packages with __tangram_schema() functions.
    my @pkg = $s->locate_schema_packages(@args && \@args);
    
    #local $" = ', ';
    #print STDERR "schema packages = @pkg\n";
    
    # Get each __tangram__schema result for each package.
    my @schema = map($s->get_package_schema($_), @pkg);
    
    # Merge all the schemas.
    my $schema = $s->merge_schema(@schema);
    
    # Prepare schema.
    $schema = $s->prepare_schema($schema);
    
    # Deploy it to DB.
    if ( $action eq 'retreat' ) {
      # $DB::single = 1;
      $s->retreat_schema($schema, $to_db);
    } else {
      # $DB::single = 1;
      $s->deploy_schema($schema, $to_db);
    }
  } else {
    confess("Unknown action: '$action'");
  }

  0;
}


#######################################################################

1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

