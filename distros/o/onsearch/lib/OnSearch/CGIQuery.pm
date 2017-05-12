package OnSearch::CGIQuery; 

=head1 NAME

OnSearch::CGIQuery - CGI library for OnSearch.

=head1 SYNOPSIS

    my $q = OnSearch::CGIQuery -> new;
    $q -> parse_query ();
    $q -> param_value ($param_name);

=head1 DESCRIPTION

OnSearch::CGIQuery provides methods to parse CGI queries and 
return parameter values.

=head1 METHODS

=cut

#$Id: CGIQuery.pm,v 1.5 2005/07/28 07:02:23 kiesling Exp $

use strict;
use warnings;
use Carp;

my $VERSION='$Revision: 1.5 $';

require Exporter;
require DynaLoader;
our (@ISA, @EXPORT_OK, %EXPORT_TAGS);
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = (qw/new parsequery param_value DESTROY/);
%EXPORT_TAGS = ( 'all' => [@EXPORT_OK] );

=head2 new ();

This is the OnSearch::CGIQuery object constructor.

=cut

sub new {
    my $proto = shift;
    my $class = ref ( $proto ) || $proto;
    my $obj = {
	pwd => '',                    # Directory of calling script.
	displayregex => undef,        # Regex used for highlighting in results.
	regex => undef,               # Regex used for multi-word searches.
        context => undef,             # How much context to show on each match.
	cache => undef,               # Web site cache directory.
	ppid => undef,                # ID of parent script process.
	sid  => undef,                # ID of search process.
    };
    bless ($obj, $class);
    return $obj;
}

=head2 $q -> DESTROY;

The OnSearch::CGIQuery destructor, also called by Perl to delete
unused objects.

=cut

sub DESTROY {
    my ($self) = @_;
    undef %{$self};
}

=head2 $q -> parsequery ();

Parse a CGI query.

=cut

sub parsequery {
    my $q = shift;
    my ($param, $arg);
    my ($scriptname, $request) = split /\?/, $ENV{REQUEST_URI}, 2;
    return unless $request;
    my @params = split /\&/, $request;
    foreach my $p (@params) {
	($param, $arg) = split /\=/, $p;
	$q -> {$param} = OnSearch::Utils::http_unescape ($arg);
    }
}

=head2 $q -> param_value (I<param>);

Return the value of CGI parameter I<param.>

=cut

sub param_value {
    my $q = shift;
    my $param = $_[0];
    return $q -> {$param};
}

1;

__END__

=head1 SEE ALSO

L<OnSearch(3)>

=cut
