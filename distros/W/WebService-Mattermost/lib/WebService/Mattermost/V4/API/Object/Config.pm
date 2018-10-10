package WebService::Mattermost::V4::API::Object::Config;

use Moo;
use Types::Standard qw(HashRef Maybe);

extends 'WebService::Mattermost::V4::API::Object';

################################################################################

has [ qw(
    analytics_settings
    cluster_settings
    compliance_settings
    email_settings
    file_settings
    gitlab_settings
    google_settings
    ldap_settings
    localisation_settings
    localization_settings
    log_settings
    metrics_settings
    native_app_settings
    office_365_settings
    password_settings
    rate_limit_settings
    saml_settings
    service_settings
    sql_settings
    support_settings
    team_settings
    webrtc_settings
) ] => (is => 'ro', isa => Maybe[HashRef], lazy => 1, builder => 1);

################################################################################

sub _build_analytics_settings     { shift->raw_data->{AnalyticsSettings}     }
sub _build_cluster_settings       { shift->raw_data->{ClusterSettings}       }
sub _build_compliance_settings    { shift->raw_data->{ComplianceSettings}    }
sub _build_email_settings         { shift->raw_data->{EmailSettings}         }
sub _build_file_settings          { shift->raw_data->{FileSettings}          }
sub _build_gitlab_settings        { shift->raw_data->{GitLabSettings}        }
sub _build_google_settings        { shift->raw_data->{GoogleSettings}        }
sub _build_ldap_settings          { shift->raw_data->{LdapSettings}          }
sub _build_localisation_settings  { shift->localization_settings             }
sub _build_localization_settings  { shift->raw_data->{LocalizationSettings}  }
sub _build_log_settings           { shift->raw_data->{LogSettings}           }
sub _build_metrics_settings       { shift->raw_data->{MetricsSettings}       }
sub _build_native_app_settings    { shift->raw_data->{NativeAppSettings}     }
sub _build_office_365_settings    { shift->raw_data->{Office365Settings}     }
sub _build_password_settings      { shift->raw_data->{PasswordSettings}      }
sub _build_rate_limit_settings    { shift->raw_data->{RateLimitSettings}     }
sub _build_saml_settings          { shift->raw_data->{SamlSettings}          }
sub _build_service_settings       { shift->raw_data->{ServiceSettings}       }
sub _build_sql_settings           { shift->raw_data->{SqlSettings}           }
sub _build_support_settings       { shift->raw_data->{SupportSettings}       }
sub _build_team_settings          { shift->raw_data->{TeamSettings}          }
sub _build_webrtc_settings        { shift->raw_data->{WebrtcSettings}        }

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Config

=head1 DESCRIPTION

Describes a Mattermost configuration response.

=head2 ATTRIBUTES

=over 4

=item C<analytics_settings>

=item C<cluster_settings>

=item C<compliance_settings>

=item C<email_settings>

=item C<file_settings>

=item C<gitlab_settings>

=item C<google_settings>

=item C<ldap_settings>

=item C<localisation_settings>

=item C<localization_settings>

=item C<log_settings>

=item C<metrics_settings>

=item C<native_app_settings>

=item C<office_365_settings>

=item C<password_settings>

=item C<rate_limit_settings>

=item C<saml_settings>

=item C<service_settings>

=item C<sql_settings>

=item C<support_settings>

=item C<team_settings>

=item C<webrtc_settings>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

