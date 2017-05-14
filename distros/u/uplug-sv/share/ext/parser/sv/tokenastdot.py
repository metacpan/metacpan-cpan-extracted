class Token:

    def __init__(self, type, attr=None):
        self.type = type
        self.attr = attr
        
    def __cmp__(self, o):
        return cmp(self.type, o)

    def __str__(self):
        if self.attr != None:
            return "%s : %s" % (self.type, self.attr)
        else:
            return "%s :" % self.type


class AST:

    def __init__(self, type, kids=None):
        self.type = type.type
        self.attr = type.attr
        if kids == None:
            self._kids = []
        else:
            self._kids = kids

    def __getitem__(self, i):
        return self._kids[i]

    def makeDotFile(self, ratio=0.25, size=(35, 10), header=None):
        if header == None:
            header = 'digraph pvn {\n    ordering=out;\n    ' \
                     'ratio=%s;\n    size="%s,%s";\n\n' \
                     % ((ratio,) + size)
        L = [header]
        self._dot_inner(1, L)
        L.append("}\n")
        return "".join(L)

    def _dot_inner(self, my_index, SL):
        "Returns the new my_index"
        # Add content
        SL.append('    %s [label="%s"];\n' % (my_index, self.label()))
        # Add kids
        kid_index = my_index + 1
        for kid in self:
            SL.append('    %s -> %s;\n' % (my_index, kid_index))
            kid_index = kid._dot_inner(kid_index, SL)
        return kid_index

    def label(self): # Override this method to get specific labels
        if self.attr:
            return "%s:\n%s" % (self.type, self.attr)
        else:
            return "%s:" % self.type
