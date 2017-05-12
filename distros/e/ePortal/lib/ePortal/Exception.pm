#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------


package ePortal::Exception;
    our $VERSION = '4.5';
    use base qw/Error/;

    use ePortal::Utils;
    use ePortal::Global;

############################################################################
sub new {   #02/26/03 9:22
############################################################################
    my $class = shift;
    my %p = @_;

    local $Error::Debug = 1;
    local $Error::Depth = $Error::Depth + 1;
    return $class->SUPER::new(%p);
}##new


############################################################################
# Description:
#    local $Error::Depth = $Error::Depth + 1;
#    my $self = $class->SUPER::new(%p);
#    $self->add_minimal_stacktrace();
#
############################################################################
sub add_minimal_stacktrace  {   #01/22/2004 4:28
############################################################################
    my $self = shift;
    
    # local $Error::Depth = 1;
    # this produces a lot of debug information. truncate it
    my @lines = split("\n", $self->stacktrace);
    my ($stacktrace, $called_at_counter) = (undef,0);
    foreach (@lines) {
        $called_at_counter++ if /called at/;
        last if $called_at_counter > 5;     # MAX depth of stacktrace
        $stacktrace .= "$_\n";
    }
    $self->{'-stacktrace'} = $stacktrace;
}##add_minimal_stacktrace


#===========================================================================
# Abort current request immediately. Do not output anything.
# Used for attacments.
package ePortal::Exception::Abort;
    our @ISA = qw/ePortal::Exception/;


#===========================================================================
package ePortal::Exception::DataNotValid;
    our @ISA = qw/ePortal::Exception/;
    # -text - description what is invalid




#===========================================================================
package ePortal::Exception::BadUser;
    our @ISA = qw/ePortal::Exception/;
    # -text - description what is invalid
    # -reason - error code
  my %reasons = (
    bad_user      => {
        rus => "Пользователь с таким именем не существует",
        eng => "Bad user name"},
    bad_password  => {
        rus => "Вы ввели неправильный пароль",
        eng => "Bad password"},
    md5_changed   => {
        rus => "Полученная информация не достоверна",
        eng => "MD5 checksum incorrect"},
    ip_changed    => {
        rus => "Адрес компьютера изменился",
        eng => "Client TCP/IP address changed"},
    no_user       => {
        rus => "Неизвестный пользователь или не указано имя пользователя",
        eng => "No user name or user unknown"},
    disabled      => {
        rus => "Бюджет пользователя отключен",
        eng => "User is disabled"},
    system_error  => {
        rus => "Системная ошибка",
        eng => "System error"},
  );
############################################################################
sub new {   #02/26/03 9:22
############################################################################
    my $class = shift;
    my %p = @_;

    if ($p{'-text'} eq '' and $p{'-reason'} ne '') {
      $p{'-text'} = ePortal::Utils::pick_lang( $reasons{ $p{'-reason'} } );
    }
    $p{'-text'} = ePortal::Utils::pick_lang( rus => "Неизвестная причина отказа", eng => "Unknown error occured")
      if $p{'-text'} eq '';

    local $Error::Depth = $Error::Depth + 1;
    my $self = $class->SUPER::new(%p);
    # $self->add_minimal_stacktrace; # don't need it

    return $self;
}##new




#===========================================================================
package ePortal::Exception::ObjectNotFound;
    our @ISA = qw/ePortal::Exception/;

    # -text - description
    # -object - empty object where restore() fail
    # -value - id requested
############################################################################
sub new {   #02/26/03 9:22
############################################################################
    my $class = shift;
    my %p = @_;

    $p{'-text'} ||= ePortal::Utils::pick_lang(
                rus => "Не могу найти указанный объект",
                eng => "Object not found");

    local $Error::Depth = $Error::Depth + 1;
    my $self = $class->SUPER::new(%p);
    $self->add_minimal_stacktrace;

    return $self;
}##new


#===========================================================================
package ePortal::Exception::DatabaseNotConfigured;
    our @ISA = qw/ePortal::Exception/;
    # DB storage does not exists or need upgrade
############################################################################
sub new {   #02/26/03 9:22
############################################################################
    my $class = shift;
    my %p = @_;

    $p{-text} ||= 'Database storage does not exists or old version. Need upgrade.';

    local $Error::Depth = $Error::Depth + 1;
    my $self = Error::new($class, %p);
    return $self;
}##new


#===========================================================================
package ePortal::Exception::DBI;
    our @ISA = qw/ePortal::Exception/;
    # -text -  Error description
    # -object dbh

############################################################################
sub new {   #02/26/03 9:22
############################################################################
    my $class = shift;
    my %p = @_;

    local $Error::Depth = $Error::Depth + 1;
    my $self = Error::new($class, %p);

    $self->add_minimal_stacktrace;

    return $self;
}##new


#===========================================================================
package ePortal::Exception::FileNotFound;
    our @ISA = qw/ePortal::Exception/;
    # -file - file that not exists

############################################################################
sub new {   #02/26/03 9:22
############################################################################
    my $class = shift;
    my %p = @_;

    $p{'-text'} = "File " . $p{'-file'} . " not found or not exists";

    local $Error::Depth = $Error::Depth + 1;
    return $class->SUPER::new(%p);
}##new


#===========================================================================
package ePortal::Exception::ApplicationNotInstalled;
    our @ISA = qw/ePortal::Exception/;
    # -app - application name

############################################################################
sub new {   #02/26/03 9:22
############################################################################
    my $class = shift;
    my %p = @_;

    $p{'-text'} = ePortal::Utils::pick_lang( {
        rus => "Приложение " . $p{'-app'} . " не установлено",
        eng => "Application " . $p{'-app'} . " is not installed"});

    local $Error::Depth = $Error::Depth + 1;
    return $class->SUPER::new(%p);
}##new


#===========================================================================
package ePortal::Exception::Fatal;
    our @ISA = qw/ePortal::Exception/;
    # -text - text of fatal exception

############################################################################
sub new {   #02/26/03 9:22
############################################################################
    my $class = shift;
    my %p = @_;

    local $Error::Depth = $Error::Depth + 1;
    my $self = $class->SUPER::new(%p);
    $self->add_minimal_stacktrace;

    return $self;
}##new



#===========================================================================
package ePortal::Exception::ACL;
    our @ISA = qw/ePortal::Exception/;
    # -operation
    # -object

############################################################################
sub new {   #02/26/03 9:22
############################################################################
    my $class = shift;
    my %p = @_;

    my %causes = (
       read => ePortal::Utils::pick_lang(
                 rus => 'У вас нет прав на просмотр данного объекта',
                 eng => 'Cannot read object. Access denied.'),
       insert => ePortal::Utils::pick_lang(
                 rus => 'У вас нет прав на создание объекта данного типа',
                 eng => 'Cannot create object. Access denied.'),
       update => ePortal::Utils::pick_lang(
                 rus => 'У вас нет прав на изменение объекта данного типа',
                 eng => 'Cannot update object. Access denied.'),
       delete => ePortal::Utils::pick_lang(
                 rus => 'У вас нет прав на удаление объекта данного типа',
                 eng => 'Cannot delete object. Access denied.'),
       admin => ePortal::Utils::pick_lang(
                 rus => 'У вас нет прав на изменение прав доступа к этому объекту',
                 eng => "You don't have right to modify access rights of this object"),
       require_registered => ePortal::Utils::pick_lang(
                 rus => "Вы не зарегистрированы в системе",
                 eng => "You are not logged in"),
       require_user => ePortal::Utils::pick_lang(
                 rus => "Администратор не разрешал Вам доступ к этому ресурсу",
                 eng => "Administrator has denied your access to this resource"),
       require_group => ePortal::Utils::pick_lang(
                 rus => "Вы не входите в группу тех, кому разрешен доступ к ресурсу",
                 eng => "Your are not member of group of users who has access to this resource"),
       require_admin => ePortal::Utils::pick_lang(
                 rus => "Доступ разрешен только администратору системы",
                 eng => "Only admin may do it"),
       require_sysacl => ePortal::Utils::pick_lang(
                 rus => "Администратор не разрешал Вам доступ к этому ресурсу",
                 eng => "Administrator has denied your access to this resource"),
    );
    $p{'-text'} ||= $causes{ $p{'-operation'} };

    local $Error::Depth = $Error::Depth + 1;
    return $class->SUPER::new(%p);
}##new



1;
