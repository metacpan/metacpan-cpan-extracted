package meon::Web::Util;

use Text::Unidecode 'unidecode';
use Path::Class 'dir', 'file';
use XML::LibXML::XPathContext;
use Carp 'croak';
use Run::Env;
use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use File::MimeInfo 'mimetype';
use Encode;

sub xpc {
    my $xpc = XML::LibXML::XPathContext->new;
    $xpc->registerNs('x', 'http://www.w3.org/1999/xhtml');
    $xpc->registerNs('w', 'http://web.meon.eu/');
    return $xpc;
}

sub filename_cleanup {
    my ($self, $text) = @_;
    $text = unidecode($text);
    $text =~ s/\s/-/g;
    $text =~ s/-+/-/g;
    $text =~ s/[^A-Za-z0-9\-_]//g;
    return $text;
}

sub to_ident {
	my ($self, $text) = @_;

	$text = unidecode($text);
	$text =~ s/[^-A-Za-z0-9]/-/g;
	$text =~ s/--+/-/g;
	$text =~ s/-$//g;
	$text =~ s/^-//g;
	$text = substr($text,0,30);

	return $text;
}

sub username_cleanup {
    my ($self, $username, $folder) = @_;

    $username = unidecode($username);
    $username =~ s/[,;]/-/g;
    $username =~ s/[^A-Za-z0-9-.]//g;
    while (length($username) < 4) {
        $username .= 'x';
    }

    my $base_username = $username;
    my $i = 1;
    while (-d dir($folder, $username)) {
        $i++;
        my $suffix = sprintf('%02d', $i);
        $username = $base_username.$suffix;
    }

    return $username;
}

sub path_fixup {
    my ($self, $path) = @_;

    my $username = (
        meon::Web::env->user
        ? $username = meon::Web::env->user->username
        : 'anonymous'
    );

    $path =~ s/{\$USERNAME}/$username/;

    if ($path =~ m/^(.*){\$TIMELINE_NEWEST}/) {
        my $base_dir = dir(meon::Web::env->current_dir, (defined($1) ? $1 : ()));
        my $dir = $base_dir;
        while (my @subfolders = sort grep { $_->basename =~ m/^\d+$/ } grep { $_->is_dir } $dir->children(no_hidden => 1)) {
            $dir = pop(@subfolders);
        }
        $dir = $dir->relative($base_dir);
        $dir .= '';
        $path =~ s/{\$TIMELINE_NEWEST}/$dir/;
    }

    if ($path =~ m/{\$COMMENT_TO}/) {
        my $comment_to = meon::Web::env->stash->{comment_to};
        $path =~ s/{\$COMMENT_TO}/$comment_to/;
    }

    return $path;
}

sub full_path_fixup {
    my ($self, $path) = @_;
    $path = $self->path_fixup($path);
    my $cur_dir = meon::Web::env->current_dir;
    $cur_dir = meon::Web::env->content_dir
        if $path =~ m{^/};
    $path = file($cur_dir, $path)->absolute;
}

sub send_email {
    my ($class, %args) = @_;

    my $from    = $args{from} // croak 'need from';
    my $to      = $args{to} // croak 'need to';
    my $bcc     = $args{bcc};
    my $subject = $args{subject} // croak 'need subject';
    my $text    = $args{text} // croak 'need text';
    my @attachments = @{ $args{attachments} // [] };

    my @email_headers = (
        header_str => [
            From    => $from,
            To      => $to,
            ($bcc && !Run::Env->prod ? (Bcc => $bcc) : ()),
            Subject => $subject,
        ],
    );
    my @email_text = (
        attributes => {
            content_type => "text/plain",
            charset      => "UTF-8",
            encoding     => "8bit",
        },
        body_str => $text,
    );

    my $email;
    if (@attachments) {
        $email = Email::MIME->create(
            @email_headers,
            parts => [
                Email::MIME->create(@email_text),
                (
                    map {
                        my $filename = file(
                            ref($_) eq 'HASH'
                            ? $_->{filename}
                            : $_
                        );
                        my $basename = $filename->basename;
                        my $content_type = (
                            ref($_) eq 'HASH'
                            ? $_->{content_type}
                            : undef
                        ) // mimetype($basename) // 'application/octet-stream';
                        Email::MIME->create(
                            attributes => {
                                filename     => $basename,
                                content_type => $content_type,
                                encoding     => "base64",
                                name         => $basename,
                            },
                            body => IO::Any->slurp($filename),
                        );
                    } @attachments
                ),
            ],
        );
    }
    else {
        $email = Email::MIME->create(
            @email_headers,
            @email_text,
        );
    }

    if (Run::Env->prod) {
        sendmail($email->as_string, { to => $bcc })
            if $bcc;
        sendmail($email->as_string);
    }
    else {
        warn $email->as_string;
    }
}

sub fix_cell_value {
	my ($class, $cell) = @_;

	return undef unless $cell;
	my $cell_value = $cell->unformatted;
	if (($cell->encoding == 1) && (!Encode::is_utf8($cell_value))) {
		$cell_value = Encode::decode('windows-1252',$cell_value);
	}
	else {
		$cell_value = $cell->value;
	}

	return $cell_value;
}

1;
