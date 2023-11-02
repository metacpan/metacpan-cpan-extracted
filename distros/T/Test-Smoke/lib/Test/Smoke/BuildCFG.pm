package Test::Smoke::BuildCFG;
use strict;

our $VERSION = '0.011';

use Cwd;
use File::Basename qw( dirname );
use File::Spec;
require File::Path;
use Test::Smoke::LogMixin;
use Test::Smoke::Util qw( skip_config );

my %CONFIG = (
    df_v      => 0,
    df_dfopts => '-Dusedevel',
);

=head1 NAME

Test::Smoke::BuildCFG - OO interface for handling build configurations

=head1 SYNOPSIS

    use Test::Smoke::BuildCFG;

    my $name = 'perlcurrent.cfg';
    my $bcfg = Test::Smoke::BuildCFG->new( $name );

    foreach my $config ( $bcfg->configurations ) {
        # do somthing with $config
    }

=head1 DESCRIPTION

Handle the build configurations

=head1 METHODS

=head2 Test::Smoke::BuildCFG->new( [$cfgname] )

[ Constructor | Public ]

Initialise a new object.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto ? ref $proto : $proto;

    my $config = shift;

    my %args_raw = @_ ? UNIVERSAL::isa( $_[0], 'HASH' ) ? %{ $_[0] } : @_ : ();

    my %args = map {
        ( my $key = $_ ) =~ s/^-?(.+)$/lc $1/e;
        ( $key => $args_raw{ $_ } );
    } keys %args_raw;

    my %fields = map {
        my $value = exists $args{$_} ? $args{ $_ } : $CONFIG{ "df_$_" };
        ( $_ => $value )
    } qw( v dfopts );

    my $self = bless \%fields, $class;
    $self->read_parse( $config );
}

=head2 Test::Smoke::BuildCFG->continue( $logfile[, $cfgname, %options] )

[Constructor | public]

Initialize a new object without the configurations that have already
been fully processed. If *all* configurations have been processed,
just pass the equivalent of the C<new()> method.

=cut

sub continue {
    my $proto = shift;
    my $class = ref $proto ? ref $proto : $proto;

    my $logfile = shift;

    my $self = $class->new( @_ );
    $self->{_continue} = 1;
    return $self unless $logfile && -f $logfile;

    my %seen = __get_smoked_configs( $logfile );
    my @not_seen = ();
    foreach my $config ( $self->configurations ) {
        push @not_seen, $config unless exists $seen{ "$config" } ||
                                       skip_config( $config );
    }
    return $self unless @not_seen;
    $self->{_list} = \@not_seen;
    return $self;
}

=head2 $bldcfg->verbose

[ Getter | Public]

Get verbosity.

=cut

sub verbose { $_[0]->{v} }

=head2 Test::Smoke::BuildCFG->config( $key[, $value] )

[ ClassAccessor | Public ]

C<config()> is an interface to the package lexical C<%CONFIG>,
which holds all the default values for the C<new()> arguments.

With the special key B<all_defaults> this returns a reference
to a hash holding all the default values.

=cut

sub config {
    my $dummy = shift;

    my $key = lc shift;

    if ( $key eq 'all_defaults' ) {
        my %default = map {
            my( $pass_key ) = $_ =~ /^df_(.+)/;
            ( $pass_key => $CONFIG{ $_ } );
        } grep /^df_/ => keys %CONFIG;
        return \%default;
    }

    return undef unless exists $CONFIG{ "df_$key" };

    $CONFIG{ "df_$key" } = shift if @_;

    return $CONFIG{ "df_$key" };
}

=head2 $self->read_parse( $cfgname )

C<read_parse()> reads the build configurations file and parses it.

=cut

sub read_parse {
    my $self = shift;

    $self->_read( @_ );
    $self->_parse;

    return $self;
}

=head2 $self->_read( $nameorref )

C<_read()> is a private method that handles the reading.

=over 4

=item B<Reference to a SCALAR> build configurations are in C<$$nameorref>

=item B<Reference to an ARRAY> build configurations are in C<@$nameorref>

=item B<Reference to a GLOB> build configurations are read from the filehandle

=item B<Other values> are taken as the filename for the build configurations

=back

=cut

sub _read {
    my $self = shift;
    my( $nameorref ) = @_;
    $nameorref = '' unless defined $nameorref;

    my $vmsg = "";
    local *BUILDCFG;
    if ( ref $nameorref eq 'SCALAR' ) {
        $self->{_buildcfg} = $$nameorref;
        $vmsg = "internal content";
    } elsif ( ref $nameorref eq 'ARRAY' ) {
        $self->{_buildcfg} = join "", @$nameorref;
        $vmsg = "internal content";
    } elsif ( ref $nameorref eq 'HASH' ) {
        $self->{_buildcfg} = undef;
        $self->{_list} = $nameorref->{_list};
        $vmsg = "continuing smoke";
    } elsif ( ref $nameorref eq 'GLOB' ) {
        *BUILDCFG = *$nameorref;
        $self->{_buildcfg} = do { local $/; <BUILDCFG> };
        $vmsg = "anonymous filehandle";
    } else {
        if ( $nameorref ) {
            if ( open BUILDCFG, "< $nameorref" ) {
                $self->{_buildcfg} = do { local $/; <BUILDCFG> };
                close BUILDCFG;
                $vmsg = $nameorref;
            } else {
                require Carp;
                Carp::carp("Cannot read buildconfigurations ($nameorref): $!");
                $self->{_buildcfg} = $self->default_buildcfg();
                $vmsg = "internal content";
            }
        } else { # Allow intentional default_buildcfg()
            $self->{_buildcfg} = $self->default_buildcfg();
            $vmsg = "internal content";
        }
    }
    $vmsg .= "[continue]" if $self->{_continue};
    $self->log_info("Reading build configurations from %s", $vmsg);
}

=head2 $self->_parse( )

C<_parse()> will split the build configurations file in sections.
Sections are ended with a line that begins with an equals-sign ('=').

There are two types of section

=over

=item B<buildopt-section>

=item B<policy-section>

A B<policy-section> contains a "target-option". This is a build option
that should be in the ccflags variable in the F<Policy.sh> file
(see also L<Test::Smoke::Policy>) and starts with a (forward) slash ('/').

A B<policy-section> can have only one (1) target-option.

=back

=cut

sub _parse {
    my $self = shift;

    return unless defined $self->{_buildcfg}; # || $self->{_list};

    $self->{_sections} = [ ];
    my @sections = split m/^=.*\n/m, $self->{_buildcfg};
    $self->log_debug("Found %d raw-sections", scalar @sections);

    foreach my $section ( @sections ) {
        chomp $section;
        my $index = 0;
        my %opts = map { s/^\s+$//; $_ => $index++ }
            grep !/^#/ => split /\n/, $section, -1;
        # Skip empty sections
        next if (keys %opts == 0) or (exists $opts{ "" } and keys %opts == 1);

        if (  grep m|^/.+/?$| => keys %opts ) { # Policy section
            my @targets;
            my @lines = keys %opts;
            foreach my $line ( @lines ) {
                next unless $line =~ m|^/(.+?)/?$|;

                push @targets, $1;
                delete $opts{ $line };
            }
            if ( @targets > 1 ) {
                require Carp;
                Carp::carp( "Multiple policy lines in one section:\n\t",
                            join( "\n\t", @targets ),
                            "\nWill use /$targets[0]/\n" );
            }
            push @{ $self->{_sections} },
                 { policy_target => $targets[0],
                   args => [ sort {$opts{ $a } <=> $opts{ $b }} keys %opts ] };

        } else { # Buildopt section
            push @{ $self->{_sections} },
                 [ sort {$opts{ $a } <=> $opts{ $b }} keys %opts ];
        }
    }
    # Make sure we have at least *one* section
    push @{ $self->{_sections} }, [ "" ] unless @{ $self->{_sections} };

    $self->log_debug("Left with %d parsed sections", scalar @{$self->{_sections}});
    $self->_serialize;
    $self->log_debug("Found %d (unfiltered) configurations", scalar @{$self->{_list}});
}

=head2 $self->_serialize( )

C<_serialize()> creates a list of B<Test::Smoke::BuildCFG::Config>
objects from the parsed sections.

=cut

sub _serialize {
    my $self = shift;

    my $list = [ ];
    __build_list( $list, $self->{dfopts}, [ ], @{ $self->{_sections} } );

    $self->{_list} = $list;
}

=head2 __build_list( $list, $previous_args, $policy_subst, $this_cfg, @cfgs )

Recursive sub, mainly taken from the old C<run_tests()> in F<mktest.pl>

=cut

sub __build_list {
    my( $list, $previous_args, $policy_subst, $this_cfg, @cfgs ) = @_;

    my $policy_target;
    if ( ref $this_cfg eq "HASH" ) {
        $policy_target = $this_cfg->{policy_target};
        $this_cfg      = $this_cfg->{args};
    }

    foreach my $conf ( @$this_cfg ) {
        my $config_args = $previous_args;
        $config_args .= " $conf" if length $conf;

        my @substitutions = @$policy_subst;
        push @substitutions, [ $policy_target, $conf ]
            if defined $policy_target;

        if ( @cfgs ) {
            __build_list( $list, $config_args, \@substitutions, @cfgs );
            next;
        }

        push @$list, Test::Smoke::BuildCFG::Config->new(
            $config_args, @substitutions
        );
    }
}

=head2 $buildcfg->configurations( )

Returns the list of configurations (Test::Smoke::BuildCFG::Config objects)

=cut

sub configurations {
    my $self = shift;

    @{ $self->{_list} };
}

=head2 $buildcfg->policy_targets( )

Returns a list of policytargets from the policy substitution sections

=cut

sub policy_targets {
    my $self = shift;

    return unless UNIVERSAL::isa( $self->{_sections}, "ARRAY" );

    my @targets;
    for my $section ( @{ $self->{_sections} } ) {
        next unless UNIVERSAL::isa( $section, "HASH" ) &&
                    $section->{policy_target};
        push @targets, $section->{policy_target};
    }

    return @targets;
}

=head2 as_string

Return the parsed configuration as a string.

=cut

sub as_string {
    my $self = shift;
    my @sections;
    for my $section ( @{ $self->{_sections} } ) {
        if ( UNIVERSAL::isa( $section, 'ARRAY' ) ) {
            push @sections, $section;
        } elsif ( UNIVERSAL::isa( $section, 'HASH' ) ) {
            push @sections, [
                "/$section->{policy_target}/",
                @{ $section->{args} },
            ];
        }
    }
    return join "=\n", map join( "\n", @$_, "" ) => @sections;
}

=head2 source

returns the text-source of this instance.

=cut

sub source {
    my $self = shift;

    return $self->{_buildcfg};
}

=head2 sections

returns an ARRAYREF of the sections in this instance.

=cut

sub sections {
    my $self = shift;

    return $self->{_sections};
}

=head2 __get_smoked_configs( $logfile )

Parse the logfile and return a hash(ref) of already processed
configurations.

=cut

sub __get_smoked_configs {
    my( $logfile ) = @_;

    my %conf_done = ( );
    local *LOG;
    if ( open LOG, "< $logfile" ) {
        my $conf;
        # A Configuration is done when we detect a new Configuration:
        # or the phrase "Finished smoking $patch"
        while ( <LOG> ) {
            s/^Configuration:\s*// || /^Finished smoking/ or next;
            $conf and $conf_done{ $conf }++;
            chomp; $conf = $_;
        }
        close LOG;
    }
    return wantarray ? %conf_done : \%conf_done;
}

=head2 Test::Smoke::BuildCFG->default_buildcfg()

This is a constant that returns a textversion of the default
configuration.

=cut

sub default_buildcfg() {

    return <<__EOCONFIG__;
# Test::Smoke::BuildCFG->default_buildcfg
# Check the documentation for more information
== Build all configurations with and without ithreads

-Duseithreads
== Build with and without 64bitall

-Duse64bitall
== All configurations with and without -DDEBUGGING
/-DDEBUGGING/

-DDEBUGGING
__EOCONFIG__
}

=head2 Test::Smoke::BuildCFG->os_default_buildcfg($os)

Check for C<MSWin32> or C<VMS> and return one of the three prepared configs.

=cut

sub os_default_buildcfg {
    my $self = shift;
    my ($os) = @_;

    (my $inc_name = __PACKAGE__ . ".pm") =~ s{::}{/}g;
    my $base_dir = dirname($INC{$inc_name});
    my $bcfg_file = 'perlcurrent.cfg';
    GIVEN: {
        local $_ = $os;

        /^MSWin32$/ && do { $bcfg_file = 'w32current.cfg'; last GIVEN; };
        /^VMS$/     && do { $bcfg_file = 'vmsperl.cfg'; last GIVEN; };
    }

    my $fullname = File::Spec->catfile($base_dir, $bcfg_file);
    my $content;
    if (open(my $fh, '<', $fullname)) {
        $content = do { local $/; <$fh> };
        close($fh);
    }
    else {
        warn("Cannot open($fullname): $!");
        $content = $self->default_buildcfg();
    }

    return $content;
}


=head2 new_configuration( $config )

A wrapper around C<< Test::Smoke::BuildCFG::Config->new() >> so the
object is accessible from outside this package.

=cut

sub new_configuration {
    return Test::Smoke::BuildCFG::Config->new( @_ );
}

1;

package Test::Smoke::BuildCFG::Config;

use overload
    '""'     => sub { $_[0]->[0] || "" },
    fallback => 1;

use Text::ParseWords qw( quotewords );

=head1 PACKAGE

Test::Smoke::BuildCFG::Config - OO interface for a build confiuration

=head1 SYNOPSIS

    my $bcfg = Test::Smoke::BuildCFG::Config->new( $args, $policy );

or

    my $bcfg = Test::Smoke::BuildCFG::Config->new;
    $bcfg->args( $args );
    $bcfg->policy( [ -DDEBUGGING => '-DDEBUGGING' ],
                   [ -DPERL_COPY_ON_WRITE => '' ] );

    if ( $bcfg->has_arg( '-Duseithreads' ) ) {
        # do stuff for -Duseithreads
    }

=head1 DESCRIPTION

This is a simple object that holds both the build arguments and the
policy substitutions. The build arguments are stored as a string and
the policy subtitutions are stored as a list of lists. Each substitution is
represented as a list with the two elements: the target and its substitute.

=head1 METHODS

=head2 Test::Smoke::BuildCFG::Config->new( [ $args[, \@policy_substs ]] )

Create the new object as an anonymous list.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = bless [ undef, [ ], { } ], $class;

    @_ >= 1 and $self->args( shift );
    @_ >  0 and $self->policy( @_ );

    $self;
}

=head2 $buildcfg->args( [$args] )

Accessor for the build arguments field.

=cut

sub args {
    my $self = shift;

    if ( defined $_[0] ) {
        $self->[0] = shift;
        $self->_split_args;
    }

    $self->[0];
}

=head2 $buildcfg->policy( [@substitutes] )

Accessor for the policy substitutions.

=cut

sub policy {
    my $self = shift;

    if ( @_ ) {
        my @substitutions = @_ == 1 &&  ref $_[0][0] eq 'ARRAY'
            ? @{ $_[0] } : @_;
        $self->[1] = \@substitutions;
    }

    @{ $self->[1] };
}

=head2 $self->_split_args( )

Create a hash with all the build arguments as keys.

=cut

sub _split_args {
    my $self = shift;

    my $i = 0;
    $self->[2] = {
        map { ( $_ => $i++ ) } quotewords( '\s+', 1, $self->[0] )
    };
    $self->[0] = join( " ", sort {
        $self->[2]{ $a } <=> $self->[2]{ $b }
    } keys %{ $self->[2] } ) || "";
}

=head2 $buildcfg->has_arg( $arg[,...] )

Check the build arguments hash for C<$arg>. If you specify more then one
the results will be logically ANDed!

=cut

sub has_arg {
    my $self = shift;

    my $ok = 1;
    $ok &&= exists $self->[2]{ $_ } foreach @_;
    return $ok;
}

=head2 $buildcfg->any_arg( $arg[,...] )

Check the build arguments hash for C<$arg>. If you specify more then one
the results will be logically ORed!

=cut

sub any_arg {
    my $self = shift;

    my $ok = 0;
    $ok ||= exists $self->[2]{ $_ } foreach @_;
    return $ok;
}

=head2 $buildcfg->args_eq( $args )

C<args_eq()> takes a string of config arguments and returns true if
C<$self> has exactly the same args as the C<$args> has.

There is the small matter of default_args (dfopts) kept as a Class
variable in L<Test::Smoke::BuildCFG>!

=cut

sub args_eq {
    my $self = shift;
    my $args = shift;

    my $default_args = join "|", sort {
        length($b) <=> length($a)
    } quotewords( '\s+', 1, Test::Smoke::BuildCFG->config( 'dfopts' ) );

    my %copy = map { ( $_ => undef ) }
        grep !/$default_args/ => keys %{ $self->[2] };
    my @s_args = grep !/$default_args/ => quotewords( '\s+', 1, $args );
    my @left;
    while ( my $option = pop @s_args ) {
        if ( exists $copy{ $option } ) {
            delete $copy{ $option };
        } else {
            push @left, $option;
        }
    }
    return (@left || keys %copy) ? 0 : 1;
}

=head2 $config->rm_arg( $arg[,..] )

Simply remove the argument(s) from the list and recreate the arguments
line.

=cut

sub rm_arg {
    my $self = shift;

    foreach my $arg ( @_ ) {
        exists $self->[2]{ $arg } and delete $self->[2]{ $arg };
    }
    $self->[0] = join( " ", sort {
        $self->[2]{ $a } <=> $self->[2]{ $b }
    } keys %{ $self->[2] } ) || "";
}

=head2 $config->vms

Redo the the commandline switches in a VMSish way.

=cut

sub vms {
    my $self = shift;

    return join( " ", map {
        tr/"'//d;
        s/^-//;
        qq/-"$_"/;
    } sort {
        $self->[2]{ $a } <=> $self->[2]{ $b }
    } keys %{ $self->[2] } ) || "";
}

1;

=head1 SEE ALSO

L<Test::Smoke::Smoker>, L<Test::Smoke::Syncer::Policy>

=head1 COPYRIGHT

(c) 2002-2003, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * http://www.perl.com/perl/misc/Artistic.html

=item * http://www.gnu.org/copyleft/gpl.html

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
