package XUL::App::View::Install;

use strict;
use warnings;
#use Smart::Comments;

use base 'Template::Declare';
use Template::Declare::Tags
        'RDF::EM' => { namespace => 'em' }, 'RDF';

our %UUID = (
    mozilla => '{86c18b42-e466-45a9-ae7a-9b95ba6f5640}',
    firefox => '{ec8030f7-c20a-464f-9b0e-13a3a9e97384}',
    flock => '{a463f10c-3994-11da-9945-000d60ca027b}',
    seamonkey => '{92650c4d-4b8e-4d2a-b7eb-24ecf4f6b63a}',
    thunderbird => '{3550f703-e582-4d05-9a08-453d09bdfdc6}',
    nvu => '{136c295a-4a5a-41cf-bf24-5cee526720d5}',
    sunbird => '{718e30fb-e89b-41dd-9da7-e25a45638b28}',
    netscape => '{3db10fab-e461-4c80-8b97-957ad5f8ea47}',
);

# for install.rdf generation:
template main => sub {
    my ($self, $xpifile) = @_;
    xml_decl { 'xml', version => '1.0', encoding => 'UTF-8' };
    RDF {
        attr {
            'xmlns' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
            'xmlns:em' => 'http://www.mozilla.org/2004/em-rdf#'
        }
        Description {
            attr { about => 'urn:mozilla:install-manifest' }
            em::id { $xpifile->id }
            em::name { $xpifile->display_name || $xpifile->name }
            em::description { $xpifile->description }
            em::version { $xpifile->version }
            em::creator { $xpifile->creator };
            for (@{ $xpifile->developers }) {
                em::developer { $_ }
            }
            for (@{ $xpifile->contributors }) {
                em::contributor { $_ }
            }

            my $targets = $xpifile->targets;
            while (my ($app, $ver_range) = each %$targets) {
                outs_raw("\n\n  <!-- $app, version $ver_range->[0] - $ver_range->[1] -->");
		em::targetApplication {
                    Description {
                        em::id { get_uuid($app) }
                        em::minVersion { $ver_range->[0] }
                        em::maxVersion { $ver_range->[1] }
                    }
                }
            }
            em::homepageURL { $xpifile->homepageURL };
            if ($xpifile->updateURL) {
                em::updateURL { $xpifile->updateURL }
            }
            if ($xpifile->iconURL) {
                em::iconURL { $xpifile->iconURL }
            }

        }
    }
};

sub get_uuid {
    my $name = shift;
    my $key = lc($name);
    #warn $key;
    ### %UUID
    my $value = $UUID{$key};
    if (!$value) {
        die "Can't find UUID for target app $name\n";
    }
    return $value;
}

1;

