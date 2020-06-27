#!/usr/bin/ruby -w
# Frozen_String_Literal: true
%w(io/console webrick).each(&method(:require))
OUTPUT_FILE = File.join(__dir__, 'index.html')

COLOUR_SUCCESS = "\e[1;38;2;0;165;45m"
COLOUR_INFO = "\e[1;38;2;255;255;0m"
COLOUR_ERROR = "\e[1;38;2;215;80;90m"
COLOUR_WARNING = "\e[1;38;2;255;180;0m"
COLOUR_PRIMARY = "\e[1;38;2;0;125;255m"

def get_files(dir = __dir__)
	Dir["#{dir}/**/*.html"].reject { |x| File.dirname(x) == dir && File.split(x)[-1] == 'index.html' }
end

def init
	unless File.exist?(OUTPUT_FILE)
		f = File.basename(Process.argv0)

		emojis = %W(
			\xF0\x9F\x90\xB9 \xF0\x9F\x90\xAD \xF0\x9F\x90\xB1
			\xF0\x9F\x90\xA3 \xF0\x9F\x90\xB5 \xF0\x9F\x90\xBC
		).map! { |x| p "&#x#{x.dump[3..-2].delete('{}')};" }.shuffle!

		IO.write(
			OUTPUT_FILE,
			<<~EOF.delete(?\n)
				<!Doctype HTML><html><head><meta charset="utf-8"><title>Welcome to #{f}</title><style>
				::selection {background-color: #0a0;color: #fff}
				body {height: 100vh;display: flex;justify-content: center;align-items: center;
				flex-direction: column}
				h2, .text {background: linear-gradient(45deg, #ff0, #f55, #f5f, #55f);-webkit-background-clip: text;
				color: transparent} .btn {transition: all 0.25s ease;
				position: relative;text-decoration: none;font-size: 20px;color: #912BFF;
				padding: 10px 20px;border: 3px solid #912BFF;border-radius: 4px;cursor: pointer;
				overflow: hidden;background-color: transparent}
				.btn::before {z-index: 1;content: attr(data-content);color: #fff;display: flex;
				align-items: center;justify-content: center;position: absolute;top: 0;
				left: 0;width: 100%;height: 100%;
				background-color: #912BFF;transition: all 0.25s ease;transform: scale(5);opacity: 0}
				.btn:hover {filter: drop-shadow(4px 4px 2px #2225)}
				.rotate {animation: rotate 2s ease-in-out infinite;display: inline-block}
				@keyframes rotate {100% {transform: rotate(0deg)} 0% {transform: rotate(360deg)}}
				.btn:hover::before {transform: scale(1.0125);opacity: 1;filter: blur(0px)}
				#x {background-color: #fff;border-radius: 4px;filter: drop-shadow(0px 0px 6px #22222266);
				transition: all 0.25s ease;margin-bottom: 20px} #x:hover {filter: drop-shadow(4px 4px 6px #222222aa)}
				#w {margin: 20px;max-width: 75vw} .btn:active::before,
				.btn:focus::before {background-color: #00A32C} .btn:active, .btn:focus {border-color: #00A32C;color: #f55 }
				</style></head><body><div id="x"><div id="w"><h2>This dummy file is generated by #{f}</h2>
				<p>#{emojis.shift} <span class="text">Please create a file with .html extension to reload it on the browser.</span></p>
				<p>#{emojis.shift} <span class="text">You can create others file, and this view will get updated!</span></p>
				<p>#{emojis.shift} <span class="text">This is handy when you are creating lots of html files and want to test them out.</span></p>
				<p>#{emojis.shift} <span class="text">Just remember to place your stylesheets, js files, assets, and other stuff in the #{__dir__}/</span></p>
				<p>#{emojis.shift} <span class="text">I am watching for files! Please reload the page once you are done!</span></p>
				<center><button class="btn" href="#" data-content="Reload" onclick="window.location.reload()">
				<span class="rotate">&#x2B6F;</span>&nbsp;Reload</button></center>
				</div></div></body></html>
			EOF
		)
	end

	n_files = get_files.count
	puts "#{COLOUR_PRIMARY}:: Watching for modified or new .html files in #{__dir__}\e[0m"
	puts "#{COLOUR_SUCCESS}:: Found #{n_files} html file#{n_files == 1 ? '' : 's' } so far...\e[0m\n\n"
end

def start_server
	port = 8080

	begin
		WEBrick::HTTPServer.new(
			Port: port,
			DocumentRoot: __dir__,
			BindAddress: '0.0.0.0',
			Logger: WEBrick::Log.new(File::NULL)
		).start
	rescue Errno::EADDRINUSE
		puts "#{COLOUR_INFO}:: Error: Port #{port} is unavailable! Retrying to http://0.0.0.0:#{port += 1}\e[0m"
		sleep 0.05
		retry
	end
end

def main
	updated_at = Time.now.to_i
	output_file = OUTPUT_FILE
	anim = %W(\xE2\xA0\x82 \xE2\xA0\x90 \xE2\xA0\xA0 \xE2\xA0\xA4 \xE2\xA0\x86)
	ellipses = %w(. .. ...)

	while files = get_files.tap(&:sort!)
		files.each do |file|
			mtime, w = File.mtime(file), STDOUT.winsize[1]

			if (mtime_i = mtime.to_i) > updated_at
				sleep 0.125
				updated_at = mtime_i
				contents = IO.read(output_file) if File.readable?(output_file)
				puts "\n\e[1;38;2;0;180;0m:: Compiling a newly modified file #{file}...\e[0m"

				begin
					compiled_html = <<~EOF
						<!Doctype HTML>
						<html>
						<!-- This file is generated by #{File.basename(Process.argv0)} -->
						<!-- Read #{file} for source code. -->
						#{IO.readlines(file).each(&:strip!).join(?\n).split(?\n).tap { |x| x.reject!(&:empty?) }.join(?\n)}
						</html>
					EOF

					if contents != compiled_html
						IO.write(output_file.tap { |f| puts "\n#{?\s.*((w / 2 - f.length / 2 - 4).clamp(0, Float::INFINITY))}#{COLOUR_PRIMARY}\e[4mUpdating #{f}\e[0m\n" + "\e[0m" }, compiled_html)
						puts "\e[38;2;255;170;40m#{compiled_html}\e[0m"
						puts "#{COLOUR_SUCCESS}:: Successfully updated #{file} at #{mtime}".center(w) + "\e[0m"
					else
						puts "\n#{COLOUR_WARNING}:: Skipped, File has same content...\e[0m"
					end
				rescue Exception
					puts "#{COLOUR_ERROR}#{' :: Error '.center(w, ?-)}\e[0m"
					puts "#{$!.to_s.each_line.map { |el| el.prepend('| ').concat(' |'.rjust(w - el.length)) }.join}"
					puts "\e[1;38;2;255;80;80m#{?- * w}\e[0m"
				ensure
					puts "\e[1m#{?-.*(3).center(w)}\e[0m"
				end
			end
		end

		print " \e[2K#{COLOUR_PRIMARY}#{anim.rotate![0]} Watching for file changes#{ellipses.rotate![0]}\e[0m\r"
		sleep(0.25)
	end
end

begin
	init
	Thread.new { start_server }
	main
rescue Interrupt, SystemExit, SignalException
	puts "\n:: Good Bye!"
rescue Exception
	abort $!.full_message
end
