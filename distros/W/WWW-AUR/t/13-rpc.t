#!perl

use warnings;
use strict;
use Test::More;

my @FIELDS = qw{name version desc votes category outdated ctime mtime
                maintainer url urlpath license id };

sub chkflds
{
    my ($info) = @_;
    for (@FIELDS) {
        fail "missing RPC field $_" unless ( exists $info->{$_} );
    }
    pass 'all RPC fields accounted for';
}

use_ok 'WWW::AUR::RPC';


my $info = WWW::AUR::RPC::info('perl-alpm');
is $info->{'name'}, 'perl-alpm';
chkflds($info);

my @found = WWW::AUR::RPC::search('perl-');
ok scalar @found > 0;

my @infos = WWW::AUR::RPC::multiinfo('perl-alpm', 'perl-www-aur');
@infos = sort { $a->{'name'} cmp $b->{'name'} } @infos;
is $infos[0]{'name'}, 'perl-alpm';
chkflds($infos[0]);
#TODO: Ugh this us hacky... each multiinfo call returns 2 results per pkg...
#Perhaps this a bug in the RPC code?
is $infos[-1]{'name'}, 'perl-www-aur';
chkflds($infos[-1]);

done_testing;
