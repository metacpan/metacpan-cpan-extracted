#!/usr/bin/perl -w
#
#  libzvbi test
#
#  Copyright (C) 2000, 2001 Michael H. Schimek
#  Perl Port: Copyright (C) 2007 Tom Zoerner
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

# Perl $Id: explist.pl,v 1.1 2007/11/18 18:48:35 tom Exp tom $
# libzvbi #Id: explist.c,v 1.10 2006/02/10 06:25:38 mschimek Exp #

use blib;
use strict;
use Getopt::Std;
use Video::ZVBI qw(/^VBI_/);

my $check = 0;

my %TypeStr = (&VBI_OPTION_BOOL => "VBI_OPTION_BOOL",
               &VBI_OPTION_INT => "VBI_OPTION_INT",
               &VBI_OPTION_REAL => "VBI_OPTION_REAL",
               &VBI_OPTION_STRING => "VBI_OPTION_STRING",
               &VBI_OPTION_MENU => "VBI_OPTION_MENU");
# (syntax note: "&" is required here to avoid auto-quoting of the bareword before "=>")

sub INT_TYPE { return ($_[0]->{type} == VBI_OPTION_BOOL) ||
                      ($_[0]->{type} == VBI_OPTION_INT) ||
                      ($_[0]->{type} == VBI_OPTION_MENU); }

sub REAL_TYPE { return ($_[0]->{type} == VBI_OPTION_REAL); }

sub MENU_TYPE { return defined($_[0]->{menu}); }

sub BOUNDS_CHECK {
        my ($oi) = @_;

        if ($oi->{menu}) {
                die unless ($oi->{def} >= 0);
                die unless ($oi->{def} <= $oi->{max});
                die unless ($oi->{min} == 0);
                die unless ($oi->{max} > 0);
                die unless ($oi->{step} == 1);
        } else {
                die unless ($oi->{max} >= $oi->{min});
                die unless ($oi->{step} > 0);
                die unless ($oi->{def} >= $oi->{min}
                            && $oi->{def} <= $oi->{max});
        }
}

sub STRING_CHECK {
        my ($oi) = @_;

        if ($oi->{menu}) {
                die unless ($oi->{def} >= 0);
                die unless ($oi->{def} <= $oi->{max});
                die unless ($oi->{min} == 0);
                die unless ($oi->{max} > 0);
                die unless ($oi->{step} == 1);
        } else {
                die unless defined $oi->{def};
        }
}

sub keyword_check {
        my ($keyword) = @_;

        die unless defined $keyword;
        die "Invalid keyword name \"$keyword\"\n" unless $keyword =~ /^[a-zA-Z0-9_]+$/;
}

sub print_current {
        my ($oi, $current) = @_;

        if (REAL_TYPE($oi)) {
                printf("    current value=%f\n", $current);
                if (!$oi->{menu}) {
                        die unless ($current >= $oi->{min}
                               && $current <= $oi->{max});
                }
        } else {
                printf("    current value=%d\n", $current);
                if (!$oi->{menu}) {
                        die unless ($current >= $oi->{min}
                               && $current <= $oi->{max});
                }
        }
}

sub test_modified {
        my ($oi, $old, $new) = @_;

        #if ($old != $new) {
        #        die "but modified current value to $new\n";
        #}
}

sub test_set_int {
        my ($ex, $oi, $current, $value) = @_;

        printf("    try to set %d: ", $value);
        my $r = $ex->option_set($oi->{keyword}, $value);

        if ($r) {
                printf("success.");
        } else {
                printf("failed, errstr=\"%s\".", $ex->errstr());
        }

        #my $new_current = 0x54321;
        my $new_current = $ex->option_get($oi->{keyword});

        if (!defined $new_current) {
                printf("vbi_export_option_get failed, errstr==\"%s\"\n",
                       $ex->errstr());
                #if ($new_current != 0x54321) {
                #       die "but modified destination to $new_current\n";
                #}
        }

        if (!$r) {
                test_modified($oi, $current, $new_current);
        }

        $current = $new_current;
        print_current($oi, $new_current);
}

sub test_set_real {
        my ($ex, $oi, $current, $value);

        printf("    try to set %f: ", $value);
        my $r = $ex->option_set($oi->{keyword}, $value);

        if ($r) {
                printf("success.");
        } else {
                printf("failed, errstr=\"%s\".", $ex->errstr());
        }

        #my $new_current = 8192.0;
        my $new_current = $ex->option_get($oi->{keyword});
        if (!defined($new_current)) {
                printf("vbi_export_option_get failed, errstr==\"%s\"\n",
                       $ex->errstr());
                # XXX unsafe
                #if ($new_current != 8192.0) {
                #       die "but modified destination to $new_current\n";
                #}
        }

        if (!$r) {
                test_modified($oi, $current, $new_current);
        }

        $current = $new_current;
        print_current($oi, $new_current);
}

sub test_set_entry {
        my ($ex, $oi, $current, $entry) = @_;

        my $valid = (MENU_TYPE($oi)
                     && $entry >= $oi->{min}
                     && $entry <= $oi->{max});

        printf("    try to set menu entry %d: ", $entry);
        my $r0 = $ex->option_menu_set($oi->{keyword}, $entry);

        $r0 = $r0 * 2 + $valid;
        if ($r0 == 0) {
                printf("failed as expected, errstr=\"%s\".", $ex->errstr());
        } elsif ($r0 == 1) {
                printf("failed, errstr=\"%s\".", $ex->errstr());
        } elsif ($r0 == 2) {
                printf("unexpected success.");
        } else {
                printf("success.");
        }

        my $new_current = $ex->option_get($oi->{keyword});
        die $ex->errstr()."\n" unless defined $new_current;
        if ($r0 == 0 || $r0 == 1) {
                test_modified($oi, $current, $new_current);
        }

        $valid = MENU_TYPE($oi);

        #my $new_entry = 0x3333;
        my $new_entry = $ex->option_menu_get($oi->{keyword});

        my $r1 = ((defined $new_entry) ? 1:0) * 2 + $valid;
        if ($r1 == 1) {
                printf("\nvbi_export_option_menu_get failed, errstr==\"%s\"\n",
                       $ex->errstr());
        } elsif ($r1 == 2) {
                printf("\nvbi_export_option_menu_get: unexpected success.\n");
        }

        #if (($r1 == 0 || $r1 == 1) && $new_entry != 0x33333) {
        #       die "vbi_export_option_menu_get failed, ".
        #              "but modified destination to $new_current\n",
        #}

        die if ($r0 == 1 || $r0 == 2 || $r1 == 1 || $r1 == 2);

        if (($oi->{type} == VBI_OPTION_BOOL) ||
            ($oi->{type} == VBI_OPTION_INT)) {
                if (defined $oi->{menu}) {
                        die unless ($new_current == $oi->{menu}[$new_entry]);
                } else {
                        test_modified($oi, $current, $new_current);
                }
                $current = $new_current;
                print_current($oi, $new_current);

        } elsif ($oi->{type} == VBI_OPTION_REAL) {
                if (defined $oi->{menu}) {
                        # XXX unsafe
                        die unless ($new_current == $oi->{menu}[$new_entry]);
                } else {
                        test_modified($oi, $current, $new_current);
                }
                $current = $new_current;
                print_current($oi, $new_current);

        } elsif ($oi->{type} == VBI_OPTION_MENU) {
                $current = $new_current;
                print_current($oi, $new_current);

        } else {
                die;
        }
}


sub dump_option_info {
        my ($ex, $oi) = @_;
        my $val;
        my $type_str;
        my $i;

        $type_str = $TypeStr{$oi->{type}};
        die "  * Option $oi->{keyword} has invalid type $oi->{type}\n" unless defined $type_str;

        $oi->{label} = "(null)" unless defined $oi->{label};
        $oi->{tooltip} = "(null)" unless defined $oi->{tooltip};

        printf "  * type=%s keyword=%s label=\"%s\" tooltip=\"%s\"\n",
               $type_str, $oi->{keyword}, $oi->{label}, $oi->{tooltip};

        keyword_check($oi->{keyword});

        if (($oi->{type} == VBI_OPTION_BOOL) ||
            ($oi->{type} == VBI_OPTION_INT)) {
                BOUNDS_CHECK($oi);
                if (defined $oi->{menu}) {
                        printf("    %d menu entries, default=%d: ",
                               $oi->{max} - $oi->{min} + 1, $oi->{def});
                        for ($i = $oi->{min}; $i <= $oi->{max}; $i++) {
                                printf("%d%s", $oi->{menu}[$i],
                                       ($i < $oi->{max}) ? ", " : "");
                        }
                        printf("\n");
                } else {
                        printf("    default=%d, min=%d, max=%d, step=%d\n",
                               $oi->{def}, $oi->{min}, $oi->{max}, $oi->{step});
                }

                $val =  $ex->option_get($oi->{keyword});
                die $ex->errstr()."\n" unless defined $val;
                print_current($oi, $val);
                if ($check) {
                        if ($oi->{menu}) {
                                test_set_entry($ex, $oi, \$val, $oi->{min});
                                test_set_entry($ex, $oi, \$val, $oi->{max});
                                test_set_entry($ex, $oi, \$val, $oi->{min} - 1);
                                test_set_entry($ex, $oi, \$val, $oi->{max} + 1);
                                test_set_int($ex, $oi, \$val, $oi->{menu}[$oi->{min}]);
                                test_set_int($ex, $oi, \$val, $oi->{menu}[$oi->{max}]);
                                test_set_int($ex, $oi, \$val, $oi->{menu}[$oi->{min}] - 1);
                                test_set_int($ex, $oi, \$val, $oi->{menu}[$oi->{max}] + 1);
                        } else {
                                test_set_entry($ex, $oi, \$val, 0);
                                test_set_int($ex, $oi, \$val, $oi->{min});
                                test_set_int($ex, $oi, \$val, $oi->{max});
                                test_set_int($ex, $oi, \$val, $oi->{min} - 1);
                                test_set_int($ex, $oi, \$val, $oi->{max} + 1);
                        }
                }

        } elsif ($oi->{type} == VBI_OPTION_REAL) {
                BOUNDS_CHECK($oi);
                if (defined $oi->{menu}) {
                        printf("    %d menu entries, default=%d: ",
                               $oi->{max} - $oi->{min} + 1, $oi->{def});
                        for ($i = $oi->{min}; $i <= $oi->{max}; $i++) {
                                printf("%f%s", $oi->{menu}[$i],
                                       ($i < $oi->{max}) ? ", " : "");
                        }
                } else {
                        printf("    default=%f, min=%f, max=%f, step=%f\n",
                               $oi->{def}, $oi->{min}, $oi->{max}, $oi->{step});
                }
                $val = $ex->option_get($oi->{keyword});
                die $ex->errstr()."\n" unless defined $val;
                print_current($oi, $val);
                if ($check) {
                        if ($oi->{menu}) {
                                test_set_entry($ex, $oi, \$val, $oi->{min});
                                test_set_entry($ex, $oi, \$val, $oi->{max});
                                test_set_entry($ex, $oi, \$val, $oi->{min} - 1);
                                test_set_entry($ex, $oi, \$val, $oi->{max} + 1);
                                test_set_real($ex, $oi, \$val, $oi->{menu}[$oi->{min}]);
                                test_set_real($ex, $oi, \$val, $oi->{menu}[$oi->{max}]);
                                test_set_real($ex, $oi, \$val, $oi->{menu}[$oi->{min}] - 1);
                                test_set_real($ex, $oi, \$val, $oi->{menu}[$oi->{max}] + 1);
                        } else {
                                test_set_entry($ex, $oi, \$val, 0);
                                test_set_real($ex, $oi, \$val, $oi->{min});
                                test_set_real($ex, $oi, \$val, $oi->{max});
                                test_set_real($ex, $oi, \$val, $oi->{min} - 1);
                                test_set_real($ex, $oi, \$val, $oi->{max} + 1);
                        }
                }

        } elsif ($oi->{type} == VBI_OPTION_STRING) {
                if ($oi->{menu}) {
                        STRING_CHECK($oi);
                        printf("    %d menu entries, default=%d: ",
                               $oi->{max} - $oi->{min} + 1, $oi->{def});
                        for ($i = $oi->{min}; $i <= $oi->{max}; $i++) {
                                printf("%s%s", $oi->{menu}[$i],
                                       ($i < $oi->{max}) ? ", " : "");
                        }
                } else {
                        printf("    default=\"%s\"\n", $oi->{def});
                }
                $val = $ex->option_get($oi->{keyword});
                die $ex->errstr()."\n" unless defined $val;
                printf("    current value=\"%s\"\n", $val);
                if ($check) {
                        printf("    try to set \"foobar\": ");
                        if ($ex->option_set($oi->{keyword}, "foobar")) {
                                printf("success.");
                        } else {
                                printf("failed, errstr=\"%s\".", $ex->errstr());
                        }
                        $val = $ex->option_get($oi->{keyword});
                        die unless defined $val;
                        printf("    current value=\"%s\"\n", $val);
                }

        } elsif ($oi->{type} == VBI_OPTION_MENU) {
                printf("    %d menu entries, default=%d: ",
                       $oi->{max} - $oi->{min} + 1, $oi->{def});
                for ($i = $oi->{min}; $i <= $oi->{max}; $i++) {
                        die unless defined ($oi->{menu}[$i]);
                        printf("%s%s", $oi->{menu}[$i],
                               ($i < $oi->{max}) ? ", " : "");
                }
                printf("\n");
                $val = $ex->option_get($oi->{keyword});
                die $ex->errstr()."\n" unless defined $val;
                print_current($oi, $val);
                if ($check) {
                        test_set_entry($ex, $oi, \$val, $oi->{min});
                        test_set_entry($ex, $oi, \$val, $oi->{max});
                        test_set_entry($ex, $oi, \$val, $oi->{min} - 1);
                        test_set_entry($ex, $oi, \$val, $oi->{max} + 1);
                }

        } else {
                die "unknown type\n";
        }
}

sub list_options {
        my ($ex) = @_;
        my $oi;

        print "  List of options:\n";

        my $i = 0;
        while ( defined($oi = $ex->option_info_enum($i)) ) {
                die unless defined $oi->{keyword};
                die $ex->errstr()."\n" unless defined $ex->option_info_keyword($oi->{keyword});

                dump_option_info($ex, $oi);
                $i++;
        }
}

sub list_modules {
        my $xi;

        print "List of export modules:\n";

        my $i = 0;
        while ( defined($xi = Video::ZVBI::export::info_enum($i)) ) {
                die unless defined $xi->{keyword};
                die unless defined Video::ZVBI::export::info_keyword($xi->{keyword});

                $xi->{label} = "(null)" unless defined $xi->{label};
                $xi->{tooltip} = "(null)" unless defined $xi->{tooltip};
                $xi->{mime_type} = "(null)" unless defined $xi->{mime_type};
                $xi->{extension} = "(null)" unless defined $xi->{extension};

                printf "* keyword=%s label=\"%s\"\n".
                       "  tooltip=\"%s\" mime_type=%s extension=%s\n",
                       $xi->{keyword}, $xi->{label},
                       $xi->{tooltip}, $xi->{mime_type}, $xi->{extension};

                keyword_check($xi->{keyword});

                my $errstr;
                my $ex = Video::ZVBI::export::new($xi->{keyword}, $errstr);
                die "Could not open $xi->{keyword}: $errstr\n" unless defined $ex;

                die $ex->errstr()."\n" unless defined $ex->info_export();

                list_options($ex);

                undef $ex;
                $i++;
        }

        print "-- end of list --\n";
}

sub main_func {
        our($opt_c);
        getopt('c');
        if ($opt_c) {
                $check = 1;
        }
        list_modules();
}

main_func();

