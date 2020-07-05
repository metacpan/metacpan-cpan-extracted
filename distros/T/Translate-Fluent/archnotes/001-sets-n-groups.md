# Resource Sets and Resource Groups

While thinking about how to split the code for this lib and what type
of functionality I would like to to provide with it, I started to think
about the usecases for this.

The reason I started to write this library was because I was looking for
something better than gettext to use for my own framework (SorWeTo) and
for my pet projects.

The way I usually write code, I want to support multiple websites with
different default languages and support for user selected languages in a
single instance of code, and while I could come up with a way to handle
this in the framework itself, I think it would be harder to handle thinks
like partial translations and similar in the framework than in the
translation code itself.

I also think similar functionality would be useful have in other projects
that may be using this. So, I come up with this structure:

## ResourceSet

A ResourceSet is a group of translation resources as defined by
[projectfluent.org]. It is a set because it doesn't not allow for multiple
definitions of the same result multiple times (other than in the ways
provided but the FTL syntax itself.

I plan on allowing to merge multiple ResultSets into a single ResourceSet,
the resulting ResourceSet will still only have one defintion per resource,
with the colision resolution method not defined at this time, but likely
will support a parameter to define which of "keep existing", "keep new" or
"fail" to use.

## ResourceGroup

A ResourceGroup is a collection of ResourceSets with defined contexts and
a way to decide on the priority of such contexts and how to cascade between
different values for the same context. As an example, consider the following
contexts:

```perl
{ app       => "default",
  language  => "default",
},
{ app       => "default",
  language  => "en",
},
{ app       => "superapp",
  language  => "en",
},
{ app       => "superapp",
  language  => "fr",
}
```

When asked for a translation from this ResourceGroup with the context:

```perl
{ app       => "supperapp",
  language  => "fr",
}
```

The ResourceGroup will look for resources first in the the ResourceSet
connect with the context for `app="superapp", language="fr"` and then
on the ResourceSet connect with `app="default", language="default"`.

If the context for translation was for "en", instead of "fr", the search
would happen instead in `app="superapp", language="en"`,
`app="default", language="en"`, `app="default", language="default"`.

This will allow the definition of translations at multiple levels, making
it possible to override at application level translations from libraries
or similar.

## Translations

From an initialization point of view, ResourceSet and ResourceGroup will
be different, as they represent different usecases, but from a translation
point of view, they have the same external behaviour, this way the
translation code itself doesn't need to know whether it is working with
a ResourceSet or a ResourceGroup.


