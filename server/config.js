/**
 * Application configuration
 */

const config = {
  production: {
    apis: {
      google: {
        apiKey: 'AIzaSyAKM6Yq4LxDIjZZ2PNaLyMZNyRgsEE-yb8'
      }
    },
    db: {
      url: 'mongodb://localhost:27017/lazymails'
    },
    socket: {
      host: '0.0.0.0',
      port: 6969
    }
  },
  development: {
    apis: {
      google: {
        apiKey: 'AIzaSyAKM6Yq4LxDIjZZ2PNaLyMZNyRgsEE-yb8'
      }
    },
    db: {
      url: 'mongodb://localhost:27017/lazymails'
    },
    socket: {
      host: '0.0.0.0',
      port: 6969
    }
  }
};

module.exports = process.env.NODE_ENV ? config[process.env.NODE_ENV] : config.development;