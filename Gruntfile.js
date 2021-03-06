module.exports = function(grunt){
    
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        nodemon: {
            prod: {
                options: {
                  file: 'app.coffee', 
                  ignoredFiles: ['README.md', 'node_modules/**'],
                }
            },
        },
        jshint: {
            all: ['*.js']
        },
        sass: {
            dist: {
                files: {
                }
            }
        }
    });

    // load tasks
    grunt.loadNpmTasks('grunt-contrib-sass');
    grunt.loadNpmTasks('grunt-nodemon');
    grunt.loadNpmTasks('grunt-contrib-jshint');

    // running tasks
    grunt.registerTask('default', ['sass', 'jshint', 'nodemon']);

};
