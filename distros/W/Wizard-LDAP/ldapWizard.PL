# -*- perl -*-

use Config;

my $script;
$script =~ s/\~\~(\w+)\~\~/$Config::$Config{$1}/g;
if (!open(FILE, ">ldapWizard")  ||  !(print FILE $script)  ||  !close(FILE)) {
    die "Error while writing ldapWizard file: $!";
}
chmod 0755, "ldapWizard";
exit 0;


BEGIN { $script = <<'END_OF_SCRIPT' };
~~startperl~~
#
#   Wizard - A Perl package for implementing system administration
#            applications in the style of Windows wizards.
#
#
#   This module is
#
#           Copyright (C) 1999     Jochen Wiedmann
#                                  Am Eisteich 9
#                                  72555 Metzingen
#                                  Germany
#
#                                  Email: joe@@ispsoft.de
#                                  Phone: +49 7123 14887
#
#                          and     Amarendran R. Subramanian
#                                  Grundstr. 32
#                                  72810 Gomaringen
#                                  Germany
#
#                                  Email: amar@@neckar-alb.de
#                                  Phone: +49 7072 920696
#
#   All Rights Reserved.
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#

use strict;

use Wizard::Shell ();
use Getopt::Long ();

use vars qw($opt_class);
$opt_class = "Wizard::LDAP";

Getopt::Long::GetOptions('debug', 'verbose', 'class=s');

my $class_pm = $opt_class;
$class_pm =~ s/\:\:/\//g;
require "$class_pm.pm";

my $wiz = Wizard::Shell->new();
my $state = $wiz->State($opt_class->new({}));

while ($state->Running()) {
    $state = $wiz->Run($state);
}
exit 0;

__END__

=pod

=head1 NAME

Wizard - An Application Wizard


=head1 SYNOPSIS

  Wizard --class=<class> [options]


=head1 DESCRIPTION

The Application Wizard is a script for running small, Perl driven system
administration tools in the sense of Windows Wizards. The script is based
on the Perl package I<Wizard>. L<Wizard>


=head1 AUTHORS AND COPYRIGHT

This module is

  Copyright (C) 1999     Jochen Wiedmann
                         Am Eisteich 9
                         72555 Metzingen
                         Germany

                         Email: joe@@ispsoft.de
                         Phone: +49 7123 14887

                 and     Amarendran R. Subramanian
                         Grundstr. 32
                         72810 Gomaringen
                         Germany

                         Email: amar@@neckar-alb.de
                         Phone: +49 7072 920696

All Rights Reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.


=head1 SEE ALSO

L<Wizard(3)>, L<Wizard::Shell(3)>

=cut

END_OF_SCRIPT

