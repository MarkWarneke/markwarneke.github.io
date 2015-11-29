module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({

    pkg: grunt.file.readJSON('package.json'),

    // uglify
    uglify: {
      options: {
        banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
      },
      build: {
        src: 'src/js/js.js',
        dest: 'build/js/<%= pkg.name %>.min.js'
      }
    },

    // imagemin
    imagemin: {
      png: {
        options: {
          optimizationLevel: 7
        },
        files: [
          {
            // Set to true to enable the following options…
            expand: true,
            // cwd is 'current working directory'
            cwd: 'src/img/',
            src: ['**/*.png'],
            // Could also match cwd line above. i.e. project-directory/img/
            dest: 'build/img/compressed/',
            ext: '.png'
          }
        ]
      },
      jpg: {
        options: {
          progressive: true
        },
        files: [
          {
            // Set to true to enable the following options…
            expand: true,
            // cwd is 'current working directory'
            cwd: 'src/img/',
            src: ['**/*.jpg'],
            // Could also match cwd. i.e. project-directory/img/
            dest: 'build/img/compressed/',
            ext: '.jpg'
          }
        ]
      }
    },

    bootlint: {
    options: {
      relaxerror: [],
      showallerrors: false,
      stoponerror: false,
      stoponwarning: false
    },
    files: ['/index.html', '*.html']
  },


  copy: {
    css: {
      expand: true,
      cwd: 'src/css/',
      src: '*.css',
      dest: 'build/css/',
      filter: 'isFile'
    }
  }


  });

  // Load the plugin that provides the "uglify" task.
  grunt.loadNpmTasks('grunt-contrib-uglify');
  // Load the plugin that provides the "imagemin" task.
  //http://blog.grayghostvisuals.com/grunt/image-optimization/
  grunt.loadNpmTasks('grunt-contrib-imagemin');

  grunt.loadNpmTasks('grunt-bootlint');

  grunt.loadNpmTasks('grunt-contrib-copy');


  // Default task(s).
  grunt.registerTask('default', ['uglify', 'copy:css']);
  // imagemin task(s)
  grunt.registerTask('image', ['imagemin']);
  grunt.registerTask('imagepng', ['imagemin:png']); // only .png files
  grunt.registerTask('imagejpg', ['imagemin:jpg']);// only .jpg files

  // Default task(s).
  grunt.registerTask('validateBootstrap', ['bootlint']);
};
