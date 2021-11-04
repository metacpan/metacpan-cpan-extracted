#!perl

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile;
use Path::Tiny;
use Data::Dumper;
use Test::More tests => 141;

my $muse = <<"MUSE";
#title My title
#author My author
#lang it
#pubdate 2018-09-05T13:30:34
#notes Seconda edizione riveduta e corretta: novembre 2018
#cover test.png

*** The standard Lorem Ipsum passage, used since the 1500s

"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat. Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum."

*** Section 1.10.32 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC

"Sed ut perspiciatis unde omnis iste natus error sit voluptatem
accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae
ab illo inventore veritatis et quasi architecto beatae vitae dicta
sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit
aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos
qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui
dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed
quia non numquam eius modi tempora incidunt ut labore et dolore magnam
aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum
exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex
ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in
ea voluptate velit esse quam nihil molestiae consequatur, vel illum
qui dolorem eum fugiat quo voluptas nulla pariatur?" 

*** 1914 translation by H. Rackham

"But I must explain to you how all this mistaken idea of denouncing
pleasure and praising pain was born and I will give you a complete
account of the system, and expound the actual teachings of the great
explorer of the truth, the master-builder of human happiness. No one
rejects, dislikes, or avoids pleasure itself, because it is pleasure,
but because those who do not know how to pursue pleasure rationally
encounter consequences that are extremely painful. Nor again is there
anyone who loves or pursues or desires to obtain pain of itself,
because it is pain, but because occasionally circumstances occur in
which toil and pain can procure him some great pleasure. To take a
trivial example, which of us ever undertakes laborious physical
exercise, except to obtain some advantage from it? But who has any
right to find fault with a man who chooses to enjoy a pleasure that
has no annoying consequences, or one who avoids a pain that produces
no resultant pleasure?" 

*** Section 1.10.33 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC


"At vero eos et accusamus et iusto odio dignissimos ducimus qui
blanditiis praesentium voluptatum deleniti atque corrupti quos dolores
et quas molestias excepturi sint occaecati cupiditate non provident,
similique sunt in culpa qui officia deserunt mollitia animi, id est
laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita
distinctio. Nam libero tempore, cum soluta nobis est eligendi optio
cumque nihil impedit quo minus id quod maxime placeat facere possimus,
omnis voluptas assumenda est, omnis dolor repellendus. Temporibus
autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe
eveniet ut et voluptates repudiandae sint et molestiae non recusandae.
Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis
voluptatibus maiores alias consequatur aut perferendis doloribus
asperiores repellat." 

*** 1914 translation by H. Rackham

"On the other hand, we denounce with righteous indignation and dislike
men who are so beguiled and demoralized by the charms of pleasure of
the moment, so blinded by desire, that they cannot foresee the pain
and trouble that are bound to ensue; and equal blame belongs to those
who fail in their duty through weakness of will, which is the same as
saying through shrinking from toil and pain. These cases are perfectly
simple and easy to distinguish. In a free hour, when our power of
choice is untrammelled and when nothing prevents our being able to do
what we like best, every pleasure is to be welcomed and every pain
avoided. But in certain circumstances and owing to the claims of duty
or the obligations of business it will frequently occur that pleasures
have to be repudiated and annoyances accepted. The wise man therefore
always holds in these matters to this principle of selection: he
rejects pleasures to secure other greater pleasures, or else he
endures pains to avoid worse pains."

MUSE

foreach my $options ({
                      # default
                     },
                     {
                      areaset_height => '50mm',
                     },
                     {
                      areaset_height => '',
                      areaset_width => '0',
                     },
                     {
                      areaset_height => undef,
                      areaset_width => undef,
                     },
                     {
                      areaset_width => '8cm',
                     },
                     {
                      areaset_width => '8cm',
                      areaset_height => '50mm',
                     },
                     {
                      tex_emergencystretch => '10pt',
                      tex_tolerance => 66666,
                     },
                     {
                      tex_emergencystretch => '0pt',
                     },
                     {
                      tex_tolerance => 66666,
                     },
                     {
                      fussy_last_word => 1,
                     },
                     {
                      ignore_cover => 1,
                     },
                     {
                      linespacing => '1.5',
                     },
                     {
                      linespacing => 'asdfasdf',
                     },
                     {
                      geometry_top_margin => '2cm',
                      geometry_outer_margin => '2cm',
                      areaset_height => '8cm',
                      areaset_width => '50mm',
                     },
                    ) {
    my $wd = Path::Tiny->tempdir(CLEANUP => !$ENV{NOCLEANUP});
    path(qw/t resources test.png/)->copy($wd->child('test.png')) or die;
    diag "Working on $wd for " . Dumper($options);

    my $c = Text::Amuse::Compile->new(tex => 1,
                                      pdf => $ENV{TEST_WITH_LATEX},
                                      extra => { papersize => 'a6',
                                                 %$options,
                                               });
    my $file = $wd->child("text.muse");
    $file->spew_utf8($muse);
    $c->compile("$file");
    my $pdf = $wd->child("text.pdf");
  SKIP:
    {
        skip "pdf $pdf not required", 1 unless $ENV{TEST_WITH_LATEX};
        ok $pdf->exists;
    }
    my $tex = $wd->child("text.tex")->slurp_utf8;
    if ($options->{areaset_width} && $options->{areaset_height} && !$options->{geometry_outer_margin}) {
        like($tex, qr/\\areaset\[current\]\{\Q$options->{areaset_width}\E\}\{\Q$options->{areaset_height}\E\}/,
             "options are fine") or diag $tex;
    }
    else {
        unlike $tex, qr{\\areaset};
    }
    like $tex, qr{^\\tolerance=}ms;
    if (!$options->{tex_tolerance} or $options->{tex_tolerance} > 10000) {
        like $tex, qr{^\\tolerance=200\b}ms, "Tolerance is 200 (default)" or die;
    }
    else {
        like $tex, qr{^\\tolerance=\Q$options->{tex_tolerance}\E\b}ms,
          "Tolerance is $options->{tex_tolerance}";
    }
    unlike $tex, qr{^\\sloppy}m, "Not sloppy";

    if ($options->{tex_emergencystretch} and $options->{tex_emergencystretch} =~ m/\A[0-9]+pt\z/) {
        like $tex, qr/^\\setlength\{\\emergencystretch\}\{\Q$options->{tex_emergencystretch}\E\}/ms;
    }
    else {
        like $tex, qr/^\\setlength\{\\emergencystretch\}\{30pt\}/ms;
    }


    if ($options->{fussy_last_word}) {
        like $tex, qr{^\\finalhyphendemerits=10000}ms;
    }
    else {
        unlike $tex, qr{^\\finalhyphendemerits=10000}ms;
    }
    if ($options->{ignore_cover}) {
        unlike $tex, qr{^\s*\\includegraphics}ms;
    }
    else {
        like $tex, qr{^\s*\\includegraphics}ms;
    }
    if (!$options->{format_id}) {
        like $tex, qr{^\% No format ID passed\.}ms;
    }
    else {
        unlike $tex, qr{^\% No format ID passed\.}ms;
    }
    if ($options->{geometry_outer_margin}) {
        like $tex, qr{\\usepackage\[%\s*
                      top=\Q$options->{geometry_top_margin}\E,%\s+
                      outer=\Q$options->{geometry_outer_margin}\E,%\s+
                      width=\Q$options->{areaset_width}\E,%\s+
                      height=\Q$options->{areaset_height}\E%\s+\]\{geometry\}
                 }sx;
    }
    if ($options->{linespacing} and $options->{linespacing} !~ /a/) {
        like $tex, qr{\\renewcommand\{\\baselinestretch\}\{1\.5\}}, "Found the line stretch"
    }
    else {
        unlike $tex, qr{baselinestretch}, "No line stretching changes";
    }
}
