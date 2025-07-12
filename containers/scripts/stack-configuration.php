<?php
/**
 * Stack Configuration - WordPress mu-plugin
 * This plugin runs before WordPress loads and configures the stack
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    define('ABSPATH', dirname(__FILE__) . '/../../');
}

// Override get_option for active plugins to ensure our plugins are always considered active
add_filter('option_active_plugins', function($active_plugins) {
    $required_plugins = [
        'sqlite-database-integration/load.php',
        'simple-seo/simple-seo.php',
        'modern-footnotes/modern-footnotes.php',
        'two-factor/two-factor.php'
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

// Remove plugins menu from admin sidebar
add_action('admin_menu', function() {
    remove_menu_page('plugins.php');
}, 999);

// Remove plugin-related submenus
add_action('admin_init', function() {
    remove_submenu_page('plugins.php', 'plugin-install.php');
    remove_submenu_page('plugins.php', 'plugin-editor.php');
}); 

// Remove SQLite admin menu
remove_action( 'admin_menu', 'sqlite_add_admin_menu' );
remove_action( 'admin_bar_menu', 'sqlite_plugin_adminbar_item', 999 );

// Set Modern Footnotes custom shortcode to "ref" via settings
add_filter( 'option_modern_footnotes_settings', function($settings) {
    if (empty($settings['modern_footnotes_custom_shortcode'])) {
        $settings['modern_footnotes_custom_shortcode'] = 'ref';
    }
    return $settings;
});

// Configure Two-Factor plugin to remove email codes and dummy method
add_filter( 'two_factor_providers', function($providers) {
    // Remove email codes provider
    unset($providers['Two_Factor_Email']);
    
    // Remove dummy method provider (for testing)
    unset($providers['Two_Factor_Dummy']);
    
    return $providers;
});