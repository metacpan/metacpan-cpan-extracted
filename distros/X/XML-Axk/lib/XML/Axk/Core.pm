#!perl
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.

# Style note: Hungarian prefixes are used on scalars:
#   "hr" (hash ref), "lr" (list ref), "sr" (string ref), "nr" (numeric ref),
#   "dr" ("do," i.e., block ref), "ref" (unspecified ref),
#   "b" or "is" (boolean), "s" (string)

package XML::Axk::Core;
use XML::Axk::Base qw(:all);
use XML::Axk::Preparse;
use Data::Dumper;

our $VERSION = '0.001006';

=encoding UTF-8

=head1 NAME

XML::Axk::Core - awk-like XML processor, core

=head1 USAGE

    my $core = XML::Axk::Core->new(\%opts);
    $core->load_script_file($filename);
    $core->load_script_text($source_text, $filename);
    $core->run(@input_filenames);

=head1 OPTIONS

A filename of C<-> represents standard input.

=head1 OVERVIEW

axk coordinates languages and backends to process XML files.  Backends read
XML input and provide it to an axk script.  Languages are the way that
script is expressed.  Languages and backends can be mixed arbitrarily,
as long as the backend provides the API the language needs.

A single axk script can include code in any number of languages, but can
only use one backend.  The first backend referenced (implicitly or
explicitly) is the one used.

Each language has a default backend, but the user can specify a different
backend using a pragma.

=head1 SUBROUTINES

=head2 XML::Axk::Core->new

Constructor.  Takes a hash ref of options

=head1 METHODS

=cut

# Wrapper around string eval, way up here so it can't see any of the
# lexicals below.
sub eval_nolex {
    eval shift;
    return $@;
} #eval_nolex

use XML::Axk::Language ();
use XML::Axk::Sandbox;

# Private vars ========================================================== {{{1

# For giving each script a unique package name
my $scriptnumber = 0;

# }}}1
# Loading =============================================================== {{{1

=head2 load_script_file

Load the named script file from disk, but do not execute it.  Usage:

    $core->load_script_file(filename => $name[, ...])

=cut

# TODO permit specifying an Ln?
# @param $self
# @param $fn {String}   Filename to load
sub load_script_file {
    my $self = shift;
    my %args = @_;

    my $fn = $args{filename} or croak 'Need a filename';
    open(my $fh, '<', $fn) or croak "Cannot open $fn";
    my $contents = do { local $/; <$fh> };
    close $fh;

    $self->load_script_text(text => $contents, filename => $fn,
        auto_language => false);
        # false => scripts on disk MUST specify a Ln directive.  This is a
        # design decision, so we don't have issues like Python 2/3.

} #load_script_file

=head2 load_script_text

Load the given text, but do not execute it.  Usage:

    $core->load_script_text(text => $text[, filename => $name][, ...])

=cut

# @param $self
# @param $text {String} The source text, **which load_script_text may modify.**
# @param $filename {String}   Filename to use in debugging messages
# @param $auto_language {boolean, default false} If true, add a Ln directive for the
#           current version if there isn't one in the script.
# @param $language {String}     If provided, the language to use for the first
#           chunk of the text.
sub load_script_text {
    my $self = shift;
    my %args = @_;

    my $text = $args{text} or croak 'Need script text';
    my $fn = $args{filename} // '(anonymous)';

    my $curr_lang = $args{language};
    my $add_Ln = $args{auto_language};
    croak 'language and auto_language are mutually exclusive' if $curr_lang && $add_Ln;

    # Text to wrap around the script
    my ($leader, $trailer) = ('', '');

    my $hrInitialPragmas = {};
    if($add_Ln || $curr_lang) {
        $hrInitialPragmas = { L => {$curr_lang ? (name => '' . $curr_lang) : ()} };
    }

    my ($lrPieces, $has_lang) = XML::Axk::Preparse::pieces(\$text, $hrInitialPragmas);

    unless($has_lang || $curr_lang) {
        if($add_Ln) {
            $lrPieces->[0]->{pragmas}->{L}->{digits} = 1;  # default language
        } else {
            die "No language (Ln) specified in file $fn";
        }
    }

    my $srNewText = XML::Axk::Preparse::assemble($fn, $lrPieces);
    $text = $$srNewText;

    $text .= "\n" unless substr($text, length($text)-1) eq "\n";

    # Mark the filename for the sake of error messages.
    $leader .= ";\n#line 1 \"$fn\"\n";
        # Extra ; so the #line directive is in its own statement.
        # Thanks to https://www.effectiveperlprogramming.com/2011/06/set-the-line-number-and-filename-of-string-evals/

    # Put the user's script in its own package, with its own sandbox
    ++$scriptnumber;
    my $scriptname = SCRIPT_PKG_PREFIX . $scriptnumber;
    my $sandbox = XML::Axk::Sandbox->new($self, $scriptname);

    { # preload the sandbox into the script's package
        no strict 'refs';
        ${"${scriptname}::_AxkSandbox"} = $sandbox;
    }

    $leader = "package $scriptname {\n" .
        "use XML::Axk::Base;\n" .
        $leader;
    $trailer .= "\n;};\n";

    $text = ($leader . $text . $trailer);

    if($self->{options}->{SHOW} && ref $self->{options}->{SHOW} eq 'ARRAY' &&
       any {$_ eq 'source'} @{$self->{options}->{SHOW}}) {
        say "****************Loading $fn:\n$text\n****************";
    }

    # TODO? un-taint the source text so we can run under -T
    my $at = eval_nolex $text;
    croak "Could not parse '$fn': $at" if $at;
} #load_script_text

# }}}1
# Running =============================================================== {{{1

sub _run_pre_file {
    my ($self, $infn) = @_ or croak("Need a filename");

    foreach my $drAction (@{$self->{pre_file}}) {
        eval { &$drAction($infn) };   # which context are they evaluated in?
        croak "pre_file: $@" if $@;
    }
} # _run_pre_file

sub _run_post_file {
    my ($self, $infn) = @_ or croak("Need a filename");

    foreach my $drAction (@{$self->{post_file}}) {
        # TODO? make the last-seen node available to the action?
        # Similar to awk, in which the END block sees the last line as $0.
        eval { &$drAction($infn) };   # which context are they evaluated in?
        croak "post_file: $@" if $@;
    }
} # _run_post_file

# _run_worklist
sub _run_worklist {
    my $self = shift;
    my $now = shift;        # $now = HI, BYE, or CIAO

    my %CPs = (             # Core parameters
        NOW => $now,
        @_
    );

    # Assign the SPs from the CPs --

    while (my ($lang, $drUpdater) = each %{$self->{updaters}}) {
        $drUpdater->($self->{sp}->{$lang}, %CPs);
    }

    # Run the worklist -------------

    foreach my $lrItem (@{$self->{worklist}}) {
        #say Dumper($lrItem);
        my ($refPattern, $refAction, $when) = @$lrItem;
        #say "At time $now: running ", Dumper($lrItem);

        next if $when && ($now != $when);   # CIAO is the only falsy one

        next unless $refPattern->test(\%CPs);
            # Matchers use CPs so they are independent of language.

        eval { &$refAction };   # which context are they evaluated in?
        die "action: $@" if $@;
    } #foreach worklist item
} #_run_worklist

sub run_sax_fh {
    my ($self, $fh, $infn) = @_ or croak("Need a filehandle and filename");
    my $runner;
    eval {
        use XML::Axk::SAX::Runner;
        $runner = XML::Axk::SAX::Runner->new($self);
    };
    die $@ if $@;

    $self->_run_pre_file($infn);
    $runner->run($fh, $infn);
    $self->_run_post_file($infn);

} #run_sax_fh()

=head2 run

Run the loaded script or scripts.  Takes a list of inputs.  Strings are treated
as filenames; references to strings are treated as raw data to be run
as if read off disk.  A filename of '-' represents STDIN.  To process a
disk file named '-', read its contents first and pass them in as a ref.

=cut

sub run {
    my $self = shift;

    #say "SPs:\n", Dumper(\%XML::Axk::Language::SP_Registry);

    foreach my $drAction (@{$self->{pre_all}}) {
        eval { &$drAction };   # which context are they evaluated in?
        croak "pre_all: $@" if $@;
    }

    foreach my $infn (@_) {
        my $fh;
        #say "Processing $infn";

        # TODO? Clear the SPs before each file for consistency?

        # For now, just process lines rather than XML nodes.
        if($infn eq '-') {  # stdin
            open($fh, '<-') or croak "Can't open stdin: $!";
        } else {            # disk file
            open($fh, "<", $infn) or croak "Can't open $infn: $!";
                # if $infn is a reference, its contents will be used -
                # http://www.perlmonks.org/?node_id=745018
        }

        $self->run_sax_fh($fh, $infn);  # TODO permit selecting DOM mode

        close($fh) or warn "close failed: $!";

    } #foreach input filename

    foreach my $drAction (@{$self->{post_all}}) {
        # TODO? pass the last-seen node? (see note above)
        eval { &$drAction };   # which context are they evaluated in?
        croak "post_all: $@" if $@;
    }

} #run()

# }}}1
# Constructor and accessors ============================================= {{{1

sub _globalname {   # static int->str
    my $idx = shift;
    return "XML::Axk::Core::_I${idx}";
} #_globalname()

# For giving each instance of Core a unique package name (_globalname)
my $_instance_number = 0;

sub new {
    my $class = shift;
    my $hrOpts = shift // {};

    # Create the instance.
    my $data = {
        _id => ++$_instance_number,
        options => $hrOpts,

        # Load these in the order they are defined in the scripts.
        pre_all => [],      # List of \& to run before reading the first file
        pre_file => [],     # List of \& to run before reading each file
        worklist => [],     # List of [$refCondition, \&action, $when] to be run against each node.
        post_file => [],    # List of \& to run after reading each file
        post_all => [],     # List of \& to run after reading the last file

        # Script parameters, indexed by language name (X::A::L::Ln).
        # Format: { lang name => { varname with sigil => value, ... }, ... }
        sp => {},

        # Per-language updaters, indexed by language name
        updaters => {},

    };
    my $self = bless($data, $class);

    # Load this instance into the global namespace so the Ln packages can
    # get at it
    do {
        no strict 'refs';
        ${_globalname($_instance_number)} = $self;
    };

    return $self;
} #new()

# Allocate the SPs for a particular language.
# All the SPs must be given in one call.  Subsequent calls are nops.
sub allocate_sps {
    my $self = shift;
    my $lang = shift;
    return if exists $self->{sp}->{$lang};
    my $hr = $self->{sp}->{$lang} = {};

    for my $name (@_) {
        my $sigil = substr($name, 0, 1);
        $self->{sp}->{$lang}->{$name} = undef, next if $sigil eq '$';
        $self->{sp}->{$lang}->{$name} = [], next if $sigil eq '@';
    }

    #say Dumper \%{$self->{sp}};
} #allocate_sp()

sub set_updater {
    my $self = shift;
    my $lang = shift;
    return if exists $self->{updaters}->{$lang};
    $self->{updaters}->{$lang} = shift // sub {};
} #set_updater()

# RO accessors
sub id {
    return shift->{_id};
}

sub global_name {
    return _globalname(shift->{_id});
}

# }}}1

# No import() --- callers should refer to the symbols with their
# fully- qualified names.
1;
# === Documentation ===================================================== {{{1

=pod

=head1 AUTHOR

Christopher White, C<cxwembedded at gmail.com>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Axk::Core

You can also look for information at:

=over 4

=item * GitHub: The project's main repository and issue tracker

L<https://github.com/cxw42/axk>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Axk>

=back

=head1 NOTE

I just recently found out about L<Web::Scraper>, which has some overlapping
functionality.  However, XML::Axk is targeted specifically at XML, rather
than HTML, and should eventually support dedicated, non-Perl script languages.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Christopher White.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). Details are in the LICENSE
file accompanying this distribution.

=cut

# }}}1
# vi: set ts=4 sts=4 sw=4 et ai fo=cql foldmethod=marker foldlevel=0: #
