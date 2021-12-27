package Tripletail::Session::DB;
use strict;
use warnings;
use Tripletail;
use base 'Tripletail::Session';

use fields qw(dbgroup dbset readdbset sessiontable);
sub __new {
    my Tripletail::Session::DB $this = shift;

    if (!ref $this) {
        $this = fields::new($this);
        $this->SUPER::__new(@_);
    }

    $this->{dbgroup     } = $TL->INI->get($this->{group} => 'dbgroup');
    $this->{dbset       } = $TL->INI->get($this->{group} => 'dbset'  );
    $this->{readdbset   } = $TL->INI->get($this->{group} => readdbset    => $this->{dbset}              );
    $this->{sessiontable} = $TL->INI->get($this->{group} => sessiontable => 'tl_session_'.$this->{group});

    return $this;
}

sub _deleteSid {
    my Tripletail::Session::DB $this = shift;
    my $sid  = shift;

    my $DB   = $TL->getDB($this->{dbgroup});
    my $type = $DB->getType;

    $DB->execute(
        \$this->{dbset},
        sprintf(
            q{DELETE FROM %s WHERE sid = ?},
            $DB->symquote($this->{sessiontable}, $this->{dbset})),
        $sid);

    return $this;
}

1;

__END__

=encoding utf-8

=head1 NAME

Tripletail::Session::DB - 内部用

=head1 SEE ALSO

L<Tripletail::Session>

=head1 AUTHOR INFORMATION

=over 4

Copyright 2011 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
