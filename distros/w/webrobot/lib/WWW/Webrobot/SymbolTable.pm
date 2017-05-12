package WWW::Webrobot::SymbolTable;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


use Carp;


=head1 NAME

WWW::Webrobot::SymbolTable - Symbol table for Webrobot properties

=head1 SYNOPSIS

 use WWW::Webrobot::SymbolTable;
 my $symbols = WWW::Webrobot::SymbolTable -> new();

=head1 DESCRIPTION

=head1 METHODS

=over

=item new

Constructor

=cut

sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    $self->{_symbols} = {};
    $self->{_scope}   = [{}];
    return $self;
}

=item $symbols->push_scope()

Open a new scope for symbols.

=cut

sub push_scope {
    my ($self) = @_;
    push @{$self->{_scope}}, {};
}

=item $symbols->pop_scope()

Close (delete) the last scope, delete all symbols in this scope.

=cut

sub pop_scope {
    my ($self) = @_;
    my $scope = $self->{_scope};
    my $symbols = $self->{_symbols};

    foreach (keys %{$scope->[-1]}) {
        pop @{$symbols->{$_}};
        delete $symbols->{$_} if scalar @{$symbols->{$_}} == 0;
    }
    pop @$scope;
}

=item $symbols->define_symbol($name, $value)

Define a symbol in the current scope.

=cut

sub define_symbol {
    my ($self, $l, $r) = @_;
    my $symbols = $self->{_symbols};
    my $last_scope = $self->{_scope}->[-1];
    # was: my $entry = [$l, $r || "", qr/(?<!\\){$l}/];
    my $entry = $r || "";

    if ($last_scope->{$l}) { # entry exists in last scope, overwrite
        $symbols->{$l}->[-1] = $entry;
    }
    else { # no entry yet
        $last_scope->{$l} = 1;
        push @{$symbols->{$l}}, $entry;
    }
}

# private
sub _evaluate_string {
    my ($self, $str) = @_;
    return undef if !defined $str;
    my $symbols = $self->{_symbols};
    $str =~ s/ \${ ([^}]+) } / $symbols->{$1} ? $symbols->{$1}->[-1] : "\${$1}" /gex;
    return $str;
}

=item $symbols->evaluate($string)

Evaluate all symbols in a string.
The symbol variables must obey the syntax C<${name}>.
Returns the evaluated string.

=cut

sub evaluate {
    my ($self, $entry) = @_;
    SWITCH: foreach (ref $entry) {
        /^HASH$/ and do {
            foreach my $key (keys %$entry) {
                # substitute value
                if (ref $entry->{$key}) {
                    $self -> evaluate($entry->{$key});
                }
                else {
                    my $tmp = $entry->{$key};
                    $self -> evaluate(\$tmp);
                    $entry->{$key} = $tmp;
                }

                # substitute key
                my $nkey = $key;
                $self -> evaluate(\$nkey);
                if ($key ne $nkey) {
                    $entry->{$nkey} = delete $entry->{$key};
                }
            }
            last;
        };
        /^ARRAY$/ and do {
            foreach my $e (@$entry) {
                $self -> evaluate((ref $e) ? $e : \$e);
            }
            last;
        };
        /^SCALAR$/ and do {
            $$entry = $self->_evaluate_string($$entry);
            last;
        };
        /^$/ and do {
            $entry = $self->_evaluate_string($entry);
            last;
        }
        # ??? missing error handling
        # my $ref = ref $entry;
        # die "ARRAY or HASH expected, found $ref";
    }
    return $entry;
}


=back

=cut

1;
