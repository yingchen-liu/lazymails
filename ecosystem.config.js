module.exports = {
  /**
   * Application configuration section
   * http://pm2.keymetrics.io/docs/usage/application-declaration/
   */
  apps : [
    {
      name      : 'Lazy Mails',
      script    : 'server/bin/www',
      env: {
        COMMON_VARIABLE: 'true'
      },
      env_production : {
        NODE_ENV: 'production'
      }
    }
  ],

  /**
   * Deployment section
   * http://pm2.keymetrics.io/docs/usage/deployment/
   */
  deploy : {
    production : {
      user : 'root',
      host : 'lazymails.com',
      ref  : 'origin/master',
      repo : 'git@github.com:ytxiuxiu/fit5140-lazy-mail.git',
      path : '/lazymails',
      'post-deploy' : 'npm install --prefix server && pm2 reload ecosystem.config.js --env production'
    }
  }
};
