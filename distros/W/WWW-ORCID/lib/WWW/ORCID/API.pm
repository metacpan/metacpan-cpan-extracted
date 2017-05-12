package WWW::ORCID::API;

use strict;
use warnings;
use namespace::clean;
use utf8;
use JSON qw(decode_json);
use XML::Writer;
use Moo;

with 'WWW::ORCID::API::Common';

sub _build_url {
    my ($self) = @_;
    $self->sandbox ? 'http://api.sandbox.orcid.org'
                   : 'http://api.orcid.org';
}

sub new_access_token {
    my ($self, $client_id, $client_secret, %opts) = @_;

    my $grant_type = $opts{grant_type};
    if (!defined $grant_type) { $grant_type = 'client_credentials' }

    my $url = $self->url;
    my $headers = {'Accept' => 'application/json'};
    my $form = {
        client_id => $client_id,
        client_secret => $client_secret,
        grant_type => $grant_type,
    };
    $form->{scope} = $opts{scope} if defined $opts{scope};
    $form->{code}  = $opts{code}  if defined $opts{code};
    my ($res_code, $res_headers, $res_body) =
        $self->_t->post_form("$url/oauth/token", $form, $headers);
    decode_json($res_body);
}

sub get_profile {
    my ($self, $access_token, $orcid) = @_;
    my $url = $self->url;
    my $headers = {
        'Accept' => 'application/orcid+json',
        'Authorization' => "Bearer $access_token",
    };
    my ($res_code, $res_headers, $res_body) =
        $self->_t->get("$url/$orcid/orcid-profile", undef, $headers);
    decode_json($res_body);
}

sub get_bio {
    my ($self, $access_token, $orcid) = @_;
    my $url = $self->url;
    my $headers = {
        'Accept' => 'application/orcid+json',
        'Authorization' => "Bearer $access_token",
    };
    my ($res_code, $res_headers, $res_body) =
        $self->_t->get("$url/$orcid/orcid-bio", undef, $headers);
    decode_json($res_body);
}

sub get_works {
    my ($self, $access_token, $orcid) = @_;
    my $url = $self->url;
    my $headers = {
        'Accept' => 'application/orcid+json',
        'Authorization' => "Bearer $access_token",
    };
    my ($res_code, $res_headers, $res_body) =
        $self->_t->get("$url/$orcid/orcid-works", undef, $headers);
    decode_json($res_body);
}

sub search_bio {
    my ($self, $access_token, $params) = @_;
    my $url = $self->url;
    my $headers = {
        'Accept' => 'application/orcid+json',
        'Authorization' => "Bearer $access_token",
    };
    my ($res_code, $res_headers, $res_body) =
        $self->_t->get("$url/search/orcid-bio", $params, $headers);
    decode_json($res_body);
}

sub new_profile {
    my ($self, $access_token, $profile) = @_;
    my $url = $self->url;
    my $headers = {
        'Accept' => 'application/xml',
        'Content-Type' => 'application/vdn.orcid+xml',
        'Authorization' => "Bearer $access_token",
    };

    my $xml = XML::Writer->new(OUTPUT => 'self', ENCODING => 'UTF-8');
    $xml->xmlDecl;
    $xml->startTag('orcid-message',
            'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
            'xsi:schemaLocation' => "http://www.orcid.org/ns/orcid https://raw.github.com/ORCID/ORCID-Source/master/orcid-model/src/main/resources/orcid-message-1.1.xsd",
            'xmlns' => "http://www.orcid.org/ns/orcid",
    );
    $xml->dataElement('message-version', '1.1');
    $xml->startTag('orcid-profile');
    $xml->startTag('orcid-bio');
    $xml->startTag('personal-details');
    $xml->dataElement('given-names', $profile->{given_names});
    $xml->dataElement('family-name', $profile->{family_name});
    if ($profile->{credit_name}) {
        $xml->dataElement('credit-name', $profile->{credit_name});
    }
    if ($profile->{other_names}) {
        $xml->startTag('other-names');
        for my $val (@{$profile->{other_names}}) {
            $xml->dataElement('other-name', $val);
        }
        $xml->endTag('other-names');
    }
    $xml->endTag('personal-details');
    $xml->startTag('contact-details');
    if (my $vals = $profile->{email}) {
        for my $val (ref $vals eq 'ARRAY' ? @$vals : ($vals)) {
            if (ref $val) {
                my $email = delete $val->{email};
                $xml->dataElement('email', $email, %$val);
            } else {
                $xml->dataElement('email', $val);
            }
        }
    }
    if ($profile->{country}) {
        $xml->startTag('address');
        $xml->dataElement('country', $profile->{country});
        $xml->endTag('address');
    }
    $xml->endTag('contact-details');
    if ($profile->{researcher_urls}) {
        $xml->startTag('researcher-urls');
        for my $val (@{$profile->{researcher_urls}}) {
            $xml->startTag('researcher-url');
            $xml->dataElement('url-name', $val->{url_name});
            $xml->dataElement('url', $val->{url});
            $xml->endTag('researcher-url');
        }
        $xml->endTag('researcher-urls');
    }
    if ($profile->{biography}) {
        $xml->dataElement('biography', $profile->{biography});
    }
    if ($profile->{keywords}) {
        $xml->startTag('keywords');
        for my $val (@{$profile->{keywords}}) {
            $xml->dataElement('keyword', $val);
        }
        $xml->endTag('keywords');
    }
    $xml->endTag('orcid-bio');
    if (($profile->{works} && @{$profile->{works}}) || 
            ($profile->{affiliations} && @{$profile->{affiliations}})) {
        $xml->startTag('orcid-activities');
        if ($profile->{works} && @{$profile->{works}}) {
            $xml->startTag('orcid-works');
            for my $work (@{$profile->{works}}) {
                if ($work->{visibility}) {
                    $xml->startTag('orcid-work', visibility => $work->{visibility});
                } else {
                    $xml->startTag('orcid-work');
                }
                $xml->startTag('work-title');
                $xml->dataElement('title', $work->{title});
                if ($work->{subtitle}) {
                    $xml->dataElement('subtitle', $work->{subtitle});
                }
                $xml->endTag('work-title');
                if ($work->{short_description}) {
                    $xml->dataElement('short-description', $work->{short_description});
                }
                if ($work->{type}) {
                    $xml->dataElement('work-type', $work->{type});
                }
                $xml->endTag('orcid-work');
            }
            $xml->endTag('orcid-works');
        }
        if ($profile->{affiliations} && @{$profile->{affiliations}}) {
            $xml->startTag('affiliations');
            for my $aff (@{$profile->{affiliations}}) {
                $xml->dataElement('type', $aff->{type});
                if ($aff->{department_name}) {
                    $xml->dataElement('department-name', $aff->{department_name});
                }
                if ($aff->{role_title}) {
                    $xml->dataElement('role-title', $aff->{role_title});
                }
                # TODO start-date
                $xml->startTag('organization');
                $xml->dataElement('name', $aff->{name});
                if (my $addr = $aff->{address}) {
                    $xml->startTag('address');
                    $xml->dataElement('city', $addr->{city});
                    $xml->dataElement('region', $addr->{region}) if exists $addr->{region};
                    $xml->dataElement('country', $addr->{country});
                    $xml->endTag('address')
                }
                # TODO disambiguated-organization
                $xml->endTag('organization');
            }
            $xml->endTag('affiliations');
        }
        $xml->endTag('orcid-activities');
    }
    $xml->endTag('orcid-profile');
    $xml->endTag('orcid-message');
    $xml->end;

    if ($self->debug) {
        print STDERR $xml->to_string."\n";
    }

    my ($res_code, $res_headers, $res_body) =
        $self->_t->post("$url/orcid-profile", $xml->to_string, $headers);
    my $location = $res_headers->{location};
    my ($orcid) = $location =~ m!([^/]+)/orcid-profile$!;
    $orcid;
}

1;
