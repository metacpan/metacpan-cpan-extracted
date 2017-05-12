package WebService::Box::Types::Library;

use strict;
use warnings;

use Type::Library
    -base,
    -declare => qw(
        BoxPerson PersonHash Timestamp BoxFolderHash BoxFileHash
        OptionalStr OptionalInt OptionalTimestamp
        SharedLink SharedLinkHash SharedLinkPermissionHash
    );

use Type::Utils -all;
use Types::Standard -types;

use DateTime;

use WebService::Box::Types::By;

our $VERSION = 0.01;


# create some basic types
{
    declare OptionalStr => as union[ Undef, Str ];
    declare OptionalInt => as union[ Undef, Int ];
}

# create types regarding users
{
    class_type BoxPerson => { class => "WebService::Box::Types::By" };

    declare PersonHash =>
        as Dict[
            type  => Str,
            id    => Int,
            name  => Str,
            login => Str,
        ];

    coerce BoxPerson => 
        from PersonHash => via { WebService::Box::Types::By->new( %{$_} ) };
}


# create types regarding times
{
    class_type Timestamp => { class => "DateTime" };

    coerce Timestamp =>
        from Str() => via {
            my ($timezone) = $_ =~ m{([+-][0-9]{2}:?[0-9]{2})\z};
            $timezone = '' if !defined $timezone;
            $timezone =~ s{:}{};

            my %opts;
            $opts{time_zone} = $timezone if defined $timezone and $timezone ne '';

            my ($year,$month,$day,$hour,$minute,$second) = split /[:T+-]/, $_;
            DateTime->new(
                second    => $second,
                minute    => $minute,
                hour      => $hour,
                day       => $day,
                month     => $month,
                year      => $year,
                %opts,
            );
        };

        declare OptionalTimestamp => as union[Timestamp, Undef];
}

{
    declare BoxFolderHash => 
        as Dict[
            type        => sub{ $_ eq 'folder' },
            id          => Str,
            sequence_id => OptionalStr,
            etag        => OptionalStr,
            name        => Str,
        ];

    declare BoxFileHash => 
        as Dict[
            type        => sub{ $_ eq 'file' },
            id          => Str,
            sequence_id => OptionalStr,
            etag        => OptionalStr,
            name        => Str,
        ];
}

{
    # shared link objects
    class_type SharedLink => { class => 'WebService::Box::Types::SharedLink' };

    declare SharedLinkPermissionHash =>
        as Dict[
            can_download    => Str,
            can_preview     => Str,
        ];

    declare SharedLinkHash => 
        as Dict[
            url                 => Str,
            download_url        => Str,
            vanity_url          => OptionalStr,
            is_password_enabled => OptionalStr,
            unshared_at         => OptionalTimestamp,
            download_count      => Int,
            preview_count       => Int,
            access              => Str,
            permissions         => SharedLinkPermissionHash,
        ];

    require WebService::Box::Types::SharedLink;

    coerce SharedLink
        from SharedLinkHash => via {
            WebService::Box::Types::SharedLink->new( %{$_} );
        };
}

1;

__END__

=pod

=head1 NAME

WebService::Box::Types::Library

=head1 VERSION

version 0.02

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
