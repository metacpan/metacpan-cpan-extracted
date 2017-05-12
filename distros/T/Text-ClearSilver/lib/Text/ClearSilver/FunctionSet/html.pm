package Text::ClearSilver::FunctionSet::html;
use strict;
use warnings;
use Text::ClearSilver::FunctionSet qw(usage);

sub _function_nl2br {
    my($str) = @_;
    usage 'nl2br(expr)' if @_ != 1;
    $str =~ s{\n}{<br />\n}xmsg;
    return $str;
}


1;
__END__

=head1 NAME

Text::ClearSilver::FunctionSet::html - A set of functions for HTML

=head1 SYNOPSIS

    use Text::ClearSilver;

    my $tcs = Text::ClearSilver->new(
        function_set => [qw(html)]
    );

=head1 FUNCTIONS

=over

=item *

C<< nl2br(expr) >>

=back

=head1 SEE ALSO

L<Text::ClearSilver>

=cut
