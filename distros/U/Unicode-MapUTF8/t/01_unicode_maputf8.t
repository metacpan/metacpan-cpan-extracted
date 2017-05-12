#!/usr/bin/perl -w

use strict;
use lib ('./blib','../blib','../lib','./lib');
#use bytes;
use Unicode::MapUTF8 qw(utf8_supported_charset to_utf8 from_utf8 utf8_charset_alias);

# General info for writing test modules: 
#
# When running as 'make test' the default
# working directory is the one _above_ the 
# 't/' directory. 

my @do_tests=(1..5);

my $test_subs = { 
       1 => { -code => \&test1,                    -desc => ' eight-bit                 ' },
       2 => { -code => \&test2,                    -desc => ' unicode                   ' },
       3 => { -code => \&test3,                    -desc => ' multi-byte                ' },
       4 => { -code => \&test4,                    -desc => ' jcode                     ' },
       5 => { -code => \&test5,                    -desc => ' charset aliases           ' },
#       6 => { -code => \&big5_with_embedded_ascii, -desc => ' big5 embedded ascii       ' },
};

my @charsets = utf8_supported_charset;

print $do_tests[0],'..',$do_tests[$#do_tests],"\n";
print STDERR "\n";
my $n_failures = 0;
foreach my $test (@do_tests) {
	my $sub  = $test_subs->{$test}->{-code};
	my $desc = $test_subs->{$test}->{-desc};
	my $failure = '';
	eval { $failure = &$sub; };
	if ($@) {
		$failure = $@;
	}
	if ($failure ne '') {
		chomp $failure;
		print "not ok $test\n";
		print STDERR "    $desc - $failure\n";
		$n_failures++;
	} else {
		print "ok $test\n";
		print STDERR "    $desc - ok\n";

	}
}
print "END\n";
exit;

########################################
# Eight bit conversions                #
########################################
sub test1 {
    my $charset       = 'ISO-8859-1';
    my $source_string = 'Hello World';
    my $utf8_string   = 'Hello World';
    my $result = test_general({ -charset => $charset,
                                 -source => $source_string,
                                   -utf8 => $utf8_string,
                             });
    return $result if ($result ne '');

    $source_string = '';
    $utf8_string    = '';
    $result = test_general({ -charset => $charset,
                              -source => $source_string,
                                -utf8 => $utf8_string,
                             });
    return $result if ($result ne '');

    return '';
}

########################################
# Unicode conversions                  #
########################################

sub test2 {
    my $charset       = 'UCS2';
    my $source_string = "\x00H\x00e\x00l\x00l\x00o\x00 \x00W\x00o\x00r\x00l\x00d";
    my $utf8_string   = 'Hello World';
    my $result = test_general({ -charset => $charset,
                                 -source => $source_string,
                                   -utf8 => $utf8_string,
                             });
    return $result if ($result ne '');

    $source_string = '';
    $utf8_string    = '';
    $result = test_general({ -charset => $charset,
                              -source => $source_string,
                                -utf8 => $utf8_string,
            });
    return $result if ($result ne '');

    return '';
}

########################################
# Multibyte conversions                #
########################################
sub test3 {
    return '';
}

########################################
# Japanese (Jcode) conversions         #
########################################
sub test4 {
    my $charset       = 'euc-jp';
    my $source_string = "Hello World";
    my $utf8_string   = 'Hello World';
    my $result = test_general({ -charset => $charset,
                                 -source => $source_string,
                                   -utf8 => $utf8_string,
                             });
    return $result if ($result ne '');

    $source_string = '';
    $utf8_string   = '';
    $result = test_general({ -charset => $charset,
                              -source => $source_string,
                                -utf8 => $utf8_string,
            });
    return $result if ($result ne '');
    
    return '';
}

########################################
# Charset aliases                      #
########################################
sub test5 {
    my $charset='ISO-8859-1';
    my $alias  ='latin-1_sort_of';
    eval {
        utf8_charset_alias({ $alias => $charset });
    };
	if ($@) { return "$@" }
    eval {
        my $aliased = utf8_charset_alias($alias);
        if ((! defined $aliased) || (lc($charset) ne lc($aliased))) {
            die("Alias crosscheck for '$alias' -> '$charset' returned a *different* charset of '$aliased'");
        }
    };
	if ($@) { return "Failed to alias character set '$charset' to '$alias': $@" }

    $charset       = $alias;
    my $source_string = 'Hello World';
    my $utf8_string   = 'Hello World';
    my $result = test_general({ -charset => $charset,
                                 -source => $source_string,
                                   -utf8 => $utf8_string,
                             });
    return $result if ($result ne '');

    $source_string = '';
    $utf8_string    = '';
    $result = test_general({ -charset => $charset,
                              -source => $source_string,
                                -utf8 => $utf8_string,
                             });
    return $result if ($result ne '');

    eval {
        utf8_charset_alias({ $alias => undef });
    };
	if ($@) { return "$@" }

    $source_string = 'Hello World';
    $utf8_string   = 'Hello World';
    eval { my $result = test_general({ -charset => $charset,
                                 -source => $source_string,
                                   -utf8 => $utf8_string,
                             });
    };
    if (! defined $@) {
        return "Failed to catch use of non-aliased charset";
    }

    return '';
}

########################################
# Test Big5 with embedded ASCII        #
########################################
sub big5_with_embedded_ascii {
    my $charset       = 'big5';
   
    my @errors = ();
    {
        my $source_string = "\xa5\x40\xa5\x41\x30";
        my $utf8_string   = to_utf8({ -charset => "ucs2", -string => "\x4e\x16\x4e\x15\x00\x30"});
        my $result        = test_general({ -charset => $charset,
                                            -source => $source_string,
                                              -utf8 => $utf8_string,
                                            });
        push(@errors,$result) if ($result ne '');
    }

    {
        my $source_string = "\xa5\x40\xa5\x41\x30\xa5\x30\x41\xa5\x40";
        my $utf8_string   = to_utf8({ -charset => "ucs2", -string => "\x4e\x16\x4e\x15\x00\x30\x00\x41\x4e\x16"});
        my $result        = test_general({ -charset => $charset,
                                            -source => $source_string,
                                              -utf8 => $utf8_string,
                                            });
        push(@errors,$result) if ($result ne '');
    }
    if (0 < @errors) {
        return join('',@errors);
    }
    return '';
}

########################################
# Generalized test framework           #
########################################

sub test_general {
    my ($parms) = shift;
    my $source_charset = $parms->{-charset};
    my $source_string  = $parms->{-source};
    my $utf8_string    = $parms->{-utf8};

	eval { 
        my $result_string = to_utf8({ -string => $source_string, 
                                     -charset => $source_charset });
        if ($utf8_string ne $result_string) {
           die ('(line ' . __LINE__ . ") conversion from '$source_charset' to UTF8 resulted in unexpected output.\nExpected '" . hexout($utf8_string) . "' but got '" . hexout($result_string) . "'\n");
        }
    };
	if ($@) { return "Failed to convert UTF8 text to $source_charset:\n$@" }
	eval { 
        my $result_string = from_utf8({ '-string' => $utf8_string, 
                                       '-charset' => $source_charset,
                                       }); 
        if ($source_string ne $result_string) {
           die ("conversion from UTF8 to '$source_charset' resulted in unexpected output.\nExpected '" . hexout($source_string) . "' but got '" . hexout($result_string) . "'\n");
        }
    };
	if ($@) { return "Failed to convert '$source_charset' text to UTF8: $@" }


	eval { 
           my $result_string = from_utf8({ -string => $source_string, 
                                          -charset => $source_charset,
                                          }); 
           if ($source_string ne to_utf8({ -string => $result_string, 
                                          -charset => $source_charset })) {
                die ("input and output strings differed");
           }     
    };
	if ($@) { return "Round trip conversion of '$source_charset' to UTF8 failed: $@" }

    return '';
}

sub hexout {
    my ($string) = @_;
    $string =~ s/([\x00-\xff])/unpack("H",$1).unpack("h",$1)/egos;
    return $string;
}
