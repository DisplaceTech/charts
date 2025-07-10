<?php
/**
 * WordPress Installation Script
 * Handles WordPress installation without WP-CLI
 */

// Load WordPress
require_once('/var/www/html/wp-load.php');

// Check if WordPress is already installed
if (get_option('siteurl')) {
    echo "WordPress is already installed.\n";
    exit(0);
}

// Get environment variables
$wp_url = getenv('WP_URL') ?: 'http://localhost';
$wp_title = getenv('WP_TITLE') ?: 'WordPress Site';
$wp_admin_user = getenv('WP_ADMIN_USER') ?: 'admin';
$wp_admin_password = getenv('WP_ADMIN_PASSWORD');
$wp_admin_email = getenv('WP_ADMIN_EMAIL');

if (!$wp_admin_password || !$wp_admin_email) {
    echo "WP_ADMIN_PASSWORD and WP_ADMIN_EMAIL environment variables are required.\n";
    exit(1);
}

// Update site URL
update_option('siteurl', $wp_url);
update_option('home', $wp_url);

// Update site title
update_option('blogname', $wp_title);

// Create admin user
$user_id = wp_create_user($wp_admin_user, $wp_admin_password, $wp_admin_email);

if (is_wp_error($user_id)) {
    echo "Error creating admin user: " . $user_id->get_error_message() . "\n";
    exit(1);
}

// Set user role to administrator
$user = new WP_User($user_id);
$user->set_role('administrator');

echo "WordPress installed successfully!\n";
echo "Admin user: $wp_admin_user\n";
echo "Admin email: $wp_admin_email\n";
echo "Site URL: $wp_url\n";
echo "Site title: $wp_title\n";

exit(0);
?> 