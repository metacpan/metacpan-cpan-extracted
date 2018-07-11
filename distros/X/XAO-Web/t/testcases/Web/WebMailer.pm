package testcases::Web::WebMailer;
use strict;
use IO::File;
use XAO::Projects;
use XAO::Utils;

use utf8;

use base qw(XAO::testcases::Web::base);

###############################################################################

sub set_up {
    my $self=shift;

    $self->SUPER::set_up();

    my $homedir=$XAO::Base::projectsdir.'/test';
    -d $homedir || die "No directory $homedir\n";
    my $outfile=$homedir.'/web-mailer.tmp';

    $self->{'outfile'}=$outfile;

    ### dprint "..home=$homedir output=$outfile";

    $self->siteconfig->put('/mailer/method' => 'local');
    $self->siteconfig->put('/mailer/agent'  => "$homedir/bin/fake-sendmail '$outfile'");
}

###############################################################################

sub tear_down {
    my $self=shift;

    unlink $self->{'outfile'} if $self->{'outfile'} && -f $self->{'outfile'};

    $self->SUPER::tear_down();
}

###############################################################################

sub test_mailer {
    my $self=shift;

    my $have_email_mime;
    eval {
        require Email::MIME;
        $have_email_mime=1;
    };
    if($@) {
        dprint "Email::MIME is not available, skipping some checks";
    }

    my %tests=(
        t01 => {
            config  => {
                '/charset'  => undef,
            },
            args    => {
                template    => 'foobarbaz',
                to          => 'to@test.org',
                from        => 'from@test.org',
                subject     => 'Subject123',
            },
            regex   => [
                qr/foobarbaz/,
                qr/Subject:\s+Subject123/,
                qr/MIME-Version:/,
                qr/Content-Type:\s+text\/plain/,
                qr/From:.*from\@test\.org/,
                qr/To:.*to\@test\.org/,
                qr/Content-Transfer-Encoding:\s+binary/,
            ],
            parts_count => 0,
        },
        t02 => {
            config  => {
                '/charset'  => 'UTF-8',
                '/mailer/transfer_encoding' => '8bit',
            },
            args    => {
                template    => 'foobarbaz',
                to          => 'to@test.org',
                from        => 'from@test.org',
                subject     => "Subject \x{2122}",
            },
            decode  => 'utf8',
            regex   => [
                qr/foobarbaz/s,
                qr/Subject:\s+=\?(?i:utf-8)\?Q\?Subject(?:_|=20)=E2=84=A2\?=/s,
                qr/MIME-Version:/s,
                qr/Content-Type:\s+text\/plain;\s+charset="?UTF-8"?/s,
                qr/Content-Transfer-Encoding:\s+8bit/s,
            ],
            parts_count => 0,
        },
        t03a => {
            config  => {
                '/charset'                  => 'UTF-8',
                '/mailer/transfer_encoding' => '8bit',
                '/xao/character_mode'       => 1,
            },
            args    => {
                'html.template' => Encode::encode('utf8',"<h1>3M\x{2122}</h1>"),
                to              => 'to@test.org',
                from            => 'from@test.org',
                subject         => Encode::encode('utf8',"Hello \x{263a}"),
            },
            decode  => 'utf8',
            regex   => [
                qr/3M\x{2122}/s,
                qr/Subject:\s+Hello \x{263a}/s,
                qr/MIME-Version:/s,
                qr/Content-Type:\s+text\/html;\s+charset="?UTF-8"?/s,
                qr/Content-Transfer-Encoding:\s+8bit/s,
            ],
            parts_count => 0,
        },
        t03b => {
            config  => {
                '/charset'                  => 'UTF-8',
                '/mailer/transfer_encoding' => '8bit',
                '/xao/character_mode'       => 1,
            },
            args    => {
                'html.template' => "<h1>3M\x{2122}</h1>",
                to              => 'to@test.org',
                from            => 'from@test.org',
                subject         => "Hello \x{263a}",
            },
            decode  => 'utf8',
            regex   => [
                qr/3M\x{2122}/s,
                qr/Subject:\s+=\?(?i:utf-8)\?Q\?Hello(?:_|=20)=E2=98=BA\?=/s,
                qr/MIME-Version:/s,
                qr/Content-Type:\s+text\/html;\s+charset="?UTF-8"?/s,
                qr/Content-Transfer-Encoding:\s+8bit/s,
            ],
            parts_count => 0,
        },
        t04 => {
            config  => {
                '/charset'                  => 'UTF-8',
                '/mailer/transfer_encoding' => 'quoted-printable',
                '/xao/character_mode'       => 1,
            },
            args    => {
                'html.template' => "HTML-CONTENT \x{263a}",
                'text.template' => "TEXT-CONTENT \x{2122}",
                to              => 'to@test.org',
                from            => 'from@test.org',
                subject         => 'SUBJECT-CONTENT',
            },
            decode  => 'utf8',
            regex   => [
                qr/TEXT-CONTENT =E2=84=A2=/,
                qr/HTML-CONTENT =E2=98=BA=/,
                qr/Content-Type:\s+multipart\/alternative/,
                qr/Content-Type:\s+text\/plain/,
                qr/Content-Type:\s+text\/html/,
            ],
            parts_count => 2,
        },
        t05 => {            # TEXT and an attachment
            config  => {
                '/charset'                  => 'UTF-8',
                '/mailer/transfer_encoding' => 'quoted-printable',
                '/xao/character_mode'       => 1,
            },
            args    => {
                'text.template'         => "TEXT-CONTENT \x{2122}",
                to                      => 'to@test.org',
                from                    => 'from@test.org',
                subject                 => 'SUBJECT-CONTENT',
                'attachment.1.path'     => '/clear.gif',
                'attachment.1.unparsed' => 1,
                'attachment.1.type'     => 'image/gif',
                'attachment.1.filename' => 'clear.gif',
            },
            decode  => 'utf8',
            regex   => [
                qr/TEXT-CONTENT =E2=84=A2=/,
                qr/Content-Type:\s+text\/plain/,
                qr|R0lGODdhAQABAIAAAP///wAAACwAAAAAAQABAAACAkQBADs=|,   # clear.gif in Base64
                qr|Content-Disposition:\s+attachment;\s*filename="clear\.gif"|,
                qr|Content-Type:\s+image/gif|,
            ],
            parts_count => 2,
        },
        t06 => {           # HTML and attachments
            config  => {
                '/charset'                  => 'UTF-8',
                '/mailer/transfer_encoding' => 'quoted-printable',
                '/xao/character_mode'       => 1,
            },
            args    => {
                'html.template'         => "HTML-CONTENT \x{263a}",
                to                      => 'to@test.org',
                from                    => 'from@test.org',
                subject                 => 'SUBJECT-CONTENT',
                'attachment.a.path'     => '/clear.gif',
                'attachment.a.unparsed' => 1,
                'attachment.a.type'     => 'image/gif',
                'attachment.a.filename' => 'clear.gif',
                'attachment.b.template' => 'ATT-2-<$Foo$>',
                'attachment.b.unparsed' => 1,
                'attachment.b.type'     => 'text/plain',
            },
            decode  => 'utf8',
            regex   => [
                qr/HTML-CONTENT =E2=98=BA=/,
                qr/Content-Type:\s+text\/html/,
                qr|R0lGODdhAQABAIAAAP///wAAACwAAAAAAQABAAACAkQBADs=|,   # clear.gif in Base64
                qr/ATT-2-<\$Foo\$>/,
            ],
            parts_count => 3,
        },
        t07a => {           # TEXT, HTML, and attachments
            config  => {
                '/charset'                  => 'UTF-8',
                '/mailer/transfer_encoding' => 'quoted-printable',
                '/xao/character_mode'       => 1,
            },
            args    => {
                'html.template'         => "HTML-CONTENT \x{263a}",
                'text.template'         => "TEXT-CONTENT \x{2122}",
                to                      => 'to@test.org',
                from                    => 'from@test.org',
                subject                 => 'SUBJECT-CONTENT',
                'attachment.1.template' => 'ATT-1-<$Foo$>',
                'attachment.1.unparsed' => 1,
                'attachment.1.type'     => 'application/octet-stream',
                'attachment.1.filename' => 'file-1.dat',
                'attachment.B.template' => 'ATT-2-<$Foo$>',
                'attachment.B.unparsed' => 1,
                'attachment.B.type'     => 'text/plain',
                'attachment.B.filename' => 'file-2.txt',
            },
            decode  => 'utf8',
            regex   => [
                qr/TEXT-CONTENT =E2=84=A2=/,
                qr/HTML-CONTENT =E2=98=BA=/,
                qr/Content-Type:\s+multipart\/alternative/,
                qr/Content-Type:\s+text\/plain/,
                qr/Content-Type:\s+text\/html/,
                qr/QVRULTEtPCRGb28kPg==/,   # 'ATT-1-<$Foo$>' in Base64
                qr/ATT-2-<\$Foo\$>/,
            ],
            parts_count => 3,
        },
        t07b => {           # TEXT, HTML, and attachments, byte mode
            config  => {
                '/charset'                  => 'UTF-8',
                '/mailer/transfer_encoding' => 'quoted-printable',
                '/xao/character_mode'       => 0,
            },
            args    => {
                'html.template'         => "HTML-CONTENT \x{263a}",
                'text.template'         => "TEXT-CONTENT \x{2122}",
                to                      => 'to@test.org',
                from                    => 'from@test.org',
                subject                 => 'SUBJECT-CONTENT',
                'attachment.1.template' => 'ATT-1-<$Foo$>',
                'attachment.1.unparsed' => 1,
                'attachment.1.type'     => 'application/octet-stream',
                'attachment.1.filename' => 'file-1.dat',
                'attachment.B.template' => 'ATT-2-<$Foo$>',
                'attachment.B.unparsed' => 1,
                'attachment.B.type'     => 'text/plain',
                'attachment.B.filename' => 'file-2.txt',
            },
            decode  => 'utf8',
            regex   => [
                qr/TEXT-CONTENT =E2=84=A2=/,
                qr/HTML-CONTENT =E2=98=BA=/,
                qr/Content-Type:\s+multipart\/alternative/,
                qr/Content-Type:\s+text\/plain/,
                qr/Content-Type:\s+text\/html/,
                qr/QVRULTEtPCRGb28kPg==/,   # 'ATT-1-<$Foo$>' in Base64
                qr/ATT-2-<\$Foo\$>/,
            ],
            parts_count => 3,
        },
        t08 => {           # TEXT, HTML, and attachments, overrides
            config  => {
                '/charset'                  => 'UTF-8',
                '/mailer/transfer_encoding' => 'quoted-printable',
                '/mailer/override_to'       => 'override-to@testing.org',
                '/mailer/from'              => 'config-from@testing.org',
                '/xao/character_mode'       => 1,
            },
            args    => {
                'html.template'         => "HTML-CONTENT \x{263a}",
                'text.template'         => "TEXT-CONTENT \x{2122}",
                to                      => 'to@test.org',
                cc                      => 'cc@test.org',
                bcc                     => 'bcc@test.org',
                replyto                 => 'replyto@test.org',
                subject                 => 'SUBJECT-CONTENT',
                'attachment.1.template' => 'ATT-1-<$Foo$>',
                'attachment.1.unparsed' => 1,
                'attachment.1.type'     => 'application/octet-stream',
                'attachment.1.filename' => 'file-1.dat',
                'attachment.B.template' => "Unicode\x{263a}",
                'attachment.B.unparsed' => 1,
                'attachment.B.type'     => 'application/octet-stream',
                'attachment.B.filename' => 'file-2.dat',
            },
            decode  => 'utf8',
            regex   => [
                qr/TEXT-CONTENT =E2=84=A2=/,
                qr/HTML-CONTENT =E2=98=BA=/,
                qr/Content-Type:\s+multipart\/alternative/,
                qr/Content-Type:\s+text\/plain/,
                qr/Content-Type:\s+text\/html/,
                qr/QVRULTEtPCRGb28kPg==/,   # 'ATT-1-<$Foo$>' in Base64
                qr/VW5pY29kZeKYug==/,       # Unicode☺ in Base64
                qr/From:.*config-from\@testing\.org/,
                qr/To:.*override-to\@testing\.org/,
                qr/X-Xao-Web-Mailer-To:\s+to\@test\.org/,
                qr/X-Xao-Web-Mailer-Cc:\s+cc\@test\.org/,
                qr/X-Xao-Web-Mailer-Bcc:\s+bcc\@test\.org/,
            ],
            negregex=> [
                qr/^To:\s+to\@test\.org/m,
                qr/^Cc:\s+cc\@test\.org/m,
                qr/^Bcc:\s+bcc\@test\.org/m,
            ],
            parts_count => 3,
        },
        t09 => {           # TEXT, HTML, and attachments, overrides
            config  => {
                '/charset'                  => 'UTF-8',
                '/mailer/transfer_encoding' => 'quoted-printable',
                '/mailer/override_to'       => 'override-to@testing.org',
                '/mailer/from'              => 'config-from@testing.org',
            },
            args    => {
                'html.path'             => '/bits/rawobj-template',
                'to'                    => 'to@test.org',
                'subject'               => 'SUBJECT-CONTENT',
            },
            decode  => 'utf8',
            regex   => [
                qr/Content-Type:\s+text\/html/,
                qr|RAWOBJ - for tests in testcases/Web\.pm|,
            ],
            negregex=> [
                qr/Content-Type:\s+text\/plain/,
            ],
            parts_count => 0,
        },
        t10 => {
            config  => {
                '/mailer/subject_prefix'    => 'FOO',
                '/mailer/from'              => 'config-from@testing.org',
            },
            args    => {
                'template'              => 'TEMPLATE',
                'to'                    => 'to@test.org',
                'subject'               => 'BAR',
            },
            decode  => 'utf8',
            regex   => [
                qr/Subject:\s*FOO BAR/,
                qr/TEMPLATE/,
            ],
            parts_count => 0,
        },
        t11 => {
            config  => {
                '/charset'                  => 'UTF-8',
                '/mailer/override_to'       => 'override-to@testing.org',
            },
            args    => {
                'template'              => 'TEMPLATE',
                'from'                  => 'from@test.org',
                'to'                    => 'to@test.org',
                'subject'               => "Unicode\x{2122} long subject to test splitting into two or more header continuation lines",
            },
            regex   => [
                ### qr/Subject:\s*=\?(?i:utf-8)\?Q\?Unicode=E2=84=A2(?:_|=20)long(?:_|=20)subject(?:_|=20)to(?:_|=20)test(?:_|=20)splitting(?:_|=20)into(?:_|=20)two(?:_|=20)or/s,
                qr/Subject:\s*=\?(?i:utf-8)\?Q\?Unicode=E2=84=A2(?:_|=20)long(?:_|=20)subj/s,
            ],
            negregex => [
                qr/\r/s,
            ],
        },

    );

    my $outfile=$self->{'outfile'};

    STDERR->binmode(':utf8');

    my %cfsaved;

    foreach my $tname (sort keys %tests) {
        my $tdata=$tests{$tname};

        foreach my $cfkey (keys %cfsaved) {
            $self->siteconfig->put($cfkey => $cfsaved{$cfkey});
        }

        if(my $config=$tdata->{'config'}) {
            foreach my $cfkey (keys %$config) {
                $cfsaved{$cfkey}=$self->siteconfig->get($cfkey);
                $self->siteconfig->put($cfkey => $config->{$cfkey});
            }
        }

        my $mailer=XAO::Objects->new(objname => 'Web::Mailer');
        $self->assert(ref($mailer),
            "Can't load Web::Mailer object");

        unlink $outfile;

        $mailer->expand($tdata->{'args'});

        my $fd=IO::File->new($outfile,'r');

        $self->assert(ref $fd,
            "Expected to have output in $outfile for test $tname");

        $fd->binmode;
        my $content=join('',$fd->getlines);
        $fd->close;

        if(my $fdcharset=$tdata->{'decode'}) {
            $content=Encode::decode($fdcharset,$content);
        }

        dprint "=============== $tname ====\n$content\n====================\n";

        if(my $regex=$tdata->{'regex'}) {
            foreach my $re (ref $regex eq 'ARRAY' ? @$regex : ($regex)) {
                ### dprint "...$re";
                $self->assert($content =~ $re ? 1 : 0,
                    "Expected content to match $re");
            }
        }

        if(my $negregex=$tdata->{'negregex'}) {
            foreach my $re (ref $negregex eq 'ARRAY' ? @$negregex : ($negregex)) {
                ### dprint "...$re";
                $self->assert($content !~ $re ? 1 : 0,
                    "Expected content to NOT match $re");
            }
        }

        if($have_email_mime) {
            my $parsed=Email::MIME->new($content);
            $self->assert(ref $parsed,
                "Expected to get a parsed MIME message");

            my $parts_count_expect=$tdata->{'parts_count'} || 0;
            my $parts_count_got=$parsed->subparts;

            $self->assert($parts_count_got == $parts_count_expect,
                "Expected $parts_count_expect sub-parts, got $parts_count_got");
        }
    }
}

###############################################################################
1;
