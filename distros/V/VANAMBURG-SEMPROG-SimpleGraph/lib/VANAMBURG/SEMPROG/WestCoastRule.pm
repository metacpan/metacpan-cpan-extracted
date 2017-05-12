package VANAMBURG::SEMPROG::WestCoastRule;

use Moose;
use English;

sub getqueries
{
    my ($self) = shift;

    my @sfoq = qw/?company headquarters San_Francisco_California/;
    my @seaq = qw/?company headquarters Seattle_Washington/;
    my @laxq = qw/?company headquarters Los_Angelese_California/;
    my @porq = qw/?company headquarters Portland_Oregon/;

    my @result = (\@sfoq, \@seaq, \@laxq, \@porq);
    return \@result;
}

sub maketriples
{
    my ($self, $binding) = @ARG;

    return [ [$binding->{company}, 'on_coast', 'west_coast'] ];
}

with 'VANAMBURG::SEMPROG::InferenceRule';

# make Moose fast;
__PACKAGE__->meta->make_immutable;

# Perl requires 'true' return from modules.
1;

__END__

=head1 WestCoastRule

=head2 getqueries

  Returns array of queries. Each query is an array ref.


=head2 maketriples

    Returns sub, pred, obj in an array.

=cut
