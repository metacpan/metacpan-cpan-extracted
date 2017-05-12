#!/usr/bin/env perl
use strict;
use warnings;

use 5.010;

use FindBin;
use lib "$FindBin::Bin/../thirdparty/lib/perl5";

use Getopt::Long qw(:config posix_default no_ignore_case);
use Pod::Usage;

use Mojo::JSON qw(decode_json encode_json);
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::UserAgent::CookieJar;

use Data::Dumper;
$Data::Dumper::Indent = 1;

my $VERSION = "0.15";

my %opt = (); # parse options
my $ua;       # Mojo User Agent

my $defaultEmailDomain = 'example.com';
my $defaultCOS         = 'example.com';
my $defaultCOSId;

# main loop
sub main {
    GetOptions(\%opt, 'help|h', 'man', 'noaction|no-action|n',
        'verbose|v','debug', 'zmurl=s', 'zmauthuser=s', 'zmauthpassword=s',
        'uid=s', 'surname=s', 'givenname:s', 'password=s', 'language:s',
        'country=s', 'email:s') or exit(1);
    if ($opt{help})    { pod2usage(1);}
    if ($opt{man})     { pod2usage(-exitstatus => 0, -verbose => 2); }
    if ($opt{noaction}){ die "ERROR: don't know how to \"no-action\".\n";  }
    if (not @ARGV){
        pod2usage(1);
    }

    my $uid; my $ms; my $command; my $param;

    init();

    $command      = $ARGV[0];
    $defaultCOSId = getDefaultCOSId($defaultCOS);
    $param        = checkParameter($command);

    runZimbraCommand($command, $param);

    exit 1;
}

sub init {
    $ua = Mojo::UserAgent->new;
    $ua->cookie_jar(Mojo::UserAgent::CookieJar->new);
    authZimbraManager();
    return;
}

### Command Line Argument Parsing ###

sub checkParameter {
    my $cmd = shift;
    my $param =  {
        uid       => $opt{uid},
        surname   => $opt{surname},
        password  => $opt{password},
        givenname => 'optional:' . ( $opt{givenname} || '' ),
        language  => 'optional:' . ( $opt{language} || '' ),
        country   => $opt{country},
        email     => 'optional:' . ( $opt{email} || ''),
    };
    checkCommandLineArgs($cmd,$param);
    return $param;
}

sub checkCommandLineArgs {
    my $cmd = shift;
    my $param = shift;
    my $caller = (caller(1))[3];
    for my $k (keys %{$param}){
        my $v = $param->{$k} || '';
        if (defined($v) and ($v eq '')) {
            fail(1, "Wrong arguments (Function $cmd, Parameter $k missing) ### Perl Function $caller ###");
        }
        $v =~ s/^optional://;
        $param->{$k} = $v;
    }
    return $param;
}

#### Zimbra Manager Communication ###

sub getJSONZimbraManager {
    my $function = shift;
    my $params   = shift;
    my $catcherr = shift;
    my $friendly = shift;
    my $zmurl    = $opt{zmurl} || 'http://zimbra.example.com';
    my $url      = Mojo::URL->new($zmurl);
    if (defined $friendly and $friendly eq 'friendly') {
        $url->path('friendly/');
    }
    $url->path($function);
    $url->query($params);
    my $req = $ua->get($url);
    return processJSONAnswer($req, $catcherr);

}

sub postJSONZimbraManager {
    my $function = shift;
    my $params   = shift;
    my $catcherr = shift;
    my $friendly = shift;
    my $zmurl    = $opt{zmurl} || 'http://zimbra.example.com';
    my $url      = Mojo::URL->new($zmurl);
    if (defined $friendly and $friendly eq 'friendly') {
        $url->path('friendly/');
    }
    $url->path($function);
    my $req = $ua->post( $url => json => $params );
    return processJSONAnswer($req, $catcherr);
}

sub postJSONZimbraManagerFriendly {
    my $function = shift;
    my $params   = shift;
    my $catcherr = shift // 0;
    return postJSONZimbraManager($function, $params, $catcherr, 'friendly');
}

sub processJSONAnswer {
    my $req = shift;
    my $catcherr = shift;
    unless ($req->success or $catcherr) {
        my ($err, $code) = $req->error;
        if ($req->res->content->asset) {
            $err = $req->res->content->asset->slurp;
            $err =~ tr/"//d;
        }
        # use code errors in own namespace (>1000)
        $code = 0 unless ($code);
        fail(1000 + $code, $err);
    }
    return $req->res->json;
}

### Zimbra Commands ###

sub authZimbraManager {
    my $json = getJSONZimbraManager( 'auth' ,
        { user     => $opt{zmauthuser}     || 'admin',
          password => $opt{zmauthpassword} || 'secret' }
    );
    return $json;
}

sub getDefaultCOSId {
    my $cosName = shift;
    my $json = postJSONZimbraManagerFriendly(
        'getCos',
        { cosName => $cosName },
    );
    return $json->{id};
}

sub getDomainZimbraID {
    my $domainName = shift;
    my $json = postJSONZimbraManagerFriendly(
        'getDomainInfo' ,
        { domainName => $domainName }
    );
    return $json->{id};
}

sub getUserZimbraID {
    my $accountName = shift;
    my $catcherr = shift;
    my $json = postJSONZimbraManagerFriendly(
        'getAccountInfo' ,
        { accountName => $accountName },
        $catcherr
    );
    if ($json =~ m/no such account/) { return undef; }
    return $json->{zimbraId};
}

sub runZimbraCommand {
    my $command = shift;
    my $params  = shift;

    warn "running runZimbraCommand: $command \n";

    if ($command =~ /^createAccount/) {
        my $json = postJSONZimbraManagerFriendly(
            'createAccount',
            {
                uid                => $params->{uid},
                defaultEmailDomain => $defaultEmailDomain,
                plainPassword      => $params->{password},
                givenName          => $params->{givenname},
                surName            => $params->{surname},
                country            => $params->{country},
                displayName        => "$params->{surname} $params->{givenname}",
                localeLang         => $params->{language},
                cosId              => $defaultCOSId,
            },
        );
    }
    elsif ( ($command =~ /^checkIfUserNew/) or
            ($command =~ /^checkEmailChange/) ) {
        # Tri-State:
        #     returns fail if virtual address already taken
        #     returns 1 if this is a virtual email address (non-hin)
        #     returns 0 for hin address

        my $defaultDomain  = $defaultEmailDomain;
        my $uid            = $params->{uid};
        my $zimbraUUID     = getUserZimbraID($uid.'@'.$defaultEmailDomain, 'catchnoexisting');
        unless ($zimbraUUID) { return -1; }
        my ($emailUsername, $emailDomain) = $params->{email}  =~ /(.*)@(.*)/;
        my $zimbraDomainId = getDomainZimbraID($emailDomain);
        my $success;

        unless ($zimbraDomainId) {
            fail(1997, "invalid Email Domain $emailDomain given");
        }

        # this includes the failure handling if email address has already taken
        my $json = postJSONZimbraManagerFriendly(
            'addAccountAlias',
            {
                id    => $zimbraUUID,
                alias => $params->{email},
            },
        );
        if (! keys %{$json}) {
            $success = 1;
            $json = postJSONZimbraManagerFriendly(
                'removeAccountAlias',
                {
                    id    => $zimbraUUID,
                    alias => $params->{email},
                },
            );
        }
        if ($success) {
            return 0 if ($emailDomain eq $defaultDomain);
            return 1 if ($emailDomain ne $defaultDomain);
        }
    }
    elsif ($command =~ /^changeEmailAlias/) {
        my $uid = $params->{uid};
        my $zimbraUUID = getUserZimbraID($uid.'@'.$defaultEmailDomain);
        my $json = postJSONZimbraManagerFriendly(
            'addAccountAlias',
            {
                id    => $zimbraUUID,
                alias => $params->{email},
            },
        );
    }
    elsif ($command =~ /^enableAccount/) {
        my $uid = $params->{uid};
        my $zimbraUUID = getUserZimbraID($uid.'@'.$defaultEmailDomain);
        my $json = postJSONZimbraManagerFriendly(
            'modifyAccount',
            {
                zimbraUUID  => $zimbraUUID,
                modifyKey   => 'zimbraMailStatus',
                modifyValue => 'enabled',
            },
        );
    }
   elsif ($command =~ /^disableAccount/) {
        my $uid = $params->{uid};
        my $zimbraUUID = getUserZimbraID($uid.'@'.$defaultEmailDomain);
        my $json = postJSONZimbraManagerFriendly(
            'modifyAccount',
            {
                zimbraUUID  => $zimbraUUID,
                modifyKey   => 'zimbraMailStatus',
                modifyValue => 'disabled',
            },
        );
    }
    elsif ($command =~ /^deleteAccount/) {
        my $uid = $params->{uid};
        my $zimbraUUID = getUserZimbraID($uid.'@'.$defaultEmailDomain);
        my $json = postJSONZimbraManagerFriendly(
            'deleteAccount',
            {
                zimbraUUID => $zimbraUUID,
            },
        );
    }
    else {
        fail(1999,"Unknown command $command");
        exit 0;
    }
    warn "running runZimbraCommand finished\n";
}

### Error Handling ###

sub fail {
    my $code = shift;
    my $msg = shift;

    say STDERR "$msg";
    say STDERR "Finished with errors";

    exit $code;
}

main;

__END__

=pod

=head1 NAME

zimbra-manager-client.pl - a ZimbraManager Client written with Mojo::UserAgent

=head1 SYNOPSIS

B<zimbra-manager-client.pl> [I<options>] [B<command>]

     --man              show man-page and exit
 -h, --help             display this help and exit
     --version          output version information and exit
     --debug            prints debug messages

     --zmurl            URL to the ZimbraManager
                        (e.g. http://localhost:13000/)
     --zmauthuser       administrative user name in Zimbra
                        (e.g. admin)
     --zmauthpassword   administrative user password in Zimbra
                        (e.g. secret)

     Actions for single user:

     --uid              user UID
     --surname          user surname
     --givenname        user givenname
     --password         user password
     --language         user language
     --country          user country
     --email            user email address / email alias

commands:

    createAccount       create a new user in Zimbra

    checkIfUserNew      check if the user not exist in Zimbra

    checkEmailChange    check if the wished email alias is
                        not already in use

    changeEmailAlias    set new Email Alias for a Zimbra User

    enableAccount       enables the Account in Zimbra

    disableAccount      disables the Account in Zimbra

    deleteAccount       delete Account in Zimbra


=head1 DESCRIPTION

zimbra-manager-client is a web consumer client of ZimbraManager.

Using zimbra-manager.pl as a Zimbra SOAP / REST Interface. And
using for most of the calls the ZimbraManager::SOAP::Friendly
interface.

=head1 SEE ALSO

L<ZimbraManager::SOAP> L<ZimbraManager::SOAP::Friendly>

=head1 COPYRIGHT

Copyright (c) 2014 by Roman Plessl. All rights reserved.

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see L<http://www.gnu.org/licenses/>.

=head1 AUTHOR

S<Roman Plessl E<lt>roman@plessl.infoE<gt>>

=head1 HISTORY

 2014-03-31 rp Initial Version
 2014-05-13 rp New API and new version

=cut
