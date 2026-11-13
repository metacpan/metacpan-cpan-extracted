use 5.016;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use Twilio::Http::Client;
use Twilio::Http::File;

my $URL  = 'https://trusthub.twilio.com/v1/Uploads';
my $http = Twilio::Http::Client->new;

# A byte that is not UTF-8, a NUL and a CRLF, which must all arrive as they are.
my $BINARY = "%PDF\xFF\x00\r\nend";

subtest 'a file is a name with optional contents and type' => sub {
  my $file = Twilio::Http::File->new('id.pdf', 'bytes', 'application/pdf');
  is($file->get_file_name,    'id.pdf',          'name');
  is($file->get_contents,     'bytes',           'contents');
  is($file->get_content_type, 'application/pdf', 'type');
  is($file->upload_name,      'id.pdf',          'a name with contents is sent as it is');
  is($file->bytes,            'bytes',           'bytes');

  my $from_disk = Twilio::Http::File->new('dir/id.pdf');
  is($from_disk->get_contents, undef,    'no contents for a path');
  is($from_disk->upload_name,  'id.pdf', 'a path is sent without its folders');
};

subtest 'contents from a path, a string or a filehandle' => sub {
  my $path = File::Spec->catfile(tempdir(CLEANUP => 1), 'id.pdf');
  open my $out, '>:raw', $path or die "Cannot write $path: $!\n";
  print {$out} $BINARY;
  close $out or die "Cannot write $path: $!\n";

  is(Twilio::Http::File->new($path)->bytes,        $BINARY, 'read from disk as bytes');
  is(Twilio::Http::File->new('a', $BINARY)->bytes, $BINARY, 'a string');

  open my $in, '<:raw', $path or die "Cannot read $path: $!\n";
  my $file = Twilio::Http::File->new('a', $in);
  is($file->bytes, $BINARY, 'a filehandle');
  is($file->bytes, $BINARY, 'read once and kept, so it is the same the second time');
  close $in or die "Cannot read $path: $!\n";

  is(Twilio::Http::File->new('a', q{})->bytes, q{}, 'an empty file');

  open my $read, '<', \'x' or die "Cannot open an in-memory file: $!\n";
  {
    local $/ = undef;
    readline $read;
  }
  is(Twilio::Http::File->new('a', $read)->bytes, q{}, 'a filehandle at its end is an empty file');
  close $read or die "Cannot close an in-memory file: $!\n";
};

subtest 'text with wide characters is not guessed' => sub {
  my $file = Twilio::Http::File->new('a', "\x{263A}");
  my $ok   = eval { $file->bytes; 1 };
  ok(!$ok, 'dies');
  like($@, qr/must be bytes/, 'and says to encode it');

  my $latin = "\xF1";
  utf8::upgrade($latin);
  is(Twilio::Http::File->new('a', $latin)->bytes, "\xF1", 'characters up to 255 are bytes');
};

subtest 'what a file cannot be' => sub {
  my @cases = (
    ['no name',          [],                               qr/needs a name/],
    ['an empty name',    [q{}],                            qr/needs a name/],
    ['a reference',      ['a', ['x']],                     qr/string or an open filehandle/],
    ['a line in a type', ['a', 'x', "text/plain\r\nX: y"], qr/line break/],
  );
  for my $case (@cases) {
    my ($name, $arguments, $error) = @{$case};
    my $ok = eval { Twilio::Http::File->new(@{$arguments}); 1 };
    ok(!$ok, "$name dies");
    like($@, $error, 'and says why');
  }

  my $missing = Twilio::Http::File->new(File::Spec->catfile(tempdir(CLEANUP => 1), 'none.pdf'));
  my $ok      = eval { $missing->bytes; 1 };
  ok(!$ok, 'a path that is not there dies when it is read');
  like($@, qr/Cannot read/, 'and says why');
};

subtest 'a file makes the form multipart' => sub {
  my $request = $http->prepare_request(
    'POST', $URL,
    {
      data => {
        File     => Twilio::Http::File->new('id.pdf', $BINARY, 'application/pdf'),
        FileName => 'id.pdf',
        Name     => "Jos\x{e9} \x{263A}",
        Skipped  => undef,
      }
    }
  );

  my ($boundary, @parts) = parts($request);
  like($boundary, qr/\Atwilio-[0-9a-f]{32}\z/, 'the boundary is in the Content-Type');
  is_deeply(
    \@parts,
    [
      qq{Content-Disposition: form-data; name="File"; filename="id.pdf"\r\n}
        . "Content-Type: application/pdf\r\n\r\n$BINARY",
      qq{Content-Disposition: form-data; name="FileName"\r\n\r\nid.pdf},
      qq{Content-Disposition: form-data; name="Name"\r\n\r\nJos\xC3\xA9 \xE2\x98\xBA},
    ],
    'one part per value, in sorted order, with text as UTF-8 and the file as it is'
  );
  like($request->{content}, qr/\r\n--\Q$boundary\E--\r\n\z/, 'the body ends with the boundary');
};

subtest 'parts of a multipart form' => sub {
  my $request = $http->prepare_request(
    'POST', $URL,
    {
      data => {
        Files => [Twilio::Http::File->new('a.txt', 'A'), 'note', Twilio::Http::File->new('b', 'B')],
        qq{say "hi"\r\nX-Injected: 1} => 'v',
      }
    }
  );

  my (undef, @parts) = parts($request);
  is_deeply(
    \@parts,
    [
      qq{Content-Disposition: form-data; name="Files"; filename="a.txt"\r\n}
        . "Content-Type: application/octet-stream\r\n\r\nA",
      qq{Content-Disposition: form-data; name="Files"\r\n\r\nnote},
      qq{Content-Disposition: form-data; name="Files"; filename="b"\r\n}
        . "Content-Type: application/octet-stream\r\n\r\nB",
      qq{Content-Disposition: form-data; name="say %22hi%22%0D%0AX-Injected: 1"\r\n\r\nv},
    ],
    'a list sends one part per item, a file has a type, and a name cannot add a header'
  );

  my $quoted = Twilio::Http::File->new(qq{a"b\nc.txt}, 'x');
  (undef, @parts) = parts($http->prepare_request('POST', $URL, { data => { F => $quoted } }));
  like($parts[0], qr/filename="a%22b%0Ac[.]txt"/, 'a file name is escaped the same way');
};

subtest 'the boundary never occurs in the body' => sub {
  my @drawn = ('twilio-taken', 'twilio-free');

  # A random draw that collides is too rare to test any other way. The first boundary drawn is
  # in the file, so a second one must be drawn.
  no warnings 'redefine';                                                         ## no critic (ProhibitNoWarnings)
  local *Twilio::Http::Client::_random_boundary = sub { return shift @drawn };    ## no critic (ProtectPrivateVars)

  my $file = Twilio::Http::File->new('a', 'before twilio-taken after');
  my ($boundary) = parts($http->prepare_request('POST', $URL, { data => { F => $file } }));
  is($boundary, 'twilio-free', 'a boundary found in a part is drawn again');
};

subtest 'without a file, nothing changes' => sub {
  my $form = $http->prepare_request('POST', $URL, { data => { A => 'b', List => ['x'] } });
  is($form->{headers}{'Content-Type'}, 'application/x-www-form-urlencoded', 'a form');
  is($form->{content},                 'A=b&List=x',                        'encoded as before');
};

done_testing;

# Returns the boundary and each part without the delimiters around it.
sub parts {
  my ($request) = @_;

  my ($boundary) =
    $request->{headers}{'Content-Type'} =~ m{\Amultipart/form-data; boundary=(\S+)\z}
    or return;
  my $body = $request->{content};
  $body =~ s/\r\n--\Q$boundary\E--\r\n\z// or return $boundary;
  my @parts = split /\r\n--\Q$boundary\E\r\n/, $body;
  $parts[0] =~ s/\A--\Q$boundary\E\r\n//;
  return ($boundary, @parts);
}
