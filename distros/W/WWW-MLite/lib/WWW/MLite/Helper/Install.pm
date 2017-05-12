package WWW::MLite::Helper::Install;
use strict; # $Id: Install.pm 22 2014-07-24 14:09:51Z minus $
use Encode;

=pod

On future: encoding utf-8

=encoding windows-1251

=head1 NAME

WWW::MLite::Helper::Install - Helper of install Your project

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use WWW::MLite::Helper::Install;
    
    WWW::MLite::Helper::Install::install(
        DIRPROJECT => getcwd(),
    ) or exit;

=head1 DESCRIPTION

Helper of install Your project. Please use it ONLY in Makefile.PL

=head2 METHODS

=over 8

=item B<install>

    WWW::MLite::Helper::Install::install(
            FOO => 'foo',
            BAR => 'bar',
            BAZ => 'baz',
            # ...
        );

Install Your project

=back

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

use vars qw($VERSION);
$VERSION = '1.00';

use constant {
        SKELDIR     => "share/skel",
        NOTSKEL     => "Skeleton is not builded! Please check your project content",
        TESTFILE    => "index.cgi",
        PERM_RWX    => 0755,
        PERM_DIR    => 0777,
    };

use CTK;
use TemplateM;
use Try::Tiny;
use File::Find;
use Cwd;
my $basedir = getcwd();

sub install {
    my %h = @_;
    my $c = new CTK;
    my $srcdir = CTK::catdir(".",SKELDIR);

    # Проверка на уже установленную систему
    my $testfile = TESTFILE;
    if ((-e $testfile) && $c->cli_prompt("Project already installed. Do You want to reinstall it?:",'no') !~ /^\s*y/i) {
        say("Bye.");
        return 0;
    }

    # Начала установки
    say("Project installing...");
    chdir($srcdir);
    find({ wanted => sub {
            if (-f $_) {
                my $dst = CTK::catfile($basedir, $File::Find::dir, $_);
                say "\tProcessing file $_ --> $dst";
                try {
                    my $tpl = new TemplateM(-file => $_, -asfile => 1);
                    $tpl->stash({%h});
                    $tpl->cast_if('WIN32', $c->isostype("Windows"));
                    CTK::bsave($dst, $tpl->output(), 0) 
                        if ((!-e $dst) || $c->cli_prompt("File \"$dst\" already exists. Overwrite it?:",'no') =~ /^\s*y/i);
                    if ($_ =~ /(\.cgi)|(\.pl)|(\.sh)$/) {
                        chmod PERM_RWX, $dst;
                    } elsif ($File::Find::dir =~ /[^a-z0-1]bin$/i) {
                        chmod PERM_RWX, $dst;
                    }
                } catch {
                    say("\tERROR: $_");
                };
            } elsif (-d $_) {
                if ($_ !~ /^\.+$/) {
                    my $dst = CTK::catdir($basedir, $File::Find::dir, $_);
                    if (!-e $dst) {
                        say "\tCreating directory $dst";
                        mkdir $dst;
                        chmod PERM_DIR, $dst;
                    }
                }
            } else {
                say "\tSkipped $_. This is not file and not directory"
            }
            
        },
        }, ".");
    chdir($basedir);
    
}

1;

