#!/usr/bin/perl
use warnings;
use strict;

# ABSTRACT: Create a ValidSign document package from the command line
# PODNAME: vs-upload.pl

use Config::Any;
use File::Temp;
use File::Spec::Functions qw(catfile);
use Getopt::Long;
use Pod::Usage;

use WebService::ValidSign;
use WebService::ValidSign::Object::DocumentPackage;
use WebService::ValidSign::Object::Document;

my %opts = (
    help      => 0,
    config    => catfile($ENV{HOME}, qw (.config validsign.conf)),
);

{
    local $SIG{__WARN__};
    my $ok = eval {
        GetOptions(
            \%opts, qw(help secret=s endpoint=s sender=s
                document-package-name=s file=s@ signer=s@ use-fh)
        );
    };
    if (!$ok) {
        die($@);
    }
}

pod2usage(0) if ($opts{help});

if (-f $opts{config}) {
    my $config = Config::Any->load_files({
            files => [$opts{config}],
            use_ext => 1,
            flatten_hash => 1,

        })->[0]{$opts{config}};

    foreach (keys %$config) {
        # If an option is set multiple times in the config file, take
        # the last value and work with that
        $opts{$_} ||= ref $config->{$_} eq 'ARRAY'
            ? $config->{$_}[-1]
            : $config->{$_};
    }
}

my @required = qw(secret document-package-name);
my $nok = 0;
foreach (@required) {
    if (!defined $opts{$_}) {
        $nok++;
        warn "$_ is missing!"
    }
}
pod2usage(1) if $nok;

my $sender  = delete $opts{sender};
my $files   = delete $opts{file};
my $signers = delete $opts{signer};
my $use_fh  = delete $opts{'use-fh'};

my $client = WebService::ValidSign->new(
    %opts
);

my $documentpackage = WebService::ValidSign::Object::DocumentPackage->new(
    name => $opts{'document-package-name'},
);

if ($sender) {
    my $senders = $client->account->senders(search => $sender);
    if (!@$senders) {
        die "Unable to find sender $senders\n";
    }
    elsif (@$senders > 1) {
        die "Multiple senders found for $senders\n";
    }
    $documentpackage->sender($senders->[0]);
}

if ($signers) {
    my $s = ref $signers ? $signers : [$signers];

    my $i = 0;
    foreach (@{$s}) {
        my $senders = $client->account->senders(search => $s);
        if (!@$senders) {
            die "Unable to find sender $s\n";
        }
        elsif (@$senders > 1) {
            die "Multiple senders found for $s\n";
        }
        $documentpackage->add_signer(sprintf("%s-%03d", "signer", $i) => $senders->[0]);
        $i++;
    }
}

if ($files) {
    my $documents = ref $files ? $files : [ $files ];

    foreach (@$documents) {
        my $document;
        if ($use_fh) {
            my $fh = File::Temp->new();
            open (my $d, '<', $_);
            my $c = <$d>;
            print $fh $c;
            close($fh);
            $fh->seek(0,0);
            $document = WebService::ValidSign::Object::Document->new(
                name => "$_",
                path => $fh,
            );
        }
        else {
            $document = WebService::ValidSign::Object::Document->new(
                name => "$_",
                path => $_,
            );

        }
        $documentpackage->add_document($document);
    }
}


my $id = $client->package->create($documentpackage);
printf "Created package with ID %s%s", $documentpackage->id , $/;

__END__

=pod

=encoding UTF-8

=head1 NAME

vs-upload.pl - Create a ValidSign document package from the command line

=head1 VERSION

version 0.004

=head1 SYNOPSIS

vs-upload.pl --secret <secret>

=head1 DESCRIPTION

A proof of concept script that creates a document package at ValidSign.

=head1 OPTIONS

=over

=item secret

Your very secret API key

=item sender

The user you want to create the package

=item config

Define where your configuration file is located, defaults to
C<$HOME/.config/valid-sign>. In here you can
change the defaults for all of the command line options. Command line
options take preference over the configuration file options.

=item document-package-name

The name of the document package that you want to create

=item file

Select the file you want to sign. Multiple files are allowed.

=item signer

Select the user who needs to sign the document. Multiple signers are allowed.

=back

=head1 SEE ALSO

=over

=item L<WebService::ValidSign>

=item L<WebService::ValidSign::Object::DocumentPackage>

=item L<WebService::ValidSign::Object::Document>

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
