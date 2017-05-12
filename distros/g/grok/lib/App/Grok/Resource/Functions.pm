package App::Grok::Resource::Functions;
BEGIN {
  $App::Grok::Resource::Functions::AUTHORITY = 'cpan:HINRIK';
}
{
  $App::Grok::Resource::Functions::VERSION = '0.26';
}

use strict;
use warnings FATAL => 'all';
use File::ShareDir qw<dist_dir>;
use File::Spec::Functions qw<catdir catfile splitpath>;

use base qw(Exporter);
our @EXPORT_OK = qw(func_index func_fetch func_locate);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );
use constant {
    NAME => 0,
    POD  => 1,
    FILE => 2,
};

my %functions;
my $syn_dir = catdir(dist_dir('Perl6-Doc'), 'Synopsis');

sub func_fetch {
    my ($func) = @_;
    _read_functions() if !%functions;
    
    return $functions{$func}[POD] if defined $functions{$func};
    return;
}

sub func_index {
    _read_functions() if !%functions;
    return keys %functions;
}

sub func_locate {
    my ($func) = @_;
    _read_functions() if !%functions;
    return if !defined $functions{$func};
    return $functions{$func}[FILE];
}

## no critic (Subroutines::ProhibitExcessComplexity)
sub _read_functions {
    my ($self) = @_; 

    my $S29_file = catfile(dist_dir('Perl6-Doc'), 'Synopsis', 'S29-functions.pod');

    ## no critic (InputOutput::RequireBriefOpen)
    open my $S29, '<', $S29_file or die "Can't open '$S29_file': $!";

    # read until you find 'Function Packages'
    until (<$S29> =~ /Function Packages/) {}

    my (%S29_funcs, $func_name);
    while (my $line = <$S29>) {
        if (my ($directive, $title) = $line =~ /^=(\S+)(?: +(.+))?/) {
            if ($directive eq 'item') {
                # Found Perl6 function name
                if (my ($reference) = $title =~ /-- (see S\d+.*)/) {
                    # one-line entries
                    (my $func = $title) =~ s/^(\S+).*/$1/;
                    $S29_funcs{$func} = $reference;
                }   
                else {
                    $title =~ s/\(.*\)//;
                    $func_name = $title;
                }   
            }   
            else {
                $func_name = undef;
            }   
        }   
        elsif ($func_name) {
            # Adding documentation to the function name
            $S29_funcs{$func_name} .= $line;
        }
    }

    my %S29_sanitized;
    while (my ($func, $body) = each %S29_funcs) {
        $body = "=encoding utf8\n\n=head2 C<<< $func >>>\n$body";
        $S29_sanitized{$func} = [$func, $body, $S29_file] if $func !~ /\s/;

        if ($func =~ /,/) {
            my @funcs = split /,\s+/, $func;
            $S29_sanitized{$_} = [$func, $body, $S29_file] for @funcs;
        }
    }
    
    %functions = %S29_sanitized;
    
    # read S32
    my $S32_dir = catdir($syn_dir, 'S32-setting-library');
    my @sections = map { (splitpath($_))[2] } glob "$S32_dir/*.pod";
    $_ = catdir($S32_dir, $_) for @sections;

    for my $section (@sections) {
        ## no critic (InputOutput::RequireBriefOpen)
        open my $handle, '<', $section or die "Can't open $section: $!";

        my @new_func;
        while (my $line = <$handle>) {
            if (my ($directive, $title) = $line =~ /^=(\S+)(?: +(.+))?/) {
                if (defined $new_func[NAME]) {
                    my $name = $new_func[NAME];
                    
                    # S32 only overwrites S29 if the new definition is wordier
                    if (!defined $functions{$name} ||
                        length $new_func[POD] > length $functions{$name}[POD]) {
                        $functions{$new_func[NAME]} = [@new_func];
                    }
                    @new_func = ();
                }
                if ($directive eq 'item') {
                    $title =~ s/.*?method\s*//;
                    $title =~ s/^(\S+)\s*\(.*/$1/;
                    if ($title =~ /^\S+$/) {
                        $new_func[NAME] = $title;
                        $new_func[POD] = "=encoding utf8\n\n=head2 C<<< $title >>>\n";
                        $new_func[FILE] = $section;
                    }
                }
            }
            elsif (defined $new_func[FILE]) {
                # Adding documentation to the function name
                $new_func[POD] .= $line;
            }
        }

        close $handle;
    }

    return;
}

1;

=encoding utf8

=head1 NAME

App::Grok::Resource::Functions - S29/S32 functions resource for grok

=head1 SYNOPSIS

 use strict;
 use warnings;
 use App::Grok::Resource::Functions qw<:ALL>;

 # a list of all functions
 my @index = func_index();

 # documentation for a specific functions
 my $pod = func_fetch('split');

 # the file where the function was found
 my $file = func_locate('split');

=head1 DESCRIPTION

This resource reads Synopses 29 and 32, and allows you to look up the
functions therein.

=head1 FUNCTIONS

=head2 C<func_index>

Takes no arguments. Returns a list of all known function names.

=head2 C<func_fetch>

Takes the name of a function as an argument. Returns the documentation for
that function.

=head2 C<func_locate>

Takes the same argument as L<C<func_fetch>|/func_fetch>. Returns the path to
the Synopsis file where the given function was found.

=cut
