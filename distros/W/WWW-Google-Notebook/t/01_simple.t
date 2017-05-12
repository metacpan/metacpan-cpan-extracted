use strict;
use Test::More;

unless ($ENV{GOOGLE_USERNAME} and $ENV{GOOGLE_PASSWORD}) {
    Test::More->import(skip_all => "no username and password set, skipped.");
    exit;
}

plan tests => 17;

use WWW::Google::Notebook;

my $api = WWW::Google::Notebook->new(
    username => $ENV{GOOGLE_USERNAME},
    password => $ENV{GOOGLE_PASSWORD},
);
my $res = $api->login;
is($res, 1);

my $notebook = $api->add_notebook('WWW::Google::Notebook::Notebook');
isa_ok($notebook, 'WWW::Google::Notebook::Notebook');

my $note = $notebook->add_note('WWW::Google::Notebook::Note');
isa_ok($note, 'WWW::Google::Notebook::Note');

undef $notebook;
undef $note;

my $notebooks = $api->notebooks;
is(ref $notebooks, 'ARRAY');
($notebook) = grep { $_->title =~ /WWW::Google::Notebook::Notebook/ } @$notebooks;
isa_ok($notebook, 'WWW::Google::Notebook::Notebook');

my $ret = $notebook->rename('WWW::Google::Notebook::Notebook::test');
is($ret, 1);
is($notebook->title, 'WWW::Google::Notebook::Notebook::test');

my $notes = $notebook->notes;
is(ref $notes, 'ARRAY');
($note) = grep { $_->content =~ /WWW::Google::Notebook::Note/ } @$notes;
isa_ok($note, 'WWW::Google::Notebook::Note');

$ret = $note->edit('WWW::Google::Notebook::Note::test');
is($ret, 1);
is($note->content, 'WWW::Google::Notebook::Note::test');

$note->delete;
is_deeply($note, {});
isa_ok($note, 'WWW::Google::Notebook::Object::Has::Been::Deleted');
$notes = $notebook->notes;
($note) = grep { $_->content =~ /WWW::Google::Notebook::Note/ } @$notes;
is($note, undef);

$notebook->delete;
is_deeply($notebook, {});
isa_ok($notebook, 'WWW::Google::Notebook::Object::Has::Been::Deleted');
$notebooks = $api->notebooks;
($notebook) = grep { $_->title =~ /WWW::Google::Notebook::Notebook::test/ } @$notebooks;
is($notebook, undef);

