
#this test suite needs ruby to run
# \curl -sSL https://get.rvm.io | bash

task :compile do

	puts 'Compiling Ocaml source'

	Dir.chdir 'src'
	`make`
	`cp compile ../test/compile`
	Dir.chdir '..'

	puts
end	

task :test do

	puts 'Running tests'
	puts 
	
	#fresh copy over c libraries
	`cp src/clibs/* test/`

	Dir.chdir 'test'

	Dir.glob('*.prtzl').each do |file|

		name = file.chomp '.prtzl'	

		puts name

		print "	Compiling .prtzl"
		if system "./compile < #{name}.prtzl > #{name}_test.c"	
			puts '	OK'
		else
			puts '	FAILED'
		end

		print "	Compiling .c"
		if system "gcc -o #{name}.o #{name}_test.c prtzl.c map.c list.c"
			puts '		OK'
		else
			puts '		FAILED'
		end

		print "	Running .o"
		if system "./#{name}.o > #{name}_test.out"
			puts '		OK'
		else
			puts '		FAILED'
		end

		system "diff #{name}.out #{name}_test.out"
	end

	Dir.chdir '..'

	puts

end


task :clean do
	Dir.chdir 'src'
	`make clean`
	Dir.chdir '..'
	`rm test/compile test/*.o test/*_test.out test/*_test.c`
end

task :all => [:compile, :test, :clean] do

end