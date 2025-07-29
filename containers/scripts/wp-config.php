<?php
/**
 * WordPress configuration file
 * All configuration is sourced from environment variables
 */

// Database configuration
define('DB_NAME', getenv('DB_NAME') ?: 'wordpress');
define('DB_USER', getenv('DB_USER') ?: 'wordpress');
define('DB_PASSWORD', getenv('DB_PASSWORD') ?: 'wordpress_password');
define('DB_HOST', getenv('DB_HOST') ?: 'mysql');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

// Database table prefix
$table_prefix = getenv('WP_TABLE_PREFIX') ?: 'wp_';

// Authentication unique keys and salts
define('AUTH_KEY',         getenv('WP_AUTH_KEY') ?: 'your-unique-phrase-here');
define('SECURE_AUTH_KEY',  getenv('WP_SECURE_AUTH_KEY') ?: 'your-unique-phrase-here');
define('LOGGED_IN_KEY',    getenv('WP_LOGGED_IN_KEY') ?: 'your-unique-phrase-here');
define('NONCE_KEY',        getenv('WP_NONCE_KEY') ?: 'your-unique-phrase-here');
define('AUTH_SALT',        getenv('WP_AUTH_SALT') ?: 'your-unique-phrase-here');
define('SECURE_AUTH_SALT', getenv('WP_SECURE_AUTH_SALT') ?: 'your-unique-phrase-here');
define('LOGGED_IN_SALT',   getenv('WP_LOGGED_IN_SALT') ?: 'your-unique-phrase-here');
define('NONCE_SALT',       getenv('WP_NONCE_SALT') ?: 'your-unique-phrase-here');

// WordPress settings
define('WP_DEBUG', getenv('WP_DEBUG') ?: 'false');
define('WP_DEBUG_LOG', getenv('WP_DEBUG_LOG') ?: 'false');
define('WP_DEBUG_DISPLAY', getenv('WP_DEBUG_DISPLAY') ?: 'false');

// Site configuration
define('WP_HOME', getenv('WP_HOME') ?: 'http://localhost:8080');
define('WP_SITEURL', getenv('WP_SITEURL') ?: 'http://localhost:8080');

// Security settings
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_FILE_MODS', true);
define('AUTOMATIC_UPDATER_DISABLED', true);
define('WP_AUTO_UPDATE_CORE', false);

// Performance settings
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');
define('WP_CACHE', true);

// Multisite (disabled by default)
// define('WP_ALLOW_MULTISITE', true);

// Absolute path to the WordPress directory
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

// Sets up WordPress vars and included files
require_once ABSPATH . 'wp-settings.php'; 