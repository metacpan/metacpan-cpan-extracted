
=head1 NAME

TimeFormat_MC - Module check for Time::Format test suite.

=head1 DESCRIPTION

This module provides one function, tf_module_check, which tests for the existence
(and loadability) of a Perl module without loading it in the current perl process
space.  See the script tf_modcheck.pl for a little more info.

=cut


use strict;
package TimeFormat_MC;

use parent 'Exporter';
our @EXPORT = qw(tf_module_check);

# $FindBin::Bin should be the test (t/) directory.
use FindBin;


my $mod_name_chunk = qr/[_[:alpha:]]+[_[:alnum:]]*/;
my $mod_name_re    = qr/\A $mod_name_chunk (?: :: $mod_name_chunk )* \z/x;

# Returns true if the module exists and can be loaded -- but loads it in a separate
# process, so it won't pollute this process.
sub tf_module_check
{
    my (@modules) = @_;
    foreach my $mod (@modules)
    {
        next  if $mod =~ $mod_name_re;
        die qq{Invalid module name "$mod"};
    }

    my $script_dir  = $FindBin::Bin;
    my $test_script = 'tf_modcheck.pl';
    my $perl = $^X;

    my $cmd = "$perl $script_dir/$test_script " . join ' ' => @modules;
    my $ret = `$cmd`;
    $ret =~ tr/\r\n//d;

    # For certain special cases (Date::Manip), the script can return multiple values.
    my @rv = split /\s+/, $ret;
    $_ =  ($_ eq 'yes'? 1 : 0)  for @rv;
    return $rv[0]  if @rv == 1;

    die "Multiple values returned, but tf_modcheck called in scalar context"
        unless wantarray;
    return @rv;
}

