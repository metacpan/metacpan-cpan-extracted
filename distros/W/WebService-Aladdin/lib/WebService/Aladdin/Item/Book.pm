package WebService::Aladdin::Item::Book;

use strict;
use warnings;

use base qw(WebService::Aladdin::Item);

__PACKAGE__->mk_accessors(qw/bookinfo/);

sub init {
    my ($self, $info) = @_;

    my $data;
    foreach my $key (keys %{ $info }) {
        my $type = $key;
        $type =~ s/^aladdin://;
        if ($type eq 'authors') {
            my $author = $info->{'aladdin:authors'}->{'aladdin:author'};
            if (ref($author) eq 'HASH') {
                $data->{author} = {
                    authorid   => $author->{'-authorid'},
                    authorType => $author->{'-authorType'},
                    text       => $author->{'#text'},
                    desc       => $author->{'-desc'},
                };
	        }
            elsif (ref($author) eq 'ARRAY') {
                foreach my $p (@{ $info->{'aladdin:authors'}->{'aladdin:author'} }) {
                    unshift @{ $data->{$type} }, {
                        authorid   => $p->{'-authorid'},
                        authorType => $p->{'-authorType'},
                        text       => $p->{'#text'},
                        desc       => $p->{'-desc'},
                    };
                }
            }
        }
        else {
            $data->{$type} = $info->{$key};
        }
    }
    $self->bookinfo($data);
}

1;
