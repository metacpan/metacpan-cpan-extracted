package opts;
use strict;
use warnings;
our $VERSION = '0.07';
use Exporter 'import';
use PadWalker qw/var_name/;
use Getopt::Long;
use Carp ();

our @EXPORT = qw/opts/;

our $TYPE_CONSTRAINT = {
    'Bool'     => '!',
    'Str'      => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%', 
};

my %is_invocant = map{ $_ => undef } qw($self $class);

my $coerce_type_map = {
    Multiple => 'ArrayRef',
};

my $coerce_generater = {
    Multiple => sub { [ split(qr{,}, join(q{,}, @{ $_[0] })) ] },
};

sub opts {
    {
        package DB;
        # call of caller in DB package sets @DB::args,
        # which requires list context, but does not use return values
        () = caller(1);
    }

    # method call
    if(exists $is_invocant{ var_name(1, \$_[0]) || '' }){
        $_[0] = shift @DB::args;
        shift;
        # XXX: should we provide ways to check the type of invocant?
    }

    # track our coderef defaults
    my %default_subs;

    my @options = ('help|h!' => \my $help);
    my %requireds;
    my %generaters;
    my $usage;
    my @option_help;
    for(my $i = 0; $i < @_; $i++){

        (my $name = var_name(1, \$_[$i]))
            or  Carp::croak('usage: opts my $var => TYPE, ...');

        $name =~ s/^\$//;

        my $rule = _compile_rule($_[$i+1]);

        if ($name =~ /_/) {

            # Name has underscores in it, which is annoying for command line
            # arguments.  Swap them and create / add to alias.
            (my $newname = $name) =~ s/_/-/g;

            $rule->{alias}
                = $rule->{alias}
                ? $name . q{|} . $rule->{alias}
                : $name
                ;

            $name = $newname;
        }

        if (exists $rule->{default}) {

            if (ref $rule->{default} && ref $rule->{default} eq 'CODE') {
                $default_subs{$i} = $rule->{default};
                $_[$i] = undef;
            }
            else {
                $_[$i] = $rule->{default};
            }
        }

        if (exists $rule->{required}) {
            $requireds{$name} = $i;
        }

        
        my $comment = $rule->{comment} || "";
        my @names = (substr($name,0,1), $name);
        push @names, $rule->{alias} if $rule->{alias};
        my $optname = join(', ', map { (length($_) > 1 ? '--' : '-').$_ } @names);
        push @option_help, [ $optname, ucfirst($comment) ];

        if (my $gen = $coerce_generater->{$rule->{isa}}) {
            $generaters{$name} = { idx => $i, gen => $gen };
        }

        $name .= '|' . $rule->{alias} if $rule->{alias};
        push @options, $name . $rule->{type} => \$_[$i];

        $i++ if defined $_[$i+1]; # discard type info
    }
    
    {
        my $err;
        local $SIG{__WARN__} = sub { $err = shift };
        GetOptions(@options) or Carp::croak($err);
        if ($help) {
            $usage = "usage: $0 [options]\n\n";

            if (@option_help) {
                require Text::Table;
                push @option_help, ['-h, --help', 'This help message'];
                my $sep = \'   ';
                $usage .= "options:\n";
                $usage .= Text::Table->new($sep, '', $sep, '')->load(@option_help)->stringify."\n";
            }

            die $usage;
        }

        do { $_[$_] = $default_subs{$_}->() unless defined $_[$_] }
            for keys %default_subs;

        while ( my ($name, $idx) = each %requireds ) {
            unless (defined($_[$idx])) {
                Carp::croak("missing mandatory parameter named '\$$name'");
            }
        }
        while ( my ($name, $val) = each %generaters ) {
            $_[$val->{idx}] = $val->{gen}->($_[$val->{idx}]);
        }
    }
}

sub coerce ($$&) { ## no critic
    my ($isa, $type, $generater) = @_;

    $coerce_type_map->{$isa}  = $type;
    $coerce_generater->{$isa} = $generater;
}

sub _compile_rule {
    my ($rule) = @_;
    if (!defined $rule) {
        return +{ type => "!", isa => 'Bool' };
    }
    elsif (!ref $rule) { # single, non-ref parameter is a type name
        my $tc = _get_type_constraint($rule) || 
                 _get_type_constraint($coerce_type_map->{$rule}) or 
                 Carp::croak("cannot find type constraint '$rule'");
        return +{ type => $tc, isa => $rule };
    }
    else {
        my %ret;
        if ($rule->{isa}) {
            $ret{isa} = $rule->{isa};
            my $tc = _get_type_constraint($rule->{isa}) ||
                     _get_type_constraint($coerce_type_map->{$rule->{isa}}) or 
                     Carp::croak("cannot find type constraint '@{[$rule->{isa}]}'");
            $ret{type} = $tc;
        } else {
            $ret{isa} = 'Bool';
            $ret{type} = "!";
        }
        for my $key (qw(alias default required comment)) {
            if (exists $rule->{$key}) {
                $ret{$key} = $rule->{$key};
            }
        }
        return \%ret;
    }
}

sub _get_type_constraint {
    my $isa = shift;

    $TYPE_CONSTRAINT->{$isa};
}

1;
__END__

=head1 NAME

opts - (DEPRECATED) simple command line option parser

=head1 DESCRIPTION

B<THIS MODULE WAS DEPRECATED. USE Smart::Options INSTEAD.>

=head1 AUTHOR

Kan Fushihara E<lt>kan.fushihara at gmail.comE<gt>

=head1 SEE ALSO

L<Smart::Options>, L<Smart::Args>, L<Getopt::Long>

=cut
