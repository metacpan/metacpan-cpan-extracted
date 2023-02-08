#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

# in the OPTS_CONFIG hash use $obj for function calls. The Wrapper constructor refers to your module's reference as $obj internally.

package MyModule;
use strict;
use warnings;
use POSIX qw(strftime);

use Exporter;
our @EXPORT = qw(fmt the_date get_fmt);

my $fmt='%Y-%m-%d';

sub the_date
{
my $tmp_fmt=(@_) ? shift : undef;
(defined $tmp_fmt) && ($tmp_fmt =~ s/^\s//);
((!defined($tmp_fmt)) || (!$tmp_fmt)) && ($tmp_fmt=undef);
(defined $tmp_fmt) && ($fmt=$tmp_fmt);
return strftime($fmt, localtime());
} # the_date

sub get_fmt
{
  return $fmt;
} # get_fmt

package main;

use POSIX qw(strftime);
use lib 'lib';
use Wrapper::GetoptLong;

# opt_arg_eg is opt_arg_example
# help opt will be added automatically

my %OPTS_CONFIG=(
   'the_date'      => {
      'desc'         => q^Print today's date followed by date format. Uses strftime formats.^,
      'func'         => q^MyModule::the_date("$opts{'the_date'}")^,
      'opt_arg_eg'   => 'e.g . %Y-%m-%d',
      'opt_arg_type' => 's',
   },
);

@ARGV=('-the_date', '%A %B %d, %Y');
my $wgol=new Wrapper::GetoptLong(\%OPTS_CONFIG);
$wgol->run_getopt();
my $got=$wgol->execute_opt();
my $myfmt=MyModule::get_fmt();
my $expected=strftime($myfmt, localtime());
is($got, $expected, "Test optarg $myfmt");
