package WWW::Spinn3r::link;
use base WWW::Spinn3r::Common;
use XML::Twig;
use Data::Dumper;
use utf8;

my @SCALAR_FIELDS = qw(
    title link guid pubDate description
    weblog:tier weblog:inranking weblong:indegree weblog:publisher_type weblog:title
    post:date_found  post:content_extract
    dc:source dc:lang
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
            'link' => sub { $self->link(@_) },
        }
    );

    $self->{results}->{link} = [];

    my $start = $self->start_timer;
    $self->debug("$class: parsing XML...");

    eval { 

    if ($args{path}) { 
        $twig->parsefile($args{path});
    } elsif ($args{string}) { 
        $twig->parse($args{string});
    } elsif ($args{stringref}) { 
        $twig->parse(${$args{stringref}});
    }

    }; 

    if ($@) { 
        return; 
    }

    my $howlong = $self->howlong($start);
    $self->debug("$class: parse complete in $howlong seconds");

    $twig->purge;

    return $self->{results};

}


sub link { 

    my ($self, $twig, $root) = @_;
    my $link = $root->text;
    push @{ $self->{results}->{link} }, $url;
    $twig->purge;

}

1;

