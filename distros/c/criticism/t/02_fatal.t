##############################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/criticism-1.02/t/02_fatal.t $
#    $Date: 2008-07-27 16:11:59 -0700 (Sun, 27 Jul 2008) $
#   $Author: thaljef $
# $Revision: 2622 $
##############################################################################

use strict;
use warnings;
use IO::String ();
use FindBin qw<$Bin>;
use File::Basename qw<basename>;
use File::Spec::Functions qw(catfile);
use English qw<-no_match_vars>;
use Test::More tests => 4;

#-----------------------------------------------------------------------------

# Find path to the directory with the test libs...
my $test_lib_basename = basename($PROGRAM_NAME, '.t');
my $test_lib_dirname = catfile( $Bin, "$test_lib_basename.lib");

#-----------------------------------------------------------------------------

test_with_criticism_fatal();
test_without_criticism_fatal();

#-----------------------------------------------------------------------------

sub test_with_criticism_fatal {
    my $module_path = "$test_lib_dirname/WithCriticismFatal.pm";
    my ($eval_error, $stderr_text) = require_file_and_catch_errors($module_path);

    like($eval_error, qr/compilation aborted/, 'Load fails when criticism is fatal');
    like($stderr_text, qr/Code before strictures/, 'criticism emitted warnings');
}

sub test_without_criticism_fatal {
    my $module_path = "$test_lib_dirname/WithoutCriticismFatal.pm";
    my ($eval_error, $stderr_text) = require_file_and_catch_errors($module_path);

    is($eval_error, q{}, 'Load succeeds when criticism is not fatal');
    like($stderr_text, qr/Code before strictures/, 'criticism emitted warnings');
}

#-----------------------------------------------------------------------------

sub require_file_and_catch_errors {
    my ($filename_to_require) = @_;
    my $stderr_text = q{};

    tie local *STDERR, 'IO::String';
    eval {require $filename_to_require};
    seek STDERR, 0, 0;  # Rewind fh to the beginning;
    $stderr_text = join "\n", <STDERR>;

    return ($EVAL_ERROR, $stderr_text);
}



