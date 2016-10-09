/*= require raven-vue */
/*= require raven */

(() => {

  const RavenConfig = {
    init() {
      if (!gon.sentry_dsn) return;
      this.configure();
      this.bindAjaxErrors();
      if (gon.current_user_id) this.setUser();
    },
    configure() {
      Raven.config(gon.sentry_dsn, {
        whitelistUrls: [gon.gitlab_url],
        environment: gon.is_production ? 'production' : 'development'
      }).install();
    },
    setUser() {
      Raven.setUserContext({
        id: gon.current_user_id
      });
    },
    bindAjaxErrors() {
      $(document).off('ajaxError.raven')
        .on('ajaxError.raven', (event, req, config, err) => {
          err = err || req.statusText;
          Raven.captureMessage(err, {
            extra: {
              type: config.type,
              url: config.url,
              data: config.data,
              status: req.status,
              error: err,
              response: req.responseText.substring(0, 100)
            }
          });
      });
    }
  };

  document.addEventListener('page:change', RavenConfig.init.bind(RavenConfig));

})();
