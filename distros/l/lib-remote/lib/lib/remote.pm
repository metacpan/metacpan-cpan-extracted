package lib::remote;

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
#~ use Data::Dumper;
use Carp qw(croak carp);

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';
our $CODE_NAME = 'Gloria';
my $pkg = __PACKAGE__;

my $url_re = qr#^(https?|ftp|file)://#i;

my $config = {#сохранение списка пар "Имя::модуля"=>{opt_name => ..., ..., ...}
    $pkg => {
        ua => LWP::UserAgent->new,
        require=>1,
        cache=>1,
        debug=>0,
        _INC=> [],# список общих путей like @INC
    },
};

my $module_content = sub {# @INC диспетчер
    my $arg = shift;#Имя/Модуля.pm
    
    my $path = my $mod = $arg;
    $mod =~ s|/+|::|g;
    $mod =~ s|\.pm$||g;
    $path =~ s|::|/|g;
    $path =~ s|\.pm$||;
    $path .= '.pm';
    
    my $conf = $config->{$mod};
    my $debug = ($conf && $conf->{debug}) // $config->{$pkg}{debug};
    my $cache = ($conf && $conf->{cache}) // $config->{$pkg}{cache};
    
    carp "$pkg->INC_dispatcher: try dispatch of [$mod][path=$path][arg=$arg]]" if $debug;
    
    if ($cache && $conf && $conf->{_content}) {
        carp "$pkg->INC_dispatcher: get cached content of [$mod]" if $debug;
        return $conf->{_content};
    }

    my $content;
    
    if ($conf && $conf->{url} && $conf->{url} =~ /$url_re/) {# конкретный модуль
        my $url = $conf->{url};
        $url .= $conf->{url_suffix} if $conf->{url_suffix};
        $content = _lwpget($url);
        carp "$pkg->INC_dispatcher: success LWP get content [$mod] by url=[ $url ]" if $debug && $content;
        carp "$pkg->INC_dispatcher: couldn't get content the module [$mod] by url=[ $url ]" if $debug && !$content;
    }
    unless ($content) {# перебор удаленных папок
        for (@{$config->{$pkg}{_INC}}) {
            s|/$||;
            my $url = "$_/$path";
            $url .= $conf->{url_suffix} if $conf->{url_suffix};
            #~ carp "$pkg: try get [$_/$path] for [$mod]" if $debug;#": get [$mod] content";
            $content = _lwpget($url);
            if ($content) {
                carp "$pkg->INC_dispatcher: success LWP get content [$mod] by url [ $url ]" if $debug;#": get [$mod] content";
                last;
            }
        }
    }
    
    $config->{$mod}{_content} = $content if $cache && $content;

    return $content;
};

BEGIN {
    push @INC, sub {# диспетчер
        my $self = shift;# эта функция CODE(0xf4d728) вроде не нужна
        my $content = $module_content->(@_)
            or return undef;
        open my $fh, '<', \$content or die "Cant open: $!";
        return $fh;
    };
}

sub import { # это разбор аргументов после строк use lib::remote ...
    my $pkg_or_obj = shift;
    carp "$pkg->import: incoming args = [ @_ ]" if $config->{$pkg}{debug};
    $pkg->config(@_);
    
    my $module;
    for my $module (@{$config->{$pkg}{_last_config_modules}}) {
        my $require = $config->{$module}{require} // $config->{$pkg}{require};
        my $debug = $config->{$module}{debug} // $config->{$pkg}{debug};
        if ( $require ) {
            #~ eval "use $module;";# вот сразу заход в диспетчер @INC
            eval {require $module};
            if ($@) {
                carp "$pkg->import: возможно проблемы с модулем [$module]: $@";
            } elsif ($debug) {
                carp "$pkg->import: success done [require $module]\n"  if $debug;
                $config->{$module}{_require_ok}++;
            }
        }
        my $import = $config->{$module}{import};# || $config->{$pkg}{import};
        
        if ($require && $import && @$import) {
            eval {$module->import(@$import)};
            if ($@) {
                carp "$pkg->import: возможно проблемы с импортом [$module]: $@";
            } else {
                carp "$pkg->import: success done [$module->import(@{[@$import]})]\n" if $debug;
                $config->{$module}{_import_ok}++;
            }
        }
    }
}

sub config {
    my $pkg_or_obj = shift;
    my $module;
    delete $config->{$pkg}{_last_config_modules};
    for my $arg (@_) {
        my $opt = _opt($arg);
        if ($module) {
            if ( $module eq $pkg ) {
                my $url = delete $opt->{url};
                push @{$config->{$pkg}{_INC}}, $url if $url && $url =~ /$url_re/ && !($url ~~ @{$config->{$pkg}{_INC}});
            } else {
                push @{$config->{$pkg}{_last_config_modules}}, $module;
            }
            @{$config->{$module}}{keys %$opt} = values %$opt;
            $module = undef; # done pair
        } elsif ($opt->{url} && $opt->{url} =~ /$url_re/) {
            push @{$config->{$pkg}{_INC}}, $opt->{url} unless $opt->{url} ~~ @{$config->{$pkg}{_INC}};#$unique{$arg}++;
        } elsif (!ref($arg)) {
            $module = $arg;
        } else {
            @{$config->{$pkg}}{keys %$opt} = values %$opt; # [] {}
        }
    }
    push @{$config->{$pkg}{_last_config_modules}}, $module if $module; 
    return $config;
}

sub new {
    my $pkg = shift;
    bless $pkg->config(@_);
}

sub module {
    my $pkg_or_obj = shift;
    $pkg_or_obj->import(@_);
    return $config->{$pkg}{_last_config_modules}[0];
}

sub _opt {
    my $arg  = shift;
    return {} unless defined $arg;
    my $ret = {url=>$arg,} unless ref($arg);
    $ret ||= {$arg->[0] =~ /$url_re/ ? (url=>@$arg) : @$arg,} if ref($arg) eq 'ARRAY';
    $ret ||= $arg if ref($arg) eq 'HASH';
    return $ret;
}

sub _lwpget {
    my $url = shift;
    my $get = $config->{$pkg}{ua}->get($url);
    if ( $get->is_success ) {
        return $get->decoded_content();# ??? ->content нужно отладить charset=>'cp-1251'
    } else {
        return undef;
    }
}

=encoding utf8

=head1 ПРИВЕТСТВИЕ SALUTE

Доброго всем! Доброго здоровья! Доброго духа!

Hello all! Nice health! Good thinks!


=head1 NAME

lib::remote - pragma, functional and object interface for load and use/require modules from remote sources without installation basically throught protocols like http (LWP). One dispather on @INC - C<push @INC, sub {};> This dispather will return filehandle for downloaded content of a module from remote server. 

lib::remote - Удаленная загрузка и использование модулей. Загружает модули с удаленного сервера. Только один диспетчер в @INC- C<push @INC, sub {...};>. Диспетчер возвращает filehandle для контента, полученного удаленно. Смотреть perldoc -f require.

Идея из L</http://forum.codecall.net/topic/64285-perl-use-modules-on-remote-servers/>

Кто-то еще стырил L</http://www.linuxdigest.org/2012/06/use-modules-on-remote-servers/> (поздняя дата и есть ошибки)


=head1 FAQ

Q: Зачем? Why?

A: За лосем. For elk.

Q: Почему? And so why?

A: По кочану. For head of cabbage.

Q: Как? How?

A: Да вот так. Da vot tak.


=head1 SYNOPSIS

Все просто. По аналогии с локальным вариантом:

    use lib '/to/any/local/lib';

указываем урл:

    # pragma interface at compile time
    use lib::remote 'http://<хост(host)>/site-perl/.../';
    use My::Module1;
    ...

Искомый модуль будет запрашиваться как в локальном варианте, дописывая в конце URL: http://<хост(host)>/site-perl/.../My/Module1.pm

Допустим, УРЛ сложнее, не содержит имени модуля или используются параметры: https://<хост>/.../?key=ede35ac1208bbf479&...

Тогда делаем пары ключ->значение, указывая КОНКРЕТНЫЙ урл для КОНКРЕТНОГО модуля, например:

    use lib::remote
        'Some::Module1'=>'https://<хост>/.../?key=ede35ac1208bbf479&...',
        'SomeModule2'=>'ssh://user:pass@host:/..../SomeModule2.pm',
    ;
    #use Some::Module1; не нужно, уже сделано require (см. "Опцию [require] расширенного синтаксиса")
    use SomeModule2 qw(func1 func2), [<what ever>, ...];# только, если нужно что-то импортировать очень сложное (см. "Опцию [import] расширенного синтаксиса")
    use parent 'Some::Module1'; # такое нужно
    ...


B<Внимание>

Конкретно указанный модуль (через пару) будет искаться сначала в своем урл, а потом во всех заданных урлах глобального конфига.

При многократном вызове use lib::remote все параметры и урлы сохраняются, аналогично use lib '';, но естественно не в @INC. Повторюсь, в @INC помещается только один диспетчер.

=head2 Расширенный синтаксис Extended syntax

=head3 Pragma variant

    use lib::remote
        # global config for modules unless them have its own
        'http://....', # push to search list urls
        ['http://....', opt1 =>..., opt2 =>..., ....], # push to search list urls
        {url=>'http://....', opt1 =>..., opt2 =>..., ....}, # push to search list urls

and per module personal options

        'Some::Module1'=> 'http://....',
        'Some::Module2'=>['http://...', opt1 =>..., opt2 =>..., ....],
        'Some::Module3'=>{url => 'http://...', opt1 =>..., opt2 =>..., ....},
        'SomeModule1'=>['ssh://user@host:/..../SomeModule2.pm', 'pass'=>..., ...],
        'SomeModule2'=>{url => 'ssh://user@host:/..../SomeModule2.pm', 'pass'=>..., ...},
    ;


=head3 Functional variant - is runtime and you cant import symbols

    use lib::remote;
    my $conf = lib::remote->config('http://....');
    # DONT WORK -> lib::remote::module('Foo::');
    # OK
    lib::remote->module('Foo::One'=>'http://...', )::foo(...);
    

=head3 Object variant  - is runtime and you cant import symbols

    use lib::remote;
    my $dispatcher = lib::remote->new(<list options>);
    my $foo2 = $dispatcher->module('Foo::Two')->new();



=head2 Опции Options

Не трудно догадаться, что вычленение пар в общем списке import/config происходит по специфике URI.

=over 4

=item * url => '>schema://>...' Это основной параметр. На уровне глобальной конфигурации сохраняется список всех урлов, к которым добавляется путь Some/Module.pm

=item * url_suffix 

=item * charset => 'utf8', Задать кодировку урла. Если веб-сервер правильно выдает C<Content-Type: ...; charset=utf8>, тогда не нужно, ->decoded_content сработает. Помнить про C<use utf8;>

=item * require => 1|0 Cрабатывает require Some::Module1; Поэтому не нужно делать строку use|require Some::Module;, если только нет хитрых импортов (см. опцию import ниже)

=item * import => [qw(), ...]. The import spec for loaded module. Disadvantage!!! Work on list of scalars only!!! Просто вызывается Some::Module1->import(...);

=item * cache => 1|0 Content would be cached

=item * debug => 0|1 warn messages

=item * что еще?

=back


Можно многократно вызывать use lib::remote ...; и тем самым изменять настройки модулей и глобальные опции.

Url может возвращать сразу пачку модулей (package). В этом случае писать ключом один модуль и дополнительно вызывать use/require для остальных модулей.

=head1 EXPORT

Ничего не экспортируется.

=head1 SUBROUTINES/METHODS

This is runtime.

=head2 new(<options list>)  Create lib::remote object and apply/merge options. All created objects are one variable.

=head2 module(<options list>) Try to load and require modules. Return the name of first parsed module in list of options.

=head2 config(<options list>) Apply/merge options to lib::remote package.

=head1 Требования REQUIRES

Если урлы 'http://...', 'https://...', 'ftp://...', 'file://...', то нужен LWP::UserAgent

Если 'ssh://...' - TODO

=head1 Пример конфига для NGINX, раздающего модули:

    ...
    server {
        listen       81;
#        server_name  localhost;


        location / {
            charset utf-8;
            charset_types *;
            root   /home/perl/lib-remote/;
            index  index.html index.htm;
        }

    }
    ...


=head1 AUTHOR

Mikhail Che, C<< <m[пёсик]cpan.org> >>

=head1 BUGS

Пишите.

Please report any bugs or feature requests to C<bug-lib-remote at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=lib-remote>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc lib::remote


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=lib-remote>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/lib-remote>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/lib-remote>

=item * Search CPAN

L<http://search.cpan.org/dist/lib-remote/>

=back


=head1 ACKNOWLEDGEMENTS

Не знаю.

=head1 SEE ALSO

perldoc -f require.

Глянь L<PAR>

Глянь L<Remote::Use>

Глянь L<lib::http>

Глянь L<lib::DBI>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Mikhail Che.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 DISTRIB

$ module-starter --module=lib::remote --author=”Mikhail Che” --email=”m.che@cpan.org" --builder=Module::Build --license=perl --verbose

$ perl Build.PL

$ ./Build test

$ ./Build dist


=cut

1; # End of lib::remote
