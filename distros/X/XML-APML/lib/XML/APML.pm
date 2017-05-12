package XML::APML;

use strict;
use warnings;

use 5.8.1;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/
    version
    title
    generator
    user_email
    date_created
    defaultprofile
/);

use XML::LibXML;

use XML::APML::Profile;
use XML::APML::Application;

use Carp ();

our $VERSION = '0.04';

use constant DEFAULT_NS => 'http://www.apml.org/apml-0.6';
use constant DEFAULT_VERSION => '0.6';

my @HEAD_ELEMENTS = qw/title generator user_email date_created/;

=head1 NAME

XML::APML - APML parser/builder

=head1 SYNOPSIS

    # parse APML

    use XML::APML;
    use Perl6::Say;
    use DateTime;
    use DateTime::Format::W3CDTF;

    my $path = "/path/to/apml.xml";
    my $apml = XML::APML->parse_file($path);

    my $fh = IO::File->open($path);
    my $apml = XML::APML->parse_fh($fh);

    my $str = "<APML version='0.6'>...</APML>";
    my $apml = XML::APML->parse_string($str);

    foreach my $profile ($apml->profiles) {

        my $implicit = $profile->implicit_data;

        foreach my $concept ($implicit->concepts) {
            say $concept->key;
            say $concept->value;
            say $concept->from;
            my $dt = DateTime::Format::W3CDTF->new->parse_datetime($concept->updated);
            say $dt->year;
            say $dt->month;
        }

        foreach my $source ($implicit->sources) {

            say $source->key;
            say $source->value;
            say $source->name;
            say $source->type;

            foreach my $author ($source->authors) {
                say $author->key;
                say $author->value;
                say $author->from;
                my $dt = DateTime::Format::W3CDTF->new->parse_datetime($author->updated);
                say $dt->year;
                say $dt->month;
            }
        }

        my $explicit = $profile->explicit_data;
        # my $explicit = $profile->explicit;

        foreach my $concept ($explicit->concepts) {
            my $key   = $concept->key;
            my $value = $concept->value;
        }

        foreach my $source ($explicit->sources) {

            $source->key;
            $source->value;
            $source->name;
            $source->type;

            foreach my $author ($source->authors) {
                $author->key;
                $author->value;
            }

        }
    }

    foreach my $application ($apml->applications) {
        $application->name;
        $application->elem;
    }

    # build apml

    my $apml = XML::APML->new;
    $apml->title('My Attention Profile');
    $apml->generator('My Application');
    $apml->user_email('example@example.com');
    $apml->date_created( DateTime::Format::W3CDTF->new->format_datetime( DateTime->now ) );
    $apml->defaultprofile("Home");

    # or you can set them at once
    my $apml = XML::APML->new(
        title          => 'My Attention Profile', 
        generator      => 'My Application',
        user_email     => 'example@example.org',
        date_created   => DateTime::Format::W3CDTF->new->format_datetime( DateTime->now ),
        defaultprofile => 'Home',
    );

    my $profile = XML::APML::Profile->new;
    $profile->name("Home");

    $profile->explicit->add_concept( XML::APML::Concept->new(
        key   => 'music',
        value => 0.5,
    ) );
    $profile->explicit->add_concept( XML::APML::Concept->new(
        key   => 'sports',
        value => 0.9,
    ) );

    $profile->explicit->add_source( XML::APML::Source->new(
        key   => 'http://feeds.feedburner.com/TechCrunch',
        value => 0.4,
        name  => 'Techchunch',
        type  => 'application/rss+xml',
    ) );

    $profile->implicit->add_concept( XML::APML::Concept->new(
        key     => 'business',
        value   => 0.93,
        from    => 'GatheringTool.com',
        updated => '2007-03-11T01:55:00Z',
    ) );

    $profile->implicit->add_source( XML::APML::Source->new(
        key     => 'http://feeds.feedburner.com/apmlspec',
        value   => 1.00,
        from    => 'GatheringTool.com',
        updated => '2007-03-11T01:55:00Z',
        name    => 'APML.org',
        type    => 'application/rss+xml',
    ) );

    my $source = XML::APML::Source->new(
        key   => 'http://feeds.feeedburner.com/TechCrunch',
        value => 0.4,
        name  => 'Techchunch',
        type  => 'application/rss+xml',
    );

    $source->add_author( XML::APML::Author->new(
        key     => 'Sample',
        value   => 0.5,
        from    => 'GatheringTool.com',
        updated => '2007-03-11T01:55:00Z',
    ) );

    $profile->implicit->add_source($source);

    $apml->add_profile($profile);

    my $application = XML::APML::Application->new;
    $application->name("MyApplication");
    $apml->add_application($application);

    print $apml->as_xml;

=head1 DESCRIPTION

APML (Attention Profiling Mark-up Language) Parser / Builder

This module allows you to parse or build XML strings according to APML specification.
Now this supports version 0.6 of APML.

See http://www.apml.org/

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my $self = bless {
        version        => DEFAULT_VERSION,
        title          => '',         
        generator      => join("/", __PACKAGE__, $VERSION),
        user_email     => '',
        date_created   => '',
        defaultprofile => undef,
        profiles       => [], 
        applications   => [],
    }, $class;
    $self->_init(@_);
    $self;
}

sub _init {
    my ($self, %args) = @_;
    for my $elem (@HEAD_ELEMENTS, qw/version defaultprofile/) {
        $self->{$elem} = delete $args{$elem} if exists $args{$elem};
    }
}

=head2 parse_string

=head2 parse_file

=head2 parse_fh

=cut

sub parse_string {
    my $class = shift;
    my $doc = XML::LibXML->new->parse_string(@_);
    $class->parse_dom($doc);
}

sub parse_file {
    my $class = shift;
    my $doc = XML::LibXML->new->parse_file(@_);
    $class->parse_dom($doc);
}

sub parse_fh {
    my $class = shift;
    my $doc = XML::LibXML->new->parse_fh(@_);
    $class->parse_dom($doc);
}

sub parse_dom {
    my ($class, $doc) = @_;
    my $root = $doc->documentElement;
    my $apml = $class->new;
    my $version = $root->getAttribute('version');
    $apml->version($version);
    my $head = $root->getElementsByTagName('Head')->[0];
    $class->_parse_head_elem($apml, $head, $_) for @HEAD_ELEMENTS;
    my $defaultprofile = $root->findvalue('*[local-name()=\'Body\']/@defaultprofile');
    $apml->defaultprofile($defaultprofile);
    my @profiles = $root->findnodes('*[local-name()=\'Body\']/*[local-name()=\'Profile\']');
    $apml->add_profile(XML::APML::Profile->parse_node($_)) for @profiles;
    my @apps = $root->findnodes('*[local-name()=\'Body\']/*[local-name()=\'Applications\']/*[local-name()=\'Application\']');
    $apml->add_application(XML::APML::Application->parse_node($_)) for @apps;
    $apml;
}

=head2 add_profile

=cut

sub add_profile {
    my ($self, $profile) = @_;
    push(@{ $self->{profiles} }, $profile);
}

=head2 profiles

=cut

sub profiles {
    my $self = shift;
    $self->add_profile($_) for @_;
    return wantarray ? @{ $self->{profiles} } : $self->{profiles};
}

=head2 add_application

=cut

sub add_application {
    my ($self, $application) = @_;
    push(@{ $self->{applications} }, $application);
}

=head2 applications

=cut

sub applications {
    my $self = shift;
    $self->add_application($_) for @_;
    return wantarray ? @{ $self->{applications} } : $self->{applications};
}

sub _parse_head_elem {
    my ($class, $apml, $head, $elem) = @_;
    my $elem_name = join("", map(ucfirst, split("_", $elem)));
    my $e = $head->getElementsByTagName($elem_name)->[0];
    if ($e && $e->string_value) {
        $apml->$elem( $e->string_value );
    } else {
        warn "$elem is not found.";
    }
}

=head2 as_xml

Build XML from object and returns it as string.

    my $apml = XML::APML->new;
    $apml->title(...);
    $apml->user_email(...);
    ...
    $apml->as_xml;

=cut

sub as_xml {
    my $self = shift;
    my $indent = shift || 1;
    my $doc = XML::LibXML->createDocument('1.0', 'utf-8');
    my $root = $doc->createElementNS(DEFAULT_NS, 'APML');
    $root->setAttribute('version', $self->{version});
    $doc->setDocumentElement($root);
    my $head = $doc->createElement('Head');
    $self->_set_header_element($doc, $head, $_) for @HEAD_ELEMENTS;
    $root->appendChild($head);
    my $body = $doc->createElement('Body');
    my $defaultprofile = $self->_find_defaultprofile();
    $body->setAttribute('defaultprofile', $defaultprofile);
    Carp::croak "APML needs at least one profile." unless @{ $self->{profiles} } > 0;
    for my $profile ( @{ $self->{profiles} } ) {
        $body->appendChild($profile->build_dom($doc));
    }
    my $applications = $doc->createElement('Applications');
    $body->appendChild($applications);
    for my $application ( @{ $self->{applications} } ) {
        $applications->appendChild($application->build_dom($doc));
    }
    $root->appendChild($body);
    return $doc->toString($indent);
}

sub _find_defaultprofile {
    my $self = shift;
    my $defaultprofile = $self->{defaultprofile};
    if (!defined $defaultprofile || $defaultprofile eq '') {
        my $first_profile = $self->{body}{profiles}[0]
            or Carp::croak "APML needs at least one profile.";
        $defaultprofile = $first_profile->name
            or Carp::croak "Profile needs its name";
    }
    $defaultprofile;
}

sub _set_header_element {
    my ($self, $doc, $head, $elem) = @_;
    my $elem_name = join("", map(ucfirst, split("_", $elem)));
    my $e = $doc->createElement($elem_name);
    my $value = $self->{$elem};
    Carp::croak "Header element:$elem not found." unless (defined $value && $value ne '');
    $e->appendText($self->{$elem});
    $head->appendChild($e);
}

1;
__END__

=head1 AUTHOR

Lyo Kato, C<lyo.kato at gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

