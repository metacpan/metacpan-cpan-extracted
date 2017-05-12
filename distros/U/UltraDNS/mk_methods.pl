#!perl -w

=head1 NAME

mk_methods.pl - generate UltraDNS::Methods module by parsing the specification

=head1 SYNOPSIS

  mk_methods.pl NUS_API_XML.txt

=head1 DESCRIPTION

Parses a plain text version of the UltraDNS Transaction Protocol document
(derived from http://www.ultradns.net/api/NUS_API_XML.pdf) and rewrites the
UltraDNS::Methods module with descriptions of the methods and their arguments.

You I<do not need to run this> unless you need to update the code to handle a
newer version of the API.

=head2 Converting PDF To Text

The NUS_API_XML.txt isn't included in the distribution for copyright reasons.
This is the procedure I used to generate the current UltraDNS::Methods module:

 - Open http://www.ultradns.net/api/NUS_API_XML.pdf using Preview on Mac OSX
 - Select and copy all the text
 - Paste the text into the TextEdit application
 - Select "Make Plain Text" from the Format menu
 - Save as NUS_API_XML.txt
 - Run mk_methods.pl NUS_API_XML.txt in the top directory of the distribution

If you use a different method to perform the conversion then it's likely that
you'll need to make slight changes to this script.

=cut

# TODO (maybe)
# identify methods that return results
# sigil doesn't need to be in the data struct (at least not the default '$')

use strict;
use warnings;

use Carp;
use Getopt::Long;

use XML::Simple qw(:strict);
use Data::Dumper;

GetOptions(
    'trace|t=i' => \(my $opt_trace = 0),
) or exit 1;

my $api_spec_file = shift or die "No API file specified";
my $pm_filename = "lib/UltraDNS/Methods.pm";

my $api_spec_txt = `cat $api_spec_file`
    or die "Couldn't read $api_spec_file\n";

# remove page breaks
my $title = qr/NeuStar Ultra Services Transaction Protocol\s*/;
$api_spec_txt =~ s/ \n $title \n \d+ //xmg
    or die "Failed to remove page breaks";

# remove blank lines
$api_spec_txt =~ s/ \s* \n (\s* \n)* /\n/xmg
    or die "Failed to remove blank lines";

# extract method call examples
my @methods = $api_spec_txt =~ m{Syntax\s* \n (<methodCall> .*? </methodCall>) }xsg;
die "Found no methods" unless @methods;
warn "Found ".@methods." methods\n";

# create Methods.pm and copy the prologue into it
open my $pm_fh, ">", $pm_filename ## no critic (RequireBriefOpen)
    or die "Unable to open $pm_filename for writing: $!";
my @prologue = <DATA>;
s/^:// for @prologue;
print $pm_fh @prologue;

# process each method found in the spec
# and write corresponding code into Methods.pm
my $method_spec = {};
my %arg_type_usage;
for my $method_xml (@methods) {

    # fix-up typos in the docs
    $method_xml =~ s{</value\s*\n}{</value>\n}xms;

    my $m = eval { XMLin($method_xml, ForceArray=>[qw(param)], KeyAttr=>[]) };
    if ($@) {
        warn "Error parsing $method_xml: $@";
        next;
    }
    my $methname = delete $m->{methodName};
    my $params   = delete $m->{params};
    warn "Unexpected remnants in $methname methodCall data: ".Dumper($m)
        if keys %$m;
    
    my $param_content = delete $params->{content}; # "..." indicating repeating param
    my $param_list = delete $params->{param};
    warn "Unexpected remnants in $methname methodCall params data: ".Dumper($params)
        if keys %$params;

    my @mk_params;
    my $last_repeats = 0;
    if ($param_list) {
        #warn Dumper($param_list);
        for my $p (@$param_list) {

            if (my $v = delete $p->{value}) { # scalar
                my ($type, $example) = %$v;
                $example =~ s/\n//g;
                push @mk_params, { type => $type, example => $example, sigil => '$' };
            }
            elsif (my $a = delete $p->{array}) { # array
                my $elem_info = $a->{data}{value};
                my $elem_type = (keys %{$elem_info->[0]})[0];
                push @mk_params, { type => 'array', elem_type => $elem_type, sigil => '\@',  };
            }
            else {
                die "I don't know how to handle $methname param ".Dumper($p);
            }
            die "Unexpected remnants in $methname param: ".Dumper($p)
                if keys %$p;

            # note which arg types are used by which methods
            $arg_type_usage{ $mk_params[-1]{type} }{ $methname }++;
        }
        if ($param_content) {
            # die if it's not an elipsis character ("...")
            die "Unexpected content in $methname param section: ".Dumper($param_content)
                unless $param_content eq "\n\x{2026}\n";
            $last_repeats = 1;
            $mk_params[-1]{sigil} = '@';
            warn "$methname has repeating params\n" if $opt_trace;
        }
        warn Dumper({ $methname => \@mk_params }) if $opt_trace >= 2;
    }

    $method_spec->{$methname} = {
        arg_info => \@mk_params,
        last_arg_repeats => $last_repeats,
    };

}

# dump the data structure into the module
print $pm_fh Data::Dumper->new([$method_spec], [qw(method_spec)])
    ->Indent(1)->Sortkeys(1)->Useqq(1)->Dump;
print $pm_fh "\n\n1;\n";

# write some docs

for my $methname (sort keys %$method_spec) {
    # skip docs for some methods
    next if $methname eq 'UDNS_OpenConnection';
    next if $methname eq 'UDNS_NoAutoCommit';

    my $info = $method_spec->{$methname};
    my $arg_info = $info->{arg_info};
    $methname =~ s/^UDNS_//;

    my $res = ""; # XXX make "$result = " if method returns a result
    my @args = map {
        $_->{sigil} . $_->{type}
    } @$arg_info;
    my $args = (@args) ? "(". join(", ", @args). ")" : "";

    print $pm_fh "=head2 $methname\n\n  $res\$udns->$methname$args;\n\n";

    if (@$arg_info) {
        for my $arg (@$arg_info) {
            my $example = $arg->{example};
            if ($arg->{type} eq 'array') {
                $example = sprintf '[ $%s, ... ]', $arg->{elem_type};
            }
            $example = "($example, ...)" if $arg->{sigil} eq '@';
            printf $pm_fh qq{  %s%s = %s\n},
                $arg->{sigil}, $arg->{type}, $example;
        }
        print $pm_fh "\n";
    }

}
print $pm_fh "\n=cut\n";

# finish up
close $pm_fh or die "Error writing $pm_filename: $!";

# sanity check the generated file
system("perl -c $pm_filename") == 0
    or die "Error in generated $pm_filename code";

warn Dumper(\%arg_type_usage) if $opt_trace >= 2;
warn Dumper([ keys %arg_type_usage ]) if $opt_trace;

__DATA__
:package UltraDNS::Methods;
:
:=head1 NAME
:
:UltraDNS::Methods - Available UltraDNS Transaction Protocol Methods
:
:=head1 SYNOPSIS
:
:  use UltraDNS;
:
:  $udns = UltraDNS->connect(...);
:
:  $udns->...any of these methods...(...);
:  $udns->...any of these methods...(...);
:  $udns->...any of these methods...(...);
:
:  $udns->commit;
:
:  $udns->...any of these methods...(...);
:  $udns->...any of these methods...(...);
:  $udns->...any of these methods...(...);
:
:  $udns->commit;
:
:  # etc
:
:=head1 DESCRIPTION
:
:This module contains details of the UltraDNS methods defined by the UltraDNS
:Transaction Protocol documentation.
:
:Refer to L<UltraDNS> for more details.
:
:=head1 METHODS
:
:The methods can be called either with our without the C<UDNS_> prefix that
:appears in the UltraDNS docs. They're shown here without the prefix because it
:I prefer it that way.
:
:=cut
:
:use strict;
:use warnings;
:
:my $method_spec;
:
:sub _method_spec {
:    my ($self, $method_name) = @_;
:    return $method_spec->{$method_name};
:}
:
