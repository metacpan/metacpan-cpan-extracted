
=head1 NAME

Weasel::WidgetHandlers - Mapping elements to widget handlers

=head1 VERSION

0.01

=head1 SYNOPSIS

  use Weasel::WidgetHandlers qw( register_widget_handler );

  register_widget_handler(
    'Weasel::Widgets::HTML::Radio', # Perl class handler
    'HTML',                         # Widget group
    tag_name => 'input',
    attributes => {
       type => 'radio',
    });

  register_widget_handler(
    'Weasel::Widgets::Dojo::FilteringSelect',
    'Dojo',
    tag_name => 'span',
    classes => ['dijitFilteringSelect'],
    attributes => {
       role => 'presentation',
       ...
    });

=cut

=head1 DESCRIPTION

=cut

=head1 DEPENDENCIES



=cut

package Weasel::WidgetHandlers;

use strict;
use warnings;

use base 'Exporter';

use Module::Runtime qw(use_module);
use List::Util qw(max);

our @EXPORT_OK = qw| register_widget_handler best_match_handler_class |;

=head1 SUBROUTINES/METHODS

=over

=item register_widget_handler($handler_class_name, $group_name, %conditions)

Registers C<$handler_class_name> to be the instantiated widget returned
for an element matching C<%conditions> into C<$group_name>.

C<Weasel::Session> can select a subset of widgets to be applicable to that
session by adding a subset of available groups to that session.

=cut


# Stores handlers as arrays per group
my %widget_handlers;

sub register_widget_handler {
    my ($class, $group, %conditions) = @_;

    # make sure we can use the module by pre-loading it
    use_module $class;

    return push @{$widget_handlers{$group}}, {
        class => $class,
        conditions => \%conditions,
    };
}

=item best_match_handler_class($driver, $_id, $groups)

Returns the best matching handler's class name, within the groups
listed in the arrayref C<$groups>, or C<undef> in case of no match.

When C<$groups> is undef, all registered handlers will be searched.

When multiple handlers are considered "best match", the one last added
to the group last mentioned in C<$groups> is selected.

=cut

sub _cached_elem_att {
    my ($cache, $driver, $_id, $att) = @_;

    return (exists $cache->{$att})
        ? $cache->{$att}
        : ($cache->{$att} = $driver->get_attribute($_id, $att));
}

sub _att_eq {
    my ($att1, $att2) = @_;

    return ($att1 // '') eq ($att2 // '');
}

sub best_match_handler_class {
    my ($driver, $_id, $groups) = @_;

    $groups //= [ keys %widget_handlers ];   # undef --> unrestricted

    my @matches;
    my $elem_att_cache = {};
    my $elem_classes;

    my $tag = $driver->tag_name($_id);
    for my $group (@{$groups}) {
        my $handlers = $widget_handlers{$group};

      HANDLER:
        for my $handler (@{$handlers}) {
            my $conditions = $handler->{conditions};

            next unless $tag eq $conditions->{tag_name};
            my $match_count = 1;

            if (exists $conditions->{classes}) {
                %{$elem_classes} =
                   map { $_ => 1 }
                   split /\s+/x, ($driver->get_attribute($_id, 'class')
                                 // '')
                       unless defined $elem_classes;

                for my $class (@{$conditions->{classes}}) {
                    next HANDLER
                        unless exists $elem_classes->{$class};
                    $match_count++;
                }
            }

            for my $att (keys %{$conditions->{attributes}}) {
                next HANDLER
                    unless _att_eq(
                        $conditions->{attributes}->{$att},
                        _cached_elem_att(
                            $elem_att_cache, $driver, $_id, $att));
                $match_count++;
            }

            push @matches, {
                count => $match_count,
                class => $handler->{class},
            };
        }
    }
    my $max_count = max map { $_->{count} } @matches;
    @matches = grep { $_->{count} == $max_count } @matches;

    warn "multiple matching handlers for element\n"
        if scalar(@matches) > 1;

    my $best_match = pop @matches;
    return $best_match ? $best_match->{class} : undef;
}

=back

=cut

=head1 AUTHOR

Erik Huelsmann

=head1 CONTRIBUTORS

Erik Huelsmann
Yves Lavoie

=head1 MAINTAINERS

Erik Huelsmann

=head1 BUGS AND LIMITATIONS

Bugs can be filed in the GitHub issue tracker for the Weasel project:
 https://github.com/perl-weasel/weasel/issues

=head1 SOURCE

The source code repository for Weasel is at
 https://github.com/perl-weasel/weasel

=head1 SUPPORT

Community support is available through
L<perl-weasel@googlegroups.com|mailto:perl-weasel@googlegroups.com>.

=head1 LICENSE AND COPYRIGHT

 (C) 2016  Erik Huelsmann

Licensed under the same terms as Perl.

=cut


1;

