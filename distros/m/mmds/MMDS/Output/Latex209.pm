package MMDS::Output::Latex209;

# RCS Info        : $Id: Latex209.pm,v 1.3 2003-01-09 18:02:01+01 jv Exp $
# Author          : Johan Vromans
# Created On      : Mon Nov 25 21:08:30 2002
# Last Modified By: Johan Vromans
# Last Modified On: Tue Jan  7 14:23:24 2003
# Update Count    : 6
# Status          : Unknown, Use with caution!

use strict;

my $RCS_Id = '$Id: Latex209.pm,v 1.3 2003-01-09 18:02:01+01 jv Exp $ ';
my $my_name = __PACKAGE__;
my ($my_version) = $RCS_Id =~ /: .+,v ([\d.]+)/;
$my_version .= '*' if length('$Locker:  $ ') > 12;

use base qw(MMDS::Output::Latex);

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self->emul_209(1);
    bless $self, $class;
}

sub id_type {
    "latex209";
}

sub id_tag {
    "LaTeX-2.09";
}

print STDERR ("Loading plugin: $my_name $my_version\n") if $::verbose;

1;
