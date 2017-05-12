package Zed;

use POSIX;
use Term::ReadLine;

use Zed::Plugin;
use Zed::Output;
use Zed::Config::Env;
use Zed::Config::Space;

use strict;
use 5.008_005;
our $VERSION = '0.03';

sub _macro
{
    my ($text, $stat) = @_;
    my %plugins = Zed::Plugin::plugins();
    my %hash = 
    ( 
        %{ env('macro') }, 
        map{$_ => $_}keys %{$plugins{invoke}},
    );

    if($hash{$text})
    {
        return $hash{$text} if $stat == 0;
        return ();
    }
    my @grep = sort grep{ /^$text/ }keys %hash;
    $grep[$stat] ? $grep[$stat] : ();
}

sub _result
{
    return unless ref $_[0] eq 'ARRAY' 
              and ref $_[1] eq 'ARRAY' 
              and scalar @_ >= 2;

    my($suc, $fail, $result) = @_;

    $result ||= {};

    my( %group, %content, $count );

    push @{ $content{ $result->{$_} } }, $_ for keys %$result;

    while(my($text, $host) = each %content)
    {
        $count += 1;    
        my $group = "group". $count;
        $group{$group} = $host;
        if(@$host <= 5)
        {
            info("$group\[", join(',', @$host), "\]:");
        }else{
            info("$group\[", scalar @$host,"\]:");
        }
        text($text);
    }

    env( "result", {space => usespace(), "suc" => $suc, "fail" => $fail, "group" => \%group } );
    info(sprintf "\nsuc:[ %s ], fail:[ %s ]\n", scalar @$suc, scalar @$fail);
}

sub run
{
    my ($term, $attribs, $prompt) = Term::ReadLine->new(__PACKAGE__);
    my $hist = File::Spec->join( $ENV{ZED_HOME}, "history" );
    $term->ReadHistory($hist);
    $attribs = $term->Attribs;

    $attribs->{attempted_completion_function} = sub { 

        my($text, $line, $start, $end) = @_;

        if( substr($line, 0, $start) =~ /^\s*$/ )
        {
            return $term->completion_matches($text, \&_macro) 
            
        }elsif( $line =~ /^(\w+) / and $start ==  1 + length $1){

            my($sub, @word) = Zed::Plugin::complete_first( $1 );
            return unless $sub and @word = $sub->();
            return $term->completion_matches($text, sub{

                my ($text, $stat, @grep) = splice @_, 0, 2;

                @grep = sort grep{ /^$text/ } @word;
                $grep[$stat] ? $grep[$stat] : undef;
            }) 
            
        }
        return;
    };

    sigaction SIGINT, new POSIX::SigAction sub {
        $term->delete_text;
        $attribs->{point} = $attribs->{end} = 0;
        print "\n", $prompt;
        $|=1;
    } or die "Error setting SIGINT handler: $!\n";

    while(1)
    {
        $prompt = ( env("username")||"nouser" ) . "\@zed#> ";
        my $in = $term->readline($prompt);
        next unless $in; $in =~ s/ *$//;

        my( $cmd, undef, $param, @params ) = $in =~ /^(.+?)(\s+(.+))?$/;
        @params = grep{$_} split /\s/, $param if $param;
        warn "input($in) error\n" and next unless $cmd;

        debug("cmd: |$cmd|");
        debug("param: |$param|") if $param;
        debug("params:", \@params) if @params;

        last if $cmd eq 'quit';

        my($sub, @return, $after) = invoke($cmd);
        debug("get invoke:", ref $sub ? "suc" : "faild");

        @return = $sub ? $sub->(@params) : info("no invoke plugin(cmd: $cmd) defined") && next;

        _result( @return );
            
        #$term->addhistory($in);
    }
    $term->WriteHistory($hist) or warn "cannot write history file: $!\n";
}
1;
__END__

=encoding utf-8

=head1 NAME

Zed - Remote execution shell over SSH

=head1 SYNOPSIS

  # Just run zed
  > zed

  Welcome nobody~!
  (Type 'help' to show more commands)

  # set your username used by ssh/scp
  > nobody@zed> set username foo

  # add a group servers
  > foo@zed> add first_group
  myserver1.bar.com
  myserver{2~9}.bar.com
  [CTRL+D]
  add servers hosts[9] suc!

  # show the servers added just now
  > foo@zed> dump first_group

  # use a group as your target
  > foo@zed> use first_group 

  # run command over ssh
  > foo@zed> cmd ls /tmp

  # run command with sudo
  > foo@zed> cmd sudo ls /root

  # port detection
  > foo@zed> port 80
  
  # checkout the results to group
  > foo@zed> checkout

  # then you can use the suc group
  > foo@zed> use default.suc

  # show more commands
  > help

=head1 DESCRIPTION

Zed is remote execution shell over SSH with many plugins to help you to manage servers.

Features below:

=over 4

=item execution over SSH

=item transfer file over scp

=item port detection

=item flexible way to manage targets

=item easy to type cmd with completion

=back

(Servers will not disconnect until you quit. So Large mount of servers may cause memory problem)

=head1 ENV

  $ENV{ZED_HOME}: zed working dir, default $HOME/.zed

=head1 CONF

  $ENV{ZED_HOME}/Space: 

    #targets defined here.
    ---
    foo:
    - 127.0.0.1
    none: ~

  $ENV{ZED_HOME}/Env: 

    ---
    username: nobody

    #idc is the name of a regex to identify servers group.
    #batch idc 1. Pick 1 server of each group identified by regex idc to build new targets.
    batch:
      idc: ^.+?\..+?\.(.+?)\.

    #short command to complete real command
    macro:
      ip: cmd /sbin/ip addr|grep inet|grep -v 127.0.0.1|awk "{print \$2}"|awk -F"/" "{print \$1}"

    #plugins to load
    plugin:
    - Zed::Plugin::Sys::Echo
    ...
    - Zed::Plugin::Host::Checkout

=head1 AUTHOR

SiYu Zhao E<lt>zuyis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2016- SiYu Zhao

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
