var spawn = require( 'child_process' ).spawn;
var exec = require( 'child_process' ).exec;
var path = require( 'path' );

module.exports = function (grunt) {

    require( 'time-grunt' )( grunt );
 
    grunt.initConfig({
		clean: {
			build: {
				src: 'build'
			},
			test: {
				expand: true,
				cwd: 'test',
				src: [ '*/compiled.c', '*/compiled.exe', '*/result.out' ]
			},
			dist: {
				src: 'compiler.exe'
			}
		},
		
		copy: {
			build: {
				expand: true,
				cwd: 'src',
				src: [ '**/*' ],
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
			ast: {
				cwd: 'build',
				src: [ 'ast.ml' ]
			},
			ccode: {
				cwd: 'build',
				src: [ 'ccode.ml' ]
			},
			translate: {
				cwd: 'build',
				src: [ 'translate.ml' ]
			},
			compile: {
				cwd: 'build',
				src: [ 'compile.ml' ]
			},
			parser_mli: {
				cwd: 'build',
				src: [ 'parser.mli' ]
			},
			parser_ml: {
				cwd: 'build',
				src: [ 'parser.ml' ]
			},
			scanner: {
				cwd: 'build',
				src: [ 'scanner.ml' ]
			}
		},
		
		ocamlc_link: {
			build: {
				cwd: 'build',
				src: [ 'ast.cmo', 'parser.cmo', 'scanner.cmo', 'ccode.cmo', 'translate.cmo', 'compile.cmo' ],
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
		
		diff: {
			options: {
				force: true
			},
			hello_out: [ 'test/hello/expected.out', 'test/hello/result.out' ],
			hello_c: [ 'test/hello/expected.c', 'test/hello/compiled.c' ],
			empty_c: [ 'test/empty/expected.c', 'test/empty/compiled.c' ]
		}
	});
	
	grunt.registerMultiTask( 'diff', function( ){
		var done = this.async( );
		var srcfiles = this.filesSrc;
		var success = true;
		
		var src = srcfiles.shift();
		var expected = grunt.file.read( src ).replace( /\s+/g, ' ' ).trim();
		
		srcfiles.forEach( function( f ){
			var actual = grunt.file.read( f ).replace( /\s+/g, ' ' ).trim();
			if( expected != actual ){
				grunt.log.writeln("Error: " + f + " did not match " + src + ".");
				grunt.log.writeln("Expected: \n\t" + grunt.file.read( src ).split("\n").join("\n\t"));
				grunt.log.writeln("Actual: \n\t" + grunt.file.read( f ).split("\n").join("\n\t"));
				success = false;
			}
		})
		
		done(success)
	} );
	
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
		
		var c_libs = [ 'list.c', 'map.c', 'prtzl.c' ].map( function( f ){
			return path.join( 'build', 'clibs', f );
		}).join( ' ' );
		
		srcfiles.forEach( function( file ){
			var command = '.' + path.sep + 'compiler.exe' + ' < ' + path.join(file, 'src.prtzl') + ' > ' + path.join(file, 'compiled.c' ); 
			exec( command, function( err, stdout, stderr ){
				grunt.log.writeln( command );
				grunt.log.writeln( '\tstdout: ' + stdout.split( '\n' ).join( '\n\t\t' ) );
				grunt.log.writeln( '\tstderr: ' + stderr.split( '\n' ).join( '\n\t\t' ) );
				
				if( err !== null ){
					grunt.warn( command + ' exited with error code ' + err.code );
					success = false;
					return completed( );
				}
				
				var gcc_command = 'gcc -o ' + path.join( file, 'compiled.exe') + ' -I ' + path.join( 'build', 'clibs' ) + ' ' + path.join( file, 'compiled.c') + ' ' + c_libs; 
				exec( gcc_command, function( err, stdout, stderr ){
					grunt.log.writeln( gcc_command );
					grunt.log.writeln( '\tstdout: ' + stdout.split( '\n' ).join( '\n\t\t' ) );
					grunt.log.writeln( '\tstderr: ' + stderr.split( '\n' ).join( '\n\t\t' ) );
					
					if( err !== null ){
						grunt.log.writeln( 'Error: ' + gcc_command + ' exited with error code ' + err.code );
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
				srcfiles.push( path.join( file.cwd, filepath ) /*, currently building in place so no dest needed */ );
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
					grunt.log.writeln( 'Error: ' + command + ' exited with error code ' + err.code );
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
		/*exec( 'ls -la', function( err, stdout, stderr ){
			grunt.log.writeln( 'ls: \n' + stdout );
			completed();
		} );*/
	} );

	grunt.loadNpmTasks( 'grunt-contrib-copy' );
	grunt.loadNpmTasks( 'grunt-contrib-clean' );

	grunt.registerTask( 'build', [
		'copy:build',
		'ocamllex:build',
		'ocamlyacc:build',
		'ocamlc_compile:ast', 
		'ocamlc_compile:ccode', 
		'ocamlc_compile:translate', 
		'ocamlc_compile:parser_mli',
		'ocamlc_compile:parser_ml',
		'ocamlc_compile:scanner',
		'ocamlc_compile:compile', 
		'ocamlc_link:build'
	] );
	
	grunt.registerTask( 'test', [
		'compile:all',
		'run:all',
		'diff'
	] );

	grunt.registerTask( 'default', [
		'env',
		'clean',
		'build',
		'env',
		'test'
	] );
}
