var spawn = require( 'child_process' ).spawn;
var exec = require( 'child_process' ).exec;
var path = require( 'path' );

module.exports = function (grunt) {

    require( 'time-grunt' )( grunt );
 
    grunt.initConfig({
		clean: {
			build: {
				src: 'build'
			}
		},
		
		copy: {
			build: {
				expand: true,
				cwd: 'src',
				src: [ '*' ],
				dest: 'build'
			}
		},
		
		ocamllex: {
			build: {
				cwd: 'build',
				src: [ '*.mll' ],
				dest: 'build'
			}
		}
	});
	
	grunt.registerMultiTask( 'ocamllex', 'Run Ocamllex.', function( ){
		var done = this.async( );
		
		this.files.forEach(function(file) {
			var files = file.src.filter(function (filepath) {
				// Remove nonexistent files (it's up to you to filter or warn here).
				if (!grunt.file.exists(file.cwd, filepath)) {
					grunt.log.warn('Source file "' + filepath + '" not found.');
					return false;
				} else {
					return true;
				}
			}).map( function( filepath ){
				return path.join( file.cwd, filepath );
			});
			console.log(files);
			console.log(file.dest);
			
			// TODO: Compile
			
		});
		
		done();
	} );
	
	// TODO: add test tasks
	
	grunt.registerTask( 'env', 'Print Build Environment.', function( ){
		var done = this.async( );
		var count = 4;
		
		function completed(){
			if( ( count -= 1 ) == 0 ){
				grunt.log.writeln();
				done( true );
			}
		}
		
		grunt.log.writeln( 'Environment:' );
		
		exec( 'node --version', function( err, stdout, stderr ){
			grunt.log.write( '\tnode: ' + stdout );
			completed();
		} );
		exec( 'npm --version', function( err, stdout, stderr ){
			grunt.log.write( '\tnpm: ' + stdout );
			completed();
		} );
		exec( 'ocaml -vnum', function( err, stdout, stderr ){
			grunt.log.write( '\tocaml: ' + stdout );
			completed();
		} );
		exec( 'ocamllex -vnum', function( err, stdout, stderr ){
			grunt.log.write( '\tocamllex: ' + stdout );
			completed();
		} );
	} );

	grunt.loadNpmTasks( 'grunt-contrib-copy' );
	grunt.loadNpmTasks('grunt-contrib-clean');

	grunt.registerTask( 'build', [
		'copy:build',
		'ocamllex:build'
	] );

	grunt.registerTask( 'default', [
		'env',
		'build'
	] );
}