package WWW::Spinn3r::item;
use base WWW::Spinn3r::Common;
use XML::Twig;
use Data::Dumper;
use utf8;

my @SCALAR_FIELDS = qw(
    title link guid pubDate description
    weblog:tier weblog:description weblog:iranking weblog:indegree weblog:publisher_type weblog:title
    post:date_found  
    post:content_extract
    dc:source 
    dc:lang
    feed:url
    atom:published
);

my @ARRAY_FIELDS = qw(
    category 
);

my %ATTRS = ( 
    'atom:author' => ['atom:name', 'atom:link', 'atom:email'],
);

sub new { 

    my ($class, %args) = @_;
    my $self = bless { %args }, $class;

    my $twig = new XML::Twig ( 
        expand_external_ents => 0, 
        twig_roots => { 
            item => sub { $self->item(@_) },
            'api:next_request_url' => sub { $self->next_request_url(@_) },
        }
    );

    $self->{results}->{item} = [];

    my $start = $self->start_timer;
    $self->debug("$class: parsing XML...");

    eval { 

    if ($args{path}) { 
        $self->debug("$class: parsing $args{path}...");
        $twig->parsefile($args{path});
    } elsif ($args{string}) { 
        $self->debug("$class: parsing string...");
        $twig->parse($args{string});
    } elsif ($args{stringref}) { 
        $self->debug("$class: parsing stringref...");
        $twig->parse(${$args{stringref}});
    }

    };

    if ($@) { 
        $self->debug("PARSE FAILED!!!! $@");
        if ($args{string}) { 
            my $head = substr $args{string}, 0, 50;
            $self->debug("XML head that failed: $head");
        }
        if ($args{stringref}) { 
            my $head = substr $$args{stringref}, 0, 50;
            $self->debug("XML head that failed: $head");
        }

        return undef;
    }

    my $howlong = $self->howlong($start);
    $self->debug("$class: parse complete in $howlong seconds");

    $twig->purge;

    return $self->{results};

}

sub item { 

    my ($self, $twig, $root) = @_; 
    my %item;
    for (@SCALAR_FIELDS) { 
        my $field = $root->first_child($_);
        if ($field) { 
            $item{$_} = $field->text;
        }
    }
    for my $f (@ARRAY_FIELDS) { 
        my @field = $root->children($f);
        for (@field) {
            push @{ $item{$f} }, $_->text;
        }
    }
    for my $f (keys %ATTRS) {
        my $branch = $root->first_child($f);
        next unless $branch;
        for (@{ $ATTRS{$f} }) { 
            my $sub_branch = $branch->first_child($_);
            if ($sub_branch) { 
                $item{$f}->{$_} = $sub_branch->text;
            }
        }
    }
    push @{ $self->{results}->{item} }, \%item;
    # $twig->purge;

    1;

}

sub next_request_url { 

    my ($self, $twig, $root) = @_;
    my $url = $root->text;
    $self->{results}->{'api:next_request_url'} = $url;
    $twig->purge;

    1;

}

1;

