package XML::Grammar::Builder;

use strict;
use warnings;

use base 'Test::Run::Builder';

use File::Find;

our $VERSION = '0.0200';

sub new
{
    my $package = shift;
    my %args = @_;
    my @extradata_files;

    my $builder = $package->SUPER::new(
        share_dir => 'extradata',
        auto_configure_requires => 1,
        @_
    );

    return $builder;
}


=begin excluded

    my $get_dest_extradata_cb = sub {
        my $fn = shift;

        # Trying if this makes it work.
        # TODO : Either remove this line or the rest of the lines.
        return $fn;

        $fn =~ s{^extradata}{data};
        return "lib/$module_name/$fn";
    };

=end excluded

=cut

1;
