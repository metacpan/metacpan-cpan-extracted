package Ex1::Storage;

use 5.6.0;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2005/10/12 };
our $VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

#######################################################################

use UMMF::Export::Perl::Tangram::Storage;


#######################################################################

# Set callback hook for UML::__ObjectBase::__storage configuration.
Ex1::__ObjectBase->__storage_set_opts_callback(\&storage_opts);

# Hook into WCTravel::MyConfig
sub storage_opts
{
  my ($storage_opts, $storage_id) = @_;

  # $DB::single = 1;

  # Select Tangram::Schema hash definition package.
  $storage_opts->{'schema_hash_dir'} ||= 'gen/perl';
  $storage_opts->{'schema_hash_pkg'} ||= __PACKAGE__ . '::Schema';

  # Storage connection options.
  $storage_opts->{'host'} ||= $ENV{'UMMF_EX_DB_HOST'} || 'localhost';
  $storage_opts->{'db'}   ||= 'ummf_ex1';
  $storage_opts->{'user'} ||= $ENV{'UMMF_EX_DB_USER'} || 'test';
  $storage_opts->{'pass'} ||= $ENV{'UMMF_EX_DB_PASS'} || 'test';

  $storage_opts->{'debug'} ||= 1;

  $storage_opts;
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

