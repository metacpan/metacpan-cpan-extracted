package WWW::Spinn3r::next_request_url;
use base WWW::Spinn3r::Common;
use XML::Twig;
use utf8;

sub new { 

    my ($class, %args) = @_;
    my $self = bless { %args }, $class;

    my $twig = new XML::Twig ( 
        expand_external_ents => 0, 
        twig_roots => { 
            'api:next_request_url' => sub { $self->next_request_url(@_) },
        },
        pretty_print => '',
    );

    $self->{results}->{'api:next_request_url'} = '';

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
        $self->debug("xml = \"${$args{stringref}}\"");
        die $@;
    }

    my $howlong = $self->howlong($start);
    $self->debug("$class: parse complete in $howlong seconds");

    $twig->purge;  # clean up all the memory.

    return $self->{results};
}

sub next_request_url { 

    my ($self, $twig, $root) = @_;
    my $url = $root->text;
    $self->{results}->{'api:next_request_url'} = $url;
    $twig->finish;  # no more parsing!
    return;

}

1;
