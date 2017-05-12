use strict;
use warnings;
package WWW::Sitemapper;
BEGIN {
  $WWW::Sitemapper::AUTHORITY = 'cpan:AJGB';
}
{
  $WWW::Sitemapper::VERSION = '1.121160';
}
#ABSTRACT: Create text, html and xml sitemap by scanning a web site.

use Moose;
use WWW::Sitemapper::Types qw( tURI tDateTime tDateTimeDuration );
use WWW::Sitemapper::Tree;
use URI;
use DateTime;
use DateTime::Duration;
use WWW::Robot;
use WWW::Sitemap::XML;
use WWW::Sitemap::XML::URL;
use Storable qw( store retrieve );
use HTML::HeadParser;
use Encode ();

BEGIN {
    extends qw( MooseX::MethodAttributes::Inheritable );
};



has 'site' => (
    is => 'rw',
    isa => tURI,
    lazy_build => 1,
    coerce => 1,
);


has 'tree' => (
    is => 'rw',
    isa => 'WWW::Sitemapper::Tree',
    lazy_build => 1,
);

sub _build_tree {
    my $self = shift;

    my $root = WWW::Sitemapper::Tree->new(
        uri => $self->site,
        id => '0',
    );

    $root->add_to_dictionary( $self->site => \$root );

    return $root;
}


has 'robot_config' => (
    is => 'rw',
    isa => 'HashRef',
    lazy_build => 1,
);

has '_robot' => (
    is => 'ro',
    isa => 'WWW::Robot',
    lazy_build => 1,
);

sub _build_robot_config {
    my $self = shift;
    return {};
}

sub _build__robot {
    my $self = shift;
    my %opts = (
        VERSION => $WWW::Sitemapper::VERSION,
        TRAVERSAL => 'breadth',
        NAME => ref $self,
        %{$self->robot_config}
    );
    return WWW::Robot->new(
        %opts
    );
}


has 'status_storage' => (
    is => 'rw',
    isa => 'Str',
);


has 'auto_save' => (
    is => 'rw',
    isa => tDateTimeDuration,
    coerce => 1,
    default => sub { DateTime::Duration->new( minutes => 0 ) },
);

has '_last_saved_time' => (
    is => 'rw',
    isa => tDateTime,
    coerce => 1,
);


has 'run_started_time' => (
    is => 'rw',
    isa => tDateTime,
    coerce => 1,
);


has 'html_sitemap_template' => (
    is => 'rw',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_html_sitemap_template {
    my $self = shift;

    return <<'EOT';
<html>
<head>
<title>Sitemap for [% mapper.site.host %]</title>
</head>
<body>
<ul>
[%- INCLUDE branch node = mapper.tree -%]
</ul>
</body>
</html>

[%- BLOCK branch -%]
<li><a href="[% node.loc %]">[% node.title || node.loc %]</a>
[%     IF node.children.size -%]
<ul>
[%-
            FOREACH child IN node.children;
                INCLUDE branch node = child;
            END;
-%]
</ul>
[%     END -%]
</li>
[% END -%]
EOT

}




sub run {
    my $self = shift;

    $self->_robot->addUrl( $self->site );

    for my $method ( $self->meta->get_all_methods_with_attributes ) {
        my $attrs = $method->attributes;
        my %attrs = ();
        for my $attr ( @$attrs ) {
            if (my($func,$param) = $attr =~ /^(\w+)\s*\(\W?(.*?)\W\)$/s) {
                $attrs{$func} = $param;
            }
        }
        if ( my $hook_name = delete $attrs{Hook} ) {
            my $method_name = $method->name;
            $self->_robot->addHook(
                $hook_name,
                sub {
                    $self->$method_name(@_);
                }
            );
        };
    }

    $self->_last_saved_time( DateTime->now );
    $self->run_started_time( DateTime->now );

    return $self->_robot->run();
}


sub txt_sitemap {
    my ($self, %args) = @_;

    sub _txt_sitemap {
        my ($node, $indent, %args) = @_;
        my $txt = '';

        $txt .= sprintf "%s%s %s%s\n",
            "  " x $indent,
            ( $args{with_id} ? '['. $node->id .']' : '*' ),
            $node->loc,
            ( $args{with_title} ? ' '. ($node->title || '') : '' );
        for my $child ( $node->children ) {
            $txt .= _txt_sitemap($child, $indent + 1, %args);
        }
        return $txt;
    }

    return _txt_sitemap($self->tree, 0, %args);
}



sub html_sitemap {
    my $self = shift;

    my %tt_opts = (
        RECURSION => 1,
        @_
    );

    require Template;

    my $tt = Template->new( \%tt_opts );

    my $html;

    no warnings 'recursion';
    $tt->process( \( $self->html_sitemap_template ),
        {
            mapper => $self,
        },
        \$html
    ) or die $tt->error();

    return $html;
}


sub xml_sitemap {
    my $self = shift;
    my %args = @_;

    no warnings 'recursion';

    my %RULES;
    my %DEFAULT = (
        priority => 0.5,
        changefreq => 'weekly',
        split_by => qr{.},
    );
    my ($priority, $changefreq);
    my $process_priority = sub {
        my $rules = shift;
        while ( my ($re, $val) = each %{ $rules } ) {
            if (ref $re ne 'Regexp' ) {
                $re = qr{$re};
            }
            if ( $val =~ /^([\-\+])?(\d+(?:\.\d+)?)$/ ) {
                if ( $1 ) { # modifier
                    push @{ $RULES{priority}->{MOD} },
                        { $re => sprintf("%f", $val) };
                } else {
                    push @{ $RULES{priority}->{DEFAULT} },
                        { $re => sprintf("%f", $2) };
                }
            } else {
                die "Invalid priority $val\n";
            }
        }
    };

    if ( my $priority = delete $args{priority} ) {
        if ( ref $priority eq 'HASH' ) {
            $process_priority->( $priority );
        } elsif ( ref $priority eq 'ARRAY' ) {
            for my $rule ( @{ $priority } ) {
                if ( ref $rule eq 'HASH' ) {
                    $process_priority->( $rule );
                } else {
                    die "Invalid priority $rule\n";
                }
            }
        } elsif ( ! ref $priority ) {
            $process_priority->( { qr{.} => sprintf("%f", $priority) } );
        } else {
            die "Invalid value for priority: ", ref $priority, "\n";
        }
    }

    my %VALID_CFRQ = map { $_ => 1 } qw(
        always
        hourly
        daily
        weekly
        monthly
        yearly
        never
    );
    my $process_changefreq = sub {
        my $rules = shift;
        while ( my ($re, $val) = each %{ $rules } ) {
            if (ref $re ne 'Regexp' ) {
                $re = qr{$re};
            }
            if ( exists $VALID_CFRQ{lc $val} ) {
                push @{ $RULES{changefreq}->{DEFAULT} },
                    { $re => lc $val };
            } else {
                die "Invalid changefreq $val\n";
            }
        }
    };


    if ( my $changefreq = delete $args{changefreq} ) {
        if ( ref $changefreq eq 'HASH' ) {
            $process_changefreq->( $changefreq );
        } elsif ( ref $changefreq eq 'ARRAY' ) {
            for my $rule ( @{ $changefreq } ) {
                if ( ref $rule eq 'HASH' ) {
                    $process_changefreq->( $rule );
                } else {
                    die "Invalid changefreq $rule\n";
                }
            }
        } elsif ( ! ref $changefreq ) {
            $process_changefreq->( { qr{.} => $changefreq } );
        } else {
            die "Invalid value for changefreq: ", ref $changefreq, "\n";
        }
    }

    if ( my $split_by = delete $args{split_by} ) {
        if ( ref $split_by eq 'ARRAY' ) {
            for my $entry ( @$split_by ) {
                push @{ $RULES{SPLIT} },
                    ref $entry eq 'Regexp' ? $entry : qr{$entry};
            }
        } else {
            die "Invalid value for split_by: $split_by\n";
        }
    }
    push @{ $RULES{SPLIT} }, $DEFAULT{split_by};

    my @maps = map {
        $RULES{SPLIT}->[$_] => WWW::Sitemap::XML->new()
    } 0 .. @{ $RULES{SPLIT} } - 1;


    for my $split_rule ( @{ $RULES{SPLIT} } ) {
        for my $node_ref ( $self->tree->all_entries ) {
            my $priority;
            my $changefreq;
            my $url = $$node_ref->loc->as_string;
            my $loc = $url;
            $loc =~ s|^.*?\/\/.*?\/|\/|;

            my %conf = (
                loc => $url,
            );

            if ( my $lastmod = $$node_ref->last_modified ) {
                $conf{lastmod} = $lastmod->strftime('%FT%T%z');
                $conf{lastmod} =~ s/(\d{2})$/:$1/;
            }
            if ( $RULES{priority} ) {
                my $default = $DEFAULT{priority};
                my $modifiers = 0;
                for my $rule ( @{ $RULES{priority}->{DEFAULT} } ) {
                    while ( my ($re, $val) = each %{ $rule } ) {
                        if ( $loc =~ /$re/ ) {
                            $default = $val;
                        }
                    }
                }

                for my $rule ( @{ $RULES{priority}->{MOD} } ) {
                    while ( my ($re, $val) = each %{ $rule } ) {
                        if ( $loc =~ /$re/ ) {
                            $modifiers = $modifiers + $val;
                        }
                    }
                }
                $priority = sprintf("%.1f", $default + $modifiers);
                $priority = '0.0' if $priority < 0;
                $priority = '1.0' if $priority > 1;
            }

            if ( $RULES{changefreq} ) {
                my $default = $DEFAULT{changefreq};
                for my $rule ( @{ $RULES{changefreq}->{DEFAULT} } ) {
                    while ( my ($re, $val) = each %{ $rule } ) {
                        if ( $loc =~ /$re/ ) {
                            $default = $val;
                        }
                    }
                }
                $changefreq = $default;
            }

            $conf{priority} = $priority || $DEFAULT{priority};
            $conf{changefreq} = $changefreq || $DEFAULT{changefreq};

            for (my $i = 0; $i < @maps; $i += 2) {
                my ($re, $map) = @maps[ $i .. $i+1];
                if ( $loc =~ /$re/ ) {
                    $map->add( WWW::Sitemap::XML::URL->new(%conf) );
                    last;
                }
            }
        }
    }

    return pop @maps if @maps == 2;
    return map { $maps[ $_ * 2 + 1 ] } 0 .. int(@maps/2) - 1;
}


sub restore_state : Hook('restore-state') {
    my $self = shift;

    if ( $self->status_storage && -e $self->status_storage ) {
        my %state = %{ retrieve( $self->status_storage ) };
        $self->_robot->{$_} = $state{ROBOT}->{$_} for qw( URL_LIST SEEN_URL );
        $self->tree( $state{TREE} );

        return 1;
    }

    return 0;
}


sub save_state : Hook('save-state') {
    my $self = shift;
    my($robot) = @_;

    if ( $self->status_storage ) {
        my %state = (
            ROBOT => {
                URL_LIST => $robot->{URL_LIST},
                SEEN_URL => $robot->{SEEN_URL},
            },
            TREE => $self->tree,
        );

        store \%state, $self->status_storage;

        return 1;
    }

    return 0;

}

# if there was other then continue-tests hook available in WWW::Robots run()
# it would be used
sub _auto_save : Hook('invoke-on-all-url') {
    my $self = shift;

    if ( $self->status_storage && $self->auto_save->is_positive) {
        if (
            DateTime->compare(
                DateTime->now,
                $self->_last_saved_time + $self->auto_save
            ) > 0
        ) {
            $self->save_state( @_ );
            $self->_last_saved_time( DateTime->now );
        }

        return 1;
    }

    return 0;
}

# creates a map of links
sub _map_builder : Hook('invoke-on-link') {
    my $self = shift;
    my ($robot, $hook_name, $from_url, $to_url) = @_;

    return unless $robot->invoke_hook_functions( 'follow-url-test', $to_url );

    $from_url = URI->new( $from_url->as_string );
    $to_url = URI->new( $to_url->as_string );

    my $parent = $self->tree->redirected_from( $from_url )
                || $self->tree->find_node( $from_url )
                || $self->tree;

    unless ( $self->tree->find_node( $to_url ) ) {
        my $link = $parent->add_node(
            WWW::Sitemapper::Tree->new(
                uri => $to_url,
            )
        );
        $self->tree->add_to_dictionary( $to_url => \$link );

        return 1;
    };

    return 0;
}

# update node info
# if the target url redirects to a different page map it
sub _set_page_data : Hook('invoke-after-get') {
    my $self = shift;
    my ($robot, $hook, $url, $response) = @_;

    $url = URI->new( $url->as_string );

    if ( my $node = $self->tree->find_node( $url ) ) {

        my $hp = HTML::HeadParser->new;
        $hp->xml_mode(1) if $response->content_is_xhtml;
        $hp->utf8_mode(1) if $] >= 5.008 && $HTML::Parser::VERSION >= 3.40;

        $hp->parse($response->content);
        if ( my $title = $hp->header('title') ) {
            $node->title( Encode::decode($response->content_charset, $title) );
        }
        if ( my $last_modified = $response->headers->last_modified ) {
            $node->last_modified( $last_modified );
        }

        if ( scalar $response->redirects ) {
            $node->_base_uri( URI->new( $response->base ) );
            # add redirected to queue
            $self->tree->store_redirect( $response->base->as_string => \$node );
            $robot->addUrl( $response->base );
        }

        return 1;
    }

    return 0;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

WWW::Sitemapper - Create text, html and xml sitemap by scanning a web site.

=head1 VERSION

version 1.121160

=head1 SYNOPSIS

WWW::Sitemapper is meant to be subclassed by user:

    package MyWebSite::Map;
    use Moose;

    use base qw( WWW::Sitemapper );

    # define attributes for your class
    has 'restricted_pages' => (
        is => 'ro',
        isa => 'ArrayRef[RegexpRef]',
        default => sub {
            [
                qr{^/cat/login},
                qr{^/cat/events},
                qr{\?_search_string=},
            ]
        },
    );

    # configuration options for WWW::Robot
    sub _build_robot_config {
        my $self = shift;

        return {
            NAME => 'MyRobot',
            EMAIL => 'me@domain.tld',
        };
    }

    # you need to provide a follow-url-test hook in your subclass
    sub url_test : Hook('follow-url-test') {
        my $self = shift;
        my ($robot, $hook_name, $uri) = @_;

        my $url = $uri->path_query;

        if ( $self->site->host eq $uri->host ) {
            for my $re ( @{ $self->restricted_pages } ) {
                if ( $url =~ /$re/ ) {
                    return 0;
                }
            }

            return 1;
        }

        return 0;
    }

    # you can add your own hooks as well
    sub run_till_first_auto_save : Hook('continue-test') {
        my $self = shift;
        my ($robot) = @_;

        if ( $self->run_started_time + $self->auto_save < DateTime->now ) {
            return 0;
        }
        return 1;
    }


    # as this is your class feel free to define your own methods
    sub ping_google {
        my $self    = shift;

        my $ua = LWP::UserAgent;
        return $ua->get( 'http://www.google.com/webmasters/sitemaps/ping',
            sitemap => $self->site .'google-sitemap.xml.gz'
        );
    }

and then

    package main;

    my $mapper = MyWebSite::Map->new(
        site => 'http://mywebsite.com/',
        status_storage => 'sitemap.data',
        auto_save => 10,
    );

    $mapper->run;


    open(HTML, ">sitemap.html") or die ("Cannot create sitemap.html: $!");
    print HTML $mapper->html_sitemap;
    close(HTML);

    my $xml_sitemap = $mapper->xml_sitemap(
        priority => '0.7',
        changefreq => 'weekly;
    );

    $xml_sitemap->write('google-sitemap.xml.gz');

    # call your own method
    $mapper->ping_google();

and while mapper is still running take a peek what has been mapped so far

    my $mapper = MyWebSite::Map->new(
        site => 'http://mywebsite.com/',
        status_storage => 'sitemap.data',
    );

    $mapper->restore_state();

    print $mapper->txt_sitemap();

=head1 ATTRIBUTES

=head2 site

Home page of the website to be mapped.

isa: L<WWW::Sitemapper::Types/"tURI">.

=head2 tree

Tree structure of the web site.

isa: L<WWW::Sitemapper::Tree>.

Note: each page is mapped only once, so if multiple pages are linking to the
same page only the first will be counted as parent.

Note: beware of pages serving same content under different URLs (eg. using
different query string parameters) as it may lead to circular references.
Besides this search engines will punish you for so called "duplicate content".
Use your subroutine with C<Hook('follow-url-test')> to restrict access to those pages.

=head2 robot_config

L<WWW::Robot> configuration options.

isa: C<HashRef>.

You need to define in your subclass builder method I<_build_robot_config>
which needs to return a hashref.
Most important options are:

=over

=item * EMAIL

Your e-mail address - in case someone wishes to complain about the behaviour
of your robot.

B<mandatory>.

=item * DELAY

Delay between each request in minutes.

Default: I<1>

=back

For more details and other options please see L<WWW::Robot/"ROBOT_ATTRIBUTES">.

=head2 status_storage

Path of status storage file to be used for saving the result of web crawl.
If defined L<Storable> will be used to store the current state.

isa: C<Str>.

=head2 auto_save

Auto save current status every N minutes (defaults to 0 - do not auto save).

isa: L<WWW::Sitemapper::Types/"tDateTimeDuration">.

Note: L<"status_storage"> has to be defined.

=head2 run_started_time

Time when L<"run"> method was called.

isa: L<WWW::Sitemapper::Types/"tDateTime">.

=head2 html_sitemap_template

L<Template-Toolkit|Template> html sitemap template to be used by helper method
L<"html_sitemap">.

isa: C<Str>.

Can be overriden by definining C<_build_html_sitemap_template> in your subclass.

Parameter passed to the template is the main object (I<$self>) named as
I<mapper>.

Default value:

    <html>
    <head>
    <title>Sitemap for [% mapper.site.host %]</title>
    </head>
    <body>
    <ul>
    [%- INCLUDE branch node = mapper.tree -%]
    </ul>
    </body>
    </html>

    [%- BLOCK branch -%]
    <li><a href="[% node.loc %]">[% node.title || node.loc %]</a>
    [%     IF node.children.size -%]
    <ul>
    [%-
                FOREACH child IN node.children;
                    INCLUDE branch node = child;
                END;
    -%]
    </ul>
    [%     END -%]
    </li>
    [% END -%]

=head1 METHODS

=head2 run

    print $mapper->run();

Creates a L<WWW::Robot> object and starts to map the website specified by
L<"site">.

Scans your subclass for methods with C<:Hook('name-of-the-hook')> attributes to
be added to robot object.

You need to define at least one subroutine with I<follow-url-test> hook which
will be used to decide if the page should be followed and added to sitemap.

    sub url_test : Hook('follow-url-test') {
        my $self = shift;
        my ($robot, $hook_name, $uri) = @_;

        my $should_follow = ...

        return $should_follow;
    }

Please see L<WWW::Robot/"SUPPORTED_HOOKS"> for full list of supported hooks.

Note: you can name your subroutines however you want and add other attributes
as well - L<WWW::Sitemapper> looks only for C<Hook(...)> ones.

=head2 txt_sitemap

    print $mapper->txt_sitemap();

Create plain text sitemap. Example output:

    * http://mywebsite.com/
      * http://mywebsite.com/page1.html
        * http://mywebsite.com/page11.html
        * http://mywebsite.com/page12.html
      * http://mywebsite.com/page2.html

Accepts following parameters:

=over

=item with_id => 0|1

    print $mapper->txt_sitemap( with_id => 1 );

Use id of each node instead of I<*>.

Defaults to 0.

=item with_title => 0|1

    print $mapper->txt_sitemap( with_title => 1 );

Add node title after node location.

Defaults to 0.

=back

=head2 html_sitemap

    print $mapper->html_sitemap(%TT_CONF);

Create HTML sitemap using template defined in L<"html_sitemap_template">.

Allows to specify Template-Toolkit configuration options, see
L<Template/"CONFIGURATION_SUMMARY">.

=head2 xml_sitemap

    my $sitemap = $mapper->xml_sitemap();

    # print xml
    print $sitemap->as_xml->sprint;

    # write to file

    $sitemap->write('sitemap.xml');

Create L<XML sitemap|http://www.sitemaps.org>. Returns
L<WWW::Sitemap::XML> object.

Accepts following parameters:

=over

=item * split_by

    my @sitemaps = $mapper->xml_sitemap(
        split_by => [
            '^/doc',
            '^/cat',
            '^/ila',
        ],
    );

Arrayref of regular expressions used to split the final sitemap based on
the page location - L<WWW::Sitemapper::Tree/loc>. If this option is supplied
the L<"xml_sitemap"> will return an array of L<WWW::Sitemap::XML> objects plus
additional one for any urls not matched by conditions provided.

Note: the first matching condition is used.

Note: schema and hostname are remove from node uri for condition matching.

Note: keys could be regexp or strings.

=item * priority

    my $sitemap = $mapper->xml_sitemap(
        priority => 0.6,
    );

or

    my $sitemap = $mapper->xml_sitemap(
        priority => {
            '^/doc/' => '+0.2', # same as 0.7
            '^/ila/' => 0.4,
            '^/cat/' => 0.9,
            '^/$' => 1,
        },
    );

or

    my $sitemap = $mapper->xml_sitemap(
        priority => [
            { '^/doc/' => '+0.2' },
            { '^/ila/' => 0.3    },
            { '^/cat/' => 0.9    },
            { '\.pdf$' => 0.8    }, # all pdfs 0.8 and in /doc/ 1.0
        ],
    );

If priority is a scalar value it will be used as a default for all pages.

Supports I<relative> values which will be added/subtracted to/from final
priority.

If it is a hashref or arrayref all conditions are checked.
In case of I<relative> values all matching ones are combined and in case
of I<absolute> ones the last one is used - use arrayref to I<chain> your
conditions.

Final priority will be set to 0.0 if the calculated one is negative.

Final priority will be set to 1.0 if the calculated one is higher then 1.

Default priority is 0.5.

Note: schema and hostname are remove from node uri for condition matching.

Note: keys could be regexp or string objects.

=item * changefreq

    my $sitemap = $mapper->xml_sitemap(
        changefreq => 'daily',
    );

or

    my $sitemap = $mapper->xml_sitemap(
        changefreq => {
            '^/doc/' => 'weekly',
            '^/ila/' => 'yearly'
            '^/cat/' => 'daily',
            '^/$' => 'always',
        },
    );

or

    my $sitemap = $mapper->xml_sitemap(
        changefreq => [
            { '^/doc/' => 'weekly' },
            { '^/ila/' => 'yearly' },
            { '^/cat/' => 'daily'  },
            { '^/$' => 'always'    },
            { '\.pdf$' => 'never'  }, # pdfs will never change
        ],
    );

If changefreq is a scalar value it will be used as a default for all pages.

If it is a hashref or arrayref all conditions are checked and the last matching one is
used - use arrayref to I<chain> your conditions.

Valid values are:

=over

=item * always

=item * hourly

=item * daily

=item * weekly

=item * monthly

=item * yearly

=item * never

=back

Default changefreq is 'weekly'.

Note: schema and hostname are remove from node uri for condition matching.

Note: keys could be regexp or string objects.

=back

=head1 HOOKED METHODS

=head2 restore_state

    $mapper->restore_state();

Restore state from L<"status_storage"> using L<Storable/"retrieve">.

Loads into current object L<"tree"> and internal state of web robot.

Uses hook L<WWW::Robot/"restore-state">.

=head2 save_state

    $mapper->save_state();

Save into L<"status_storage"> using L<Storable/"store"> current content of
L<"tree"> and internal state of web robot.

Uses hook L<WWW::Robot/"save-state">.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

