class HtmlReport {
    public static function report(coverage:coverme.Coverage, out:String) {
        var files = new Map();
        function getFileData(file) {
            var data = files[file];
            if (data == null)
                data = files[file] = {branches: [], statements: []};
            return data;
        }

        for (branch in coverage.branches)
            getFileData(branch.pos.file).branches.push(branch);

        for (statement in coverage.statements)
            getFileData(statement.pos.file).statements.push(statement);

        var output = [
            "<style>
.missing {
    background-color: #fc8c84;
}
.missing:hover {
    background-color: #82B8C0;
}
</style>",
        ];

        for (file in files.keys()) {
            output.push('<h1>$file</h1>');
            var content = sys.io.File.getContent(file);
            var chars = [
                for (i in 0...content.length) {
                    var c = content.charAt(i);
                    c = StringTools.htmlEscape(c, true);
                    c = ~/\r?\n/.replace(c, "<br/>\n");
                    c = StringTools.replace(c, " ", "&nbsp;");
                    c = StringTools.replace(c, "\t", "&nbsp;&nbsp;&nbsp;&nbsp;");
                    c;
                }
            ];
            var insertions = new Map<Int,Array<String>>();

            function insert(pos:Int, html:String) {
                var ins = insertions[pos];
                if (ins == null)
                    ins = insertions[pos] = [];
                ins.push(html);
            }

            var fileData = files[file];

            for (branch in fileData.branches) {
                var missing = [];
                if (branch.result.trueCount == 0)
                    missing.push("true");
                if (branch.result.falseCount == 0)
                    missing.push("false");
                if (missing.length > 0) {
                    insert(branch.pos.min, '<span class="missing" title="path${if (missing.length > 1) "s" else ""} not taken: ${missing.join(", ")}">');
                    insert(branch.pos.max, '</span>');
                }
            }

            for (statement in fileData.statements) {
                if (statement.result == 0) {
                    insert(statement.pos.min, '<span class="missing" title="statement not executed">');
                    insert(statement.pos.max, '</span>');
                }
            }

            var resultChars = [];
            for (i in 0...chars.length) {
                var ins = insertions[i];
                if (ins != null) {
                    for (c in ins)
                        resultChars.push(c);
                }
                resultChars.push(chars[i]);
            }

            output.push('<code>');
            output.push(resultChars.join(""));
            output.push('</code>');
        }

        var html = output.join("\n");
        sys.io.File.saveContent(out, html);
    }
}