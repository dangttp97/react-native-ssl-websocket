const path = require('path');
const { getDefaultConfig } = require('@react-native/metro-config');

const root = path.resolve(__dirname, '..');

/**
 * Metro configuration
 * https://facebook.github.io/metro/docs/configuration
 *
 * @type {import('metro-config').MetroConfig}
 */
module.exports = (() => {
  const config = getDefaultConfig(__dirname);

  // Add the root directory to the watch folders
  config.watchFolders = [root];

  // Add the root directory to the resolver
  config.resolver.nodeModulesPaths = [
    path.resolve(__dirname, 'node_modules'),
    path.resolve(root, 'node_modules'),
  ];

  // Add the library source to the resolver
  config.resolver.alias = {
    'react-native-ssl-websocket': path.resolve(root, 'src'),
  };

  return config;
})();
