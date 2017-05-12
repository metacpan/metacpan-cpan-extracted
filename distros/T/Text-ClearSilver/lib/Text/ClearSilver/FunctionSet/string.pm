package Text::ClearSilver::FunctionSet::string;
use strict;
use warnings;
use Text::ClearSilver::FunctionSet qw(usage);

sub _function_sprintf {
    my $fmt = shift;
    usage 'sprintf(fmt, ...)' if !defined $fmt;

    return sprintf($fmt, @_);
}

sub _function_substr {
    if(@_ == 2) {
        return substr($_[0], $_[1]);
    }
    elsif(@_ == 3) {
        return substr($_[0], $_[1], $_[2]);
    }
    else {
        usage 'substr(expr, offset [, length])';
    }
}

sub _function_trim {
    my($str) = @_;
    usage 'trim(expr)' if @_ != 1;

    $str =~ s/\A \s+   //xms;
    $str =~ s/   \s+ \z//xms;

    return $str;
}

sub _function_uc {
    usage 'uc(expr)' if @_ != 1;

    return uc($_[0]);
}

sub _function_lc {
    usage 'lc(expr)' if @_ != 1;

    return lc($_[0]);
}

sub _function_ucfirst {
    usage 'ucfirst(expr)' if @_ != 1;

    return ucfirst($_[0]);
}

sub _function_lcfirst {
    usage 'lcfirst(expr)' if @_ != 1;

    return lcfirst($_[0]);
}


1;
__END__

=head1 NAME

Text::ClearSilver::FunctionSet::string - A set of functions for strings

=head1 SYNOPSIS

    use Text::ClearSilver;

    my $tcs = Text::ClearSilver->new(
        function_set => [qw(string)]
    );

=head1 FUNCTIONS

=over

=item *

C<< sprintf(fmt, ...) >>

=item *

C<< substr(expr, offset [, length) >>

=item *

C<< trim(expr) >>

=item *

C<< lc(expr) >>

=item *

C<< uc(expr) >>

=item *

C<< lcfirst(expr) >>

=item *

C<< ucfirst(expr) >>

=back

=head1 SEE ALSO

L<Text::ClearSilver>

=cut
