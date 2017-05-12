# $Id: /mirror/perl/Web-Scraper-Config/trunk/lib/Web/Scraper/Config.pm 7145 2007-05-09T16:36:57.901467Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package Web::Scraper::Config;
use strict;
use warnings;
use Config::Any;
use Data::Visitor::Callback;
use Web::Scraper;
use URI;
our $VERSION = '0.01';

sub new
{
    my $class  = shift;
    my $self   = bless {}, $class;
    my $config = shift;
    my $opts   = shift;
    $config = $self->_load_config($config);

    { # BROKEN YAML::Syck
        my $v = Data::Visitor::Callback->new(
            plain_value => sub { $_[1] =~ s/(\w:) /$1/g; $_[1] }
        );
        $config = $v->visit($config);
    }

    $self->{config} = $config;
    $self->{callbacks} = $opts->{callbacks} if $opts && $opts->{callbacks};
    return $self;
}

sub _load_config
{
    my $self = shift;
    my $file = shift;

    if (ref $file eq 'HASH') {
        return $file;
    } else {
        # This is a bit hackish, but we're only loading one file, so
        # we should be okay
        my $list = Config::Any->load_files({ files => [ $file ]});
        if (! @$list ) {
            require Carp;
            Carp::croak("Could not load config file $file: $@");
        }
        return (values %{$list->[0]})[0];
    }
}

sub scrape
{
    my $self = shift;
    my $config = $self->{config};
    my $scraper = $self->_recurse($config)->();
    return $scraper->scrape(@_);
}

sub _recurse
{
    my ($self, $rules) = @_;

    my $ref = ref($rules);
    my $ret;
    if (! $ref) {
        if ($rules =~ /^__callback\(([^\)]+)\)__$/) {
            $rules = $self->{callbacks}{$1};
        }
        $ret = $rules;
    } elsif ($ref eq 'ARRAY') {
        my @elements;
        foreach my $rule (@$rules) {
            if ($rule =~ /^__callback\(([^\)]+)\)__$/) {
                $rule = $self->{callbacks}{$1};
                push @elements, sub { sub { $rule->(@_) } };
            } else {
                push @elements, ref $rule ? $self->_recurse($rule) : $rule;
            }
        }

        if (! grep { my $ref = ref($_); $ref ? $ref ne 'CODE' : 1 } @elements) {
            $ret = sub {
                foreach my $code (@elements) {
                    $code->()
                }
            };
        } else {
            $ret = \@elements;
        }
    } elsif ($ref eq 'HASH'){
        my($op) = keys %$rules;
        my $h = $self->_recurse($rules->{$op});
        my $is_func = ($op =~ /^(?:scraper|process(?:_first)?|result)$/);

        if ($is_func) {
            my @args = (ref $h eq 'ARRAY') ? @$h : ($h);
            if ($op eq 'scraper') {
                $ret = sub { 
                    scraper(sub { for (@args) { $_->() } })
                };
            } else {
                $ret = sub {
                    my $code = sub {
                        @_ = map { (ref $_ eq 'CODE') ? $_->() : $_ }@args;
                        goto &$op;
                    };
                    $code->()
                };
            }
        } else {
            $ret = { $op => $h };
        }
    } else {
        require Data::Dumper;
        die "Web::Scraper::Config does not know how to parse: " . Data::Dumper::Dumper($rules);
    }

    return $ret;
}

1;

__END__

=head1 NAME

Web::Scraper::Config - Run Web::Scraper From Config Files

=head1 SYNOPSIS

  ---
  scraper:
    - process:
      - td>ul>li
      - trailers[]
      - scraper:
        - process_first:
          - li>b
          - title
          -  TEXT
        - process_first:
          - ul>li>a[href]
          - url
          - @href
        - process:
          - ul>li>ul>li>a
          - movies[]
          - __callback(process_movie)__


  my $scraper = Web::Scraper::Config->new(
    $config,
    {
      callbacks => {
        process_movie => sub {
          my $elem = shift;
          return {
            text => $elem->as_text,
            href => $elem->attr('href')
          }
        }
     }
   }
  );
  $scraper->scrape($uri);

=head1 DESCRIPTION

Web::Scraper::Config allows you to harness the power of Web::Scraper from
a config file.

The config files can be written in any format that Config::Any understands,
as long as it conforms to this module's rules.

=head1 METHODS

=head2 new

Creates a new Web::Scraper::Config instance.

The first arguments is either a hashref that represents a config, or a 
filename to the config. The config file can be in any format that Config::Any 
understands as long as it returns a hash that's conformant to the 
Web::Scraper::Config rules.

The second argument (options) is optional, and is currently only used to
provider callbacks to be called from the scraper. When Web::Scraper::Config
encounters an element in the form of:

  __callback(function_name)__

then that is replaced by the corresponding callback specified in the
options hash.

=head2 scrape

Starts scraping. The semantics are exactly the same as Web::Scraper::scrape

=head1 AUTHOR

Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut