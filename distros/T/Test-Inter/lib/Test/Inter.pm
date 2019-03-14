package Test::Inter;
# Copyright (c) 2010-2019 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################

require 5.004;

use warnings;
use strict;
use File::Basename;
use IO::File;
use Cwd 'abs_path';

our($VERSION);
$VERSION = '1.09';

###############################################################################
# BASE METHODS
###############################################################################

sub version {
   my($self) = @_;

   return $VERSION;
}

sub new {
   my($class,@args) = @_;
   my($name,%opts);

   if (@args % 2) {
      ($name,%opts) = @args;
   } else {
      $name = $0;
      $name =~ s,^\./,,;
      %opts = @args;
   }

   # The basic structure

   my $self = {
               'name'     => $name,  # the name of the test script
               'start'    => 1,      # the first test to run
               'end'      => 0,      # the last test to end
               'plan'     => 0,      # the number of tests planned
               'abort'    => 0,      # abort on the first failed test
               'quiet'    => 0,      # if 1, no output on successes
                                     # (this should only be done when
                                     # running as an interactive script)
               'mode'     => 'test', # mode to run script in
               'width'    => 80,     # width of terminal
               'features' => {},     # a list of available features
               'use_lib'  => 'on',   # whether to run 'use lib' when loading
                                     # this module

               'skipall'  => '',     # the reason for skipping all
                                     # remaining tests

               'plandone' => 0,      # 1 if a plan is done
               'testsrun' => 0,      # 1 if any tests have been run

               'libdir'   => '',     # a directory to load modules from
               'testdir'  => '',     # the test directory
              };

   bless $self, $class;
   $main::TI_NUM = 0;

   # Handle options, environment variables, global variables

   my @opts = qw(start end testnum plan abort quiet mode width skip_all);
   my %o    = map { $_,1 } @opts;

   no strict 'refs';
   foreach my $opt (@opts) {
      if (! exists $o{$opt}) {
         $self->_die("Invalid option to new method: $opt");
      }

      my $OPT = uc("ti_$opt");

      if (exists $opts{opt}  ||
          exists $ENV{$OPT}  ||
          defined ${ "main::$OPT" }) {

         my $val;
         if (defined ${ "main::$OPT" }) {
            $val = ${ "main::$OPT" };
         } elsif (exists $ENV{$OPT}) {
            $val = $ENV{$OPT};
         } else {
            $val = $opts{$opt};
         }

         &{ "Test::Inter::$opt" }($self,$val);
      }
   }

   if ($$self{'mode'} ne 'test') {
      print "\nRunning $name...\n";
   }

   # We assume that the module is distributed in a directory with the correct
   # hierarchy.  This is:
   #      /some/path      MODDIR
   #                /t    TESTDIR
   #                /lib  LIBDIR
   # We'll find the full path to each.

   my($moddir,$testdir,$libdir);

   if (-f "$0") {
      $moddir = dirname(dirname(abs_path($0)));
   } elsif (-d "./t") {
      $moddir = dirname(abs_path('.'));
   } elsif (-d "../t") {
      $moddir = dirname(abs_path('..'));
   }
   if (-d "$moddir/t") {
      $testdir = "$moddir/t";
   }
   if (-d "$moddir/lib") {
      $libdir  = "$moddir/lib";
   }

   $$self{'moddir'}  = $moddir;
   $$self{'testdir'} = $testdir;
   $$self{'libdir'}  = $libdir;

   $self->use_lib();

   return $self;
}

sub use_lib {
   my($self,$val) = @_;
   if (defined $val) {
      $$self{'use_lib'} = $val;
      return;
   }

   if ($$self{'use_lib'} eq 'on') {
      foreach my $dir ($$self{'libdir'},$$self{'testdir'}) {
         next  if (! defined $dir);
         eval "use lib '$dir'";
      }
   }
}

sub testdir {
   my($self,$req) = @_;
   if ($req  &&  $req eq 'mod') {
      return $$self{'moddir'};
   } elsif ($req  &&  $req eq 'lib') {
      return $$self{'libdir'};
   }
   return $$self{'testdir'};
}

sub start {
   my($self,$val) = @_;
   $val = 1  if (! defined($val));
   $self->_die("start requires an integer value")  if ($val !~ /^\d+$/);
   $$self{'start'} = $val;
}

sub end {
   my($self,$val) = @_;
   $val = 0  if (! $val);
   $self->_die("end requires an integer value")  if ($val !~ /^\d+$/);
   $$self{'end'} = $val;
}

sub testnum {
   my($self,$val) = @_;
   if (! defined($val)) {
      $$self{'start'} = 1;
      $$self{'end'}   = 0;
   } else {
      $self->_die("testnum requires an integer value")  if ($val !~ /^\d+$/);
      $$self{'start'} = $$self{'end'} = $val;
   }
}

sub plan {
   my($self,$val) = @_;

   if ($$self{'plandone'}) {
      $self->_die('Plan/done_testing included twice');
   }
   $$self{'plandone'} = 1;

   $val = 0  if (! defined($val));
   $self->_die("plan requires an integer value")  if ($val !~ /^\d+$/);
   $$self{'plan'} = $val;

   if ($val != 0) {
      $self->_plan($val);
   }
}

sub done_testing {
   my($self,$val) = @_;

   if ($$self{'plandone'}) {
      $self->_die('Plan/done_testing included twice');
   }
   $$self{'plandone'} = 1;

   $val = $main::TI_NUM  if (! $val);
   $self->_die("done_testing requires an integer value")  if ($val !~ /^\d+$/);
   $self->_plan($val);

   if ($val != $main::TI_NUM) {
      $self->_die("Ran $main::TI_NUM tests, expected $val");
   }
}

sub abort {
   my($self,$val) = @_;
   $val = 0  if (! $val);
   $$self{'abort'} = $val;
}

sub quiet {
   my($self,$val) = @_;
   $val = 0  if (! $val);
   $$self{'quiet'} = $val;
}

sub mode {
   my($self,$val) = @_;
   $val = 'test'  if (! $val);
   $$self{'mode'} = $val;
}

sub width {
   my($self,$val) = @_;
   $val = 0  if (! $val);
   $$self{'width'} = $val;
}

sub skip_all {
   my($self,$reason,@features) = @_;

   if (@features) {
      my $skip = 0;
      foreach my $feature (@features) {
         if (! exists $$self{'features'}{$feature}  ||
             ! $$self{'features'}{$feature}) {
            $skip   = 1;
            $reason = "Required feature ($feature) missing"
              if (! $reason);
            last;
         }
      }
      return  if (! $skip);
   }

   if ($$self{'plandone'}  ||
       $$self{'testsrun'}) {
      $reason = 'Remaining tests skipped'  if (! $reason);
      $$self{'skipall'} = $reason;

   } else {
      $reason = 'Test script skipped'  if (! $reason);
      $self->_plan(0,$reason);
      exit 0;
   }
}

sub _die {
   my($self,$message) = @_;

   print "ERROR: $message\n";
   exit 1;
}

sub feature {
   my($self,$feature,$val) = @_;
   $$self{'features'}{$feature} = $val;
}

sub diag {
   my($self,$message) = @_;
   return  if ($$self{'quiet'} == 2);
   $self->_diag($message);
}

sub note {
   my($self,$message) = @_;
   return  if ($$self{'quiet'});
   $self->_diag($message);
}

###############################################################################
# LOAD METHODS
###############################################################################
# The routines were originally from Test::More (though they have been
# changed... some to a greater extent than others).

sub require_ok {
   my($self,$module,$mode) = @_;
   $mode = ''  if (! $mode);
   $main::TI_NUM++  unless ($mode eq 'feature');

   my $pack = caller;
   my @inc  = map { "unshift(\@INC,'$_');\n" } ($$self{'libdir'},$$self{'testdir'});

   my($desc,$code);

   if ( $module =~ /^\d+(?:\.\d+)?$/ ) {
      # A perl version check.
      $desc   = "require perl $module";
      $code   = <<REQUIRE;
require $module;
1;
REQUIRE
   } else {
      $module = qq['$module'] unless $self->_is_module_name($module);
      $desc   = "require $module";
      my $p   = "package";   # So the following do not get picked up by cpantorpm-depreq
      my $r   = "require";
      $code   = <<REQUIRE;
$p $pack;
@inc
$r $module;
1;
REQUIRE
   }

   $desc   .= ' (should not load)'  if ($mode eq 'forbid');
   $desc   .= ' (feature)'          if ($mode eq 'feature');

   my($eval_result,$eval_error) = $self->_eval($code);
   chomp($eval_error);
   my @eval_error = split(/\n/,$eval_error);
   foreach my $err (@eval_error) {
      $err =~ s/ \(\@INC contains.*//; # strip out the actual @INC values
   }

   my $ok = 1;
   if ($eval_result) {
      # Able to load the module
      if ($mode eq 'forbid') {
         $$self{'skipall'} = 'Loaded a module not supposed to be present';
         $self->_not_ok($desc);
         $self->_diag('Test required that module not be loadable')
           unless ($$self{'quiet'} == 2);
         $ok = 0;
      } elsif ($mode eq 'feature') {
         $self->feature($module,1);
         if (! $$self{'quiet'}) {
            $self->_diag($desc);
            $self->_diag("Feature available: $module");
         }
      } else {
         $self->_ok($desc);
      }

   } else {
      # Unable to load the module
      if ($mode eq 'forbid') {
         $self->_ok($desc);
      } elsif ($mode eq 'feature') {
         $self->feature($module,0);
         if (! $$self{'quiet'}) {
            $self->_diag($desc);
            $self->_diag("Feature unavailable: $module");
         }
      } else {
         $$self{'skipall'} = 'Unable to load a required module';
         $self->_not_ok($desc);
         $ok = 0;
      }
   }

   return
     if ( ($ok    &&  $$self{'quiet'})  ||
          (! $ok  &&  $$self{'quiet'} == 2) );

   foreach my $err (@eval_error) {
      $self->_diag($err);
   }
}

sub use_ok {
   my($self,@args) = @_;

   my $mode = '';
   if ($args[$#args] eq 'forbid'  ||
       $args[$#args] eq 'feature') {
      $mode = pop(@args);
   }
   $main::TI_NUM++  unless ($mode eq 'feature');

   my $pack = caller;

   my($code,$desc,$module);
   if ( @args == 1 and $args[0] =~ /^\d+(?:\.\d+)?$/ ) {
      # A perl version check.
      $desc   = "require perl $args[0]";
      $module = 'perl';
      $code   = <<USE;
use $args[0];
1;
USE

   } elsif (@args) {
      $module = shift(@args);

      if (! $self->_is_module_name($module)) {
         $self->_not_ok("use module: invalid module name: $module");
         return;
      }

      my $vers = '';
      if ( @args  and  $args[0] =~ /^\d+(?:\.\d+)?$/ ) {
         $vers = shift(@args);
      }

      my $imports = (@args ? 'qw(' . join(' ',@args) . ')' : '');
      $desc = "use $module $vers $imports";

      my @inc  = map { "unshift(\@INC,'$_');\n" } ($$self{'libdir'},$$self{'testdir'});

      my $p   = "package";   # So the following do not get picked up by cpantorpm-depreq
      $code = <<USE;
$p $pack;
@inc
use $module $vers $imports;
1;
USE

   } else {
      $self->_not_ok('use module: no module specified');
      return;
   }

   $desc   .= ' (should not load)'  if ($mode eq 'forbid');
   $desc   .= ' (feature)'          if ($mode eq 'feature');

   my($eval_result,$eval_error) = $self->_eval($code);
   chomp($eval_error);
   my @eval_error = split(/\n/,$eval_error);
   @eval_error    = grep(!/^BEGIN failed--compilation aborted/,@eval_error);
   foreach my $err (@eval_error) {
      $err =~ s/ \(\@INC contains.*//; # strip out the actual @INC values
   }

   my $ok = 1;
   if ($eval_result) {
      # Able to load the module
      if ($mode eq 'forbid') {
         $$self{'skipall'} = 'Loaded a module not supposed to be present';
         $self->_not_ok($desc);
         $self->_diag('Test required that module not be usable')
           unless ($$self{'quiet'} == 2);
         $ok = 0;
      } elsif ($mode eq 'feature') {
         $self->feature($module,1);
         if (! $$self{'quiet'}) {
            $self->_diag($desc);
            $self->_diag("Feature available: $module");
         }
      } else {
         $self->_ok($desc);
      }

   } else {
      # Unable to load the module
      if ($mode eq 'forbid') {
         $self->_ok($desc);
      } elsif ($mode eq 'feature') {
         $self->feature($module,0);
         if (! $$self{'quiet'}) {
            $self->_diag($desc);
            $self->_diag("Feature unavailable: $module");
         }
      } else {
         $$self{'skipall'} = 'Unable to load a required module';
         $self->_not_ok($desc);
         $ok = 0;
      }
   }

   return
     if ( ($ok    &&  $$self{'quiet'})  ||
          (! $ok  &&  $$self{'quiet'} == 2) );

   foreach my $err (@eval_error) {
      $self->_diag($err);
   }
}

sub _is_module_name {
   my($self,$module) = @_;

   # Module names start with a letter.
   # End with an alphanumeric.
   # The rest is an alphanumeric or ::
   $module =~ s/\b::\b//g;

   return $module =~ /^[a-zA-Z]\w*$/ ? 1 : 0;
}

sub _eval {
   my($self,$code) = @_;

   my( $sigdie, $eval_result, $eval_error );
   {
      local( $@, $!, $SIG{__DIE__} ); # isolate eval
      $eval_result = eval $code;
      $eval_error  = $@;
      $sigdie      = $SIG{__DIE__} || undef;
   }
   # make sure that $code got a chance to set $SIG{__DIE__}
   $SIG{__DIE__} = $sigdie if defined $sigdie;

   return( $eval_result, $eval_error );
}

###############################################################################
# OK/IS/ISNT METHODS
###############################################################################

sub ok {
   my($self,@args) = @_;
   $main::TI_NUM++;

   my($op,@ret) = $self->_ok_result(@args);
   my($name,@diag);
   my $ok = 1;

   if ($op eq 'skip') {
      my $reason = shift(@ret);
      $self->_skip($reason);

   } elsif ($op eq 'pass') {
      ($name,@diag) = @ret;
      $self->_ok($name);

   } else {
      ($name,@diag) = @ret;
      $self->_not_ok($name);
      $ok = 0;
   }

   return
     if ( ($ok    &&  $$self{'quiet'})  ||
          (! $ok  &&  $$self{'quiet'} == 2) );

   foreach my $diag (@diag) {
      $self->_diag($diag);
   }
}

sub _ok_result {
   my($self,@args) = @_;

   # Test if we're skipping this test

   my($skip,$reason) = $self->_skip_test();
   return ('skip',$reason)  if ($skip);

   # No args == always pass

   if (@args == 0) {
      return ('pass','Empty test');
   }

   # Get the result

   my($func,$funcargs,$result) = $self->_get_result(\@args);

   # Get name/expected

   my($name,$expected);
   if (@args == 1) {
      $name = $args[0];
   } elsif (@args == 2) {
      ($expected,$name) = @args;
   } elsif (@args > 2) {
      return(0,'','Improperly formed test: too many arguments');
   }

   # Check the result

   my($pass,@diag) = $self->_cmp_result('ok',$func,$funcargs,$result,$expected);
   return($pass,$name,@diag);
}

sub is {
   my($self,@args) = @_;
   $self->_is("is",@args);
}

sub isnt {
   my($self,@args) = @_;
   $self->_is("isnt",@args);
}

sub _is {
   my($self,$is,@args) = @_;
   $main::TI_NUM++;

   my($op,@ret) = $self->_is_result($is,@args);
   my($name,@diag);
   my $ok = 1;

   if ($op eq 'skip') {
      my $reason = shift(@ret);
      $self->_skip($reason);

   } elsif ($op eq 'pass') {
      ($name,@diag) = @ret;
      $self->_ok($name);

   } else {
      ($name,@diag) = @ret;
      $self->_not_ok($name);
      $ok = 0;
   }

   return
     if ( ($ok    &&  $$self{'quiet'})  ||
          (! $ok  &&  $$self{'quiet'} == 2) );

   foreach my $diag (@diag) {
      $self->_diag($diag);
   }
}

sub _is_result {
   my($self,$is,@args) = @_;

   # Test if we're skipping this test

   my($skip,$reason) = $self->_skip_test();
   return ('skip',$reason)  if ($skip);

   # Test args

   if (@args < 2) {
      return ('fail','','Improperly formed test: too few arguments');
   }

   my($func,$funcargs,$result) = $self->_get_result(\@args);

   my($name,$expected);
   if (@args == 1) {
      ($expected) = @args;
   } elsif (@args == 2) {
      ($expected,$name) = @args;
   } else {
      return(0,'','Improperly formed test: too many arguments');
   }

   # Check the result

   my($pass,@diag) = $self->_cmp_result($is,$func,$funcargs,$result,$expected);
   return($pass,$name,@diag);
}

# Returns $func,$args and $results. The first two are returned only if
# there is a function.
#
sub _get_result {
   my($self,$args) = @_;
   my($func,@funcargs,@result,$result);

   if (ref($$args[0]) eq 'CODE') {
      $func = shift(@$args);

      if (ref($$args[0]) eq 'ARRAY') {
         @funcargs = @{ $$args[0] };
         shift(@$args);
      }

      @result = &$func(@funcargs);
      return ($func,\@funcargs,\@result);

   } elsif (ref($$args[0]) eq 'ARRAY') {
      @result = @{ $$args[0] };
      shift(@$args);
      return ('','',\@result);

   } else {
      $result = shift(@$args);
      return ('','',$result);
   }
}

sub _cmp_result {
   my($self,$type,$func,$funcargs,$result,$expected) = @_;
   my $pass      = 0;
   my $identical = 0;
   my @diag;

   if ($type eq 'ok') {
      if (ref($result) eq 'ARRAY') {
         foreach my $ele (@$result) {
            $pass = 1  if (defined($ele));
         }

      } elsif (ref($result) eq 'HASH') {
         foreach my $key (keys %$result) {
            my $val = $$result{$key};
            $pass   = 1  if (defined($val));
         }

      } else {
         $pass = ($result ? 1 : 0);
      }

      if (! defined($expected)) {
         # If no expected result passed in, we don't test the results
         $identical = 1;
      } else {
         # Results/expected must be the same structure
         $identical = $self->_cmp_structure($result,$expected);
      }

   } else {
      $identical = $self->_cmp_structure($result,$expected);
      if ($type eq 'is') {
         $pass = $identical;
      } else {
         $pass = 1 - $identical;
      }
   }

   if (! $identical  &&  $type ne 'isnt') {
      if ($func) {
         push(@diag,"Arguments: " . $self->_stringify($funcargs));
      }
      push(@diag,   "Results  : " . $self->_stringify($result));
      push(@diag,   "Expected : " . $self->_stringify($expected))  unless ($type eq 'ok'  &&
                                                                           ! defined($result));
   }

   return (($pass ? 'pass' : 'fail'),@diag);
}

# Turn a data structure into a string (poor-man's Data::Dumper)
sub _stringify {
   my($self,$s) = @_;

   my($str)   = $self->__stringify($s);
   my($width) = $$self{'width'};
   if ($width) {
      $width -= 21;    # The leading string
      $width  = 10  if ($width < 10);
      $str = substr($str,0,$width)  if (length($str)>$width);
   }
   return $str;
}

sub __stringify {
   my($self,$s) = @_;

   if (! defined($s)) {
      return '__undef__';

   } elsif (ref($s) eq 'ARRAY') {
      my $str = '[ ';
      foreach my $val (@$s) {
         $str .= $self->__stringify($val) . ' ';
      }
      $str .= ']';
      return $str;

   } elsif (ref($s) eq 'HASH') {
      my $str = '{ ';
      foreach my $key (sort keys %$s) {
         my $key = $self->__stringify($key);
         my $val = $self->__stringify($$s{$key});
         $str .= "$key=>$val ";
      }
      $str .= '}';
      return $str;

   } elsif (ref($s)) {
      return '<' . ref($s) . '>';

   } elsif ($s eq '') {
      return "''";

   } else {
      if ($s =~ /\s/) {
         my $q       = qr/\'/;  # single quote
         my $qq      = qr/\"/;  # double quote
         if ($s !~ $q) {
            return "'$s'";
         }
         if ($s !~ $qq) {
            return '"' . $s . '"';
         }
         return "<$s>";

      } else {
         return $s;
      }
   }
}

sub _cmp_structure {
   my($self,$s1,$s2) = @_;

   return 1  if (! defined($s1)  &&  ! defined($s2)); # undef =  undef
   return 0  if (! defined($s1)  ||  ! defined($s2)); # undef != def
   return 0  if (ref($s1) ne ref($s2)); # must be same type

   if (ref($s1) eq 'ARRAY') {
      return 0  if ($#$s1 != $#$s2); # two lists must be the same length
      foreach (my $i=0; $i<=$#$s1; $i++) {
         return 0  unless $self->_cmp_structure($$s1[$i],$$s2[$i]);
      }
      return 1;

   } elsif (ref($s1) eq 'HASH') {
      my @k1 = keys %$s1;
      my @k2 = keys %$s2;
      return 0  if ($#k1 != $#k2); # two hashes must be the same length
      foreach my $key (@k1) {
         return 0  if (! exists $$s2{$key}); # keys must be the same
         return 0  unless $self->_cmp_structure($$s1{$key},$$s2{$key});
      }
      return 1;

   } elsif (ref($s1)) {
      # Two references (other than ARRAY and HASH are assumed equal.
      return 1;

   } else {
      # Two scalars are compared stringwise
      return ($s1 eq $s2);
   }
}

sub _skip_test {
   my($self) = @_;

   if ($$self{'skipall'}) {
      return (1,$$self{'skipall'});
   } elsif ( $main::TI_NUM < $$self{'start'}  ||
             ($$self{'end'}  &&  $main::TI_NUM > $$self{'end'}) ) {
      return (1,'Test not in list of tests specified to run');
   }
   return 0;
}

###############################################################################
# FILE METHOD
###############################################################################

sub file {
   my($self,$func,$input,$outputdir,$expected,$name,@args) = @_;
   $name = ""  if (! $name);

   if (! ref($func) eq 'CODE') {
      $self->_die("file method required a coderef");
   }

   my @funcargs;
   my $testdir = $$self{'testdir'};

   # Input file

   if ($input) {
      if (-r $input) {
         # Nothing

      } elsif (-r "$testdir/$input") {
         $input = "$testdir/$input";

      } else {
         $self->_die("Input file not readable: $input");
      }
      push(@funcargs,$input);
   }

   # Output file and directory

   if (! $outputdir) {
      if (-d $testdir  &&
          -w $testdir) {
         $outputdir = $testdir;
      } else {
         $outputdir = ".";
      }
   }
   if ($outputdir) {
      if (! -d $outputdir  ||
          ! -w $outputdir) {
         $self->_die("Output directory not writable: $outputdir");
      }
   }
   my $output = "$outputdir/tmp_test_inter";
   push(@funcargs,$output);

   # Expected output

   if (! $expected) {
      $self->_die("Expected output file not specified");

   } elsif (-r $expected) {
      # Nothing

   } elsif (-r "$testdir/$expected") {
      $expected = "$testdir/$expected";

   } else {
      $self->_die("Expected output file not readable: $expected");
   }

   # Create the temporary output file.

   &$func(@funcargs,@args);
   if (! -r "$output") {
      $self->_die("Output file not created");
   }

   # Test each line

   my $in = new IO::File;
   $in->open($output);
   my @out = <$in>;
   $in->close();
   chomp(@out);

   $in->open($expected);
   my @exp = <$in>;
   $in->close();
   chomp(@exp);
   unlink($output)   if (! $ENV{'TI_NOCLEAN'});

   while (@out < @exp) {
      push(@out,'');
   }
   while (@exp < @out) {
      push(@exp,'');
   }

   for (my $i=0; $i<@out; $i++) {
      my $line = $i+1;
      my $n    = ($name ? "$name : Line $line" : "Line $line");
      $self->_is('is',$out[$i],$exp[$i],$n);
   }
}

###############################################################################
# TESTS METHOD
###############################################################################

sub tests {
   my($self,%opts) = @_;

   #
   # feature => [ FEATURE, FEATURE, ... ]
   # disable => [ FEATURE, FEATURE, ... ]
   #

   my $skip = '';
   if (exists $opts{'feature'}) {
      foreach my $feature (@{ $opts{'feature'} }) {
         $skip = "Required feature unavailable: $feature", last
           if (! exists $$self{'features'}{$feature});
      }
   }
   if (exists $opts{'disable'}  &&  ! $skip) {
      foreach my $feature (@{ $opts{'disable'} }) {
         $skip = "Disabled due to feature being available: $feature", last
           if (exists $$self{'features'}{$feature});
      }
   }

   #
   # name => NAME
   # skip => REASON
   # todo => 0/1
   #

   my $name = '';
   if (exists $opts{'name'}) {
      $name = $opts{'name'};
   }

   if (exists $opts{'skip'}) {
      $skip = $opts{'skip'};
   }

   my $todo = 0;
   if (exists $opts{'todo'}) {
      $todo = $opts{'todo'};
   }

   #
   # tests    => STRING OR LISTREF
   # func     => CODEREF
   # expected => STRING OR LISTREF
   #

   # tests
   if (! exists $opts{'tests'}) {
      $self->_die("invalid test format: tests required");
   }
   my $tests = $opts{'tests'};
   my(%tests,$gotexpected);

   my($ntest,$nexp);
   if (ref($tests) eq 'ARRAY') {
      my @results = @$tests;
      $ntest      = 0;
      foreach my $result (@results) {
         $ntest++;
         $tests{$ntest}{'err'} = 0;
         if (ref($result) eq 'ARRAY') {
            $tests{$ntest}{'args'} = $result;
         } else {
            $tests{$ntest}{'args'} = [$result];
         }
      }
      $gotexpected = 0;

   } else {
      ($ntest,$gotexpected,%tests) = $self->_parse($tests);
      $nexp = $ntest  if ($gotexpected);
   }

   # expected
   if (exists $opts{'expected'}) {
      if ($gotexpected) {
         $self->_die("invalid test format: expected results included twice");
      }
      my $expected = $opts{'expected'};

      if (ref($expected) eq 'ARRAY') {
         my @exp = @$expected;
         $nexp   = 0;
         foreach my $exp (@exp) {
            $nexp++;
            if (ref($exp) eq 'ARRAY') {
               $tests{$nexp}{'expected'} = $exp;
            } else {
               $tests{$nexp}{'expected'} = [$exp];
            }
         }

      } else {
         my($g,%t);
         ($nexp,$g,%t) = $self->_parse($expected);
         if ($g) {
            $self->_die("invalid test format: expected results contain '=>'");
         }
         foreach my $t (1..$nexp) {
            $tests{$t}{'expected'} = $t{$t}{'args'};
         }
      }
      $gotexpected = 1;
   }

   if ($gotexpected  &&
       ($nexp != 1  &&  $nexp != $ntest)) {
      $self->_die("invalid test format: number expected results differs from number of tests");
   }

   # func
   my $func;
   if (exists $opts{'func'}) {
      $func = $opts{'func'};
      if (ref($func) ne 'CODE') {
         $self->_die("invalid test format: func must be a code reference");
      }
   }

   #
   # Compare results
   #

   foreach my $t (1..$ntest) {
      $main::TI_NUM++;

      if ($skip) {
         $self->_skip($skip,$name);
         next;
      }

      if ($tests{$t}{'err'}) {
         $self->_not_ok($name);
         $self->diag($tests{$t}{'err'});
         next;
      }

      my($op,@ret);

      # Test results

      if ($gotexpected) {
         # Do an 'is' test

         my @a = ('is');
         push(@a,$func)  if ($func);
         push(@a,$tests{$t}{'args'});
         push(@a,($nexp == 1 ? $tests{'1'}{'expected'}
                             : $tests{$t}{'expected'}));
         push(@a,$name);

         ($op,@ret) = $self->_is_result(@a);

      } else {
         # Do an 'ok' test

         my $result = $tests{$t}{'args'};
         if (@$result == 1) {
            $result = $$result[0];
         }
         ($op,@ret) = $self->_ok_result($result,$name);
      }

      # Print it out

      my($name,@diag);
      my $ok = 1;

      if ($op eq 'skip') {
         my $reason = shift(@ret);
         $self->_skip($reason);

      } elsif ($op eq 'pass') {
         ($name,@diag) = @ret;
         $self->_ok($name);

      } else {
         ($name,@diag) = @ret;
         $self->_not_ok($name);
         $ok = 0;
      }

      next
        if ( ($ok    &&  $$self{'quiet'})  ||
             (! $ok  &&  $$self{'quiet'} == 2) );

      foreach my $diag (@diag) {
         $self->_diag($diag);
      }
   }
}

###############################################################################
# TAP METHODS
###############################################################################

sub _diag {
   my($self,$message) = @_;
   print '#' . ' 'x10 . "$message\n";
}

sub _plan {
   my($self,$n,$reason) = @_;
   $reason = ''  if (! $reason);

   if ($$self{'mode'} eq 'test') {

      # Test mode

      if (! $n) {
         $reason = ''  if (! $reason);
         print "1..0 # Skipped $reason\n";
         return;
      }

      print "1..$n\n";

   } else {

      if (! $n) {
         print "  All tests skipped: $reason\n";
      } else {
         print "  Epected number of tests: $n\n"
           unless ($$self{'quiet'});
      }
   }
}

sub _ok {
   my($self,$name) = @_;

   $name = ''  if (! $name);
   $name =~ s/\#//;

   $$self{'testsrun'} = 1;

   return  if ($$self{'mode'} ne 'test'  &&
               $$self{'quiet'});

   print "ok $main::TI_NUM" . ' 'x(8-length($main::TI_NUM)) . "$name\n";

   if ($name =~ /^\d/  &&  $$self{'quiet'} != 2) {
      $self->_diag('It is strongly recommended that the name of a test not');
      $self->_diag('begin with a digit so it will not be confused with the');
      $self->_diag('test number.');
   }
}

sub _not_ok {
   my($self,$name) = @_;
   $name = ''  if (! $name);
   $name =~ s/\#//;

   $$self{'testsrun'} = 1;

   print "not ok $main::TI_NUM" . ' 'x(4-length($main::TI_NUM)) . "$name\n";

   if ($$self{'abort'} == 2) {
      exit 1;
   } elsif ($$self{'abort'}) {
      $$self{'skipall'} = 'Tests aborted due to failed test';
   }
}

sub _skip {
   my($self,$reason,$name) = @_;
   $name = ''  if (! $name);
   $name =~ s/\#//;

   $$self{'testsrun'} = 1;

   return  if ($$self{'mode'} ne 'test'  &&
               $$self{'quiet'});

   print "ok $main::TI_NUM" . ' 'x(8-length($main::TI_NUM)) .
     ($name ? "$name " : "") . "# SKIPPED $reason\n";
}

###############################################################################
# TEST PARSING METHODS
###############################################################################

{
   my $l;                         # current line number
   my $sp_opt  = qr/\s*/;         # optional whitespace
   my $sp      = qr/\s+/;         # required whitespace
   my $lparen  = qr/\(/;          # opening paren
   my $lbrack  = qr/\[/;          # opening brack
   my $lbrace  = qr/\{/;          # opening brace
   my $q       = qr/\'/;          # single quote
   my $qq      = qr/\"/;          # double quote
   my $token   = qr/\S+/;         # a token of non-whitespace characters
   my $min_str = qr/.*?/;         # a minimum length string
   my $results = qr/=>/;          # the string to switch to results

   # We'll also need to match delimiters and other special characters that
   # signal the end of a token. The default delimiter is just whitespace,
   # both other end-of-token regular expressions will include closing
   # parens, delimiters, etc.
   #
   # The end-of-token regexp will return a match for a special character (if
   # any) that terminates the token. If a token ends a whitespace or EOL,
   # nothing is matched.
   #
   my $eot     = qr/()(?:\s+|$)/;

   # Allowed delimiters is anything except () [] {} alphanumeric,
   # underscore, and whitespace.
   #
   my $delim   = qr/[^\'\"\(\)\[\]\{\}a-zA-Z0-9_ \t]/;

   # This takes a string which may contain a partial or complete
   # descritpion of any number of tests, and parses it.
   #
   # The string is multiline, and tests must be separated from each other
   # by one or more blank lines.  Lines starting with a pound sign (#)
   # are comments.
   #
   # A test may include arguments (or obtained results), expected results,
   # or both.
   #
   # Returns
   #    ($n,$gotboth,%tests)
   # where
   #    $n is the number of tests
   #    $gotboth is 1 if both arguments and expected results are obtained
   #    $tests{$i} is the i'th test.
   #
   sub _parse {
      my($self,$string) = @_;
      my $t       = 0;
      my $gotboth = -1;
      my %tests   = ();

      # Split on newlines
      $string = [ split(/\n/s,$string) ];

      $t      = 0;
      while (@$string) {
         my $test = $self->_next_test($string);
         last  if (! @$test);

         # All tests must contain both args/results OR only one of them.
         my ($err,$both,$args,$results) = $self->_parse_test($test);
         if ($gotboth == -1) {
            $gotboth = $both;
         } elsif ($gotboth != $both) {
            $err = "Malformed test [$l]: expected results for some tests, not others";
         }

         $t++;
         $tests{$t}{'err'}      = $err;
         $tests{$t}{'args'}     = $args;
         $tests{$t}{'expected'} = $results  if ($gotboth);
      }

      return ($t,$gotboth,%tests);
   }

   # Get all lines up to the end of lines or a blank line. Both
   # signal the end of a test.
   #
   sub _next_test {
      my($self,$list) = @_;
      my @test;
      my $started     = 0;

      while (1) {
         last  if (! @$list);
         my $line = shift(@$list);

         $line =~ s/^\s*//;
         $line =~ s/\s*$//;

         # If it's a blank line, add it to the test. If we've
         # already done test lines, then this signals the end
         # of the test. Otherwise, this is before the test,
         # so keep looking.
         if ($line eq '') {
            push(@test,$line);
            next  if (! $started);
            last;
         }

         # Comments are added to the test as a blank line.
         if ($line =~ /^#/) {
            push(@test,'');
            next;
         }

         push(@test,$line);
         $started = 1;
      }

      return []  if (! $started);
      return \@test;
   }

   # Parse an entire test. Look for arguments, =>, and expected results.
   #
   sub _parse_test {
      my($self,$test) = @_;
      my($err,$both,@args,@results);

      my $curr        = 'args';

      while (@$test) {

         last  if (! $self->_test_line($test));

         # Check for '=>'

         if ($self->_parse_begin_results($test)) {
            if ($curr eq 'args') {
               $curr = 'results';
            } else {
               return ("Malformed test [$l]: '=>' found twice");
            }
            next;
         }

         # Get the next item(s) to add.

         my($err,$match,@val) = $self->_parse_token($test,$eot);
         return ($err)  if ($err);

         if ($curr eq 'args') {
            push(@args,@val);
         } else {
            push(@results,@val);
         }
      }

      $both = ($curr eq 'results' ? 1 : 0);
      return ("",$both,\@args,\@results);
   }

   # Makes sure that the first line in the test contains
   # something. Blank lines are ignored.
   #
   sub _test_line {
      my($self,$test) = @_;

      while (@$test  &&
             (! defined($$test[0])  ||
              $$test[0] eq '')) {
         shift(@$test);
         $l++;
         next;
      }
      return 1  if (@$test);
      return 0;
   }

   # Check for '=>'.
   #
   # Return 1 if found, 0 otherwise.
   #
   sub _parse_begin_results {
      my($self,$test) = @_;

      return 1  if ($$test[0] =~ s/^ $sp_opt $results $eot //x);
      return 0;
   }

   # Gets the next item to add to the current list.
   #
   # Returns ($err,$match,@val) where $match is the character that
   # matched the end of the current element (either a delimiter,
   # closing character, or nothing if the element ends on
   # whitespace/newline).
   #
   sub _parse_token {
      my($self,$test,$EOT) = @_;

      my($err,$found,$match,@val);

      {
         last  if (! $self->_test_line($test));

         # Check for quoted

         ($err,$found,$match,@val) = $self->_parse_quoted($test,$EOT);
         last  if ($err);
         if ($found) {
            # ''  remains ''
            last;
         }

         # Check for open

         ($err,$found,$match,@val) = $self->_parse_open_close($test,$EOT,$lparen,')');
         last  if ($err);
         if ($found) {
            # ()  is an empty list
            if (@val == 1  &&  $val[0] eq '') {
               @val = ();
            }
            last;
         }

         ($err,$found,$match,@val) = $self->_parse_open_close($test,$EOT,$lbrack,']');
         last  if ($err);
         if ($found) {
            # []  is []
            if (@val == 1  &&  $val[0] eq '') {
               @val = ([]);
            } else {
               @val = ( [@val] );
            }
            last;
         }

         ($err,$found,$match,@val) = $self->_parse_open_close($test,$EOT,$lbrace,'}');
         last  if ($err);
         if ($found) {
            if (@val == 1  &&  $val[0] eq '') {
               @val = ( {} );
            } elsif (@val % 2 == 0) {
               # Even number of elements
               @val = ( {@val} );
            } elsif (! defined $val[$#val]  ||
                     $val[$#val] eq '') {
               # Odd number of elements with nothing as the
               # last element.
               pop(@val);
               @val = ( {@val} );
            } else {
               # Odd number of elements not supported for a hash
               $err = "Malformed test [$l]: hash with odd number of elements";
            }
            last;
         }

         # Check for some other token

         ($err,$found,$match,@val) = $self->_parse_simple_token($test,$EOT);
         last  if ($err);

         last;
      }

      return ($err)            if ($err);
      return ("Malformed test: unable to parse")  if (! $found);

      foreach my $v (@val) {
         $v = ''     if ($v eq '__blank__');
         $v = undef  if ($v eq '__undef__');
         $v =~ s/__nl__/\n/g  if ($v);
     }
      return (0,$match,@val)  if ($found);
      return (0,0);
   }

   ###
   ### The next few routines parse parts of the test. Each of them
   ### take as arguments:
   ###
   ###    $test    : the listref containing the unparsed portion of
   ###               the test
   ###    $EOT     : the end of a token
   ###
   ###    + other args as needed.
   ###
   ### They all return:
   ###
   ###    $err     : a string containing the error (if any)
   ###    $found   : 1 if something matched
   ###    $match   : the character which terminates the current
   ###               token signaling the start of the next token
   ###               (this will either be a delimiter, a closing
   ###               character, or nothing if the string ended on
   ###               whitespace or a newline)
   ###    @val     : the value (or values) of the token
   ###

   # Check for a quoted string
   #   'STRING'
   #   "STRING"
   # The string must be on one line, and everything up to the
   # closing quote is included (the quotes themselves are
   # stripped).
   #
   sub _parse_quoted {
      my($self,$test,$EOT) = @_;

      if ($$test[0] =~ s/^ $sp_opt $q  ($min_str) $q  $EOT//x  ||
          $$test[0] =~ s/^ $sp_opt $qq ($min_str) $qq $EOT//x) {
         return (0,1,$2,$1);

      } elsif ($$test[0] =~ /^ $sp_opt $q/x  ||
               $$test[0] =~ /^ $sp_opt $qq/x) {
         return ("Malformed test [$l]: improper quoting");
      }
      return (0,0);
   }

   # Parses an open/close section.
   #
   #   ( TOKEN TOKEN ... )
   #   (, TOKEN, TOKEN, ... )
   #
   # $open is a regular expression matching the open, $close is the
   # actual closing character.
   #
   # After the closing character must be an $EOT.
   #
   sub _parse_open_close {
      my($self,$test,$EOT,$open,$close) = @_;

      # See if there is an open

      my($del,$newEOT);
      if ($$test[0] =~ s/^ $sp_opt $open ($delim) $sp_opt //x) {
         $del     = $1;
         $newEOT  = qr/ $sp_opt ($|\Q$del\E|\Q$close\E) /x;

      } elsif ($$test[0] =~ s/^ $sp_opt $open $sp_opt //x) {
         $del     = '';
         $newEOT  = qr/ ($sp_opt $|$sp_opt \Q$close\E|$sp) /x;

      } else {
         return (0,0);
      }

      # If there was, then we need to read tokens until either:
      #    the string is all used up => error
      #    $close is found

      my($match,@val);
      while (1) {

         # Get a token. We MUST find something valid even if it is
         # an empty list followed by the closing character.
         my($e,$m,@v) = $self->_parse_token($test,$newEOT);
         return ($e)  if ($e);
         $m =~ s/^$sp//;

         # If we ended on nothing, and $del is something, then we
         # ended on a newline with no delimiter. The next line MUST
         # start with a delimiter or close character or the test is
         # invalid.

         if (! $m  &&  $del) {

            if (! $self->_test_line($test)) {
               return ("Malformed test [$l]: premature end of test");
            }

            if ($$test[0] =~ s/^ $sp_opt $newEOT //x) {
               $m = $1;
            } else {
               return ("Malformed test [$l]: unexpected token (expected '$close' or '$del')");
            }
         }

         # Figure out what value(s) were returned
         if ($m eq $close  &&  ! @v) {
            push(@val,'');
         } else {
            push(@val,@v);
         }

         last  if ($m eq $close);

      }

      # Now we need to find out what character ends this token:

      if ($$test[0] eq '') {
         # Ended at EOL
         return (0,1,'',@val);
      }
      if ($$test[0] =~ s/^ $sp_opt $EOT //x) {
         return (0,1,$1,@val);
      } else {
         return ("Malformed test [$l]: unexpected token");
      }
   }

   # Checks for a simple token.
   #
   sub _parse_simple_token {
      my($self,$test,$EOT) = @_;

      $$test[0] =~ s/^ $sp_opt (.*?) $EOT//x;
      return (0,1,$2,$1);
   }
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
