package URI::Template::Restrict::Expansion;

use strict;
use warnings;
use base 'Class::Accessor::Fast';
use Carp qw(croak);
use URI::Escape qw(uri_unescape);

__PACKAGE__->mk_accessors(qw'op arg vars');

{
    package # hide from PAUSE
        URI::Template::Restrict::Expansion::var;
    use base 'Class::Accessor::Fast';
    __PACKAGE__->mk_accessors(qw'name default');
}

my (%RE, %PATTERN, %PROCESSOR, %EXTRACTOR);

# ----------------------------------------------------------------------
# Draft 03 - 4.2. Template Expansions
# ----------------------------------------------------------------------
#   op         = 1*ALPHA
#   arg        = *(reserved / unreserved / pct-encoded)
#   var        = varname [ "=" vardefault ]
#   vars       = var [ *("," var) ]
#   varname    = (ALPHA / DIGIT)*(ALPHA / DIGIT / "." / "_" / "-" )
#   vardefault = *(unreserved / pct-encoded)
#   operator   = "-" op "|" arg "|" vars
#   expansion  = "{" ( var / operator ) "}"
# ----------------------------------------------------------------------
# RFC 3986 - 2. Characters
# ----------------------------------------------------------------------
#   pct-encoded = "%" HEXDIG HEXDIG
#   unreserved  = ALPHA / DIGIT / "-" / "." / "_" / "~"
#   reserved    = gen-delims / sub-delims
#   gen-delims  = ":" / "/" / "?" / "#" / "[" / "]" / "@"
#   sub-delims  = "!" / "$" / "&" / "'" / "(" / ")"
#               / "*" / "+" / "," / ";" / "="
# ----------------------------------------------------------------------
{
    $RE{op}         = '[a-zA-Z]+';
    $RE{arg}        = '.*?';
    $RE{varname}    = '[a-zA-Z0-9][a-zA-Z0-9._\-]*';
    $RE{vardefault} = '(?:[a-zA-Z0-9\-._~]|(?:%[a-fA-F0-9]{2}))*';
    $RE{varextract} = sub {
        my %ex = map { $_ => undef } @_;
        my $re = join '' =>
            grep { !exists $ex{$_} }
            ('!', '$', '&', q|'|, '(', ')', '*', '+', ',', ';', '=', ':', '@');
        return '(?:[a-zA-Z0-9\-._~]|[' . $re . ']|(?:%[a-fA-F0-9]{2}))*';
    };
    $RE{var}        = "$RE{varname}(?:=$RE{vardefault})?";
    $RE{vars}       = "$RE{var}(?:,$RE{var})*";
}

sub new {
    my ($class, $expansion) = @_;
    my ($op, $arg, $vars);

    if ($expansion =~ /^($RE{var})$/) {
        # var = varname [ "=" vardefault ]
        ($op, $vars) = ('fill', $1);
    }
    elsif ($expansion =~ /^\-($RE{op})\|($RE{arg})\|($RE{vars})$/) {
        # operator = "-" op "|" arg "|" vars
        ($op, $arg, $vars) = ($1, $2, $3);
    }

    # no vars
    croak "unparsable expansion: $expansion"
        unless defined $op and defined $vars;

    my @vars = split /,/, $vars;
    for my $var (@vars) {
        my ($name, $default) = split /=/, $var;
        # replace var
        $var = URI::Template::Restrict::Expansion::var->new({
            name    => $name,
            default => $default
        });
    }

    my $self = {
        op   => $op,
        arg  => $arg,
        vars => @vars == 1 ? $vars[0] : \@vars,
    };
    return bless $self, $class;
}

%PATTERN = (
    fill   => $RE{varextract}->(),
    prefix => sub {
        my $arg = shift->arg;
        my $re  = $RE{varextract}->($arg);
        $arg = quotemeta $arg;
        return "(?:${arg}$re)*";
    },
    suffix => sub {
        my $arg = shift->arg;
        my $re  = $RE{varextract}->($arg);
        $arg = quotemeta $arg;
        return "(?:$re${arg})*";
    },
    list   => sub {
        my $arg = shift->arg;
        my $re  = $RE{varextract}->($arg);
        $arg = quotemeta $arg;
        return "(?:$re(?:${arg}$re)*)*";
    },
    join   => sub {
        my $self = shift;
        my $arg  = quotemeta $self->arg;
        my @vars = ref $self->vars eq 'ARRAY' ? @{ $self->vars } : ($self->vars);
        my @pattern;
        my $re = $RE{varextract}->($self->arg, '=');
	my $names = join('|', map { $_->name } @vars);
	my $n = $#vars;
	return "(?:(?:(?:${names})=$re){0,1}(?:${arg}(?:${names})=$re){0,${n}})";
    },
);

sub pattern {
    my $self = shift;
    my $pattern = $PATTERN{$self->op};
    return ref $pattern ? $pattern->($self) : $pattern;
}

%PROCESSOR = (
    fill   => sub {
        my ($self, $vars) = @_;
        my $var   = $self->vars;
        my $name  = $var->name;
        my $value = defined $var->default ? $var->default : '';
        return defined $vars->{$name} ? $vars->{$name} : $value;
    },
    prefix => sub {
        my ($self, $vars) = @_;
        my $args = $vars->{$self->vars->name};
        return '' unless defined $args;
        my $arg = defined $self->arg ? $self->arg : '';
        return join '', map { "${arg}${_}" } ref $args ? @$args : ($args);
    },
    suffix => sub {
        my ($self, $vars) = @_;
        my $args = $vars->{$self->vars->name};
        return '' unless defined $args;
        my $arg = defined $self->arg ? $self->arg : '';
        return join '', map { "${_}${arg}" } ref $args ? @$args : ($args);
    },
    list   => sub {
        my ($self, $vars) = @_;
        my $args = $vars->{$self->vars->name};
        return '' unless defined $args and ref $args eq 'ARRAY' and @$args > 0;
        return join defined $self->arg ? $self->arg : '', @$args;
    },
    join   => sub {
        my ($self, $vars) = @_;
        my @vars = ref $self->vars eq 'ARRAY' ? @{ $self->vars } : ($self->vars);
        my @pairs;
        for my $var (@vars) {
            my $name  = $var->name;
            my $value = exists $vars->{$name} ? $vars->{$name} : $var->default;
            next unless defined $value;
            push @pairs, "${name}=${value}";
        }
        return join defined $self->arg ? $self->arg : '', @pairs;
    },
);

sub process {
    my ($self, $vars) = @_;
    my $processor = $PROCESSOR{$self->op};
    return $processor->($self, $vars);
}

%EXTRACTOR = (
    fill   => sub {
        my ($self, $var) = @_;
        my $value = $var eq '' ? undef : uri_unescape($var);
        return ($self->vars->name, $value);
    },
    prefix => sub {
        my ($self, $var) = @_;
        my $arg = $self->arg;
        $var =~ s/^$arg//;
        my @vars = map { uri_unescape($_) } split /$arg/, $var;
        return ($self->vars->name, @vars > 1 ? \@vars : @vars ? $vars[0] : undef);
    },
    suffix => sub {
        my ($self, $var) = @_;
        my $arg = $self->arg;
        $var =~ s/$arg$//;
        my @vars = map { uri_unescape($_) } split /$arg/, $var;
        return ($self->vars->name, @vars > 1 ? \@vars : @vars ? $vars[0] : undef);
    },
    list   => sub {
        my ($self, $var) = @_;
        my $arg = $self->arg;
        my @vars = map { uri_unescape($_) } split /$arg/, $var;
        return ($self->vars->name, @vars > 0 ? \@vars : undef);
    },
    join   => sub {
        my ($self, $var) = @_;
        my %vars =
            map { ($_->name, $_->default) }
            ref $self->vars eq 'ARRAY' ? @{ $self->vars } : ($self->vars);
        my $arg = $self->arg;
        for my $pair (split /$arg/, $var) {
            my ($name, $value) = split /=/, $pair;
            $vars{$name} = uri_unescape($value);
        }
        return %vars;
    },
);

sub extract {
    my ($self, $var) = @_;
    my $extractor = $EXTRACTOR{$self->op};
    return $extractor->($self, $var);
}

1;

=head1 NAME

URI::Template::Restrict::Expansion - Template expansions

=head1 METHODS

=head2 process

=head2 extract

=head1 PROPERTIES

=head2 op

=head2 arg

=head2 vars

=head2 pattern

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<URI::Template::Restrict>

=cut
