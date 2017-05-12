package XML::Grammar::Builder;

use strict;
use warnings;

use base 'Test::Run::Builder';

use File::Find;

our $VERSION = '0.0101';

sub new
{
    my $package = shift;
    my %args = @_;
    my @extradata_files;
    
    my $module_name = $args{'module_name'};
    $module_name =~ s{::}{-}g;

    my $filter_files_cb = sub {
        my $filename = $File::Find::name;
        if ((-f $filename) &&
            ($filename =~ /\.(?:mod|xslt|dtd|ent|cat|jpg|rng|xcf\.bz2)$/)
        )
        {
            push @extradata_files, $filename;
        }
    };
 
    find({ wanted => $filter_files_cb, no_chdir => 1}, "extradata");

    my $builder = $package->SUPER::new(
        extradata_files =>
        {
            (map { $_ => $_ } @extradata_files)
        },
        @_
    );

    $builder->add_build_element('extradata');

    $builder->install_path()->{'extradata'} = 
        File::Spec->catdir(
                $builder->install_destination("lib"),
                qw(data modules),
                $module_name,
                qw(data)
        );

    $builder->config_data(
        'extradata_install_path' =>
        [$builder->install_path()->{'extradata'}]
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
