#------------------------------------------------
# Version 3.2 specific functions

package VCF::V3_2;
$VCF::V3_2::VERSION = '1.003';
use base qw(VCF::Reader);

sub new
{
    my ($class,@args) = @_;
    my $self = $class->SUPER::new(@args);
    bless $self, ref($class) || $class;

    $$self{_defaults} =
    {
        version => '3.2',
        drop_trailings => 1,
        filter_passed  => 0,

        defaults =>
        {
            QUAL    => '-1',
            default => '.',
            Flag    => undef,
            GT      => '.',
        },

        handlers =>
        {
            Integer   => \&VCF::Reader::validate_int,
            Float     => \&VCF::Reader::validate_float,
            Character => \&VCF::Reader::validate_char,
            String    => undef,
            Flag      => undef,
        },

        regex_snp   => qr/^[ACGTN]$/i,
        regex_ins   => qr/^I[ACGTN]+$/,
        regex_del   => qr/^D\d+$/,
        regex_gtsep => qr{[\\|/]},
        regex_gt    => qr{^(\.|\d+)([\\|/]?)(\.?|\d*)$},
        regex_gt2   => qr{^(\.|[0-9ACGTNIDacgtn]+)([\\|/]?)},
    };

    for my $key (keys %{$$self{_defaults}})
    {
        $$self{$key}=$$self{_defaults}{$key};
    }


    return $self;
}
