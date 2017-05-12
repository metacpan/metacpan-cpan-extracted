package WebService::Dropbox::Files::UploadSession;
use strict;
use warnings;
use parent qw(Exporter);

our @EXPORT = do {
    no strict 'refs';
    grep { $_ !~ qr{ \A [A-Z]+ \z }xms } keys %{ __PACKAGE__ . '::' };
};

sub upload_session {
    my ($self, $path, $content, $optional_params, $limit) = @_;

    $limit ||= 4 * 1024 * 1024; # A typical chunk is 4 MB

    my $session_id;
    my $offset = 0;

    my $commit_params = {
        path => $path,
        %{ $optional_params || {} },
    };

    my $upload;
    $upload = sub {
        my $buf;
        my $total = 0;
        my $chunk = 1024;
        my $tmp = File::Temp->new;
        my $is_last;
        while (my $read = read($content, $buf, $chunk)) {
            $tmp->print($buf);
            $total += $read;
            my $remaining = $limit - $total;
            if ($chunk > $remaining) {
                $chunk = $remaining;
            }
            unless ($chunk) {
                last;
            }
        }

        $tmp->flush;
        $tmp->seek(0, 0);

        # finish or small file
        if ($total < $limit) {
            if ($session_id) {
                my $params = {
                    cursor => {
                        session_id => $session_id,
                        offset     => $offset,
                    },
                    commit => $commit_params,
                };
                return $self->upload_session_finish($tmp, $params);
            } else {
                return $self->upload($path, $tmp, $commit_params);
            }
        }

        # append
        elsif ($session_id) {
            my $params = {
                cursor => {
                    session_id => $session_id,
                    offset     => $offset,
                },
            };
            unless ($self->upload_session_append_v2($tmp, $params)) {
                # some error
                return;
            }
            $offset += $total;
        }

        # start
        else {
            my $res = $self->upload_session_start($tmp);
            if ($res && $res->{session_id}) {
                $session_id = $res->{session_id};
                $offset = $total;
            } else {
                # some error
                return;
            }
        }

        $upload->();
    };
    $upload->();
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-start
sub upload_session_start {
    my ($self, $content, $params) = @_;

    $self->api({
        url => 'https://content.dropboxapi.com/2/files/upload_session/start',
        params => $params,
        content => $content,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-append_v2
sub upload_session_append_v2 {
    my ($self, $content, $params) = @_;

    $self->api({
        url => 'https://content.dropboxapi.com/2/files/upload_session/append_v2',
        params => $params,
        content => $content,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-finish
sub upload_session_finish {
    my ($self, $content, $params) = @_;

    $self->api({
        url => 'https://content.dropboxapi.com/2/files/upload_session/finish',
        params => $params,
        content => $content,
    });
}

1;
