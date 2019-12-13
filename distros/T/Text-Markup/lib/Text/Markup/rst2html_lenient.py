#!/usr/bin/env python3
"""
Parse a reST file into HTML in a very forgiving way.

The script is meant to render specialized reST documents, such as Sphinx
files, preserving the content, while not emulating the original rendering.

The script is currently tested against docutils 0.7-0.10. Other versions may
break it as it deals with the parser at a relatively low level. Use
--test-patch to verify if the script works as expected with your library
version.
"""

import sys

import docutils
from docutils import nodes, utils, SettingsSpec
from docutils.core import publish_cmdline, publish_string, default_description
from docutils.parsers.rst import Directive, directives, roles
from docutils.writers.html4css1 import HTMLTranslator, Writer
from docutils.parsers.rst.states import Body, Inliner
from docutils.frontend import validate_boolean

class any_directive(nodes.General, nodes.FixedTextElement):
    """A generic directive to deal with any unknown directive we may find."""
    pass

class AnyDirective(Directive):
    """A directive returning its unaltered body."""
    optional_arguments = 100 # should suffice
    has_content = True

    def run(self):
        if self.name in self.state.document.settings.dir_ignore:
            return []

        children = []

        if self.name not in self.state.document.settings.dir_notitle:
            children.append(nodes.strong(self.name, "%s: " % self.name))
            # keep the arguments, drop the options
            for a in self.arguments:
                if a.startswith(':') and a.endswith(':'):
                    break
                children.append(nodes.emphasis(a, "%s " % a))

        if self.name in self.state.document.settings.dir_nested:
            if self.content:
                container = nodes.Element()
                self.state.nested_parse(self.content, self.content_offset,
                                        container)
                children.extend(container.children)
        else:
            content = '\n'.join(self.content)
            children.append(nodes.literal_block(content, content))

        node = any_directive(self.block_text, '', *children, dir_name=self.name)

        return [node]


class any_role(nodes.Inline, nodes.TextElement):
    """A generic role to deal with any unknown role we may find."""
    pass

class AnyRole:
    """A role to be rendered as a generic element with a specific class."""
    def __init__(self, role_name):
        self.role_name = role_name

    def __call__(self, role, rawtext, text, lineno, inliner,
                 options={}, content=[]):
        roles.set_classes(options)
        options['role_name'] = self.role_name
        node = any_role(rawtext, utils.unescape(text), **options)
        return [node], []


def catchall_directive(self, match, **option_presets):
    """Directive dispatch method.

    Replacement for Body.directive(): if a directive is not known, build one
    on the fly instead of reporting an error.
    """
    type_name = match.group(1)
    directive_class, messages = directives.directive(
        type_name, self.memo.language, self.document)

    # in case it's missing, register a generic directive
    if not directive_class:
        directives.register_directive(type_name, AnyDirective)
        directive_class, messages = directives.directive(
            type_name, self.memo.language, self.document)
        assert directive_class, "can't find just defined directive"

    self.parent += messages
    return self.run_directive(
        directive_class, match, type_name, option_presets)


def catchall_interpreted(self, rawsource, text, role, lineno):
    """Interpreted text role dispatch method.

    Replacement for Inliner.interpreted(): if a role is not known, build one
    on the fly instead of reporting an error.
    """
    role_fn, messages = roles.role(role, self.language, lineno,
                                   self.reporter)
    # in case it's missing, register a generic role
    if not role_fn:
        role_obj = AnyRole(role)
        roles.register_canonical_role(role, role_obj)
        role_fn, messages = roles.role(
            role, self.language, lineno, self.reporter)
        assert role_fn, "can't find just defined role"

    nodes, messages2 = role_fn(role, rawsource, text, lineno, self)
    return nodes, messages + messages2


def patch_docutils():
    """Change the docutils parser behaviour."""
    # Patch the constructs dispatch table
    for i, (f, p) in enumerate(Body.explicit.constructs):
        if f is Body.directive is f:
            Body.explicit.constructs[i] = (catchall_directive, p)
            break
    else:
        assert False, "can't find directive dispatch entry"

    # Patch the parser so that when an unknown directive is found, a generic one
    # is generated on the fly.
    Body.directive = catchall_directive

    # Patch the parser so that when an unknown interpreted text role is found,
    # a generic one is generated on the fly.
    Inliner.interpreted = catchall_interpreted


class MyTranslator(HTMLTranslator):
    """An HTML translator that can render with any_role/any_directive.
    """
    def visit_any_directive(self, node):
        cls = node.get('dir_name')
        cls = cls and 'directive-%s' % cls or 'directive'
        self.body.append(self.starttag(node, 'div', CLASS=cls))

    def depart_any_directive(self, node):
        self.body.append('\n</div>\n')

    def visit_any_role(self, node):
        cls = node.get('role_name')
        cls = cls and 'role-%s' % cls or 'role'
        self.body.append(self.starttag(node, 'span', '', CLASS=cls))

    def depart_any_role(self, node):
        self.body.append('</span>')


class LenientSettingsSpecs(SettingsSpec):
    settings_spec = ("Lenient parsing options", None, (
        ("Directive whose content should be interpreted as reST.  "
         "By default emit the content as unparsed text block.  "
         "Can be specified more than once",
            ["--dir-nested"],
            {'metavar': 'NAME', 'default': [], 'action': 'append'}),
        ("Directive that should produce no output.  "
         "Can be specified more than once",
            ["--dir-ignore"],
            {'metavar': 'NAME', 'default': [], 'action': 'append'}),
        ("Only emit the content of the directive, no title and options.  "
         "Can be specified more than once",
            ["--dir-notitle"],
            {'metavar': 'NAME', 'default': [], 'action': 'append'}),
        ("Verify that lenient customization works fine.  "
         "Immediately return with 0 (success) or 1 (error).  "
         "In case of error, print a report on stdout.",
            ['--test-patch'],
            {'action': 'store_true', 'validator': validate_boolean}),
    ))


def main():

    # Create a writer to deal with the generic element we may have created.
    writer = Writer()
    writer.translator_class = MyTranslator

    description = (
        'Generates (X)HTML documents from standalone reStructuredText '
       'sources.  Be forgiving against unknown elements.  '
       + default_description)

    # the parser processes the settings too late: we want to decide earlier if
    # we are running or testing.
    if ('--test-patch' in sys.argv
            and not ('-h' in sys.argv or '--help' in sys.argv)):
        return test_patch(writer)

    else:
        # Make docutils lenient.
        patch_docutils()

        overrides = {
            # If Pygments is missing, code-block directives are swallowed
            # with Docutils >= 0.9.
            'syntax_highlight': 'none',

            # not available on Docutils < 0.8 so can't pass as an option
            'math_output': 'HTML',
        }

        publish_cmdline(writer=writer, description=description,
             settings_spec=LenientSettingsSpecs, settings_overrides=overrides)
        return 0

def test_patch(writer):
    """Verify that patching docutils works as expected."""
    TEST_SOURCE = """`
Hello `role`:norole:

.. nodirective::
"""
    rv = 0
    problems = []
    exc = None

    # patch and use lenient docutils
    try:
        try:
            patch_docutils()
        except Exception as exc:
            problems.append("error during library patching")
            raise

        try:
            out = publish_string(TEST_SOURCE,
                writer=writer, settings_spec=LenientSettingsSpecs,
                settings_overrides={'output_encoding': 'unicode'})
        except Exception as exc:
            problems.append("error while running patched docutils")
            raise

    except:
        pass

    # verify conform output
    else:
        out = out.replace("'", '"')
        if '<span class="role-norole">' not in out:
            problems.append(
                "unknown role didn't produce the expected output")

        if '<div class="directive-nodirective">' not in out:
            problems.append(
                "unknown directive didn't produce the expected output")

    # report problems if any
    if problems:
        rv = 1
        print("Patching docutils failed!", file=sys.stderr)
        for problem in problems:
            print("-", problem, file=sys.stderr)

    if rv:
        print("\nVersions:", \
            'docutils:', docutils.__version__, docutils.__version_details__, \
            '\nPython:', sys.version, file=sys.stderr)

    if exc:
        if '--traceback' in sys.argv:
            print(file=sys.stderr)
            import traceback
            traceback.print_exc()
        else:
            print("\nUse --traceback to display the error stack trace.", file=sys.stderr)

    return rv

if __name__ == '__main__':
    sys.exit(main())

