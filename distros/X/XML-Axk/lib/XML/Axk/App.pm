#!perl
package XML::Axk::App;
use XML::Axk::Base;
use XML::Axk::Core;

#BEGIN { require Exporter; $Exporter::Verbose=1; }

# Semantic versioning, packed per Perl rules.  Must always be at least one
# digit left of the decimal, and six digits right of the decimal.  For
# prerelease versions, put an underscore before the last three digits.
our $VERSION = '0.001008';

use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt);

use constant DEBUG			=> false;

# Shell exit codes
use constant EXIT_OK 		=> 0;	# success
use constant EXIT_PROC_ERR 	=> 1;	# error during processing
use constant EXIT_PARAM_ERR	=> 2;	# couldn't understand the command line

# === Command line parsing ============================================== {{{1

# Files/scripts to load, in order.  Each element is either [isfile, text]
# or {...} for pragmas.
# It is a package var so we can localize it.
our @_Sources;

my $dr_save_source = sub {
    my ($which, $text) = @_;
    push @_Sources, [$which eq 'f', $text];
}; # dr_save_source

my $dr_save_pragma = sub {
    my ($kind, $text) = @_;
    $kind = 'B' if $kind eq 'backend';
    $kind = 'L' if $kind eq 'language';

    push @_Sources, { $kind => $text };
}; # dr_save_pragma

my %CMDLINE_OPTS = (
    # hash from internal name to array reference of
    # [getopt-name, getopt-options, optional default-value]
    #   --- However, if default-value is a reference, it will be the
    #   --- destination for that value.
    # They are listed in alphabetical order by option name,
    # lowercase before upper, although the code does not require that order.

    #BACKEND => ['b', '|backend=s', $dr_save_pragma],   # TODO

    #DUMP_VARS => ['d', '|dump-variables', false],
    #DEBUG => ['D','|debug', false],
    EVAL => ['e','|source=s@', $dr_save_source],
    #RESTRICTED_EVAL => ['E','|exec=s@'],
    SCRIPT => ['f','|file=s@', $dr_save_source],
    # -F field separator?
    # -h and --help reserved
    # INPUT_FILENAME assigned by parse_command_line_into()
    #INCLUDE => ['i','|include=s@'],
    #KEEP_GOING => ['k','|keep-going',false], #not in gawk
    #LIB => ['l','|load=s@'],
    LANGUAGE => ['L','|language=s', $dr_save_pragma],
    # --man reserved
    # OUTPUT_FILENAME => ['o','|output=s', ""], # conflict with gawk
    # OPTIMIZE => ['O','|optimize'],
    #SANDBOX => ['S','|sandbox',false],
    #SOURCES reserved
    # --usage reserved
    PRINT_VERSION => ['version','', false],
    DEFS => ['v','|var=s%'],
    # -? reserved
    #
    # gawk(1) long options: --dump-variables, --exec, --gen-po, --lint,
    # --profile

    # Long-only options that are specific to axk.
    NO_INPUT => ['no-input'],   # When set, don't read any files.  This is so
                                # testing with empty inputs is easier.
    SHOW => ['show','=s@'],     # which debugging output to print.
                                # TODO make it a hash instead?
);

sub parse_command_line {
    # Takes {into=>hash ref, from=>array ref}.  Fills in the hash with the
    # values from the command line, keyed by the keys in %CMDLINE_OPTS.

    my %params = @_;
    local @_Sources;

    my $hrOptsOut = $params{into};

    # Easier syntax for checking whether optional args were provided.
    # Syntax thanks to http://www.perlmonks.org/?node_id=696592
    local *have = sub { return exists($hrOptsOut->{ $_[0] }); };

    # Set defaults so we don't have to test them with exists().
    %$hrOptsOut = (     # map getopt option name to default value
        map { $CMDLINE_OPTS{ $_ }->[0] => $CMDLINE_OPTS{ $_ }[2] }
        grep { (scalar @{$CMDLINE_OPTS{ $_ }})==3 }
        keys %CMDLINE_OPTS
    );

    # Get options
    my $opts_ok = GetOptionsFromArray(
        $params{from},                  # source array
        $hrOptsOut,                     # destination hash
        'usage|?', 'h|help', 'man',     # options we handle here
        map { $_->[0] . ($_->[1] // '') } values %CMDLINE_OPTS, # options strs
        );

    # Help, if requested
    if(!$opts_ok || have('usage') || have('h') || have('man')) {
        # Only pull in the Pod routines if we actually need them.
        require Pod::Usage;

        #require Pod::Find; # qw(pod_where);
        #my $pod_input = Pod::Find::pod_where({-inc => 1, -verbose=>1}, __PACKAGE__);
            # This takes a long time on my system.

        Pod::Usage::pod2usage(-verbose => 0, -exitval => EXIT_PARAM_ERR, -input => __FILE__) if !$opts_ok;    # unknown opt
        Pod::Usage::pod2usage(-verbose => 0, -exitval => EXIT_OK, -input => __FILE__) if have('usage');
        Pod::Usage::pod2usage(-verbose => 1, -exitval => EXIT_OK, -input => __FILE__) if have('h');
        Pod::Usage::pod2usage(-verbose => 2, -exitval => EXIT_OK, -input => __FILE__) if have('man');
    }

    # Map the option names from GetOptions back to the internal names we use,
    # e.g., $hrOptsOut->{EVAL} from $hrOptsOut->{e}.
    my %revmap = map { $CMDLINE_OPTS{$_}->[0] => $_ } keys %CMDLINE_OPTS;
    for my $optname (keys %$hrOptsOut) {
        $hrOptsOut->{ $revmap{$optname} } = $hrOptsOut->{ $optname };
    }

    # Process other arguments.  TODO? support multiple input filenames?
    #$hrOptsOut->{INPUT_FILENAME} = $ARGV[0] // "";

    $hrOptsOut->{SOURCES} = \@_Sources;     # our local copy

} #parse_command_line()

# }}}1
# === Command-line runner =============================================== {{{1

# Command-line runner.  Call as XML::Axk::App::Main(\@ARGV).
sub Main {
    my $lrArgs = shift or croak "No arguments - need at least a script";

    my %opts;
    parse_command_line(from => $lrArgs, into => \%opts);

    if($opts{PRINT_VERSION}) {
        $VERSION =~ m<^([^\.]+)\.(\d{3})(_?)(\d{3})>;
        printf "axk version %d.%d.%d ($VERSION)%s\n", $1, $2, $4,
                ($3 ? ' (dev)' : '');

        return 0;
    }

    # Treat the first non-option arg as a script file if it exists
    # and is readable, otherwise as axk source.
    unless(@{$opts{SOURCES}}) {
        die "No scripts to run" unless @$lrArgs;
        my $option = shift @$lrArgs;
        push @{$opts{SOURCES}}, [
            -r $option && (-f $option || -l $option),
            $option
        ];
    }

    my $core = XML::Axk::Core->new(\%opts);
        # Note: core doesn't copy the provided options, so make sure
        # they stick around as long as $core does.

    my $cmd_line_idx = 0;   # Number the `-e`s on the command line
    my $curr_lang = undef;  # current -L, if any.
    #my $curr_backend = undef;  # to do

    foreach my $rItem (@{$opts{SOURCES}}) {

        if(ref $rItem eq 'ARRAY') {     # source file or text
            my $lrSource = $rItem;
            my ($is_file, $text) = @$lrSource;

            if($is_file) {
                $core->load_script_file(filename => $text,
                    $curr_lang ? (language => $curr_lang) : ()
                );

            } else {
                $core->load_script_text(text => $text,
                    filename => "(cmd line script #@{[++$cmd_line_idx]})",
                    $curr_lang ? (language => $curr_lang) :
                        (auto_language => true)
                        # true => add a Ln if there isn't one in the script
                );
            }

        } else {                        # pragma
            my $hrPragma = $rItem;

            if(exists $hrPragma->{L}) {
                $curr_lang = $hrPragma->{L};
                #say "# Language is now $curr_lang"
            }

            if(exists $hrPragma->{B}) {
                die 'Backend selection is not yet supported';
            }
        }

    } #foreach source item

    # read from stdin if no input files specified.
    push @$lrArgs, '-' unless @$lrArgs || $opts{NO_INPUT};

    $core->run(@$lrArgs);

    return 0;
} #Main()

# }}}1

# no import() --- call Main() directly with its fully-qualified name

1; # End of XML::Axk::App
__END__
# === Documentation ===================================================== {{{1

=pod

=encoding UTF-8

=head1 NAME

XML::Axk::App - awk-like XML processor, command-line interface

=head1 USAGE

    axk [options] [--] [input filename or script]

=head1 INPUTS

A filename of C<-> represents standard input.  To actually process a file
named C<->, you will need to use shell redirection (e.g., C<< axk < - >>).
Standard input is the default if no input filenames are given.

The first non-option argument is used for program text if no -e or -f
are given.  If that argument names a readable regular file or symlink,
an axk program will be loaded from that file.  Otherwise, that argument
is used as an axk program directly.

The script language version for a -e will default to the latest if the text
on the command line doesn't specify a language version.

# TODO make -L and -B apply to following -e's

=head1 OPTIONS

=over

=item -B, --backend B<bkend>

B<Not yet implemented:>
Take input using the backend B<bkend>.

=item -e, --source B<text>

Run the axk code given as B<text>.

=item -f, --file B<filename>

Run the axk code given in the file called B<filename>.

=item -L, --language B<lang>

B<Not yet implemented:>
Interpret the following B<-e> in axk language B<lang>.

=item --show B<what>

Show debugging information.  Currently-implemented B<what> values are:

=over

=item source

Show the Perl source generated from the provided axk code.

=back

=item -v, --var B<name>=B<value>

B<Not yet implemented:>
Set B<name>=B<value>.

=item --version

Print the version of axk and exit

=back

=head1 PERL INTERFACE

For use in Perl programs:

    use XML::Axk::App;      # pick whichever you want,
    use XML::Axk::Core;     # or both

    # Canned interface, as if run from the command line
    XML::Axk::App::Main(\@ARGV)

    # Perl interface
    my $axk = XML::Axk::Core->new();

For details about the library interface, see L<XML::Axk::Core>.

=head1 AUTHOR

Christopher White, C<cxwembedded at gmail.com>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Axk::App

You can also look for information at:

=over 4

=item * GitHub: The project's main repository and issue tracker

L<https://github.com/cxw42/axk>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Axk>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Christopher White.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). Details are in the LICENSE
file accompanying this distribution.

=cut

# }}}1
# vi: set ts=4 sts=4 sw=4 et ai foldmethod=marker: #
