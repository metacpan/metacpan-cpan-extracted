use strict; use warnings;
package assign::Hash;

use assign::Struct;
use base 'assign::Struct';

use assign::Types;

use XXX;

sub parse_elem {
    my ($self) = @_;
    my $in = $self->{in};
    my $elems = $self->{elems};
    while (@$in) {
        my $tok = shift(@$in);
        my $type = ref($tok);
        next if $type eq 'PPI::Token::Whitespace';

        if ($type eq 'PPI::Token::Symbol') {
            my $str = $tok->content;
            if ($str =~ /^\$\w+$/) {
                push @$elems, assign::var->new($str);
                return 1;
            }
        }
        XXX $tok, "unexpected token";
    }
    return 0;
}

sub gen_code {
    my ($self, $decl, $oper, $from, $init) = @_;

    my $code = [ @$init ];
    my $elems = $self->{elems};

    if ($decl) {
        push @$code,
            "$decl(" .
            join(', ',
                map $_->val,
                @$elems
            ) .
            ');';
    }

    for my $elem (@$elems) {
        my $type = ref $elem;
        my $var = $elem->val;
        (my $key = $var) =~ s/^\$//;
        push @$code, "$var $oper $from\->{$key};";
    }

    return join "\n", @$code;
}

1;
