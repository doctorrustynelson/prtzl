var spawn = require( 'child_process' ).spawn;
var exec = require( 'child_process' ).exec;

module.exports = function (grunt) {

    require( 'time-grunt' )( grunt );
 
    grunt.initConfig({
		// TODO: configure
	});
	
	// TODO: add build tasks
	
	// TODO: add test tasks
	
	grunt.registerTask( 'env', 'Print build environment.', function( ){
		console.log( 'Environment:' );
		exec( 'node --version', function( err, stdout, stderr ){
			console.log( 'node: ' + stdout );
		} );
		exec( 'npm --version', function( err, stdout, stderr ){
			console.log( 'npm: ' + stdout );
		} );
		exec( 'ocaml -vnum', function( err, stdout, stderr ){
			console.log( 'ocaml: ' + stdout );
		} );
	} );

	grunt.registerTask( 'default', [
		'env'
	] );
}