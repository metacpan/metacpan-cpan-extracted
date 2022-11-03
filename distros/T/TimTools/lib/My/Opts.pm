package My::Opts;

use FindBin qw( $RealBin );
use lib "$RealBin/lib";

use v5.32;
use Mojo::Base -strict;
use File::Basename  qw(basename);
use Getopt::Long    qw( GetOptions );
use Mojo::Util      qw( dumper );
use My::Array();

=head2 new

Input:
   [
      {
         desc     => "Option1",
         spec     => "opt1=s",
      },
      {
         desc     => "Option2",
         spec     => "opt2=s",
         required => 1,
         default  => 123,
      },
   ]

=cut

=head2 new

Create a new options object.

=cut

sub new {
    my ( $class, $spec ) = @_;

    my $s = bless {
        _args => \@ARGV,
        _spec => $spec,
    }, $class;

    $s->_init();
    $s;
}

sub _init {
    my ( $s ) = @_;

    $s->_parse();

    GetOptions( $s, $s->{_opts_spec}->@* ) or die "\n[$!]\n";

    # Check required options.
    my @missing_required =
      map  { $_->{key} }
      grep { not defined $s->{$_->{key}} }
      grep { $_->{_spec}{required} } $s->{_parsed}->@*;
    if ( @missing_required ) {
        local $" = "', '";
        say "";
        say $s->colored_msg(
            "ERROR: Missing required parameter(s): '@missing_required'" );
        say "";
        exit 1;
    }

    # Set Defaults.
    my @key_default =
      map  { [
          $_->{key},
          $_->{_spec}{default},
      ] }
      grep { not defined $s->{$_->{key}} }
      grep { $_->{_spec}{default} } $s->{_parsed}->@*;

    for (@key_default) {
        my ($key,$default) = @$_;
        $s->{$key} = $default;
    }

    $s->debug()        if $s->{debug};
    $s->list_options() if $s->{list_options};
}

sub _parse {
    my ( $s ) = @_;

    my $parsed = $s->{_parsed} = $s->__parse();

    $s->{_opts_spec} = [ map { $_->{spec} } @$parsed ];
    $s->{_opts_list} = [ sort map { $_->{list}->@* } @$parsed ];

    $s;
}

sub __parse {
    my ( $s ) = @_;

    my @parsed = map {
        my $opt_spec = $_->{spec};
        my $opt_desc = $_->{desc};
        my @opt_list = split /\|/, $opt_spec;
        my $arg      = $1 if $opt_list[-1] =~ s/ (\W+.*) //x;
        my $key      = $opt_list[0];

        for ( @opt_list ) {
            s/ (?=^\w{2,}) /--/x;    # Long options.
            s/ (?=^\w$)     /-/x;    # Short options.
        }

        {
            _spec => $_,
            key   => $key,
            spec  => $opt_spec,
            list  => \@opt_list,
            arg   => $arg      // "",
            desc  => $opt_desc // "...",
        };

    } $s->{_spec}->@*;

    \@parsed;
}

=head2 debug

Show the options.

=cut

sub debug {
    my ( $s ) = @_;
    delete $s->{_parsed} unless $s->{debug} > 1;
    say dumper $s;
    exit 1;
}

=head2 list_options

Show all options.

Nice for generating bash completions.

=cut

sub list_options {
    my ( $s ) = @_;
    say for $s->{_opts_list}->@*;
    exit 1;
}

=head2 build_help_options

Builds the text for the options
section of a help menu.

=cut

sub build_help_options {
    my ( $s )  = @_;
    my $indent = " " x 6;
    my $parsed = $s->{_parsed};

    my @line = map {
        my $arg       = _expand_arg( $_->{arg} );
        my $opts_list = join ", ", $_->{list}->@*;
        [ "$opts_list$arg", $_->{desc}, ]
    } @$parsed;

    my $max    = My::Array->max_lengths( \@line );
    my $format = $s->_make_format( $max );
    my $output = join "\n$indent", map { sprintf $format, @$_; } @line;

    $output;
}

sub _expand_arg {
    local ( $_ ) = @_;

    my $required = s/=//;
    my $optional = s/:(\d+)/DEFAULT=$1/ or s/://;

    my %means = (
        s   => "STRING",
        i   => "INTEGER",
        '+' => "INCREMENT",
    );

    my $arg = $means{$_} // $_;

    $arg = "[$arg]" if $optional;
    $arg = " $arg"  if $arg ne "";

    $arg;
}

sub _make_format {
    my ( $s, $max ) = @_;
    join " # ", map { "%-${_}s" } @$max;
}

=head2 colored_msg

Returned a colored message.

=cut

sub colored_msg {
    my ( $s, $msg, $script_path ) = @_;
    my $script = basename($script_path // $0);

    package My { use Mojo::Base -base };
    my $my = My->with_roles( "+ColoredHelp" )->new;
    $my->color_msg( $msg, $script );
}

1;
