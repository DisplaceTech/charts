<?php
/**
 * Auto-activate required plugins and theme
 * This mu-plugin runs before WordPress loads
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    define('ABSPATH', dirname(__FILE__) . '/');
}

// Hook into WordPress init to activate plugins and theme
add_action('init', function() {
    // Only run on first install or if plugins are not active
    if (!get_option('auto_plugins_activated')) {
        
        // Activate Redis Object Cache
        if (!is_plugin_active('redis-cache/redis-cache.php')) {
            activate_plugin('redis-cache/redis-cache.php');
        }
        
        // Activate Batcache
        if (!is_plugin_active('batcache/batcache.php')) {
            activate_plugin('batcache/batcache.php');
        }
        
        // Activate Simple SEO
        if (!is_plugin_active('simple-seo/simple-seo.php')) {
            activate_plugin('simple-seo/simple-seo.php');
        }
        
        // Switch to Powder theme
        $current_theme = get_option('stylesheet');
        if ($current_theme !== 'powder') {
            switch_theme('powder');
        }
        
        // Mark as activated
        update_option('auto_plugins_activated', true);
    }
});

// Override get_option for active plugins to ensure our plugins are always considered active
add_filter('option_active_plugins', function($active_plugins) {
    $required_plugins = [
        'redis-cache/redis-cache.php',
        'batcache/batcache.php',
        'simple-seo/simple-seo.php'
    ];
    
    foreach ($required_plugins as $plugin) {
        if (!in_array($plugin, $active_plugins)) {
            $active_plugins[] = $plugin;
        }
    }
    
    return $active_plugins;
});

// Override get_option for active theme
add_filter('option_stylesheet', function($stylesheet) {
    return 'powder';
});

add_filter('option_template', function($template) {
    return 'powder';
}); 