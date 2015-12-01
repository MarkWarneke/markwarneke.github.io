# markwarneke.me

Dies ist das öffentliche Repository für die Webseite markwarneke.me eine privaten Webseite von Mark Warneke

## Todo's

* Intro
* Privates Bild
* Navigation
* Kontakt
  * Social
* Impressum

## Commands

### Default task(s).
 grunt.registerTask('default', ['uglify', 'sass']);
 
### imagemin task(s)
  grunt.registerTask('image', ['imagemin']);
  grunt.registerTask('imagepng', ['imagemin:png']); // only .png files
  grunt.registerTask('imagejpg', ['imagemin:jpg']);// only .jpg files

## scss
  grunt.registerTask('css', ['sass']);
