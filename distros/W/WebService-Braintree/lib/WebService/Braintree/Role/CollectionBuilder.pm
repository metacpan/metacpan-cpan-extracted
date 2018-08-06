# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::Role::CollectionBuilder;

use 5.010_001;
use strictures 1;

use Moo::Role;

use WebService::Braintree::Util qw(to_instance_array);

use WebService::Braintree::GenericSearch;
use WebService::Braintree::PaginatedCollection;
use WebService::Braintree::PaginatedResult;
use WebService::Braintree::ResourceCollection;

sub resource_collection {
    my ($self, $opts) = @_;

    my ($ids_resp, $search);
    if ($opts->{search}) {
        $search = $opts->{search};
        $ids_resp = $self->gateway->http->post($opts->{ids_url}, {
            search => $search->to_hash,
        });
    }
    else {
        $ids_resp = $self->gateway->http->post($opts->{ids_url});
        $search = WebService::Braintree::GenericSearch->new;
    }

    if ($opts->{post_ids}) {
        $opts->{post_ids}->($ids_resp);
    }

    my $obj_class = $opts->{inflate}[2];
    return WebService::Braintree::ResourceCollection->new({
        response => $ids_resp,
        callback => sub {
            my $ids = shift;
            return [] if scalar @{$ids} == 0;
            $search->ids->in($ids);

            my $response = $self->gateway->http->post($opts->{obj_url}, {
                search => $search->to_hash,
            });
            my $body = $response->{$opts->{inflate}[0]} // {};
            my $attrs = $body->{$opts->{inflate}[1]} // [];
            return to_instance_array($attrs, "WebService::Braintree::${obj_class}");
        },
    });
}

sub paginated_collection {
    my ($self, $opts) = @_;
    my $url = $opts->{url};
    my $obj_class = $opts->{inflate}[2];

    my $method = $opts->{method} // 'get';

    return WebService::Braintree::PaginatedCollection->new({ callback => sub {
        my $page_number = shift;

        my $response;
        if ($opts->{search}) {
            $response = $self->gateway->http->$method(
                "${url}?page=${page_number}", {
                    search => $opts->{search}->to_hash,
                    page => $page_number,
                }
            );
        }
        else {
            $response = $self->gateway->http->$method(
                "${url}?page=${page_number}",
            );
        }

        my $body = $response->{$opts->{inflate}[0]} // {};
        my $attrs = $body->{$opts->{inflate}[1]} // [];
        return WebService::Braintree::PaginatedResult->new({
            total_items => $body->{total_items},
            page_size => $body->{page_size},
            current_page => to_instance_array(
                $attrs, "WebService::Braintree::${obj_class}"
            ),
        });
    }});
}

1;
__END__
