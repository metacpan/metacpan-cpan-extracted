# Text::Stencil

Fast XS list/table renderer with escaping, formatting, and transform chaining.

## Synopsis

```perl
use Text::Stencil;

my $s = Text::Stencil->new(
    header => '<table><tr><th>id</th><th>name</th></tr>',
    row    => '<tr><td>{0:int}</td><td>{1:html}</td></tr>',
    footer => '</table>',
);
my $html = $s->render(\@rows);

# hashrefs, chaining, separator
my $s = Text::Stencil->new(
    header => '<ul>',
    row    => '<li>{title:default:Untitled|trim|trunc:80|html}</li>',
    footer => '</ul>',
    separator => "\n",
);

# single row, stream to file
print $s->render_one({id => 1, title => 'Hello'});
$s->render_to_fh($fh, \@rows);
```

## Performance

Perl 5.40, x86_64 Linux.

**HTML table** (13 rows, html escape):

| Renderer | Rate | vs Xslate |
|---|---|---|
| Text::Xslate | 413K/s | -- |
| render hashref | 733K/s | +77% |
| render chained | 813K/s | +97% |
| render arrayref | 922K/s | +123% |
| render_one | 5161K/s | +1150% |

**Transform throughput** (1000 rows, single transform):

```
default:x  67.4K/s    int       52.4K/s    raw   39.8K/s
trunc:20   44.4K/s    int_comma 50.1K/s    json  33.7K/s
uc         36.4K/s    html      28.7K/s    url   32.2K/s
```

**Row count scaling**: ~25M rows/s constant from 10 to 10,000 rows.

Run `perl bench.pl` for your own numbers.

## Documentation

Full docs: [metacpan.org/pod/Text::Stencil](https://metacpan.org/pod/Text::Stencil)

## License

Same terms as Perl itself.
