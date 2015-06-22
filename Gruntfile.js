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
				src: [ '*.mll' ]
			}
		},
		
		ocamlyacc: {
			build: {
				cwd: 'build',
				src: [ '*.mly' ]
			}
		},
		
		ocamlc_compile: {
			build: {
				cwd: 'build',
				src: [ 'ast.mli', 'parser.mli', 'scanner.ml', 'parser.ml', 'calc.ml' ]
			}
		},
		
		ocamlc_link: {
			build: {
				cwd: 'build',
				src: [ 'parser.cmo', 'scanner.cmo', 'calc.cmo' ],
				dest: 'compiler.exe'
			}
		},
		
		compile: {
			all: {
				cwd: 'test',
				src: [ '*' ]
			}
		},
		
		run: {
			all: {
				cwd: 'test',
				src: [ '*' ]
			}
		},
		
		file_compare: {
			hello_out: [ 'test/hello/expected.out', 'test/hello/result.out' ],
			hello_c: [ 'test/hello/expected.c', 'test/hello/compiled.c' ]
		}
	});
	
	grunt.registerMultiTask( 'compile', function( ){
		var done = this.async( );
		var success = true;
		
		var srcfiles = []
		
		this.files.forEach(function(file) {
			var files = file.src.filter(function (filepath) {
				// Remove nonexistent files (it's up to you to filter or warn here).
				if (!grunt.file.exists(file.cwd, filepath)) {
					grunt.log.warn('Source file "' + filepath + '" not found.');
					return false;
				} else {
					return true;
				}
			}).forEach( function( filepath ){
				srcfiles.push( path.join( file.cwd, filepath ) /*, currently building in place so no dest needed */ );
			});
		});
		
		var count = srcfiles.length;
		function completed(){
			if( ( count -= 1 ) == 0 ){
				done( success );
			}
		}
		
		console.log(srcfiles)
		
		srcfiles.forEach( function( file ){
			var command = 'compiler.exe < ' + path.join(file, 'src.prtzl') + ' > ' + path.join(file, 'compiled.c' ); 
			exec( command, function( err, stdout, stderr ){
				grunt.log.writeln( command );
				grunt.log.writeln( '\tstdout: ' + stdout.split( '\n' ).join( '\n\t\t' ) );
				grunt.log.writeln( '\tstderr: ' + stderr.split( '\n' ).join( '\n\t\t' ) );
				
				if( err !== null ){
					grunt.warn( command + ' exited with error code ' + err.code );
					success = false;
					return completed( );
				}
				
				var command = 'gcc -o ' + path.join( file, 'compiled.exe') + ' ' + path.join( file, 'compiled.c'); 
				exec( command, function( err, stdout, stderr ){
					grunt.log.writeln( command );
					grunt.log.writeln( '\tstdout: ' + stdout.split( '\n' ).join( '\n\t\t' ) );
					grunt.log.writeln( '\tstderr: ' + stderr.split( '\n' ).join( '\n\t\t' ) );
					
					if( err !== null ){
						grunt.warn( command + ' exited with error code ' + err.code );
						success = false;
					}
					
					completed();
				} );
			} );
		} );		
	} );
	
	grunt.registerMultiTask( 'run', function( ){
		var done = this.async( );
		var success = true;
		
		var srcfiles = []
		
		this.files.forEach(function(file) {
			var files = file.src.filter(function (filepath) {
				// Remove nonexistent files (it's up to you to filter or warn here).
				if (!grunt.file.exists(file.cwd, filepath)) {
					grunt.log.warn('Source file "' + filepath + '" not found.');
					return false;
				} else {
					return true;
				}
			}).forEach( function( filepath ){
				srcfiles.push( [ path.join( file.cwd, filepath ) /*, currently building in place so no dest needed */] );
			});
		});
		
		var count = srcfiles.length;
		function completed(){
			if( ( count -= 1 ) == 0 ){
				done( success );
			}
		}
		
		srcfiles.forEach( function( file ){
			var command = path.join( file, 'compiled.exe' ) + ' > ' + path.join( file, 'result.out' ); 
			exec( command, function( err, stdout, stderr ){
				grunt.log.writeln( command );
				grunt.log.writeln( '\tstdout: ' + stdout.split( '\n' ).join( '\n\t\t' ) );
				grunt.log.writeln( '\tstderr: ' + stderr.split( '\n' ).join( '\n\t\t' ) );
				
				if( err !== null ){
					grunt.warn( command + ' exited with error code ' + err.code );
					success = false;
				}
				
				completed();
			} );
		} );		
	} );
	
	grunt.registerMultiTask( 'ocamllex', 'Run Ocamllex.', function( ){
		var done = this.async( );
		var success = true;
		
		var srcfiles = []
		
		this.files.forEach(function(file) {
			var files = file.src.filter(function (filepath) {
				// Remove nonexistent files (it's up to you to filter or warn here).
				if (!grunt.file.exists(file.cwd, filepath)) {
					grunt.log.warn('Source file "' + filepath + '" not found.');
					return false;
				} else {
					return true;
				}
			}).forEach( function( filepath ){
				srcfiles.push( [ path.join( file.cwd, filepath ) /*, currently building in place so no dest needed */] );
			});
		});
		
		var count = srcfiles.length;
		function completed(){
			if( ( count -= 1 ) == 0 ){
				done( success );
			}
		}
		
		
		srcfiles.forEach( function( file ){
			var command = 'ocamllex ' + file; 
			exec( command, function( err, stdout, stderr ){
				grunt.log.writeln( command );
				grunt.log.writeln( '\tstdout: ' + stdout.split( '\n' ).join( '\n\t\t' ) );
				grunt.log.writeln( '\tstderr: ' + stderr.split( '\n' ).join( '\n\t\t' ) );
				
				if( err !== null ){
					grunt.warn( command + ' exited with error code ' + err.code );
					success = false;
				}
				
				completed();
			} );
		} );		
	} );
	
	grunt.registerMultiTask( 'ocamlyacc', 'Run Ocamlyacc.', function( ){
		var done = this.async( );
		var success = true;
		
		var srcfiles = []
		
		this.files.forEach(function(file) {
			var files = file.src.filter(function (filepath) {
				// Remove nonexistent files (it's up to you to filter or warn here).
				if (!grunt.file.exists(file.cwd, filepath)) {
					grunt.log.warn('Source file "' + filepath + '" not found.');
					return false;
				} else {
					return true;
				}
			}).forEach( function( filepath ){
				srcfiles.push( [ path.join( file.cwd, filepath ) /*, currently building in place so no dest needed */] );
			});
		});
		
		var count = srcfiles.length;
		function completed(){
			if( ( count -= 1 ) == 0 ){
				done( success );
			}
		}
		
		
		srcfiles.forEach( function( file ){
			var command = 'ocamlyacc ' + file; 
			exec( command, function( err, stdout, stderr ){
				grunt.log.writeln( command )
				grunt.log.writeln( '\tstdout: ' + stdout.split( '\n' ).join( '\n\t\t' ) );
				grunt.log.writeln( '\tstderr: ' + stderr.split( '\n' ).join( '\n\t\t' ) );
				
				if( err !== null ){
					grunt.warn( command + ' exited with error code ' + err.code );
					success = false;
				}
				
				completed();
			} );
		} );		
	} );
	
	grunt.registerMultiTask( 'ocamlc_compile', 'Run Ocamlc compilier.', function( ){
		var done = this.async( );
		var success = true;
		
		var srcfiles = []
		
		this.files.forEach(function(file) {
			var files = file.src.filter(function (filepath) {
				// Remove nonexistent files (it's up to you to filter or warn here).
				if (!grunt.file.exists(file.cwd, filepath)) {
					grunt.log.warn('Source file "' + filepath + '" not found.');
					return false;
				} else {
					return true;
				}
			}).forEach( function( filepath ){
				srcfiles.push( [ file.cwd, filepath /*, currently building in place so no dest needed */] );
			});
		});
		
		var count = srcfiles.length;
		function completed(){
			if( ( count -= 1 ) == 0 ){
				done( success );
			}
		}
		
		
		srcfiles.forEach( function( file ){
			var command = 'ocamlc -c ' + file[1]; 
			exec( command, { cwd: file[0] }, function( err, stdout, stderr ){
				grunt.log.writeln( command )
				grunt.log.writeln( '\tstdout: ' + stdout.split( '\n' ).join( '\n\t\t' ) );
				grunt.log.writeln( '\tstderr: ' + stderr.split( '\n' ).join( '\n\t\t' ) );
				
				if( err !== null ){
					grunt.warn( command + ' exited with error code ' + err.code );
					success = false;
				}
				
				completed();
			} );
		} );		
	} );
	
	grunt.registerMultiTask( 'ocamlc_link', 'Run Ocamlc linker.', function( ){
		var done = this.async( );
		var success = true;
		
		var srcfiles = []
		
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
			
			srcfiles.push( [files, file.dest] );
		});
		
		var count = srcfiles.length;
		function completed(){
			if( ( count -= 1 ) == 0 ){
				done( success );
			}
		}
		
		
		srcfiles.forEach( function( file ){
			var command = 'ocamlc -o ' + file[1] + ' ' + file[0].join(' '); 
			exec( command, function( err, stdout, stderr ){
				grunt.log.writeln( command )
				grunt.log.writeln( '\tstdout: ' + stdout.split( '\n' ).join( '\n\t\t' ) );
				grunt.log.writeln( '\tstderr: ' + stderr.split( '\n' ).join( '\n\t\t' ) );
				
				if( err !== null ){
					grunt.warn( command + ' exited with error code ' + err.code );
					success = false;
				}
				
				completed();
			} );
		} );		
	} );
	
	grunt.registerTask( 'env', 'Print Build Environment.', function( ){
		var done = this.async( );
		var count = 5;
		
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
		exec( 'ocamlyacc -vnum', function( err, stdout, stderr ){
			grunt.log.write( '\tocamlyacc: ' + stdout );
			completed();
		} );
	} );

	grunt.loadNpmTasks( 'grunt-file-compare' );
	grunt.loadNpmTasks( 'grunt-contrib-copy' );
	grunt.loadNpmTasks( 'grunt-contrib-clean' );

	grunt.registerTask( 'build', [
		'copy:build',
		'ocamllex:build',
		'ocamlyacc:build',
		'ocamlc_compile:build',
		'ocamlc_link:build'
	] );
	
	grunt.registerTask( 'test', [
		'compile:all',
		'run:all',
		'file_compare'
	] );

	grunt.registerTask( 'default', [
		'env',
		'build',
		'test'
	] );
}
