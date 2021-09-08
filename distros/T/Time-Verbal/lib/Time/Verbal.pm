package Time::Verbal;
# ABSTRACT: Convert time distance to words.

use strict;
use warnings;

use Object::Tiny qw(locale);
use File::Spec;
use Locale::Wolowitz;

sub distance {
    my $self = shift;
    unless (ref($self)) {
        unshift(@_, $self);
        $self = __PACKAGE__->new;
    }

    my ($from_time, $to_time) = @_;

    die "The arguments should be (\$from_time, \$to_time), both are required." unless defined($from_time) && defined($to_time);

    my $delta = abs($to_time - $from_time);

    if ($delta < 30) {
        return $self->loc("less then a minute")
    }
    if ($delta < 90) {
        return $self->loc("1 minute");
    }
    if ($delta < 3600) {
        return $self->loc('%1 minutes', int(0.5+$delta / 60));
    }
    if ($delta < 5400) {
        return $self->loc("about 1 hour");
    }
    if ($delta < 86400) {
        return $self->loc('%1 hours', int(0.5+ $delta / 3600));
    }
    if ($delta >= 86400 && $delta < 86400 * 2) {
        return $self->loc("one day");
    }
    if ($delta < 86400 * 365) {
        return $self->loc('%1 days', int($delta / 86400));
    }

    return $self->loc("over a year");
}

sub loc {
    my ($self, $msg, @args) = @_;
    return $self->wolowitz->loc( $msg, $self->locale || "en" , @args );
}

sub i18n_dir {
    my ($self, $dir) = @_;

    my $i18n_dir = sub {
        my @i18n_dir = (File::Spec->splitdir(__FILE__), "i18n");
        $i18n_dir[-2] =~ s/\.pm//;
        return File::Spec->catdir(@i18n_dir);
    };

    if (ref($self)) {
        if (defined($dir)) {
            $self->{i18n_dir} = $dir;
        }

        if (defined($self->{i18n_dir})) {
            return $self->{i18n_dir}
        }

        return $self->{i18n_dir} = $i18n_dir->();
    }

    return $i18n_dir->();
}

sub wolowitz {
    my ($self) = @_;
    $self->{wolowitz} ||= Locale::Wolowitz->new( $self->i18n_dir);
    return $self->{wolowitz}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Verbal - Convert time distance to words.

=head1 VERSION

version 1.1.1

=head1 SYNOPSIS

    use Time::Verbal;

    my $now = time;
    my $then = $now - 76543210;

    my $o = Time::Verbal->new();

    say $o->distance($then, $now);
    #=> over a year

    say $o->distance($now, $then);
    #=> about 1 hour

=head1 DESCRIPTION

Time::Verbal is a module for converting the difference between two
timestamps to its verbal form -- something a human would say.

=head1 METHODS

=head2 new(...)

The constructor, with arguments being a list of key-value pairs.

The valid keys are:

    - locale
    - i18n_dir

They are both optional, and are both for i18n purpose.

The value of C<locale> should be one of the ISO language code.
The valid ones for the release are:

    ar bg bn-IN bs ca cy da de-AT de-CH de dsb el en-AU en-GB en-US eo
    es-AR es-CL es-CO es-MX es-PE es et eu fa fi fr-CA fr-CH fr fur gl-ES
    gsw-CH he hi-IN hi hr hsb hu id is it ja ko lo lt lv mk mn nb nl nn pl
    pt-BR pt-PT rm ro ru sk sl sr-Latn sr sv-SE sw tr uk vi zh-CN zh-TW

However, you may pass something not in this list as long as you also provide
a path (string) for C<i18n_dir> pointing to a directory with JSON files that
are recongized by L<Locale::Wolowitz>.

=head2 distance($from_time, $to_time)

Returns the absolute distance of two timestamp in words.

Output are in one of these forms:

    - less than a minute
    - 1 minute
    - 3 minutes
    - about 1 hour
    - 6 hours
    - yesterday
    - 177 days
    - over a year

For time distances larger the a year, it'll always be "over a year".

The returned string is a localized string if the object is constructed with locale
parameter:

    my $tv = Time::Verbal->new(locale => "zh-TW");
    say $tv->distance(time, time + 3600);
    #=> 一小時

Internally l10n is done with L<Locale::Wolowitz>, which means the dictionary
files are just a bunch of JSON text files that you can locate with this command:

    perl -MTime::Verbal -E 'say Time::Verbal->i18n_dir'

In case you need to provide your own translation JSON files, you may specify
the value of i18n_dir pointing to your own dir:

    my $tv = Time::Verbal->new(locale => "xx", i18n_dir => "/app/awesome/i18n");

Your should start by copying and modify one of the JSON file under
C<Time::Verbal->i18n_dir>. The JSON file should be named after the
language code as a good convention, but there is no strict rule for
that. As a result, you may create your own language code like
C<"LOLSPEAK"> by first creating the translation file C<LOLSPEAK.json>, then
use C<"LOLSPEAK"> as the value of C<locale> attribute.

Current translations are imported from the rails-i18n project at
L<https://github.com/svenfuchs/rails-i18n>

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Kang-min Liu.

This is free software, licensed under:

  The MIT (X11) License

=cut
