package WWW::MLite; # $Id: MLite.pm 32 2014-08-01 10:31:31Z minus $
use strict;

=head1 NAME

WWW::MLite - Lite Web Application Framework

=head1 VERSION

Version 1.05

=head1 SYNOPSIS

    use WWW::MLite;

=head1 ABSTRACT

WWW::MLite - Lite Web Application Framework

=head1 DESCRIPTION

Lite Web Application Framework

=head1 METHODS

=over 8

=item B<new>

    my $mlite = new WWW::MLite( ... args ... );

Returns object

=item B<show>

    $mlite->show( qw/foo bar baz/ );

Run project and send data to Apache

=item B<register>

    $mlite->register( qw/Foo Bar Baz/ );

Register all announced modules after creating object

=item B<get_recs>

    $mlite->get_recs( qw/foo bar baz/ )

Get metadata as one hash

=item B<get_rec>

    my $data = $mlite->get_rec( "foo" )

Get data one key only

=item B<get_node, get>

    my $name = $mlite->get( 'name' );

Getting node by name

=item B<set_node, set>

    $mlite->set( key => 'value' );

Setting node by name

=item B<config, conf>

    my $config = $mlite->config;

Getting config-node

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<CTK>

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw/ $VERSION /;
$VERSION = '1.05';

use Module::Load;
use CTK::Util qw/ :API /;
use CTK::ConfGenUtil;
use WWW::MLite::Config;

use base qw/
        WWW::MLite::Log
        WWW::MLite::Transaction
    /;

use constant {
        HANDLER         => 'handler',
    };

sub new {
    my $class   = shift;
    my %args    = @_;
    
    # Подгружаем модуль
    my $h_module = $args{module};
    croak("The 'module' argument missing") unless $h_module;
    load $h_module;
    #croak("Module '$h_module' can't loaded");

    # Проверяем наличие главного хендлера
    my $h_handler = $args{handler} || HANDLER;
    croak("The 'handler' argument missing") unless $h_handler;
    my $handler = undef;
    #eval "\$handler = $h_module->can(\$h_handler)"; croak("Method '$h_handler' not exists. $@") if $@;
    croak("Method '$h_handler' not exists") unless $handler = $h_module->can($h_handler);
    
    
    

    my $self = bless {
        name        => $args{name} || 'noname',
        prefix      => defined($args{prefix}) ? $args{prefix} : '',
        module      => $h_module,
        handler     => $handler,
        params      => $args{params},
        register    => _to_arrayref($args{register}),
        meta        => {},
        inheritance => $args{inheritance} ? 1 : 0, # Включить наследование зерегистрированных модулей
        config      => new WWW::MLite::Config( # Конфигурационные опции
                            file => $args{config_file}, 
                            dirs => $args{config_dirs},
                        ),
    }, $class;
    
    # Регистрация модулей, если они заданы
    $self->register();

    return $self;
}
sub show {
    my $self = shift;
    croak("The method call not in the WWW::MLite context") unless ref($self) =~ /WWW\:\:MLite/;
    return $self->{handler}->($self, @_);
}
sub register {
    my $self = shift;
    my @mdls = @_;
    @mdls = @{($self->{register})} unless @mdls;
    return 0 unless @mdls;
    
    load $_ for @mdls;
    push @WWW::MLite::ISA, @mdls if $self->{inheritance};
    my $meta = $self->{meta};
    
    for (@mdls) {
        my @rec = (); 
        if ($_->can("meta")) {
            @rec = $_->meta;
        } else {
            carp("Method 'meta' not exists in $_ package");
            next;
        }
        $meta->{$_} = {
                status      => 'registered',
                actions     => {@rec},
            };
    }
    return 1;
}
sub get_recs {
    # Get metadata as one hash where key = name of action, value = data of action
    my $self = shift;
    my @rq = @_;
    my $metas = hash($self->{meta});
    my %recs = ();
    foreach my $k (keys %$metas) {
        my $actions = hash($metas, $k, "actions");
        foreach my $a (keys %$actions) {
            if (@rq) {
                next unless grep {$a eq $_} @rq;
            }
            $recs{$a} = hash($actions, $a);
            $recs{$a}{module} = $k;
        }
    }
    return {%recs}
}
sub get_rec {
    # Get data by name of action
    my $self = shift;
    my $name = shift;
    return {} unless defined $name;
    return hash($self->get_recs($name), $name);
}

sub get_node {
    # Прочитать ноду из глобального массива
    my $self = shift;
    my $node = shift;
    return $self->{$node};
}
sub get { goto &get_node };
sub set_node {
    # Добавить ноду к глобальному массиву
    my $self = shift;
    my $node = shift;
    my $data = shift;
    $self->{$node} = $data;
}
sub set { goto &set_node };
sub config { return shift->{config}; };
sub conf { goto &config };

sub _to_arrayref {
    my $p = shift;
    if ($p && ref($p) eq 'ARRAY') {
        return $p;
    } elsif (defined($p)) {
        return [$p];
    }
    return [];
}
sub AUTOLOAD {
    # Это своего рода интерфейс ко всем свойствам через объектную модель
    # если такого свойства не окажится, то значит ругаемся карпом !!
    my $self = shift;
    our $AUTOLOAD;
    my $AL = $AUTOLOAD;
    my $ss = undef;
    $ss = $1 if $AL=~/\:\:([^\:]+)$/;
    if ($ss && defined($self->{$ss})) {
        return $self->{$ss};
    } else {
        carp("Can't find WWW::MLite node \"$ss\"");
    }
    return undef;
}
sub DESTROY {
    my $self = shift;
    #print STDERR "Object WWW::MLite destroyed\n";
    return 1 unless $self && ref($self);
    #my $oo = $self->oracle;
    #my $mo = $self->mysql;
    #my $msoo = $self->multistore;
    #undef $oo;
    #undef $mo;
    #undef $msoo;
    return 1;
}


1;
