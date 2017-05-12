package Text::DoubleMetaphone_PP;

use 5.008007;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(double_metaphone_pp);
our $VERSION = '0.03';

use utf8;
binmode(STDOUT, ":utf8");

sub double_metaphone_pp {
    # $pm for Primary Metaphone
    my $pm;
    # $sm for Secondary Metaphone
    my $sm;
    # $c for current letter being used. 0 index of word
    my $c = 0;
    my $length = length($_[0]);
    return 0 if $length < 1;
    my $last = $length - 1;
    my $alternate = 0;
    if (substr($_[0], 0, 2) =~ /gn|kn|pn|wr|ps/i) {
        $c++;
    }
    if (substr($_[0], 0, 1) =~ /x/i) {
        $pm .= "S";
        $sm .= "S";
        $c++;
    }
    no warnings('uninitialized');
    LOOP: while (length($pm) < 4 and length($sm) < 4) {
        last LOOP if ($c >= $length);
        if (substr($_[0], $c, 1) =~ /a|ǎ|e|i|o|o|u|y/i) {
            if ($c == 0) {
                $pm .= "A";
                $sm .= "A";
                $c++;
            } elsif($c + 1 == $last and substr($_[0], $c, 2) =~ /ǎu/i) {
                $sm .= "F";
                $c += 2;
            } else {
                $c++;
            }
        } elsif (substr($_[0], $c, 1) =~ /b/i) {
            $pm .= "P";
            $sm .= "P";
            $c++;
            $c++ if substr($_[0], $c, 1) =~ /b/i;
        } elsif (substr($_[0], $c, 1) =~ /ç/i) {
            $pm .= "S";
            $sm .= "S";
            $c++;
        } elsif (substr($_[0], $c, 1) =~ /c/i) {
            if (($c > 1) and !&is_vowel($_[0], $c - 2) and
                        substr($_[0], $c - 1, 3) =~ /ach/i and
                        (substr($_[0], $c + 2, 1) !~ /i/i and
                        (substr($_[0], $c + 2, 1) !~ /e/i or
                        substr($_[0], $c - 2, 6) =~ /bacher|macher/i))) {
                $pm .= "K";
                $sm .= "K";
                $c += 2;
            } elsif ($c == 0 and substr($_[0], $c, 6) =~ /caesar/i) {
                $pm .= "S";
                $sm .= "S";
                $c += 2;
            } elsif (substr($_[0], $c, 4) =~ /chia/i) {
                $pm .= "K";
                $sm .= "K";
                $c += 2;
            } elsif (substr($_[0], $c, 2) =~ /ch/i) {
                if ($c > 0 and substr($_[0], $c, 4) =~ /chae/i) {
                    $pm .= "K";
                    $sm .= "X";
                } elsif ($c == 0 and
                                (substr($_[0], $c + 1, 5) =~ /harac|haris/i or
                                substr($_[0], $c + 1, 3) =~ /hor|hym|hia|hem/i) and
                                substr($_[0], 0, 5) !~ /chore/i) {
                    $pm .= "K";
                    $sm .= "K";
                } elsif ((substr($_[0], 0, 4) =~ /van |von /i or substr($_[0], 0, 3) =~ /sch/i)
                                or substr($_[0], $c - 2, 6) =~ /orches|archit|orchid/i
                                or substr($_[0], $c + 2, 1) =~ /t|s/i
                                or ((substr($_[0], $c - 1, 1) =~ /a|e|o|u/i or $c == 0)
                                and (substr($_[0], $c + 2, 1) =~ /l|r|n|m|b|h|f|v|w| /i
                                    or ($c + 2) > $last))) {
                    $pm .= "K";
                    $sm .= "K";
                } else {
                    if ($c > 0) {
                        if (substr($_[0], 0, 2) =~ /mc/i) {
                            $pm .= "K";
                            $sm .= "K";
                        } else {
                            $pm .= "X";
                            $sm .= "K";
                        }
                    } else {
                        $pm .= "X";
                        $sm .= "X";
                    }
                }
                $c += 2;
            } elsif (substr($_[0], $c, 2) =~ /cz/i and substr($_[0], $c -2, 4) !~ /wicz/i) {
                $pm .= "S";
                $sm .= "X";
                $c += 2;
            } elsif (substr($_[0], $c + 1, 3) =~ /cia/i) {
                $pm .= "X";
                $sm .= "X";
                $c += 3;
            } elsif (substr($_[0], $c, 2) =~ /cc/i and !($c == 1 and substr($_[0], 0, 1) =~ /m/i)) {
                if (substr($_[0], $c + 2, 1) =~ /e|h|i/i and substr($_[0], $c + 2, 2) !~ /hu/i) {
                    if (($c == 1 and substr($_[0], $c - 1, 1) =~ /a/i) or
                                substr($_[0], $c - 1, 5) =~ /uccee|ucces/i) {
                        $pm .= "KS";
                        $sm .= "KS";
                    } else {
                        $pm .= "X";
                        $sm .= "X";
                    }
                    $c += 3;
                } else {
                    $pm .= "K";
                    $sm .= "K";
                    $c += 2;
                }
            } elsif (substr($_[0], $c, 2) =~ /ck|cg|cq/i) {
                $pm .= "K";
                $sm .= "K";
                $c += 2;
            } elsif (substr($_[0], $c, 2) =~ /ci|ce|cy/i) {
                if (substr($_[0], $c, 3) =~ /cio|cie|cia/i) {
                    $pm .= "S";
                    $sm .= "X";
                } else {
                    $pm .= "S";
                    $sm .= "S";
                }
                $c += 2;
            } elsif (substr($_[0], $c + 1, 2) =~ / c| g| q/i) {
                $pm .= "K";
                $sm .= "K";
                $c += 3;
            } else {
                $pm .= "K";
                $sm .= "K";
                if (substr($_[0], $c + 1, 1) =~ /c|k|q/i and substr($_[0], $c + 1, 2) !~ /ce|ce/i) {
                    $c += 2;
                } else {
                    $c++;
                }
            }
        } elsif (substr($_[0], $c, 1) =~ /d/i) {
            if (substr($_[0], $c, 2) =~ /dg/i) {
                if (substr($_[0], $c + 2, 1) =~ /e|i|y/i) {
                    $pm .= "J";
                    $sm .= "J";
                    $c += 3;
                } else {
                    $pm .= "TK";
                    $sm .= "TK";
                    $c += 2;
                }
            } elsif (substr($_[0], $c, 2) =~ /dt|dd/i) {
                $pm .= "T";
                $sm .= "T";
                $c += 2;
            } else {
                $pm .= "T";
                $sm .= "T";
                $c++;
            }
        } elsif (substr($_[0], $c, 1) =~ /f/i) {
            if (substr($_[0], $c + 1, 1) =~ /f/i) {
                $c += 2;
            } else {
                $c++;
            }
            $pm .= "F";
            $sm .= "F";
        } elsif (substr($_[0], $c, 1) =~ /ǧ/i) {
            $c++;
        } elsif (substr($_[0], $c, 1) =~ /g/i) {
            if (substr($_[0], $c + 1, 1) =~ /h/i) {
                if ($c > 0 and !&is_vowel($_[0], $c -1)) {
                    $pm .= "K";
                    $sm .= "K";
                    $c += 2;
                } elsif ($c < 3 && $c == 0) {
                    if (substr($_[0], $c + 2, 1) =~ /i/i) {
                        $pm .= "J";
                        $sm .= "J";
                    } else {
                        $pm .= "K";
                        $sm .= "K";
                    }
                    $c += 2;
                } elsif (($c > 1 and substr($_[0], $c - 2, 1) =~ /b|d|h/i)
                                or ($c > 2 and substr($_[0], $c - 3, 1) =~ /b|d|h/i)
                                or ($c > 3 and substr($_[0], $c - 4, 1) =~ /b|h/i)) {
                    $c += 2;
                } else {
                    if ($c > 2 and substr($_[0], $c - 1, 1) =~ /u/i
                                and substr($_[0], $c - 3, 1) =~ /c|g|l|r|t/i) {
                        $pm .= "F";
                        $sm .= "F";
                    } elsif ($c > 0 and substr($_[0], $c - 1, 1) !~ /i/i) {
                        $pm .= "K";
                        $sm .= "K";
                    }
                    $c += 2;
                }
            } elsif (substr($_[0], $c + 1, 1) =~ /n/i) {
                if ($c == 1 and &is_vowel($_[0], 0) and !&slavo_germanic($_[0])) {
                    $pm .= "KN";
                    $sm .= "N";
                } elsif (substr($_[0], $c + 2, 2) !~ /ey/i
                                and substr($_[0], $c + 1, 1) !~ /y/i and !&slavo_germanic($_[0])) {
                    $pm .= "N";
                    $sm .= "KN";
                } else {
                    $pm .= "KN";
                    $sm .= "KN";
                }
                $c += 2;
            } elsif (substr($_[0], $c + 1, 2) =~ /li/i and !&slavo_germanic($_[0])) {
                $pm .= "KL";
                $sm .= "L";
                $c += 2;
            } elsif ($c == 0 and (substr($_[0], $c + 1, 1) =~ /y/i
                                    or substr($_[0], $c + 1, 2) =~ /es|ep|eb|el|ey|ib|il|in|ie|ei|er/i)) {
                $pm .= "K";
                $sm .= "J";
                $c += 2;
            } elsif ((substr($_[0], $c + 1, 2) =~ /er/i or substr($_[0], $c + 1, 1) =~ /y/i)
                            and substr($_[0], 0, 6) !~ /danger|ranger|manger/i
                            and substr($_[0], $c - 1, 1) !~ /e|i/i
                            and substr($_[0], $c - 1, 3) !~ /rgy|ogy/i) {
                $pm .= "K";
                $sm .= "J";
                $c += 2;
            } elsif (substr($_[0], $c + 1, 1) =~ /e|i|y/i or substr($_[0], $c - 1, 4) =~ /aggi|oggi/i) {
                if ((substr($_[0], 0, 4) =~ /van |von /i or substr($_[0], 0, 3) =~ /sch/i)
                            or substr($_[0], $c + 1, 2) =~ /et/i) {
                    $pm .= "K";
                    $sm .= "K";
                } elsif (substr($_[0], $c + 1, 4) =~ /^ier |^ier$/i) {
                    $pm .= "J";
                    $sm .= "J";
                } else {
                    $pm .= "J";
                    $sm .= "K";
                }
                $c += 2;
            } elsif (substr($_[0], $c + 1, 1) =~ /g/i) {
                $pm .= "K";
                $sm .= "K";
                $c += 2;
            } else {
                $pm .= "K";
                $sm .= "K";
                $c++;
            }
        } elsif (substr($_[0], $c, 1) =~ /h/i) {
            if (($c == 0 or &is_vowel($_[0], $c - 1)) and &is_vowel($_[0], $c + 1)) {
                $pm .= "H";
                $sm .= "H";
                $c += 2;
            } else {
                $c++;
            }
        } elsif (substr($_[0], $c, 1) =~ /j/i) {
            if (substr($_[0], $c, 4) =~ /jose/i or substr($_[0], 0, 4) =~ /san /i) {
                if (($c == 0 and (substr($_[0], $c + 4, 1) eq ' ' or ($c +4 > $last)))
			    or substr($_[0], 0, 4) =~ /san /i) {
                    $pm .= "H";
                    $sm .= "H";
                } else {
                    $pm .= "J";
                    $sm .= "H";
                }
                $c++;
            } elsif ($c == 0 and substr($_[0], $c, 4) !~ /jose/i) {
                $pm .= "J";
                $sm .= "A";
                if (substr($_[0], $c + 1, 1) =~ /j/i) {
                    $c += 2;
                } else {
                    $c++;
                }
            } else {
                if (&is_vowel($_[0], $c - 1) and !&slavo_germanic($_[0])
                            and (substr($_[0], $c + 1, 1) =~ /a/i or substr($_[0], $c + 1, 1) =~ /o/i)) {
                    $pm .= "J";
                    $sm .= "H";
                } else {
                    if ($c == $last) {
                        $pm .= "J";
                    } else {
                        if (substr($_[0], $c + 1, 1) !~ /l|t|k|s|n|m|b|z/i
                                    and substr($_[0], $c -1, 1) !~ /s|k|l/i) {
                            $pm .= "J";
                            $sm .= "J";
                        }
                    }
                }
                if (substr($_[0], $c + 1, 1) =~ /j/i) {
                    $c += 2;
                } else {
                    $c++;
                }
            }
        } elsif (substr($_[0], $c, 1) =~ /k/i) {
            if (substr($_[0], $c + 1, 1) =~ /k/i) {
                $c += 2;
            } else {
                $c++;
            }
            $pm .= "K";
            $sm .= "K";
        } elsif (substr($_[0], $c, 1) =~ /l/i) {
            if (substr($_[0], $c + 1, 1) =~ /l/i) {
                if (($c == $length - 3 and substr($_[0], $c - 1, 4) =~ /illo|illa|alle/i)
                            or ((substr($_[0], $last - 1, 2) =~ /as|os/i or substr($_[0], $last, 1) =~ /a|o/i)
                            and substr($_[0], $c - 1, 4) =~ /alle/i)) {
                    $pm .= "L";
                    $c += 2;
                } else {
                    $c += 2;
                    $pm .= "L";
                    $sm .= "L";
                }
            } else {
                $c++;
                $pm .= "L";
                $sm .= "L";
            }
        } elsif (substr($_[0], $c, 1) =~ /m/i) {
            if ((substr($_[0], $c - 1, 3) =~ /umb/i
                        and ($c + 1 == $last or substr($_[0], $c + 2, 2) =~ /er/i))
                        or substr($_[0], $c + 1, 1) =~ /m/i) {
                $c += 2;
            } else {
                $c++;
            }
            $pm .= "M";
            $sm .= "M";
        } elsif (substr($_[0], $c, 1) =~ /n/i) {
            if (substr($_[0], $c + 1, 1) =~ /n/i) {
                $c += 2;
            } else {
                $c++;
            }
            $pm .= "N";
            $sm .= "N";
        } elsif (substr($_[0], $c, 1) =~ /ñ/i) {
            $c++;
            $pm .= "N";
            $sm .= "N";
        } elsif (substr($_[0], $c, 1) =~ /p/i) {
            if (substr($_[0], $c + 1, 1) =~ /h/i) {
                $pm .= "F";
                $sm .= "F";
                $c += 2;
            } elsif (substr($_[0], $c + 1, 1) =~ /p|b/i) {
                $c += 2;
                $pm .= "P";
                $sm .= "P";
            } else {
                $c++;
                $pm .= "P";
                $sm .= "P";
            }
        } elsif (substr($_[0], $c, 1) =~ /q/i) {
            if (substr($_[0], $c + 1, 1) =~ /q/i) {
                $c += 2;
            } else {
                $c++;
            }
            $pm .= "K";
            $sm .= "K";
        } elsif (substr($_[0], $c, 1) =~ /r/i) {
            if ($c == $last and !&slavo_germanic($_[0]) and substr($_[0], $c - 2, 2) =~ /ie/i
                        and substr($_[0], $c - 4, 2) !~ /me|ma/i) {
                $sm .= "R";
            } else {
                $pm .= "R";
                $sm .= "R";
            }
            if (substr($_[0], $c + 1, 1) =~ /r/i) {
                $c += 2;
            } else {
                $c++;
            }
        } elsif (substr($_[0], $c, 1) =~ /ş/i) {
            $pm .= "X";
            $sm .= "X";
            $c++;
        } elsif (substr($_[0], $c, 1) =~ /s/i) {
            if (substr($_[0], $c - 1, 3) =~ /isl|ysl/i) {
                $c++;
            } elsif ($c == 0 and substr($_[0], $c, 5) =~ /sugar/i) {
                $pm .= "X";
                $sm .= "S";
                $c++;
            } elsif (substr($_[0], $c, 2) =~ /sh/i) {
                if (substr($_[0], $c + 1, 4) =~ /heim|hoek|holm|holz/i) {
                    $pm .= "S";
                    $sm .= "S";
                } else {
                    $pm .= "X";
                    $sm .= "X";
                }
                $c += 2;
            } elsif (substr($_[0], $c, 3) =~ /sio|sia/i or substr($_[0], $c, 4) =~ /sian/i) {
                if (!&slavo_germanic($_[0])) {
                    $pm .= "S";
                    $sm .= "X";
                } else {
                    $pm .= "S";
                    $sm .= "S";
                }
                $c += 3;
            } elsif (($c == 0 and substr($_[0], $c + 1, 1) =~ /m|n|l|w/i) or substr($_[0], $c + 1, 1) =~ /z/i) {
                $pm .= "S";
                $sm .= "X";
                if (substr($_[0], $c + 1, 1) =~ /z/i) {
                    $c += 2;
                } else {
                    $c++;
                }
            } elsif (substr($_[0], $c, 2) =~ /sc/i) {
                if (substr($_[0], $c + 2, 1) =~ /h/i) {
                    if (substr($_[0], $c + 3, 2) =~ /oo|er|en|uy|ed|em/i) {
                        if (substr($_[0], $c + 3, 2) =~ /er|en/i) {
                            $pm .= "X";
                            $sm .= "SK";
                        } else {
                            $pm .= "SK";
                            $sm .= "SK";
                        }
                        $c += 3;
                    } else {
                        if ($c == 0 and !&is_vowel($_[0], 3) and substr($_[0], 3, 1) !~ /w/i) {
                            $pm .= "X";
                            $sm .= "S";
                        } else {
                            $pm .= "X";
                            $sm .= "X";
                        }
                        $c += 3;
                    }
                } elsif (substr($_[0], $c + 2, 1) =~ /e|i|y/i) {
                    $pm .= "S";
                    $sm .= "S";
                    $c += 3;
                } else {
                    $pm .= "SK";
                    $sm .= "SK";
                    $c += 3;
                }
            } else {
                if ($c == $last and substr($_[0], $c - 2, 2) =~ /ai|oi/i) {
                    $sm .= "S";
                } else {
                    $pm .= "S";
                    $sm .= "S";
                }
                if (substr($_[0], $c + 1, 1) =~ /s|z/i) {
                    $c += 2;
                } else {
                    $c++;
                }
            }
        } elsif (substr($_[0], $c, 1) =~ /t/i) {
            if (substr($_[0], $c, 4) =~ /tion/i) {
                $pm .= "X";
                $sm .= "X";
                $c += 3;
            } elsif (substr($_[0], $c, 3) =~ /tia|tch/i) {
                $pm .= "X";
                $sm .= "X";
                $c += 3;
            } elsif (substr($_[0], $c, 2) =~ /th/i or substr($_[0], $c, 3) =~ /tth/i) {
                if (substr($_[0], $c + 2, 2) =~ /om|am/i or substr($_[0], 0, 4) =~ /van |von /i
                            or substr($_[0], 0, 3) =~ /sch/i) {
                    $pm .= "T";
                    $sm .= "T";
                } else {
                    $pm .= "0";
                    $sm .= "T";
                }
                $c += 2;
            } elsif (substr($_[0], $c + 1, 1) =~ /t|d/i) {
                $pm .= "T";
                $sm .= "T";
                $c += 2;
            } else {
                $pm .= "T";
                $sm .= "T";
                $c++;
            }
        } elsif (substr($_[0], $c, 1) =~ /v/i) {
            if (substr($_[0], $c + 1, 1) =~ /v/i) {
                $c += 2;
            } else {
                $c++;
            }
            $pm .= "F";
            $sm .= "F";
        } elsif (substr($_[0], $c, 1) =~ /w/i) {
            if (substr($_[0], $c, 2) =~ /wr/i ) {
                $pm .= "R";
                $sm .= "R";
                $c += 2;
            } else {
                if ($c == 0 and (&is_vowel($_[0], $c + 1) or substr($_[0], $c, 2) =~ /wh/i)) {
                    if (&is_vowel($_[0], $c + 1)) {
                        $pm .= "A";
                        $sm .= "F";
                    } else {
                        $pm .= "A";
                        $sm .= "A";
                    }
                }
                if (($c == $last and &is_vowel($_[0], $c - 1))
                            or substr($_[0], $c - 1, 5) =~ /ewski|ewsky|owski|owsky/i
                            or substr($_[0], 0, 3) =~ /sch/i) {
                    $sm .= "F";
                    $c++;
                } elsif (substr($_[0], $c, 4) =~ /wicz|witz/i) {
                    $pm .= "TS";
                    $sm .= "FX";
                    $c += 4;
                } else {
                    $c++;
                }
            }
        } elsif (substr($_[0], $c, 1) =~ /x/i) {
            if (!($c == $last
                        and (substr($_[0], $c - 3, 3) =~ /iau|eau/i or substr($_[0], $c - 2, 2) =~ /au|ou/i))) {
                $pm .= "KS";
                $sm .= "KS";
            }
            if (substr($_[0], $c + 1, 1) =~ /c|x/i) {
                $c += 2;
            } else {
                $c++;
            }
        } elsif (substr($_[0], $c, 1) =~ /z/i) {
            if (substr($_[0], $c + 1, 1) =~ /h/i) {
                $pm .= "J";
                $sm .= "J";
                $c += 2;
            } else {
                if (substr($_[0], $c + 1, 2) =~ /zo|zi|za/i
                            or (&slavo_germanic($_[0]) and $c > 0 and substr($_[0], $c - 1, 1) !~ /t/i)) {
                    $pm .= "S";
                    $sm .= "TS";
                } else {
                    $pm .= "S";
                    $sm .= "S";
                }
                if (substr($_[0], $c + 1, 1) =~ /z/i) {
                    $c += 2;
                } else {
                    $c++;
                }
            }
        } else {
            $c++;
        }
    }
    (my $primary = substr($pm, 0, 4)) =~ s/\s$//;
    (my $secondary = substr($sm, 0, 4)) =~ s/\s$//;
    return($primary, $secondary);
}

sub is_vowel {
    no warnings('uninitialized');
    if (($_[1] < 0) or($_[1] >= length($_[0]))) {
        return 0;
    } else {
        return 1 if (substr($_[0], $_[1], 1) =~ /a|e|i|o|u|y/i);
        return 0;
    }
}

sub slavo_germanic {
    if ($_[0] =~ /w|k|cz|witz/i) {
        return 1;
    } else {
        return 0;
    }
}

1;
__END__
=head1 NAME

Text::DoubleMetaphone_PP - A Phonetic Algorithm to Encode Words

=head1 SYNOPSIS

  use Text::DoubleMetaphone_PP qw ( double_metaphone_pp );
  my($code1, $code2) = double_metaphone_pp("Word");

=head1 DESCRIPTION

This module is a pure perl implimentation of a "sounds like" algorithm
based off of Lawrence Phillips' Double Metaphone method which, was published
in the June, 2000 issue of C/C++ Users Journal. The Double Metaphone algorithm
produce two encodings for each word passed to it creating a more accurate
representation of words that may be pronounced in multiple ways. For additional
information about the Double Metaphone algorithm refer to:
http:/en.wikipedia.ort/wiki/Metaphone

=head2 EXPORT



=head1 SEE ALSO

Philips, Lawrence. C/C++ Users Journal, June, 2000.
Philips, Lawrence. Computer Language, Vol. u, No. 12 (December), 1990.
aspell.net/metaphone

=head1 AUTHOR

Theodore Klepin

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Theodore Klepin E<lt>mods@emetbeshem.com<gt>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
