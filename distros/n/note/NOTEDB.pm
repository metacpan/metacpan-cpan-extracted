#
# this is a generic module, used by note database
# backend modules.
#
# Copyright (c) 2000-2015 T.v.Dein <tlinden@cpan.org>


package NOTEDB;

use Exporter ();
use vars qw(@ISA @EXPORT $crypt_supported);

$NOTEDB::VERSION = "1.44";

BEGIN {
    # make sure, it works, otherwise encryption
    # is not supported on this system!
    eval { require Crypt::CBC; };
    if($@) {
	$NOTEDB::crypt_supported = 0;
    }
    else {
	$NOTEDB::crypt_supported = 1;
    }
}


sub no_crypt {
    $NOTEDB::crypt_supported = 0;
}


sub use_crypt {
    my($this,$key,$method) = @_;
    my($cipher);
    if($NOTEDB::crypt_supported == 1) {
	eval {
	    $cipher = new Crypt::CBC($key, $method);
	};
	if($@) {
	  print "warning: Crypt::$method not supported by system!\n";
	  $NOTEDB::crypt_supported = 0;
	}
	else {
	    $this->{cipher} = $cipher;
	}
    }
    else{
	print "warning: Crypt::CBC not supported by system!\n";
    }
}


sub use_cache {
    #
    # this sub turns on cache support
    #
    my $this = shift;
    $this->{use_cache} = 1;
    $this->{changed}   = 1;
}

sub cache {
    #
    # store the whole db as hash
    # if use_cache is turned on
    #
    my $this = shift;
    if ($this->{use_cache}) {
	my %res = @_;
	%{$this->{cache}} = %res;
    }
}

sub unchanged {
    #
    # return true if $this->{changed} is true, this will
    # be set to true by writing subs using $this->changed().
    #
    my $this = shift;
    return 0 if(!$this->{use_cache});
    if ($this->{changed}) {
	$this->{changed} = 0;
	return 0;
    }
    else {
	print "%\n";
	return 1;
    }
}

sub changed {
    #
    # turn on $this->{changed}
    # this will be used by update or create subs.
    #
    my $this = shift;
    $this->{changed} = 1;
    return 1;
}


sub generate_search {
    #
    # get user input and create perlcode ready for eval
    #  sample input:
    # "ann.a OR eg???on AND u*do$"
    #  resulting output:
    # "$match = 1 if(/ann\.a/i or /eg...on/i and /u.*do\$/i );
    #
    my($this, $string) = @_;

    my $case = "i";

    if ($string =~ /^\/.+?\/$/) {
      return $string;
    }
    elsif (!$string) {
      return "/^/";
    }

    # we will get a / in front of the first word too!
    $string = " " . $string . " ";

    # check for apostrophs
    $string =~ s/(?<=\s)(\(??)("[^"]+"|\S+)(\)??)(?=\s)/$1 . $this->check_exact($2) . $3/ge;

    # remove odd spaces infront of and after »and« and »or«
    $string =~ s/\s\s*(AND|OR)\s\s*/ $1 /g;

    # remove odd spaces infront of »(« and after »)«
    $string =~ s/(\s*\()/\(/g;
    $string =~ s/(\)\s*)/\)/g;

    # remove first and last space so it will not masked!
    $string =~ s/^\s//;
    $string =~ s/\s$//;

    # mask spaces if not infront of or after »and« and »or«
    $string =~ s/(?<!AND)(?<!OR)(\s+?)(?!AND|OR)/'\s' x length($1)/ge;

    # add first space again
    $string = " " . $string;

    # lowercase AND and OR
    $string =~ s/(\s??OR\s??|\s??AND\s??)/\L$1\E/g;

    # surround brackets with at least one space
    $string =~ s/(?<!\\)(\)|\()/ $1 /g;

    # surround strings with slashes
    $string =~ s/(?<=\s)(\S+)/ $this->check_or($1, $case) /ge;

    # remove slashes on »and« and »or«
    $string =~ s/\/(and|or)\/$case/$1/g;

    # remove spaces inside /string/ constructs
    $string =~ s/(?<!and)(?<!or)\s*\//\//g;

    $string =~ s/\/\s*(?!and|or)/\//g;

    #my $res = qq(\$match = 1 if($string););
    return qq(\$match = 1 if($string););
    #print $res . "\n";
    #return $res;
}

sub check_or {
  #
  # surrounds string with slashes if it is not
  # »and« or »or«
  #
  my($this, $str, $case) = @_;
  if ($str =~ /^\s*(or|and)\s*$/) {
    return " $str ";
  }
  elsif ($str =~ /(?<!\\)[)(]/) {
    return $str;
  }
  else {
    return " \/$str\/$case ";
  }
}


sub check_exact {
  #
  # helper for generate_search()
  # masks special chars if string
  # not inside ""
  #
  my($this, $str) = @_;

  my %wildcards = (
		   '*' => '.*',
		   '?' => '.',
		   '[' => '[',
		   ']' => ']',
		   '+' => '\+',
		   '.' => '\.',
		   '$' => '\$',
		   '@' => '\@',
		   '/' => '\/',
		   '|' => '\|',
		   '}' => '\}',
		   '{' => '\{',
	      );

  my %escapes  = (
		  '*' => '\*',
		  '?' => '\?',
		  '[' => '[',
		  ']' => ']',
		  '+' => '\+',
		  '.' => '\.',
		  '$' => '\$',
		  '@' => '\@',
		  '(' => '\(',
		  ')' => '\)',
		  '/' => '\/',
		  '|' => '\|',
		  '}' => '\}',
		  '{' => '\{',
		 );

  # mask backslash
  $str =~ s/\\/\\\\/g;


  if ($str =~ /^"/ && $str =~ /"$/) {
    # mask bracket-constructs
      $str =~ s/(.)/$escapes{$1} || "$1"/ge;
  }
  else {
      $str =~ s/(.)/$wildcards{$1} || "$1"/ge;
  }

  $str =~ s/^"//;
  $str =~ s/"$//;

  # mask spaces
  $str =~ s/\s/\\s/g;
  return $str;
}




sub lock {
  my ($this) = @_;

  if (-e $this->{LOCKFILE}) {
    open LOCK, "<$this->{LOCKFILE}" or die "could not open $this->{LOCKFILE}: $!\n";
    my $data = <LOCK>;
    close LOCK;
    chomp $data;
    print "-- waiting for lock by $data --\n";
    print "-- remove the lockfile if you are sure: \"$this->{LOCKFILE}\" --\n";
  }

  my $timeout = 60;

  eval {
    local $SIG{ALRM} = sub { die "timeout" };
    local $SIG{INT}  = sub { die "interrupted"   };
    alarm $timeout - 2;
    while (1) {
      if (! -e $this->{LOCKFILE}) {
	umask 022;
	open LOCK, ">$this->{LOCKFILE}" or die "could not open $this->{LOCKFILE}: $!\n";
	flock LOCK, LOCK_EX;

	my $now = scalar localtime();
	print LOCK "$ENV{USER} since $now (PID: $$)\n";

	flock LOCK, LOCK_UN;
	close LOCK;
	alarm 0;
	return 0;
      }
      printf " %0d\r", $timeout;
      $timeout--;
      sleep 1;
    }
  };
  if($@) {
    if ($@ =~ /^inter/) {
      print " interrupted\n";
    }
    else {
      print $@;
      print " timeout\n";
    }
    return 1;
  }
  return 0;
}

sub unlock {
  my ($this) = @_;
  unlink $this->{LOCKFILE};
}



1;
