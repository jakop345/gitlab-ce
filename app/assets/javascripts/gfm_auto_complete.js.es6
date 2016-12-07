/* eslint-disable */
// Creates the variables for setting up GFM auto-completion
(function() {
  if (window.gl == null) {
    window.gl = {};
  }

  function sanitize(str) {
    return str.replace(/<(?:.|\n)*?>/gm, '');
  }

  gl.GfmAutoComplete = {
    dataSources: {},
    defaultLoadingData: ['loading'],
    cachedData: {},
    isLoadingData: {},
    isSetup: false,
    atTypeMap: {
      ':': 'emojis',
      '@': 'members',
      '#': 'issues',
      '!': 'mergeRequests',
      '~': 'labels',
      '%': 'milestones',
      '/': 'commands'
    },
    // Emoji
    Emoji: {
      template: '<li>${name} <img alt="${name}" height="20" src="${path}" width="20" /></li>'
    },
    // Team Members
    Members: {
      template: '<li>${avatarTag} ${username} <small>${title}</small></li>'
    },
    Labels: {
      template: '<li><span class="dropdown-label-box" style="background: ${color}"></span> ${title}</li>'
    },
    // Issues and MergeRequests
    Issues: {
      template: '<li><small>${id}</small> ${title}</li>'
    },
    // Milestones
    Milestones: {
      template: '<li>${title}</li>'
    },
    Loading: {
      template: '<li style="pointer-events: none;"><i class="fa fa-refresh fa-spin"></i> Loading...</li>'
    },
    DefaultOptions: {
      sorter: function(query, items, searchKey) {
        if (gl.GfmAutoComplete.isLoading(items)) {
          return items;
        }
        return $.fn.atwho["default"].callbacks.sorter(query, items, searchKey);
      },
      filter: function(query, data, searchKey) {
        if (gl.GfmAutoComplete.isLoading(data)) {
          gl.GfmAutoComplete.togglePreventSelection.call(this, true);
          gl.GfmAutoComplete.fetchData(this.$inputor, this.at);
          return data;
        } else {
          gl.GfmAutoComplete.togglePreventSelection.call(this, false);
          return $.fn.atwho["default"].callbacks.filter(query, data, searchKey);
        }
      },
      beforeInsert: function(value) {
        return value;
      },
      matcher: function (flag, subtext) {
        // The below is taken from At.js source
        // Tweaked to commands to start without a space only if char before is a non-word character
        // https://github.com/ichord/At.js
        var _a, _y, regexp, match;
        subtext = subtext.split(' ').pop();
        flag = flag.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");

        _a = decodeURI("%C3%80");
        _y = decodeURI("%C3%BF");

        regexp = new RegExp("(?:\\B|\\W|\\s)" + flag + "(?!\\W)([A-Za-z" + _a + "-" + _y + "0-9_\'\.\+\-]*)|([^\\x00-\\xff]*)$", 'gi');

        match = regexp.exec(subtext);

        if (match) {
          return match[2] || match[1];
        } else {
          return null;
        }
      }
    },
    setup: function(input) {
      // Add GFM auto-completion to all input fields, that accept GFM input.
      this.input = input || $('.js-gfm-input');
      this.setupLifecycle();
    },
    setupLifecycle() {
      this.input.each((i, input) => {
        const $input = $(input);
        $input.off('focus.setupAtWho').on('focus.setupAtWho', this.setupAtWho.bind(this, $input));
      });
    },
    setupAtWho: function($input) {
      if (this.isSetup) return;
      this.isSetup = true;
      // Emoji
      $input.atwho({
        at: ':',
        displayTpl: function(value) {
          return value.path != null ? this.Emoji.template : this.Loading.template;
        }.bind(this),
        insertTpl: ':${name}:',
        startWithSpace: false,
        data: this.defaultLoadingData,
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          filter: this.DefaultOptions.filter
        }
      });
      // Team Members
      $input.atwho({
        at: '@',
        displayTpl: function(value) {
          return value.username != null ? this.Members.template : this.Loading.template;
        }.bind(this),
        insertTpl: '${atwho-at}${username}',
        searchKey: 'search',
        startWithSpace: false,
        alwaysHighlightFirst: true,
        data: this.defaultLoadingData,
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          matcher: this.DefaultOptions.matcher,
          beforeSave: function(members) {
            return $.map(members, function(m) {
              let title = '';
              if (m.username == null) {
                return m;
              }
              title = m.name;
              if (m.count) {
                title += " (" + m.count + ")";
              }

              const autoCompleteAvatar = m.avatar_url || m.username.charAt(0).toUpperCase();
              const imgAvatar = `<img src="${m.avatar_url}" alt="${m.username}" class="avatar avatar-inline center s26"/>`;
              const txtAvatar = `<div class="avatar center avatar-inline s26">${autoCompleteAvatar}</div>`;

              return {
                username: m.username,
                avatarTag: autoCompleteAvatar.length === 1 ?  txtAvatar : imgAvatar,
                title: sanitize(title),
                search: sanitize(m.username + " " + m.name)
              };
            });
          }
        }
      });
      $input.atwho({
        at: '#',
        alias: 'issues',
        searchKey: 'search',
        displayTpl: function(value) {
          return value.title != null ? this.Issues.template : this.Loading.template;
        }.bind(this),
        data: this.defaultLoadingData,
        insertTpl: '${atwho-at}${id}',
        startWithSpace: false,
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          matcher: this.DefaultOptions.matcher,
          beforeSave: function(issues) {
            return $.map(issues, function(i) {
              if (i.title == null) {
                return i;
              }
              return {
                id: i.iid,
                title: sanitize(i.title),
                search: i.iid + " " + i.title
              };
            });
          }
        }
      });
      $input.atwho({
        at: '%',
        alias: 'milestones',
        searchKey: 'search',
        displayTpl: function(value) {
          return value.title != null ? this.Milestones.template : this.Loading.template;
        }.bind(this),
        insertTpl: '${atwho-at}"${title}"',
        startWithSpace: false,
        data: this.defaultLoadingData,
        callbacks: {
          matcher: this.DefaultOptions.matcher,
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeSave: function(milestones) {
            return $.map(milestones, function(m) {
              if (m.title == null) {
                return m;
              }
              return {
                id: m.iid,
                title: sanitize(m.title),
                search: "" + m.title
              };
            });
          }
        }
      });
      $input.atwho({
        at: '!',
        alias: 'mergerequests',
        searchKey: 'search',
        startWithSpace: false,
        displayTpl: function(value) {
          return value.title != null ? this.Issues.template : this.Loading.template;
        }.bind(this),
        data: this.defaultLoadingData,
        insertTpl: '${atwho-at}${id}',
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          matcher: this.DefaultOptions.matcher,
          beforeSave: function(merges) {
            return $.map(merges, function(m) {
              if (m.title == null) {
                return m;
              }
              return {
                id: m.iid,
                title: sanitize(m.title),
                search: m.iid + " " + m.title
              };
            });
          }
        }
      });
      $input.atwho({
        at: '~',
        alias: 'labels',
        searchKey: 'search',
        data: this.defaultLoadingData,
        displayTpl: function(value) {
          return this.isLoading(value) ? this.Loading.template : this.Labels.template;
        }.bind(this),
        insertTpl: '${atwho-at}${title}',
        startWithSpace: false,
        callbacks: {
          matcher: this.DefaultOptions.matcher,
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeSave: function(merges) {
            if (gl.GfmAutoComplete.isLoading(merges)) return merges;
            var sanitizeLabelTitle;
            sanitizeLabelTitle = function(title) {
              if (/[\w\?&]+\s+[\w\?&]+/g.test(title)) {
                return "\"" + (sanitize(title)) + "\"";
              } else {
                return sanitize(title);
              }
            };
            return $.map(merges, function(m) {
              return {
                title: sanitizeLabelTitle(m.title),
                color: m.color,
                search: "" + m.title
              };
            });
          }
        }
      });
      // We don't instantiate the slash commands autocomplete for note and issue/MR edit forms
      $input.filter('[data-supports-slash-commands="true"]').atwho({
        at: '/',
        alias: 'commands',
        searchKey: 'search',
        data: this.defaultLoadingData,
        displayTpl: function(value) {
          if (this.isLoading(value)) return this.Loading.template;
          var tpl = '<li>/${name}';
          if (value.aliases.length > 0) {
            tpl += ' <small>(or /<%- aliases.join(", /") %>)</small>';
          }
          if (value.params.length > 0) {
            tpl += ' <small><%- params.join(" ") %></small>';
          }
          if (value.description !== '') {
            tpl += '<small class="description"><i><%- description %></i></small>';
          }
          tpl += '</li>';
          return _.template(tpl)(value);
        }.bind(this),
        insertTpl: function(value) {
          var tpl = "/${name} ";
          var reference_prefix = null;
          if (value.params.length > 0) {
            reference_prefix = value.params[0][0];
            if (/^[@%~]/.test(reference_prefix)) {
              tpl += '<%- reference_prefix %>';
            }
          }
          return _.template(tpl)({ reference_prefix: reference_prefix });
        },
        suffix: '',
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          beforeSave: function(commands) {
            if (gl.GfmAutoComplete.isLoading(commands)) return commands;
            return $.map(commands, function(c) {
              var search = c.name;
              if (c.aliases.length > 0) {
                search = search + " " + c.aliases.join(" ");
              }
              return {
                name: c.name,
                aliases: c.aliases,
                params: c.params,
                description: c.description,
                search: search
              };
            });
          },
          matcher: function(flag, subtext, should_startWithSpace, acceptSpaceBar) {
            var regexp = /(?:^|\n)\/([A-Za-z_]*)$/gi
            var match = regexp.exec(subtext);
            if (match) {
              return match[1];
            } else {
              return null;
            }
          }
        }
      });
      return;
    },
    fetchData: function($input, at) {
      if (this.isLoadingData[at]) return;
      this.isLoadingData[at] = true;
      if (this.cachedData[at]) {
        this.loadData($input, at, this.cachedData[at]);
      } else {
        $.getJSON(this.dataSources[this.atTypeMap[at]], (data) => {
          this.loadData($input, at, data);
        });
      }
    },
    loadData: function($input, at, data) {
      this.isLoadingData[at] = false;
      this.cachedData[at] = data;
      $input.atwho('load', at, data);
      // This trigger at.js again
      // otherwise we would be stuck with loading until the user types
      return $input.trigger('keyup');
    },
    isLoading(data) {
      if (Array.isArray(data)) data = data[0];
      if (!data) return false
      return data === this.defaultLoadingData[0] || data.name === this.defaultLoadingData[0];
    },
    togglePreventSelection(isPrevented = !!this.setting.tabSelectsMatch) {
      this.setting.tabSelectsMatch = !isPrevented;
      this.setting.spaceSelectsMatch = !isPrevented;
      const eventListenerAction = `${isPrevented ? 'add' : 'remove'}EventListener`;
      this.$inputor[0][eventListenerAction]('keydown', gl.GfmAutoComplete.preventSpaceTabEnter);
    },
    preventSpaceTabEnter(e) {
      const key = e.which || e.keyCode;
      const preventables = [9, 13, 32];
      if (preventables.indexOf(key) > -1) e.preventDefault();
    }
  };

}).call(this);
