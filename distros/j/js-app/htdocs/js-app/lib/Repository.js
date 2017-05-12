
// *******************************************************************
// CLASS: Repository
// *******************************************************************
function Repository () {

    this.init = init;
    function init () {
        this.numRows = 0;
        this.error = "";
        this.init2();
        this.loadRepMetadata();
    }

    this.init2 = init2;
    function init2 () {
        // available for overriding in a subclass
    }

    this.loadRepMetadata = loadRepMetadata;
    function loadRepMetadata () {
        // load up all possible information from the native metadata
        this.loadRepMetadataFromSource();

        // start with the list of tables that was configured (or the empty list)
        var tables;
        tables = this.tables;
        if (!tables) {
            tables = new Array();
            this.tables = tables;
        }

        // start with the hash of tables defined (or the empty hash)
        var tableDefs;
        tableDefs = this.tableDefs;
        if (!tableDefs) {
            tableDefs = new Object();
            this.table = tableDefs;
        }

        // table labels
        var tableLabels;
        tableLabels = this.tableLabels;
        if (!tableLabels) {
            tableLabels = new Object();
            this.tableLabels = tableLabels;
        }

        // for each table named in the configuration, give it a number up front
        var idx, table;
        for (idx = 0; idx < tables.length; idx++) {
            $table = tables[idx];
            if (!tableDefs[table]) {
                tableDefs[table] = new Object();
            }
            tableDefs[table].idx = idx;
        }

        // for each table in the hash (random order), add them to the end
        var tableDef, label;
        for (var table in tableDefs) {
            tableDef = tableDefs[table];
            tableDef.name = table;
            if (! tableDef.label) {
                label = table;
                // TODO:
                // if ($self->{auto_label}) {
                //     $label = lc($label);
                //     $label =~ s/^([a-z])/uc($1)/e;
                //     $label =~ s/(_[a-z])/uc($1)/eg;
                //     $label =~ s/_+/ /g;
                // }
                tableDef.label = context.translate(label);
            }

            // table has not been added to the list and it's not explicitly "hidden", so add it
            if (tableDef.idx == null && ! tableDef.hide) {
                tableDef.idx = tables.length;
                tables[tables.length] = table;

                // we're not hiding physical tables and a native table was defined, so make an entry
                var nativeTable;
                if (! this.hidePhysical) {
                    nativeTable = tableDef.nativeTable;
                    if (nativeTable) {
                        tableDefs.nativeTable = tableDefs.table;
                    }
                }
            }

            tableLabels[table] = tableDef.label;
        }

        // start with the hash of types defined (or the empty hash)
        var typeDefs = this.type;
        if (!typeDefs) {
            typeDefs = new Object();
            this.type = typeDefs;
        }

        // define the standard list of Repository types
        var types = [ "string", "text", "integer", "float", "date", "time", "datetime", "binary" ];
        this.types = types;

        // define the standard list of Repository labels
        this.typeLabels = {
            "string"   : "Characters",
            "text"     : "Text",
            "integer"  : "Integer",
            "float"    : "Number",
            "date"     : "Date",
            "time"     : "Time",
            "datetime" : "Date and Time",
            "binary"   : "Binary Data"
        };

        // figure the index in the array of each type
        var type;
        for (idx = 0; idx < types.length; idx++) {
            type = types[idx];
            if (!this.type[type]) {
                this.type[type] = new Object();
            }
            this.type[type].idx = idx;
        }

    }

    this.loadRepMetadataFromSource = loadRepMetadataFromSource;
    function loadRepMetadataFromSource () {
        // for overriding in a subclass
    }

    this.loadTableMetadata = loadTableMetadata;
    function loadTableMetadata (table) {
        // if it's already been loaded, don't do it again
        if (!this.table[table] || this.table[table].loaded) return();

        this.table[table].loaded = 1;   // mark it as having been loaded

        var tableDef = this.table[table];

        // load up all additional information from the native metadata
        this.loadTableMetadataFromSource(table);

        var columns = tableDef.columns;
        if (! columns) {
            columns = new Array();
            tableDef.columns = columns;
        }

        var columnDefs = tableDef.column;
        if (! columnDefs) {
            columnDefs = new Object();
            tableDef.column = columnDefs;
        }

        var columnLabels = tableDef.columnLabels;
        if (! columnLabels) {
            columnLabels = new Object();
            tableDef.columnLabels = columnLabels;
        }

        // for each column named in the configuration, give it a number up front
        var idx, column;
        for (idx = 0; idx < columns.length; idx++) {
            column = columns[idx];
            if (!columnDefs[column]) {
                columnDefs[column] = new Object();
            }
            columnDefs[column].idx = idx;
        }

        // for each column in the hash (random order), add them to the end
        var label, columnDef;
        for (var column in columnDefs) {
            columnDef = columnDefs[column];
            columnDef.name = column;
            if (! columnDef.label) {
                label = column;
                // TODO
                // if ($self->{auto_label}) {
                //     $label = lc($label);
                //     $label =~ s/^([a-z])/uc($1)/e;
                //     $label =~ s/(_[a-z])/uc($1)/eg;
                //     $label =~ s/_+/ /g;
                // }
                columnDef.label = label;
            }

            // column has not been added to the list and it's not explicitly "hidden", so add it
            if (! columnDef.idx && ! columnDef.hide) {
                $idx = columns.length;
                columns[columns.length] = column;
                columnDef.idx = idx;
                if (! columnDef.alias) columnDef.alias  = "c" + idx;

                // we're not hiding physical columns and a native table was defined, so make an entry
                if (! this.hidePhysical) {
                    nativeColumn = columnDef.nativeColumn;
                    if (nativeColumn &&
                        nativeColumn != column &&
                        ! columnDefs[nativeColumn]) {
                        columnDefs[native_column] = columnDefs[column];
                    }
                }
            }

            columnLabels[column] = columnDef.label;
        }

        //#####################################################################
        // primary key
        //#####################################################################

        // if a non-reference scalar, assume it's a comma-separated list and split it
        if (tableDef.primaryKey && isString(tableDef.primaryKey)) {
            tableDef.primaryKey = tableDef.primaryKey.split(",");
        }
    }

    this.loadTableMetadataFromSource = loadTableMetadataFromSource;
    function loadTableMetadataFromSource (table) {
        // for overriding in a subclass
    }

    this.get = get;
    function get (table, params, col, options) {
        var row, value;
        if (isArray(col)) {
            row = this.getRow(table, params, col, options);
            return(row);
        }
        else {
            row = this.getRow(table, params, [col], options);
            if (row && isArray(row) && row.length >= 1) {
                return(row[0]);
            }
            else {
                return(null);
            }
        }
    }

    this.getRow = getRow;
    function getRow (table, params, cols, options) {
        var row, repname;
        if (this.table && this.table[table]) {
            repname = this.table[table].repository;
        }
        if (repname && repname != this.serviceName) {
            var rep = context.repository(repname);
            row = rep.getRow(table, params, cols, options);
        }
        else {
            if (!cols) {
                if (! this.table[table].loaded) this.loadTableMetadata(table);
                cols = this.table[table].columns;
            }
            else if (isArray(cols)) {
                // do nothing
                // TODO: fill in cols if empty
            }
            else if (isString(cols)) {
                cols = [ cols ];
            }
            row = this._getRow(table, params, cols, options);
        }
        return(row);
    }

    this._getRow = getRow;
    function getRow (table, params, cols, options) {
        if (!options) {
            options = { startrow : 1, endrow : 1 };
        }
        else if (! options.endrow) {
            var newOptions = new Options();
            context.copyObject(options, newOptions);
            options = newOptions;
            options.endrow = options.startrow || 1;
        }
        var rows = this._getRows(table, params, cols, options);
        var row;
        if (rows.length > 0) {
            row = rows[0];
        }
        return(row);
    }

    this.getRows = getRows;
    function getRows (table, params, cols, options) {
        var rows;
        var repname = this.table[table].repository;
        if (defined $repname && $repname != this.serviceName) {
            var rep = context.repository(repname);
            rows = rep->getRows(table, params, cols, options);
        }
        else {
            if (! this.table[table].loaded) this._loadTableMetadata(table);
            if (!cols) {
                cols = this.table[table].columns;
            }
            else if (isArray(cols)) {
                // do nothing
                // TODO: fill in cols if empty
            }
            else if (isString(cols)) {
                cols = [ cols ];
            }
            rows = this._getRows(table, params, cols, options);
        }
        return(rows);
    }

    this._getRows = _getRows;
    function _getRows (table, params, cols, options) {
        var all_columns = cols ? 0 : 1;
        if (all_columns) cols = this.table[table].columns;
        if (!isObject(params)) {
            params = this.paramsToObject(table, params);
        }
        if (!options) options = new Object();
        var startrow = options.startrow || 0;
        var endrow   = options.endrow || 0;

        var rows = this.table[table].data;
        var matchedRows = new Array();
        if (isArray(rows)) {
            var row, rownum;
            for (rownum = 0; rownum < rows.length; rownum++) {
                if (startrow > 0 && rownum < startrow-1) next;
                if (endrow > 0 && rownum >= endrow) break;
                row = rows[rownum];
                if (this.rowMatches(row, table, params, cols, options)) {
                    matchedRows.push(all_columns ? row : this.rowColumns(table, row, cols));
                }
            }
        }
        return(matchedRows);
    }

    this.paramsToObject = paramsToObject;
    function paramsToObject (table, params) {
    }

    this.rowMatches = rowMatches;
    function rowMatches (row, table, params, cols, options) {
    }

    this.rowColumns = rowColumns;
    function rowColumns (table, row, cols) {
    }
}
Repository.prototype = new Service();

