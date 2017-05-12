package DBIx::dbMan::Extension;

use strict;

our $VERSION = '0.06';

1;

# identification: author-module-version
sub IDENTIFICATION { return "000001-000001-000006"; }

# author list:
# 000001 Milan Sorm <sorm@is4u.cz>
# 000002 Frantisek Darena <darena@mendelu.cz>
# 000003 Ales Kutin <kutin@is4u.cz>
# 000004 Ondrej 'Kepi' Kudlik <kepi@igloonet.cz>
# 000005 Tomas Klein <klein@is4u.cz>
# 999999 test user (not for redistributable)

# dbMan use only one instance from author-module with the highest version
# module 000001-000001 can't be loaded (not override IDENTIFICATION)

sub new {
	my $class = shift;
	my $obj = bless { @_ }, $class;
	return $obj;
}

sub preference { return 0; } 
# higher value, higher priority in calling
#        <0 fallback modules
#    0- 999 low priority - lowlevel (database) interface
# 1000-1999 medium priority - command parsers
# 2000-2999 high priority - preprocessors
# 3000-     super priority

sub for_version { return ('0.21',''); }

sub known_actions { return undef; }

sub init { };

sub done { };

sub menu { };

sub load_ok { return 1; };

# handle_action must set processed to 1 if done
# otherwise new handling of action in all extensions will be started
sub handle_action { 
	my ($obj,%action) = @_;
	$action{processed} = 1;
	return %action;
}
