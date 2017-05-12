package Time::Duration::Concise::Localize;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

use Carp;
use base qw(Time::Duration::Concise);
use Module::Pluggable
    search_path => 'Time::Duration::Concise::Locale',
    sub_name    => 'translation_classes',
    require     => 1;

our $VERSION = '2.61';

=head1 NAME

Time::Duration::Concise::Localize - localize concise time duration string representation.

=head1 DESCRIPTION

Time::Duration::Concise provides localize concise time duration string representation.

=head1 SYNOPSIS

    use Time::Duration::Concise::Localize;

    my $duration = Time::Duration::Concise::Localize->new(

        # concise time interval
        'interval' => '1.5h',

        # Locale for translation
        'locale' => 'en'
    );

    $duration->as_string;

=head1 FIELDS

=head2 interval (REQUIRED)

concise interval string

=head2 locale

Get and set the locale for translation

=cut

sub locale {
    my ($self, $locale) = @_;
    $self->{'locale'} = lc $locale if $locale;
    return $self->{'locale'};
}

=head1 METHODS

=head2 as_string

Localized duration string

=cut

# Map self and plurals for English default. Should use KNOWN_UNITS...
my %locale_cache = (en => +{map { $_ => $_ } map { ($_, $_ . 's') } qw(second minute hour day)});

sub _load_translation {
    my ($self, $req_locale) = @_;

    # If locale already cached do not load
    my $cached = exists $locale_cache{$req_locale};

    if (!$cached) {
        foreach my $locale_module ($self->translation_classes) {
            my $load_locale = (split('::', $locale_module))[-1];
            next if (exists $locale_cache{$load_locale});    # Got this one already.
            next unless ($locale_module->can('translation'));    # Chocolate in our peanut butter.
            $locale_cache{$load_locale} = $locale_module->translation();
            $cached = 1 if ($load_locale eq $req_locale);        # Good news, everyone!
        }
    }

    return ($cached) ? $locale_cache{$req_locale} : $locale_cache{en};    # English default.
}

sub as_string {
    my ($self, $precision) = @_;

    my $translation = $self->_load_translation($self->locale);

    return join(' ', map { join ' ', ($_->{'value'}, $translation->{$_->{'unit'}}) } @{$self->duration_array($precision)});
}

=head2 new

Object constructor

=cut

sub new {    ## no critic (RequireArgUnpacking)
    my $class = shift;
    my %params_ref = ref($_[0]) ? %{$_[0]} : @_;

    my $interval = $params_ref{'interval'};

    my $whatsit = ref($interval);

    if ($whatsit eq __PACKAGE__) {
        $interval = $interval->seconds;
    }

    if (not defined $interval) {
        confess "Missing required arguments";
    }

    my $self = $class->SUPER::new(interval => $interval);

    # Set default locale as english
    $self->{'locale'} = 'en';
    if (exists $params_ref{'locale'}) {
        $self->{'locale'} = lc $params_ref{'locale'};
    }

    my $obj = bless $self, $class;
    return $obj;
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-time-duration-concise-localize at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Time-Duration-Concise-Localize>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Time::Duration::Concise::Localize


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Time-Duration-Concise-Localize>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Time-Duration-Concise-Localize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Time-Duration-Concise-Localize>

=item * Search CPAN

L<http://search.cpan.org/dist/Time-Duration-Concise-Localize/>

=back

=cut

1;    # End of Time::Duration::Concise::Localize
