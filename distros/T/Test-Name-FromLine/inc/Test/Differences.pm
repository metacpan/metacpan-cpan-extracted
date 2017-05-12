#line 1
package Test::Differences;

#line 284

our $VERSION = "0.13"; # or "0.001_001" for a dev release
$VERSION = eval $VERSION;

use Exporter;

@ISA    = qw( Exporter );
@EXPORT = qw(
  eq_or_diff
  eq_or_diff_text
  eq_or_diff_data
  unified_diff
  context_diff
  oldstyle_diff
  table_diff
);

use strict;

use Carp;
use Text::Diff;

sub _isnt_ARRAY_of_scalars {
    return 1 if ref ne "ARRAY";
    return scalar grep ref, @$_;
}

sub _isnt_HASH_of_scalars {
    return 1 if ref ne "HASH";
    return scalar grep ref, values %$_;
}

use constant ARRAY_of_scalars           => "ARRAY of scalars";
use constant ARRAY_of_ARRAYs_of_scalars => "ARRAY of ARRAYs of scalars";
use constant ARRAY_of_HASHes_of_scalars => "ARRAY of HASHes of scalars";
use constant HASH_of_scalars            => "HASH of scalars";

{
    my $diff_style = 'Table';
    my %allowed_style = map { $_ => 1 } qw/Unified Context OldStyle Table/;
    sub _diff_style {
        return $diff_style unless @_;
        my $requested_style = shift;
        unless ( $allowed_style{$requested_style} ) {
           Carp::croak("Uknown style ($requested_style) requested for diff");
        }
        $diff_style = $requested_style;
    }
}

sub unified_diff  { _diff_style('Unified') }
sub context_diff  { _diff_style('Context') }
sub oldstyle_diff { _diff_style('OldStyle') }
sub table_diff    { _diff_style('Table') }

sub _grok_type {
    local $_ = shift if @_;
    return "SCALAR" unless ref;
    if ( ref eq "ARRAY" ) {
        return undef unless @$_;
        return ARRAY_of_scalars
          unless _isnt_ARRAY_of_scalars;
        return ARRAY_of_ARRAYs_of_scalars
          unless grep _isnt_ARRAY_of_scalars, @$_;
        return ARRAY_of_HASHes_of_scalars
          unless grep _isnt_HASH_of_scalars, @$_;
        return 0;
    }
    elsif ( ref eq 'HASH' ) {
        return HASH_of_scalars
          unless _isnt_HASH_of_scalars($_);
        return 0;
    }
}

## Flatten any acceptable data structure in to an array of lines.
sub _flatten {
    my $type = shift;
    local $_ = shift if @_;

    return [ split /^/m, _quote_str($_) ] unless ref;

    croak "Can't flatten $_" unless $type;

    ## Copy the top level array so we don't trash the originals
    my ( @recs, %hash_copy );
    if ( ref $_ eq 'ARRAY' ) {
        @recs = @$_;
    }
    elsif ( ref $_ eq 'HASH' ) {
        %hash_copy = %$_;
    }
    else {
        die "unsupported ref type";
    }
    if ( $type eq ARRAY_of_scalars) {
        @recs = map { _quote_str($_) } @recs;
    }
    elsif ( $type eq ARRAY_of_ARRAYs_of_scalars ) {
        ## Also copy the inner arrays if need be
        $_ = [@$_] for @recs;
    }
    elsif ( $type eq ARRAY_of_HASHes_of_scalars ) {
        my %headings;
        for my $rec (@recs) {
            $headings{$_} = 1 for keys %$rec;
        }
        my @headings = sort keys %headings;

        ## Convert all hashes in to arrays.
        for my $rec (@recs) {
            $rec = [ map $rec->{$_}, @headings ],;
        }

        unshift @recs, \@headings;

        $type = ARRAY_of_ARRAYs_of_scalars;
    }
    elsif ( $type eq HASH_of_scalars ) {
        my @headings = sort keys %hash_copy;
        @recs = ( \@headings, [ map $hash_copy{$_}, @headings ] );
        $type = ARRAY_of_ARRAYs_of_scalars;
    }

    if ( $type eq ARRAY_of_ARRAYs_of_scalars ) {
        ## Quote strings
        for my $rec (@recs) {
            for (@$rec) {
                $_ = _quote_str($_);
            }
            $rec = join ",", @$rec;
        }
    }

    return \@recs;
}

sub _quote_str {
    my $str = shift;
    return 'undef' unless defined $str;
    return $str if $str =~ /^[0-9]+$/;
    $str =~ s{([\\\'])}{\\$1}g;
    return "'$str'";
}

sub _identify_callers_test_package_of_choice {
    ## This is called at each test in case Test::Differences was used before
    ## the base testing modules.
    ## First see if %INC tells us much of interest.
    my $has_builder_pm = grep $_ eq "Test/Builder.pm", keys %INC;
    my $has_test_pm    = grep $_ eq "Test.pm",         keys %INC;

    return "Test"          if $has_test_pm  && !$has_builder_pm;
    return "Test::Builder" if !$has_test_pm && $has_builder_pm;

    if ( $has_test_pm && $has_builder_pm ) {
        ## TODO: Look in caller's namespace for hints.  For now, assume Builder.
        ## This should only ever be an issue if multiple test suites end
        ## up in memory at once.
        return "Test::Builder";
    }
}

my $warned_of_unknown_test_lib;

sub eq_or_diff_text { $_[3] = { data_type => "text" }; goto &eq_or_diff; }
sub eq_or_diff_data { $_[3] = { data_type => "data" }; goto &eq_or_diff; }

## This string is a cheat: it's used to see if the two arrays of values
## are identical.  The stringified values are joined using this joint
## and compared using eq.  This is a deep equality comparison for
## references and a shallow one for scalars.
my $joint = chr(0) . "A" . chr(1);

sub eq_or_diff {
    my ( @vals, $name, $options );
    $options = pop if @_ > 2 && ref $_[-1];
    ( $vals[0], $vals[1], $name ) = @_;

    my $data_type;
    $data_type = $options->{data_type} if $options;
    $data_type ||= "text" unless ref $vals[0] || ref $vals[1];
    $data_type ||= "data";

    my @widths;

    my @types = map _grok_type, @vals;

    my $dump_it = !$types[0] || !$types[1];

    my ( $got, $expected );
    if ($dump_it) {
        require Data::Dumper;
        local $Data::Dumper::Indent    = 1;
        local $Data::Dumper::Purity    = 0;
        local $Data::Dumper::Terse     = 1;
        local $Data::Dumper::Deepcopy  = 1;
        local $Data::Dumper::Quotekeys = 0;
        local $Data::Dumper::Sortkeys =
          exists $options->{Sortkeys} ? $options->{Sortkeys} : 1;
        ( $got, $expected ) = map
          [ split /^/, Data::Dumper::Dumper($_) ],
          @vals;
    }
    else {
        ( $got, $expected ) = (
            _flatten( $types[0], $vals[0] ),
            _flatten( $types[1], $vals[1] )
        );
    }

    my $caller = caller;

    my $passed
      = join( $joint, @$got ) eq join( $joint, @$expected );

    my $diff;
    unless ($passed) {
        my $context;

        $context = $options->{context}
          if exists $options->{context};

        $context = $dump_it ? 2**31 : grep( @$_ > 25, $got, $expected ) ? 3 : 25
          unless defined $context;

        confess "context must be an integer: '$context'\n"
          unless $context =~ /\A\d+\z/;

        $diff = diff $got, $expected,
          { CONTEXT     => $context,
            STYLE       => _diff_style(),
            FILENAME_A  => "Got",
            FILENAME_B  => "Expected",
            OFFSET_A    => $data_type eq "text" ? 1 : 0,
            OFFSET_B    => $data_type eq "text" ? 1 : 0,
            INDEX_LABEL => $data_type eq "text" ? "Ln" : "Elt",
          };
        chomp $diff;
        $diff .= "\n";
    }

    my $which = _identify_callers_test_package_of_choice;

    if ( $which eq "Test" ) {
        @_
          = $passed
          ? ( "", "", $name )
          : ( "\n$diff", "No differences", $name );
        goto &Test::ok;
    }
    elsif ( $which eq "Test::Builder" ) {
        my $test = Test::Builder->new;
        ## TODO: Call exported_to here?  May not need to because the caller
        ## should have imported something based on Test::Builder already.
        $test->ok( $passed, $name );
        $test->diag($diff) unless $passed;
    }
    else {
        unless ($warned_of_unknown_test_lib) {
            Carp::cluck
              "Can't identify test lib in use, doesn't seem to be Test.pm or Test::Builder based\n";
            $warned_of_unknown_test_lib = 1;
        }
        ## Play dumb and hope nobody notices the fool drooling in the corner
        if ($passed) {
            print "ok\n";
        }
        else {
            $diff =~ s/^/# /gm;
            print "not ok\n", $diff;
        }
    }
}

#line 650

1;
