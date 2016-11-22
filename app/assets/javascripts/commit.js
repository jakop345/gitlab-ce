/* eslint-disable func-names, space-before-function-paren */
/* global CommitFile */

(function() {
  this.Commit = (function() {
    function Commit() {
      $('.files .diff-file').each(function() {
        return new CommitFile(this);
      });
    }

    return Commit;
  }());
}).call(this);
