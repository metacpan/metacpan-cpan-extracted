package Test::Float::Straps;

use strict;
use vars qw($VERSION);
$VERSION = '0.26_01';

use Config;
use Test::Float::Assert;
use Test::Float::Iterator;
use Test::Float::Point;
use Test::Float::Results;

# Flags used as return values from our methods.  Just for internal 
# clarification.
my $YES   = (1==1);
my $NO    = !$YES;

=head1 NAME

Test::Float::Straps - detailed analysis of test results

=head1 SYNOPSIS

  use Test::Float::Straps;

  my $strap = Test::Float::Straps->new;

  # Various ways to interpret a test
  my $results = $strap->analyze($name, \@test_output);
  my $results = $strap->analyze_fh($name, $test_filehandle);
  my $results = $strap->analyze_file($test_file);

  # UNIMPLEMENTED
  my %total = $strap->total_results;

  # Altering the behavior of the strap  UNIMPLEMENTED
  my $verbose_output = $strap->dump_verbose();
  $strap->dump_verbose_fh($output_filehandle);


=head1 DESCRIPTION

This is a hacked up copy of the L<Test::Harness> version.
See the L<Test::Float> documentation and copyright.

=cut

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    $self->_init;

    return $self;
}

sub _init {
    my($self) = shift;

    $self->{_is_vms}   = ( $^O eq 'VMS' );
    $self->{_is_win32} = ( $^O =~ /^(MS)?Win32$/ );
    $self->{_is_macos} = ( $^O eq 'MacOS' );
}

sub analyze {
    my($self, $name, $test_output) = @_;

    my $it = Test::Float::Iterator->new($test_output);
    return $self->_analyze_iterator($name, $it);
}


# sub _analyze_iterator {
#     my($self, $name, $it) = @_;
# 
#     $self->_reset_file_state;
#     $self->{file} = $name;
# 
#     my $results = Test::Harness::Results->new;
# 
#     # Set them up here so callbacks can have them.
#     $self->{totals}{$name} = $results;
#     while( defined(my $line = $it->next) ) {
#         $self->_analyze_line($line, $results);
#         last if $self->{saw_bailout};
#     }
# 
#     $results->set_skip_all( $self->{skip_all} ) if defined $self->{skip_all};
# 
#     my $passed =
#         (($results->max == 0) && defined $results->skip_all) ||
#         ($results->max &&
#          $results->seen &&
#          $results->max == $results->seen &&
#          $results->max == $results->ok);
# 
#     $results->set_passing( $passed ? 1 : 0 );
# 
#     return $results;
# }
# 

sub _analyze_iterator {
    my($self, $name, $it) = @_;

    $self->_reset_file_state;
    $self->{file} = $name;

    my $results = Test::Float::Results->new;

    # Set them up here so callbacks can have them.
    $self->{totals}{$name} = $results;
    while( defined(my $line = $it->next) ) {
        $self->_analyze_line($line, $results);
        last if $self->{saw_bailout};
    }
    
    $results->set_skip_all( $self->{skip_all} ) if defined $self->{skip_all};

    my $passed = $results->ok;

    #    (($results->max == 0) && defined $results->skip_all) ||
    #    ($results->max &&
    #     $results->seen &&
    #     $results->max == $results->seen &&
    #     $results->max == $results->ok);

    # $results->set_passing( $passed ? 1 : 0 );

    $results->set_passing( $passed );

    return $results;
}

# sub _analyze_line {
#     my $self = shift;
#     my $line = shift;
#     my $results = shift;
# 
#     $self->{line}++;
# 
#     my $linetype;
#     my $point = Test::Harness::Point->from_test_line( $line );
#     if ( $point ) {
#         $linetype = 'test';
# 
#         $results->inc_seen;
#         $point->set_number( $self->{'next'} ) unless $point->number;
# 
#         # sometimes the 'not ' and the 'ok' are on different lines,
#         # happens often on VMS if you do:
#         #   print "not " unless $test;
#         #   print "ok $num\n";
#         if ( $self->{lone_not_line} && ($self->{lone_not_line} == $self->{line} - 1) ) {
#             $point->set_ok( 0 );
#         }
# 
#         if ( $self->{todo}{$point->number} ) {
#             $point->set_directive_type( 'todo' );
#         }
# 
#         if ( $point->is_todo ) {
#             $results->inc_todo;
#             $results->inc_bonus if $point->ok;
#         }
#         elsif ( $point->is_skip ) {
#             $results->inc_skip;
#         }
# 
#         $results->inc_ok if $point->pass;
# 
#         if ( ($point->number > 100_000) && ($point->number > ($self->{max}||100_000)) ) {
#             if ( !$self->{too_many_tests}++ ) {
#                 warn "Enormous test number seen [test ", $point->number, "]\n";
#                 warn "Can't detailize, too big.\n";
#             }
#         }
#         else {
#             my $details = {
#                 ok          => $point->pass,
#                 actual_ok   => $point->ok,
#                 name        => _def_or_blank( $point->description ),
#                 type        => _def_or_blank( $point->directive_type ),
#                 reason      => _def_or_blank( $point->directive_reason ),
#             };
# 
#             assert( defined( $details->{ok} ) && defined( $details->{actual_ok} ) );
#             $results->set_details( $point->number, $details );
#         }
#     } # test point
#     elsif ( $line =~ /^not\s+$/ ) {
#         $linetype = 'other';
#         # Sometimes the "not " and "ok" will be on separate lines on VMS.
#         # We catch this and remember we saw it.
#         $self->{lone_not_line} = $self->{line};
#     }
#     elsif ( $self->_is_header($line) ) {
#         $linetype = 'header';
# 
#         $self->{saw_header}++;
# 
#         $results->inc_max( $self->{max} );
#     }
#     elsif ( $self->_is_bail_out($line, \$self->{bailout_reason}) ) {
#         $linetype = 'bailout';
#         $self->{saw_bailout} = 1;
#     }
#     elsif (my $diagnostics = $self->_is_diagnostic_line( $line )) {
#         $linetype = 'other';
#         # XXX We can throw this away, really.
#         my $test = $results->details->[-1];
#         $test->{diagnostics} ||=  '';
#         $test->{diagnostics}  .= $diagnostics;
#     }
#     else {
#         $linetype = 'other';
#     }
# 
#     $self->callback->($self, $line, $linetype, $results) if $self->callback;
# 
#     $self->{'next'} = $point->number + 1 if $point;
# } # _analyze_line

sub _analyze_line {
    my $self = shift;
    my $line = shift;
    my $results = shift;

    $self->{line}++;

    my $linetype;
    my $point = Test::Float::Point->from_test_line( $line );
    if ( $point ) {
        $linetype = 'test';

        $results->inc_seen;
        $point->set_number( $self->{'next'} ) unless $point->number;

        # sometimes the 'not ' and the 'ok' are on different lines,
        # happens often on VMS if you do:
        #   print "not " unless $test;
        #   print "ok $num\n";
        if ( $self->{lone_not_line} && ($self->{lone_not_line} == $self->{line} - 1) ) {
            $point->set_ok( 0 );
        }

        if ( $self->{todo}{$point->number} ) {
            $point->set_directive_type( 'todo' );
        }

        if ( $point->is_todo ) {
            $results->inc_todo;
            $results->inc_bonus if $point->ok;
        }
        elsif ( $point->is_skip ) {
            $results->inc_skip;
        }

        $results->inc_ok($point->ok) if $point->pass;

        if ( ($point->number > 100_000) && ($point->number > ($self->{max}||100_000)) ) {
            if ( !$self->{too_many_tests}++ ) {
                warn "Enormous test number seen [test ", $point->number, "]\n";
                warn "Can't detailize, too big.\n";
            }
        }
        else {
            my $details = {
                ok          => $point->pass,
                actual_ok   => $point->ok,
                name        => _def_or_blank( $point->description ),
                type        => _def_or_blank( $point->directive_type ),
                reason      => _def_or_blank( $point->directive_reason ),
            };

            assert( defined( $details->{ok} ) && defined( $details->{actual_ok} ) );
            $results->set_details( $point->number, $details );
        }
    } # test point
    elsif ( $line =~ /^not\s+$/ ) {
        $linetype = 'other';
        # Sometimes the "not " and "ok" will be on separate lines on VMS.
        # We catch this and remember we saw it.
        $self->{lone_not_line} = $self->{line};
    }
    elsif ( $self->_is_header($line) ) {
        $linetype = 'header';

        $self->{saw_header}++;

        $results->inc_max( $self->{max} );
    }
    elsif ( $self->_is_bail_out($line, \$self->{bailout_reason}) ) {
        $linetype = 'bailout';
        $self->{saw_bailout} = 1;
    }
    elsif (my $diagnostics = $self->_is_diagnostic_line( $line )) {
        $linetype = 'other';
        # XXX We can throw this away, really.
        my $test = $results->details->[-1];
        $test->{diagnostics} ||=  '';
        $test->{diagnostics}  .= $diagnostics;
    }
    else {
        $linetype = 'other';
    }

    # $self->callback->($self, $line, $linetype, $results) if $self->callback;

    $self->{'next'} = $point->number + 1 if $point;
} # _analyze_line

sub _is_diagnostic_line {
    my ($self, $line) = @_;
    return if index( $line, '# Looks like you failed' ) == 0;
    $line =~ s/^#\s//;
    return $line;
}

sub analyze_fh {
    my($self, $name, $fh) = @_;

    my $it = Test::Float::Iterator->new($fh);
    return $self->_analyze_iterator($name, $it);
}

sub analyze_file {
    my($self, $file) = @_;

    unless( -e $file ) {
        $self->{error} = "$file does not exist";
        return;
    }

    unless( -r $file ) {
        $self->{error} = "$file is not readable";
        return;
    }

    local $ENV{PERL5LIB} = $self->_INC2PERL5LIB;
    if ( $Test::Float::Debug ) {
        local $^W=0; # ignore undef warnings
        print "# PERL5LIB=$ENV{PERL5LIB}\n";
    }

    # *sigh* this breaks under taint, but open -| is unportable.
    my $line = $self->_command_line($file);

    unless ( open(FILE, "$line|" )) {
        print "can't run $file. $!\n";
        return;
    }

    my $results = $self->analyze_fh($file, \*FILE);
    my $exit    = close FILE;

    $results->set_wait($?);
    if ( $? && $self->{_is_vms} ) {
        $results->set_exit($?);
    }
    else {
        $results->set_exit( _wait2exit($?) );
    }
    $results->set_passing(0) unless $? == 0;

    $self->_restore_PERL5LIB();

    return $results;
}


eval { require POSIX; &POSIX::WEXITSTATUS(0) };
if( $@ ) {
    *_wait2exit = sub { $_[0] >> 8 };
}
else {
    *_wait2exit = sub { POSIX::WEXITSTATUS($_[0]) }
}

sub _command_line {
    my $self = shift;
    my $file = shift;

    my $command =  $self->_command();
    my $switches = $self->_switches($file);

    $file = qq["$file"] if ($file =~ /\s/) && ($file !~ /^".*"$/);
    my $line = "$command $switches $file";

    return $line;
}

sub _command {
    my $self = shift;

    return $ENV{HARNESS_PERL}   if defined $ENV{HARNESS_PERL};
    #return qq["$^X"]            if $self->{_is_win32} && ($^X =~ /[^\w\.\/\\]/);
    return qq["$^X"]            if $^X =~ /\s/ and $^X !~ /^["']/;
    return $^X;
}


sub _switches {
    my($self, $file) = @_;

    my @existing_switches = $self->_cleaned_switches( $Test::Float::Switches, $ENV{HARNESS_PERL_SWITCHES} );
    my @derived_switches;

    local *TEST;
    open(TEST, $file) or print "can't open $file. $!\n";
    my $shebang = <TEST>;
    close(TEST) or print "can't close $file. $!\n";

    my $taint = ( $shebang =~ /^#!.*\bperl.*\s-\w*([Tt]+)/ );
    push( @derived_switches, "-$1" ) if $taint;

    # When taint mode is on, PERL5LIB is ignored.  So we need to put
    # all that on the command line as -Is.
    # MacPerl's putenv is broken, so it will not see PERL5LIB, tainted or not.
    if ( $taint || $self->{_is_macos} ) {
	my @inc = $self->_filtered_INC;
	push @derived_switches, map { "-I$_" } @inc;
    }

    # Quote the argument if there's any whitespace in it, or if
    # we're VMS, since VMS requires all parms quoted.  Also, don't quote
    # it if it's already quoted.
    for ( @derived_switches ) {
	$_ = qq["$_"] if ((/\s/ || $self->{_is_vms}) && !/^".*"$/ );
    }
    return join( " ", @existing_switches, @derived_switches );
}

sub _cleaned_switches {
    my $self = shift;

    local $_;

    my @switches;
    for ( @_ ) {
	my $switch = $_;
	next unless defined $switch;
	$switch =~ s/^\s+//;
	$switch =~ s/\s+$//;
	push( @switches, $switch ) if $switch ne "";
    }

    return @switches;
}

sub _INC2PERL5LIB {
    my($self) = shift;

    $self->{_old5lib} = $ENV{PERL5LIB};

    return join $Config{path_sep}, $self->_filtered_INC;
}

sub _filtered_INC {
    my($self, @inc) = @_;
    @inc = @INC unless @inc;

    if( $self->{_is_vms} ) {
	# VMS has a 255-byte limit on the length of %ENV entries, so
	# toss the ones that involve perl_root, the install location
        @inc = grep !/perl_root/i, @inc;

    }
    elsif ( $self->{_is_win32} ) {
	# Lose any trailing backslashes in the Win32 paths
	s/[\\\/+]$// foreach @inc;
    }

    my %seen;
    $seen{$_}++ foreach $self->_default_inc();
    @inc = grep !$seen{$_}++, @inc;

    return @inc;
}


{ # Without caching, _default_inc() takes a huge amount of time
    my %cache;
    sub _default_inc {
        my $self = shift;
        my $perl = $self->_command;
        $cache{$perl} ||= [do {
            local $ENV{PERL5LIB};
            my @inc =`$perl -le "print join qq[\\n], \@INC"`;
            chomp @inc;
        }];
        return @{$cache{$perl}};
    }
}


sub _restore_PERL5LIB {
    my($self) = shift;

    return unless $self->{_is_vms};

    if (defined $self->{_old5lib}) {
        $ENV{PERL5LIB} = $self->{_old5lib};
    }
}

sub _is_diagnostic {
    my($self, $line, $comment) = @_;

    if( $line =~ /^\s*\#(.*)/ ) {
        $$comment = $1;
        return $YES;
    }
    else {
        return $NO;
    }
}

# Regex for parsing a header.  Will be run with /x
my $Extra_Header_Re = <<'REGEX';
                       ^
                        (?: \s+ todo \s+ ([\d \t]+) )?      # optional todo set
                        (?: \s* \# \s* ([\w:]+\s?) (.*) )?     # optional skip with optional reason
REGEX

sub _is_header {
    my($self, $line) = @_;

    if( my($max, $extra) = $line =~ /^1\.\.(\d+)(.*)/ ) {
        $self->{max}  = $max;
        assert( $self->{max} >= 0,  'Max # of tests looks right' );

        if( defined $extra ) {
            my($todo, $skip, $reason) = $extra =~ /$Extra_Header_Re/xo;

            $self->{todo} = { map { $_ => 1 } split /\s+/, $todo } if $todo;

            if( $self->{max} == 0 ) {
                $reason = '' unless defined $skip and $skip =~ /^Skip/i;
            }

            $self->{skip_all} = $reason;
        }

        return $YES;
    }
    else {
        return $NO;
    }
}

sub _is_bail_out {
    my($self, $line, $reason) = @_;

    if( $line =~ /^Bail out!\s*(.*)/i ) {
        $$reason = $1 if $1;
        return $YES;
    }
    else {
        return $NO;
    }
}

sub _reset_file_state {
    my($self) = shift;

    delete @{$self}{qw(max skip_all todo too_many_tests)};
    $self->{line}       = 0;
    $self->{saw_header} = 0;
    $self->{saw_bailout}= 0;
    $self->{lone_not_line} = 0;
    $self->{bailout_reason} = '';
    $self->{'next'}       = 1;
}

=head1 AUTHOR

Bugs to Scott Walters C<< scott@slowass.net >>.

Michael G Schwern C<< <schwern at pobox.com> >>, Andy Lester C<< <andy at petdance.com> >>.

=head1 SEE ALSO

L<Test::Harness>

=cut

sub _def_or_blank {
    return $_[0] if defined $_[0];
    return "";
}

sub set_callback {
    my $self = shift;
    $self->{callback} = shift;
}

sub callback {
    my $self = shift;
    return $self->{callback};
}

1;
