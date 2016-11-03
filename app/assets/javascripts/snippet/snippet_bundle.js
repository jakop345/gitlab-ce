/* eslint-disable */

// require everything else in this directory
function require_all(context) { return context.keys().map(context); }
require_all(require.context('.', false, /^\.\/(?!snippet_bundle).*\.(js|es6)$/));

(function() {
  $(function() {
    var editor = ace.edit("editor")

    $(".snippet-form-holder form").on('submit', function() {
      $(".snippet-file-content").val(editor.getValue());
    });
  });

}).call(this);
