package urpm::xml_info_pkg;

use strict;

=head1 NAME

urpm::xml_info_pkg - XML Package data retrieving related routines for urpmi

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=item new($class, $hash, $pkg)

Returns a proxy object
It enable to get the XML info if available, otherwise redirects to URPM::Package

=cut

sub new {
    my ($class, $hash, $pkg) = @_;

    $pkg and $hash->{pkg} = $pkg;

    bless $hash, $class;
}


=item id($pkg)

=item group($pkg)

=item size($pkg)

=item epoch($pkg)

=item buildhost($pkg)

=item packager($pkg)

=item summary($pkg)

Only available in synthesis/hdlist
=cut

sub id        { $_[0]{pkg}->id }
sub group     { $_[0]{pkg}->group }
sub size      { $_[0]{pkg}->size }
sub epoch     { $_[0]{pkg}->epoch }
sub buildhost { $_[0]{pkg}->buildhost }
sub packager  { $_[0]{pkg}->packager }
sub summary   { $_[0]{pkg}->summary }
sub conflicts { $_[0]{pkg}->conflicts }
sub obsoletes { $_[0]{pkg}->obsoletes }
sub provides  { $_[0]{pkg}->provides }
sub requires  { $_[0]{pkg}->requires }
sub suggests  { $_[0]{pkg}->recommends_nosense }
sub recommends{ $_[0]{pkg}->recommends_nosense }


=item url($pkg)

=item license($pkg)

=item sourcerpm($pkg)

=item description($pkg)

=item changelogs($pkg)

=item files($pkg)

Can be directly available in xml_info

=cut

sub url         { exists $_[0]{url}         ? $_[0]{url}         : $_[0]{pkg}->url }
sub license     { exists $_[0]{license}     ? $_[0]{license}     : $_[0]{pkg}->license }
sub sourcerpm   { exists $_[0]{sourcerpm}   ? $_[0]{sourcerpm}   : $_[0]{pkg}->sourcerpm }
sub description { exists $_[0]{description} ? $_[0]{description} : $_[0]{pkg}->description }

sub changelogs  { exists $_[0]{changelogs} ? @{$_[0]{changelogs}} : $_[0]{pkg}->changelogs }

sub files { exists $_[0]{files} ? split("\n", $_[0]{files}) : $_[0]{pkg}->files }

my $fullname_re = qr/^(.*)-([^\-]*)-([^\-]*)\.([^\.\-]*)$/;

=item name($pkg)

=item version($pkg)

=item release($pkg)

=item arch($pkg)

=item fullname($pkg)

=item filename($pkg)

Available in both {pkg} and {fn}

=cut

sub name      { exists $_[0]{pkg} ? $_[0]{pkg}->name    : $_[0]{fn} =~ $fullname_re && $1 }
sub version   { exists $_[0]{pkg} ? $_[0]{pkg}->version : $_[0]{fn} =~ $fullname_re && $2 }
sub release   { exists $_[0]{pkg} ? $_[0]{pkg}->release : $_[0]{fn} =~ $fullname_re && $3 }
sub arch      { exists $_[0]{pkg} ? $_[0]{pkg}->arch    : $_[0]{fn} =~ $fullname_re && $4 }

sub fullname { wantarray() ? $_[0]{pkg}->fullname : $_[0]{fn} }
sub filename { $_[0]{fn} . '.rpm' }


1;

=back

=head1 COPYRIGHT

Copyright (C) 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2017 Mageia

=cut
