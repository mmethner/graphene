'use strict';

// # Globbing
// for performance reasons we're only matching one level down:
// 'test/spec/{,*/}*.js'
// use this if you want to recursively match all subfolders:
// 'test/spec/**/*.js'

module.exports = function (grunt) {

  // Load grunt tasks automatically
  require('load-grunt-tasks')(grunt);

  // Time how long tasks take. Can help when optimizing build times
  require('time-grunt')(grunt);

  // Define the configuration for all the tasks
  grunt.initConfig({

    // Empties folders to start fresh
    clean: {
      dist: {
        files: [{
          dot: true,
          src: [
            '.tmp',
          ]
        }]
      },
    },

    // Compiles CoffeeScript to JavaScript
    coffee: {
      options: {
        sourceMap: false,
        sourceRoot: '',
        bare: true
      },
      dist: {
        files: [{
          expand: true,
          cwd: 'js',
          src: '{,*/}*.coffee',
          dest: '.tmp',
          ext: '.js'
        }]
      },
    },

    // concat, uglify and minify javascript
    uglify: {
      dist: {
        files: {
          'graphene.min.js': [
            'vendor/underscore.js',
            'vendor/backbone.js',
            'vendor/d3.js',
            'js/d3.gauge.js',
            '.tmp/events/graphene.js',
            '.tmp/graphene.js',
            '.tmp/modals/graphene.js',
            '.tmp/views/graphene.js'
          ]
        }
      }
    },

    cssmin: {
      dist: {
        files: {
          'demo/css/graphene.min.css': [
            'demo/css/*.css'
          ]
        }
      }
    },

    // Compiles Sass to CSS and generates necessary files if requested
    compass: {
      options: {
        sassDir: 'demo/css',
        cssDir: 'demo/css',
      },
      dist: {
        options: {}
      },
    },

  });

  grunt.registerTask('default', [
    'clean',
    'coffee',
    'compass',
    'uglify',
    'cssmin'
  ]);
};
