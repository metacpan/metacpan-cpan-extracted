#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::Tabbed;

my $widget = Tickit::Widget::Tabbed->new(
        tab_position => "top",
        tab_class => "TestWidget::Tab",
);

my $tab = $widget->add_tab(
        Tickit::Widget::Static->new( text => "" ),
        label => "newtab",
        custom_attr => 123,
);

isa_ok( $tab, "TestWidget::Tab", '$tab from custom tab_class' );

is( $tab->custom_attr, 123, '$tab->custom_attr' );

done_testing;

package TestWidget::Tab;
use base qw( Tickit::Widget::Tabbed::Tab );

sub new
{
        my $class = shift;
        ( undef, my %args ) = @_;
        my $self = $class->SUPER::new( @_ );
        $self->{custom_attr} = $args{custom_attr};
        return $self;
}

sub custom_attr
{
        my $self = shift;
        return $self->{custom_attr};
}
