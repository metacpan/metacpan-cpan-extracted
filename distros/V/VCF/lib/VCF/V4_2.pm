
#------------------------------------------------
# Version 4.2 specific functions

=head1 VCFv4.2

VCFv4.2 specific functions

=cut

package VCF::V4_2;
$VCF::V4_2::VERSION = '1.003';
use base qw(VCF::V4_1);

sub new
{
    my ($class,@args) = @_;
    my $self = $class->SUPER::new(@args);
    bless $self, ref($class) || $class;

    $$self{version} = '4.2';
    return $self;
}

1;
