use strict; use warnings;
package assign::Hash;

use assign::Struct;
use base 'assign::Struct';

use XXX;

sub parse_elem {
    my ($self) = @_;
    my $in = $self->{in};
    my $elems = $self->{elems};
    while (@$in) {
        my $tok = shift(@$in);
        my $type = ref($tok);
        $type =~ s/^PPI::Token::// or XXX $type;
        next if $type eq 'Whitespace';

        if ($type eq 'Symbol') {
            my $str = $tok->content;
            if ($str =~ /^\$\w+$/) {
                push @$elems, var->new($str);
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

    for my $elem (@$elems) {
        my $type = ref $elem;
        my $var = $elem->val;
        (my $key = $var) =~ s/^\$//;
        push @$code, "$decl$var $oper $from\->{$key};";
    }

    return join "\n", @$code;
}

1;
