#line 1
package Data::Section::Simple;

use strict;
use 5.008_001;
our $VERSION = '0.02';

use base qw(Exporter);
our @EXPORT_OK = qw(get_data_section);

sub new {
    my($class, $pkg) = @_;
    bless { package => $pkg || caller }, $class;
}

sub get_data_section {
    my $self = ref $_[0] ? shift : __PACKAGE__->new(scalar caller);

    if (@_) {
        return $self->get_data_section->{$_[0]};
    } else {
        my $d = do { no strict 'refs'; \*{$self->{package}."::DATA"} };
        return unless defined fileno $d;

        seek $d, 0, 0;
        my $content = join '', <$d>;
        $content =~ s/^.*\n__DATA__\n/\n/s; # for win32
        $content =~ s/\n__END__\n.*$/\n/s;

        my @data = split /^@@\s+(.+?)\s*\r?\n/m, $content;
        shift @data; # trailing whitespaces

        my $all = {};
        while (@data) {
            my ($name, $content) = splice @data, 0, 2;
            $all->{$name} = $content;
        }

        return $all;
    }
}

1;
__END__

=encoding utf-8

#line 130
