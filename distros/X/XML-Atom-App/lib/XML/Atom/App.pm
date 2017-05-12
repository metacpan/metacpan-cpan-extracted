package XML::Atom::App;

use warnings;
use strict;
use Carp ();
use Time::HiRes;

use version; our $VERSION = qv('0.0.5');

use XML::Atom;
use XML::Atom::Entry;
use XML::Atom::Feed;

use base qw(XML::Atom::Feed);
$XML::Atom::DefaultVersion = '1.0'; # $feed->version()

# not currently in use but if ever needed the logic is in place...
my %new_map;
my %key_map;
my %link_key_map;
my %author_key_map;

sub new {
    my ($self, $args_hr, $opt_hr) = @_;
    local $XML::Atom::DefaultVersion = '1.0';
    $args_hr = {} if !defined $args_hr || ref $args_hr ne 'HASH';
    $opt_hr = {} if !defined $opt_hr || ref $opt_hr ne 'HASH';
    
    my $feed = $self->SUPER::new( 'Version' => delete($args_hr->{'Version'}) || $XML::Atom::DefaultVersion );

    my $particles = delete $args_hr->{'particles'} || '';
    my $link      = exists $args_hr->{'link'} ? delete $args_hr->{'link'} : undef;
    $link ||= $opt_hr->{no_self_link} ? undef : [{ 'rel' => 'self' }];
    my $contrib   = exists $args_hr->{'contributor'} ? delete $args_hr->{'contributor'} : undef;
    
    $feed->{'alert_cant'} = delete $args_hr->{'alert_cant'} || '';
    $feed->{'alert_cant'} = '' if ref $feed->{'alert_cant'} ne 'CODE';

    for my $item ( sort keys %{ $args_hr } ) {
        $item = $new_map{$item} if exists $new_map{$item};
        if ( $feed->can($item) ) {
            $feed->$item( ref $args_hr->{$item} eq 'ARRAY' ? @{$args_hr->{$item}} : ($args_hr->{$item}) );
        }
        else {
            $feed->alert_cant( $item );
        }
    }
    
    $feed->_do_app_author( $feed, delete $args_hr->{'author'} );
    $feed->_do_app_link( $feed, $link );
    $feed->_do_app_contributor( $feed, $contrib ) if defined $contrib;
    
    $feed->{'time_of_last_create_from_atomic_structure'} = 0;
    $feed->create_from_atomic_structure( $particles ) if ref $particles eq 'ARRAY';
    return $feed;
}

sub clear_particles {
    my ($feed, $dx) = @_;
    $feed->{'time_of_last_create_from_atomic_structure'} = 0;

    # would love to know of a better way to remove $feed->entries, anyone ?
    my $author = $feed->author();
    my @links  = $feed->link();
    my @contribs  = $feed->contributors();

    use XML::Simple (); 
    my $xml_struct = XML::Simple::XMLin( $feed->as_xml ); 
    for my $key (qw(xmlns entry link author contributor)) {
        delete $xml_struct->{$key};
    }

    $feed->init; # resets 'elem' key to new empty object, wipes out everything not just entries..   
    
    for my $item ( sort keys %{ $xml_struct } ) {
        $item = $new_map{$item} if exists $new_map{$item};
        if ( $feed->can($item) ) {
            $xml_struct->{$item} = $xml_struct->{$item}{'content'} if ref $xml_struct->{$item} eq 'HASH';
            $feed->$item( ref $xml_struct->{$item} eq 'ARRAY' ? @{$xml_struct->{$item}} : ($xml_struct->{$item}) );
        }
        else {
            $feed->alert_cant( $item );
        }
    }
    
    $feed->author( $author ) if $author;
    $feed->add_link($_) for @links;
    $feed->add_contributor($_) for @contribs;

    return $feed;
}

sub alert_cant {
    my ($feed, $cant, $obj) = @_;
    $obj = $feed if !defined $obj || !$obj;
    
    if ( ref $feed->{'alert_cant'} eq 'CODE' ) {
        return $feed->{'alert_cant'}->( $feed, $cant, $obj );
    }
    else {
        my $msg = sprintf q{Can't locate object method "%s" via package "%s"}, $cant, ref($obj);  
        if ( exists $INC{'CGI/Carp.pm'} ) {
            return CGI::Carp::carp( $msg );
        }
        else {
            return Carp::carp( $msg );
        }
    }
}

sub atom_date_string {
    goto &datetime_as_rfc3339;    
}

sub datetime_as_rfc3339 {
    my ($feed, $dt) = @_;

    if (ref $dt eq 'ARRAY') {
        require DateTime if !exists $INC{'DateTime.pm'};
        $dt = DateTime->new(@{ $dt });
    }
    
    my $offset = $dt->offset != 0 ? '%z' : 'Z';
    return $dt->strftime('%FT%T' . $offset);
}

sub create_entry_from_atomic_structure {
    my ( $feed, $entry_hr ) = @_;
    local $XML::Atom::DefaultVersion = $feed->version();

    my $entry = XML::Atom::Entry->new;
    
    for my $item (keys %{ $entry_hr } ) {
        next if $item eq 'author' || $item eq 'link' || $item eq 'contributor' || $item eq 'source';
        $item = $key_map{$item} if exists $key_map{$item};
        if ( $entry->can($item) ) {
            $entry->$item( ref $entry_hr->{$item} eq 'ARRAY' ? @{$entry_hr->{$item}} : $entry_hr->{$item} );
        }
        else {
            $feed->alert_cant( $item, $entry );
        }
    }

    $feed->_do_app_author( $entry, $entry_hr->{'author'} );
    $feed->_do_app_contributor( $entry, $entry_hr->{'contributor'} );
    $feed->_do_app_link( $entry, $entry_hr->{'link'} );
    $feed->_do_app_source( $entry, $entry_hr->{'source'} ) if defined $entry_hr->{'source'};

    return $entry;
}

sub create_from_atomic_structure {
    my ( $feed, $particles, $opts_hr ) = @_;
    $opts_hr = {} if !defined $opts_hr || ref $opts_hr ne 'HASH';
    local $XML::Atom::DefaultVersion = $feed->version();
    
    $feed->clear_particles() if !$opts_hr->{'do_not_clear_particles'};
    
    for my $entry_hr ( @{ $particles } ) {
        my $entry = $feed->create_entry_from_atomic_structure( $entry_hr );
        $feed->add_entry($entry);    
    }
    
    $feed->{'time_of_last_create_from_atomic_structure'} = Time::HiRes::time();
    return $feed;
}

sub _do_app_contributor {
    my ($feed, $thing, $aref) = @_;
    return unless defined $aref;
    $aref = [ $aref ] unless ref $aref eq 'ARRAY';

    foreach my $contrib_ds ( @{$aref} ) {
        if ( ref $contrib_ds eq 'HASH' ) {
            my $contrib = XML::Atom::App::Contributor->new;
            for my $item ( keys %{ $contrib_ds } ) {
                $item = $author_key_map{$item} if exists $author_key_map{$item};
                if ( $contrib->can( $item ) ) {
                    $contrib->$item( ref $contrib_ds->{$item} eq 'ARRAY' ? @{$contrib_ds->{$item}} : $contrib_ds->{$item} );
                }
                else {
                    $feed->alert_cant( $item, $contrib );
                }
            }

            $thing->add_contributor($contrib);
        }
    }
}

sub _do_app_author {
    my ($feed, $thing, $author_ds) = @_;
    if ( ref $author_ds eq 'HASH' ) {
        my $author = XML::Atom::Person->new;
        for my $item ( keys %{ $author_ds } ) {
            $item = $author_key_map{$item} if exists $author_key_map{$item};
            if ( $author->can( $item ) ) {
                $author->$item( ref $author_ds->{$item} eq 'ARRAY' ? @{$author_ds->{$item}} : $author_ds->{$item} );
            }
            else {
                $feed->alert_cant( $item, $author );
            }
        }

        $thing->author($author);
    }
}

sub _do_app_link {
    my ($feed, $thing, $link_ds) = @_;
    
    if ( ref $link_ds eq 'ARRAY' ) {
        for my $link_hr ( @{ $link_ds } ) {
            next if ref $link_hr ne 'HASH';
        
            my $link = XML::Atom::Link->new;
            for my $item ( keys %{ $link_hr } ) {
                $item = $link_key_map{$item} if exists $link_key_map{$item};
                if ( $link->can( $item ) ) {
                    $link->$item( ref $link_hr->{$item} eq 'ARRAY' ? @{$link_hr->{$item}} : $link_hr->{$item} );
                }
                else {
                    $feed->alert_cant( $item, $link);
                }
            }
            $thing->add_link($link);
        }
    }
}


sub _do_app_source {
    my ($feed, $entry, $source_ds) = @_;

    if ( ref $source_ds ne 'HASH' ) {
        $entry->source( $source_ds );
        return;
    }
    delete $source_ds->{particles};
    my $src = __PACKAGE__-> new( $source_ds, {no_self_link=>1} );
    $entry->source( $src );
}

sub output_with_headers {
    my ($feed, $xml) = @_;
    # local $XML::Atom::DefaultVersion = $feed->version();
    
    $xml = $feed->as_xml() if !defined $xml || !$xml; # get $xml if non provided
    {
        use bytes;
        my $len = length($xml);
        if (defined wantarray) {
            return "Content-length: $len\nContent-type: application/atom+xml\n\n$xml";
        }
        else {
            # print in void context
            print "Content-length: $len\nContent-type: application/atom+xml\n\n$xml";
        }    
    }
}

sub orange_atom_icon_32_32_base64 {
    # my ($feed) = @_;
    return q{data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAUzSURBVHjavFdbbFRVFF3nPjoz7dTWTittaW0jUDRAUqaNojyqREnEQKgfUj9MqqAmhqRt/OCD4CuY+Kckoh+aiGKC+gMJbdHoRysJ8dkhhmJLNdDKtJU+6GMK87j3Hs85d2Z6HzNtMYWb3Dn3NWftvfba+5xNYDl+e6Fkj6yqb/oDRbWq14vlPBLRKCITkxf0ROLt+hNjp1PPSRK4kA3vF1dXNRcWlyA2OQU9eos9opAkAiKxD+XkKO6t15aRWO7J/MgmAZU8MEgexgZHMX518Dh72sYMmVKShnxWuWHdHtxKIDIYTgMuDzgfmSOIQkYMpdUF8OY92Hytt4/jvkg47czzU16iQovM3QFwmNck+Yyduu7D6NA0Z6JR4THntFs9V4tWQg6Ui3s6MwKDncsFTnXKLJhDSeUK3AgPtyhccDzmVs999buRt/1Vm4i0od+hX7+MRG87jPGB/w1u8FPj9xEw7McVrnYuOCvtpjTth3J/nTg99c8LRhKhr6D3dTB5R24bXFwbMXBsyZzeoXaycEpJ95TB09AGX/NpqLVNtw8urnVzLvHjFNxiFqRy2OOHuqUVnue+ACkoWzo4O6lGzTmuHq6nPvY2m9rVqjrIK2rMEKxqyG5NPAKt+wjo0LklgfNxJkZMA3KJvqRUk3z5UFY3QH14P0h+WUY79HPvgv7VuSg4ZRGY1YgZgqXmORccF17sy2ehnf9AeO085K2HQFbtXBScj0LcpgF2cN+WV+DZ/LJQu6gD4R7oV7pBJwbSgtMvfiPoVp56DySwxm7EtkMs1WdAB7qzggsDJKQYsHucSkOudrkiCPWR/fA2nYCn8SNIK4NptSMyAu3sAdDRkIsJdfth0LzSrODUoPNZ4KI9SxJI5UHk7D4GdQfz2us31c7CoHMjRkKuDPHseCMrONVhNcDJwMJpKFVvg9L4OaTiNWm1x789KCqkrXhVBiEz0WYCT2nAzQAD1/vaETv1GrRfP4Vx5cfMNcDPwvP0h0DhanPym7OIf/+O67vcJ1/PCJ4KgdzaUP6Wz+dU+5yIL6fV+PsHGAOdwlPpvvUOyeeAVGyCdqkDNB6DPjsBSrnndfOGevOh3RhGItxvA+fX1CtbGFhgYUFkFMZPR6F1HnClHq8HyubWtJexX06CRmdt33hrd7nA7SFY4qoGpnYuOKcRykPPgDCBcsHx9Iv+fNL2PueBehCWUfYQIIMGLOCcOmXDXsh1+yCt35tUPfvzGFuSvzvoinXOxqa02qOhM6733nVP2MAdaej2XN11DPKjLZCD+yBvahGCo7JfTKAN9UD7s8Oe9zUNIhz8fWI8DG2k38WCFdxugANcXrvTVd1IEbuv3Jour7Hzn7jLMBNfKs7R3i67gRVrbeCOEDhinmWhAatsqdquM2XzHZINhK2cqTjHr/XZdVJUbgN3MWAVXKbSyg9jesRW2xP9di+lwrL5ojM3m2H/kG9hwcIA37c71W6wJdW2J2S5nrjYbq/t1AHAhJsKQeyfPvf6IMJgghPJhFZ4x0KlfLFvt22du45Au/A1SOlGc0P672XXwhLtOcM0kTTEMMd0qkVmMNXxMd/tsedUjInr4SQDgOfeXMSiN0FCL5WHah4L1qqYXPJOJlttd+a5M+YpcG5poLYKQ5f+6JJ4r8bbJYP47hq4r7QAs9PjYNhHJd4o8l5taiwuOpa7AS4XKqI/5NjJbTnaWK92nLdLuhQAJayRNMiygXPBeQN+Qbvu0zDc3y+aUzhbkGR73sI7ljvUnndx2q3t+X8CDAD66FtrIL864AAAAABJRU5ErkJggg%3D%3D};
}

sub orange_atom_icon_32_32_body_with_headers {
    # my ($feed) = @_;
    my $base64  = orange_atom_icon_32_32_base64();
    my ($ctype) = $base64 =~ m{data:([^/]+[/][^;]+);base64,};
    $ctype      = 'image/png' if !$ctype;
    $base64     =~ s{^data:image/png;base64,}{};
    
    require MIME::Base64;
    my $binary  = MIME::Base64::decode_base64( $base64 );
    
    {
        use bytes;
        my $len = length $binary;
        return "Content-length: $len\nContent-type: image/png\n\n$binary";
    }    
}

sub orange_atom_icon_32_32_img_tag {
    my ($feed, $attr) = @_; # !! make sure your $attr are XSS safe !!
    $attr = $attr ? " $attr" : '';
    return q{<img src="} . orange_atom_icon_32_32_base64() . qq{" width="32" height="32"$attr />};
}

sub orange_atom_icon_16_16_base64 {
    # my ($feed) = @_;
    return q{data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAKOSURBVHjadJNNSFRRGIbfc+6dO6OOOplDykSZaRCtnKRc+ANRUBFEm0gicxG0bGoVhERRYIvIjRAtW+UmW5QQQS6qRWQSWJRaUcjkT0LiVWfm/pzTd869M5LShe+eufC973m+n2Fj55KJymTt9ZgVy3AGMHoxvvEs/qZgDL4AlhbsAfv34g1TiRPxRMZbWwU3GQzO9clNhGcYBpkY4UlGiWRd5scnMvx5tUWano9IMoXy1pOUBPgz4xC/xv8r1hSexNKiB1Nhq6RIbQoVhy6i+MiCDffDEPyJITBvZZPYLwiQFFzVZ0Q45Moc8q8fwP34FGJ5FixaCevgBZT1DMNs7Nok9iikL8GyfWkZ3VgvhbljP6yOy2BbmzWR/+o2vM/PSmLfkchTaAIlsHa1ourSS5Sfvg8r3Q38mYb7+DzE9Ig2MDquAan2kth3AgKu0JSBapLCNranEWnPIHp2GDzZDEE3+1OBiXW4D4LHtViZCB/rBHJuHPmHp+CO3oK0Zyk7DvP4IGR1EwrPb673JX0mELslgvVRYW0O8usIvCe9AboyOdIPn1Ug9+Kupihr69ZiZSJFsYRwztbRO4icGARv6IT3ZkCTsKp68J2dyE2MQuZtsFgllbZHTyMsAVqsaldCVt8CtvsYPHsZzvtH+tZIc5e+sfBtLOhFYytRFAlYuGGED2clGNn8lO62m53U37y6XmM7M8E3onEIIpCSLp/vPyC31Bp6SUSsjmIbnO9jpVEZqbROzn15F5RDZs5CFs58FmaNBTZ5Ze+9hn11Genl/1mS0qjChumaCVvo2iViNXHkuD1g9Daxt7lVEQPMNpcSdah1pQb5kqho4yVXQc2iacHiMMpNFPia/jv/FWAAUTVTOunExzkAAAAASUVORK5CYII%3D};
}

sub orange_atom_icon_16_16_body_with_headers {
    # my ($feed) = @_;
    my $base64  = orange_atom_icon_16_16_base64();
    my ($ctype) = $base64 =~ m{data:([^/]+[/][^;]+);base64,};
    $ctype      = 'image/png' if !$ctype;
    $base64     =~ s{^data:image/png;base64,}{};
    
    require MIME::Base64;
    my $binary  = MIME::Base64::decode_base64( $base64 );
    
    {
        use bytes;
        my $len = length $binary;
        return "Content-length: $len\nContent-type: image/png\n\n$binary";
    }    
}

sub orange_atom_icon_16_16_img_tag {
    my ($feed, $attr) = @_; # !! make sure your $attr are XSS safe !!
    $attr = $attr ? " $attr" : '';
    return q{<img src="} . orange_atom_icon_16_16_base64() . qq{" width="16" height="16"$attr />};
}

#
# This is a workaround for the fact that XML::Atom::Person always pretends
# to by an author. This minimal change allows a contributor.
{
    package XML::Atom::App::Contributor;
    use base 'XML::Atom::Person';

    sub element_name { 'contributor' }
}


1; 

__END__

=head1 NAME

XML::Atom::App - quickly create small efficient scripts to syndicate via Atom

=head1 VERSION

This document describes XML::Atom::App version 0.0.5

=head1 SYNOPSIS

A complete Atom feed script:

    use XML::Atom::App;

    XML::Atom::App->new({
        'title'     => _get_title_string(),
        'id'        => _get_id_string(),
        'updated'   => XML::Atom::App->datetime_as_rfc3339( _get_last_updated_datetime_args() ),
        'particles' => _get_latest_particles_arrayref(),
    })->output_with_headers();

=head2 EXAMPLE SCRIPTS

=head3 uber efficient persistent perl process 

If using L<PersistentPerl> this script will only create the $feed, update particles, and/or generate $xml if needed instead of on every hit.

    #!/usr/bin/perperl

    use strict;
    use warnings;
    use vars ($feed $xml $particles);
    use XML::Atom::App;

    if (!defined $feed || ref $feed ne 'XML::Atom::App' ) {
        $feed = XML::Atom::App->new({
            'title' => _get_title_string(),
            'id'    => _get_id_string(),
            'updated'   => XML::Atom::App->datetime_as_rfc3339( _get_last_updated_datetime_args() ),
        });
    }

    if ( !defined $xml || !xml || !defined $particles || ref $particles ne 'ARRAY' || _particles_need_updated() ) {
        $particles = _get_latest_particles_arrayref();
        $feed->create_from_atomic_structure( $particles );
        $xml = $feed->as_xml();
    }

    $feed->output_with_headers( $xml );

=head3 explicit creation basic CGI

    #!/usr/bin/perl

    use strict;
    use warnings;
    use XML::Atom::App;

    my $feed = XML::Atom::App->new({
        'title'     => _get_title_string(),
        'id'        => _get_id_string(),
        'updated'   => XML::Atom::App->datetime_as_rfc3339( _get_last_updated_datetime_args() ),
    });

    $feed->create_from_atomic_structure( _get_latest_particles_arrayref() );

    $feed->output_with_headers();

=head3 implicit creation basic CGI

    #!/usr/bin/perl

    use strict;
    use warnings;
    use XML::Atom::App;

    my $feed = XML::Atom::App->new({
        'title'     => _get_title_string(),
        'id'        => _get_id_string(),
        'particles' => _get_latest_particles_arrayref(),
        'updated'   => XML::Atom::App->datetime_as_rfc3339( _get_last_updated_datetime_args() ),
    });

    # this is done (IE implied) for you w/ 'particles' key to new(): 
    # $feed->create_from_atomic_structure( _get_latest_particles_arrayref() );

    $feed->output_with_headers();

=head1 DESCRIPTION

The idea of this module is to make it easy to create Atom feed scripts by packaging up the logic that happens 
over and over and using a fairly simple data structure that you can generate easily based on your needs.

=head1 INTERFACE 

=head2 METHODS

=head3 new()

Accepts no arguments or a hashref with any of the following keys:

=over 4

=item Version

Atom version to output. Defaults to 1.0 (which is different than XML::Atom which defaults to 0.3 at the time of writing this)

=item alert_cant

A coderef to run instead of the default alert_cant method. Internally it called in void context and is passed the name of the method and the object.

=item particles

An arrayref to create the Atom document from (See "particles" array ref below). If specified it calls create_from_atomic_structure() for you.

=item link

Same as the particle array ref 'link' but for the feed (see below). If not specified a simple link is created: rel="self" (as recommended by L<http://feedvalidator.org>)

=item author

Same as the particle array ref 'author' but for the feed (see below).

=item contributor

Same as the particle array ref 'contributor', but for the feed (see below).

=back

Additionally it takes as a key any XML::Atom::Feed method name which is subsequently called by new() for you. 

The value can be a valid argument to said function or an array of valid arguments.

    my $feed = XML::Atom::App->new({
        'title'     => _get_title_string(),
        'id'        => _get_id_string(),       
        'updated'   => XML::Atom::App->datetime_as_rfc3339( _get_last_updated_datetime_args() ),
    });
    
is the same as
    
    my $feed = XML::Atom::App->new();
    $feed->title( _get_title_string() );
    $feed->id( _get_id_string() );
    $feed->updated( $feed->datetime_as_rfc3339( _get_last_updated_datetime_args() ) );

Any unknown keys will cause and alert_cant().

=head3 create_entry_from_atomic_structure()

Takes the particle hashref representing one entry and does the work needed to turn it into an Atom Entry document. (See "particles" array ref below).

The newly created L<XML::Atom::Entry> object is returned, but not added to the current feed. To add the entry to the L<XML::Atom::Feed> object, use the C<add_entry> method.

=head3 create_from_atomic_structure()

Takes the particle arrayref passed and does all the necessary calls to make it into an Atom document. (See "particles" array ref below).

It clears the previous particles for you before creating the new one (unless you tell it not to)

A second argument can be a hashref of options. Currently the only option is the 'do_not_clear_particles' key which if true does not clear the previouse particles. 

$feed->{'time_of_last_create_from_atomic_structure'} gets set to Time::HiRes::time for your use in seeing if the particles need updated. (IE say your database was updated since this was generated)

=head3 output_with_headers()

This outputs (in void context) or returns as a string (in non void context) all HTTP headers and XML necessary to serve the Atom feed.

You can avoid having it call $feed->as_xml() internally by passing it as an argument. This is useful for perisistent environments so you only have to generate the XML when the particles are updated.

=head3 alert_cant()

Generally you won't ever call this in your scripts.

This is called internally when an item that can't be used is found in the particles array ref. See DIAGNOSTICS.

By default it just does a warning. It can be changed by using the 'alert_cant' key.

=head3 clear_particles()

Generally you won't ever call this in your scripts.

This clears all particles from the $feed.

=head3 CONVIENIENCE

=head4 atom_date_string()

Clone of datetime_as_rfc3339()

=head4 datetime_as_rfc3339()

Returns a string suitable for any Atom date related entry. 

It must be passed a L<DateTime> object or an array ref of DateTime->new() arguments.

    my $atom_safe_date_string = $feed->datetime_as_rfc3339( DateTime->now() );
    
    my $atom_safe_date_string = $feed->datetime_as_rfc3339(
        [
            'year'      => 1999, 
            'month'     => 7, 
            'day'       => 17, 
            'hour'      => 12,
            'minute'    => 01,
            'second'    => 00,
            'time_zone' => 'EST',               
        ]
    );

=head4 orange_atom_icon_32_32_base64()

Returns a base64 string (Plus leading "header" info) of the binary that makes up a 32 x 32 pixel orange Atom icon png image.

=head4 orange_atom_icon_32_32_body_with_headers()

Returns HTTP headers and binary data suitable for serving a 32 x 32 pixel orange Atom icon png image.

    if ( $action eq 'icon' ) {
        print XML::Atom::App->orange_atom_icon_32_32_body_with_headers();
    }
    else {
        my $feed = ...
        ...
        $feed->output_with_headers();
    }

=head4 orange_atom_icon_32_32_img_tag()

Returns an HTML image tag for a 32 x 32 pixel orange Atom icon png image using the base 64 data instead of a normal URL.

Any attributes (height and width are already done) can be added by passing a string as the method's argument.

=head4 orange_atom_icon_16_16_base64()

16 pixel x 16 pixel version of corresponding '32_32' method

=head4 orange_atom_icon_16_16_body_with_headers()

16 pixel x 16 pixel version of corresponding '32_32' method

=head4 orange_atom_icon_16_16_img_tag()

16 pixel x 16 pixel version of corresponding '32_32' method

=head2 "particles" array ref

Each item in this array ref is an entry in your feed. It is represented as a hashref with the following keys:

=over 4

=item title, id, content, updated, created, etc...

Any L<XML::Atom::Entry> method name may be used as a key. The value can be a valid argument to said function or an array of valid arguments.

=item author

This is a hashref whose keys should be any L<XML::Atom::Person> method name (E.g. name, email, uri, url, homepage). 

The value can be a valid argument to said function or an array of valid arguments.

=item link

This is an array ref of links. Each item is a hashref whose keys should be any L<XML::Atom::Link> method name (E.g. type, rel, href, hreflang, title, length). 

The value can be a valid argument to said function or an array of valid arguments.

=item contributors

This is an array ref of hashrefs whose keys should be any L<XML::Atom::Person> method name (See author above).

The value can be a valid argument to said function or an array of valid arguments.

=back

=head1 DIAGNOSTICS

=over

=item C<< Can't locate object method "%s" via package "%s" >>

The particles data structure had a key that was not specially handled and not a method of the given class.

This warning can be overridden by the 'alert_cant' key.

=back

=head1 CONFIGURATION AND ENVIRONMENT

XML::Atom::App requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<XML::Atom>, L<XML::Atom::Entry>, L<XML::Atom::Feed>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-xml-atom-app@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
