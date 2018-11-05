#!perl
use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use Path::Tiny;
use Data::Dumper;
use Test::More tests => 21;

my $muse = <<'MUSE';
#title My title

Test 
MUSE

{
    my $c = Text::Amuse::Compile->new(tex => 1,
                                      fontspec => get_fontspec(),
                                      extra => { mainfont => 'AmuseWiki Serif',
                                                 monofont => 'AmuseWiki Mono',
                                                 sansfont => 'AmuseWiki Sans',
                                               }
                                     );
    my $fonts = $c->fonts;
    is $fonts->main->regular->basename, 'regular.otf';
    is $fonts->main->regular->extension, '.otf';
    is $fonts->main->regular->basename_and_ext, 'regular.otf';
    diag $fonts->main->regular->dirname;
    diag Dumper($fonts->definitions);
    foreach my $def (keys %{$fonts->definitions}) {
        my $defined = $fonts->definitions->{$def};
        ok $defined->{name};
        foreach my $attr (qw/ItalicFont BoldFont BoldItalicFont/) {
            ok $defined->{attr}->{$attr},
              "$attr in $def $defined->{name} is $defined->{attr}->{$attr}";
        }
        if ($fonts->main->regular->dirname =~ m/\A([A-Za-z0-9\.\/_-]+)\z/) {
            is $defined->{attr}->{Path}, $fonts->main->regular->dirname;
        }
        else {
            ok !$defined->{attr}->{Path}, "No Path provided";
        }


        diag $fonts->_fontspec_args($def, 'english');
        diag $fonts->_fontspec_args($def, 'russian');        
    }

    my $fontspec = $fonts->compose_polyglossia_fontspec_stanza(lang => 'english',
                                                               others => [qw/farsi 
                                                                             macedonian
                                                                             russian/],
                                                               bidi => 1,
                                                              );
    diag $fontspec;
}

{
    my $c = Text::Amuse::Compile->new;
    ok $c->fonts;
    diag $c->fonts->compose_polyglossia_fontspec_stanza;
}

{
    my $c = Text::Amuse::Compile->new(extra => { mainfont => 'Coelacanth' });
    ok $c->fonts;
    diag $c->fonts->compose_polyglossia_fontspec_stanza;
}

{
    my $c = Text::Amuse::Compile->new(extra => { mainfont => 'Coelacanthx' });
    ok $c->fonts;
    diag $c->fonts->compose_polyglossia_fontspec_stanza;
}



sub get_fontspec {
    my @list;
    foreach my $type (qw/serif sans mono/) {
        my %spec = (
                    type => $type,
                    name => "AmuseWiki " . ucfirst($type),
                    desc => "AmuseWiki " . ucfirst($type),
                   );
        foreach my $shape (qw/regular italic bold bolditalic/) {
            $spec{$shape} = path(qw/t fonts/, $shape . '.otf')->stringify;
        }
        push @list, \%spec;
    }
    return \@list;
}
