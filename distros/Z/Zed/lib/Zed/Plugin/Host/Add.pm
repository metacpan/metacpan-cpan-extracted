package Zed::Plugin::Host::Add;
use strict;

use Zed::Range::Set;
use Zed::Range::Parser;
use Zed::Config::Space;
use Zed::Output;
use Zed::Plugin;

=head1 SYNOPSIS

    add SPACE
    ex:
        add list1
        add list2 /tmp/servser_list

=cut

invoke "add" => sub {
    my ($key, $file, @lines, $fh) = splice @_, 0, 2;

    error("key not defined!") and return unless $key;

    @lines = $file ? -f $file && open( $fh, '<', $file ) ? <$fh> : () : <STDIN>;
    @lines = grep{s/ //g;$_ !~ /^$/}@lines;
    return unless @lines;
    chomp @lines;

    #
    #@lines = grep{ ++$hash{$_} < 2 } map{ chomp; $_ }@lines;
    
    debug("lines:", \@lines);
    my $set = Zed::Range::Set->new();
    map{ $set->add( Zed::Range::Parser->parse($_) ) }@lines;
    @lines = $set->dump;
    debug("add:", \@lines);
    space($key, \@lines);
    info("add $key hosts[", scalar @lines, "] suc!");
};
1
