package Test::Smoke::App::AppOption;
use warnings;
use strict;
use Carp;

our $VERSION = '0.002';

use base 'Test::Smoke::ObjectBase';

our $HTFMT = "%-30s - %s\n";

=head1 NAME

Test::Smoke::App::AppOption - Object that represents an Application Option.

=head1 SYNOPSIS

    use Test::Smoke::App::AppOption;
    my $o = Test::Smoke::App::AppOption->new(
    );
    printf "%s\n", $o->gol_option;
    print $o->show_helptext;

=head1 DESCRIPTION

=head2 Test::Smoke::App::AppOption->new(%arguments)

=head3 Arguments

Named:

=over

=item name => $basic_option_name [required]

=item option => $option_extention (see L<Getopt::Long>)

=item allow => $arrary_ref_with alternatives

=item default => $default_value

=item helptext => $text_to_show_with help

=back

=head3 Returns

An instance.

=head3 Exceptions

croak()s when:

=over

=item B<name not set>

=item B<allow is not undef or ref($allow) is Regexp, CODE or ARRAY>

=back

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $struct = {
        _name       => undef,
        _option     => "",
        _allow      => undef,
        _default    => undef,
        _helptext   => "",
        _configtext => "",
        _configtype => "prompt",
        _configalt  => sub { [] },
        _configdft  => sub { },
        _configfnex => 0,
        _configord  => 0,
    };
    $struct->{_had_default} = exists $args{default};
    for my $known (keys %$struct) {
        (my $key = $known) =~ s/^_//;
        $struct->{$known} = delete $args{$key} if exists $args{$key};
    }
    if (!defined($struct->{_name}) || !length($struct->{_name})) {
        croak("Required option 'name' not given.");
    }
    if (    defined($struct->{_allow})
        and (ref($struct->{_allow}) !~ /^(?:ARRAY|Regexp|CODE)$/))
    {
        croak("Option 'allow' must be an ArrayRef|CodeRef|RegExp when set");
    }
    # had_default(): order == code < configfile < commandline

    return bless $struct, $class;
}

=head2 $option->allowed($value[, $allow])

Checks if a value is in a set of allowed values.

=head3 Arguments

Positional.

=over

=item $value (the value to check)

=item $allow [optional]

C<$allow> can be:

=over 8

=item * ArrayRef => a list of allowed() items

=item * Regex => a regex to test C<$value> against.

=item * CodeRef => a coderef that is executed with C<$value>

=item * other_value => $value eq $other_value (checks for definedness)

=back

=back

=head3 Returns

(perl) True of False.

=cut

sub allowed {
    my $self = shift;
    return 1 if !defined $self->allow;

    my ($value, $allow) = @_;
    $allow = $self->allow if @_ == 1;
    GIVEN: {
        local $_ = ref($allow);

        /^ARRAY$/ && do {
            return scalar grep $self->allowed($value, $_), @$allow;
        };
        /^Regexp$/ && do {
            return ($value || '') =~ $allow;
        };
        /^CODE$/ && do {
            return $allow->($value);
        };
        # default
        do {
            if (!defined $value) {
                return !defined $allow;
            }
            return 0 if !defined $allow;
            return $value eq $allow;
        };
    }
}

=head2 $opt->gol_option

Getopt::Long compatible option string.

=cut

sub gol_option {
    my $self = shift;

    my $gol = $self->name;
    if ($self->option !~ /^(=|!|\||$)/) {
        $gol .= "|";
    }
    $gol .= $self->option;
    return $gol;
}

=head2 $opt->show_helptext()

    sprintf "%-30s - %s", $option_with_allowd, $self->helptext

=cut

sub show_helptext {
    my $self = shift;

    my $prefix = '--';
    if ($self->option =~ /!$/) {
        $prefix .= '[no]';
    }
    my @option = ($prefix . $self->gol_option);

    if (   defined($self->allow)
        && ref($self->allow) eq 'ARRAY' && @{$self->allow})
    {
        my @values = sort {
            lc($a) cmp lc($b)
        } map
            defined($_) ? $_ : "'undef'"
        , @{$self->allow};
        my $allowed = join('|', @values);
        push @option, "<$allowed>";
    }

    my $text = join(" ", @option);

    return $text if !$self->helptext;
    return sprintf($HTFMT, $text, $self->helptext);
}

1;

=head1 COPYRIGHT

(c) 2002-2013, Abe Timmerman <abeltje@cpan.org> All rights reserved.

With contributions from Jarkko Hietaniemi, Merijn Brand, Campo
Weijerman, Alan Burlison, Allen Smith, Alain Barbet, Dominic Dunlop,
Rich Rauenzahn, David Cantrell.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
