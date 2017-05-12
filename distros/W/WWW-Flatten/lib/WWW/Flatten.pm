package WWW::Flatten;
use strict;
use warnings;
use utf8;
use 5.010;
use Mojo::Base 'WWW::Crawler::Mojo';
use Mojo::Util qw(md5_sum);
use Mojo::File;
use Mojo::Log;
use WWW::Crawler::Mojo::ScraperUtil qw{resolve_href guess_encoding};
use Encode;
our $VERSION = '0.09';

my $html_type_regex = qr{^(text|application)/(html|xml|xhtml)};
my $css_type_regex = qr{^text/css$};
my $types = {
    'application/atom+xml'      => 'atom',
    'application/font-woff'     => 'woff',
    'application/javascript'    => 'js',
    'application/json'          => 'json',
    'application/pdf'           => 'pdf',
    'application/rss+xml'       => 'rss',
    'application/x-gzip'        => 'gz',
    'application/xml'           => 'xml',
    'application/zip'           => 'zip',
    'audio/mpeg'                => 'mp3',
    'audio/ogg'                 => 'ogg',
    'image/gif'                 => 'gif',
    'image/jpeg'                => 'jpg',
    'image/png'                 => 'png',
    'image/svg+xml'             => 'svg',
    'image/x-icon'              => 'ico',
    'text/cache-manifest'       => 'appcache',
    'text/css'                  => 'css',
    'text/html'                 => 'html',
    'text/plain'                => 'txt',
    'text/xml'                  => 'xml',
    'video/mp4'                 => 'mp4',
    'video/ogg'                 => 'ogv',
    'video/webm'                => 'webm',
};

has depth => 10;
has filenames => sub { {} };
has 'basedir';
has is_target => sub { sub { 1 } };
has 'normalize';
has asset_name => sub { asset_number_generator(6) };
has _retrys => sub { {} };
has max_retry => 3;
has 'log_name';
has 'log';

sub asset_number_generator {
    my $digit = (shift || 6);
    my $num = 0;
    return sub {
        return sprintf("%0${digit}d", $num++);
    };
}

sub asset_hash_generator {
    my $len = (shift || 6);
    my %uniq;
    return sub {
        my $md5 = md5_sum(shift->url);
        my $len = $len;
        my $key;
        do { $key = substr($md5, 0, $len++) } while (exists $uniq{$key});
        $uniq{$key} = undef;
        return $key;
    };
}

sub init {
    my ($self) = @_;
    
    $self->log(Mojo::Log->new(
        path => $self->basedir. $self->log_name)) if $self->log_name;
    
    for (keys %{$self->filenames}) {
        $self->enqueue($_);
        if (!ref $_) {
            my $val = $self->filenames->{$_};
            delete $self->filenames->{$_};
            $self->filenames->{Mojo::URL->new($_)} = $val;
        }
    }
    
    $self->on(res => sub {
        my ($self, $scrape, $job, $res) = @_;

        $self->say_progress;
        
        return unless $res->code == 200;
        
        for my $job2 ($scrape->()) {
            
            next unless ($self->is_target->($job2));
            next unless ($job2->depth <= $self->depth);
            
            my $url = $job2->url;
            
            if (my $cb = $self->normalize) {
                $job2->url($url = $cb->($url));
            }
            
            next if ($self->filenames->{$url});
            
            my $new_id = $self->asset_name->($job2);
            my $type = $self->ua->head($url)->res->headers->content_type || '';
            my $ext1 = $types->{ lc(($type =~ /([^;]*)/)[0]) };
            my $ext2 = ($url->path =~ qr{\.(\w+)$})[0];
            my $ext = $ext1 || $ext2;
            $new_id .= ".$ext" if $ext;
            $self->filenames->{$url} = $new_id;
            
            next if $type !~ $html_type_regex && $type !~ $css_type_regex
                                                && -f $self->basedir. $new_id;
            
            $self->enqueue($job2);
        }
        
        my $url = $job->url;
        my $type = $res->headers->content_type;
        my $original = $job->original_url;
        my $save_file = $self->filenames->{$original};
        
        if ($type && $type =~ $html_type_regex) {
            my $encode = guess_encoding($res) || 'UTF-8';
            my $cont = Mojo::DOM->new(Encode::decode($encode, $res->body));
            my $base = $url;
            
            if (my $base_tag = $cont->at('base')) {
                $base = resolve_href($base, $base_tag->attr('href'));
            }
            
            $self->flatten_html($cont, $base, $save_file);
            $cont = $cont->to_string;
            $self->save($original, $cont, $encode);
        } elsif ($type && $type =~ $css_type_regex) {
            my $encode = guess_encoding($res) || 'UTF-8';
            my $cont = $self->flatten_css($res->body, $url, $save_file);
            $self->save($original, $cont, $encode);
        } else {
            $self->save($original, $res->body);
        }
        
        $self->log->info(
            sprintf('created: %s => %s ', $save_file, $original)) if $self->log;
    });
    
    $self->on(error => sub {
        my ($self, $msg, $job) = @_;
        
        $self->log->error("$msg: ". $job->url) if $self->log;
        
        my $md5 = md5_sum($job->url->to_string);
        if (++$self->_retrys->{$md5} < $self->max_retry) {
            $self->requeue($job);
            $self->log->warn("Re-scheduled: ". $job->url) if $self->log;
        } else {
            my $times = $self->max_retry;
            $self->log->error("Failed $times times: ". $job->url) if $self->log;
        }
    });
    
    $self->SUPER::init;
}

sub get_href {
    my ($self, $base, $url, $ref_path) = @_;
    my $fragment = ($url =~ qr{(#.+)})[0] || '';
    my $abs = resolve_href($base, $url);
    if (my $cb = $self->normalize) {
        $abs = $cb->($abs);
    }
    my $file = $self->filenames->{$abs};
    return $abs. $fragment unless $file;
    my $path = Mojo::File->new($file)->to_rel(
                                Mojo::File->new($ref_path || '')->dirname);
    $path =~ s{\\}{/}g if $^O eq 'MSWin32';
    return $path. $fragment if ($file);
}

sub flatten_html {
    my ($self, $dom, $base, $ref_path) = @_;
    
    state $handlers = $self->html_handlers();
    $dom->find(join(',', keys %{$handlers}))->each(sub {
        my $dom = shift;
        for ('href', 'ping','src','data') {
            $dom->{$_} = $self->get_href($base, $dom->{$_}, $ref_path) if ($dom->{$_});
        }
    });
    
    $dom->find('meta[content]')->each(sub {
        if ($_[0] =~ qr{http\-equiv="?Refresh"?}i && $_[0]->{content}) {
            $_[0]->{content} =~
                            s{URL=(.+)}{ 'URL='. $self->get_href($base, $1, $ref_path) }e;
        }
    });

    
    $dom->find('base')->each(sub {shift->remove});
    
    $dom->find('style')->each(sub {
        my $dom = shift;
        my $cont = $dom->content;
        $dom->content($self->flatten_css($cont, $base, $ref_path));
    });
    
    $dom->find('[style]')->each(sub {
        my $dom = shift;
        my $cont = $dom->{style};
        $dom->{style} = $self->flatten_css($dom->{style}, $base, $ref_path);
    });
    return $dom
}

sub flatten_css {
    my ($self, $cont, $base, $ref_path) = @_;
    $cont =~ s{url\((.+?)\)}{
        my $url = $1;
        $url =~ s/^(['"])// && $url =~ s/$1$//;
        'url('. $self->get_href($base, $url, $ref_path). ')';
    }egi;
    return $cont;
}

sub save {
    my ($self, $url, $content, $encode) = @_;
    my $path =  Mojo::File->new($self->basedir. $self->filenames->{$url});
    $path->dirname->make_path unless -d $path->dirname;
    $content = Encode::encode($encode, $content) if $encode;
    $path->spurt($content);
}

sub say_start {
    my $self = shift;
    
    my $content = <<"EOF";
----------------------------------------
Crawling is starting with @{[ $self->queue->next->url ]}
Max Connection  : @{[ $self->max_conn ]}
User Agent      : @{[ $self->ua_name ]}
----------------------------------------
EOF
    say $content;

    if ($self->log) {
        $self->log->append($content);
        
        my $path =  Mojo::File->new($self->log->path)->to_abs;
        
        say <<EOF;
This could take a while. You can run the following command on another shell to track the status:

  tail -f $path
EOF
    }
}

sub say_progress {
    local $| = 1;
    my $self = shift;
    my $len = $self->queue->length;
    print sprintf('%s jobs left', $len), ' ' x 30, "\r";
}

1;

=head1 NAME

WWW::Flatten - Flatten a web pages deeply and make it portable

=head1 SYNOPSIS

    use strict;
    use warnings;
    use utf8;
    use 5.010;
    use WWW::Flatten;
    
    my $basedir = './github/';
    mkdir($basedir);
    
    my $bot = WWW::Flatten->new(
        basedir => $basedir,
        max_conn => 1,
        max_conn_per_host => 1,
        depth => 3,
        filenames => {
            'https://github.com' => 'index.html',
        },
        is_target => sub {
            my $uri = shift->url;
            
            if ($uri =~ qr{\.(css|png|gif|jpeg|jpg|pdf|js|json)$}i) {
                return 1;
            }
            
            if ($uri->host eq 'assets-cdn.github.com') {
                return 1;
            }
            
            return 0;
        },
        normalize => sub {
            my $uri = shift;
            ...
            return $uri;
        }
    );
    
    $bot->crawl;

=head1 DESCRIPTION

WWW::Flatten is a web crawling tool for freezing pages into standalone.

This software is considered to be alpha quality and isn't recommended for regular usage.

=head1 ATTRIBUTES

=head2 depth

Depth limitation. Defaults to 10.

    $ua->depth(10);

=head2 filenames

URL-Filename mapping table. This well automatically be increased during crawling
but you can pre-define some beforehand.

    $bot->finenames({
        'http://example.com/index.html' => 'index.html',
        'http://example.com/index2.html' => 'index2.html',
    })

=head2 basedir

A directory path for output files.

    $bot->basedir('./out');

=head2 is_target

Set the condition which indecates whether the job is flatten target or not.

    $bot->is_target(sub {
        my $job = shift;
        ...
        return 1 # or 0
    });

=head2 'normalize'

A code reference which perform normalization for URLs. The callback will take
L<Mojo::URL> instance.

    $bot->normalize(sub {
        my $url = shift;
        my $modified = ...;
        return $modified;
    });

=head2 asset_name

A code reference that generates asset names. Defaults to a preset generator
asset_number_generator, which generates 6 digit number. There provides
another option asset_hash_generator, which generates 6 character hash.

    $bot->asset_name(WWW::Flatten::asset_hash_generator(6));

=head2 max_retry

Max attempt limit of retry in case the server in inresponsible. Defaults to 3.

=head1 METHODS

=head2 asset_number_generator

Numeric file name generating closure with self containing storage. See also
L<asset_name> attribute.

    $bot->asset_name(WWW::Flatten::asset_number_generator(3));

=head2 asset_hash_generator

Hash-based file name generating closure with self containing storage. See also
L<asset_name> attribute. This function automatically avoid name collision by
extending the given length.

If you want the names as short as possible, use the following setting.

    $bot->asset_name(WWW::Flatten::asset_hash_generator(1));

=head2 init

Initialize the crawler

=head2 get_href

Generate new href with old one.

=head2 flatten_html

Replace URLs in a Mojo::DOM instance, according to filenames attribute.

=head2 flatten_css

Replace URLs in a CSS string, according to filenames attribute.

=head2 save

Save HTTP response into a file.

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) jamadam

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
