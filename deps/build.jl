using Dates

function build_time(t)
	open((io)->println(io, t), "buildtime.txt", "w")
end

println("Building HTMLParser")
build_time(Dates.now())


