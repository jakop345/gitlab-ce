/* global Api */
/*= require droplab */
/*= require droplab-ajax-datasource */
/*= require droplab-remote-filter */
/*= require droplab-infinite-scroll */

(() => {
  const global = window.gl || (window.gl = {});

  class GroupsDroplab {
    constructor() {
      var loadedAllElement = document.createElement('p');
      loadedAllElement.textContent = 'Showing all groups';

      var loadingElement = document.createElement('i');
      loadingElement.classList = 'fa fa-spinner fa-spin';

      droplab.setConfig({
        inputor: {
          trigger: 'inputor',
          endpoint: Api.buildUrl(Api.groupsPath),
          searchKey: 'search',
          paginationKey: 'page',
          loadingHTML: function loadingHTML(data, req) {
            var total;
            var currentData = droplab.hooks.filter(function(hook) {
              return hook.id === this.id;
            }.bind(this))[0].list.data;

            if (req) total = parseInt(req.getResponseHeader('X-Total'), 10);

            if (!data && !req) {
              return loadingElement;
            } else if (currentData.length === total) {
              return loadedAllElement;
            } else {
              var container = document.createElement('div');
              var message = document.createElement('p');

              message.textContent = 'Loading more groups... (' + (total - currentData.length) + ' left)';
              container.classList.add('loading-more');

              container.appendChild(loadingElement);
              container.appendChild(message);

              return container;
            }
          },
          params: {
            per_page: 10,
            page: 1,
            skip_groups: document.querySelector('#groups-droplab').dataset.skip_groups,
          },
        },
      });
    }
  }

  global.GroupsDroplab = GroupsDroplab;
})();
