package WWW::SnipeIT::Hardware;
use Modern::Perl '2018';

use Object::Pad;

use HTTP::Request;
use LWP::UserAgent;
use JSON::XS;


class Hardware {

    field $endpoint :param;
    field $header :param;



    method getHardwareIDByAssetTag ($assetTag) {
        my $url = $endpoint."hardware/bytag/".$assetTag;
        my $r = HTTP::Request->new('GET', $url, $header);
        my $ua = LWP::UserAgent->new();
        my $res = $ua->request($r);
        my $results = JSON::XS::decode_json($res->{_content});

        return $results->{'id'}
    }

    method getHardwareByAssetTag ($assetTag) {
        my $url = $endpoint."hardware/bytag/".$assetTag;
        my $r = HTTP::Request->new('GET', $url, $header);
        my $ua = LWP::UserAgent->new();
        my $res = $ua->request($r);
        my $results = JSON::XS::decode_json($res->{_content});

        return $results
    }

    method getHardwareBySerialNumber ($serialNumber) {
        my $url = $endpoint."hardware/byserial/".$serialNumber;
        my $r = HTTP::Request->new('GET', $url, $header);
        my $ua = LWP::UserAgent->new();
        my $res = $ua->request($r);
        my $results = JSON::XS::decode_json($res->{_content});

        return $results
    }

    method getAssetTagByHardwareID ($hardwareID) {
        my $url = $endpoint."hardware/".$hardwareID;
        my $r = HTTP::Request->new('GET', $url, $header);
        my $ua = LWP::UserAgent->new();
        my $res = $ua->request($r);
        my $results = JSON::XS::decode_json($res->{_content});

        return $results->{'asset_tag'}
    }

    method updateAssetByHardwareID ($hardwareID, $body) {
        my $url = $endpoint."hardware/".$hardwareID;
        my $r = HTTP::Request->new('PUT', $url, $header, $body);
        my $ua = LWP::UserAgent->new();
        my $res = $ua->request($r);
    }

    method updateAssetByAssetTag ($assetTag, $body) {
        my $hardwareID = ($self->getHardwareIDByAssetTag($assetTag));
        $self->updateAssetByHardwareID ($hardwareID, $body)
    }

    method getHardwareByCustomField ($fieldName, $fieldValue, $itemType = 'asset') {
        my $url = $endpoint."hardware?".$fieldName."=".$fieldValue."&item_type=".$itemType;
        my $r = HTTP::Request->new('GET', $url, $header);
        my $ua = LWP::UserAgent->new();
        my $res = $ua->request($r);
        my $results = JSON::XS::decode_json($res->{_content});

        return $results;
    }

    method getHistoryByHardwareID ($hardwareID, $itemType = 'asset') {
        my $url = $endpoint."reports/activity?item_id=".$hardwareID."&item_type=".$itemType;
        my $r = HTTP::Request->new('GET', $url, $header);
        my $ua = LWP::UserAgent->new();
        my $res = $ua->request($r);
        my $results = JSON::XS::decode_json($res->{_content});
        return $results;
    }

    method getHistoryByAssetTag ($assetTag, $itemType = 'asset') {
        my $hardwareID = ($self->getHardwareIDByAssetTag($assetTag));
        return $self->getHistoryByHardwareID($hardwareID);
    }

    method searchHardware ($searchString) {
        my $url = $endpoint."hardware?search=".$searchString;
        my $r = HTTP::Request->new('GET', $url, $header);
        my $ua = LWP::UserAgent->new();
        my $res = $ua->request($r);
        my $results = JSON::XS::decode_json($res->{_content});

        return $results;
    }

    method getHardwareByCategory ($searchString) {
        my $url = $endpoint."hardware?category_id=".$searchString;
        my $r = HTTP::Request->new('GET', $url, $header);
        my $ua = LWP::UserAgent->new();
        my $res = $ua->request($r);
        my $results = JSON::XS::decode_json($res->{_content});

        return $results;
    }
}

1;