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

    // Compiles CoffeeScript to JavaScript
    coffee: {
      options: {
        sourceMap: false,
        sourceRoot: ''
      },
      dist: {
        files: [{
          expand: true,
          cwd: 'app/js',
          src: '*.coffee',
          dest: 'app/js',
          ext: '.js'
        }]
      },
    },

    // concat, uglify and minify javascript
    uglify: {
      dist: {
        files: {
          'graphene.min.js': [
            'vendor/js/underscore.js',
            'vendor/js/backbone.js',
            'vendor/js/d3.js',
            'app/js/d3.gauge.js',
            'app/js/graphene.events.js',
            'app/js/graphene.js'
          ]
        }
      }
    },

  });

  grunt.registerTask('default', [
    'coffee',
    'uglify',
  ]);
};
