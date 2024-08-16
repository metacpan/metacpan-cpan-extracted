# Brief Internals of YATT::Lite::CGen::Perl

## Template (Widget)

```html
<!yatt:args a=text b=text>

**Toplevel**

&yatt:a;

<yatt:foo -- x, y, z, w is assignments --
  x="...assignment to text..."
  z="... to value"
  w="... to list"
>

  **Toplevel (in body closure)**

  <yatt:bar x="foo &yatt:a; bar">
    <:yatt:y>... to html</:yatt:y>

    **Toplevel (in body closure)**

  </yatt:bar>

<:yatt:y/>
  ... to html
</yatt:foo>
```

```html
<!yatt:widget foo x=text y=html z=value w=list body=[code]>

<!yatt:widget bar x=text y=html z=value w=list body=[code]>

```

※processing instructions `<?perl= ... ?>` are omitted in this doc.

### How toplevel code generator works - a simplified version of `as_print()`

Basically, `as_print()` scans current tokens in `$self->{curtoks}` and generates a sequence of statements which mostly are print statements. (Users of as_print() must put input tokens to `curtoks` with proper localization before its invocation). (Note: Real implementation of as_print contains more logic for better(?) line splitting of generated code).

- Most tokens are converted to **printable expressions** and queued to `@queue`.
- Then if the current token contains a newline, all items of `@queue` are removed, are wrapped by a `print` statement, and go to the final code fragment list `@result`.
- Also, token handlers can generate **general statements** (represented by scalar reference) that directly goes to `@result`.
- Finally, every generated code in `@result` is joined to a result string.

```perl
sub as_print {
  my ($self) = @_;
  my (@result, @queue);
  my sub flush {
    push @result, q{print $CON (}.join(", ", @queue). q{);} if @queue;
    undef @queue;
  }
  while (@{$self->{curtoks}}) {
    my $node = @{$self->{curtoks}};
    if (not ref $node) {
      push @queue, qtext($node);
      flush() if $node =~ /\n/;
    }
    else {
      my $handler = $DISPATCH[$node->[0]]; # from_element, from_entity...
      my $expr = $handler->($self, $node);
      if (ref $expr) {
        flush();
        push @result, "$$expr;";
      }
      else {
        push @queue, $expr;
        flush() if $expr =~ /\n/;
      }
    }
  }
  flush();
  join " ", @result;
}
```

### as_text, as_list and gen_as([list | text])

```perl
sub as_text { join '.', gen_as(text => \@AS_TEXT, 0, 1, @_) }
sub as_list {           gen_as(list => \@AS_LIST, 0, 0, @_) }

sub gen_as {
  my ($self, $type, $dispatch, $escape, $text_quote, @node) = @_;
  local $self->{needs_escaping} = $escape;

  my @result = map {
    if (not ref $_) {
      $text_quote ? qtext($_) : $_;
    } else {
      my $handler = $dispatch->[$_->[0]];
      my $expr = $handler->($self, $_);
      defined $expr ? $expr : ();
    }
  } @node;

  wantarray ? @result : join("", @result)
}
```

Other cast
```perl
sub as_cast_to_text($self, $var, $value) {
  ref $value ? $self->as_text(@$value) : qtext($value); 
}
sub as_cast_to_html($self, $var, $value) {
  ref $value ? join('.', gen_as(text => \@AS_TEXT, 1, 1, @$value)) : qtext($value); 
}
sub as_cast_to_scalar($self, $var, $value) {
  'scalar(do {'.(ref $value ? $self->as_list(@$value) : $value).'})';
}
sub as_cast_to_list($self, $var, $value) {
  '['.(ref $value ? $self->as_list(@$value) : $value).']';
}
sub as_cast_to_code($self, $var, $value) {
  local $self->{curtoks} = [@$value];
  my Widget $virtual = $var->widget;
  local $self->{scope} = $self->mkscope
    ({}, $virtual->{arg_dict} ||= {}, $self->{scope});
  q|sub {|. join('', $self->gen_getargs($virtual)
		   , $self->as_print("}"));
}
```


### Corresponding handlers for each node kinds and their appeared contexts

<table border="0" cellspacing="0" cellpadding="0" class="table-1">
<style>
table.table-1 th {text-align: left;}
table.table-1 th.bottom {border-bottom-width: 5px;}
table.table-1 th.right  {border-right-width:  5px;}
</style>
<colgroup>
<col width="140"/>
<col width="80"/>
<col width="90"/>
<col width="181"/>
<col width="201"/>
</colgroup>
<tr class="ro4">
<th colspan="2" rowspan="2" class="bottom right"><p>Context \ Node Kind</p></th>
<th rowspan="2" class="bottom"><p>constant text</p><p>(trusted)</p></th>
<th rowspan="2" class="bottom"><p>element</p><p>(general statement)</p></th>
<th rowspan="2" class="bottom"><p>entity</p><p>(typed replacement)</p></th></tr>
<tr class="ro4"/>
<tr class="ro5">
<th colspan="2" class="right"><p>Toplevel</p><p>(= Output as_print())</p></th><td><p>qtext()</p></td>
<td><p>from_element (invoke)</p></td>
<td rowspan="6"><p>from_entity() </p><p>→ gen_entpath( <b><code>$self->{needs_escaping}</code></b> )</p></td></tr>
<tr class="ro6">
<th rowspan="5"><p>Assignment (Cast to type)</p><p>/ Composition</p></th>
<th class="right"><p>text</p><p>as_cast_to_text:</p></th>
<td><p>qtext()</p><p>/ as_text()</p></td>
<td><p>?text_from_element</p><p>→ <code>capture {</code><br>from_element<br><code>}</code></p></td></tr>
<tr class="ro6">
<th class="right"><p>html</p><p>as_cast_to_html:</p></th>
<td><p>qtext()</p><p>/ gen_as(text, <b>escaping</b>, <b>text_quote</b>)</p></td>
<td><p>?text_from_element</p><p>→ <code>capture {</code><br>from_element<br><code>}</code></p></td></tr>
<tr class="ro3">
<th class="right"><p>value</p><p>as_cast_to_scalar:</p></th>
<td><p><code>scalar do {</code>gen_as(list)<code>}</code></p></td>
<td><p>-</p></td></tr>
<tr class="ro3">
<th class="right"><p>list</p><p>as_cast_to_list:</p></th>
<td><p><code>[</code>gen_as(list)<code>]</code></p></td>
<td><p>-</p></td></tr>
<tr class="ro3">
<th class="right"><p>code<br>(widget)</p><p>as_cast_to_code:</p></th>
<td><p><b>escaping</b>, as_print</p></td>
<td><p>from_element (invoke)</p></td></tr>
</table>

## Entity Path Items

YATT entities like `&yatt:foo;` are parsed as a namespace prefix `&yatt`, one or more entity path items `:foo` and terminal `;`.
* Entity path items can start either `:var` or `:call(...)` which can also takes path items as arguments in `(...)`.
  ```
  :var
  :call(...)
  ```


* In entity arguments `(...)`, each startings of path items can also be `(text)`, `(=expr)`, `[array]` and `{hash}`.

  ```
  (text...)
  (=expr...)
  [array...]
  {hash...}
  ```


* After the leading items, arbitrary number of `:prop`, `:invoke(...)`, `[aref]` and `{href}` can follow.

  ```
  〜:prop
  〜:invoke(...)
  〜[aref...]
  〜{href...}
  ```


### How entpath code generator works - a simplified version of `gen_entpath()`

```perl
sub gen_entpath {
  my ($self, $escape_now, @pathItems) = @_;
  return '' unless @pathItems;
  local $self->{needs_escaping} = 0;
  if (my $macro = $self->_is_entmacro_call($pathItems[0])) {
    return $macro->($self, $pathItems[0])
  }
  my @pathCodes = map {
    my ($type, @rest) = @$_;
    my $handler = $self->can("as_expr_$type");
    $handler->($self, \$escape_now, @rest);
  } @pathItems;
  return '' unless @pathCodes;
  my $result = @pathCodes > 1 ? join("->", @pathCodes) : $pathCodes[0];
  if (not $escape_now or ref $result) {
    # as_expr_var_html comes here because not $escape_now
    # as_expr_call_var comes here because ref $result
    $result;
  } else {
    sprintf(q{YATT::Lite::Util::escape(%s)}, $result);
  }
}
```

### Corresponding handlers called from gen_entpath

<table border="0" cellspacing="0" cellpadding="0" class="ta1">
<colgroup>
<col width="111"/>
<col width="111"/>
<col width="128"/>
<col width="181"/>
<col width="407"/>
</colgroup>
<tr class="ro4">
<td><p>path place</p></td>
<td><p>path item kind</p></td>
<td><p>handler</p></td>
<td><p>name kind/var type</p></td>
<td><p>codegen action (pseudo code with JS style template string)</p></td>
</tr>
<tr class="ro4">
<td><p>head</p></td>
<td><p>var</p></td>
<td><p>as_expr_var($name)</p></td>
<td> </td>
<td><p>as_lvalue($var)</p></td>
</tr>
<tr class="ro4">
<td> </td>
<td> </td>
<td> </td>
<td><p>entity</p></td>
<td><p>gen_entcall($name)</p></td>
</tr>
<tr class="ro5">
<td> </td>
<td> </td>
<td> </td>
<td><p>var html</p><p><span class="T2">→ as_expr_var_html</span></p></td>
<td><p>This entpath is returned as-is(== no need to be escaped in gen_entpath)<code>($$esc_later = 0)</code>, as_lvalue_html($var)</p></td>
</tr>
<tr class="ro5">
<td> </td>
<td> </td>
<td> </td>
<td><p>var attr</p><p><span class="T2">→ as_expr_var_attr</span></p></td>
<td><p><code>named_attr(${attname // name}, ${name})</code></p></td>
</tr>
<tr class="ro4">
<td> </td>
<td><p>call</p></td>
<td><p>as_expr_call($name, @args)</p></td>
<td> </td>
<td> </td>
</tr>
<tr class="ro4">
<td> </td>
<td> </td>
<td> </td>
<td><p>entity</p></td>
<td><p>gen_entcall($name, @args)</p></td>
</tr>
<tr class="ro5">
<td> </td>
<td> </td>
<td> </td>
<td><p>var </p><p><span class="T2">→ as_expr_call_var</span></p></td>
<td><p><code>${name} &amp;&amp; ${name}(${ gen_entlist(@args) })</code></p></td>
</tr>
<tr class="ro5">
<td> </td>
<td> </td>
<td> </td>
<td><p>var attr</p><p><span class="T2">→ as_expr_call_var_attr</span></p></td>
<td><p><code>named_attr(${attname // name}, ${ gen_entlist(@args) })</code></p></td>
</tr>
<tr class="ro4">
<td><p>arg head</p></td>
<td><p>text</p></td>
<td><p>as_expr_text($val)</p></td>
<td> </td>
<td><p>qqvalue($val)</p></td>
</tr>
<tr class="ro4">
<td> </td>
<td><p>expr</p></td>
<td><p>as_expr_expr($val)</p></td>
<td> </td>
<td><p>$val</p></td>
</tr>
<tr class="ro4">
<td> </td>
<td><p>array</p></td>
<td><p>as_expr_array(@args)</p></td>
<td> </td>
<td><p><code>[${ gen_entlist(@args) }]</code></p></td>
</tr>
<tr class="ro4">
<td> </td>
<td><p>hash</p></td>
<td><p>as_expr_hash(@args)</p></td>
<td> </td>
<td><p><code>{${ gen_entlist(@args) }}</code></p></td>
</tr>
<tr class="ro4">
<td><p>rest</p></td>
<td><p>prop</p></td>
<td><p>as_expr_prop($name)</p></td>
<td> </td>
<td><p>$name</p></td>
</tr>
<tr class="ro4">
<td> </td>
<td><p>invoke</p></td>
<td><p>as_expr_invoke($name, @args)</p></td>
<td> </td>
<td><p><code>${name}(${ gen_entlist(@args) })</code></p></td>
</tr>
<tr class="ro4">
<td> </td>
<td><p>aref</p></td>
<td><p>as_expr_aref(@args)</p></td>
<td> </td>
<td><p><code>[${ gen_entpath(@args) }]</code></p></td>
</tr>
<tr class="ro4">
<td> </td>
<td><p>href</p></td>
<td><p>as_expr_href(@args)</p></td>
<td> </td>
<td><p><code>{${ gen_entpath(@args) }}</code></p></td>
</tr>
</table>

Note:

- <code>gen_entlist(@args)</code> is approximately:
  ```perl
  map {gen_entpath(@$_)} @args
  ```
- <code>gen_entcall($name, @args)</code> generates:
  ```js
  `$this->entity_${name}(${ gen_entlist(@args) })`
  ```

## TODO

- escape_now? escape_later? Which is true?
